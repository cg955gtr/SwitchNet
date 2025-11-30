--[==[
	Author: 8ch99
	File: boolean.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 1,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): boolean
		local Bool: boolean = buffer.readu8(Buffer._buffer, Buffer.Pointer) ~= 0

		Buffer.Pointer += 1

		return Bool
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: boolean)
		buffer.writeu8(Buffer._buffer, Buffer.Pointer, if Value then 1 else 0)
		
		Buffer.Pointer += 1
	end,
}