--[==[
	Author: 8ch99
	File: table.luau
	Date written: 15th November 2025
	Last edited: 15th December 2025
]==]

--!strict
--!native
--!optimize 2

--// ^ not proper, but it works

local Bitstream

local GetSizeOfValues
local Types
local TypesFromValue

return {
	Init = function(...)
		Bitstream = ...
		
		GetSizeOfValues = Bitstream._getSizeOfValues
		Types = Bitstream.Types
		TypesFromValue = Bitstream.TypesFromValue
	end,

	GetSize = function(Value: { [any]: any }): number
		local Size: number = 3
		local Type: number = 0

		if Value[1] then
			Type = 1
		end

		--// Get table size
		if Type == 0 then
			local Array: { any } = {}

			for i: any, v: any in Value do
				table.insert(Array, i)
				table.insert(Array, v)
			end
			
			local TableSize: number = #Array
			Size += GetSizeOfValues(Array, TableSize)

			--table.clear(Array)
			Array = nil :: never
		else
			local TableSize: number = Value.n or #Value
			
			if TableSize == 0 then
				return Size
			end

			Size += GetSizeOfValues(Value, TableSize)
		end

		return Size
	end,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): ({ [any]: any }, number)
		local OriginPointer: number = Pointer

		local Table: { [any]: any }

		local TableType: number = buffer.readu8(Buffer, Pointer)
		local TableSize: number = buffer.readu16(Buffer, Pointer + 1)

		Pointer += 3

		if TableType == 0 then
			Table = {}
			
			for _ = 1, TableSize do
				--// Index
				local IndexType: number = buffer.readu8(Buffer, Pointer)
				Pointer += 1
	
				if IndexType == 0 then
					continue
				end

				local Index: any

				if IndexType == 255 then
					--// REFERENCE
					local Position: number = buffer.readu16(Buffer, Pointer)
					Index = References[Position]
					Pointer += 2
				else
					--// OTHER
					local Type = TypesFromValue[IndexType]
					local IndexResult: any, PtrOffset: number = Type.Reader(Buffer, References, Pointer)
					Index = IndexResult
					Pointer += PtrOffset
				end

				--// Value
				local ValueType: number = buffer.readu8(Buffer, Pointer)
				Pointer += 1
	
				if ValueType == 0 then
					continue
				end

				local Value: any

				if ValueType == 255 then
					--// REFERENCE
					local Position: number = buffer.readu16(Buffer, Pointer)
					Value = References[Position]
					Pointer += 2
				else
					--// OTHER
					local Type = TypesFromValue[ValueType]
					local ValueResult: any, PtrOffset: number = Type.Reader(Buffer, References, Pointer)
					Value = ValueResult
					Pointer += PtrOffset
				end

				Table[Index] = Value
			end
		else
			Table = table.create(TableSize)
			
			for i: number = 1, TableSize do
				local ValueType: number = buffer.readu8(Buffer, Pointer)
				Pointer += 1
	
				if ValueType == 0 then
					continue
				end

				local Value: any

				if ValueType == 255 then
					--// REFERENCE
					local Position: number = buffer.readu16(Buffer, Pointer)
					Value = References[Position]
					Pointer += 2
				else
					--// OTHER
					local Type = TypesFromValue[ValueType]
					local ValueResult: any, PtrOffset: number = Type.Reader(Buffer, References, Pointer)
					Value = ValueResult
					Pointer += PtrOffset
				end

				Table[i] = Value
			end
		end

		return Table, Pointer - OriginPointer
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: { [any]: any }): number
		local OriginPointer: number = Pointer

		local TableType: number = 0

		if Value[1] then
			--// Assume its an array
			--// HttpService:JSONEncode() behaves the same way for array checks, so this should be fine
			TableType = 1
		end

		--// Get table size
		local TableSize: number = 0

		if TableType == 0 then
			for _ in Value do TableSize += 1 end
		else
			TableSize = Value.n or #Value
		end
		
		--// Write type flag + size
		buffer.writeu8(Buffer, Pointer, TableType)
		buffer.writeu16(Buffer, Pointer + 1, TableSize)
		
		if TableSize == 0 then
			return 3
		end

		Pointer += 3

		if TableType == 0 then
			for i: any, v: any in Value do
				--// Index
				local IndexType: any = Types[type(i)] or Types[typeof(i)]

				if IndexType ~= nil then
					buffer.writeu8(Buffer, Pointer, IndexType.Value)
					Pointer += 1

					local PtrOffset: number = IndexType.Writer(Buffer, References, Pointer, i)
					Pointer += PtrOffset
				else
					local NewCount: number = References.n + 1
					References.n = NewCount

					buffer.writeu8(Buffer, Pointer, 255)
					buffer.writeu16(Buffer, Pointer + 1, NewCount)

					Pointer += 3

					References[NewCount] = i
				end

				--// Value
				local ValueType: any = Types[type(v)] or Types[typeof(v)]

				if ValueType ~= nil then
					buffer.writeu8(Buffer, Pointer, ValueType.Value)
					Pointer += 1

					local PtrOffset: number = ValueType.Writer(Buffer, References, Pointer, v)
					Pointer += PtrOffset
				else
					local NewCount: number = References.n + 1
					References.n = NewCount

					buffer.writeu8(Buffer, Pointer, 255)
					buffer.writeu16(Buffer, Pointer + 1, NewCount)

					Pointer += 3

					References[NewCount] = v
				end
			end
		else
			for i: number = 1, TableSize do
				local v: any = Value[i]

				if v == nil then
					buffer.writeu8(Buffer, Pointer, 0)
					Pointer += 1
					continue
				end

				local Type: any = Types[type(v)] or Types[typeof(v)]

				if Type ~= nil then
					buffer.writeu8(Buffer, Pointer, Type.Value)
					Pointer += 1

					local PtrOffset: number = Type.Writer(Buffer, References, Pointer, v)
					Pointer += PtrOffset
				else
					local NewCount: number = References.n + 1
					References.n = NewCount

					buffer.writeu8(Buffer, Pointer, 255)
					buffer.writeu16(Buffer, Pointer + 1, NewCount)

					Pointer += 3

					References[NewCount] = v
				end
			end
		end

		return Pointer - OriginPointer
	end,
}