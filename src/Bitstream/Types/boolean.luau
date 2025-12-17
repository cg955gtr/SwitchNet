--[==[
	Author: 8ch99
	File: boolean.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 1,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (boolean, number)
		return buffer.readu8(Buffer, Pointer) ~= 0, 1
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: boolean): number
		buffer.writeu8(Buffer, Pointer, if Value then 1 else 0)
		return 1
	end,
}