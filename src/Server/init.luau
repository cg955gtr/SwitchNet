--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

local ACTIVE_REMOTES = {}

--// Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

--// Dependencies

local Bitstream = require("./Bitstream")

local Create = Bitstream.Create
local Read = Bitstream.Read
local GetSizeOfValues = Bitstream._getSizeOfValues

local function VerifyNetworkPacketIntegrity(packet: NetworkPacket): boolean
	return packet and type(packet) == "table" and type(packet.Data) == "buffer" and type(packet.References) == "table"
end

--// Typedefs

type NBasedArray = Bitstream.NBasedArray

type NetworkPacket = {
	Data: buffer,
	References: { any },
}

export type Server = {
	Name: string,

	_onServerInvokeCallback: ((Player, ...any) -> ...any)?,

	_onServerEventCallbacks: { [string]: (Player, ...any) -> () },
	_onServerEventCallbacksUnr: { [string]: (Player, ...any) -> () },

	_playerSendStack: { [Player]: { NetworkPacket } },
	_playerSendStackUnr: { [Player]: { NetworkPacket } },
	_globalSendStack: { NetworkPacket },
	_globalSendStackUnr: { NetworkPacket },

	_waitingThreads: { [thread]: boolean },
	_waitingThreadsUnr: { [thread]: boolean },

	_remoteContainer: Folder,
	
	_remoteEvent: RemoteEvent,
	_unrRemoteEvent: UnreliableRemoteEvent,
	_remoteFunction: RemoteFunction,

	_onServerEvent: RBXScriptConnection,
	_onUnrServerEvent: RBXScriptConnection,
	_replicationHandler: RBXScriptConnection,

	_playerLeaving: RBXScriptConnection,
}


--// @module Server

local Server = {}

function Server.new(name: string): Server
	assert(ACTIVE_REMOTES[name] == nil, `remote bridge '{name}' already exists!`)
	assert(ReplicatedStorage:FindFirstChild(name) == nil, `RS has an instance with the same name already! Use a different name to '{name}'.`)
	assert(RunService:IsServer(), "This is a server-only function!")

	ACTIVE_REMOTES[name] = true

	local self = {
		Name = name,

		_waitingThreads = {} :: { [thread]: boolean },
		_waitingThreadsUnr = {} :: { [thread]: boolean },

		_onServerEventCallbacks = {} :: { [string]: (Player, ...any) -> () },
		_onServerEventCallbacksUnr = {} :: { [string]: (Player, ...any) -> () },

		_playerSendStack = {} :: { [Player]: { NetworkPacket } },
		_playerSendStackUnr = {} :: { [Player]: { NetworkPacket } },
		_globalSendStack = {} :: { NetworkPacket },
		_globalSendStackUnr = {} :: { NetworkPacket },

		_remoteContainer = Instance.new("Folder") :: Folder,
		_remoteEvent = Instance.new("RemoteEvent") :: RemoteEvent,
		_unrRemoteEvent = Instance.new("UnreliableRemoteEvent") :: UnreliableRemoteEvent,
		_remoteFunction = Instance.new("RemoteFunction") :: RemoteFunction,
	} :: Server


	self._remoteContainer.Name = name
	self._remoteEvent.Name = "Reliable"
	self._unrRemoteEvent.Name = "Unreliable"
	self._remoteFunction.Name = "Function"

	self._remoteEvent.Parent = self._remoteContainer
	self._unrRemoteEvent.Parent = self._remoteContainer
	self._remoteFunction.Parent = self._remoteContainer

	self._remoteContainer.Parent = ReplicatedStorage


	--// Setup main handlers

	local remote = self._remoteEvent
	local unreliableRemote = self._unrRemoteEvent
	
	local _globalSendStack = self._globalSendStack
	local _globalSendStackUnr = self._globalSendStackUnr
	local _playerSendStack = self._playerSendStack
	local _playerSendStackUnr = self._playerSendStackUnr

	local onServerEventCallbacks = self._onServerEventCallbacks
	local onServerEventCallbacksUnr = self._onServerEventCallbacksUnr
	local waitingThreads = self._waitingThreads
	local waitingThreadsUnr = self._waitingThreadsUnr


	self._playerLeaving = Players.PlayerRemoving:Connect(function(player: Player)

		--// Event here to replace the parent checks in the replication handlers
		--// So we don't have to check player.Parent for everyone

		if _playerSendStack[player] then
			_playerSendStack[player] = nil
		end

		if _playerSendStackUnr[player] then
			_playerSendStackUnr[player] = nil
		end

	end)


	--// Internal functions for firing callbacks without using unpack() too many times
	local function _fireCallbacks(player: Player, ...: any)
		for thread in waitingThreads do
			coroutine.resume(thread, player, ...)
		end

		table.clear(waitingThreads)

		for name, callback in onServerEventCallbacks do
			local success, result = pcall(task.spawn, callback, player, ...)
			if not success then
				TestService:Error(`SwitchNet.Server '{self.Name}' Callback '{name}' Error:\n{result}`)
			end
		end
	end

	local function _fireCallbacksUnr(player: Player, ...: any)
		for thread in waitingThreadsUnr do
			coroutine.resume(thread, player, ...)
		end

		table.clear(waitingThreadsUnr)

		for name, callback in onServerEventCallbacksUnr do
			local Success: boolean, Error: any = pcall(task.spawn, callback, player, ...)
			if not Success then
				TestService:Error(`SwitchNet.Server '{self.Name}' (UNRELIABLE) Callback '{name}' Error:\n{Error}`)
			end
		end
	end


	self._onServerEvent = self._remoteEvent.OnServerEvent:Connect(function(player: Player, incomingData: { NetworkPacket })
		if type(incomingData) ~= "table" then return end
		if not next(onServerEventCallbacks) and not next(waitingThreads) then return end

		debug.profilebegin("SwitchNet.Server Incoming Packets Job")
		
		for _, packet in incomingData do
			if not VerifyNetworkPacketIntegrity(packet) then return end
			
			local args = Read(packet.Data, packet.References)
			_fireCallbacks(player, table.unpack(args, 1, args.n))
		end
	end)

	self._onUnrServerEvent = self._unrRemoteEvent.OnServerEvent:Connect(function(player: Player, incomingData: { NetworkPacket })
		if type(incomingData) ~= "table" then return end
		if not next(onServerEventCallbacksUnr) and not next(waitingThreadsUnr) then return end

		debug.profilebegin("SwitchNet.Server Incoming Packets Job (Unreliable)")

		for _, packet in incomingData do
			if not VerifyNetworkPacketIntegrity(packet) then return end
			
			local args = Read(packet.Data, packet.References)
			_fireCallbacksUnr(player, table.unpack(args, 1, args.n))
		end

		debug.profileend()
	end)



	self._replicationHandler = RunService.PostSimulation:Connect(function()
		--// Per-player stacks
		for player, packets in _playerSendStack do
			remote:FireClient(player, packets)
		end
		table.clear(_playerSendStack)

		for player, packets in _playerSendStackUnr do
			unreliableRemote:FireClient(player, packets)
		end
		table.clear(_playerSendStackUnr)

		--// Global stacks (FireAllClients)
		if #_globalSendStack > 0 then
			remote:FireAllClients(_globalSendStack)
			table.clear(_globalSendStack)
		end

		if #_globalSendStackUnr > 0 then
			unreliableRemote:FireAllClients(_globalSendStackUnr)
			table.clear(_globalSendStackUnr)
		end
	end)


	self._remoteFunction.OnServerInvoke = function(player: Player, incomingData: NetworkPacket): NetworkPacket?
		if not self._onServerInvokeCallback then return nil end
		if not VerifyNetworkPacketIntegrity(incomingData) then return nil end
		
		local results: NBasedArray
		local success, args = pcall(Read, incomingData.Data, incomingData.References)
		if success then
			results = table.pack(pcall(self._onServerInvokeCallback, player, table.unpack(args, 1, args.n)))
			results.n -= 1
			if table.remove(results, 1) == false then
				results = { n = 0 }
			end
		end

		if not results or results.n == 0 then return nil end

		local size = GetSizeOfValues(results)
		local createSuccess, buff, references = pcall(Create, results, size)

		if not createSuccess then return nil end

		return { Data = buff, References = references }
	end

	return self
end

function Server.Destroy(self: Server)
	ACTIVE_REMOTES[self.Name] = nil
	
	self._playerLeaving:Disconnect()
	self._replicationHandler:Disconnect()
	self._onUnrServerEvent:Disconnect()
	self._onServerEvent:Disconnect()

	self._remoteContainer:Destroy()
	--// ^ also destroys the remote events

	--// Free yielding threads (in-case they are still present)
	for thread in self._waitingThreads do
		coroutine.resume(thread)
	end

	for thread in self._waitingThreadsUnr do
		coroutine.resume(thread)
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
	local thread = coroutine.running()
	self._waitingThreads[thread] = true
	return coroutine.yield()
end

function Server.WaitUnreliable(self: Server): ...any
	local thread = coroutine.running()
	self._waitingThreadsUnr[thread] = true
	return coroutine.yield()
end



function Server.Connect(self: Server, name: string, callback: (Player, ...any) -> ())
	self._onServerEventCallbacks[name] = callback
end

function Server.ConnectUnreliable(self: Server, name: string, callback: (Player, ...any) -> ())
	self._onServerEventCallbacksUnr[name] = callback
end

function Server.Disconnect(self: Server, name: string)
	self._onServerEventCallbacks[name] = nil
end

function Server.DisconnectUnreliable(self: Server, name: string)
	self._onServerEventCallbacksUnr[name] = nil
end

function Server.SetOnInvoke(self: Server, callback: (Player, ...any) -> ...any)
	self._onServerInvokeCallback = callback
end



function Server.FireClient(self: Server, player: Player, ...: any)
	local sendStack = self._playerSendStack
	local stack = sendStack[player]

	if not stack then
		stack = {}
		sendStack[player] = stack
	end

	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	table.insert(stack, {
		Data = buff,
		References = references,
	})
end

function Server.FireClientUnreliable(self: Server, player: Player, ...: any)
	local sendStack = self._playerSendStackUnr
	local stack = sendStack[player]

	if not stack then
		stack = {}
		sendStack[player] = stack
	end

	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	table.insert(stack, {
		Data = buff,
		References = references,
	})
end



function Server.FireAllClients(self: Server, ...: any)
	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	table.insert(self._globalSendStack, {
		Data = buff,
		References = references,
	})
end

function Server.FireAllClientsUnreliable(self: Server, ...: any)
	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	table.insert(self._globalSendStackUnr, {
		Data = buff,
		References = references,
	})
end



function Server.FireAllClientsExcept(self: Server, exemptPlayer: Player, ...: any)
	local sendStacks = self._playerSendStack
	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	local packet: NetworkPacket = {
		Data = buff,
		References = references,
	}

	for _, player in Players:GetPlayers() do
		if exemptPlayer ~= player then
			local stack = sendStacks[player]
			if not stack then
				stack = {}
				sendStacks[player] = stack
			end
			table.insert(stack, packet)
		end
	end
end

function Server.FireAllClientsUnreliableExcept(self: Server, exemptPlayer: Player, ...: any)
	local sendStacks = self._playerSendStackUnr
	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	local packet: NetworkPacket = {
		Data = buff,
		References = references,
	}

	for _, player in Players:GetPlayers() do
		if exemptPlayer ~= player then
			local stack = sendStacks[player]
			if not stack then
				stack = {}
				sendStacks[player] = stack
			end
			table.insert(stack, packet)
		end
	end
end



function Server.InvokeClient(self: Server, player: Player, ...: any): ...any
	local sendData = table.pack(...)
	local bufferSize = GetSizeOfValues(sendData)
	local buff, references = Create(sendData, bufferSize)
	local responsePacket: NetworkPacket

	local success, result = pcall(function()
		responsePacket = self._remoteFunction:InvokeClient(player, {
			Data = buff,
			References = references,
		})
	end)

	if not success then
		TestService:Error(`SwitchNet.Server '{self.Name}' InvokeClient failed! Error:\n{result}`)
		return nil
	end

	if responsePacket == nil then return nil end
	if not VerifyNetworkPacketIntegrity(responsePacket) then return nil end

	local response = Read(responsePacket.Data, responsePacket.References)
	return table.unpack(response, 1, response.n)
end

return Server