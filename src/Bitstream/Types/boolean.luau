--[==[
	Author: 8ch99
	File: boolean.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadBoolean = ByteBuffer.ReadBoolean

local WriteBoolean = ByteBuffer.WriteBoolean

return {
	Size = 1,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): boolean
		return ReadBoolean(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: boolean)
		WriteBoolean(Buffer, Value)
	end,
}