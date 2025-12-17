--[==[
	Author: 8ch99
	File: Rect.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 16,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (Rect, number)
		return Rect.new(
			Vector2.new(
				buffer.readf32(Buffer, Pointer),
				buffer.readf32(Buffer, Pointer + 4)
			),
			Vector2.new(
				buffer.readf32(Buffer, Pointer + 8),
				buffer.readf32(Buffer, Pointer + 12)
			)
		), 16
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: Rect): number
		local Min: Vector2 = Value.Min
		local Max: Vector2 = Value.Max

		buffer.writef32(Buffer, Pointer, Min.X)
		buffer.writef32(Buffer, Pointer + 4, Min.Y)

		buffer.writef32(Buffer, Pointer + 8, Max.X)
		buffer.writef32(Buffer, Pointer + 12, Max.Y)

		return 16
	end,
}