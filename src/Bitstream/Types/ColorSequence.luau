--[==[
	Author: 8ch99
	File: ColorSequence.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

local SIZE_PER_KEYPOINT: number = 7

return {
	GetSize = function(Value: ColorSequence): number
		return 1 + SIZE_PER_KEYPOINT * #Value.Keypoints
	end,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (ColorSequence, number)
		local Keypoints: { ColorSequenceKeypoint } = {}
		local Size: number = buffer.readu8(Buffer, Pointer)

		Pointer += 1

		for _ = 1, Size do
			table.insert(Keypoints, ColorSequenceKeypoint.new(
				buffer.readf32(Buffer, Pointer),
				Color3.fromRGB(
					buffer.readu8(Buffer, Pointer + 4),
					buffer.readu8(Buffer, Pointer + 5),
					buffer.readu8(Buffer, Pointer + 6)
				)
			))
			
			Pointer += SIZE_PER_KEYPOINT
		end

		return ColorSequence.new(Keypoints), 1 + SIZE_PER_KEYPOINT * Size
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: ColorSequence): number
		local Keypoints: { ColorSequenceKeypoint } = Value.Keypoints
		local Size: number = #Keypoints

		buffer.writeu8(Buffer, Pointer, Size)
		Pointer += 1

		for _, Keypoint: ColorSequenceKeypoint in Keypoints do
			local Color: Color3 = Keypoint.Value

			buffer.writef32(Buffer, Pointer, Keypoint.Time)
			
			buffer.writeu8(Buffer, Pointer + 4, math.round(Color.R * 255))
			buffer.writeu8(Buffer, Pointer + 5, math.round(Color.G * 255))
			buffer.writeu8(Buffer, Pointer + 6, math.round(Color.B * 255))

			Pointer += SIZE_PER_KEYPOINT
		end

		return 1 + SIZE_PER_KEYPOINT * Size
	end,
}