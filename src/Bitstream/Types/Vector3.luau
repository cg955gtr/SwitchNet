--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 12,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (Vector3, number)
		return Vector3.new(
			buffer.readf32(Buffer, Pointer),
			buffer.readf32(Buffer, Pointer + 4),
			buffer.readf32(Buffer, Pointer + 8)
		), 12
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: Vector3): number
		buffer.writef32(Buffer, Pointer, Value.X)
		buffer.writef32(Buffer, Pointer + 4, Value.Y)
		buffer.writef32(Buffer, Pointer + 8, Value.Z)
		return 12
	end,
}