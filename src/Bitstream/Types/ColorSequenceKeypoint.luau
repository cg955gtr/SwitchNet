--[==[
	Author: 8ch99
	File: ColorSequenceKeypoint.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 7,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): ColorSequenceKeypoint
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Time: number = buffer.readf32(_buffer, Pointer)
		local Color: Color3 = Color3.fromRGB(
			buffer.readu8(_buffer, Pointer + 4),
			buffer.readu8(_buffer, Pointer + 5),
			buffer.readu8(_buffer, Pointer + 6)
		)

		Buffer.Pointer += 7

		return ColorSequenceKeypoint.new(Time, Color)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: ColorSequenceKeypoint)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 7

		local Color: Color3 = Value.Value

		buffer.writef32(_buffer, Pointer, Value.Time)
			
		buffer.writeu8(_buffer, Pointer + 1, math.round(Color.R * 255))
		buffer.writeu8(_buffer, Pointer + 2, math.round(Color.G * 255))
		buffer.writeu8(_buffer, Pointer + 3, math.round(Color.B * 255))
	end,
}