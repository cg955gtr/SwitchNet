--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 7,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (ColorSequenceKeypoint, number)
		local Time: number = buffer.readf32(Buffer, Pointer)
		local Color: Color3 = Color3.fromRGB(
			buffer.readu8(Buffer, Pointer + 4),
			buffer.readu8(Buffer, Pointer + 5),
			buffer.readu8(Buffer, Pointer + 6)
		)

		return ColorSequenceKeypoint.new(Time, Color), 7
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: ColorSequenceKeypoint): number
		local Color: Color3 = Value.Value

		buffer.writef32(Buffer, Pointer, Value.Time)
			
		buffer.writeu8(Buffer, Pointer + 1, math.round(Color.R * 255))
		buffer.writeu8(Buffer, Pointer + 2, math.round(Color.G * 255))
		buffer.writeu8(Buffer, Pointer + 3, math.round(Color.B * 255))

		return 7
	end,
}