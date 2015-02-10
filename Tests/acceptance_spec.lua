-- Every print statement should be true
local i = 0
local oldPrint = print
local function print( ... )
	i = i + 1
	local tab = { ... }
	io.write( i ) 
	for ii = 1, #tab do
		assert( tab[ii], 'Expected Value tp be true...' )
		oldPrint( '', tab[ii] )
	end
end

--------------------------------------- works on the basic case
local Enemy = Class:extend( 'Enemy' )
function Enemy:new( health ) self.health = health end
function Enemy:speak() return 'My health is ' .. self.health end
Enemy:implement( State )

local Immortal = Enemy:addState( 'Immortal' )
function Immortal:speak() return 'I am UNBREAKABLE!!' end
function Immortal:die() return 'I can not die now!' end

local peter = Enemy( 10 )
print( peter:speak() == 'My health is 10' )

peter:gotoState( 'Immortal' )

print( peter:speak() == 'I am UNBREAKABLE!!' )
print( peter:die() == 'I can not die now!' )

peter:gotoState( nil )

print( peter:speak() == 'My health is 10' )

--------------------------------------- handles basic callbacks
local Enemy = Class:extend( 'Enemy' )
function Enemy:new( health ) self.health = health end
function Enemy:speak() return 'My health is ' .. self.health end
Enemy:implement( State )

local Drunk = Enemy:addState( 'Drunk' )
function Drunk:enteredState() self.health = self.health - 1 end
function Drunk:exitedState() self.health = self.health + 1 end

local john = Enemy( 10 )

print( john:speak() == 'My health is 10' )

john:gotoState( 'Drunk' )
print( john:speak() == 'My health is 9' )
print( john.enteredState == nil )
print( john.exitedState == nil )

john:gotoState( nil )
print( john:speak() == 'My health is 10' )

--------------------------------------- supports state inheritance
local Enemy = Class:extend( 'Enemy' )
function Enemy:new( health ) self.health = health end
function Enemy:speak() return 'My health is ' .. self.health end
Enemy:implement( State )

function Enemy:sing() return 'dadadada' end
function Enemy:singMore() return 'lalalala' end

local Happy = Enemy:addState( 'Happy' )
function Happy:speak() return 'hehehe' end

local Stalker = Enemy:extend( 'Stalker' )
Stalker.states['Happy'].sing = function( self ) return 'I\'ll be watching you' end

local VeryHappy = Stalker:addState( 'VeryHappy', Happy )
function VeryHappy:sing() return 'hehey' end

local jimmy = Stalker(10)

print( jimmy:speak() == 'My health is 10' )
print( jimmy:sing() == 'dadadada' )
jimmy:gotoState( 'Happy' )
print( jimmy:sing()	== 'I\'ll be watching you' )
print( jimmy:singMore() == 'lalalala' )
print( jimmy:speak() == 'hehehe' )
jimmy:gotoState( 'VeryHappy' )
print( jimmy:sing() == 'hehey' )
print( jimmy:singMore()	== 'lalalala' )
print( jimmy:speak() == 'hehehe' )

--------------------------------------- supports state stacking
local Enemy = Class:extend( 'Enemy' )
function Enemy:new( health ) self.health = health end
function Enemy:speak() return 'My health is ' .. self.health end
Enemy:implement( State )

function Enemy:sing() return 'la donna e mobile' end
function Enemy:dance() return 'up down left right' end
function Enemy:all() return table.concat( { self:dance(); self:sing(); self:speak() }, ' - ' ) end

local SteveWonder = Enemy:addState( 'SteveWonder' )
function SteveWonder:sing() return 'you are the sunshine of my life' end

local FredAstaire = Enemy:addState( 'FredAstaire' )
function FredAstaire:dance() return 'clap clap clappity clap' end

local PhilCollins = Enemy:addState( 'PhilCollins' )
function PhilCollins:dance() return 'I can\'t dance' end
function PhilCollins:sing() return 'I can\'t sing' end
function PhilCollins:speak() return 'Only thing about me is the way I walk' end

local artist = Enemy( 10 )

print( artist:all() == 'up down left right - la donna e mobile - My health is 10' )

artist:gotoState('PhilCollins')
print( artist:all()	== 'I can\'t dance - I can\'t sing - Only thing about me is the way I walk' )

artist:pushState('FredAstaire')
print( artist:all() == 'clap clap clappity clap - I can\'t sing - Only thing about me is the way I walk' )

artist:pushState('SteveWonder')
print( artist:all() == 'clap clap clappity clap - you are the sunshine of my life - Only thing about me is the way I walk' )

artist:popAllStates()
print( artist:all() == 'up down left right - la donna e mobile - My health is 10' )


artist:pushState( 'PhilCollins' )
artist:pushState( 'FredAstaire' )
artist:pushState( 'SteveWonder' )

artist:popState( 'FredAstaire' )
print( artist:all() == 'I can\'t dance - you are the sunshine of my life - Only thing about me is the way I walk' )

artist:popState()
print( artist:all() == 'I can\'t dance - I can\'t sing - Only thing about me is the way I walk' )

artist:popState( 'FredAstaire' )
print( artist:all() == 'I can\'t dance - I can\'t sing - Only thing about me is the way I walk' )

artist:gotoState( 'FredAstaire' )
print( artist:all() == 'clap clap clappity clap - la donna e mobile - My health is 10' )

--------------------------------------- has stack-related callbacks
local Enemy = Class:extend( 'Enemy' )
function Enemy:new( health ) self.health = health end
Enemy:implement( State )

function Enemy:speak() return 'My health is ' .. self.health end

local TweetPaused = Enemy:addState( 'TweetPaused' )
function TweetPaused:pausedState() self.tweet = true end

local TootContinued = Enemy:addState( 'TootContinued' )
function TootContinued:continuedState() self.toot = true end

local PamPushed = Enemy:addState( 'PamPushed' )
function PamPushed:pushedState() self.pam = true end

local PopPopped = Enemy:addState( 'PopPopped' )
function PopPopped:poppedState() self.pop = true end

local QuackExited = Enemy:addState( 'QuackExited' )
function QuackExited:exitedState() self.quack = true end

local MooEntered = Enemy:addState( 'MooEntered' )
function MooEntered:enteredState() self.moo = true end

local e = Enemy()
e:gotoState( 'TweetPaused' )
print( e.tweet == nil )
e:pushState( 'TootContinued' )
print( e.tweet == true )

e:pushState( 'PopPopped' )
e:popState()

print( e.toot == true )
print( e.pop == true )

e:pushState( 'PopPopped' )
e:pushState( 'PamPushed' )

print( e.pam == true )

e.toot = false
e.pop = false

e:popState( 'PopPopped' )
print( e.pop == true )

e:popState()
print( e.toot == true )

e:pushState( 'QuackExited' )
e:pushState( 'MooEntered' )
print( e.moo == true )
print( e.quack == nil )

e.quack = false
e:popState( 'QuackExited' )
print( e.quack == true )

e = Enemy()
e:pushState( 'PopPopped' )
e:pushState( 'QuackExited' )
e:popAllStates()
print( e.pop == true )
print( e.quack == true )

--------------------------------------- has debugging info
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local State1 = Enemy:addState('State1')
local State2 = Enemy:addState('State2')

local e = Enemy()
local info = e:getStateStackDebugInfo()
print( #info == 0 )

e:pushState('State1')
info = e:getStateStackDebugInfo()
print( #info == 1 )
print( info[1] == '<State: State1>' )

e:pushState('State2')
info = e:getStateStackDebugInfo()
print( #info == 2 )
print( info[1] == '<State: State1>' )
print( info[2] == '<State: State2>' )