--[==[
	Author: 8ch99
	File: FloatCurveKey.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 17,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): FloatCurveKey
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 17

		local Time: number = buffer.readf32(_buffer, Pointer)
		local Value: number = buffer.readf32(_buffer, Pointer + 4)
		local Mode: number = buffer.readu8(_buffer, Pointer + 8)
		local LeftTangent: number = buffer.readf32(_buffer, Pointer + 9)
		local RightTangent: number = buffer.readf32(_buffer, Pointer + 13)

		local Key: FloatCurveKey =  FloatCurveKey.new(Time, Value, Enum.KeyInterpolationMode:FromValue(Mode) :: Enum.KeyInterpolationMode)

		Key.LeftTangent = LeftTangent
		Key.RightTangent = RightTangent

		return Key
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: FloatCurveKey)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 17

		buffer.writef32(_buffer, Pointer, Value.Time)
		buffer.writef32(_buffer, Pointer + 4, Value.Value)
		buffer.writeu8(_buffer, Pointer + 8, Value.Interpolation.Value)
		buffer.writef32(_buffer, Pointer + 9, Value.LeftTangent or 0)
		buffer.writef32(_buffer, Pointer + 13, Value.RightTangent or 0)
	end,
}