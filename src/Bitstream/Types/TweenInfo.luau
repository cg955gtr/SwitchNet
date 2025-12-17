--[==[
	Author: 8ch99
	File: TweenInfo.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	Size = 15,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (TweenInfo, number)
		local Time: number = buffer.readf32(Buffer, Pointer)

		local EasingStyleValue: number = buffer.readu8(Buffer, Pointer + 4)
		local EasingDirectionValue: number = buffer.readu8(Buffer, Pointer + 5)

		local RepeatCount: number = buffer.readi32(Buffer, Pointer + 6)
		local Reverses: boolean = buffer.readu8(Buffer, Pointer + 10) ~= 0

		local DelayTime: number = buffer.readf32(Buffer, Pointer + 11)

		--// Get enums
		local EasingStyle = Enum.EasingStyle:FromValue(EasingStyleValue) :: Enum.EasingStyle
		local EasingDirection = Enum.EasingDirection:FromValue(EasingDirectionValue) :: Enum.EasingDirection

		return TweenInfo.new(Time, EasingStyle, EasingDirection, RepeatCount, Reverses, DelayTime), 15
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: TweenInfo): number
		buffer.writef32(Buffer, Pointer, Value.Time)

		buffer.writeu8(Buffer, Pointer + 4, Value.EasingStyle.Value)
		buffer.writeu8(Buffer, Pointer + 5, Value.EasingDirection.Value)

		buffer.writei32(Buffer, Pointer + 6, Value.RepeatCount)
		buffer.writeu8(Buffer, Pointer + 10, if Value.Reverses then 1 else 0)
		buffer.writef32(Buffer, Pointer + 11, Value.DelayTime)

		return 15
	end,
}