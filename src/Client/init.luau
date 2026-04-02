--[==[
	Author: 8ch99
	File: Client.luau
	Date written: 15th November 2025
	Last edited: 2nd April 2026
]==]

--!strict
--!native
--!optimize 2

local ACTIVE_REMOTES = {}

--// Services

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

export type Client = {
	Name: string,

	_onClientInvokeCallback: ((...any) -> ...any)?,

	_onClientEventCallbacks: { [string]: (...any) -> () },
	_onClientEventCallbacksUnr: { [string]: (...any) -> () },

	_waitingThreads: { [thread]: boolean },
	_waitingThreadsUnr: { [thread]: boolean },

	_sendStack: { NetworkPacket },
	_sendStackUnr: { NetworkPacket },

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

function Client.new(name: string): Client
	assert(ACTIVE_REMOTES[name] == nil, `Remote bridge '{name}' already exists!`)
	assert(RunService:IsClient(), "This is a client-only function!")

	--// Verify its a actual remote bridge
	local remoteContainer = ReplicatedStorage:WaitForChild(name)
	assert(remoteContainer and remoteContainer:IsA("Folder"), `Remote bridge '{name}' is invalid! Container is not a folder/does not exist.`)
	
	local remote = remoteContainer:WaitForChild("Reliable") :: RemoteEvent
	local unreliableRemote = remoteContainer:WaitForChild("Unreliable") :: UnreliableRemoteEvent
	local remoteFunction = remoteContainer:WaitForChild("Function") :: RemoteFunction

	assert(remote and remote:IsA("RemoteEvent"), `Remote bridge '{name}' is invalid! RemoteEvent is not a RemoteEvent/does not exist.`)
	assert(unreliableRemote and unreliableRemote:IsA("UnreliableRemoteEvent"), `Remote bridge '{name}' is invalid! UnreliableRemoteEvent is not a UnreliableRemoteEvent/does not exist.`)
	assert(remoteFunction and remoteFunction:IsA("RemoteFunction"), `Remote bridge '{name}' is invalid! RemoteFunction is not a RemoteFunction/does not exist.`)

	ACTIVE_REMOTES[name] = true


	local self = {
		Name = name,

		_onClientEventCallbacks = {} :: { [string]: (...any) -> () },
		_onClientEventCallbacksUnr = {} :: { [string]: (...any) -> () },

		_sendStack = {} :: { NetworkPacket },
		_sendStackUnr = {} :: { NetworkPacket },

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

		debug.profilebegin("SwitchNet.Client Incoming Packets Job")

		for _, packet in incomingData do
			if not VerifyNetworkPacketIntegrity(packet) then return end

			local args = Read(packet.Data, packet.References)
			_fireCallbacks(table.unpack(args, 1, args.n))
		end

		debug.profileend()
	end)

	self._onUnrClientEvent = self._unrRemoteEvent.OnClientEvent:Connect(function(IncomingData: { NetworkPacket })
		if type(IncomingData) ~= "table" then return end
		if not next(onClientEventCallbacksUnr) and not next(waitingThreadsUnr) then return end

		debug.profilebegin("SwitchNet.Client Incoming Packets Job (Unreliable)")

		for _, packet in IncomingData do
			if not VerifyNetworkPacketIntegrity(packet) then return end

			local args = Read(packet.Data, packet.References)
			_fireCallbacksUnr(table.unpack(args, 1, args.n))
		end

		debug.profileend()
	end)


	
	self._replicationHandler = RunService.PostSimulation:Connect(function()
		if #_sendStack > 0 then
			remote:FireServer(_sendStack)
			table.clear(_sendStack)
		end

		if #_sendStackUnr > 0 then
			unreliableRemote:FireServer(_sendStackUnr)
			table.clear(_sendStackUnr)
		end
	end)



	self._remoteFunction.OnClientInvoke = function(incomingData: NetworkPacket): NetworkPacket?
		if not self._onClientInvokeCallback then return nil end

		local results: Bitstream.NBasedArray
		if incomingData then
			if not VerifyNetworkPacketIntegrity(incomingData) then return end

			local success, args = pcall(Read, incomingData.Data, incomingData.References)
			if success then
				results = table.pack(pcall(self._onClientInvokeCallback, table.unpack(args, 1, args.n)))
				results.n -= 1
				if table.remove(results, 1) == false then
					results = { n = 0 }
				end
			end
		end

		if not results or results.n == 0 then return nil end
		
		local size = GetSizeOfValues(results)
		local success, buff, references = pcall(Create, results, size)

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
	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	table.insert(self._sendStack, {
		Data = buff,
		References = references,
	})
end

function Client.FireServerUnreliable(self: Client, ...: any)
	local data = table.pack(...)
	local size = GetSizeOfValues(data)
	local buff, references = Create(data, size)
	table.insert(self._sendStackUnr, {
		Data = buff,
		References = references,
	})
end



function Client.InvokeServer(self: Client, ...: any): ...any
	local sendData = table.pack(...)
	local bufferSize = GetSizeOfValues(sendData)
	local buff, references = Create(sendData, bufferSize)
	local responsePacket: NetworkPacket

	local success, result = pcall(function()
		responsePacket = self._remoteFunction:InvokeServer({
			Data = buff,
			References = references,
		})
	end)

	if not success then
		TestService:Error(`SwitchNet.Client '{self.Name}' InvokeServer failed! Error:\n{result}`)
		return nil
	end

	if responsePacket == nil then return nil end
	if not VerifyNetworkPacketIntegrity(responsePacket) then return nil end

	local response = Read(responsePacket.Data, responsePacket.References)
	return table.unpack(response, 1, response.n)
end

return Client