--[==[
	Author: 8ch99
	File: Server.luau
	Date written: 15th November 2025
	Last edited: 23rd November 2025
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

type OnServerEventCallback = {
	Reliable: boolean,
	Function: (Player, ...any) -> (),
}

type NetworkPacket = {
	Data: buffer,
	References: Bitstream.References,
}

type SendPacket = {
	Data: { any },
}

type PlayerSendPacket = SendPacket & {
	Client: Player,
}

export type Server = {
	Name: string,

	_onServerInvokeCallback: ((Player, ...any) -> ...any)?,
	_onServerEventCallbacks: { [string]: OnServerEventCallback },

	_playerSendStack: { PlayerSendPacket },
	_playerSendStackUnr: { PlayerSendPacket },
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

--// @module Server

local Server = {}

--// Main methods

function Server.new(Name: string): Server
	assert(ACTIVE_REMOTES[Name] == nil, `remote bridge '{Name}' already exists!`)
	ACTIVE_REMOTES[Name] = true

	local self = {} :: Server

	self.Name = Name

	self._onServerEventCallbacks = {} :: { [string]: OnServerEventCallback }
	self._playerSendStack = {} :: { PlayerSendPacket }
	self._playerSendStackUnr = {} :: { PlayerSendPacket }
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
	local HandleSendStack = Server._handleSendStack
	local HandlePlayerSendStack = Server._handlePlayerSendStack

	self._onServerEvent = self._remoteEvent.OnServerEvent:Connect(function(Sender: Player, IncomingData: { NetworkPacket })
		for _, Packet: NetworkPacket in IncomingData do
			HandleIncomingRequest(self, true, Sender, Packet.Data, Packet.References)
		end
	end)

	self._onUnrServerEvent = self._unrRemoteEvent.OnServerEvent:Connect(function(Sender: Player, IncomingData: { NetworkPacket })
		for _, Packet: NetworkPacket in IncomingData do
			HandleIncomingRequest(self, false, Sender, Packet.Data, Packet.References)
		end
	end)
	
	local _globalSendStack: { SendPacket } = self._globalSendStack
	local _globalSendStackUnr: { SendPacket } = self._globalSendStackUnr
	local _playerSendStack: { PlayerSendPacket } = self._playerSendStack
	local _playerSendStackUnr: { PlayerSendPacket } = self._playerSendStackUnr

	self._replicationHandler = RunService.PostSimulation:Connect(function()
		debug.profilebegin("SwitchNet.Server._replicationHandler")

		--// Global stacks (FireAllClients)
		if #_globalSendStack > 0 then
			HandleSendStack(self, true)
		end

		if #_globalSendStackUnr > 0 then
			HandleSendStack(self, false)
		end

		--// Per-player stacks
		if #_playerSendStack > 0 then
			HandlePlayerSendStack(self, true)
		end

		if #_playerSendStackUnr > 0 then
			HandlePlayerSendStack(self, false)
		end

		debug.profileend()
	end)

	self._remoteFunction.OnServerInvoke = function(Sender: Player, IncomingData: NetworkPacket)
		if not self._onServerInvokeCallback then
			return nil
		end

		debug.profilebegin("SwitchNet.Server.OnServerInvoke")

		local Results: { any } = {}

		if IncomingData then
			local Success: boolean, Args: { n: number, [number]: any } = pcall(Read, IncomingData.Data, IncomingData.References)

			if Success then
				Results = { pcall(self._onServerInvokeCallback, Sender, table.unpack(Args)) }
				
				if table.remove(Results, 1) == false then
					Results = {}
				end
			end
		end

		if #Results == 0 then
			return nil
		end

		local Success: boolean, Buffer: buffer, References: Bitstream.References = pcall(Create, table.unpack(Results))

		debug.profileend()

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
	table.insert(self._playerSendStack, {
		Client = Player,
		Data = { ... },
	})
end

function Server.FireClientUnreliable(self: Server, Player: Player, ...: any)
	table.insert(self._playerSendStackUnr, {
		Client = Player,
		Data = { ... },
	})
end

function Server.FireAllClients(self: Server, ...: any)
	table.insert(self._globalSendStack, {
		Data = { ... },
	})
end

function Server.FireAllClientsUnreliable(self: Server, ...: any)
	table.insert(self._globalSendStackUnr, {
		Data = { ... },
	})
end

function Server.InvokeClient(self: Server, Player: Player, ...: any): ...any
	local Data: buffer, References: Bitstream.References = Create(...)
	local ResponsePacket: NetworkPacket

	local Success: boolean, Error: string? = pcall(function()
		ResponsePacket = self._remoteFunction:InvokeClient(Player, {
			Data = Data,
			References = References,
		})
	end)

	if not Success then
		warn(`InvokeServer failed! Error:\n{Error}`)
		return nil
	end

	if ResponsePacket == nil then
		return nil
	end

	local Response: { n: number, [number]: any } = Read(ResponsePacket.Data, ResponsePacket.References)

	return table.unpack(Response, 1, Response.n)
end

--// Private methods

function Server._handleIncomingRequest(self: Server, Reliable: boolean, Sender: Player, Data: buffer, References: Bitstream.References)
	if not next(self._onServerEventCallbacks) then
		return
	end

	debug.profilebegin("SwitchNet.Server._handleIncomingRequest")

	local Args: { n: number, [number]: any } = Read(Data, References)
	
	for Name, Callback: OnServerEventCallback in self._onServerEventCallbacks do
		if Callback.Reliable == Reliable then
			local Success: boolean, Error: any = pcall(task.spawn, Callback.Function, Sender, table.unpack(Args, 1, Args.n))

			if not Success then
				TestService:Error(`NetworkServer '{self.Name}' Callback Error:\n{Error}`)
			end
		end
	end

	debug.profileend()
end

function Server._handleSendStack(self: Server, Reliable: boolean)
	local Remote: RemoteEvent | UnreliableRemoteEvent = if Reliable then self._remoteEvent else self._unrRemoteEvent
	local Stack: { SendPacket } = if Reliable then self._globalSendStack else self._globalSendStackUnr

	local NetworkPackets: { NetworkPacket } = {}

	for _, Packet: SendPacket in Stack do
		local Buffer: buffer, References: Bitstream.References = Create(table.unpack(Packet.Data))

		table.insert(NetworkPackets, {
			Data = Buffer,
			References = References,
		})
	end

	table.clear(Stack);

	(Remote :: RemoteEvent):FireAllClients(NetworkPackets)
		--// ^ I hate the typechecker
end

function Server._handlePlayerSendStack(self: Server, Reliable: boolean)
	local Remote: RemoteEvent | UnreliableRemoteEvent = if Reliable then self._remoteEvent else self._unrRemoteEvent
	local Stack: { PlayerSendPacket } = if Reliable then self._playerSendStack else self._playerSendStackUnr

	local PlayerDelegatedPackets: { [Player]: { PlayerSendPacket } } = {}

	for _, Packet: PlayerSendPacket in Stack do
		local PlayerPacketPool: { PlayerSendPacket } = PlayerDelegatedPackets[Packet.Client]
				
		if not PlayerPacketPool then
			PlayerPacketPool = {}
			PlayerDelegatedPackets[Packet.Client] = PlayerPacketPool
		end

		table.insert(PlayerPacketPool, Packet)
	end

	table.clear(Stack)

	for Player: Player, Packets: { PlayerSendPacket } in PlayerDelegatedPackets do
		local NetworkPackets: { NetworkPacket } = {}

		for _, Packet: PlayerSendPacket in Packets do
			local Buffer: buffer, References: Bitstream.References = Create(table.unpack(Packet.Data))

			table.insert(NetworkPackets, {
				Data = Buffer,
				References = References,
			})
		end

		(Remote :: RemoteEvent):FireClient(Player, NetworkPackets)
		--// ^ I hate the typechecker
	end
end

return Server