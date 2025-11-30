--[==[
	Author: 8ch99
	File: boolean.luau
	Date written: 22nd November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local EnumTypeNameReferences: { [Enum]: string } = {}

for _, List: Enum in Enum:GetEnums() do
	EnumTypeNameReferences[List] = tostring(List)
end

return {
	GetSize = function(Value: EnumItem): number
		return 5 + #EnumTypeNameReferences[Value.EnumType]
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): EnumItem
		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		local Value: number = buffer.readu32(_buffer, Pointer)
		local ListNameSize: number = buffer.readu8(_buffer, Pointer + 4)
		local ListName: string = buffer.readstring(_buffer, Pointer + 5, ListNameSize)

		Buffer.Pointer += 5 + ListNameSize

		return (Enum[ListName] :: any):FromValue(Value)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: EnumItem)
		local ListName: string = EnumTypeNameReferences[Value.EnumType]
		local ListNameSize: number = #ListName

		local _buffer: buffer = Buffer._buffer
		local Pointer: number = Buffer.Pointer

		buffer.writeu32(_buffer, Pointer, Value.Value)
		buffer.writeu8(_buffer, Pointer + 4, ListNameSize)
		buffer.writestring(_buffer, Pointer + 5, ListName, ListNameSize)

		Buffer.Pointer += 5 + ListNameSize
	end,
}