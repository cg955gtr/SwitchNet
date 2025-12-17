--[==[
	Author: 8ch99
	File: BrickColor.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 2,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (BrickColor, number)
		return BrickColor.new(buffer.readu16(Buffer, Pointer)), 2
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: BrickColor): number
		buffer.writeu8(Buffer, Pointer, Value.Number)
		return 2
	end,
}