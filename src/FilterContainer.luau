--// Author: 8ch99
--// Date written: 4th May 2026
--// Filter container class for nicely organized priority-sorted checks

--!strict
--!native
--!optimize 2

const DEFAULT_PRIORITY: number = 20


const FilterContainer = {}
FilterContainer.__index = FilterContainer

--// Typedefs

type FilterInfoNode = { Name: string, Priority: number }

export type FilterContainer<T...> = typeof(setmetatable({} :: {
	_container: { [string]: (T...) -> boolean },
	_order: { FilterInfoNode },
	_defaultPriority: number,
}, FilterContainer))



function FilterContainer.new<T...>(defaultPriority: number?): FilterContainer<T...>

	local self = setmetatable({}, FilterContainer)

	self._container = {}
	self._order = {}
	self._defaultPriority = defaultPriority or DEFAULT_PRIORITY

	return self

end

function FilterContainer.Destroy<T...>(self: FilterContainer<T...>)

	table.clear(self._container)
	table.clear(self._order)

	table.clear(self :: any)
	setmetatable(self :: any, nil)
	self = nil :: never

end



function FilterContainer._resort<T...>(self: FilterContainer<T...>)
	table.sort(self._order, function(a: FilterInfoNode, b: FilterInfoNode): boolean
		return a.Priority < b.Priority
	end)
end



--// Adds the given filter if it doesn't already exist
function FilterContainer.AddFilter<T...>(self: FilterContainer<T...>, name: string, callback: (T...) -> boolean, priority: number?)
	if self._container[name] then return end
	self._container[name] = callback

	local node: FilterInfoNode = { Name = name, Priority = priority or self._defaultPriority }
	table.insert(self._order, node)
	self:_resort()
end

--// Removes the given filter if it exists.
function FilterContainer.RemoveFilter<T...>(self: FilterContainer<T...>, name: string)
	if not self._container[name] then return end
	self._container[name] = nil

	for i, node: FilterInfoNode in self._order do
		if node.Name == name then
			table.remove(self._order, i)
			self:_resort()
			break
		end
	end
end

--// Removes all filters currently added to the filter container.
function FilterContainer.Clear<T...>(self: FilterContainer<T...>)
	table.clear(self._order)
	table.clear(self._container)
end



--// Runs default checks on all the filters. Returns true if all filters passed, returns false
--// and the name of the filter that failed if that filter fails.
--// 
--// If there are no filters, this defaults to true
function FilterContainer.Check<T...>(self: FilterContainer<T...>, ...: T...): (boolean, string?)
	if #self._order == 0 then return true, nil end --// None to check

	for _, node: FilterInfoNode in self._order do
		local callback: (T...) -> boolean = self._container[node.Name]
		local result: boolean = callback(...)
		if not result then
			return false, node.Name
		end
	end

	return true, nil
end

--// Runs more lenient checks on all the filters. This will only return false if *every single*
--// filter fails. If at least one filter passes, it will be pass the check
--// 
--// If there are no filters, this defaults to true
function FilterContainer.LenientCheck<T...>(self: FilterContainer<T...>, ...: T...): boolean
	if #self._order == 0 then return true end --// None to check

	for _, node: FilterInfoNode in self._order do
		local callback: (T...) -> boolean = self._container[node.Name]
		local result: boolean = callback(...)
		if result then
			return true
		end
	end

	return false
end



--// Returns the default priority value from the filter container
function FilterContainer.GetDefaultPriority<T...>(self: FilterContainer<T...>): number
	return self._defaultPriority
end

--// Returns the total amount of filters.
function FilterContainer.GetFilterCount<T...>(self: FilterContainer<T...>): number
	return #self._order
end

--// Returns a boolean stating if the given filter exists.
function FilterContainer.DoesFilterExist<T...>(self: FilterContainer<T...>, name: string): boolean
	return self._container[name] ~= nil
end

--// Returns a string array of all filter names, sorted by priority.
function FilterContainer.GetFilterNames<T...>(self: FilterContainer<T...>, name: string): { string }
	local names: { string } = {}
	for _, node: FilterInfoNode in self._order do
		table.insert(names, node.Name)
	end
	return names
end



return FilterContainer