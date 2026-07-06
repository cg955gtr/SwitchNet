--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--[=[
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
]=]

--!strict

const VERSION: string = "v1.4.1"
const PRINT_OUTPUT_MESSAGE: boolean = true

--// Services

const RunService = game:GetService("RunService")
const LogService = game:GetService("LogService")

--// Dependencies

const Server = require("@self/Server")
const Client = require("@self/Client")
const Typedefs = require("@self/Typedefs")

--// Typedefs

export type Server = Typedefs.Server
export type Client = Typedefs.Client

--// @module SwitchNet

const SwitchNet = table.freeze({
	Server = Server,
	Client = Client,
})




if PRINT_OUTPUT_MESSAGE then
	--// Print message
	--// Check if it exists already too, so if theres several dependencies, it won't add extras
	local runContext: "Client" | "Server" = if RunService:IsClient() then "Client" else "Server"
	local message = `SwitchNet {VERSION} - ({runContext}) initialized - @8ch99`
		
	for _, log in LogService:GetLogHistory() do
		if log.message == message then return end
	end

	print(message)
end



return SwitchNet