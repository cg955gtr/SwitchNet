--[==[
	Author: 8ch99
	File: NumberSequence.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

local SIZE_PER_KEYPOINT: number = 12

return {
	GetSize = function(Value: NumberSequence): number
		return 1 + SIZE_PER_KEYPOINT * #Value.Keypoints
	end,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (NumberSequence, number)
		local Keypoints: { NumberSequenceKeypoint } = {}
		local Size: number = buffer.readu8(Buffer, Pointer)
		Pointer += 1

		for _ = 1, Size do
			table.insert(Keypoints, NumberSequenceKeypoint.new(
				buffer.readf32(Buffer, Pointer),
				buffer.readf32(Buffer, Pointer + 4),
				buffer.readf32(Buffer, Pointer + 8)
			))
			
			Pointer += SIZE_PER_KEYPOINT
		end

		return NumberSequence.new(Keypoints), 1 + SIZE_PER_KEYPOINT * Size
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: NumberSequence): number
		local Keypoints: { NumberSequenceKeypoint } = Value.Keypoints
		local Size: number = #Keypoints

		buffer.writeu8(Buffer, Pointer, Size)
		Pointer += 1

		for _, Keypoint: NumberSequenceKeypoint in Keypoints do
			buffer.writef32(Buffer, Pointer, Keypoint.Time)
			buffer.writef32(Buffer, Pointer + 4, Keypoint.Value)
			buffer.writef32(Buffer, Pointer + 8, Keypoint.Envelope)

			Pointer += SIZE_PER_KEYPOINT
		end

		return 1 + SIZE_PER_KEYPOINT * Size
	end,
}