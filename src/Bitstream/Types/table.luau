--[==[
	Author: 8ch99
	File: table.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

export type StreamTypeMap = {
	Type: any | string,
	ExtraTypes: { [any]: any }?,
}

--// ^ not proper, but it works

local Bitstream

local ByteBuffer = require("../ByteBuffer")

local GetValueSizeAndType
local TypesFromValue

local ReadUInt8 = ByteBuffer.ReadUInt8
local ReadUInt16 = ByteBuffer.ReadUInt16

local WriteUInt8 = ByteBuffer.WriteUInt8
local WriteUInt16 = ByteBuffer.WriteUInt16

return {
	Init = function(...)
		Bitstream = ...
		
		GetValueSizeAndType = Bitstream._getValueSizeAndType
		TypesFromValue = Bitstream.TypesFromValue
	end,

	GetSize = function(Value: { [any]: any }): (number, { [any]: StreamTypeMap })
		local Size: number = 3
		local Type: number = 0

		local Types: { [any]: StreamTypeMap } = {}

		if Value[1] then
			Type = 1
		end

		--// Get table size
		local TableSize: number = 0

		if Type == 0 then
			for _ in Value do TableSize += 1 end
		else
			TableSize = Value.n or #Value
		end

		if TableSize == 0 then
			return Size, Types
		end

		local PreviousValue: any, PreviousValueSize: number, PreviousValueType: StreamTypeMap

		if Type == 1 then
			for i: number = 1, TableSize do
				local v: any = Value[i]

				if v ~= PreviousValue then
					PreviousValue = v
					PreviousValueSize, PreviousValueType = GetValueSizeAndType(v)
				end

				Size += PreviousValueSize

				Types[i] = PreviousValueType
			end
		else
			local PreviousIndex: any, PreviousIndexSize: number, PreviousIndexType: StreamTypeMap

			for i: any, v: any in Value do
				if i ~= PreviousIndex then
					PreviousIndex = i
					PreviousIndexSize, PreviousIndexType = GetValueSizeAndType(i)
				end

				if v ~= PreviousValue then
					PreviousValue = v
					PreviousValueSize, PreviousValueType = GetValueSizeAndType(v)
				end

				Size += PreviousIndexSize + PreviousValueSize

				if not Types[i] then
					Types[i] = PreviousIndexType
				end

				if not Types[v] then
					Types[v] = PreviousValueType
				end
			end
		end

		return Size, Types
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): { [any]: any }
		local Table: { [any]: any } = {}
		local ReferenceData: { any } = References.Data

		local TableType: number = ReadUInt8(Buffer)
		local TableSize: number = ReadUInt16(Buffer)

		if TableType == 0 then
			for _ = 1, TableSize do
				--// Index
				local IndexType: number = ReadUInt8(Buffer)
	
				if IndexType == 0 then
					continue
				end

				local Index: any

				if IndexType == 255 then
					--// REFERENCE
					local Position: number = ReadUInt16(Buffer)
					Index = ReferenceData[Position]
				else
					--// OTHER
					local Type = TypesFromValue[IndexType]
					Index = Type.Reader(Buffer, References)
				end

				--// Value
				local ValueType: number = ReadUInt8(Buffer)
	
				if ValueType == 0 then
					continue
				end

				local Value: any

				if ValueType == 255 then
					--// REFERENCE
					local Position: number = ReadUInt16(Buffer)
					Value = ReferenceData[Position]
				else
					--// OTHER
					local Type = TypesFromValue[ValueType]
					Value = Type.Reader(Buffer, References)
				end

				Table[Index] = Value
			end
		else
			for i: number = 1, TableSize do
				local ValueType: number = ReadUInt8(Buffer)
	
				if ValueType == 0 then
					continue
				end

				local Value: any

				if ValueType == 255 then
					--// REFERENCE
					local Position: number = ReadUInt16(Buffer)
					Value = ReferenceData[Position]
				else
					--// OTHER
					local Type = TypesFromValue[ValueType]
					Value = Type.Reader(Buffer, References)
				end

				Table[i] = Value
				--Table[i] = ReadValue(Buffer, References)
			end
		end

		return Table
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: { [any]: any }, Types: { StreamTypeMap })
		local TableType: number = 0

		if Value[1] then
			--// Assume its an array
			--// HttpService:JSONEncode() behaves the same way for array checks, so this should be fine
			TableType = 1
		end

		--// Write type flag
		WriteUInt8(Buffer, TableType)

		--// Get table size
		local TableSize: number = 0

		if TableType == 0 then
			for _ in Value do TableSize += 1 end
		else
			TableSize = Value.n or #Value
		end

		WriteUInt16(Buffer, TableSize)

		if TableSize == 0 then
			return
		end

		if TableType == 0 then
			for i: any, v: any in Value do
				--// Index
				local IndexTypeInfo: StreamTypeMap = Types[i]
				local IndexType: any = IndexTypeInfo.Type

				if IndexType == "REFERENCE" then
					local NewCount: number = References.Count + 1
					References.Count = NewCount

					WriteUInt8(Buffer, 255)
					WriteUInt16(Buffer, NewCount)
						
					References.Data[NewCount] = i
				else
					WriteUInt8(Buffer, IndexType.Enum.Value)
					IndexType.Writer(Buffer, References, i, IndexTypeInfo.ExtraTypes)
				end

				--// Value
				local ValueTypeInfo: StreamTypeMap = Types[v]
				local ValueType: any = ValueTypeInfo.Type

				if ValueType == "REFERENCE" then
					local NewCount: number = References.Count + 1
					References.Count = NewCount

					WriteUInt8(Buffer, 255)
					WriteUInt16(Buffer, NewCount)
						
					References.Data[NewCount] = v
				else
					WriteUInt8(Buffer, ValueType.Enum.Value)
					ValueType.Writer(Buffer, References, v, ValueTypeInfo.ExtraTypes)
				end
			end
		else
			for i: number = 1, TableSize do
				local v: any = Value[i]

				if v == nil then
					WriteUInt8(Buffer, 0)
					continue
				end

				local TypeInfo: StreamTypeMap = Types[i]
				local Type: any = TypeInfo.Type

				if Type == "REFERENCE" then
					--// REFERENCE
					local NewCount: number = References.Count + 1
					References.Count = NewCount

					WriteUInt8(Buffer, 255)
					WriteUInt16(Buffer, NewCount)
						
					References.Data[NewCount] = v
				else
					--// OTHER
					WriteUInt8(Buffer, Type.Enum.Value)
					Type.Writer(Buffer, References, v, TypeInfo.ExtraTypes)
				end
			end
		end
	end,
}