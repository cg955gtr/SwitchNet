--[==[
	Author: 8ch99
	File: Region3.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 24,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (Region3, number)
		return Region3.new(
			Vector3.new(
				buffer.readf32(Buffer, Pointer),
				buffer.readf32(Buffer, Pointer + 4),
				buffer.readf32(Buffer, Pointer + 8)
			),
			Vector3.new(
				buffer.readf32(Buffer, Pointer + 12),
				buffer.readf32(Buffer, Pointer + 16),
				buffer.readf32(Buffer, Pointer + 20)
			)
		), 24
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: Region3): number
		local Origin: Vector3 = Value.CFrame.Position
		local Size: Vector3 = Value.Size / 2

		local Min: Vector3 = Origin - Size
		local Max: Vector3 = Origin + Size

		buffer.writef32(Buffer, Pointer, Min.X)
		buffer.writef32(Buffer, Pointer + 4, Min.Y)
		buffer.writef32(Buffer, Pointer + 8, Min.Z)

		buffer.writef32(Buffer, Pointer + 12, Max.X)
		buffer.writef32(Buffer, Pointer + 16, Max.Y)
		buffer.writef32(Buffer, Pointer + 20, Max.Z)

		return 24
	end,
}