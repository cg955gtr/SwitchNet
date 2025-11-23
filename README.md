# SwitchNet

A blazingly fast and easy to use networking module for reducing bandwidth and overhead across remotes.
It is designed to be easy to use and allows for communication via reliable, unreliable, and remote functions, while also prioritizing performance simultaneously.

For optimization, it uses buffer compression to reduce bandwidth as much as possible, and every remote request via the reliable/unreliable bridges are batched per frame to reduce the amount of remote requests made, helping reduce total network overhead and request amounts.

> More on the buffer compression part, the compression technique works by instead calculating the size of the buffer and only creating it once, rather than constantly expanding it for every write operation. Most buffer-based libraries use the expansion approach, and because Luau's buffer library does not have a native buffer expansion method, it ends up wasting heaps of CPU. This helps save LOTS of CPU usage, especially with larger payloads.

> **NOTE:** Unsupported objects (e.g. Instances) are simply passed through a reference routing table, as instances like that are not possible to compress currently.

This library is also compatible with --!strict typechecking.

# Installation

> SwitchNet can be installed via. Wally, or via the .rbxm in latest releases.

# Documentation

> For documentation, refer to the `DOCS.md` file.

# Some basic usage examples

### Server

```luau
--!strict
local SwitchNet = require(game.ReplicatedStorage.SwitchNet)

local Remote: SwitchNet.Server = SwitchNet.Server.new("NetTest")
--// ^ Creates a new server instance, also creating and adding the remote instances to ReplicatedStorage.

SwitchNet.Server.Connect(Remote, "Main", function(Sender: Player, ...: any)
	--// ^ Basically as if you did .OnServerEvent
	print(`The server sent us data! Data:`, ...)

	SwitchNet.Server.FireServer(Remote, Sender, "Hello from the server!")
end)

SwitchNet.Server.SetOnInvoke(Remote, function(Sender: Player, Action: string)
	--// ^ Basically as if you did .OnServerInvoke
	if Action == "HelloMessage" then
		return "Hello again, from the server!"
	end
end)
```

### Client

```luau
--!strict
local SwitchNet = require(game.ReplicatedStorage:WaitForChild("SwitchNet"))

local Remote: SwitchNet.Client = SwitchNet.Client.new("NetTest")
--// ^ Creates a new client instance, which automatically searches ReplicatedStorage for the remote instances and listens to them.

SwitchNet.Client.Connect(Remote, "Main", function(...: any)
	--// ^ Basically as if you did .OnClientEvent
	print(`The server sent us data! Data:`, ...)
end)

--// Send some data to the server!
SwitchNet.Client.FireServer(Remote, workspace:WaitForChild("Baseplate"), "Hello from client!")

--// Get some data from the server too
local ServerMessage: string = SwitchNet.Client.InvokeServer(Remote, "HelloMessage")

warn(`The server responded! Message: {ServerMessage}`)
```

### And thats it in terms of setting it up! Its really easy to use, and heaps of bandwidth is being saved.
Made by 8ch99