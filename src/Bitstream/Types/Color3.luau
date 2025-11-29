--[==[
	Author: 8ch99
	File: Color3.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 3,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Color3
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 3

		return Color3.new(
			buffer.readu8(_buffer, Pointer),
			buffer.readu8(_buffer, Pointer + 1),
			buffer.readu8(_buffer, Pointer + 2)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Color3)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		buffer.writeu8(_buffer, Pointer, math.round(Value.R * 255))
		buffer.writeu8(_buffer, Pointer + 1, math.round(Value.G * 255))
		buffer.writeu8(_buffer, Pointer + 2, math.round(Value.B * 255))

		Buffer.Pointer += 3
	end,
}