--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

const DEBUG_PROFILING: boolean = true
const ACTIVE_REMOTES: { [string]: boolean } = {}

--// Services

const RunService = game:GetService("RunService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const TestService = game:GetService("TestService")

--// Dependencies

const Stream = require("./Stream")
const Typedefs = require("./Typedefs")
const FilterContainer = require("./FilterContainer")

const readStream = Stream.Read
const createPacket = Stream.CreatePacket
const createPacketFromArgs = Stream.CreatePacketFromArgs

local function verifyNetworkPacket(packet: NetworkPacket): boolean
	return packet and type(packet) == "table" and type(packet.Data) == "buffer" and type(packet.References) == "table"
end


local function profilebegin(label: string): ()
	if DEBUG_PROFILING then
		debug.profilebegin(label)
	end
end

local function profileend(): ()
	if DEBUG_PROFILING then
		debug.profileend()
	end
end

--// Typedefs

type Client = Typedefs.Client

type NBasedArray = Typedefs.NBasedArray
type NetworkPacket = Typedefs.NetworkPacket
type RequestType = Typedefs.RequestType

--// @module Client

const Client = {}



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

		_filter = FilterContainer.new(),
		_preProcessFilter = FilterContainer.new(),

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


	local sendStack: { NetworkPacket } = self._sendStack
	local sendStackUnr: { NetworkPacket } = self._sendStackUnr

	local onClientEventCallbacks: { [string]: (...any) -> () } = self._onClientEventCallbacks
	local onClientEventCallbacksUnr: { [string]: (...any) -> () } = self._onClientEventCallbacksUnr
	local waitingThreads: { [thread]: boolean } = self._waitingThreads
	local waitingThreadsUnr: { [thread]: boolean } = self._waitingThreadsUnr


	--// Internal functions for firing callbacks without using unpack() too many times
	local function fireCallbacks(...: any)

		if not self._filter:Check("Reliable", ...) then return end

		for thread: thread in waitingThreads do
			coroutine.resume(thread, ...)
		end
		table.clear(waitingThreads)

		for name: string, callback: (...any) -> () in onClientEventCallbacks do
			local success: boolean, result: thread | string = pcall(task.spawn, callback, ...)
			if not success then
				TestService:Error(`SwitchNet.Client '{self.Name}' Callback '{name}' Error:\n{result :: string}`)
			end
		end

	end

	local function fireCallbacksUnr(...: any)

		if not self._filter:Check("Unreliable", ...) then return end
		
		for thread: thread in waitingThreadsUnr do
			coroutine.resume(thread, ...)
		end
		table.clear(waitingThreadsUnr)

		for name: string, callback: (...any) -> () in onClientEventCallbacksUnr do
			local success: boolean, result: thread | string = pcall(task.spawn, callback, ...)
			if not success then
				TestService:Error(`SwitchNet.Client '{self.Name}' (UNRELIABLE) Callback '{name}' Error:\n{result :: string}`)
			end
		end
		
	end

	

	self._onClientEvent = self._remoteEvent.OnClientEvent:Connect(function(incomingData: { NetworkPacket })
		
		if type(incomingData) ~= "table" then return end
		if not next(onClientEventCallbacks) and not next(waitingThreads) then return end

		profilebegin("SwitchNet.Client Incoming Packets Job")

		for _, packet in incomingData do
			if not verifyNetworkPacket(packet) then return end
			if not self._preProcessFilter:Check("Reliable" :: RequestType, packet.Data, packet.References) then return end

			local args: NBasedArray = readStream(packet.Data, packet.References)
			fireCallbacks(table.unpack(args, 1, args.n))
		end

		profileend()

	end)

	self._onUnrClientEvent = self._unrRemoteEvent.OnClientEvent:Connect(function(IncomingData: { NetworkPacket })
		
		if type(IncomingData) ~= "table" then return end
		if not next(onClientEventCallbacksUnr) and not next(waitingThreadsUnr) then return end

		profilebegin("SwitchNet.Client Incoming Packets Job (Unreliable)")

		for _, packet in IncomingData do
			if not verifyNetworkPacket(packet) then return end
			if not self._preProcessFilter:Check("Unreliable" :: RequestType, packet.Data, packet.References) then return end

			local args: NBasedArray = readStream(packet.Data, packet.References)
			fireCallbacksUnr(table.unpack(args, 1, args.n))
		end

		profileend()

	end)


	
	self._replicationHandler = RunService.PostSimulation:Connect(function()
		
		if #sendStack > 0 then
			remote:FireServer(sendStack)
			table.clear(sendStack)
		end

		if #sendStackUnr > 0 then
			unreliableRemote:FireServer(sendStackUnr)
			table.clear(sendStackUnr)
		end

	end)



	self._remoteFunction.OnClientInvoke = function(incomingData: NetworkPacket): NetworkPacket?
		
		if not self._onClientInvokeCallback then return nil end
		if not verifyNetworkPacket(incomingData) then return nil end
		if not self._preProcessFilter:Check("Request" :: RequestType, incomingData.Data, incomingData.References) then return nil end

		local results: NBasedArray
		if incomingData then
			if not verifyNetworkPacket(incomingData) then return nil end

			local success: boolean, args: NBasedArray = pcall(readStream, incomingData.Data, incomingData.References)
			if success then
				results = table.pack(pcall(function(...: any)
					if not self._onClientInvokeCallback then return nil end --// double checked to avoid type error
					if not self._filter:Check("Request" :: RequestType, ...) then return nil end
					return self._onClientInvokeCallback(...)
				end, table.unpack(args, 1, args.n)))

				results.n -= 1
				if table.remove(results, 1) == false then
					results = { n = 0 }
				end
			end
		end

		if not results or results.n == 0 then return nil end

		local createSuccess: boolean, packet: NetworkPacket = pcall(createPacket, results)
		if not createSuccess then return nil end

		return packet

	end



	return self

end

function Client.Destroy(self: Client)

	ACTIVE_REMOTES[self.Name] = nil

	--// Free yielding threads (in-case they are still present)
	for thread: thread in self._waitingThreads do
		coroutine.resume(thread, nil)
	end

	for thread: thread in self._waitingThreadsUnr do
		coroutine.resume(thread, nil)
	end
	
	self._replicationHandler:Disconnect()
	self._onUnrClientEvent:Disconnect()
	self._onClientEvent:Disconnect()

	self._preProcessFilter:Destroy()
	self._filter:Destroy()

	table.clear(self._onClientEventCallbacks)
	table.clear(self._sendStack)
	table.clear(self._sendStackUnr)
	
	table.clear(self)

	self = nil :: never

end



function Client.Wait(self: Client): ...any
	local thread: thread = coroutine.running()
	self._waitingThreads[thread] = true
	return coroutine.yield()
end

function Client.WaitUnreliable(self: Client): ...any
	local thread: thread = coroutine.running()
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
	local packet: NetworkPacket = createPacketFromArgs(...)
	table.insert(self._sendStack, packet)
end

function Client.FireServerUnreliable(self: Client, ...: any)
	local packet: NetworkPacket = createPacketFromArgs(...)
	table.insert(self._sendStackUnr, packet)
end



function Client.InvokeServer(self: Client, ...: any): ...any
	
	local packet: NetworkPacket = createPacketFromArgs(...)
	local responsePacket: NetworkPacket

	local success: boolean, result: any = pcall(function()
		responsePacket = self._remoteFunction:InvokeServer(packet)
	end)

	if not success then
		TestService:Error(`SwitchNet.Client '{self.Name}' InvokeServer failed! Error:\n{result}`)
		return nil
	end

	if responsePacket == nil then return nil end
	if not verifyNetworkPacket(responsePacket) then return nil end

	local response: NBasedArray = readStream(responsePacket.Data, responsePacket.References)
	return table.unpack(response, 1, response.n)

end



function Client.AddFilter(self: Client, name: string, callback: (RequestType, ...any) -> boolean, priority: number?)
	self._filter:AddFilter(name, callback, priority)
end

function Client.RemoveFilter(self: Client, name: string)
	self._filter:RemoveFilter(name)
end



function Client.AddPreProcessFilter(self: Client, name: string, callback: (RequestType, buffer, { any }) -> boolean, priority: number?)
	self._preProcessFilter:AddFilter(name, callback, priority)
end

function Client.RemovePreProcessFilter(self: Client, name: string)
	self._preProcessFilter:RemoveFilter(name)
end



return Client