--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

return {
	Size = 8,

	Reader = function(Buffer: buffer, References: { any }, Pointer: number): (DateTime, number)
		return DateTime.fromUnixTimestampMillis(buffer.readf64(Buffer, Pointer)), 8
	end,

	Writer = function(Buffer: buffer, References: { any }, Pointer: number, Value: DateTime): number
		buffer.writef64(Buffer, Pointer, Value.UnixTimestampMillis)
		return 8
	end,
}