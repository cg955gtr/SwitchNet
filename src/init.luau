--[==[
	Author: 8ch99
	File: SwitchNet.luau
	Date written: 15th November 2025
	Last edited: 18th December 2025

	A blazingly fast and easy to use networking module for reducing bandwidth and overhead across remotes.
]==]

--[==[

MIT License

Copyright (c) 2025 8ch99

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

--!strict
--!native
--!optimize 2

local START_TIME: number = os.clock()
local VERSION: string = "v0.2.5"

--// Dependencies

local Server = require("@self/Server")
local Client = require("@self/Client")

export type Server = Server.Server
export type Client = Client.Client

--// @module SwitchNet

local SwitchNet = {
	Server = Server,
	Client = Client,
}

local LOADING_TIME: number = os.clock() - START_TIME

task.spawn(warn, `SwitchNet - {VERSION} Loaded in {LOADING_TIME}! Created by 8ch99.`)

return SwitchNet