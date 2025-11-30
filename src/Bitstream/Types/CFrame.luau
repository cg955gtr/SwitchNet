--[==[
	Author: 8ch99
	File: CFrame.luau
	Date written: 15th November 2025
	Last edited: 30th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local LOSSLESS: boolean = false
--// ^ If you ever run into issues with CFrame rotations, enable this
local SIZE: number = if LOSSLESS then 48 else 24

return {
	Size = SIZE,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): CFrame
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += SIZE

		if LOSSLESS then
			local Position: Vector3 = Vector3.new(
				buffer.readf32(_buffer, Pointer),
				buffer.readf32(_buffer, Pointer + 4),
				buffer.readf32(_buffer, Pointer + 8)
			)

			local rX: Vector3 = Vector3.new(
				buffer.readf32(_buffer, Pointer + 12),
				buffer.readf32(_buffer, Pointer + 16),
				buffer.readf32(_buffer, Pointer + 20)
			)

			local rY: Vector3 = Vector3.new(
				buffer.readf32(_buffer, Pointer + 24),
				buffer.readf32(_buffer, Pointer + 28),
				buffer.readf32(_buffer, Pointer + 32)
			)

			local rZ: Vector3 = Vector3.new(
				buffer.readf32(_buffer, Pointer + 36),
				buffer.readf32(_buffer, Pointer + 40),
				buffer.readf32(_buffer, Pointer + 44)
			)

			return CFrame.fromMatrix(Position, rX, rY, rZ)
		else
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

			return BaseCFrame
		end
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: CFrame)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += SIZE

		buffer.writef32(_buffer, Pointer, Value.X)
		buffer.writef32(_buffer, Pointer + 4, Value.Y)
		buffer.writef32(_buffer, Pointer + 8, Value.Z)
		
		if LOSSLESS then
			local rX: Vector3 = Value.XVector
			local rY: Vector3 = Value.YVector
			local rZ: Vector3 = Value.ZVector

			buffer.writef32(_buffer, Pointer + 12, rX.X)
			buffer.writef32(_buffer, Pointer + 16, rX.Y)
			buffer.writef32(_buffer, Pointer + 20, rX.Z)

			buffer.writef32(_buffer, Pointer + 24, rY.X)
			buffer.writef32(_buffer, Pointer + 28, rY.Y)
			buffer.writef32(_buffer, Pointer + 32, rY.Z)

			buffer.writef32(_buffer, Pointer + 36, rZ.X)
			buffer.writef32(_buffer, Pointer + 40, rZ.Y)
			buffer.writef32(_buffer, Pointer + 44, rZ.Z)
		else
			local rX: number, rY: number, rZ: number = Value:ToEulerAnglesXYZ()
			
			buffer.writef32(_buffer, Pointer + 12, rX)
			buffer.writef32(_buffer, Pointer + 16, rY)
			buffer.writef32(_buffer, Pointer + 20, rZ)
		end
	end,
}