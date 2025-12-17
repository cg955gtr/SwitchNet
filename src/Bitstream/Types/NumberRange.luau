--[==[
	Author: 8ch99
	File: NumberRange.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 8,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (NumberRange, number)
		return NumberRange.new(
			buffer.readf32(Buffer, Pointer),
			buffer.readf32(Buffer, Pointer + 4)
		), 8
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: NumberRange): number
		buffer.writef32(Buffer, Pointer, Value.Min)
		buffer.writef32(Buffer, Pointer + 4, Value.Max)
		return 8
	end,
}