--[==[
	Author: 8ch99
	File: buffer.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local WriteString = ByteBuffer.WriteString

local ReadString = ByteBuffer.ReadString

return {
	GetSize = function(Value: buffer): number
		return 2 + buffer.len(Value)
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): buffer
		return buffer.fromstring(ReadString(Buffer))
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: buffer)
		WriteString(Buffer, buffer.tostring(Value))
	end,
}