--[==[
	Author: 8ch99
	File: Color3.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadColor3 = ByteBuffer.ReadColor3

local WriteColor3 = ByteBuffer.WriteColor3

return {
	Size = 3,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Color3
		return ReadColor3(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Color3)
		WriteColor3(Buffer, Value)
	end,
}