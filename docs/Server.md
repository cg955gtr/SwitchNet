# > SwitchNet.Server

## Server.new
```luau
function Server.new(name: string): Server
```
> Creates a new SwitchNet server instance with the given name.

> **NOTE:** Do not use duplicate names for remote bridges, as this will throw an error if the given remote bridge with that name exists already. Also ensure that nothing in ReplicatedStorage conflicts with the given name. (e.g. Another instance with the same name)
### Parameters
`name` : `string` - The name of the remote instance.
### Example
```luau
local remote: SwitchNet.Server = SwitchNet.Server.new("Example123")
```

## Server.Destroy
```luau
function Server.Destroy(self: Server): ()
```
> Destroys the given SwitchNet server instance and its remote instances. Use this when you don't need the remote bridge anymore.
### Parameters
- `self` : `Server` - The SwitchNet server instance.



## Server.Wait
```luau
function Server.Wait(self: Server): ...any
```
> Yields the current thread until a remote request is sent, and returns the calling player + received arguments.

### Parameters
- `self` : `Server` - The SwitchNet server instance.
### Example
```luau
local caller: Player, timestamp: number = SwitchNet.Server.Wait(remote)

print(`{caller.Name} sent their timestamp: {timestamp}`)
```

## Server.WaitUnreliable
```luau
function Server.WaitUnreliable(self: Server): ...any
```
> Yields the current thread until a (unreliable) remote request is sent, and returns the calling player + received arguments.

### Parameters
- `self` : `Server` - The SwitchNet server instance.
### Example
```luau
local caller: Player, timestamp: number = SwitchNet.Server.WaitUnreliable(remote)

print(`(Unreliable) {Caller.Name} sent their timestamp: {timestamp}`)
```



## Server.Connect
```luau
function Server.Connect(self: Server, name: string, callback: (Player, ...any) -> ()): ()
```
> Creates a new remote input callback with the given name, and function to use.

### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the callback.
- `callback` : `(Player, ...any) -> ()` - The function to use in the callback.
### Example
```luau
SwitchNet.Server.Connect(remote, "Main", function(sender: Player, ...: any)
	--// ^ Basically as if you did .OnServerEvent!
	print(`User {sender.Name} sent us data! Data:`, ...)
end)
```

## Server.ConnectUnreliable
```luau
function Server.ConnectUnreliable(self: Server, name: string, callback: (Player, ...any) -> ()): ()
```
> Creates a new (unreliable) remote input callback with the given name, and function to use.

### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the callback.
- `callback` : `(Player, ...any) -> ()` - The function to use in the callback.
### Example
```luau
SwitchNet.Server.ConnectUnreliable(remote, "Main", function(sender: Player, ...: any)
	--// ^ Basically as if you did .OnServerEvent!
	print(`User {sender.Name} sent us data! Data:`, ...)
end)
```



## Server.Disconnect
```luau
function Server.Disconnect(self: Server, name: string): ()
```
> Removes the current remote input callback with the given name (if it exists). Use this if you don't want the given callback to listen to remote calls anymore.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the callback.
### Example
```luau
SwitchNet.Server.Disconnect(remote, "Main")
```

## Server.DisconnectUnreliable
```luau
function Server.DisconnectUnreliable(self: Server, name: string): ()
```
> Removes the current remote (unreliable) input callback with the given name (if it exists). Use this if you don't want the given callback to listen to remote calls anymore.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the callback.
### Example
```luau
SwitchNet.Server.DisconnectUnreliable(remote, "Main")
```



## Server.SetOnInvoke
```luau
function Server.SetOnInvoke(self: Server, callback: (Player, ...any) -> ...any): ()
```
> Sets the current RemoteFunction callback function. Use this how you would use `RemoteFunction.OnServerInvoke = function_here`.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `callback` : `(Player, ...any) -> ...any` - The function to use.
### Example
```luau
SwitchNet.Server.SetOnInvoke(remote, function(player: Player, requestType: "HELLO" | "BYE"): any
	if requestType == "HELLO" then
		return "Hello!"
	elseif requestType == "BYE" then
		return "Goodbye!"
	end

	return "unknown_request"
end)
```



## Server.FireClient
```luau
function Server.FireClient(self: Server, player: Player, ...: any): ()
```
> Sends the given data to the given player over the remote bridge. Use this how you would use `RemoteEvent:FireClient(Player, ...)`
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Player` : `Player` - The target player.
- `...` : `any` - The data to send.
### Example
```luau
SwitchNet.Server.FireClient(remote, some_player, "Hello from the server!")
```

## Server.FireClientUnreliable
```luau
function Server.FireClientUnreliable(self: Server, player: Player, ...: any): ()
```
> Sends the given data to the given player over the remote bridge via. UnreliableRemoteEvent. Use this how you would use `UnreliableRemoteEvent:FireClient(Player, ...)`
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Player` : `Player` - The target player.
- `...` : `any` - The data to send.
### Example
```luau
SwitchNet.Server.FireClientUnreliable(remote, some_player, "Hello from the server! (Unreliable)")
```

## Server.FireAllClients
```luau
function Server.FireAllClients(self: Server, ...: any): ()
```
> Sends the given data to all players over the remote bridge. Use this how you would use `RemoteEvent:FireAllClients(...)`
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `...` : `any` - The data to send.
### Example
```luau
SwitchNet.Server.FireAllClients(remote, "Hello everybody from the server!")
```

## Server.FireAllClientsUnreliable
```luau
function Server.FireAllClientsUnreliable(self: Server, ...: any): ()
```
> Sends the given data to all players over the remote bridge via. UnreliableRemoteEvent. Use this how you would use `UnreliableRemoteEvent:FireAllClients(...)`
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `...` : `any` - The data to send.
### Example
```luau
SwitchNet.Server.FireAllClientsUnreliable(remote, "Hello everybody from the server! (Unreliable)")
```

## Server.FireAllClientsExcept
```luau
function Server.FireAllClientsExcept(self: Server, exemptPlayer: Player, ...: any): ()
```
> Sends the given data to all players over the remote bridge *EXCLUDING* the passed player.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `exemptPlayer` : `Player` - The player who should not receive the data.
- `...` : `any` - The data to send.
### Example
```luau
SwitchNet.Server.FireAllClientsExcept(remote, game.Players['8ch99'], "Hello everybody (excluding 8ch99) from the server!")
```

## Server.FireAllClientsUnreliableExcept
```luau
function Server.FireAllClientsUnreliableExcept(self: Server, exemptPlayer: Player, ...: any): ()
```
> Sends the given data to all players over the remote bridge via. UnreliableRemoteEvent *EXCLUDING* the passed player.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `exemptPlayer` : `Player` - The player who should not receive the data.
- `...` : `any` - The data to send.
### Example
```luau
SwitchNet.Server.FireAllClientsUnreliableExcept(remote, game.Players['8ch99'], "Hello everybody (excluding 8ch99) from the server! (Unreliable)")
```

## Server.FireClientList
```luau
function Server.FireClientList(self: Server, exemptPlayer: Player, ...: any): ()
```
> Sends the given data to the players in the given player array.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `exemptPlayer` : `Player` - The target players who should receive the data.
- `...` : `any` - The data to send.
### Example
```luau
const Players = game:GetService("Players")

local players: { Player } = Players:GetPlayers()
Random.new():Shuffle(players)

for i: number = (#players // 2) + 1, #players do
	players[i] = nil
end

SwitchNet.Server.FireClientList(remote, players, "Hello random people from the server!")
```

## Server.FireClientListUnreliable
```luau
function Server.FireClientListUnreliable(self: Server, exemptPlayer: Player, ...: any): ()
```
> Sends the given data to the players in the given player array (via. UnreliableRemoteEvent).
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `exemptPlayer` : `Player` - The player who should not receive the data.
- `...` : `any` - The data to send.
### Example
```luau
const Players = game:GetService("Players")

local players: { Player } = Players:GetPlayers()
Random.new():Shuffle(players)

for i: number = (#players // 2) + 1, #players do
	players[i] = nil
end

SwitchNet.Server.FireClientListUnreliable(remote, players, "Hello random people from the server! (Unreliable)")
```

## Server.InvokeClient
```luau
function Server.InvokeClient(self: Server, player: Player, ...: any): ...any
```
> Sends the given data to the given player over the remote bridge via. RemoteFunction, and yields the current thread until response. Use this how you would use `RemoteFunction:InvokeClient(Player, ...)`

> **NOTE:** Only use this if the client has a on invoke callback set, otherwise its only going to return `nil`.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `player` : `Player` - The target player.
- `...` : `any` - The data to send.
### Example
```luau
local localTime: number = SwitchNet.Server.InvokeClient(remote, some_player, "GetTime")
local date: DateTypeResult = os.date("!*t", localTime)

print(`The player's local time is: {string.format("%02d:%02d:%02d", date.hour, date.min, date.sec)}`)
```



## Server.AddFilter
```luau
function Server.AddFilter(self: Server, name: string, callback: ("Reliable" | "Unreliable" | "Request", Player, ...any) -> boolean, priority: number?): ()
```
> Adds a filter callback to the server. If the callback returns false, the remote request is dropped.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the filter.
- `callback` : `("Reliable" | "Unreliable" | "Request", Player, ...any) -> boolean` - The callback to use. (params are request type, calling player and data)
- `priority` : `number?` - The priority of the filter (lower = called earlier)
### Example
```luau
SwitchNet.Server.AddFilter(remote, "ActionArgCheck", function(requestType: "Reliable" | "Unreliable" | "Request", player: Player, action: string): boolean
	return type(action) == "string" and VALID_ACTIONS[action] ~= nil --// The action must exist
end, 10)
```

## Server.RemoveFilter
```luau
function Server.RemoveFilter(self: Server, name: string): ()
```
> Removes a filter callback from the server if it exists.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the filter.
### Example
```luau
SwitchNet.Server.RemoveFilter(remote, "ActionArgCheck")
```


## Server.AddPreProcessFilter
```luau
function Server.AddPreProcessFilter(self: Server, name: string, callback: ("Reliable" | "Unreliable" | "Request", Player, buffer, { any }) -> boolean, priority: number?): ()
```
> Adds a (pre-process, called before any deserialization work is done) filter callback to the server. If the callback returns false, the remote request is dropped.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the filter.
- `callback` : `("Reliable" | "Unreliable" | "Request", Player, buffer, { any }) -> boolean` - The callback to use. (params are request type, calling player, buffer and references table)
- `priority` : `number?` - The priority of the filter (lower = called earlier)
### Example
```luau
SwitchNet.Server.AddPreProcessFilter(remote, "EnabledCheck", function(): boolean
	return configuration.isRemoteBridgeEnabled
end, 5)
```

## Server.RemovePreProcessFilter
```luau
function Server.RemovePreProcessFilter(self: Server, name: string): ()
```
> Removes a (pre-process, called before any deserialization work is done) filter callback from the server if it exists.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `name` : `string` - The name of the filter.
### Example
```luau
SwitchNet.Server.RemovePreProcessFilter(remote, "EnabledCheck")
```