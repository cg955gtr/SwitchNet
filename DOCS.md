# SwitchNet Documentation

This document contains all the documentation for SwitchNet usage.

> **NOTE:** Properties/types/methods prefixed with `_` are intended for internal use only.

The respective library/libraries can be fetched by fetching the main module and referencing like so:

```luau
local SwitchNet = require(path_to_switchnet_here)

local Server = SwitchNet.Server
local Client = SwitchNet.Client
```
> The luau types for Server and Client can be referenced from the SwitchNet module. You can use them like so:
```luau
local Remote: SwitchNet.Server = Server.new("Example123")
```

> ***Each respective library should only be used on the valid run context. (in simpler terms, only use the Server library if the script is running on the server, vice versa)***


# > SwitchNet.Server

## Server.new
```luau
function Server.new(Name: string): Server
```
> Creates a new SwitchNet server instance with the given name.

> **NOTE:** Do not use duplicate names for remote bridges, as this will throw an error if the given remote bridge with that name exists already. Also ensure that nothing in ReplicatedStorage conflicts with the given name. (e.g. Another instance with the same name)
### Parameters
`Name` : `string` - The name of the remote instance.
### Example
```luau
local Remote: SwitchNet.Server = Server.new("Example123")
```

## Server.Destroy
```luau
function Server.Destroy(self: Server): ()
```
> Destroys the given SwitchNet server instance and its remote instances. Use this when you don't need the remote bridge anymore.
### Parameters
- `self` : `Server` - The SwitchNet server instance.

## Server.Connect
```luau
function Server.Connect(self: Server, Name: string, Function: (Player, ...any) -> (), Unreliable: boolean?): ()
```
> Creates a new remote input callback with the given name, and function to use.

> **NOTE:** To listen to UnreliableRemoteEvent inputs, set the `Unreliable` parameter to `true`.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Name` : `string` - The name of the callback.
- `Function` : `(Player, ...any) -> ()` - The function to use in the callback.
- `Unreliable` : `boolean?` **(optional)** - Whether the callback should listen to UnreliableRemoteEvent requests instead of standard RemoteEvent requests.
### Example
```luau
Server.Connect(Remote, "Main", function(Sender: Player, ...: any)
	--// ^ Basically as if you did .OnServerEvent!
	print(`User {Sender.Name} sent us data! Data:`, ...)
end)
```

## Server.Disconnect
```luau
function Server.Disconnect(self: Server, Name: string): ()
```
> Removes the current remote input callback with the given name (if it exists). Use this if you don't want the given callback to listen to remote calls anymore.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Name` : `string` - The name of the callback.
### Example
```luau
Server.Disconnect(Remote, "Main")
```

## Server.SetOnInvoke
```luau
function Server.SetOnInvoke(self: Server, Function: (Player, ...any) -> ...any): ()
```
> Sets the current RemoteFunction callback function. Use this how you would use `RemoteFunction.OnServerInvoke = function_here`.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Function` : `(Player, ...any) -> ...any` - The function to use.
### Example
```luau
Server.SetOnInvoke(Remote, function(Player: Player, RequestType: string): any
	if RequestType == "HELLO" then
		return "Hello!"
	elseif RequestType == "BYE" then
		return "Goodbye!"
	end

	return "unknown_request"
end)
```

## Server.FireClient
```luau
function Server.FireClient(self: Server, Player: Player, ...: any): ()
```
> Sends the given data to the given player over the remote bridge. Use this how you would use `RemoteEvent:FireClient(Player, ...)`
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Player` : `Player` - The target player.
- `...` : `any` - The data to send.
### Example
```luau
Server.FireClient(Remote, some_player, "Hello from the server!")
```

## Server.FireClientUnreliable
```luau
function Server.FireClientUnreliable(self: Server, Player: Player, ...: any): ()
```
> Sends the given data to the given player over the remote bridge via. UnreliableRemoteEvent. Use this how you would use `UnreliableRemoteEvent:FireClient(Player, ...)`
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Player` : `Player` - The target player.
- `...` : `any` - The data to send.
### Example
```luau
Server.FireClientUnreliable(Remote, some_player, "Hello from the server! (Unreliable)")
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
Server.FireAllClients(Remote, "Hello everybody from the server!")
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
Server.FireAllClientsUnreliable(Remote, "Hello everybody from the server! (Unreliable)")
```

## Server.InvokeClient
```luau
function Server.InvokeClient(self: Server, Player: Player, ...: any): ...any
```
> Sends the given data to the given player over the remote bridge via. RemoteFunction, and yields the current thread until response. Use this how you would use `RemoteFunction:InvokeClient(Player, ...)`

> **NOTE:** Only use this if the client has a on invoke callback set, otherwise its only going to return `nil`.
### Parameters
- `self` : `Server` - The SwitchNet server instance.
- `Player` : `Player` - The target player.
- `...` : `any` - The data to send.
### Example
```luau
local Time: number = Server.InvokeClient(Remote, some_player, "GetTime")
local Date: DateTypeResult = os.date("!*t", Time)

print(`The player's local time is: {string.format("%02d:%02d:%02d", Date.hour, Date.min, Date.sec)}`)
```

# > SwitchNet.Client

## Client.new
```luau
function Client.new(Name: string): Client
```
> Creates a new SwitchNet client instance with the given name.

> **NOTE:** Do not use duplicate names for remote bridges, as this will throw an error if the given remote bridge with that name exists already. Also ensure that nothing in ReplicatedStorage conflicts with the given name. (e.g. Another instance with the same name)
### Parameters
`Name` : `string` - The name of the remote instance.
### Example
```luau
local Remote: SwitchNet.Client = Client.new("Example123")
```

## Client.Destroy
```luau
function Client.Destroy(self: Client): ()
```
> Destroys the given SwitchNet client instance. Use this when you don't need the remote bridge anymore.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.

## Client.Connect
```luau
function Client.Connect(self: Client, Name: string, Function: (...any) -> (), Unreliable: boolean?): ()
```
> Creates a new remote input callback with the given name, and function to use.

> **NOTE:** To listen to UnreliableRemoteEvent inputs, set the `Unreliable` parameter to `true`.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `Name` : `string` - The name of the callback.
- `Function` : `(...any) -> ()` - The function to use in the callback.
- `Unreliable` : `boolean?` **(optional)** - Whether the callback should listen to UnreliableRemoteEvent requests instead of standard RemoteEvent requests.
### Example
```luau
Client.Connect(Remote, "Main", function(...: any)
	--// ^ Basically as if you did .OnServerEvent!
	print(`The server sent us data! Data:`, ...)
end)
```

## Client.Disconnect
```luau
function Client.Disconnect(self: Client, Name: string): ()
```
> Removes the current remote input callback with the given name (if it exists). Use this if you don't want the given callback to listen to remote calls anymore.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `Name` : `string` - The name of the callback.
### Example
```luau
Client.Disconnect(Remote, "Main")
```

## Client.SetOnInvoke
```luau
function Client.SetOnInvoke(self: Client, Function: (...any) -> ...any): ()
```
> Sets the current RemoteFunction callback function. Use this how you would use `RemoteFunction.OnClientInvoke = function_here`.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `Function` : `(Player, ...any) -> ...any` - The function to use.
### Example
```luau
Client.SetOnInvoke(Remote, function(RequestType: string): any
	if RequestType == "HELLO" then
		return "Hello!"
	elseif RequestType == "BYE" then
		return "Goodbye!"
	end

	return "unknown_request"
end)
```

## Client.FireServer
```luau
function Client.FireServer(self: Client, ...: any): ()
```
> Sends the given data to the server over the remote bridge. Use this how you would use `RemoteEvent:FireServer(...)`
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `...` : `any` - The data to send.
### Example
```luau
Client.FireServer(Remote, "Hello from the client!")
```

## Client.FireClientUnreliable
```luau
function Client.FireClientUnreliable(self: Client, ...: any): ()
```
> Sends the given data to the given player over the remote bridge via. UnreliableRemoteEvent. Use this how you would use `UnreliableRemoteEvent:FireServer(...)`
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `...` : `any` - The data to send.
### Example
```luau
Client.FireServerUnreliable(Remote, "Hello from the client! (Unreliable)")
```

## Client.InvokeServer
```luau
function Client.InvokeServer(self: Client, ...: any): ...any
```
> Sends the given data to the server over the remote bridge via. RemoteFunction, and yields the current thread until response. Use this how you would use `RemoteFunction:InvokeServer(Player, ...)`

> **NOTE:** Only use this if the server has a on invoke callback set, otherwise its only going to return `nil`.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `...` : `any` - The data to send.
### Example
```luau
local Time: number = Client.InvokeServer(Remote, "GetLastUpdateTime")
local TimeNow: number = workspace:GetServerTimeNow()

print(`It has been ~{math.round(TimeNow - Time)} seconds since the last update.`)
```