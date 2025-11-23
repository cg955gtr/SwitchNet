--[==[
	Author: 8ch99
	File: CFrame.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadCFrame = ByteBuffer.ReadCFrame

local WriteCFrame = ByteBuffer.WriteCFrame

return {
	Size = 24,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): CFrame
		return ReadCFrame(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: CFrame)
		WriteCFrame(Buffer, Value)
	end,
}