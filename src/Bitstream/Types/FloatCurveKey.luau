--[==[
	Author: 8ch99
	File: FloatCurveKey.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadFloat32 = ByteBuffer.ReadFloat32
local ReadUInt8 = ByteBuffer.ReadUInt8

local WriteFloat32 = ByteBuffer.WriteFloat32
local WriteUInt8 = ByteBuffer.WriteUInt8

return {
	Size = 17,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): FloatCurveKey
		local Time: number = ReadFloat32(Buffer)
		local Value: number = ReadFloat32(Buffer)
		local Mode: number = ReadUInt8(Buffer)
		local LeftTangent: number = ReadFloat32(Buffer)
		local RightTangent: number = ReadFloat32(Buffer)

		local Key: FloatCurveKey =  FloatCurveKey.new(Time, Value, Enum.KeyInterpolationMode:FromValue(Mode) :: Enum.KeyInterpolationMode)

		Key.LeftTangent = LeftTangent
		Key.RightTangent = RightTangent

		return Key
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: FloatCurveKey)
		WriteFloat32(Buffer, Value.Time)
		WriteFloat32(Buffer, Value.Value)
		WriteUInt8(Buffer, Value.Interpolation.Value)
		WriteFloat32(Buffer, Value.LeftTangent or 0)
		WriteFloat32(Buffer, Value.RightTangent or 0)
	end,
}