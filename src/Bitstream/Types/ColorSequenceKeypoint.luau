--[==[
	Author: 8ch99
	File: ColorSequenceKeypoint.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadFloat32 = ByteBuffer.ReadFloat32
local ReadColor3 = ByteBuffer.ReadColor3

local WriteFloat32 = ByteBuffer.WriteFloat32
local WriteColor3 = ByteBuffer.WriteColor3

return {
	Size = 7,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): ColorSequenceKeypoint
		local Time: number = ReadFloat32(Buffer)
		local Color: Color3 = ReadColor3(Buffer)

		return ColorSequenceKeypoint.new(Time, Color)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: ColorSequenceKeypoint)
		WriteFloat32(Buffer, Value.Time)
		WriteColor3(Buffer, Value.Value)
	end,
}