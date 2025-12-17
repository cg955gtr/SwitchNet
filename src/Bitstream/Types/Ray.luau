--[==[
	Author: 8ch99
	File: Ray.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 24,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (Ray, number)
		return Ray.new(
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

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: Ray): number
		local Origin: Vector3 = Value.Origin
		local Direction: Vector3 = Value.Direction

		buffer.writef32(Buffer, Pointer, Origin.X)
		buffer.writef32(Buffer, Pointer + 4, Origin.Y)
		buffer.writef32(Buffer, Pointer + 8, Origin.Z)

		buffer.writef32(Buffer, Pointer + 12, Direction.X)
		buffer.writef32(Buffer, Pointer + 16, Direction.Y)
		buffer.writef32(Buffer, Pointer + 20, Direction.Z)

		return 24
	end,
}