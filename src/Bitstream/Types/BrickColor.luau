--[==[
	Author: 8ch99
	File: BrickColor.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 2,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): BrickColor
		local Value: number = buffer.readu16(Buffer._buffer, Buffer.Pointer)

		Buffer.Pointer += 2

		return BrickColor.new(Value)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: BrickColor)
		buffer.writeu16(Buffer._buffer, Buffer.Pointer, Value.Number)

		Buffer.Pointer += 2
	end,
}