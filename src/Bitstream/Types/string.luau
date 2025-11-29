--[==[
	Author: 8ch99
	File: string.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	GetSize = function(Value: string): number
		return 4 + #Value
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): string
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Size: number = buffer.readu32(_buffer, Pointer)

		Buffer.Pointer += 4 + Size

		if Size == 0 then
			return ""
		end

		local String: string = buffer.readstring(_buffer, Pointer + 4, Size)

		return String
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: string)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Size: number = #Value

		Buffer.Pointer += 4 + Size

		buffer.writeu16(_buffer, Pointer, Size)
		
		if Size > 0 then
			buffer.writestring(_buffer, Pointer + 4, Value)
		end
	end,
}