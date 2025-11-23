--[==[
	Author: 8ch99
	File: UDim2.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadUDim2 = ByteBuffer.ReadUDim2

local WriteUDim2 = ByteBuffer.WriteUDim2

return {
	Size = 16,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): UDim2
		return ReadUDim2(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: UDim2)
		WriteUDim2(Buffer, Value)
	end,
}