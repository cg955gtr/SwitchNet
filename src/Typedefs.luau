--// Author: 8ch99
--// Date written: 4th May 2026
--// SwitchNet Networking Library

--!strict

export type NBasedArray = { n: number, [number]: any }



export type StreamType = {
	Name: string,
	Value: number,
	Size: number?,
	GetSize: ((Value: any) -> number)?,

	Reader: (Buffer: buffer, References: { any }, Pointer: number) -> (any, number),
	Writer: (Buffer: buffer, References: { any }, Pointer: number, Value: any) -> number,
}

export type NetworkPacket = {
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



return nil