local State = {}

local function add__methods( class ) -- Make sure table is set up properly
	local previous = class.super.__stateStack or {}
	
	class.__inited = true
	class.__stateStack = rawget( class, '__stateStack' ) or {}	
	class.__states = class.__states or {}
	
	for index = #previous, 1, -1 do -- Add inheritance from parents.
		table.insert( class.__stateStack, previous[index] )
	end
end

local function checkInit( class ) -- Set up table only once.
	if not rawget( class, '__inited' ) then add__methods( class ) else return true end
end

local function _pushstate( class, state, ... ) -- Default class.setState function. 
	local previous = class.__stateStack[#class.__stateStack]
	if type( state ) == 'string' then 
		state = class:getState( state )
	end
	class.__stateStack[#class.__stateStack + 1] = state
end

local function _popstate( class ) -- Default class.popState function.
	local state = class.__stateStack[#class.__stateStack]
	assert( state, 'State Error: Attempt to pop state of class with no remaining states.' )
	class.__stateStack[#class.__stateStack] = nil
end

local function _getstate( class, name ) -- Default class.getClass function.
	if type( name ) == 'string' then
		for index, value in pairs( class.__states ) do
			if index == name then return value end
		end
		return nil
	elseif tostring( name ):find( '<State:' ) == 1 then
		return name
	end
end

local function _removestate( class, name ) -- Default class.removeState function.
	class.__states[name] = nil
	local pattern = string.format( '<State: %s>', name )
	for index, value in pairs( class.__stateStack ) do -- Pairs to safely iterate.
		local named = tostring( value )
		if named == pattern then table.remove( class.__stateStack, index ) end
	end
end

local function _popallstates( class ) -- Default class.popAllStates function.
	for index = #class.__stateStack, 1, -1 do
		-- class.__stateStack[index]:exitedState()
		class.__stateStack[index] = nil
	end
end

local function _gotostate( class, state ) -- Default class.gotoState function.
	class:popAllStates()
	state = class:getState( state )
	class.__stateStack[#class.__stateStack + 1] = state
end

local function prepareTable( class ) -- Prepares the table for the "state infrastructure."
	checkInit( class )
	
	class.popAllStates = class.popAllStates or _popallstates
	class.gotoState = class.gotoState or _gotostate
	class.pushState = class.pushState or _pushstate
	class.popState = class.popState or _popstate
	class.getState = class.getState or _getstate
	class.removeState = class.removeState or _removestate
end

local function newState( class, name ) -- Creates the framework for the state being added.
	local new = class:extend( name, true, 'State' )
	prepareTable( class )
	return new
end

function State.addState( class, name ) -- Adds a new state to the class.
	local mt = getmetatable( class )
	local _index = function( tab, index )
		-- First look through currently implemented class.
		if rawget( tab, '__stateStack' ) and #tab.__stateStack > 0 then
			for i, v in pairs( tab.__stateStack[#tab.__stateStack] ) do -- Look through the currently active state only.
				if index == i then return v end
			end
		end
		for i, v in pairs( tab ) do 
			if index == i then return v end
		end
		for i, v in pairs( class ) do
			if index == i then return v end
		end
		return ( ( type( mt.__index ) == 'function' ) and mt.__index( class, index ) ) or ( ( type( mt.__index ) == 'table' ) and mt.__index[index] )
	end
	
	local oldCall = class.__call
	if not checkInit( class ) then
		function class.__call( _, ... )
			local new = oldCall( _, ... )
			prepareTable( new )
			return setmetatable( new, {
					__index = _index, 
					__tostring = class.__tostring 
				} 
			)
		end 
	end
	checkInit( class )
	
	local new = newState( class, name )
	class.__states[name] = new
	setmetatable( class, { __index = _index, __call = oldCall, __tostring = class.__tostring } )
	
	return new
end

return State