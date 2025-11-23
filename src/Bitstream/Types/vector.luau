--[==[
	Author: 8ch99
	File: string.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadVector = ByteBuffer.ReadVector

local WriteVector = ByteBuffer.WriteVector

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): vector
		return ReadVector(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: vector)
		WriteVector(Buffer, Value)
	end,
}