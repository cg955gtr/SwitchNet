--[==[
	Author: 8ch99
	File: table.luau
	Date written: 15th November 2025
	Last edited: 29th November 2025
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
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Table: { [any]: any } = {}
		local ReferenceData: { any } = References.Data

		local TableType: number = buffer.readu8(_buffer, Pointer)
		local TableSize: number = buffer.readu16(_buffer, Pointer + 1)

		Pointer += 3

		if TableType == 0 then
			for _ = 1, TableSize do
				--// Index
				local IndexType: number = buffer.readu8(_buffer, Pointer)
				Pointer += 1
	
				if IndexType == 0 then
					continue
				end

				local Index: any

				if IndexType == 255 then
					--// REFERENCE
					local Position: number = buffer.readu16(_buffer, Pointer)
					Index = ReferenceData[Position]
					Pointer += 2
				else
					--// OTHER
					local Type = TypesFromValue[IndexType]
					Buffer.Pointer = Pointer --// Set buffer pointer, so the object can read
					Index = Type.Reader(Buffer, References)
					Pointer = Buffer.Pointer --// Update pointer after
				end

				--// Value
				local ValueType: number = buffer.readu8(_buffer, Pointer)
				Pointer += 1
	
				if ValueType == 0 then
					continue
				end

				local Value: any

				if ValueType == 255 then
					--// REFERENCE
					local Position: number = buffer.readu16(_buffer, Pointer)
					Value = ReferenceData[Position]
					Pointer += 2
				else
					--// OTHER
					local Type = TypesFromValue[ValueType]
					Buffer.Pointer = Pointer --// Set buffer pointer, so the object can read
					Value = Type.Reader(Buffer, References)
					Pointer = Buffer.Pointer --// Update pointer after
				end

				Table[Index] = Value
			end
		else
			for i: number = 1, TableSize do
				local ValueType: number = buffer.readu8(_buffer, Pointer)
				Pointer += 1
	
				if ValueType == 0 then
					continue
				end

				local Value: any

				if ValueType == 255 then
					--// REFERENCE
					local Position: number = buffer.readu16(_buffer, Pointer)
					Value = ReferenceData[Position]
					Pointer += 2
				else
					--// OTHER
					local Type = TypesFromValue[ValueType]
					Buffer.Pointer = Pointer --// Set buffer pointer, so the object can read
					Value = Type.Reader(Buffer, References)
					Pointer = Buffer.Pointer --// Update pointer after
				end

				Table[i] = Value
			end
		end

		Buffer.Pointer = Pointer

		return Table
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: { [any]: any }, Types: { StreamTypeMap })
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer
		
		local TableType: number = 0

		if Value[1] then
			--// Assume its an array
			--// HttpService:JSONEncode() behaves the same way for array checks, so this should be fine
			TableType = 1
		end

		--// Write type flag
		buffer.writeu8(_buffer, Pointer, TableType)

		--// Get table size
		local TableSize: number = 0

		if TableType == 0 then
			for _ in Value do TableSize += 1 end
		else
			TableSize = Value.n or #Value
		end

		buffer.writeu16(_buffer, Pointer + 1, TableSize)

		Pointer += 3
		Buffer.Pointer = Pointer

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

					buffer.writeu8(_buffer, Pointer, 255)
					buffer.writeu16(_buffer, Pointer + 1, NewCount)

					Pointer += 3
						
					References.Data[NewCount] = i
				else
					buffer.writeu8(_buffer, Pointer, IndexType.Enum.Value)
					Pointer += 1

					Buffer.Pointer = Pointer --// Set buffer pointer, so the object can read
					IndexType.Writer(Buffer, References, i, IndexTypeInfo.ExtraTypes)
					Pointer = Buffer.Pointer --// Update pointer after
				end

				--// Value
				local ValueTypeInfo: StreamTypeMap = Types[v]
				local ValueType: any = ValueTypeInfo.Type

				if ValueType == "REFERENCE" then
					local NewCount: number = References.Count + 1
					References.Count = NewCount

					buffer.writeu8(_buffer, Pointer, 255)
					buffer.writeu16(_buffer, Pointer + 1, NewCount)

					Pointer += 3
						
					References.Data[NewCount] = v
				else
					buffer.writeu8(_buffer, Pointer, ValueType.Enum.Value)
					Pointer += 1

					Buffer.Pointer = Pointer --// Set buffer pointer, so the object can read
					ValueType.Writer(Buffer, References, v, ValueTypeInfo.ExtraTypes)
					Pointer = Buffer.Pointer --// Update pointer after
				end
			end
		else
			for i: number = 1, TableSize do
				local v: any = Value[i]

				if v == nil then
					buffer.writeu8(_buffer, Pointer, 0)
					Pointer += 1
					continue
				end

				local TypeInfo: StreamTypeMap = Types[i]
				local Type: any = TypeInfo.Type

				if Type == "REFERENCE" then
					local NewCount: number = References.Count + 1
					References.Count = NewCount

					buffer.writeu8(_buffer, Pointer, 255)
					buffer.writeu16(_buffer, Pointer + 1, NewCount)

					Pointer += 3
						
					References.Data[NewCount] = v
				else
					buffer.writeu8(_buffer, Pointer, Type.Enum.Value)
					Pointer += 1

					Buffer.Pointer = Pointer --// Set buffer pointer, so the object can read
					Type.Writer(Buffer, References, v, TypeInfo.ExtraTypes)
					Pointer = Buffer.Pointer --// Update pointer after
				end
			end
		end
	end,
}