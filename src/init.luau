--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library
--// 
--// A blazingly fast and easy to use networking module for reducing bandwidth and overhead across remotes

--[==[

MIT License

Copyright (c) 2026 8ch99

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]==]

--// TODO: Move some variables to `const` when its rolled out

--!strict
--!native
--!optimize 2

local VERSION = "v1.2.2"
local PRINT_OUTPUT_MESSAGE = true

--// Services

local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

--// Dependencies

local Server = require("@self/Server")
local Client = require("@self/Client")

--// Typedefs

export type Server = Server.Server
export type Client = Client.Client

--// @module SwitchNet

local SwitchNet = table.freeze({
	Server = Server,
	Client = Client,
})


if PRINT_OUTPUT_MESSAGE then
	task.spawn(function()
		--// Print message
		--// Check if it exists already too, so if theres several dependencies, it won't add extras
		local runContext = if RunService:IsClient() then "Client" else "Server"
		local message = `SwitchNet {runContext} - {VERSION} loaded successfully! Created by 8ch99.`
		
		for _, log in LogService:GetLogHistory() do
			if log.messageType == Enum.MessageType.MessageInfo and string.find(log.message, message, nil, true) then
				--// Message was sent already, cancel!
				return
			end
		end
		
		TestService:Message(message)
	end)
end


return SwitchNet