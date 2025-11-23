--[==[
	Author: 8ch99
	File: DateTime.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadFloat64 = ByteBuffer.ReadFloat64

local WriteFloat64 = ByteBuffer.WriteFloat64

return {
	Size = 8,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): DateTime
		return DateTime.fromUnixTimestampMillis(ReadFloat64(Buffer))
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: DateTime)
		WriteFloat64(Buffer, Value.UnixTimestampMillis)
	end,
}