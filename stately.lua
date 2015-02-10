local function isState( state ) -- Check if class submitted is a state.
	if tostring( state ):find( '<State:' ) == 1 then return true end
	return false
end

local function addMethods( class ) -- Make sure table is set up properly
	local previous = class.super.__stateStack or {}
	
	class.__inited = true
	class.__stateStack = rawget( class, '__stateStack' ) or {}	
	class.states = class.states or {}
	
	for index = #previous, 1, -1 do -- Add inheritance from parents.
		table.insert( class.__stateStack, 1, previous[index] )
	end
end

local function checkInit( class )
	if not rawget( class, '__inited' ) then return false else return true end
end

local function format( class ) -- Set up table only once.
	if not checkInit( class ) then addMethods( class ); return false else return true end
end

local function pushState( class, state, ... ) -- Default class.setState function. 
	local previous = class.__stateStack[#class.__stateStack]
	if previous then 
		previous.pausedState( class, ... )
	end
	
	state = class:getState( state )
	assert( state, 'State Error: Attempt to push non-existant state!' )
	
	state.pushedState( class, ... )
	state.enteredState( class, ... )
	
	table.insert( class.__stateStack, state )
end

local function getStateIndexFromStackByName( class, name )
	if name == nil then return #class.__stateStack end
	local target = class:getState( name )
	for i = #class.__stateStack, 1, -1 do
		if class.__stateStack[i] == target then return i end
	end
end

local function getCurrentState( class )
	return class.__stateStack[#class.__stateStack]
end

local function popState( class, name ) -- Default class.popState function.
	assert( not(  name ~= nil and not class:getState( name ) ), 'State Error: Attempt to pop non-existant state!' )
	
	local oldStateIndex = getStateIndexFromStackByName( class, name )
	local oldState
	
	if oldStateIndex and oldStateIndex > 0 then
		oldState = class.__stateStack[oldStateIndex]
		
		oldState.poppedState( class )
		oldState.exitedState( class )
		
		table.remove( class.__stateStack, oldStateIndex )
	end
	
	local newState = getCurrentState( class )
	
	if newState and oldState ~= newState then
		newState.continuedState( class )
	end
end

local function popAllStates( class ) -- Default class.popAllStates function.
	for i = #class.__stateStack, 1, -1 do
		class:popState()
	end
end

local function getStateName( state ) -- Gets the string version of the state name.
	return tostring( state ):sub( 9, -2 )
end

local function getState( class, name ) -- Default class.getClass function.
	if type( name ) == 'string' then
		for index, value in pairs( class.states ) do
			if index == name then return value end
		end
	elseif isState( name ) then
		return name
	end
end

local function removeState( class, name ) -- Default class.removeState function.
	class.states[name] = nil
	local pattern = string.format( '<State: %s>', name )
	for index, value in pairs( class.__stateStack ) do -- Pairs to safely iterate.
		local named = tostring( value )
		if named == pattern then table.remove( class.__stateStack, index ) end
	end
end

local function gotoState( class, state, ... ) -- Default class.gotoState function. 
	class:popAllStates()
	
	if state == nil then 
		class.__stateStack = {}
	else
		state = class:getState( state )
		assert( state, 'State Error: Attempt to goto non-existant state!' )
		state.enteredState( class, ... )
		class.__stateStack = { state }
	end
end

local function getStateStackDebugInfo( class )
	local info = {}
	for i = 1, #class.__stateStack do
		info[i] = tostring( class.__stateStack[i] )
	end
	return info
end

local function prepareTable( class ) -- Prepares the table for the "state infrastructure."
	format( class )
	
	class.popAllStates = class.popAllStates or popAllStates
	class.gotoState = class.gotoState or gotoState
	class.pushState = class.pushState or pushState
	class.popState = class.popState or popState
	class.getState = class.getState or getState
	class.removeState = class.removeState or removeState
	class.getStateStackDebugInfo = class.getStateStackDebugInfo or getStateStackDebugInfo
end

local function newState( class, name ) -- Creates the framework for the state being added.
	local new = class:extend( name, 'State' )

	new.enteredState = function() end
	new.exitedState = function() end
	new.pausedState = function() end
	new.continuedState = function() end
	new.pushedState = function() end
	new.poppedState = function() end
	
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
		assert( type( name ) == 'string', 'State Error: Attempt to assign invalid name to state!' )
		
		local new = newState( class, name )
		class.states[name] = new
		
		if inheritance then 
			if type( inheritance ) == 'string' and not checkInit( class ) then
				error( 'State Error: Attempt to give inheritance to a class with no parent!' )
			end
			inheritance = class.getState and class:getState( inheritance )
			for index, value in pairs( inheritance ) do
				new[index] = value
			end
		end
		
		return new
	end, 
	__callback_setUpClass = function( class ) -- Set up the class.
		local mt = getmetatable( class )
		
		local function _index( tab, index )
			-- First look through currently implemented class.
			if ( rawget( tab, '__stateStack' ) and #tab.__stateStack > 0 ) and
			( index ~= 'enteredState' and index ~= 'exitedState' and index ~= 'pausedState' and index ~= 'continuedState' and index ~= 'pushedState' and index ~= 'poppedState' ) then
				for state = #tab.__stateStack, 1, -1 do
					-- print( state, tab.__stateStack[state], index )
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
			return string.format( '<%s: %s - State: %s>', class.super.__prefix, class.super.__type, getStateName( getCurrentState( class ) ) )
		end
		
		local oldCall = class.__call
		local oldTostring = class.__tostring
		local newCall
		
		prepareTable( class )
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
	end, 
}