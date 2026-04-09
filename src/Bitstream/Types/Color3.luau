--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 3,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (Color3, number)
		return Color3.fromRGB(
			buffer.readu8(Buffer, Pointer),
			buffer.readu8(Buffer, Pointer + 1),
			buffer.readu8(Buffer, Pointer + 2)
		), 3
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: Color3)
		buffer.writeu8(Buffer, Pointer, math.round(Value.R * 255))
		buffer.writeu8(Buffer, Pointer + 1, math.round(Value.G * 255))
		buffer.writeu8(Buffer, Pointer + 2, math.round(Value.B * 255))

		return 3
	end,
}