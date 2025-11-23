--[==[
	Author: 8ch99
	File: PathWaypoint.luau
	Date written: 15th November 2025
	Last edited: 15th November 2025
]==]

--!strict
--!native
--!optimize 2

local ByteBuffer = require("../ByteBuffer")

local ReadVector3 = ByteBuffer.ReadVector3
local ReadUInt8 = ByteBuffer.ReadUInt8
local ReadString = ByteBuffer.ReadString

local WriteVector3 = ByteBuffer.WriteVector3
local WriteUInt8 = ByteBuffer.WriteUInt8
local WriteString = ByteBuffer.WriteString

return {
	Size = 12,

	Reader = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }): PathWaypoint
		local Position: Vector3 = ReadVector3(Buffer)
		local Action: Enum.PathWaypointAction = Enum.PathWaypointAction:FromValue(ReadUInt8(Buffer)) :: Enum.PathWaypointAction
		local Label: string = ReadString(Buffer)

		return PathWaypoint.new(Position, Action, Label)
	end,

	Writer = function(Buffer: ByteBuffer.ByteBuffer, References: { Count: number, Data: { any } }, Value: PathWaypoint)
		WriteVector3(Buffer, Value.Position)
		WriteUInt8(Buffer, Value.Action.Value)
		WriteString(Buffer, Value.Label)
	end,
}