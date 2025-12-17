--[==[
	Author: 8ch99
	File: Server.luau
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

type OnServerEventCallback = {
	Reliable: boolean,
	Function: (Player, ...any) -> (),
}

type NetworkPacket = {
	Data: buffer,
	References: { any },
}

type SendPacket = {
	Size: number,
	Data: Bitstream.NBasedArray,
}

export type Server = {
	Name: string,

	_onServerInvokeCallback: ((Player, ...any) -> ...any)?,
	_onServerEventCallbacks: { [string]: OnServerEventCallback },

	_playerSendStack: { [Player]: { SendPacket } },
	_playerSendStackUnr: { [Player]: { SendPacket } },
	_globalSendStack: { SendPacket },
	_globalSendStackUnr: { SendPacket },

	_remoteContainer: Folder,
	
	_remoteEvent: RemoteEvent,
	_unrRemoteEvent: UnreliableRemoteEvent,
	_remoteFunction: RemoteFunction,

	_onServerEvent: RBXScriptConnection,
	_onUnrServerEvent: RBXScriptConnection,
	_replicationHandler: RBXScriptConnection,
}

local function VerifyNetworkPacketIntegrity(Packet: NetworkPacket): boolean
	return type(Packet) == "table" and type(Packet.Data) == "buffer" and type(Packet.References) == "table"
end

--// @module Server

local Server = {}

function Server.new(Name: string): Server
	assert(ACTIVE_REMOTES[Name] == nil, `remote bridge '{Name}' already exists!`)
	ACTIVE_REMOTES[Name] = true

	local self = {} :: Server

	self.Name = Name

	self._onServerEventCallbacks = {} :: { [string]: OnServerEventCallback }
	self._playerSendStack = {} :: { [Player]: { SendPacket } }
	self._playerSendStackUnr = {} :: { [Player]: { SendPacket } }
	self._globalSendStack = {} :: { SendPacket }
	self._globalSendStackUnr = {} :: { SendPacket }

	self._remoteContainer = Instance.new("Folder") :: Folder
	self._remoteContainer.Name = Name

	self._remoteEvent = Instance.new("RemoteEvent") :: RemoteEvent
	self._remoteEvent.Name = "Reliable"

	self._unrRemoteEvent = Instance.new("UnreliableRemoteEvent") :: UnreliableRemoteEvent
	self._unrRemoteEvent.Name = "Unreliable"

	self._remoteFunction = Instance.new("RemoteFunction") :: RemoteFunction
	self._remoteFunction.Name = "Function"

	self._remoteEvent.Parent = self._remoteContainer
	self._unrRemoteEvent.Parent = self._remoteContainer
	self._remoteFunction.Parent = self._remoteContainer
	self._remoteContainer.Parent = ReplicatedStorage

	local HandleIncomingRequest = Server._handleIncomingRequest

	self._onServerEvent = self._remoteEvent.OnServerEvent:Connect(function(Sender: Player, IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end
		
		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				return
			end

			HandleIncomingRequest(self, true, Sender, Packet.Data, Packet.References)
		end
	end)

	self._onUnrServerEvent = self._unrRemoteEvent.OnServerEvent:Connect(function(Sender: Player, IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end

		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				return
			end

			HandleIncomingRequest(self, false, Sender, Packet.Data, Packet.References)
		end
	end)

	local Remote: RemoteEvent = self._remoteEvent
	local UnreliableRemote: UnreliableRemoteEvent = self._unrRemoteEvent
	
	local _globalSendStack: { SendPacket } = self._globalSendStack
	local _globalSendStackUnr: { SendPacket } = self._globalSendStackUnr
	local _playerSendStack: { [Player]: { SendPacket } } = self._playerSendStack
	local _playerSendStackUnr: { [Player]: { SendPacket } } = self._playerSendStackUnr

	self._replicationHandler = RunService.PostSimulation:Connect(function()
		debug.profilebegin("SwitchNet.Server._replicationHandler")

		--// Global stacks (FireAllClients)
		if #_globalSendStack > 0 then
			local NetworkPackets: { NetworkPacket } = {}

			for _, Packet: SendPacket in _globalSendStack do
				local Buffer: buffer, References: Bitstream.NBasedArray = Create(Packet.Data, Packet.Size)

				table.insert(NetworkPackets, {
					Data = Buffer,
					References = References :: { any },
				})
			end

			table.clear(_globalSendStack)

			Remote:FireAllClients(NetworkPackets)
		end

		if #_globalSendStackUnr > 0 then
			local NetworkPackets: { NetworkPacket } = {}

			for _, Packet: SendPacket in _globalSendStackUnr do
				local Buffer: buffer, References: Bitstream.NBasedArray = Create(Packet.Data, Packet.Size)

				table.insert(NetworkPackets, {
					Data = Buffer,
					References = References :: { any },
				})
			end

			table.clear(_globalSendStackUnr)

			UnreliableRemote:FireAllClients(NetworkPackets)
		end

		--// Per-player stacks
		if #_playerSendStack > 0 then
			for Player: Player, Packets: { SendPacket } in _playerSendStack do
				if Player.Parent == nil then
					continue
				end

				local NetworkPackets: { NetworkPacket } = {}

				for _, Packet: SendPacket in Packets do
					local Buffer: buffer, References: Bitstream.NBasedArray = Create(Packet.Data, Packet.Size)

					table.insert(NetworkPackets, {
						Data = Buffer,
						References = References :: { any },
					})
				end

				Remote:FireClient(Player, NetworkPackets)
			end

			table.clear(_playerSendStack)
		end

		if #_playerSendStackUnr > 0 then
			for Player: Player, Packets: { SendPacket } in _playerSendStackUnr do
				if Player.Parent == nil then
					continue
				end

				local NetworkPackets: { NetworkPacket } = {}

				for _, Packet: SendPacket in Packets do
					local Buffer: buffer, References: Bitstream.NBasedArray = Create(Packet.Data, Packet.Size)

					table.insert(NetworkPackets, {
						Data = Buffer,
						References = References :: { any },
					})
				end

				UnreliableRemote:FireClient(Player, NetworkPackets)
			end

			table.clear(_playerSendStackUnr)
		end

		debug.profileend()
	end)

	self._remoteFunction.OnServerInvoke = function(Sender: Player, IncomingData: NetworkPacket)
		if not self._onServerInvokeCallback then
			return nil
		end

		local Results: Bitstream.NBasedArray

		if IncomingData then
			if not VerifyNetworkPacketIntegrity(IncomingData) then
				return nil
			end

			local RealReferences: Bitstream.NBasedArray = IncomingData.References :: Bitstream.NBasedArray
			RealReferences.n = #RealReferences

			local Success: boolean, Args: Bitstream.NBasedArray = pcall(Read, IncomingData.Data, RealReferences)

			if Success then
				Results = { pcall(self._onServerInvokeCallback, Sender, table.unpack(Args, 1, Args.n)) } :: Bitstream.NBasedArray
				
				if table.remove(Results, 1) == false then
					Results = { n = 0 }
				else
					Results.n = #Results
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

function Server.Destroy(self: Server)
	self._replicationHandler:Disconnect()
	self._onUnrServerEvent:Disconnect()
	self._onServerEvent:Disconnect()

	self._remoteContainer:Destroy()
	--// ^ also destroys the remote events

	table.clear(self._onServerEventCallbacks)
	table.clear(self._playerSendStack)
	table.clear(self._playerSendStackUnr)
	table.clear(self._globalSendStack)
	table.clear(self._globalSendStackUnr)
	
	table.clear(self)

	self = nil :: never
end

function Server.Connect(self: Server, Name: string, Function: (Player, ...any) -> (), Unreliable: boolean?)
	local Callback: OnServerEventCallback = {
		Reliable = not Unreliable,
		Function = Function,
	}

	self._onServerEventCallbacks[Name] = Callback
end

function Server.Disconnect(self: Server, Name: string)
	self._onServerEventCallbacks[Name] = nil
end

function Server.SetOnInvoke(self: Server, Function: (Player, ...any) -> ...any)
	self._onServerInvokeCallback = Function
end

function Server.FireClient(self: Server, Player: Player, ...: any)
	local Data: Bitstream.NBasedArray = table.pack(...)

	local SendStack: { [Player]: { SendPacket } } = self._playerSendStack
	local Stack: { SendPacket } = SendStack[Player]

	if not Stack then
		Stack = {} :: { SendPacket }
		SendStack[Player] = Stack
	end

	table.insert(Stack, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})
end

function Server.FireClientUnreliable(self: Server, Player: Player, ...: any)
	local Data: Bitstream.NBasedArray = table.pack(...)

	local SendStack: { [Player]: { SendPacket } } = self._playerSendStackUnr
	local Stack: { SendPacket } = SendStack[Player]

	if not Stack then
		Stack = {} :: { SendPacket }
		SendStack[Player] = Stack
	end

	table.insert(Stack, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})
end

function Server.FireAllClients(self: Server, ...: any)
	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._globalSendStack, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})
end

function Server.FireAllClientsUnreliable(self: Server, ...: any)
	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._globalSendStackUnr, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})
end

function Server.InvokeClient(self: Server, Player: Player, ...: any): ...any
	local SendData: Bitstream.NBasedArray = table.pack(...)
	local BufferSize: number = GetSizeOfValues(SendData)

	local Data: buffer, References: Bitstream.NBasedArray = Create(SendData, BufferSize)
	local ResponsePacket: NetworkPacket

	local Success: boolean, Error: string? = pcall(function()
		ResponsePacket = self._remoteFunction:InvokeClient(Player, {
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
		return nil
	end

	local RealReferences: Bitstream.NBasedArray = ResponsePacket.References :: Bitstream.NBasedArray
	RealReferences.n = #RealReferences

	local Response: Bitstream.NBasedArray = Read(ResponsePacket.Data, RealReferences)

	return table.unpack(Response, 1, Response.n)
end

--// Private methods

function Server._handleIncomingRequest(self: Server, Reliable: boolean, Sender: Player, Data: buffer, References: { any })
	if not next(self._onServerEventCallbacks) then
		return
	end

	debug.profilebegin("SwitchNet.Server._handleIncomingRequest")

	local RealReferences: Bitstream.NBasedArray = References :: Bitstream.NBasedArray
	RealReferences.n = #RealReferences
	
	local Args: Bitstream.NBasedArray = Read(Data, RealReferences)
	
	for Name, Callback: OnServerEventCallback in self._onServerEventCallbacks do
		if Callback.Reliable == Reliable then
			--// TODO: Use xpcall instead to fetch error tracebacks
			local Success: boolean, Error: any = pcall(task.spawn, Callback.Function, Sender, table.unpack(Args, 1, Args.n))

			if not Success then
				TestService:Error(`NetworkServer '{self.Name}' Callback Error:\n{Error}`)
			end
		end
	end

	debug.profileend()
end

return Server