local superState = {
	enteredState = function() end,
	exitedState = function() end,
	pushedState = function() end,
	poppedState = function() end,
	pausedState = function() end,
	continuedState = function() end,
}

local function copy( tab )
	local new = {}
	for i, v in pairs( tab ) do new[i] = v end
	return new
end

local function invokeCallback( self, state, callback, ... )
	if state and state[callback] then state[callback]( self, ... ) end
end

local function getStateIndexFromStack( class, state )
	if not state then return #class.__stateStack end
	state = class.states[state] or state

	for i = #class.__stateStack, 1, -1 do
		if class.__stateStack[i] == state then return i end
	end
end

local function test( protocols, self, index )
	for i = 1, #protocols do
		local result = protocols[i]( self, index )
		if result ~= nil then return result end
	end
end

local function getCurrentState( class )
	local stateStack = rawget( class, '__stateStack' ) or {}
	return stateStack[#stateStack]
end

local function getStateName( class, state )
	for i, v in pairs( class.states ) do
		if v == state then return i end
	end
end

local function validateState( states, state )
	local t = type( state )
	assert( t == 'string' or t == 'table', 'Stately Error: Invalid state reference: State reference must be a string or table' )
	if t == 'string' then
		assert( states[state], string.format( 'Stately Error: Invalid state reference: State %s is not a part of this class', tostring( state ) ) )
	else
		for i in pairs( superState ) do
			assert( type( state[i] ) == 'function', 'Stately Error: Invalid state reference: Tables passed must be states' )
		end
	end
end

local State = {
	addState = function( class, name, parent )
		assert( type( name ) == 'string', 'Stately Error: State names must be strings!' )
		assert( not class.states[name], 'Stately Error: No duplicate state names!' )

		parent = parent or superState
		class.states[name] = setmetatable( {}, { __index = parent } )
		return class.states[name]
	end,
	gotoState = function( class, state, ... )
		class:popAllStates( ... )
		if not state then
			class.__stateStack = {}
		else
			validateState( class.states, state )
			local newState = class.states[state] or state
			class.__stateStack = { newState }
			invokeCallback( class, newState, 'enteredState', ... )
		end
	end,
	pushState = function( class, state, ... )
		validateState( class.states, state )

		local oldState = getCurrentState( class )
		invokeCallback( class, oldState, 'pausedState', ... )

		local newState = class.states[state] or state
		table.insert( class.__stateStack, newState )

		invokeCallback( class, newState, 'pushedState', ... )
		invokeCallback( class, newState, 'enteredState', ... )
	end,
	popState = function( class, state, ... )
		if state then validateState( class.states, state ) end
		local oldIndex = getStateIndexFromStack( class, state )
		local oldState

		if oldIndex then
			oldState = class.__stateStack[oldIndex]

			invokeCallback( class, oldState, 'poppedState', ... )
			invokeCallback( class, oldState, 'exitedState', ... )

			table.remove( class.__stateStack, oldIndex )
		end

		local newState = getCurrentState( class )
		if oldState ~= newState then
			invokeCallback( class, newState, 'continuedState', ... )
		end
	end,
	popAllStates = function( class, ... )
		local size = #class.__stateStack
		for i = 1, size do
			class:popState( nil, ... )
		end
	end,
	getStateStackDebugInfo = function( class )
		local info, state = {}
		for i = 1, #class.__stateStack do
			state = class.__stateStack[i]
			table.insert( info, getStateName( class, state ) )
		end
		return info
	end,
}

local protocols = {}

return setmetatable( State, { __call = function( _, Classic )
	local oldExtend = Classic.extend
	Classic.extend = function( self, ... )
		local class = oldExtend( self, ... )
		class:implement( State )

		class.states = copy( class.states or {} )
		class.__stateStack = {}

		protocols[class] = {
			function( c, i )
				local stateStack = rawget( c, '__stateStack' ) or {}
				for count = #stateStack, 1, -1 do
					local val = stateStack[count][i]
					if val then return val end
				end
			end,
			function( c, i ) return rawget( c, i ) end,
			function( c, i ) return class[i] end,
		}

		return class
	end

	Classic.__call = function( self, ... )
		local obj = setmetatable( {}, {
			__index = function( tab, i )
				return ( not superState[i] ) and test( protocols[self], tab, i ) or nil
			end
		} )
		obj:new( ... )
		return obj
	end
end } )
