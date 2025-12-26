--[==[
	Author: 8ch99
	File: Client.luau
	Date written: 15th November 2025
	Last edited: 25th December 2025
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

	_parallel: boolean,

	_onClientInvokeCallback: ((...any) -> ...any)?,

	_onClientEventCallbacks: { [string]: (...any) -> () },
	_onClientEventCallbacksUnr: { [string]: (...any) -> () },

	_waitingThreads: { [thread]: boolean },
	_waitingThreadsUnr: { [thread]: boolean },

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

local function GetCallingScript(): Instance?
	local Src: string = debug.info(3, "s")

	if Src == "" then
		return nil
	end

	local Current: Instance? = game

	for _, Name in string.split(Src, ".") do
		Current = (Current :: Instance):FindFirstChild(Name)
		if not Current then
			return nil
		end
	end

	if Current == game then
		return nil
	end

	return Current
end

--// @module Client

local Client = {}

function Client.new(Name: string): Client
	assert(ACTIVE_REMOTES[Name] == nil, `remote bridge '{Name}' already exists!`)
	assert(RunService:IsClient(), "This is a client-only function!")

	ACTIVE_REMOTES[Name] = true

	local CallingScript = GetCallingScript()

	local self = {
		Name = Name,

		_parallel = if CallingScript then CallingScript:FindFirstAncestorOfClass("Actor") ~= nil else false,

		_onClientEventCallbacks = {} :: { [string]: (...any) -> () },
		_onClientEventCallbacksUnr = {} :: { [string]: (...any) -> () },

		_sendStack = {} :: { SendPacket },
		_sendStackUnr = {} :: { SendPacket },

		_waitingThreads = {} :: { [thread]: boolean },
		_waitingThreadsUnr = {} :: { [thread]: boolean },

		_remoteContainer = ReplicatedStorage:WaitForChild(Name) :: Folder,
	} :: Client

	self._remoteEvent = self._remoteContainer:WaitForChild("Reliable") :: RemoteEvent
	self._unrRemoteEvent = self._remoteContainer:WaitForChild("Unreliable") :: UnreliableRemoteEvent
	self._remoteFunction = self._remoteContainer:WaitForChild("Function") :: RemoteFunction

	self._onClientEvent = self._remoteEvent.OnClientEvent:Connect(function(IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end

		local OnClientEventCallbacks: { [string]: (Player, ...any) -> () } = self._onClientEventCallbacks
		local WaitingThreads: { [thread]: boolean } = self._waitingThreads

		if not next(OnClientEventCallbacks) and not next(WaitingThreads) then
			return
		end

		if self._parallel then
			task.desynchronize()
		end

		debug.profilebegin("SwitchNet.Client Incoming Packets Job")

		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				return
			end

			local Data: buffer = Packet.Data
			local References: { any } = Packet.References

			local RealReferences: Bitstream.NBasedArray = References :: Bitstream.NBasedArray
			RealReferences.n = #RealReferences
			
			local Args: Bitstream.NBasedArray = Read(Data, RealReferences)
			local Amount: number = Args.n

			--// Free waiting threads
			for Thread: thread in WaitingThreads do
				pcall(task.spawn, Thread, table.unpack(Args, 1, Amount))
			end

			table.clear(WaitingThreads)
			
			--// Fire callbacks
			for Name: string, Function: (Player, ...any) -> () in OnClientEventCallbacks do
				--// TODO: Use xpcall instead to fetch error tracebacks
				local Success: boolean, Error: any = pcall(task.spawn, Function, table.unpack(Args, 1, Amount))

				if not Success then
					TestService:Error(`SwitchNet.Client '{self.Name}' Callback Error:\n{Error}`)
				end
			end
		end

		debug.profileend()

		if self._parallel then
			task.synchronize()
		end
	end)

	self._onUnrClientEvent = self._unrRemoteEvent.OnClientEvent:Connect(function(IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end

		local OnClientEventCallbacks: { [string]: (Player, ...any) -> () } = self._onClientEventCallbacksUnr
		local WaitingThreads: { [thread]: boolean } = self._waitingThreadsUnr

		if not next(OnClientEventCallbacks) and not next(WaitingThreads) then
			return
		end

		if self._parallel then
			task.desynchronize()
		end

		debug.profilebegin("SwitchNet.Client Incoming Packets Job (Unreliable)")

		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				return
			end

			local Data: buffer = Packet.Data
			local References: { any } = Packet.References

			local RealReferences: Bitstream.NBasedArray = References :: Bitstream.NBasedArray
			RealReferences.n = #RealReferences
			
			local Args: Bitstream.NBasedArray = Read(Data, RealReferences)
			local Amount: number = Args.n

			--// Free waiting threads
			for Thread: thread in WaitingThreads do
				pcall(task.spawn, Thread, table.unpack(Args, 1, Amount))
			end

			table.clear(WaitingThreads)
			
			--// Fire callbacks
			for Name: string, Function: (Player, ...any) -> () in OnClientEventCallbacks do
				--// TODO: Use xpcall instead to fetch error tracebacks
				local Success: boolean, Error: any = pcall(task.spawn, Function, table.unpack(Args, 1, Amount))

				if not Success then
					TestService:Error(`SwitchNet.Client '{self.Name}' (UNRELIABLE) Callback Error:\n{Error}`)
				end
			end
		end

		debug.profileend()

		if self._parallel then
			task.synchronize()
		end
	end)

	local Remote: RemoteEvent = self._remoteEvent
	local UnreliableRemote: UnreliableRemoteEvent = self._unrRemoteEvent

	local _sendStack: { SendPacket } = self._sendStack
	local _sendStackUnr: { SendPacket } = self._sendStackUnr

	self._replicationHandler = RunService.PostSimulation[if self._parallel then "ConnectParallel" else "Connect"](RunService.PostSimulation, function()
		debug.profilebegin("SwitchNet.Client Outgoing Packets Job")

		if #_sendStack > 0 then
			local NetworkPackets: { NetworkPacket } = {}

			for _, Packet: SendPacket in _sendStack do
				local Buffer: buffer, References: Bitstream.NBasedArray = Create(Packet.Data, Packet.Size)

				table.insert(NetworkPackets, {
					Data = Buffer,
					References = References :: { any },
				})
			end

			table.clear(_sendStack)

			if self._parallel then
				task.synchronize()
			end
	
			Remote:FireServer(NetworkPackets)

			if self._parallel then
				task.desynchronize()
			end
		end

		if #_sendStackUnr > 0 then
			local NetworkPackets: { NetworkPacket } = {}

			for _, Packet: SendPacket in _sendStackUnr do
				local Buffer: buffer, References: Bitstream.NBasedArray = Create(Packet.Data, Packet.Size)

				table.insert(NetworkPackets, {
					Data = Buffer,
					References = References :: { any },
				})
			end

			table.clear(_sendStackUnr)

			if self._parallel then
				task.desynchronize()
			end
	
			UnreliableRemote:FireServer(NetworkPackets)

			if self._parallel then
				task.synchronize()
			end
		end

		debug.profileend()
	end)

	self._remoteFunction.OnClientInvoke = function(IncomingData: NetworkPacket)
		if not self._onClientInvokeCallback then
			return nil
		end

		if self._parallel then
			task.desynchronize()
		end

		local Results: Bitstream.NBasedArray

		if IncomingData then
			if not VerifyNetworkPacketIntegrity(IncomingData) then
				if self._parallel then
					task.synchronize()
				end

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
			if self._parallel then
				task.synchronize()
			end

			return nil
		end

		local Success: boolean, Buffer: buffer, References: Bitstream.NBasedArray = pcall(Create, Results, GetSizeOfValues(Results))

		if self._parallel then
			task.synchronize()
		end

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

function Client.Wait(self: Client): ...any
	local Thread: thread = coroutine.running()

	self._waitingThreads[Thread] = true
	
	return coroutine.yield()
end

function Client.WaitUnreliable(self: Client): ...any
	local Thread: thread = coroutine.running()

	self._waitingThreadsUnr[Thread] = true
	
	return coroutine.yield()
end

function Client.Connect(self: Client, Name: string, Function: (...any) -> ())
	self._onClientEventCallbacks[Name] = Function
end

function Client.ConnectUnreliable(self: Client, Name: string, Function: (...any) -> ())
	self._onClientEventCallbacksUnr[Name] = Function
end

function Client.Disconnect(self: Client, Name: string)
	self._onClientEventCallbacks[Name] = nil
end

function Client.DisconnectUnreliable(self: Client, Name: string)
	self._onClientEventCallbacksUnr[Name] = nil
end

function Client.SetOnInvoke(self: Client, Function: (...any) -> ...any)
	self._onClientInvokeCallback = Function
end

function Client.FireServer(self: Client, ...: any)
	if self._parallel then
		task.desynchronize()
	end

	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._sendStack, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})

	if self._parallel then
		task.synchronize()
	end
end

function Client.FireServerUnreliable(self: Client, ...: any)
	if self._parallel then
		task.desynchronize()
	end

	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._sendStackUnr, {
		Size = GetSizeOfValues(Data),
		Data = Data,
	})

	if self._parallel then
		task.synchronize()
	end
end

function Client.InvokeServer(self: Client, ...: any): ...any
	if self._parallel then
		task.desynchronize()
	end

	local SendData: Bitstream.NBasedArray = table.pack(...)
	local BufferSize: number = GetSizeOfValues(SendData)

	local Data: buffer, References: Bitstream.NBasedArray = Create(SendData, BufferSize)
	local ResponsePacket: NetworkPacket

	local Success: boolean, Error: string? = pcall(function()
		if self._parallel then
			task.synchronize()
		end

		ResponsePacket = self._remoteFunction:InvokeServer({
			Data = Data,
			References = References,
			ReferenceCount = References.n,
		})
	end)

	if self._parallel then
		task.desynchronize()
	end

	if not Success then
		TestService:Error(`SwitchNet.Client '{self.Name}' InvokeServer failed! Error:\n{Error}`)
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

	if self._parallel then
		task.synchronize()
	end

	return table.unpack(Response, 1, Response.n)
end

return Client