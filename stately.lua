local function isState( state ) -- Check if class submitted is a state.
	if tostring( state ):find( '<State:' ) == 1 then return true end
	return false
end

local function add__methods( class ) -- Make sure table is set up properly
	local previous = class.super.__stateStack or {}
	
	class.__inited = true
	class.__stateStack = rawget( class, '__stateStack' ) or {}	
	class.__states = class.__states or {}
	class.__currentState = nil
	
	for index = #previous, 1, -1 do -- Add inheritance from parents.
		table.insert( class.__stateStack, 1, previous[index] )
	end
end

local function checkInit( class )
	if not rawget( class, '__inited' ) then return false else return true end
end

local function format( class ) -- Set up table only once.
	if not checkInit( class ) then add__methods( class ); return false else return true end
end

local function _pushstate( class, state, ... ) -- Default class.setState function. 
	local previous = class.__stateStack[#class.__stateStack]
	state = class:getState( state )
	assert( state, 'State Error: Attempt to non-existant state!' )
	
	if previous then previous.exitedState( class ) end
	assert( not ( tostring( previous ) == tostring( state ) ), 'State Error: Attempt to set state already set!' )
	state:enteredState( previous )
	class.__currentState = state
	
	table.insert( class.__stateStack, state )
end

local function _popstate( class, name ) -- Default class.popState function.
	local index = #class.__stateStack
	name = class:getState( name )
	if name then
		for i = #class.__stateStack, 1, -1 do
			if class.__stateStack[i] == name then
				index = i
				break
			end
		end
	end

	local state = class.__stateStack[#class.__stateStack]
	assert( state, 'State Error: Attempt to pop state of class with no remaining states.' )
	
	class.__stateStack[index].exitedState( class )
	table.remove( class.__stateStack, index )
	
	local current = #class.__stateStack
	while not class.__stateStack[current] do
		current = current - 1
	end
	class.__currentState = class.__stateStack[current]
end

local function _getStateName( state ) -- Gets the string version of the state name.
	-- <State: asdfa;lkj;lkja;dslkfj>
	return tostring( state ):sub( 9, -2 )
end

local function _getstate( class, name ) -- Default class.getClass function.
	if type( name ) == 'string' then
		for index, value in pairs( class.__states ) do
			if index == name then return value end
		end
		error( 'State Error: Attempt to get non-existant state!' )
	elseif isState( name ) then
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
		class.__stateStack[index].exitedState( class )
		class.__stateStack[index] = nil
	end
	class.__currentState = nil
end

local function _gotostate( class, state ) -- Default class.gotoState function. 
	class:popAllStates()

	state = class:getState( state )
	assert( state, 'State Error: Attempt to goto non-existant state!' )
	state.enteredState( class, class.__stateStack[#class.__stateStack] )
	
	class.__stateStack[#class.__stateStack + 1] = state
	class.__currentState = state
end

local function prepareTable( class ) -- Prepares the table for the "state infrastructure."
	format( class )
	
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
	
	new.enteredState = function() end
	new.exitedState = function() end
	
	return new
end

local function defaultMt( mt, index, custom )
	local tab = { 
		__index = index or mt.__index, 
		__call = mt.__call, 
		
		__newindex = mt.__newindex, 
		__tostring = mt.__tostring, 
		__gc = mt.__gc, 
		__concat = mt.__concat, 
		
		__unm = mt.__unm, 
		__add = mt.__add, 
		__sub = mt.__sub, 
		__mul = mt.__mul, 
		__div = mt.__div, 
		__pow = mt.__pow, 
		__eq = mt.__eq, 
		__lt = mt.__lt, 
		__le = mt.__le, 
	}
	for i, v in pairs( custom ) do
		tab[i] = v
	end
	return tab
end

return {
	addState = function( class, name, inheritance ) -- Adds a new state to the class.
		local mt = getmetatable( class )
		
		local function _index( tab, index )
			-- First look through currently implemented class.
			if rawget( tab, '__stateStack' ) and #tab.__stateStack > 0 and ( index ~= 'enteredState' and index ~= 'exitedState' ) then
				for state = #tab.__stateStack, 1, -1 do
					for i, v in pairs( tab.__stateStack[state] ) do -- Look through the currently active state only.
						if index == i then return v end
					end
				end
			end
			for i, v in pairs( tab ) do 
				if index == i then return v end
			end
			for i, v in pairs( class ) do
				if index == i then return v end
			end
			return ( ( type( mt.__index ) == 'function' ) and mt.__index( class, index ) ) 
				or ( ( type( mt.__index ) == 'table' ) and mt.__index[index] )
		end
		local function _tostring( class )
			return string.format( '<%s: %s - State: %s>', class.super.__prefix, class.super.__type, _getStateName( class.__currentState ) )
		end
		
		local oldCall = class.__call
		local oldTostring = class.__tostring
		local newCall
		
		if not checkInit( class ) then
			newCall = function( _, ... )
				local new = oldCall( _, ... )
				prepareTable( new )
				
				new.__index = _index
				new.__tostring = _tostring
				new.__index = _index
				return setmetatable( new, defaultMt( mt, _index, { __tostring = _tostring } ) )
			end 
			
			class.__call = newCall
			class.__tostring = oldTostring
			class.__index = _index
			setmetatable( class, defaultMt( mt, _index, { __call = newCall, __tostring = oldTostring } ) )
		end
		
		local new = newState( class, name )
		
		class.__states[name] = new
		
		if inheritance then
			if type( inheritance ) == 'string' and not checkInit( class.super ) then
				error( 'State Error: Attempt to give inheritance to a class with no parent!' )
			end
			inheritance = class.super:getState( inheritance )
			for index, value in pairs( inheritance ) do
				if not rawget( new, index ) then new[index] = value end
			end
		end
		
		return new
	end, 
}