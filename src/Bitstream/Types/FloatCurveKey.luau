--[==[
	Author: 8ch99
	File: FloatCurveKey.luau
	Date written: 15th November 2025
	Last edited: 15th December 2025
]==]

--!strict
--!native
--!optimize 2

return {
	GetSize = function(Value: FloatCurveKey): number
		return if Value.Interpolation.Value == 2 then 17 else 9
	end,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (FloatCurveKey, number)
		local Time: number = buffer.readf32(Buffer, Pointer)
		local Value: number = buffer.readf32(Buffer, Pointer + 4)
		local Mode: number = buffer.readu8(Buffer, Pointer + 8)

		local Key: FloatCurveKey =  FloatCurveKey.new(Time, Value, Enum.KeyInterpolationMode:FromValue(Mode) :: Enum.KeyInterpolationMode)

		if Mode == 2 then
			--// Cubic, fetch tangents
			Key.LeftTangent = buffer.readf32(Buffer, Pointer + 9)
			Key.RightTangent = buffer.readf32(Buffer, Pointer + 13)
			
			return Key, 17
		end

		return Key, 9
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: FloatCurveKey): number
		local Mode: number = Value.Interpolation.Value
		
		buffer.writef32(Buffer, Pointer, Value.Time)
		buffer.writef32(Buffer, Pointer + 4, Value.Value)
		buffer.writeu8(Buffer, Pointer + 8, Mode)
		
		if Mode == 2 then
			--// Cubic, write tangents
			buffer.writef32(Buffer, Pointer + 9, Value.LeftTangent or 0)
			buffer.writef32(Buffer, Pointer + 13, Value.RightTangent or 0)
			
			return 17
		end
		return 9
	end,
}