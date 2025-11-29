--[==[
	Author: 8ch99
	File: Ray.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 24,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Ray
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 24

		return Ray.new(
			Vector3.new(
				buffer.readf32(_buffer, Pointer),
				buffer.readf32(_buffer, Pointer + 4),
				buffer.readf32(_buffer, Pointer + 8)
			),
			Vector3.new(
				buffer.readf32(_buffer, Pointer + 12),
				buffer.readf32(_buffer, Pointer + 16),
				buffer.readf32(_buffer, Pointer + 20)
			)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Ray)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 24

		local Origin: Vector3 = Value.Origin
		local Direction: Vector3 = Value.Direction

		buffer.writef32(_buffer, Pointer, Origin.X)
		buffer.writef32(_buffer, Pointer + 4, Origin.Y)
		buffer.writef32(_buffer, Pointer + 8, Origin.Z)

		buffer.writef32(_buffer, Pointer + 12, Direction.X)
		buffer.writef32(_buffer, Pointer + 16, Direction.Y)
		buffer.writef32(_buffer, Pointer + 20, Direction.Z)
	end,
}