--[==[
	Author: 8ch99
	File: Vector3int16.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 6,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (Vector3int16, number)
		return Vector3int16.new(
			buffer.readi16(Buffer, Pointer),
			buffer.readi16(Buffer, Pointer + 2),
			buffer.readi16(Buffer, Pointer + 6)
		), 6
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: Vector3int16): number
		buffer.writei16(Buffer, Pointer, Value.X)
		buffer.writei16(Buffer, Pointer + 2, Value.Y)
		buffer.writei16(Buffer, Pointer + 4, Value.Z)
		return 6
	end,
}