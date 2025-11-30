--[==[
	Author: 8ch99
	File: Region3int16.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Region3int16
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 12

		return Region3int16.new(
			Vector3int16.new(
				buffer.readi16(_buffer, Pointer),
				buffer.readi16(_buffer, Pointer + 2),
				buffer.readi16(_buffer, Pointer + 4)
			),
			Vector3int16.new(
				buffer.readi16(_buffer, Pointer + 6),
				buffer.readi16(_buffer, Pointer + 8),
				buffer.readi16(_buffer, Pointer + 10)
			)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Region3int16)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 12

		local Min: Vector3int16 = Value.Min
		local Max: Vector3int16 = Value.Max

		buffer.writef32(_buffer, Pointer, Min.X)
		buffer.writef32(_buffer, Pointer + 2, Min.Y)
		buffer.writef32(_buffer, Pointer + 4, Min.Z)

		buffer.writef32(_buffer, Pointer + 6, Max.X)
		buffer.writef32(_buffer, Pointer + 8, Max.Y)
		buffer.writef32(_buffer, Pointer + 10, Max.Z)
	end,
}