--[==[
	Author: 8ch99
	File: Vector2int16.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 4,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Vector2int16
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 4

		return Vector2int16.new(
			buffer.readi16(_buffer, Pointer),
			buffer.readi16(_buffer, Pointer + 2)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Vector2int16)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 4

		buffer.writei16(_buffer, Pointer, Value.X)
		buffer.writei16(_buffer, Pointer + 2, Value.Y)
	end,
}