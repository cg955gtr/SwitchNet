--[==[
	Author: 8ch99
	File: Bitstream.luau
	Date written: 15th November 2025
	Last edited: 23rd November 2025
]==]

--!strict
--!native
--!optimize 2

--// Dependencies

--local EncodingService = game:GetService("EncodingService")

local HEADER: string = "\16\26"
local BUFFER_SIZE_LIMIT: number = 1048575 --// 2 ^ 20 - 1

local ByteBuffer = require("@self/ByteBuffer")

local fromBuffer = ByteBuffer.fromBuffer

local ReadUInt8 = ByteBuffer.ReadUInt8
local ReadUInt16 = ByteBuffer.ReadUInt16
local ReadString = ByteBuffer.ReadString

local WriteUInt8 = ByteBuffer.WriteUInt8
local WriteUInt16 = ByteBuffer.WriteUInt16
local WriteString = ByteBuffer.WriteString

export type StreamType = {
	Size: number?,
	GetSize: ((Value: any) -> (number, any?))?,
	
	Reader: (Buffer: ByteBuffer.ByteBuffer, References: References) -> any,
	Writer: (Buffer: ByteBuffer.ByteBuffer, References: References, Value: any, Types: { [any]: StreamTypeMap }?) -> (),
	Enum: StreamEnum,
}

export type StreamEnum = {
	Name: string,
	Value: number,
}

export type References = {
	Count: number,
	Data: { any },
}

export type StreamTypeMap = {
	Type: StreamType | string,
	ExtraTypes: { [any]: StreamTypeMap }?,
}

--// @module Bitstream

local Bitstream = {}

local Types = {} :: { [string]: StreamType }
local TypesFromValue = {} :: { StreamType }

Bitstream.Types = Types
Bitstream.TypesFromValue = TypesFromValue

Bitstream.Enums = {} :: { [string]: StreamEnum }

local function GetAndCheckRemoteData(Data: buffer, References: References): (ByteBuffer.ByteBuffer, number)
	debug.profilebegin("Bitstream._getAndCheckRemoteData")

	--// Check remote arg types
	assert(type(Data) == "buffer" and type(References) == "table", "invalid remote args!")

	local Count: number = References.Count
	assert(type(Count) == "number" and tostring(Count) == tostring(math.floor(Count)), "invalid remote args!")
	assert(type(References.Data) == "table", "invalid remote args!")

	--// Check buffer size
	local Size: number = buffer.len(Data)
	assert(Size <= BUFFER_SIZE_LIMIT, "buffer too large!")

	local Buffer: ByteBuffer.ByteBuffer = fromBuffer(Data)

	--// Read header
	assert(ReadString(Buffer, #HEADER) == HEADER, "invalid data sequence provided (unknown header)")

	--// Read element count, and check
	local ElementCount: number = ReadUInt16(Buffer)

	assert(ElementCount <= (Size // 2), "invalid data sequence provided (element size is too high relative to buffer size)")

	debug.profileend()

	--// Return bit buffer + element count
	return Buffer, ElementCount
end

local function AddToReferences(Buffer: ByteBuffer.ByteBuffer, References: References, Value: any)
	local NewCount: number = References.Count + 1
	References.Count = NewCount

	WriteUInt8(Buffer, 255)
	WriteUInt16(Buffer, NewCount)
	
	References.Data[NewCount] = Value
end

local function GetValueSizeAndType(Value: any, NoHeader: boolean?): (number, StreamTypeMap)
	debug.profilebegin("Bitstream._getValueSizeAndType")

	local Size: number = if NoHeader then 0 else 1
	local Type: StreamType?
	local ExtraTypes: { [any]: StreamTypeMap }?

	if Value ~= nil then
		Type = Types[typeof(Value)] or Types[type(Value)]

		if Type then
			--// OTHER
			local _size: number? = Type.Size

			if _size then
				Size += _size
			else
				local GetSize = Type.GetSize
				if GetSize then
					local __size: number, _extraTypes: { [any]: StreamTypeMap }? = GetSize(Value)
					
					Size += __size

					if _extraTypes ~= nil then
						ExtraTypes = _extraTypes
					end
				end
			end
		else
			--// REFERENCE
			Size += 2
		end
	end

	debug.profileend()

	local StreamTypeMap: StreamTypeMap = {
		Type = if Type then Type else "REFERENCE",
		ExtraTypes = ExtraTypes,
	}

	return Size, StreamTypeMap
end

Bitstream.AddToReferences = AddToReferences
Bitstream._getValueSizeAndType = GetValueSizeAndType

function Bitstream.Read(Data: buffer, References: References): { n: number, [number]: any }
	debug.profilebegin("Bitstream.Read")

	local Buffer: ByteBuffer.ByteBuffer, ElementCount: number = GetAndCheckRemoteData(Data, References)
	local Streamed: { n: number, [number]: any } = { n = 0 }
	local Count: number = 0

	while Count < ElementCount do
		Count += 1

		local ValueType: number = ReadUInt8(Buffer)
	
		if ValueType == 0 then
			continue
		end

		local Value: any

		if ValueType == 255 then
			--// REFERENCE
			local Position: number = ReadUInt16(Buffer)
			Value = References.Data[Position]
		else
			--// OTHER
			local Type: StreamType = TypesFromValue[ValueType]
			Value = Type.Reader(Buffer, References)
		end

		Streamed[Count] = Value
	end

	ByteBuffer.Destroy(Buffer)
	
	Streamed.n = Count

	debug.profileend()
	
	return Streamed
end

function Bitstream.Create(...: any): (buffer, References)
	debug.profilebegin("Bitstream.Create")

	local Data: { n: number, [number]: any } = table.pack(...)
	local DataCount: number = Data.n

	local DataTypes: { StreamTypeMap } = {}
	local BufferSize: number = 2 + #HEADER + 2

	--// First step, calculate buffer size
	for i: number = 1, DataCount do
		local Size: number, Type: StreamTypeMap = GetValueSizeAndType(Data[i])

		BufferSize += Size

		DataTypes[i] = Type
	end
	
	--// Now create the buffer
	local Buffer: ByteBuffer.ByteBuffer = ByteBuffer.new(BufferSize)
	local References: References = {
		Count = 0,
		Data = {},
	}

	--// Write header
	WriteString(Buffer, HEADER)
	WriteUInt16(Buffer, DataCount)
	
	for i: number = 1, DataCount do
		local Value: any = Data[i]

		if Value == nil then
			WriteUInt8(Buffer, 0)
			continue
		end

		local TypeInfo: StreamTypeMap = DataTypes[i]
		local Type: StreamType | string = TypeInfo.Type
		
		if Type == "REFERENCE" then
			local NewCount: number = References.Count + 1
			References.Count = NewCount

			WriteUInt8(Buffer, 255)
			WriteUInt16(Buffer, NewCount)
				
			References.Data[NewCount] = Value
		else
			--// OTHER
			local RealType: StreamType = Type :: StreamType
			local ExtraTypes: { [any]: StreamTypeMap }? = TypeInfo.ExtraTypes

			WriteUInt8(Buffer, RealType.Enum.Value)
			RealType.Writer(Buffer, References, Value, ExtraTypes)
		end
	end

	local Payload: buffer = Buffer._buffer

	ByteBuffer.Destroy(Buffer)

	debug.profileend()

	return Payload, References
end

--// Init types
local TypeModules = {}

for _, Module in script:WaitForChild("Types"):GetChildren() do
	if not Module:IsA("ModuleScript") then
		continue
	end

	local Success: boolean, Result: any = pcall(require, Module :: ModuleScript)

	if Success then
		table.insert(TypeModules, { Name = Module.Name, Module = Result })

		if Result.Init then
			task.spawn(Result.Init, Bitstream)
		end
	else
		warn(`Failed to load compression type {Module.Name}, Error: {Result}`)
	end
end

--// Sort by name, so we can mandate a fixed order
table.sort(TypeModules, function(A: { Name: string, Module: any }, B: { Name: string, Module: any }): boolean
	return A.Name < B.Name
end)

--// Create type objects and enums
for Index: number, Module: { Name: string, Module: any } in TypeModules do
	local RealModule: any = Module.Module
	local Enum: StreamEnum = { Name = Module.Name, Value = Index }
	local Type: StreamType = {
		Enum = Enum,
		Reader = RealModule.Reader,
		Writer = RealModule.Writer,
		Size = RealModule.Size,
		GetSize = RealModule.GetSize,
	}

	Bitstream.Enums[Module.Name] = Enum
	Types[Module.Name] = Type
	TypesFromValue[Index] = Type
end

return Bitstream