--[==[
	Author: 8ch99
	File: ByteBuffer.luau
	Date written: 22nd November 2025
	Last edited: 23rd November 2025
]==]

--!strict
--!native
--!optimize 2

--// Typedefs

export type ByteBuffer = {
	Pointer: number,
	_buffer: buffer,
}

--// Dependencies

local EncodingService = game:GetService("EncodingService")

local EnumTypeNameReferences: { [Enum]: string } = {}

for _, List: Enum in Enum:GetEnums() do
	EnumTypeNameReferences[List] = tostring(List)
end

--// @module ByteBuffer

local ByteBuffer = {}

--// Constructors

function ByteBuffer.new(Size: number?): ByteBuffer
	return {
		_buffer = buffer.create(Size or 0),
		Pointer = 0,
	}
end

function ByteBuffer.fromBuffer(Buffer: buffer): ByteBuffer
	return {
		_buffer = Buffer,
		Pointer = 0,
	}
end

function ByteBuffer.fromString(String: string): ByteBuffer
	return {
		_buffer = buffer.fromstring(String),
		Pointer = 0,
	}
end

function ByteBuffer.fromBase64(Base64: buffer): ByteBuffer
	return {
		_buffer = EncodingService:Base64Decode(Base64),
		Pointer = 0,
	}
end



function ByteBuffer.Destroy(self: ByteBuffer)
	table.clear(self)
end

--// Private methods

function ByteBuffer._getEnumTypeNameReferences()
	return EnumTypeNameReferences
end

--[[
function ByteBuffer._expand(self: ByteBuffer, Bytes: number): buffer
	local Buffer: buffer = buffer.create(self._size + Bytes)

	buffer.copy(Buffer, 0, self._buffer)

	self._buffer = Buffer
	self._size += Bytes

	return Buffer
end

function ByteBuffer._incrementPointerAndAllocateIfTooSmall(self: ByteBuffer, Bytes: number): number
	local OldPointer: number = self.Pointer
	local NewPointer: number = OldPointer + Bytes
	local CurrentSize: number = self.Size

	if NewPointer > CurrentSize then
		--// Increment size if too short
		CurrentSize += (NewPointer - CurrentSize)
		self.Size = CurrentSize

		local CurrentBufferSize: number = self._size

		if CurrentSize > CurrentBufferSize then
			ByteBuffer._expand(self, CurrentSize - CurrentBufferSize)
		end
	end

	self.Pointer = NewPointer

	return OldPointer
end
]]

--// Main methods

function ByteBuffer.GetBuffer(self: ByteBuffer): buffer
	return self._buffer
end

function ByteBuffer.ResetPointer(self: ByteBuffer)
	self.Pointer = 0
end

function ByteBuffer.ToString(self: ByteBuffer): string
	return buffer.tostring(self._buffer)
end

function ByteBuffer.ToBase64(self: ByteBuffer): buffer
	return EncodingService:Base64Encode(self._buffer)
end

--// Readers

function ByteBuffer.ReadUInt8(self: ByteBuffer): number
	local Value: number = buffer.readu8(self._buffer, self.Pointer)

	self.Pointer += 1

	return Value
end

function ByteBuffer.ReadUInt16(self: ByteBuffer): number
	local Value: number = buffer.readu16(self._buffer, self.Pointer)

	self.Pointer += 2

	return Value
end

function ByteBuffer.ReadUInt32(self: ByteBuffer): number
	local Value: number = buffer.readu32(self._buffer, self.Pointer)

	self.Pointer += 4

	return Value
end

function ByteBuffer.ReadInt8(self: ByteBuffer): number
	local Value: number = buffer.readi8(self._buffer, self.Pointer)

	self.Pointer += 1

	return Value
end

function ByteBuffer.ReadInt16(self: ByteBuffer): number
	local Value: number = buffer.readi16(self._buffer, self.Pointer)

	self.Pointer += 2

	return Value
end

function ByteBuffer.ReadInt32(self: ByteBuffer): number
	local Value: number = buffer.readi32(self._buffer, self.Pointer)

	self.Pointer += 4

	return Value
end

function ByteBuffer.ReadFloat32(self: ByteBuffer): number
	local Value: number = buffer.readf32(self._buffer, self.Pointer)

	self.Pointer += 4

	return Value
end

function ByteBuffer.ReadFloat64(self: ByteBuffer): number
	local Value: number = buffer.readf64(self._buffer, self.Pointer)

	self.Pointer += 8

	return Value
end



function ByteBuffer.ReadBoolean(self: ByteBuffer): boolean
	local Value: number = buffer.readu8(self._buffer, self.Pointer)

	self.Pointer += 1

	return Value ~= 0
end

function ByteBuffer.ReadString(self: ByteBuffer, Limit: number?): string
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	local Size: number = Limit or buffer.readu16(Buffer, Pointer)

	if Size == 0 then
		return ""
	end

	Pointer += 2

	local String: string = buffer.readstring(Buffer, Pointer, Size)

	self.Pointer += 2 + Size

	return String
end

function ByteBuffer.ReadVector(self: ByteBuffer): vector
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 12

	return vector.create(
		buffer.readf32(Buffer, Pointer),
		buffer.readf32(Buffer, Pointer + 4),
		buffer.readf32(Buffer, Pointer + 8)
	)
end

function ByteBuffer.ReadVector2(self: ByteBuffer): Vector2
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 8

	return Vector2.new(
		buffer.readf32(Buffer, Pointer),
		buffer.readf32(Buffer, Pointer + 4)
	)
end

function ByteBuffer.ReadVector3(self: ByteBuffer): Vector3
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 12

	return Vector3.new(
		buffer.readf32(Buffer, Pointer),
		buffer.readf32(Buffer, Pointer + 4),
		buffer.readf32(Buffer, Pointer + 8)
	)
end

function ByteBuffer.ReadVector2int16(self: ByteBuffer): Vector2int16
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 4

	return Vector2int16.new(
		buffer.readi16(Buffer, Pointer),
		buffer.readi16(Buffer, Pointer + 2)
	)
end

function ByteBuffer.ReadVector3int16(self: ByteBuffer): Vector3int16
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 6

	return Vector3int16.new(
		buffer.readi16(Buffer, Pointer),
		buffer.readi16(Buffer, Pointer + 2),
		buffer.readi16(Buffer, Pointer + 4)
	)
end

function ByteBuffer.ReadCFrame(self: ByteBuffer): CFrame
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 24

	local BaseCFrame: CFrame = CFrame.new(
		buffer.readf32(Buffer, Pointer),
		buffer.readf32(Buffer, Pointer + 4),
		buffer.readf32(Buffer, Pointer + 8)
	)

	--// Rotate the base CFrame
	BaseCFrame *= CFrame.fromEulerAnglesXYZ(
		buffer.readf32(Buffer, Pointer + 12),
		buffer.readf32(Buffer, Pointer + 16),
		buffer.readf32(Buffer, Pointer + 20)
	)

	return BaseCFrame
end

function ByteBuffer.ReadUDim(self: ByteBuffer): UDim
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 8

	return UDim.new(
		buffer.readf32(Buffer, Pointer),
		buffer.readi32(Buffer, Pointer + 4)
	)
end

function ByteBuffer.ReadUDim2(self: ByteBuffer): UDim2
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 8

	return UDim2.new(
		buffer.readf32(Buffer, Pointer),
		buffer.readi32(Buffer, Pointer + 4),
		buffer.readf32(Buffer, Pointer + 8),
		buffer.readi32(Buffer, Pointer + 12)
	)
end

function ByteBuffer.ReadColor3(self: ByteBuffer): Color3
	local Pointer: number = self.Pointer
	local Buffer: buffer = self._buffer

	self.Pointer += 3

	return Color3.fromRGB(
		buffer.readu8(Buffer, Pointer),
		buffer.readu8(Buffer, Pointer + 1),
		buffer.readu8(Buffer, Pointer + 2)
	)
end

function ByteBuffer.ReadBrickColor(self: ByteBuffer): BrickColor
	local Value: number = buffer.readu16(self._buffer, self.Pointer)

	self.Pointer += 2

	return BrickColor.new(Value)
end

function ByteBuffer.ReadTweenInfo(self: ByteBuffer): TweenInfo
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 15

	local Time: number = buffer.readf32(Buffer, Pointer)

	local EasingStyleValue: number = buffer.readu8(Buffer, Pointer + 4)
	local EasingDirectionValue: number = buffer.readu8(Buffer, Pointer + 5)

	local RepeatCount: number = buffer.readi32(Buffer, Pointer + 6)
	local Reverses: boolean = buffer.readu8(Buffer, Pointer + 10) ~= 0

	local DelayTime: number = buffer.readf32(Buffer, Pointer + 11)

	--// Get enums
	local EasingStyle = Enum.EasingStyle:FromValue(EasingStyleValue) :: Enum.EasingStyle
	local EasingDirection = Enum.EasingDirection:FromValue(EasingDirectionValue) :: Enum.EasingDirection

	return TweenInfo.new(Time, EasingStyle, EasingDirection, RepeatCount, Reverses, DelayTime)
end

function ByteBuffer.ReadEnumItem(self: ByteBuffer): EnumItem
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	self.Pointer += 15

	local Value: number = buffer.readu32(Buffer, Pointer)
	local ListNameSize: number = buffer.readu8(Buffer, Pointer + 4)
	local ListName: string = buffer.readstring(Buffer, Pointer + 5, ListNameSize)

	return (Enum[ListName] :: any):FromValue(Value), 5 + ListNameSize
end

--// Writers

function ByteBuffer.WriteUInt8(self: ByteBuffer, Value: number)
	buffer.writeu8(self._buffer, self.Pointer, Value)
	self.Pointer += 1
end

function ByteBuffer.WriteUInt16(self: ByteBuffer, Value: number)
	buffer.writeu16(self._buffer, self.Pointer, Value)
	self.Pointer += 2
end

function ByteBuffer.WriteUInt32(self: ByteBuffer, Value: number)
	buffer.writeu32(self._buffer, self.Pointer, Value)
	self.Pointer += 4
end

function ByteBuffer.WriteInt8(self: ByteBuffer, Value: number)
	buffer.writei8(self._buffer, self.Pointer, Value)
	self.Pointer += 1
end

function ByteBuffer.WriteInt16(self: ByteBuffer, Value: number)
	buffer.writei16(self._buffer, self.Pointer, Value)
	self.Pointer += 2
end

function ByteBuffer.WriteInt32(self: ByteBuffer, Value: number)
	buffer.writei32(self._buffer, self.Pointer, Value)
	self.Pointer += 4
end

function ByteBuffer.WriteFloat32(self: ByteBuffer, Value: number)
	buffer.writef32(self._buffer, self.Pointer, Value)
	self.Pointer += 4
end

function ByteBuffer.WriteFloat64(self: ByteBuffer, Value: number)
	buffer.writef64(self._buffer, self.Pointer, Value)
	self.Pointer += 8
end

function ByteBuffer.WriteBoolean(self: ByteBuffer, Value: boolean)
	buffer.writeu8(self._buffer, self.Pointer, if Value then 1 else 0)
	self.Pointer += 1
end

function ByteBuffer.WriteString(self: ByteBuffer, Value: string)
	local Size: number = #Value
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writeu16(Buffer, Pointer, Size)

	if Size > 0 then
		buffer.writestring(Buffer, Pointer + 2, Value)
		self.Pointer += 2 + Size
	else
		self.Pointer += 2
	end
end

function ByteBuffer.WriteVector(self: ByteBuffer, Value: vector)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writef32(Buffer, Pointer, Value.x)
	buffer.writef32(Buffer, Pointer + 4, Value.y)
	buffer.writef32(Buffer, Pointer + 8, Value.z)

	self.Pointer += 12
end

function ByteBuffer.WriteVector2(self: ByteBuffer, Value: Vector2)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writef32(Buffer, Pointer, Value.X)
	buffer.writef32(Buffer, Pointer + 4, Value.Y)

	self.Pointer += 8
end

function ByteBuffer.WriteVector3(self: ByteBuffer, Value: Vector3)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writef32(Buffer, Pointer, Value.X)
	buffer.writef32(Buffer, Pointer + 4, Value.Y)
	buffer.writef32(Buffer, Pointer + 8, Value.Z)

	self.Pointer += 12
end

function ByteBuffer.WriteVector2int16(self: ByteBuffer, Value: Vector2int16)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writei16(Buffer, Pointer, Value.X)
	buffer.writei16(Buffer, Pointer + 2, Value.Y)

	self.Pointer += 4
end

function ByteBuffer.WriteVector3int16(self: ByteBuffer, Value: Vector3int16)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writei16(Buffer, Pointer, Value.X)
	buffer.writei16(Buffer, Pointer + 2, Value.Y)
	buffer.writei16(Buffer, Pointer + 4, Value.Z)

	self.Pointer += 6
end

function ByteBuffer.WriteCFrame(self: ByteBuffer, Value: CFrame)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	local rX: number, rY: number, rZ: number = Value:ToEulerAnglesXYZ()

	buffer.writef32(Buffer, Pointer, Value.X)
	buffer.writef32(Buffer, Pointer + 4, Value.Y)
	buffer.writef32(Buffer, Pointer + 8, Value.Z)

	buffer.writef32(Buffer, Pointer + 12, rX)
	buffer.writef32(Buffer, Pointer + 16, rY)
	buffer.writef32(Buffer, Pointer + 20, rZ)

	self.Pointer += 24
end

function ByteBuffer.WriteUDim(self: ByteBuffer, Value: UDim)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writef32(Buffer, Pointer, Value.Scale)
	buffer.writei32(Buffer, Pointer + 4, Value.Offset)

	self.Pointer += 8
end

function ByteBuffer.WriteUDim2(self: ByteBuffer, Value: UDim2)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	local X: UDim, Y: UDim = Value.X, Value.Y

	buffer.writef32(Buffer, Pointer, X.Scale)
	buffer.writei32(Buffer, Pointer + 4, X.Offset)
	buffer.writef32(Buffer, Pointer + 8, Y.Scale)
	buffer.writei32(Buffer, Pointer + 12, Y.Offset)

	self.Pointer += 16
end

function ByteBuffer.WriteColor3(self: ByteBuffer, Value: Color3)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writeu8(Buffer, Pointer, math.round(Value.R * 255))
	buffer.writeu8(Buffer, Pointer + 1, math.round(Value.G * 255))
	buffer.writeu8(Buffer, Pointer + 2, math.round(Value.B * 255))

	self.Pointer += 3
end

function ByteBuffer.WriteBrickColor(self: ByteBuffer, Value: BrickColor)
	buffer.writeu16(self._buffer, self.Pointer, Value.Number)
	self.Pointer += 2
end

function ByteBuffer.WriteTweenInfo(self: ByteBuffer, Value: TweenInfo)
	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writef32(Buffer, Pointer, Value.Time)

	buffer.writeu8(Buffer, Pointer + 4, Value.EasingStyle.Value)
	buffer.writeu8(Buffer, Pointer + 5, Value.EasingDirection.Value)

	buffer.writei32(Buffer, Pointer + 6, Value.RepeatCount)
	buffer.writeu8(Buffer, Pointer + 10, if Value.Reverses then 1 else 0)
	buffer.writef32(Buffer, Pointer + 11, Value.DelayTime)

	self.Pointer += 15
end

function ByteBuffer.WriteEnumItem(self: ByteBuffer, Value: EnumItem)
	local ListName: string = EnumTypeNameReferences[Value.EnumType]
	local ListNameSize: number = #ListName

	local Buffer: buffer = self._buffer
	local Pointer: number = self.Pointer

	buffer.writeu32(Buffer, Pointer, Value.Value)
	buffer.writeu8(Buffer, Pointer + 4, ListNameSize)
	buffer.writestring(Buffer, Pointer + 5, ListName, ListNameSize)

	self.Pointer += 5 + ListNameSize
end

return ByteBuffer