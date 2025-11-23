--[==[
	Author: 8ch99
	File: Rect.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadVector2 = ByteBuffer.ReadVector2

local WriteVector2 = ByteBuffer.WriteVector2

return {
	Size = 16,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Rect
		return Rect.new(
			ReadVector2(Buffer),
			ReadVector2(Buffer)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Rect)
		WriteVector2(Buffer, Value.Min)
		WriteVector2(Buffer, Value.Max)
	end,
}