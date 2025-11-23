--[==[
	Author: 8ch99
	File: boolean.luau
	Date written: 22nd November 2025
	Last edited: 22nd November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local EnumTypeNameReferences: { [Enum]: string } = ByteBuffer._getEnumTypeNameReferences()

local ReadEnumItem = ByteBuffer.ReadEnumItem

local WriteEnumItem = ByteBuffer.WriteEnumItem

return {
	GetSize = function(Value: EnumItem): number
		return 5 + #EnumTypeNameReferences[Value.EnumType]
	end,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): EnumItem
		return ReadEnumItem(Buffer)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: EnumItem)
		WriteEnumItem(Buffer, Value)
	end,
}