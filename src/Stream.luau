--// Author: 8ch99
--// Date written: 15th November 2025
--// SwitchNet Networking Library

--!strict
--!native
--!optimize 2

const HEADER: string = "\16\26"
const HEADER_SIZE: number = #HEADER
const BUFFER_SIZE_LIMIT: number = 2 ^ 21

--// Dependencies

const Typedefs = require("./Typedefs")

--// Typedefs

type NBasedArray = Typedefs.NBasedArray
type StreamType = Typedefs.StreamType
type NetworkPacket = Typedefs.NetworkPacket

--// @module Stream

const Stream = {}


const types: { [string]: StreamType } = {}
const typesFromValue: { StreamType } = {}

Stream.Types = types
Stream.TypesFromValue = typesFromValue



const function getStreamSizeOfValues(data: NBasedArray | { any }, length: number?): number

	local size: number = 0

	for i: number = 1, length or (data :: NBasedArray).n or #data do
		size += 1
		local value: any = data[i]
		if value == nil then continue end

		local streamType: StreamType = types[type(value)] or types[typeof(value)]
		if streamType then
			--// OTHER
			local _size: number? = streamType.Size
			if _size then
				size += _size
			else
				local getSize: ((any) -> number)? = streamType.GetSize
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

const function readStream(buff: buffer, references: { any }): NBasedArray
	
	--// Check buffer size
	local size: number = buffer.len(buff)
	assert(size <= BUFFER_SIZE_LIMIT, "buffer too large!")

	--// Verify header
	assert(buffer.readstring(buff, 0, HEADER_SIZE) == HEADER, "invalid data sequence provided (unknown header)")

	--// Read element count, and check
	local elementCount: number = buffer.readu16(buff, HEADER_SIZE)
	assert(elementCount <= (size // 2), "invalid data sequence provided (element size is too high relative to buffer size)")

	--// Now start reading!
	local pointer: number = HEADER_SIZE + 2
	local streamed = table.create(elementCount) :: NBasedArray
	streamed.n = elementCount

	for i: number = 1, elementCount do
		local valueType: number = buffer.readu8(buff, pointer)
		pointer += 1
		if valueType == 0 then continue end

		local value: any
		if valueType == 255 then
			--// REFERENCE
			local position: number = buffer.readu16(buff, pointer)
			value = references[position]
			pointer += 2
		else
			--// OTHER
			local streamType: StreamType = typesFromValue[valueType]
			local result: any, pointerOffset: number = streamType.Reader(buff, references, pointer)
			value = result
			pointer += pointerOffset
		end

		streamed[i] = value
	end

	return streamed

end

const function createStream(data: NBasedArray, bufferSize: number): (buffer, { any })

	bufferSize += HEADER_SIZE + 2 --// account for header+element count too

	local dataCount: number = data.n

	--// Create the buffer!
	local buff: buffer = buffer.create(bufferSize)
	local references: { any } = table.create(16)
	local pointer: number = HEADER_SIZE + 2

	--// Write header
	buffer.writestring(buff, 0, HEADER)
	buffer.writeu16(buff, HEADER_SIZE, dataCount)

	for i: number = 1, dataCount do
		local value: any? = data[i]
		if value == nil then
			buffer.writeu8(buff, pointer, 0)
			pointer += 1
			continue
		end

		local streamType: StreamType? = types[type(value)] or types[typeof(value)]
		if streamType ~= nil then
			--// OTHER
			buffer.writeu8(buff, pointer, streamType.Value)
			pointer += 1

			local pointerOffset: number = streamType.Writer(buff, references, pointer, value)
			pointer += pointerOffset
		else
			local newCount: number = #references + 1
			buffer.writeu8(buff, pointer, 255)
			buffer.writeu16(buff, pointer + 1, newCount)

			pointer += 3
			references[newCount] = value
		end
	end

	return buff, references

end


const function createStreamPacket(data: NBasedArray): NetworkPacket
	local size: number = getStreamSizeOfValues(data)
	local buff: buffer, references: { any } = createStream(data, size)
	local packet: NetworkPacket = {
		Data = buff,
		References = references,
	}

	return packet
end

const function createStreamPacketFromArgs(...: any): NetworkPacket
	return createStreamPacket(table.pack(...))
end



Stream._getSizeOfValues = getStreamSizeOfValues
Stream.Read = readStream
Stream.Create = createStream
Stream.CreatePacket = createStreamPacket
Stream.CreatePacketFromArgs = createStreamPacketFromArgs



--// Init types
local typeModules = {}

for _, module in script.Parent:WaitForChild("Types"):GetChildren() do
	if not module:IsA("ModuleScript") then continue end

	local success, result = pcall(require, module :: ModuleScript)

	if success then
		table.insert(typeModules, { Name = module.Name, Module = result })
		if result.Init then
			task.spawn(result.Init, Stream)
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



return Stream