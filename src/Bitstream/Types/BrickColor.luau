--[==[
	Author: 8ch99
	File: BrickColor.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadBrickColor = ByteBuffer.ReadBrickColor

local WriteBrickColor = ByteBuffer.WriteBrickColor

return {
	Size = 2,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): BrickColor
		return ReadBrickColor(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: BrickColor)
		WriteBrickColor(Buffer, Value)
	end,
}