--[==[
	Author: 8ch99
	File: boolean.luau
	Date written: 22nd November 2025
	Last edited: 17th December 2025
]==]

--!strict
--!native
--!optimize 2

local EnumTypeNameReferences: { [Enum]: string } = {}

for _, List: Enum in Enum:GetEnums() do
	EnumTypeNameReferences[List] = tostring(List)
end

return {
	GetSize = function(Value: EnumItem): number
		return 5 + #EnumTypeNameReferences[Value.EnumType]
	end,

	Reader = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number): (EnumItem, number)
		local Value: number = buffer.readu32(Buffer, Pointer)
		local ListNameSize: number = buffer.readu8(Buffer, Pointer + 4)
		local ListName: string = buffer.readstring(Buffer, Pointer + 5, ListNameSize)

		return (Enum[ListName] :: any):FromValue(Value), 5 + ListNameSize
	end,

	Writer = function(Buffer: buffer, References: { n: number, [number]: any }, Pointer: number, Value: EnumItem): number
		local ListName: string = EnumTypeNameReferences[Value.EnumType]
		local ListNameSize: number = #ListName

		buffer.writeu32(Buffer, Pointer, Value.Value)
		buffer.writeu8(Buffer, Pointer + 4, ListNameSize)
		buffer.writestring(Buffer, Pointer + 5, ListName, ListNameSize)

		return 5 + ListNameSize
	end,
}