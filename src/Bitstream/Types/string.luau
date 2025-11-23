--[==[
	Author: 8ch99
	File: string.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadString = ByteBuffer.ReadString

local WriteString = ByteBuffer.WriteString

return {
	GetSize = function(Value: string): number
		return 2 + #Value
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): string
		return ReadString(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: string)
		WriteString(Buffer, Value)
	end,
}