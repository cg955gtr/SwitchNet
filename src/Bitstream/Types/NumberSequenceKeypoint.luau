--[==[
	Author: 8ch99
	File: NumberSequenceKeypoint.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 12,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (NumberSequenceKeypoint, number)
		return NumberSequenceKeypoint.new(
			buffer.readf32(Buffer, Pointer),
			buffer.readf32(Buffer, Pointer + 4),
			buffer.readf32(Buffer, Pointer + 8)
		), 12
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: NumberSequenceKeypoint): number
		buffer.writef32(Buffer, Pointer, Value.Time)
		buffer.writef32(Buffer, Pointer + 4, Value.Value)
		buffer.writef32(Buffer, Pointer + 8, Value.Envelope)
		return 12
	end,
}