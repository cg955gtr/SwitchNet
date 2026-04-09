--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 4,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (Vector2int16, number)
		return Vector2int16.new(
			buffer.readi16(Buffer, Pointer),
			buffer.readi16(Buffer, Pointer + 2)
		), 4
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: Vector2int16): number
		buffer.writei16(Buffer, Pointer, Value.X)
		buffer.writei16(Buffer, Pointer + 2, Value.Y)
		return 4
	end,
}