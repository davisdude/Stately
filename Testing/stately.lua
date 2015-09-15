local defaultFunctions = {
    enteredState = function() end,
    exitedState = function() end,
    pushedState = function() end,
    poppedState = function() end,
    pausedState = function() end,
    continuedState = function() end,
}

-- Local Functions {{{
local function isClassCompatible( class )
    return not not ( class.__stateStack and class.states )
end

local function getStateNameByStack( class, index )
    return class.__stateStack[ index or #class.__stateStack ]
end

local function getStateByStack( class, index )
    return class.states[getStateNameByStack( class, index )]
end

local function getStateByName( class, name )
    return class.states[name]
end

local function validateState( class, name )
    local state = class.states[name]
    assert( state, 'Stately Error: Attempt to access state ' .. tostring( name ) .. '.' )
    return state
end

local function setUpClass( class )
    class.__stateStack = {}
    class.states = {}

    class:implement( defaultFunctions )
    function class:__index( index )
        local stateStack = rawget( self, '__stateStack' ) or {}
        local currentState = class.states[stateStack[#stateStack]]
        return ( currentState and currentState ~= self and currentState[index] )
            or class[index]
    end
end

local function invokeCallback( class, state, callback, ... )
    if class.states[state] then class.states[state][callback]( class, callback, ... ) 
    else class[callback]( class, callback, ... ) end
end -- }}}

-- Library Functions {{{
local function addState( class, name, parentState )
    if not isClassCompatible( class ) then setUpClass( class ) end
    local new = class:extend()
    class.states[name] = new
    return new
end

local function pushState( class, name )
    local oldName = getStateNameByStack( class )
    local oldState = class.states[oldName]
    invokeCallback( class, oldName, 'pausedState' )

    local newState = getStateByName( class, name )
    table.insert( class.__stateStack, name )
    invokeCallback( class, name, 'pushedState' )
    invokeCallback( class, name, 'enteredState' )
end

local function popState( class )
    local oldName = getStateNameByStack( class )
    local oldState = class.states[oldName]
    if oldState then
        invokeCallback( class, oldName, 'poppedState' )
        invokeCallback( class, oldName, 'exitedState' )
        class.__stateStack[#class.__stateStack] = nil
    end

    local newName = getStateNameByStack( class )
    local newState = class.states[newName]
    if newState ~= oldState then
        invokeCallback( class, newName, 'continuedState' )
    end
end

local function popAllStates( class )
    local size = #class.__stateStack
    for i = 1, size do
        class:popState()
    end
end

local function gotoState( class, name, ... )
    popAllStates( class )

    if not name then
        class.__stateStack = {}
    else
        class.__stateStack = { name }
        invokeCallback( class, name, 'enteredState', ... )
    end
end -- }}}

return {
    addState = addState,
    pushState = pushState,
    popState = popState,
    popAllStates = popAllStates,
    gotoState = gotoState,
}
