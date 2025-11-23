--[==[
	Author: 8ch99
	File: Vector2int16.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadVector2int16 = ByteBuffer.ReadVector2int16

local WriteVector2int16 = ByteBuffer.WriteVector2int16

return {
	Size = 4,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Vector2int16
		return ReadVector2int16(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Vector2int16)
		WriteVector2int16(Buffer, Value)
	end,
}