--[==[
	Author: 8ch99
	File: NumberSequenceKeypoint.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadFloat32 = ByteBuffer.ReadFloat32

local WriteFloat32 = ByteBuffer.WriteFloat32

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): NumberSequenceKeypoint
		return NumberSequenceKeypoint.new(
			ReadFloat32(Buffer),
			ReadFloat32(Buffer),
			ReadFloat32(Buffer)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: NumberSequenceKeypoint)
		WriteFloat32(Buffer, Value.Time)
		WriteFloat32(Buffer, Value.Value)
		WriteFloat32(Buffer, Value.Envelope)
	end,
}