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



## Client.Wait
```luau
function Client.Wait(self: Client): ...any
```
> Yields the current thread until a remote request is sent, and returns the received arguments.

### Parameters
- `self` : `Client` - The SwitchNet Client instance.
### Example
```luau
local Time: number = Client.Wait(Remote)

print(`The server sent their timestamp: {Time}`)
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
local Time: number = Client.WaitUnreliable(Remote)

print(`(Unreliable) The server sent their timestamp: {Time}`)
```



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


## Client.ConnectUnreliable
```luau
function Client.ConnectUnreliable(self: Client, Name: string, Function: (...any) -> ()): ()
```
> Creates a new (unreliable) remote input callback with the given name, and function to use.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `Name` : `string` - The name of the callback.
- `Function` : `(...any) -> ()` - The function to use in the callback.
### Example
```luau
Client.ConnectUnreliable(Remote, "Main", function(...: any)
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

## Client.DisconnectUnreliable
```luau
function Client.DisconnectUnreliable(self: Client, Name: string): ()
```
> Removes the current (unreliable) remote input callback with the given name (if it exists). Use this if you don't want the given callback to listen to remote calls anymore.
### Parameters
- `self` : `Client` - The SwitchNet Client instance.
- `Name` : `string` - The name of the callback.
### Example
```luau
Client.DisconnectUnreliable(Remote, "Main")
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
Client.AddFilter(Remote, "ActionArgCheck", function(requestType: "Reliable" | "Unreliable" | "Request", action: string): boolean
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
Client.RemoveFilter(Remote, "ActionArgCheck")
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
Client.AddPreProcessFilter(Remote, "EnabledCheck", function(): boolean
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
Client.RemovePreProcessFilter(Remote, "EnabledCheck")
```