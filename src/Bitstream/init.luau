--[==[
	Author: 8ch99
	File: Bitstream.luau
	Date written: 15th November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

--// Dependencies

local HEADER: string = "\16\26"
local BUFFER_SIZE_LIMIT: number = 2 ^ 21

export type NBasedArray = { n: number, [number]: any }

export type StreamType = {
	Name: string,
	Value: number,
	Size: number?,
	GetSize: ((Value: any) -> number)?,

	Reader: (Buffer: buffer, References: NBasedArray, Pointer: number) -> (any, number),
	Writer: (Buffer: buffer, References: NBasedArray, Pointer: number, Value: any) -> number,
}

--// @module Bitstream

local Bitstream = {}

local Types = {} :: { [string]: StreamType }
local TypesFromValue = {} :: { StreamType }

Bitstream.Types = Types
Bitstream.TypesFromValue = TypesFromValue

local function GetAndCheckRemoteData(Data: buffer, References: NBasedArray): (buffer, number)
	--// TODO: Add some extra checks probably? It might be good enough for now

	--// Check remote arg types
	assert(type(Data) == "buffer" and type(References) == "table", "invalid remote args!")

	local Count: number = References.n
	assert(type(Count) == "number" and tostring(Count) == tostring(math.floor(Count)), "invalid remote args!")

	--// Check buffer size
	local Size: number = buffer.len(Data)
	assert(Size <= BUFFER_SIZE_LIMIT, "buffer too large!")

	--// Read header
	assert(buffer.readstring(Data, 0, #HEADER) == HEADER, "invalid data sequence provided (unknown header)")

	--// Read element count, and check
	local ElementCount: number = buffer.readu16(Data, #HEADER)
	assert(ElementCount <= (Size // 2), "invalid data sequence provided (element size is too high relative to buffer size)")

	--// Return bit buffer + element count
	return Data, ElementCount
end


local function GetValueSizeAndType(Value: any): (number, StreamType?)
	local Size: number = 1
	local Type: StreamType?

	if Value ~= nil then
		Type = Types[type(Value)] or Types[typeof(Value)]

		if Type then
			--// OTHER
			local _size: number? = Type.Size

			if _size then
				Size += _size
			else
				local GetSize = Type.GetSize

				if GetSize then
					Size += GetSize(Value)
				end
			end
		else
			--// REFERENCE
			Size += 2
		end
	end

	return Size, Type
end

local function GetValueSizeOnly(Value: any): number
	local Size: number = 1

	if Value ~= nil then
		local Type: StreamType? = Types[type(Value)] or Types[typeof(Value)]

		if Type then
			--// OTHER
			local _size: number? = Type.Size

			if _size then
				Size += _size
			else
				local GetSize = Type.GetSize

				if GetSize then
					Size += GetSize(Value)
				end
			end
		else
			--// REFERENCE
			Size += 2
		end
	end

	return Size
end

local function GetSizeOfValues(Data: NBasedArray, Length: number?): number
	local Size: number = 0

	for i: number = 1, Length or Data.n or #Data do
		Size += 1
		local Value: any? = Data[i]

		if Value ~= nil then
			local Type: StreamType? = Types[type(Value)] or Types[typeof(Value)]

			if Type then
				--// OTHER
				local _size: number? = Type.Size

				if _size then
					Size += _size
				else
					local GetSize = Type.GetSize

					if GetSize then
						Size += GetSize(Value)
					end
				end
			else
				--// REFERENCE
				Size += 2
			end
		end
	end

	return Size
end

Bitstream._getValueSizeAndType = GetValueSizeAndType
Bitstream._getValueSizeOnly = GetValueSizeOnly
Bitstream._getSizeOfValues = GetSizeOfValues

function Bitstream.Read(Data: buffer, References: NBasedArray): { n: number, [number]: any }
	local Buffer: buffer, ElementCount: number = GetAndCheckRemoteData(Data, References)
	local Pointer: number = #HEADER + 2

	local Streamed = table.create(ElementCount);
	(Streamed :: NBasedArray).n = ElementCount
	--local Streamed = { n = ElementCount }

	for i: number = 1, ElementCount do
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
			local Type: StreamType = TypesFromValue[ValueType]

			local Result: any, PtrOffset: number = Type.Reader(Buffer, References, Pointer)
			Value = Result
			Pointer += PtrOffset
		end

		Streamed[i] = Value
	end

	return Streamed :: NBasedArray
end

function Bitstream.Create(Data: NBasedArray, BufferSize: number): (buffer, NBasedArray)
	local DataCount: number = Data.n

	BufferSize += #HEADER + 2

	--// Create the buffer!
	local Buffer: buffer = buffer.create(BufferSize)
	local References: NBasedArray = { n = 0 }
	local Pointer: number = #HEADER + 2

	--// Write header
	buffer.writestring(Buffer, 0, HEADER)
	buffer.writeu16(Buffer, #HEADER, DataCount)

	for i: number = 1, DataCount do
		local Value: any = Data[i]

		if Value == nil then
			buffer.writeu8(Buffer, Pointer, 0)
			Pointer += 1
			continue
		end

		local Type: StreamType? = Types[type(Value)] or Types[typeof(Value)]

		if Type ~= nil then
			--// OTHER
			buffer.writeu8(Buffer, Pointer, Type.Value)
			Pointer += 1

			local PtrOffset: number = Type.Writer(Buffer, References, Pointer, Value)
			Pointer += PtrOffset
		else
			local NewCount: number = References.n + 1
			References.n = NewCount

			buffer.writeu8(Buffer, Pointer, 255)
			buffer.writeu16(Buffer, Pointer + 1, NewCount)

			Pointer += 3

			References[NewCount] = Value
		end
	end

	return Buffer, References
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
	local Name: string = Module.Name
	local RealModule: any = Module.Module

	local Type: StreamType = {
		Name = Name,
		Value = Index,

		Reader = RealModule.Reader,
		Writer = RealModule.Writer,
		Size = RealModule.Size,
		GetSize = RealModule.GetSize,
	}

	Types[Name] = Type
	TypesFromValue[Index] = Type
end

return Bitstream