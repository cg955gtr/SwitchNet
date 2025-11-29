--[==[
	Author: 8ch99
	File: Rect.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 16,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Rect
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 16

		return Rect.new(
			Vector2.new(
				buffer.readf32(_buffer, Pointer),
				buffer.readf32(_buffer, Pointer + 4)
			),
			Vector2.new(
				buffer.readf32(_buffer, Pointer + 8),
				buffer.readf32(_buffer, Pointer + 12)
			)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Rect)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 16

		local Min: Vector2 = Value.Min
		local Max: Vector2 = Value.Max

		buffer.writef32(_buffer, Pointer, Min.X)
		buffer.writef32(_buffer, Pointer + 4, Min.Y)

		buffer.writef32(_buffer, Pointer + 8, Max.X)
		buffer.writef32(_buffer, Pointer + 12, Max.Y)
	end,
}