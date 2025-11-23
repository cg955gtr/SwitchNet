--[==[
	Author: 8ch99
	File: Vector3int16.luau
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
	Size = 6,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Vector3int16
		return ReadVector3int16(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Vector3int16)
		WriteVector3int16(Buffer, Value)
	end,
}