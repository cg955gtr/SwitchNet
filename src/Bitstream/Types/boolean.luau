--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 1,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (boolean, number)
		return buffer.readu8(Buffer, Pointer) ~= 0, 1
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: boolean): number
		buffer.writeu8(Buffer, Pointer, if Value then 1 else 0)
		return 1
	end,
}