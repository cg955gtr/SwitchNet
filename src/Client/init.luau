--[==[
	Author: 8ch99
	File: Client.luau
	Date written: 15th November 2025
	Last edited: 23rd March 2026
]==]

--!strict
--!native
--!optimize 2

local ACTIVE_REMOTES = {}
local USE_DEEP_COPY = true

--// Services

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

--// Dependencies

local Bitstream = require("./Bitstream")

local Create = Bitstream.Create
local Read = Bitstream.Read
local GetSizeOfValues = Bitstream._getSizeOfValues

local function DeepClone(t: { [any]: any }): { [any]: any }
	local clone = {}
	for index, value in t do
		clone[index] = if type(value) == "table" then DeepClone(value) else value
	end
	return clone
end

local function VerifyNetworkPacketIntegrity(packet: NetworkPacket): boolean
	return packet and type(packet) == "table" and type(packet.Data) == "buffer" and type(packet.References) == "table"
end

local function GetCallingScript(): Instance?
	local source = debug.info(3, "s")
	if source == "" then return nil end

	local current: Instance? = game
	for _, name in string.split(source, ".") do
		current = (current :: Instance):FindFirstChild(name)
		if not current then
			return nil
		end
	end

	if current == game then return end

	return current
end

--// Typedefs

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

--// @module Client

local Client = {}

function Client.new(Name: string): Client
	assert(ACTIVE_REMOTES[Name] == nil, `Remote bridge '{Name}' already exists!`)
	assert(RunService:IsClient(), "This is a client-only function!")

	--// Verify its a actual remote bridge
	local remoteContainer = ReplicatedStorage:WaitForChild(Name)
	assert(remoteContainer and remoteContainer:IsA("Folder"), `Remote bridge '{Name}' is invalid! Container is not a folder/does not exist.`)
	
	local remote = remoteContainer:WaitForChild("Reliable") :: RemoteEvent
	local unreliableRemote = remoteContainer:WaitForChild("Unreliable") :: UnreliableRemoteEvent
	local remoteFunction = remoteContainer:WaitForChild("Function") :: RemoteFunction

	assert(remote and remote:IsA("RemoteEvent"), `Remote bridge '{Name}' is invalid! RemoteEvent is not a RemoteEvent/does not exist.`)
	assert(unreliableRemote and unreliableRemote:IsA("UnreliableRemoteEvent"), `Remote bridge '{Name}' is invalid! UnreliableRemoteEvent is not a UnreliableRemoteEvent/does not exist.`)
	assert(remoteFunction and remoteFunction:IsA("RemoteFunction"), `Remote bridge '{Name}' is invalid! RemoteFunction is not a RemoteFunction/does not exist.`)

	ACTIVE_REMOTES[Name] = true

	local callingScript = GetCallingScript()
	local hasActor = if callingScript then callingScript:FindFirstAncestorOfClass("Actor") ~= nil else false

	local self = {
		Name = Name,

		_parallel = hasActor,

		_onClientEventCallbacks = {} :: { [string]: (...any) -> () },
		_onClientEventCallbacksUnr = {} :: { [string]: (...any) -> () },

		_sendStack = {} :: { SendPacket },
		_sendStackUnr = {} :: { SendPacket },

		_waitingThreads = {} :: { [thread]: boolean },
		_waitingThreadsUnr = {} :: { [thread]: boolean },

		_remoteContainer = remoteContainer,
		_remoteEvent = remote,
		_unrRemoteEvent = unreliableRemote,
		_remoteFunction = remoteFunction,
	} :: Client


	local _sendStack = self._sendStack
	local _sendStackUnr = self._sendStackUnr

	local onClientEventCallbacks = self._onClientEventCallbacks
	local onClientEventCallbacksUnr = self._onClientEventCallbacksUnr
	local waitingThreads = self._waitingThreads
	local waitingThreadsUnr = self._waitingThreadsUnr

	local isParallel = self._parallel

	--// Internal functions for firing callbacks without using unpack() too many times
	local function _fireCallbacks(...: any)
		for thread in waitingThreads do
			coroutine.resume(thread, ...)
		end

		table.clear(waitingThreads)

		for name, callback in onClientEventCallbacks do
			local success, result = pcall(task.spawn, callback, ...)
			if not success then
				TestService:Error(`SwitchNet.Client '{self.Name}' Callback '{name}' Error:\n{result}`)
			end
		end
	end

	local function _fireCallbacksUnr(...: any)
		for thread in waitingThreadsUnr do
			coroutine.resume(thread, ...)
		end

		table.clear(waitingThreadsUnr)

		for name, callback in onClientEventCallbacksUnr do
			local Success: boolean, Error: any = pcall(task.spawn, callback, ...)
			if not Success then
				TestService:Error(`SwitchNet.Client '{self.Name}' (UNRELIABLE) Callback '{name}' Error:\n{Error}`)
			end
		end
	end


	self._onClientEvent = self._remoteEvent.OnClientEvent:Connect(function(incomingData: { NetworkPacket })
		if type(incomingData) ~= "table" then return end
		if not next(onClientEventCallbacks) and not next(waitingThreads) then return end

		if isParallel then
			task.desynchronize()
		end

		debug.profilebegin("SwitchNet.Client Incoming Packets Job")

		for _, packet in incomingData do
			if not VerifyNetworkPacketIntegrity(packet) then
				if isParallel then
					task.synchronize()
				end

				return
			end

			local references = packet.References :: Bitstream.NBasedArray
			references.n = #references
			
			local args = Read(packet.Data, references)
			_fireCallbacks(table.unpack(args, 1, args.n))
		end

		debug.profileend()

		if isParallel then
			task.synchronize()
		end
	end)

	self._onUnrClientEvent = self._unrRemoteEvent.OnClientEvent:Connect(function(IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then return end
		if not next(onClientEventCallbacksUnr) and not next(waitingThreadsUnr) then return end

		if isParallel then
			task.desynchronize()
		end

		debug.profilebegin("SwitchNet.Client Incoming Packets Job (Unreliable)")

		for _, packet in IncomingData do
			if not VerifyNetworkPacketIntegrity(packet) then
				if isParallel then
					task.synchronize()
				end

				return
			end

			local references = packet.References :: Bitstream.NBasedArray
			references.n = #references
			
			local args = Read(packet.Data, references)
			_fireCallbacksUnr(table.unpack(args, 1, args.n))
		end

		debug.profileend()

		if isParallel then
			task.synchronize()
		end
	end)



	local function OutgoingPacketsJobHandler()
		debug.profilebegin("SwitchNet.Client Outgoing Packets Job")

		if #_sendStack > 0 then
			local networkPackets = {}

			for _, packet in _sendStack do
				local buff, references = Create(packet.Data, packet.Size)
				table.insert(networkPackets, {
					Data = buff,
					References = references,
				})
			end

			table.clear(_sendStack)

			if isParallel then
				task.synchronize()
			end
	
			remote:FireServer(networkPackets)

			if isParallel then
				task.desynchronize()
			end
		end

		if #_sendStackUnr > 0 then
			local networkPackets = {}

			for _, packet in _sendStackUnr do
				local buff, references = Create(packet.Data, packet.Size)
				table.insert(networkPackets, {
					Data = buff,
					References = references,
				})
			end

			table.clear(_sendStackUnr)

			if isParallel then
				task.desynchronize()
			end
	
			unreliableRemote:FireServer(networkPackets)

			if isParallel then
				task.synchronize()
			end
		end

		debug.profileend()
	end

	if isParallel then
		self._replicationHandler = RunService.PostSimulation:ConnectParallel(OutgoingPacketsJobHandler)
	else
		self._replicationHandler = RunService.PostSimulation:Connect(OutgoingPacketsJobHandler)
	end



	self._remoteFunction.OnClientInvoke = function(incomingData: NetworkPacket): { Data: buffer, References: Bitstream.NBasedArray }?
		if not self._onClientInvokeCallback then return nil end

		if isParallel then
			task.desynchronize()
		end

		local results: Bitstream.NBasedArray

		if incomingData then
			if not VerifyNetworkPacketIntegrity(incomingData) then
				if isParallel then
					task.synchronize()
				end

				return
			end

			local references = incomingData.References :: Bitstream.NBasedArray
			references.n = #references

			local success, args = pcall(Read, incomingData.Data, references)

			if success then
				results = table.pack(pcall(self._onClientInvokeCallback, table.unpack(args, 1, args.n)))
				results.n -= 1
				if table.remove(results, 1) == false then
					results = { n = 0 }
				end
			end
		end

		if not results or results.n == 0 then
			if isParallel then
				task.synchronize()
			end

			return nil
		end
		
		local size = GetSizeOfValues(results)
		local success, buff, references = pcall(Create, results, size)

		if isParallel then
			task.synchronize()
		end

		if not success then return nil end

		return { Data = buff, References = references }
	end

	return self
end

function Client.Destroy(self: Client)
	ACTIVE_REMOTES[self.Name] = nil
	
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
	local thread = coroutine.running()
	self._waitingThreads[thread] = true
	return coroutine.yield()
end

function Client.WaitUnreliable(self: Client): ...any
	local thread = coroutine.running()
	self._waitingThreadsUnr[thread] = true
	return coroutine.yield()
end



function Client.Connect(self: Client, name: string, callback: (...any) -> ())
	self._onClientEventCallbacks[name] = callback
end

function Client.ConnectUnreliable(self: Client, name: string, callback: (...any) -> ())
	self._onClientEventCallbacksUnr[name] = callback
end

function Client.Disconnect(self: Client, name: string)
	self._onClientEventCallbacks[name] = nil
end

function Client.DisconnectUnreliable(self: Client, name: string)
	self._onClientEventCallbacksUnr[name] = nil
end

function Client.SetOnInvoke(self: Client, callback: (...any) -> ...any)
	self._onClientInvokeCallback = callback
end



function Client.FireServer(self: Client, ...: any)
	if self._parallel then
		task.desynchronize()
	end

	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	table.insert(self._sendStack, {
		Size = size,
		Data = if USE_DEEP_COPY then DeepClone(data) else data,
	})

	if self._parallel then
		task.synchronize()
	end
end

function Client.FireServerUnreliable(self: Client, ...: any)
	if self._parallel then
		task.desynchronize()
	end

	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	table.insert(self._sendStackUnr, {
		Size = size,
		Data = if USE_DEEP_COPY then DeepClone(data) else data,
	})

	if self._parallel then
		task.synchronize()
	end
end



function Client.InvokeServer(self: Client, ...: any): ...any
	if self._parallel then
		task.desynchronize()
	end

	local sendData = table.pack(...)
	local bufferSize = GetSizeOfValues(sendData)
	local buff, references = Create(sendData, bufferSize)
	local responsePacket: NetworkPacket

	local success, result = pcall(function()
		if self._parallel then
			task.synchronize()
		end
		
		responsePacket = self._remoteFunction:InvokeServer({
			Data = buff,
			References = references,
			ReferenceCount = references.n,
		})
	end)

	if self._parallel then
		task.desynchronize()
	end

	if not success then
		TestService:Error(`SwitchNet.Client '{self.Name}' InvokeServer failed! Error:\n{result}`)
		return nil
	end

	if responsePacket == nil then return nil end
	if not VerifyNetworkPacketIntegrity(responsePacket) then return nil end

	local responseReferences = responsePacket.References :: Bitstream.NBasedArray
	responseReferences.n = #responseReferences

	local response = Read(responsePacket.Data, responseReferences)

	if self._parallel then
		task.synchronize()
	end

	return table.unpack(response, 1, response.n)
end

return Client