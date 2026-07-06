# > SwitchNet.Client




## Client.new
```luau
function Client.new(name: string): Client
```
> Creates a new SwitchNet client instance with the given name.

> **NOTE:** Do not use duplicate names for remote bridges, as this will throw an error if the given remote bridge with that name exists already. Also ensure that nothing in ReplicatedStorage conflicts with the given name. (e.g. Another instance with the same name)
### Parameters
`name` : `string` - The name of the remote instance.
### Example
```luau
local remote: SwitchNet.Client = SwitchNet.Client.new("Example123")
```

## Client.Destroy
```luau
function Client.Destroy(self: Client): ()
```
> Destroys the given SwitchNet client instance. Use this when you don't need the remote bridge anymore.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.



## Client.Wait
```luau
function Client.Wait(self: Client): ...any
```
> Yields the current thread until a remote request is sent, and returns the received arguments.

### Parameters
- `self` : `Client` - The SwitchNet Client instance.
### Example
```luau
local timestamp: number = SwitchNet.Client.Wait(remote)

print(`The server sent their timestamp: {timestamp}`)
```

## Client.WaitUnreliable
```luau
function Client.WaitUnreliable(self: Client): ...any
```
> Yields the current thread until a (unreliable) remote request is sent, and returns the received arguments.

### Parameters
- `self` : `Client` - The SwitchNet Client instance.
### Example
```luau
local timestamp: number = SwitchNet.Client.WaitUnreliable(remote)

print(`(Unreliable) The server sent their timestamp: {timestamp}`)
```



## Client.Connect
```luau
function Client.Connect(self: Client, name: string, callback: (...any) -> ()): ()
```
> Creates a new remote input callback with the given name, and function to use.

> **NOTE:** To listen to UnreliableRemoteEvent inputs, set the `unreliable` parameter to `true`.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `name` : `string` - The name of the callback.
- `callback` : `(...any) -> ()` - The function to use in the callback.
### Example
```luau
SwitchNet.Client.Connect(remote, "Main", function(...: any)
	--// ^ Basically as if you did .OnServerEvent!
	print(`The server sent us data! Data:`, ...)
end)
```


## Client.ConnectUnreliable
```luau
function Client.ConnectUnreliable(self: Client, name: string, callback: (...any) -> ()): ()
```
> Creates a new (unreliable) remote input callback with the given name, and function to use.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `name` : `string` - The name of the callback.
- `callback` : `(...any) -> ()` - The function to use in the callback.
### Example
```luau
SwitchNet.Client.ConnectUnreliable(remote, "Main", function(...: any)
	--// ^ Basically as if you did .OnServerEvent!
	print(`The server sent us data! Data:`, ...)
end)
```



## Client.Disconnect
```luau
function Client.Disconnect(self: Client, name: string): ()
```
> Removes the current remote input callback with the given name (if it exists). Use this if you don't want the given callback to listen to remote calls anymore.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `name` : `string` - The name of the callback.
### Example
```luau
SwitchNet.Client.Disconnect(remote, "Main")
```

## Client.DisconnectUnreliable
```luau
function Client.DisconnectUnreliable(self: Client, name: string): ()
```
> Removes the current (unreliable) remote input callback with the given name (if it exists). Use this if you don't want the given callback to listen to remote calls anymore.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `name` : `string` - The name of the callback.
### Example
```luau
SwitchNet.Client.DisconnectUnreliable(remote, "Main")
```



## Client.SetOnInvoke
```luau
function Client.SetOnInvoke(self: Client, callback: (...any) -> ...any): ()
```
> Sets the current RemoteFunction callback function. Use this how you would use `RemoteFunction.OnClientInvoke = function_here`.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `callback` : `(Player, ...any) -> ...any` - The function to use.
### Example
```luau
SwitchNet.Client.SetOnInvoke(remote, function(requestType: "HELLO" | "BYE"): any
	if requestType == "HELLO" then
		return "Hello!"
	elseif requestType == "BYE" then
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
SwitchNet.Client.FireServer(remote, "Hello from the client!")
```

## Client.FireServerUnreliable
```luau
function Client.FireServerUnreliable(self: Client, ...: any): ()
```
> Sends the given data to the server over the remote bridge via. UnreliableRemoteEvent. Use this how you would use `UnreliableRemoteEvent:FireServer(...)`
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `...` : `any` - The data to send.
### Example
```luau
SwitchNet.Client.FireServerUnreliable(remote, "Hello from the client! (Unreliable)")
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
local updateTime: number = SwitchNet.Client.InvokeServer(remote, "GetLastUpdateTime")
local timeNow: number = workspace:GetServerTimeNow()

print(`It has been ~{math.round(timeNow - updateTime)} seconds since the last update.`)
```



## Client.AddFilter
```luau
function Client.AddFilter(self: Client, name: string, callback: ("Reliable" | "Unreliable" | "Request", ...any) -> boolean, priority: number?): ()
```
> Adds a filter callback to the client. If the callback returns false, the remote request is dropped.
### Parameters
- `self` : `Client` - The SwitchNet client instance.
- `name` : `string` - The name of the filter.
- `callback` : `("Reliable" | "Unreliable" | "Request", ...any) -> boolean` - The callback to use. (params are request type and data)
- `priority` : `number?` - The priority of the filter (lower = called earlier)
### Example
```luau
SwitchNet.Client.AddFilter(remote, "ActionArgCheck", function(requestType: "Reliable" | "Unreliable" | "Request", action: string): boolean
	return type(action) == "string" and VALID_ACTIONS[action] ~= nil --// The action must exist
end, 10)
```

## Client.RemoveFilter
```luau
function Client.RemoveFilter(self: Client, name: string): ()
```
> Removes a filter callback from the client if it exists.
### Parameters
- `self` : `Client` - The SwitchNet client instance.
- `name` : `string` - The name of the filter.
### Example
```luau
SwitchNet.Client.RemoveFilter(remote, "ActionArgCheck")
```


## Client.AddPreProcessFilter
```luau
function Client.AddPreProcessFilter(self: Client, name: string, callback: ("Reliable" | "Unreliable" | "Request", buffer, { any }) -> boolean, priority: number?): ()
```
> Adds a (pre-process, called before any deserialization work is done) filter callback to the client. If the callback returns false, the remote request is dropped.
### Parameters
- `self` : `Client` - The SwitchNet client instance.
- `name` : `string` - The name of the filter.
- `callback` : `("Reliable" | "Unreliable" | "Request", buffer, { any }) -> boolean` - The callback to use. (params are request type, buffer and references table)
- `priority` : `number?` - The priority of the filter (lower = called earlier)
### Example
```luau
SwitchNet.Client.AddPreProcessFilter(remote, "EnabledCheck", function(): boolean
	return configuration.isRemoteBridgeEnabled
end, 5)
```

## Client.RemovePreProcessFilter
```luau
function Client.RemovePreProcessFilter(self: Client, name: string): ()
```
> Removes a (pre-process, called before any deserialization work is done) filter callback from the client if it exists.
### Parameters
- `self` : `Client` - The SwitchNet client instance.
- `name` : `string` - The name of the filter.
### Example
```luau
SwitchNet.Client.RemovePreProcessFilter(remote, "EnabledCheck")
```