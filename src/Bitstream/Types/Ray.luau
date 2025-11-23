--[==[
	Author: 8ch99
	File: Ray.luau
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
	Size = 24,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Ray
		return Ray.new(
			ReadVector3(Buffer),
			ReadVector3(Buffer)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Ray)
		WriteVector3(Buffer, Value.Origin)
		WriteVector3(Buffer, Value.Direction)
	end,
}