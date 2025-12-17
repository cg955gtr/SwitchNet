--[==[
	Author: 8ch99
	File: UDim2.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 16,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (UDim2, number)
		return UDim2.new(
			buffer.readf32(Buffer, Pointer),
			buffer.readi32(Buffer, Pointer + 4),
			buffer.readf32(Buffer, Pointer + 8),
			buffer.readi32(Buffer, Pointer + 12)
		), 16
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: UDim2): number
		local X: UDim, Y: UDim = Value.X, Value.Y

		buffer.writef32(Buffer, Pointer, X.Scale)
		buffer.writei32(Buffer, Pointer + 4, X.Offset)
		buffer.writef32(Buffer, Pointer + 8, Y.Scale)
		buffer.writei32(Buffer, Pointer + 12, Y.Offset)

		return 16
	end,
}