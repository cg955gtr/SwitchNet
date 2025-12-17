--[==[
	Author: 8ch99
	File: Client.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

local ACTIVE_REMOTES = {}

--// Dependencies

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

local Bitstream = require("./Bitstream")

local Create = Bitstream.Create
local Read = Bitstream.Read
local GetSizeOfValues = Bitstream._getSizeOfValues

export type OnClientEventCallback = {
	Reliable: boolean,
	Function: (...any) -> (),
}

export type NetworkPacket = {
	Data: buffer,
	References: { any },
}

export type SendPacket = {
	Size: number,
	Data: Bitstream.NBasedArray,
}

export type Client = {
	Name: string,

	_onClientInvokeCallback: ((Player, ...any) -> ...any)?,
	_onClientEventCallbacks: { [string]: OnClientEventCallback },

	_sendStack: { SendPacket },
	_sendStackUnr: { SendPacket },

	_remoteContainer: Folder,
	
	_remoteEvent: RemoteEvent,
	_unrRemoteEvent: UnreliableRemoteEvent,
	_remoteFunction: RemoteFunction,

	_onClientEvent: RBXScriptConnection,
	_onUnrClientEvent: RBXScriptConnection,
	_replicationHandler: RBXScriptConnection,
}

local function VerifyNetworkPacketIntegrity(Packet: NetworkPacket): boolean
	return type(Packet) == "table" and type(Packet.Data) == "buffer" and type(Packet.References) == "table"
end

--// @module Client

local Client = {}

--// Main methods

function Client.new(Name: string): Client
	assert(ACTIVE_REMOTES[Name] == nil, `remote bridge '{Name}' already exists!`)
	ACTIVE_REMOTES[Name] = true

	local self = {} :: Client

	self.Name = Name

	self._onClientEventCallbacks = {} :: { [string]: OnClientEventCallback }
	self._sendStack = {} :: { SendPacket }
	self._sendStackUnr = {} :: { SendPacket }

	self._remoteContainer = ReplicatedStorage:WaitForChild(Name) :: Folder
	self._remoteEvent = self._remoteContainer:WaitForChild("Reliable") :: RemoteEvent
	self._unrRemoteEvent = self._remoteContainer:WaitForChild("Unreliable") :: UnreliableRemoteEvent
	self._remoteFunction = self._remoteContainer:WaitForChild("Function") :: RemoteFunction

	local HandleIncomingRequest = Client._handleIncomingRequest
	local HandleSendStack = Client._handleSendStack

	self._onClientEvent = self._remoteEvent.OnClientEvent:Connect(function(IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end

		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				return
			end

			HandleIncomingRequest(self, true, Packet.Data, Packet.References)
		end
	end)

	self._onUnrClientEvent = self._unrRemoteEvent.OnClientEvent:Connect(function(IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end

		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				return
			end

			HandleIncomingRequest(self, false, Packet.Data, Packet.References)
		end
	end)

	local _sendStack: { SendPacket } = self._sendStack
	local _sendStackUnr: { SendPacket } = self._sendStackUnr

	self._replicationHandler = RunService.PostSimulation:Connect(function()
		debug.profilebegin("SwitchNet.Client._replicationHandler")

		if #_sendStack > 0 then
			HandleSendStack(self, true)
		end

		if #_sendStackUnr > 0 then
			HandleSendStack(self, false)
		end

		debug.profileend()
	end)

	self._remoteFunction.OnClientInvoke = function(IncomingData: NetworkPacket)
		if not self._onClientInvokeCallback then
			return nil
		end

		local Results: Bitstream.NBasedArray

		if IncomingData then
			if not VerifyNetworkPacketIntegrity(IncomingData) then
				return
			end

			local RealReferences: Bitstream.NBasedArray = IncomingData.References :: Bitstream.NBasedArray
			RealReferences.n = #RealReferences

			local Success: boolean, Args: Bitstream.NBasedArray = pcall(Read, IncomingData.Data, RealReferences)

			if Success then
				Results = table.pack(pcall(self._onClientInvokeCallback, table.unpack(Args, 1, Args.n)))
				
				if table.remove(Results, 1) == false then
					Results = { n = 0 }
				end
			end
		end

		if not Results or Results.n == 0 then
			return nil
		end

		local Success: boolean, Buffer: buffer, References: Bitstream.NBasedArray = pcall(Create, Results, GetSizeOfValues(Results))

		if not Success then
			return nil
		end

		return {
			Data = Buffer,
			References = References,
		}
	end

	return self
end

function Client.Destroy(self: Client)
	self._replicationHandler:Disconnect()
	self._onUnrClientEvent:Disconnect()
	self._onClientEvent:Disconnect()

	table.clear(self._onClientEventCallbacks)
	table.clear(self._sendStack)
	table.clear(self._sendStackUnr)
	
	table.clear(self)

	self = nil :: never
end

function Client.Connect(self: Client, Name: string, Function: (Player, ...any) -> (), Unreliable: boolean?)
	local Callback: OnClientEventCallback = {
		Reliable = not Unreliable,
		Function = Function,
	}

	self._onClientEventCallbacks[Name] = Callback
end

function Client.Disconnect(self: Client, Name: string)
	self._onClientEventCallbacks[Name] = nil
end

function Client.SetOnInvoke(self: Client, Function: (Player, ...any) -> ...any)
	self._onClientInvokeCallback = Function
end

function Client.FireServer(self: Client, ...: any)
	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._sendStack, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})
end

function Client.FireServerUnreliable(self: Client, ...: any)
	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._sendStackUnr, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})
end

function Client.InvokeServer(self: Client, ...: any): ...any
	local SendData: Bitstream.NBasedArray = table.pack(...)
	local BufferSize: number = GetSizeOfValues(SendData)

	local Data: buffer, References: Bitstream.NBasedArray = Create(SendData, BufferSize)
	local ResponsePacket: NetworkPacket

	local Success: boolean, Error: string? = pcall(function()
		ResponsePacket = self._remoteFunction:InvokeServer({
			Data = Data,
			References = References,
			ReferenceCount = References.n,
		})
	end)

	if not Success then
		warn(`InvokeServer failed! Error:\n{Error}`)
		return nil
	end

	if ResponsePacket == nil then
		return nil
	end

	if not VerifyNetworkPacketIntegrity(ResponsePacket) then
		return
	end
	
	local RealReferences: Bitstream.NBasedArray = ResponsePacket.References :: Bitstream.NBasedArray
	RealReferences.n = #RealReferences

	local Response: Bitstream.NBasedArray = Read(ResponsePacket.Data, RealReferences)

	return table.unpack(Response, 1, Response.n)
end

--// Private methods

function Client._handleIncomingRequest(self: Client, Reliable: boolean, Data: buffer, References: { any })
	if not next(self._onClientEventCallbacks) then
		return
	end

	debug.profilebegin("SwitchNet.Client._handleIncomingRequest")

	local RealReferences: Bitstream.NBasedArray = References :: Bitstream.NBasedArray
	RealReferences.n = #RealReferences

	local Args: Bitstream.NBasedArray = Read(Data, RealReferences)

	for Name, Callback: OnClientEventCallback in self._onClientEventCallbacks do
		if Callback.Reliable == Reliable then
			--// TODO: Use xpcall instead to fetch error tracebacks
			local Success: boolean, Error: any = pcall(task.spawn, Callback.Function, table.unpack(Args, 1, Args.n))

			if not Success then
				TestService:Error(`NetworkClient '{self.Name}' Callback Error:\n{Error}`)
			end
		end
	end

	debug.profileend()
end

function Client._handleSendStack(self: Client, Reliable: boolean)
	local Remote = if Reliable then self._remoteEvent else self._unrRemoteEvent
	local Stack: { SendPacket } = if Reliable then self._sendStack else self._sendStackUnr

	local NetworkPackets: { NetworkPacket } = {}

	for _, Packet: SendPacket in Stack do
		local Buffer: buffer, References: Bitstream.NBasedArray = Create(Packet.Data, Packet.Size)

		table.insert(NetworkPackets, {
			Data = Buffer,
			References = References :: { any },
		})
	end

	table.clear(Stack);
	
	(Remote :: RemoteEvent):FireServer(NetworkPackets)
	--// ^ I hate the typechecker
end

return Client