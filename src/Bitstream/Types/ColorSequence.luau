--[==[
	Author: 8ch99
	File: ColorSequence.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local SIZE_PER_KEYPOINT = 7

return {
	GetSize = function(Value: ColorSequence): number
		return 1 + SIZE_PER_KEYPOINT * #Value.Keypoints
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): ColorSequence
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Keypoints: { ColorSequenceKeypoint } = {}
		local Size: number = buffer.readu8(_buffer, Pointer)

		Buffer.Pointer += 1 + SIZE_PER_KEYPOINT * Size
		Pointer += 1

		for _ = 1, Size do
			table.insert(Keypoints, ColorSequenceKeypoint.new(
				buffer.readf32(_buffer, Pointer),
				Color3.fromRGB(
					buffer.readu8(_buffer, Pointer + 4),
					buffer.readu8(_buffer, Pointer + 5),
					buffer.readu8(_buffer, Pointer + 6)
				)
			))
			
			Pointer += SIZE_PER_KEYPOINT
		end

		return ColorSequence.new(Keypoints)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: ColorSequence)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer
		
		local Keypoints: { ColorSequenceKeypoint } = Value.Keypoints
		local Size: number = #Keypoints

		Buffer.Pointer += 1 + SIZE_PER_KEYPOINT * Size

		buffer.writeu8(_buffer, Pointer, Size)
		Pointer += 1

		for _, Keypoint: ColorSequenceKeypoint in Keypoints do
			local Color: Color3 = Keypoint.Value

			buffer.writef32(_buffer, Pointer, Keypoint.Time)
			
			buffer.writeu8(_buffer, Pointer + 4, math.round(Color.R * 255))
			buffer.writeu8(_buffer, Pointer + 5, math.round(Color.G * 255))
			buffer.writeu8(_buffer, Pointer + 6, math.round(Color.B * 255))

			Pointer += SIZE_PER_KEYPOINT
		end
	end,
}