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
	if not rawget( class, '__inited' ) then add__methods( class ) end
end

local function _setstate( class, state, ... ) -- Default class.setState function. 
	checkInit( class )
	
	local previous = class.__stateStack[#class.__stateStack]
	if type( state ) == 'string' then 
		state = class:getState( state )
	end
	class.__stateStack[#class.__stateStack + 1] = state
end

local function _popstate( class ) -- Default class.popState function.
	checkInit( class )
	
	local state = class.__stateStack[#class.__stateStack]
	assert( state, 'State Error: Attempt to pop state of class with no remaining states.' )
	class.__stateStack[#class.__stateStack] = nil
end

local function _getstate( class, name ) -- Default class.getClass function.
	checkInit( class )
	
	for index, value in pairs( class.__states ) do
		if index == name then return value end
	end
	return nil
end

local function _removestate( class, name ) -- Default class.removeState function.
	checkInit( class )
	
	class.__states[name] = nil
	local pattern = string.format( '<State: %s>', name )
	for index, value in pairs( class.__stateStack ) do -- Pairs to safely iterate.
		local named = tostring( value )
		if named == pattern then table.remove( class.__stateStack, index ) end
	end
end

local function prepareTable( class ) -- Prepares the table for the "state infrastructure."
	checkInit( class )
	
	class.setState = class.setState or _setstate
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
	local new = newState( class, name )
	class.__states[name] = new
	local mt = getmetatable( class )
	
	local __index = function( tab, index ) 
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
		for i, v in pairs( mt ) do
			if index == i then return v end
		end
		return nil
	end
	
	-- Warning: The following is VERY ugly. Don't look at it unless you must.
	setmetatable( class, 
		{ 
			__index = __index, 
			__tostring = class.__tostring, 
			__call = 
				function( _, ... )
					-- checkInit( _ ) -- Doesn't seem necessary currently.
					local new = class.__call( _, ... )
					checkInit( new )
					return setmetatable( new, { __index = __index, __tostring == class.__tostring } )
					-- ^ I can't believe how simple that was. I spent HOURS trying to figure it out. And that's it.
				end, 
		} 
	)
	
	return new
end

return State