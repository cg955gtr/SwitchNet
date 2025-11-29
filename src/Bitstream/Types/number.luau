--[==[
	Author: 8ch99
	File: number.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 8,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): number
		local Number: number = buffer.readf64(Buffer._buffer, Buffer.Pointer)

		Buffer.Pointer += 8

		return Number
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: number)
		buffer.writef64(Buffer._buffer, Buffer.Pointer, Value)
		
		Buffer.Pointer += 8
	end,
}