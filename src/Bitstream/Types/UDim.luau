--[==[
	Author: 8ch99
	File: UDim.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadUDim = ByteBuffer.ReadUDim

local WriteUDim = ByteBuffer.WriteUDim

return {
	Size = 8,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): UDim
		return ReadUDim(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: UDim)
		WriteUDim(Buffer, Value)
	end,
}