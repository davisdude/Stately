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

local function getStateName( self, target )
	for name, state in pairs( self.states or {} ) do
		if state == target then return name end
	end
end

local function assertString( var )
	local t = type( var )
	assert( t == 'string', 'Expected ' .. tostring( var ) .. ' to be of type "string", got "' .. t .. '".' )
end

local function assertStringOrState( var )
	local t = type( var )
	if t ~= 'string' and t ~= 'table' then
		error( 'Expected ' .. tostring( var ) .. ' to be of type "string" or "table", got "' .. t .. '".' )
	elseif t == 'table' then
		assert( var.enteredState, 'Expected ' .. tostring( var ) .. ' to be a class.' )
	end
end

local function assertClassHasState( class, state )
	state = getStateName( class, state )
	assert( class.states[state], 'Invalid state: State "' .. tostring( state ) .. '" does not exist in the class.' )
end

local function copy( t )
	local tab = {}
	for i, v in pairs( t ) do
		tab[i] = v
	end
	return tab
end

local superState = {
	enteredState = function() end,
	exitedState = function() end,
	pushedState = function() end,
	poppedState = function() end,
	pausedState = function() end,
	continuedState = function() end,
}

local State = {
	addState = function( class, state, parentState )
		parentState = parentState or superState
		assertString( state )
		assert( class.states[state] == nil, 'State ' .. state .. ' already exists in class' )
		class.states[state] = setmetatable( {}, { __index = parentState } )
		return class.states[state]
	end,
	gotoState = function( class, state, ... )
		class:popAllStates( ... )
		if not state then
			class.__stateStack = {}
		else
			assertStringOrState( state )
			local newState = class.states[state] or state
			assertClassHasState( class, newState )
			class.__stateStack = { newState }
			invokeCallback( class, newState, 'enteredState', ... )
		end
	end,
	pushState = function( class, state, ... )
		local oldState = getCurrentState( class )
		invokeCallback( class, oldState, 'pausedState', ... )

		assertStringOrState( state )
		local newState = class.states[state] or state
		assertClassHasState( class, newState )
		table.insert( class.__stateStack, newState )

		invokeCallback( class, newState, 'pushedState', ... )
		invokeCallback( class, newState, 'enteredState', ... )
	end,
	popState = function( class, state, ... )
		if state ~= nil then
			assertStringOrState( state )
			local newState = class.states[state] or state
			assertClassHasState( class, newState )
		end

		local oldIndex, oldState = getStateIndexFromStack( class, state )
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
		local info = {}
		local state
		for i = #class.__stateStack, 1, -1 do
			local name = getStateName( class, class.__stateStack[i] )
			table.insert( info, name )
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
		class.states = copy( self.states or {} )

		class.__stateStack = {}

		protocols[class] = {
			function( c, i )
				local stateStack = rawget( c, '__stateStack' ) or {}
				for index = #stateStack, 1, -1 do
					if stateStack[index][i] then
						return stateStack[index][i]
					end
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
				if superState[i] then return nil end
				return test( protocols[self], tab, i )
			end
		} )
		obj:new( ... )
		return obj
	end
end } )
