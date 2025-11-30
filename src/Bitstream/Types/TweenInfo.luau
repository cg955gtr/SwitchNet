--[==[
	Author: 8ch99
	File: TweenInfo.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

return {
	Size = 15,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): TweenInfo
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 15

		local Time: number = buffer.readf32(_buffer, Pointer)

		local EasingStyleValue: number = buffer.readu8(_buffer, Pointer + 4)
		local EasingDirectionValue: number = buffer.readu8(_buffer, Pointer + 5)

		local RepeatCount: number = buffer.readi32(_buffer, Pointer + 6)
		local Reverses: boolean = buffer.readu8(_buffer, Pointer + 10) ~= 0

		local DelayTime: number = buffer.readf32(_buffer, Pointer + 11)

		--// Get enums
		local EasingStyle = Enum.EasingStyle:FromValue(EasingStyleValue) :: Enum.EasingStyle
		local EasingDirection = Enum.EasingDirection:FromValue(EasingDirectionValue) :: Enum.EasingDirection

		return TweenInfo.new(Time, EasingStyle, EasingDirection, RepeatCount, Reverses, DelayTime)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: TweenInfo)
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		Buffer.Pointer += 15

		buffer.writef32(_buffer, Pointer, Value.Time)

		buffer.writeu8(_buffer, Pointer + 4, Value.EasingStyle.Value)
		buffer.writeu8(_buffer, Pointer + 5, Value.EasingDirection.Value)

		buffer.writei32(_buffer, Pointer + 6, Value.RepeatCount)
		buffer.writeu8(_buffer, Pointer + 10, if Value.Reverses then 1 else 0)
		buffer.writef32(_buffer, Pointer + 11, Value.DelayTime)
	end,
}