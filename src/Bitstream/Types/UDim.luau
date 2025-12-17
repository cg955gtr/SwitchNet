--[==[
	Author: 8ch99
	File: UDim.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 8,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (UDim, number)
		return UDim.new(
			buffer.readf32(Buffer, Pointer),
			buffer.readi32(Buffer, Pointer + 4)
		), 8
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: UDim): number
		buffer.writef32(Buffer, Pointer, Value.Scale)
		buffer.writei32(Buffer, Pointer + 4, Value.Offset)
		return 8
	end,
}