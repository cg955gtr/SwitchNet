--[==[
	Author: 8ch99
	File: NumberRange.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 8,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): NumberRange
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 8

		return NumberRange.new(
			buffer.readf32(_buffer, Pointer),
			buffer.readf32(_buffer, Pointer + 4)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: NumberRange)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 8
		
		buffer.writef32(_buffer, Pointer, Value.Min)
		buffer.writef32(_buffer, Pointer + 4, Value.Max)
	end,
}