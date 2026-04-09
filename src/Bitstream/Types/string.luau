--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	GetSize = function(Value: string): number
		return 2 + #Value
	end,

	Reader = function(buff: buffer, references: { any }, pointer: number): (string, number)
		local size = buffer.readu16(buff, pointer)
		if size == 0 then
			return "", 2
		end
		return buffer.readstring(buff, pointer + 2, size), 2 + size
	end,

	Writer = function(buff: buffer, references: { any }, pointer: number, value: string): number
		local size = #value
		buffer.writeu16(buff, pointer, size)
		if size > 0 then
			buffer.writestring(buff, pointer + 2, value)
		end
		return 2 + size
	end,
}