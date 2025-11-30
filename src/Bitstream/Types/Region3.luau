--[==[
	Author: 8ch99
	File: Region3.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 24,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Region3
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 24

		return Region3.new(
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

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Region3)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 24

		local Origin: Vector3 = Value.CFrame.Position
		local Size: Vector3 = Value.Size / 2

		local Min: Vector3 = Origin - Size
		local Max: Vector3 = Origin + Size

		buffer.writef32(_buffer, Pointer, Min.X)
		buffer.writef32(_buffer, Pointer + 4, Min.Y)
		buffer.writef32(_buffer, Pointer + 8, Min.Z)

		buffer.writef32(_buffer, Pointer + 12, Max.X)
		buffer.writef32(_buffer, Pointer + 16, Max.Y)
		buffer.writef32(_buffer, Pointer + 20, Max.Z)
	end,
}