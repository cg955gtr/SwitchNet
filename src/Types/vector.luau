--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 12,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (vector, number)
		return vector.create(
			buffer.readf32(Buffer, Pointer),
			buffer.readf32(Buffer, Pointer + 4),
			buffer.readf32(Buffer, Pointer + 8)
		), 12
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: vector): number
		buffer.writef32(Buffer, Pointer, Value.x)
		buffer.writef32(Buffer, Pointer + 4, Value.y)
		buffer.writef32(Buffer, Pointer + 8, Value.z)
		return 12
	end,
}