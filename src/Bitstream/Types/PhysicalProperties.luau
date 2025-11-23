--[==[
	Author: 8ch99
	File: PhysicalProperties.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!nonstrict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadFloat32 = ByteBuffer.ReadFloat32

local WriteFloat32 = ByteBuffer.WriteFloat32

return {
	Size = 24,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): PhysicalProperties
		return PhysicalProperties.new(
			ReadFloat32(Buffer),
			ReadFloat32(Buffer),
			ReadFloat32(Buffer),
			ReadFloat32(Buffer),
			ReadFloat32(Buffer),
			ReadFloat32(Buffer)
		)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: PhysicalProperties)
		WriteFloat32(Buffer, Value.Density)
		WriteFloat32(Buffer, Value.Friction)
		WriteFloat32(Buffer, Value.Elasticity)
		WriteFloat32(Buffer, Value.FrictionWeight)
		WriteFloat32(Buffer, Value.ElasticityWeight)
		WriteFloat32(Buffer, Value.ElasticityWeight)
	end,
}