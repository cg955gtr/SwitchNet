--[==[
	Author: 8ch99
	File: Bitstream.luau
	Date written: 15th November 2025
	Last edited: 23rd March 2026
]==]

--!strict
--!native
--!optimize 2

--// Dependencies

local HEADER = "\16\26"
local HEADER_SIZE = #HEADER
local BUFFER_SIZE_LIMIT = 2 ^ 21

export type NBasedArray = { n: number, [number]: any }

export type StreamType = {
	Name: string,
	Value: number,
	Size: number?,
	GetSize: ((Value: any) -> number)?,

	Reader: (Buffer: buffer, References: { any }, Pointer: number) -> (any, number),
	Writer: (Buffer: buffer, References: { any }, Pointer: number, Value: any) -> number,
}

--// @module Bitstream

local Bitstream = {}


local types = {} :: { [string]: StreamType }
local typesFromValue = {} :: { StreamType }

Bitstream.Types = types
Bitstream.TypesFromValue = typesFromValue



function Bitstream._getSizeOfValues(data: NBasedArray | { any }, length: number?): number
	local size = 0

	for i = 1, length or (data :: NBasedArray).n or #data do
		size += 1
		local value = data[i]
		if value == nil then continue end

		local streamType = types[type(value)] or types[typeof(value)]
		if streamType then
			--// OTHER
			local _size = streamType.Size
			if _size then
				size += _size
			else
				local getSize = streamType.GetSize
				if getSize then
					size += getSize(value)
				end
			end
		else
			--// REFERENCE
			size += 2
		end
	end

	return size
end



function Bitstream.Read(buff: buffer, references: { any }): NBasedArray
	--// TODO: Add some extra checks probably? It might be good enough for now
	--// Remote typechecks are done seperately already
	
	--local Count: number = References.n
	--assert(type(Count) == "number" and tostring(Count) == tostring(math.floor(Count)), "invalid remote args!")

	--// Check buffer size
	local size = buffer.len(buff)
	assert(size <= BUFFER_SIZE_LIMIT, "buffer too large!")

	--// Verify header
	assert(buffer.readstring(buff, 0, HEADER_SIZE) == HEADER, "invalid data sequence provided (unknown header)")

	--// Read element count, and check
	local elementCount = buffer.readu16(buff, HEADER_SIZE)
	assert(elementCount <= (size // 2), "invalid data sequence provided (element size is too high relative to buffer size)")

	--// Now start reading!
	local pointer = HEADER_SIZE + 2
	local streamed = table.create(elementCount) :: NBasedArray
	streamed.n = elementCount

	for i = 1, elementCount do
		local valueType = buffer.readu8(buff, pointer)
		pointer += 1
		if valueType == 0 then continue end

		local Value: any
		if valueType == 255 then
			--// REFERENCE
			Value = references[buffer.readu16(buff, pointer)]
			pointer += 2
		else
			--// OTHER
			local streamType = typesFromValue[valueType]
			local result, pointerOffset = streamType.Reader(buff, references, pointer)
			Value = result
			pointer += pointerOffset
		end

		streamed[i] = Value
	end

	return streamed
end



function Bitstream.Create(data: NBasedArray, bufferSize: number): (buffer, { any })
	bufferSize += HEADER_SIZE + 2

	local dataCount = data.n

	--// Create the buffer!
	local buff = buffer.create(bufferSize)
	local references = {}
	local pointer = HEADER_SIZE + 2

	--// Write header
	buffer.writestring(buff, 0, HEADER)
	buffer.writeu16(buff, HEADER_SIZE, dataCount)

	for i = 1, dataCount do
		local value = data[i]
		if value == nil then
			buffer.writeu8(buff, pointer, 0)
			pointer += 1
			continue
		end

		local streamType = types[type(value)] or types[typeof(value)]
		if streamType ~= nil then
			--// OTHER
			buffer.writeu8(buff, pointer, streamType.Value)
			pointer += 1

			local pointerOffset = streamType.Writer(buff, references, pointer, value)
			pointer += pointerOffset
		else
			local newCount = #references + 1
			buffer.writeu8(buff, pointer, 255)
			buffer.writeu16(buff, pointer + 1, newCount)

			pointer += 3
			references[newCount] = value
		end
	end

	return buff, references
end


--// Init types
local typeModules = {}

for _, module in script:WaitForChild("Types"):GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	local success, result = pcall(require, module :: ModuleScript)

	if success then
		table.insert(typeModules, { Name = module.Name, Module = result })
		if result.Init then
			task.spawn(result.Init, Bitstream)
		end
	else
		warn(`Failed to load compression type {module.Name}, Error: {result}`)
	end
end

--// Sort by name, so we can mandate a fixed order between server and client
table.sort(typeModules, function(a: { Name: string, Module: any }, b: { Name: string, Module: any }): boolean
	return a.Name < b.Name
end)

--// Create type objects and enums
for index, module in typeModules do
	local name = module.Name
	local realModule = module.Module

	local streamType = {
		Name = name,
		Value = index,

		Reader = realModule.Reader,
		Writer = realModule.Writer,
		Size = realModule.Size,
		GetSize = realModule.GetSize,
	}

	types[name] = streamType
	typesFromValue[index] = streamType
end

return Bitstream