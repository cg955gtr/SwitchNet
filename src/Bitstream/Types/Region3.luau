--[==[
	Author: 8ch99
	File: Region3.luau
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

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): Region3
		local Min: Vector3 = ReadVector3(Buffer)
		local Max: Vector3 = ReadVector3(Buffer)

		return Region3.new(Min, Max)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: Region3)
		local Origin: Vector3 = Value.CFrame.Position
		local Size: Vector3 = Value.Size / 2

		WriteVector3(Buffer, Origin - Size)
		WriteVector3(Buffer, Origin + Size)
	end,
}