--[==[
	Author: 8ch99
	File: string.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	GetSize = function(Value: string): number
		return 4 + #Value
	end,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (string, number)
		local Size: number = buffer.readu32(Buffer, Pointer)

		if Size == 0 then
			return "", 4
		end

		return buffer.readstring(Buffer, Pointer + 4, Size), 4 + Size
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: string): number
		local Size: number = #Value

		buffer.writeu32(Buffer, Pointer, Size)
		
		if Size > 0 then
			buffer.writestring(Buffer, Pointer + 4, Value)
		end

		return 4 + Size
	end,
}