--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 8,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (Vector2, number)
		return Vector2.new(
			buffer.readf32(Buffer, Pointer),
			buffer.readf32(Buffer, Pointer + 4)
		), 8
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: Vector2): number
		buffer.writef32(Buffer, Pointer, Value.X)
		buffer.writef32(Buffer, Pointer + 4, Value.Y)
		return 8
	end,
}