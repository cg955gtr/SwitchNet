--[==[
	Author: 8ch99
	File: Region3int16.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadVector3int16 = ByteBuffer.ReadVector3int16

local WriteVector3int16 = ByteBuffer.WriteVector3int16

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Region3int16
		local Min: Vector3int16 = ReadVector3int16(Buffer)
		local Max: Vector3int16 = ReadVector3int16(Buffer)

		return Region3int16.new(Min, Max)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Region3int16)
		WriteVector3int16(Buffer, Value.Min)
		WriteVector3int16(Buffer, Value.Max)
	end,
}