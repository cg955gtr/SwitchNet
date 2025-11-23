--[==[
	Author: 8ch99
	File: NumberSequence.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local SIZE_PER_KEYPOINT = 12

local ReadUInt8 = ByteBuffer.ReadUInt8
local ReadFloat32 = ByteBuffer.ReadFloat32

local WriteUInt8 = ByteBuffer.WriteUInt8
local WriteFloat32 = ByteBuffer.WriteFloat32

return {
	GetSize = function(Value: NumberSequence): number
		return 1 + SIZE_PER_KEYPOINT * #Value.Keypoints
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): NumberSequence
		local Keypoints: { NumberSequenceKeypoint } = {}
		local Size: number = ReadUInt8(Buffer)

		for _ = 1, Size do
			table.insert(Keypoints, NumberSequenceKeypoint.new(
				ReadFloat32(Buffer),
				ReadFloat32(Buffer),
				ReadFloat32(Buffer)
			))
		end

		return NumberSequence.new(Keypoints)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: NumberSequence)
		local Keypoints: { NumberSequenceKeypoint } = Value.Keypoints
		local Size: number = #Keypoints

		WriteUInt8(Buffer, Size)

		for _, Keypoint: NumberSequenceKeypoint in Keypoints do
			WriteFloat32(Buffer, Keypoint.Time)
			WriteFloat32(Buffer, Keypoint.Value)
			WriteFloat32(Buffer, Keypoint.Envelope)
		end
	end,
}