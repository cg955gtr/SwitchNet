--[==[
	Author: 8ch99
	File: buffer.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	GetSize = function(Value: buffer): number
		return 4 + buffer.len(Value)
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): buffer
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Size: number = buffer.readu32(_buffer, Pointer)

		Buffer.Pointer += 4 + Size

		if Size == 0 then
			return buffer.create(0)
		end

		local String: string = buffer.readstring(_buffer, Pointer + 4, Size)

		return buffer.fromstring(String)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: buffer)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Size: number = buffer.len(Value)

		Buffer.Pointer += 4 + Size

		buffer.writeu32(_buffer, Pointer, Size)
		
		if Size > 0 then
			buffer.writestring(_buffer, Pointer + 4, buffer.tostring(Value))
		end
	end,
}