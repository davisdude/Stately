-- A Stateful class
local Enemy
local function clear()
    Enemy = Object:extend()
    Enemy:implement( stately )
    function Enemy:new( health )
        self.health = health
    end
    function Enemy:speak()
        return 'My health is ' .. tostring( self.health )
    end
end

-- It works on the basic case
do
    clear()
    local Immortal = Enemy:addState( 'Immortal' )
    function Immortal:speak() return 'I am UNBREAKABLE!!' end
    function Immortal:die() return 'I cannot die now!' end

    local peter = Enemy( 10 )
    isEqual( peter:speak(), 'My health is 10' )

    peter:gotoState( 'Immortal' )
    isEqual( peter:speak(), 'I am UNBREAKABLE!!' )
    isEqual( peter:die(), 'I cannot die now!' )

    peter:gotoState( nil )
    isEqual( peter:speak(), 'My health is 10' )
end

-- It handles basic callbacks
do
    clear()
    local Drunk = Enemy:addState( 'Drunk' )
    function Drunk:enteredState() self.health = self.health - 1 end
    function Drunk:exitedState() self.health = self.health + 1 end

    local john = Enemy( 10 )
    isEqual( john:speak(), 'My health is 10' )

    john:gotoState( 'Drunk' )
    isEqual( john:speak(), 'My health is 9' )
    -- See differences in README

    john:gotoState( nil )
    isEqual( john:speak(), 'My health is 10' )
end

-- It supports state inheritance
do
    clear()
    
    function Enemy:sing() return 'dadadada' end
    function Enemy:singMore() return 'lalalala' end

    local Happy = Enemy:addState( 'Happy' )
    function Happy:speak() return 'hehehe' end

    local Stalker = Enemy:extend()
    function Stalker.states.Happy:sing() return 'I\'ll be watching you' end

    local VeryHappy = Stalker:addState( 'VeryHappy', Happy )
end
