# SwitchNet Documentation

These documents contain essential notes for SwitchNet usages.

> **NOTE:** Properties/variables/methods prefixed with `_` are intended for internal use only.

```luau
const SwitchNet = require(path_to_switchnet_here)
```
> The luau types for Server and Client can be referenced from the SwitchNet module. You can use them like so:
```luau
local remote: SwitchNet.Server = SwitchNet.Server.new("Example123")
```

> ***Each respective library should only be used on the valid run context. (in simpler terms, only use the Server library if the script is running on the server, vice versa)***