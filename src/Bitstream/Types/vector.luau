--[==[
	Author: 8ch99
	File: vector.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): vector
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 12

		return vector.create(
			buffer.readf32(_buffer, Pointer),
			buffer.readf32(_buffer, Pointer + 4),
			buffer.readf32(_buffer, Pointer + 8)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: vector)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 12

		buffer.writef32(_buffer, Pointer, Value.x)
		buffer.writef32(_buffer, Pointer + 4, Value.y)
		buffer.writef32(_buffer, Pointer + 8, Value.z)
	end,
}