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
		return 2 + buffer.len(Value)
	end,

	Reader = function(buff: buffer, references: { any }, pointer: number): (buffer, number)
		local size = buffer.readu16(buff, pointer)
		local newBuffer = buffer.create(size)
		if size == 0 then
			return newBuffer, 2
		end
			
		buffer.copy(newBuffer, 0, buff, pointer + 2, size)
		return newBuffer, 2 + size
	end,

	Writer = function(buff: buffer, references: { any }, pointer: number, value: buffer): number
		local size = buffer.len(value)
		buffer.writeu16(buff, pointer, size)
		if size > 0 then
			buffer.copy(buff, pointer + 2, value, size)
		end
		return 2 + size
	end,
}