--[==[
	Author: 8ch99
	File: Vector2.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadVector2 = ByteBuffer.ReadVector2

local WriteVector2 = ByteBuffer.WriteVector2

return {
	Size = 8,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Vector2
		return ReadVector2(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Vector2)
		WriteVector2(Buffer, Value)
	end,
}