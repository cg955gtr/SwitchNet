--[==[
	Author: 8ch99
	File: Path2DControlPoint.luau
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
	Size = 48,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Path2DControlPoint
		return Path2DControlPoint.new(
			ReadUDim2(Buffer),
			ReadUDim2(Buffer),
			ReadUDim2(Buffer)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Path2DControlPoint)
		WriteUDim2(Buffer, Value.Position)
		WriteUDim2(Buffer, Value.LeftTangent)
		WriteUDim2(Buffer, Value.RightTangent)
	end,
}