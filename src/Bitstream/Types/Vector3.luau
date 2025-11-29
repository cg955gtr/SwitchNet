--[==[
	Author: 8ch99
	File: Vector3.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Vector3
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 12

		return Vector3.new(
			buffer.readf32(_buffer, Pointer),
			buffer.readf32(_buffer, Pointer + 4),
			buffer.readf32(_buffer, Pointer + 8)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Vector3)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 12

		buffer.writef32(_buffer, Pointer, Value.X)
		buffer.writef32(_buffer, Pointer + 4, Value.Y)
		buffer.writef32(_buffer, Pointer + 8, Value.Z)
	end,
}