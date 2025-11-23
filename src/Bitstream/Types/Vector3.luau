--[==[
	Author: 8ch99
	File: Vector3.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadVector3 = ByteBuffer.ReadVector3

local WriteVector3 = ByteBuffer.WriteVector3

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Vector3
		return ReadVector3(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Vector3)
		WriteVector3(Buffer, Value)
	end,
}