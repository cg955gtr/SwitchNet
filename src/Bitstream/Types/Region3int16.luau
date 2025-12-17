--[==[
	Author: 8ch99
	File: Region3int16.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 12,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (Region3int16, number)
		return Region3int16.new(
			Vector3int16.new(
				buffer.readi16(Buffer, Pointer),
				buffer.readi16(Buffer, Pointer + 2),
				buffer.readi16(Buffer, Pointer + 4)
			),
			Vector3int16.new(
				buffer.readi16(Buffer, Pointer + 6),
				buffer.readi16(Buffer, Pointer + 8),
				buffer.readi16(Buffer, Pointer + 10)
			)
		), 12
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: Region3int16): number
		local Min: Vector3int16 = Value.Min
		local Max: Vector3int16 = Value.Max

		buffer.writef32(Buffer, Pointer, Min.X)
		buffer.writef32(Buffer, Pointer + 2, Min.Y)
		buffer.writef32(Buffer, Pointer + 4, Min.Z)

		buffer.writef32(Buffer, Pointer + 6, Max.X)
		buffer.writef32(Buffer, Pointer + 8, Max.Y)
		buffer.writef32(Buffer, Pointer + 10, Max.Z)

		return 12
	end,
}