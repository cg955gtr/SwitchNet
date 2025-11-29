--[==[
	Author: 8ch99
	File: DateTime.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 8,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): DateTime
		local Time: DateTime = DateTime.fromUnixTimestampMillis(buffer.readf64(Buffer._buffer, Buffer.Pointer))

		Buffer.Pointer += 8

		return Time
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: DateTime)
		buffer.writef64(Buffer._buffer, Buffer.Pointer, Value.UnixTimestampMillis)

		Buffer.Pointer += 8
	end,
}