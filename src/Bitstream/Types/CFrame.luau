--[==[
	Author: 8ch99
	File: CFrame.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 24,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): CFrame
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local BaseCFrame: CFrame = CFrame.new(
			buffer.readf32(_buffer, Pointer),
			buffer.readf32(_buffer, Pointer + 4),
			buffer.readf32(_buffer, Pointer + 8)
		)

		BaseCFrame *= CFrame.fromEulerAnglesXYZ(
			buffer.readf32(_buffer, Pointer + 12),
			buffer.readf32(_buffer, Pointer + 16),
			buffer.readf32(_buffer, Pointer + 20)
		)

		Buffer.Pointer += 24

		return BaseCFrame
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: CFrame)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

        local Axis: Vector3, Angle: number = Value:ToAxisAngle()
        Axis *= Angle
		
		local rX: number, rY: number, rZ: number = Axis.X, Axis.Y, Axis.Z

		buffer.writef32(_buffer, Pointer, Value.X)
		buffer.writef32(_buffer, Pointer + 4, Value.Y)
		buffer.writef32(_buffer, Pointer + 8, Value.Z)

		buffer.writef32(_buffer, Pointer + 12, rX)
		buffer.writef32(_buffer, Pointer + 16, rY)
		buffer.writef32(_buffer, Pointer + 20, rZ)

		Buffer.Pointer += 24
	end,
}