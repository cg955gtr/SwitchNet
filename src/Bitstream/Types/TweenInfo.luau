--[==[
	Author: 8ch99
	File: TweenInfo.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadTweenInfo = ByteBuffer.ReadTweenInfo

local WriteTweenInfo = ByteBuffer.WriteTweenInfo

return {
	Size = 15,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): TweenInfo
		return ReadTweenInfo(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: TweenInfo)
		WriteTweenInfo(Buffer, Value)
	end,
}