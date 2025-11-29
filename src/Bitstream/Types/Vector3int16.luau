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
	Size = 6,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Vector3int16
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 6

		return Vector3int16.new(
			buffer.readi16(_buffer, Pointer),
			buffer.readi16(_buffer, Pointer + 2),
			buffer.readi16(_buffer, Pointer + 6)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Vector3int16)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 6

		buffer.writei16(_buffer, Pointer, Value.X)
		buffer.writei16(_buffer, Pointer + 2, Value.Y)
		buffer.writei16(_buffer, Pointer + 4, Value.Z)
	end,
}