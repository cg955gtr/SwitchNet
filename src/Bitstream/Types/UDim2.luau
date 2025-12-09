--[==[
	Author: 8ch99
	File: UDim2.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 16,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): UDim2
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 16

		return UDim2.new(
			buffer.readf32(_buffer, Pointer),
			buffer.readi32(_buffer, Pointer + 4),
			buffer.readf32(_buffer, Pointer + 8),
			buffer.readi32(_buffer, Pointer + 12)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: UDim2)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 16

		local X: UDim, Y: UDim = Value.X, Value.Y

		buffer.writef32(_buffer, Pointer, X.Scale)
		buffer.writei32(_buffer, Pointer + 4, X.Offset)
		buffer.writef32(_buffer, Pointer + 8, Y.Scale)
		buffer.writei32(_buffer, Pointer + 12, Y.Offset)
	end,
}