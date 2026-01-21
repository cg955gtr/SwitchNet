--[==[
	Author: 8ch99
	File: Server.luau
	Date written: 15th November 2025
	Last edited: 25th December 2025
]==]

--!strict
--!native
--!optimize 2

local ACTIVE_REMOTES = {}
local USE_DEEP_COPY: boolean = true

--// Dependencies

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

local Bitstream = require("./Bitstream")

local Create = Bitstream.Create
local Read = Bitstream.Read
local GetSizeOfValues = Bitstream._getSizeOfValues

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

	_parallel: boolean,

	_onServerInvokeCallback: ((Player, ...any) -> ...any)?,

	_onServerEventCallbacks: { [string]: (Player, ...any) -> () },
	_onServerEventCallbacksUnr: { [string]: (Player, ...any) -> () },

	_playerSendStack: { [Player]: { SendPacket } },
	_playerSendStackUnr: { [Player]: { SendPacket } },
	_globalSendStack: { SendPacket },
	_globalSendStackUnr: { SendPacket },

	_waitingThreads: { [thread]: boolean },
	_waitingThreadsUnr: { [thread]: boolean },

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

local function DeepClone(Table: { [any]: any }): { [any]: any }
	local Copy: { [any]: any } = {}

	for Index: any, Value: any in Table do
		if type(Value) == "table" then
			Value = DeepClone(Value)
		end
		Copy[Index] = Value
	end

	return Copy
end

--// @module Server

local Server = {}

function Server.new(Name: string): Server
	assert(ACTIVE_REMOTES[Name] == nil, `remote bridge '{Name}' already exists!`)
	assert(ReplicatedStorage:FindFirstChild(Name) == nil, `RS has an instance with the same name already! Use a different name to '{Name}'.`)
	assert(RunService:IsServer(), "This is a server-only function!")

	ACTIVE_REMOTES[Name] = true

	local CallingScript = GetCallingScript()

	local self = {
		Name = Name,

		_parallel = if CallingScript then CallingScript:FindFirstAncestorOfClass("Actor") ~= nil else false,

		_waitingThreads = {} :: { [thread]: boolean },
		_waitingThreadsUnr = {} :: { [thread]: boolean },

		_onServerEventCallbacks = {} :: { [string]: (Player, ...any) -> () },
		_onServerEventCallbacksUnr = {} :: { [string]: (Player, ...any) -> () },

		_playerSendStack = {} :: { [Player]: { SendPacket } },
		_playerSendStackUnr = {} :: { [Player]: { SendPacket } },
		_globalSendStack = {} :: { SendPacket },
		_globalSendStackUnr = {} :: { SendPacket },

		_remoteContainer = Instance.new("Folder") :: Folder,
		_remoteEvent = Instance.new("RemoteEvent") :: RemoteEvent,
		_unrRemoteEvent = Instance.new("UnreliableRemoteEvent") :: UnreliableRemoteEvent,
		_remoteFunction = Instance.new("RemoteFunction") :: RemoteFunction,
	} :: Server

	self._remoteContainer.Name = Name
	self._remoteEvent.Name = "Reliable"
	self._unrRemoteEvent.Name = "Unreliable"
	self._remoteFunction.Name = "Function"

	self._remoteEvent.Parent = self._remoteContainer
	self._unrRemoteEvent.Parent = self._remoteContainer
	self._remoteFunction.Parent = self._remoteContainer

	self._remoteContainer.Parent = ReplicatedStorage

	local Remote: RemoteEvent = self._remoteEvent
	local UnreliableRemote: UnreliableRemoteEvent = self._unrRemoteEvent
	
	local _globalSendStack: { SendPacket } = self._globalSendStack
	local _globalSendStackUnr: { SendPacket } = self._globalSendStackUnr
	local _playerSendStack: { [Player]: { SendPacket } } = self._playerSendStack
	local _playerSendStackUnr: { [Player]: { SendPacket } } = self._playerSendStackUnr

	local OnServerEventCallbacks: { [string]: (Player, ...any) -> () } = self._onServerEventCallbacks
	local OnServerEventCallbacksUnr: { [string]: (Player, ...any) -> () } = self._onServerEventCallbacksUnr
	local WaitingThreads: { [thread]: boolean } = self._waitingThreads
	local WaitingThreadsUnr: { [thread]: boolean } = self._waitingThreadsUnr

	local IsParallel: boolean = self._parallel

	--// Internal functions for firing callbacks without using unpack() too many times
	local function _fireCallbacks(Sender: Player, ...: any)
		for Thread: thread in WaitingThreads do
			pcall(task.spawn, Thread, Sender, ...)
		end

		table.clear(WaitingThreads)

		for Name: string, Function: (Player, ...any) -> () in OnServerEventCallbacks do
			local Success: boolean, Error: any = pcall(task.spawn, Function, Sender, ...)

			if not Success then
				TestService:Error(`SwitchNet.Server '{self.Name}' Callback '{Name}' Error:\n{Error}`)
			end
		end
	end

	local function _fireCallbacksUnr(Sender: Player, ...: any)
		for Thread: thread in WaitingThreadsUnr do
			pcall(task.spawn, Thread, Sender, ...)
		end

		table.clear(WaitingThreadsUnr)

		for Name: string, Function: (Player, ...any) -> () in OnServerEventCallbacksUnr do
			local Success: boolean, Error: any = pcall(task.spawn, Function, Sender, ...)

			if not Success then
				TestService:Error(`SwitchNet.Server '{self.Name}' (UNRELIABLE) Callback '{Name}' Error:\n{Error}`)
			end
		end
	end

	self._onServerEvent = self._remoteEvent.OnServerEvent:Connect(function(Sender: Player, IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end

		if not next(OnServerEventCallbacks) and not next(WaitingThreads) then
			return
		end

		if IsParallel then
			task.desynchronize()
		end

		debug.profilebegin("SwitchNet.Server Incoming Packets Job")
		
		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				if IsParallel then
					task.synchronize()
				end

				return
			end
			
			local Data: buffer = Packet.Data
			local References: { any } = Packet.References

			local RealReferences: Bitstream.NBasedArray = References :: Bitstream.NBasedArray
			RealReferences.n = #RealReferences
			
			local Args: Bitstream.NBasedArray = Read(Data, RealReferences)
			_fireCallbacks(Sender, table.unpack(Args, 1, Args.n))
		end

		if IsParallel then
			task.synchronize()
		end
	end)

	self._onUnrServerEvent = self._unrRemoteEvent.OnServerEvent:Connect(function(Sender: Player, IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then
			return
		end

		if not next(OnServerEventCallbacksUnr) and not next(WaitingThreadsUnr) then
			return
		end

		if IsParallel then
			task.desynchronize()
		end

		debug.profilebegin("SwitchNet.Server Incoming Packets Job (Unreliable)")

		for _, Packet: NetworkPacket in IncomingData do
			if not VerifyNetworkPacketIntegrity(Packet) then
				if IsParallel then
					task.synchronize()
				end

				return
			end

			local Data: buffer = Packet.Data
			local References: { any } = Packet.References

			local RealReferences: Bitstream.NBasedArray = References :: Bitstream.NBasedArray
			RealReferences.n = #RealReferences
			
			local Args: Bitstream.NBasedArray = Read(Data, RealReferences)
			_fireCallbacksUnr(Sender, table.unpack(Args, 1, Args.n))
		end

		debug.profileend()

		if IsParallel then
			task.synchronize()
		end
	end)

	self._replicationHandler = RunService.PostSimulation[if IsParallel then "ConnectParallel" else "Connect"](RunService.PostSimulation, function()
		debug.profilebegin("SwitchNet.Server Outgoing Packets Job")

		--// Per-player stacks
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

			if IsParallel then
				task.synchronize()
			end

			Remote:FireClient(Player, NetworkPackets)

			if IsParallel then
				task.desynchronize()
			end
		end

		table.clear(_playerSendStack)

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

			if IsParallel then
				task.synchronize()
			end

			UnreliableRemote:FireClient(Player, NetworkPackets)

			if IsParallel then
				task.desynchronize()
			end
		end

		table.clear(_playerSendStackUnr)

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

			if IsParallel then
				task.synchronize()
			end

			Remote:FireAllClients(NetworkPackets)

			if IsParallel then
				task.desynchronize()
			end
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

			if IsParallel then
				task.synchronize()
			end

			UnreliableRemote:FireAllClients(NetworkPackets)

			if IsParallel then
				task.desynchronize()
			end
		end

		debug.profileend()
	end)

	self._remoteFunction.OnServerInvoke = function(Sender: Player, IncomingData: NetworkPacket)
		if not self._onServerInvokeCallback then
			return nil
		end

		if IsParallel then
			task.desynchronize()
		end

		local Results: Bitstream.NBasedArray

		if IncomingData then
			if not VerifyNetworkPacketIntegrity(IncomingData) then
				if IsParallel then
					task.synchronize()
				end

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
			if IsParallel then
				task.synchronize()
			end

			return nil
		end

		local Success: boolean, Buffer: buffer, References: Bitstream.NBasedArray = pcall(Create, Results, GetSizeOfValues(Results))

		if IsParallel then
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

function Server.Destroy(self: Server)
	ACTIVE_REMOTES[self.Name] = nil
	
	self._replicationHandler:Disconnect()
	self._onUnrServerEvent:Disconnect()
	self._onServerEvent:Disconnect()

	self._remoteContainer:Destroy()
	--// ^ also destroys the remote events

	--// Free yielding threads (in-case they are still present)
	for Thread: thread in self._waitingThreads do
		pcall(task.spawn, Thread)
	end

	for Thread: thread in self._waitingThreadsUnr do
		pcall(task.spawn, Thread)
	end

	table.clear(self._waitingThreads)
	table.clear(self._waitingThreadsUnr)
	
	table.clear(self._onServerEventCallbacks)
	table.clear(self._onServerEventCallbacksUnr)
	table.clear(self._playerSendStack)
	table.clear(self._playerSendStackUnr)
	table.clear(self._globalSendStack)
	table.clear(self._globalSendStackUnr)
	
	table.clear(self)

	self = nil :: never
end

function Server.Wait(self: Server): ...any
	local Thread: thread = coroutine.running()

	self._waitingThreads[Thread] = true
	
	return coroutine.yield()
end

function Server.WaitUnreliable(self: Server): ...any
	local Thread: thread = coroutine.running()

	self._waitingThreadsUnr[Thread] = true
	
	return coroutine.yield()
end

--// TODO: Make seperated functions for binding to asnyc calls?
function Server.Connect(self: Server, Name: string, Function: (Player, ...any) -> ())
	self._onServerEventCallbacks[Name] = Function
end

function Server.ConnectUnreliable(self: Server, Name: string, Function: (Player, ...any) -> ())
	self._onServerEventCallbacksUnr[Name] = Function
end

function Server.Disconnect(self: Server, Name: string)
	self._onServerEventCallbacks[Name] = nil
end

function Server.DisconnectUnreliable(self: Server, Name: string)
	self._onServerEventCallbacksUnr[Name] = nil
end

function Server.SetOnInvoke(self: Server, Function: (Player, ...any) -> ...any)
	self._onServerInvokeCallback = Function
end

function Server.FireClient(self: Server, Player: Player, ...: any)
	if self._parallel then
		task.desynchronize()
	end

	local Data: Bitstream.NBasedArray = table.pack(...)

	local SendStack: { [Player]: { SendPacket } } = self._playerSendStack
	local Stack: { SendPacket } = SendStack[Player]

	if not Stack then
		Stack = {} :: { SendPacket }
		SendStack[Player] = Stack
	end

	table.insert(Stack, {
		Size = GetSizeOfValues(Data),
		Data = if USE_DEEP_COPY then DeepClone(Data) else Data,
	})

	if self._parallel then
		task.synchronize()
	end
end

function Server.FireClientUnreliable(self: Server, Player: Player, ...: any)
	if self._parallel then
		task.desynchronize()
	end
	
	local Data: Bitstream.NBasedArray = table.pack(...)

	local SendStack: { [Player]: { SendPacket } } = self._playerSendStackUnr
	local Stack: { SendPacket } = SendStack[Player]

	if not Stack then
		Stack = {} :: { SendPacket }
		SendStack[Player] = Stack
	end

	table.insert(Stack, {
		Size = GetSizeOfValues(Data),
		Data = if USE_DEEP_COPY then DeepClone(Data) else Data,
	})

	if self._parallel then
		task.synchronize()
	end
end

function Server.FireAllClients(self: Server, ...: any)
	if self._parallel then
		task.desynchronize()
	end

	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._globalSendStack, {
		Size = GetSizeOfValues(Data),
		Data = if USE_DEEP_COPY then DeepClone(Data) else Data,
	})

	if self._parallel then
		task.synchronize()
	end
end

function Server.FireAllClientsUnreliable(self: Server, ...: any)
	if self._parallel then
		task.desynchronize()
	end

	local Data: Bitstream.NBasedArray = table.pack(...)

	table.insert(self._globalSendStackUnr, {
		Size = GetSizeOfValues(Data),
		Data = if USE_DEEP_COPY then DeepClone(Data) else Data,
	})

	if self._parallel then
		task.synchronize()
	end
end

function Server.InvokeClient(self: Server, Player: Player, ...: any): ...any
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

		ResponsePacket = self._remoteFunction:InvokeClient(Player, {
			Data = Data,
			References = References,
			ReferenceCount = References.n,
		})
	end)

	if self._parallel then
		task.desynchronize()
	end

	if not Success then
		TestService:Error(`SwitchNet.Server '{self.Name}' InvokeClient failed! Error:\n{Error}`)
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

	if self._parallel then
		task.synchronize()
	end

	return table.unpack(Response, 1, Response.n)
end

return Server