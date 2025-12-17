--[==[
	Author: 8ch99
	File: number.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 8,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (number, number)
		return buffer.readf64(Buffer, Pointer), 8
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: number): number
		buffer.writef64(Buffer, Pointer, Value)
		return 8
	end,
}