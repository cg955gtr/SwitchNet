--[==[
	Author: 8ch99
	File: CFrame.luau
	Date written: 15th November 2025
	Last edited: 15th December 2025
]==]

--!strict
--!native
--!optimize 2

local WRITE_FULL_MATRIX: boolean = false
--// ^ If you ever run into issues with CFrame rotations, enable this
--// It will use more data but will promise no corruptions

local SIZE: number = if WRITE_FULL_MATRIX then 48 else 24

local function NormalReader(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (CFrame, number)
	local BaseCFrame: CFrame = CFrame.new(
		buffer.readf32(Buffer, Pointer),
		buffer.readf32(Buffer, Pointer + 4),
		buffer.readf32(Buffer, Pointer + 8)
	)

	BaseCFrame *= CFrame.fromEulerAnglesXYZ(
		buffer.readf32(Buffer, Pointer + 12),
		buffer.readf32(Buffer, Pointer + 16),
		buffer.readf32(Buffer, Pointer + 20)
	)

	return BaseCFrame, SIZE
end

local function FullReader(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (CFrame, number)
	local Position: Vector3 = Vector3.new(
		buffer.readf32(Buffer, Pointer),
		buffer.readf32(Buffer, Pointer + 4),
		buffer.readf32(Buffer, Pointer + 8)
	)

	local rX: Vector3 = Vector3.new(
		buffer.readf32(Buffer, Pointer + 12),
		buffer.readf32(Buffer, Pointer + 16),
		buffer.readf32(Buffer, Pointer + 20)
	)

	local rY: Vector3 = Vector3.new(
		buffer.readf32(Buffer, Pointer + 24),
		buffer.readf32(Buffer, Pointer + 28),
		buffer.readf32(Buffer, Pointer + 32)
	)

	local rZ: Vector3 = Vector3.new(
		buffer.readf32(Buffer, Pointer + 36),
		buffer.readf32(Buffer, Pointer + 40),
		buffer.readf32(Buffer, Pointer + 44)
	)

	return CFrame.fromMatrix(Position, rX, rY, rZ), SIZE
end


local function NormalWriter(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: CFrame): number
	buffer.writef32(Buffer, Pointer, Value.X)
	buffer.writef32(Buffer, Pointer + 4, Value.Y)
	buffer.writef32(Buffer, Pointer + 8, Value.Z)
	
	local rX: number, rY: number, rZ: number = Value:ToEulerAnglesXYZ()

	buffer.writef32(Buffer, Pointer + 12, rX)
	buffer.writef32(Buffer, Pointer + 16, rY)
	buffer.writef32(Buffer, Pointer + 20, rZ)

	return SIZE
end

local function FullWriter(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: CFrame): number
	buffer.writef32(Buffer, Pointer, Value.X)
	buffer.writef32(Buffer, Pointer + 4, Value.Y)
	buffer.writef32(Buffer, Pointer + 8, Value.Z)
	
	local rX: Vector3 = Value.XVector
	local rY: Vector3 = Value.YVector
	local rZ: Vector3 = Value.ZVector

	buffer.writef32(Buffer, Pointer + 12, rX.X)
	buffer.writef32(Buffer, Pointer + 16, rX.Y)
	buffer.writef32(Buffer, Pointer + 20, rX.Z)

	buffer.writef32(Buffer, Pointer + 24, rY.X)
	buffer.writef32(Buffer, Pointer + 28, rY.Y)
	buffer.writef32(Buffer, Pointer + 32, rY.Z)

	buffer.writef32(Buffer, Pointer + 36, rZ.X)
	buffer.writef32(Buffer, Pointer + 40, rZ.Y)
	buffer.writef32(Buffer, Pointer + 44, rZ.Z)

	return SIZE
end


return {
	Size = SIZE,

	Reader = if WRITE_FULL_MATRIX then FullReader else NormalReader,
	Writer = if WRITE_FULL_MATRIX then FullWriter else NormalWriter,
}