# SwitchNet Documentation

These documents contain essential notes for SwitchNet usages.

> **NOTE:** Properties/variables/methods prefixed with `_` are intended for internal use only.

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