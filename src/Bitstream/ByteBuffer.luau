--[==[
	Author: 8ch99
	File: ByteBuffer.luau
	Date written: 22nd November 2025
	Last edited: 29th November 2025
]==]

--!strict
--!native
--!optimize 2

--// Typedefs

export type ByteBuffer = {
	Pointer: number,
	_buffer: buffer,
}

--// @module ByteBuffer

local ByteBuffer = {}

function ByteBuffer.new(Size: number?): ByteBuffer
	return {
		_buffer = buffer.create(Size or 0),
		Pointer = 0,
	}
end

function ByteBuffer.fromBuffer(Buffer: buffer): ByteBuffer
	return {
		_buffer = Buffer,
		Pointer = 0,
	}
end

function ByteBuffer.Destroy(self: ByteBuffer)
	table.clear(self)
end

function ByteBuffer.GetBuffer(self: ByteBuffer): buffer
	return self._buffer
end

function ByteBuffer.ResetPointer(self: ByteBuffer)
	self.Pointer = 0
end

--[[
function ByteBuffer._expand(self: ByteBuffer, Bytes: number): buffer
	local Buffer: buffer = buffer.create(self._size + Bytes)

	buffer.copy(Buffer, 0, self._buffer)

	self._buffer = Buffer
	self._size += Bytes

	return Buffer
end

function ByteBuffer._incrementPointerAndAllocateIfTooSmall(self: ByteBuffer, Bytes: number): number
	local OldPointer: number = self.Pointer
	local NewPointer: number = OldPointer + Bytes
	local CurrentSize: number = self.Size

	if NewPointer > CurrentSize then
		--// Increment size if too short
		CurrentSize += (NewPointer - CurrentSize)
		self.Size = CurrentSize

		local CurrentBufferSize: number = self._size

		if CurrentSize > CurrentBufferSize then
			ByteBuffer._expand(self, CurrentSize - CurrentBufferSize)
		end
	end

	self.Pointer = NewPointer

	return OldPointer
end
]]

return ByteBuffer