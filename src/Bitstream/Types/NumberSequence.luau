--[==[
	Author: 8ch99
	File: NumberSequence.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local SIZE_PER_KEYPOINT = 12

return {
	GetSize = function(Value: NumberSequence): number
		return 1 + SIZE_PER_KEYPOINT * #Value.Keypoints
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): NumberSequence
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Keypoints: { NumberSequenceKeypoint } = {}
		local Size: number = buffer.readu8(_buffer, Pointer)

		Buffer.Pointer += 1 + SIZE_PER_KEYPOINT * Size
		Pointer += 1

		for _ = 1, Size do
			table.insert(Keypoints, NumberSequenceKeypoint.new(
				buffer.readf32(_buffer, Pointer),
				buffer.readf32(_buffer, Pointer + 4),
				buffer.readf32(_buffer, Pointer + 8)
			))
			
			Pointer += SIZE_PER_KEYPOINT
		end

		return NumberSequence.new(Keypoints)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: NumberSequence)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer
		
		local Keypoints: { NumberSequenceKeypoint } = Value.Keypoints
		local Size: number = #Keypoints

		Buffer.Pointer += 1 + SIZE_PER_KEYPOINT * Size

		buffer.writeu8(_buffer, Pointer, Size)
		Pointer += 1

		for _, Keypoint: NumberSequenceKeypoint in Keypoints do
			buffer.writef32(_buffer, Pointer, Keypoint.Time)
			buffer.writef32(_buffer, Pointer + 4, Keypoint.Value)
			buffer.writef32(_buffer, Pointer + 8, Keypoint.Envelope)

			Pointer += SIZE_PER_KEYPOINT
		end
	end,
}