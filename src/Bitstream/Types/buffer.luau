--[==[
	Author: 8ch99
	File: buffer.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	GetSize = function(Value: buffer): number
		return 4 + buffer.len(Value)
	end,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (buffer, number)
		local Size: number = buffer.readu32(Buffer, Pointer)

		if Size == 0 then
			return buffer.create(0), 4
		end

		local String: string = buffer.readstring(Buffer, Pointer + 4, Size)

		return buffer.fromstring(String), 4 + Size
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: buffer): number
		local Size: number = buffer.len(Value)

		buffer.writeu32(Buffer, Pointer, Size)
		
		if Size > 0 then
			buffer.writestring(Buffer, Pointer + 4, buffer.tostring(Value))
		end

		return 4 + Size
	end,
}