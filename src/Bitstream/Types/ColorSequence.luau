--[==[
	Author: 8ch99
	File: ColorSequence.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local SIZE_PER_KEYPOINT = 7

local ReadUInt8 = ByteBuffer.ReadUInt8
local ReadFloat32 = ByteBuffer.ReadFloat32
local ReadColor3 = ByteBuffer.ReadColor3

local WriteUInt8 = ByteBuffer.WriteUInt8
local WriteFloat32 = ByteBuffer.WriteFloat32
local WriteColor3 = ByteBuffer.WriteColor3

return {
	GetSize = function(Value: ColorSequence): number
		return 1 + SIZE_PER_KEYPOINT * #Value.Keypoints
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): ColorSequence
		local Keypoints: { ColorSequenceKeypoint } = {}
		local Size: number = ReadUInt8(Buffer)

		for _ = 1, Size do
			table.insert(Keypoints, ColorSequenceKeypoint.new(
				ReadFloat32(Buffer),
				ReadColor3(Buffer)
			))
		end

		return ColorSequence.new(Keypoints)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: ColorSequence)
		local Keypoints: { ColorSequenceKeypoint } = Value.Keypoints
		local Size: number = #Keypoints

		WriteUInt8(Buffer, Size)

		for _, Keypoint: ColorSequenceKeypoint in Keypoints do
			WriteFloat32(Buffer, Keypoint.Time)
			WriteColor3(Buffer, Keypoint.Value)
		end
	end,
}