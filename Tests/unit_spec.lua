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

---------------------------------------- gets a new class attribute called 'states' when including the mixin
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

print( type( Enemy.states ) == 'table' )
---------------------------------------- has a list of states, different from the superclass
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

Enemy:addState( 'a' )
local SubEnemy = Enemy:extend( 'SubEnemy' )
print( type( SubEnemy.states ) == 'table' )
print( Enemy.states ~= SubEnemy.states )
---------------------------------------- each inherited state inherits methods from the superclass' states
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Scary = Enemy:addState( 'Scary' )
function Scary:speak() return 'boo!' end
function Scary:fly() return 'like the wind' end

local Clown = Enemy:extend( 'Clown' )
function Clown.states.Scary.speak() return 'mock, mock!' end

local it = Clown()
it:gotoState( 'Scary' )

print( it:fly() == 'like the wind' )
print( it:speak() == 'mock, mock!' )
---------------------------------------- states can be inherited individually too
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

function Enemy:speak() return 'booboo' end

local Funny = Enemy:addState( 'Funny' )
function Funny:laugh() return 'hahaha' end

local VeryFunny = Enemy:addState( 'VeryFunny', Funny )
function VeryFunny:laughMore() return 'hehehe' end

local albert = Enemy()
albert:gotoState( 'VeryFunny' )
print( albert:speak() == 'booboo' )
print( albert:laugh() == 'hahaha' )
print( albert:laughMore() == 'hehehe' )
---------------------------------------- adds an entry to class.states when given a valid, new name
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

Enemy:addState( 'State' )
print( type( Enemy.states.State ) == 'table' )
---------------------------------------- throws an error when given a non-string name
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local _, err1 = pcall( function() Enemy:addState( 1 ) end )
local _, err2 = pcall( function() Enemy:addState() end )

err1 = err1:match( '.-:%s(.*)' ) -- Cuts off the file-path
err2 = err2:match( '.-:%s(.*)' )
print( err1 == 'State Error: Attempt to assign invalid name to state!' )
print( err2 == 'State Error: Attempt to assign invalid name to state!' )
---------------------------------------- doesn't add state callbacks to instances
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

Enemy:addState( 'State' )
local e = Enemy()
e:gotoState( 'State' )
print( e.enterState == nil )
print( e.exitState == nil )
---------------------------------------- makes the class instances use that state methods instead of the default ones
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

function Enemy:foo() return 'foo' end
local SayBar = Enemy:addState( 'SayBar' )
function SayBar:foo() return 'bar' end

local e = Enemy()
print( e:foo() == 'foo' )
e:gotoState( 'SayBar' )
print( e:foo() == 'bar' )
---------------------------------------- calls enteredState callback, if it exists
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Marked = Enemy:addState( 'Marked' )
function Marked:enteredState() self.mark = true end

local e = Enemy()
print( e.mark == nil )

e:gotoState( 'Marked' )
print( e.mark == true )
---------------------------------------- passes all additional arguments to enteredState and exitedState
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local FooEnemy = Enemy:addState( 'FooEnemy' )
local testValue = "Bar"

local function validateVarargs( self, ... ) local val = ...; print( val == testValue ) end
FooEnemy.enteredState = validateVarargs
FooEnemy.exitedState = validateVarargs

local e = Enemy()
e:gotoState( 'FooEnemy', testValue )
---------------------------------------- calls exitedState in all the stacked states
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local counter = 0
local count = function() counter = counter + 1 end
local Jumping = Enemy:addState( 'Jumping' )
local Firing = Enemy:addState( 'Firing' )
local Shouting = Enemy:addState( 'Shouting' )

Jumping.exitedState = count
Firing.exitedState = count

local e = Enemy()
e:pushState( 'Jumping' )
e:pushState( 'Firing' )

e:gotoState( 'Shouting' )

print( counter == 2 )
---------------------------------------- raises an error when given an invalid id
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local e = Enemy()
local _, err1 = pcall( function() Enemy:gotoState( 1 ) end )
local _, err2 = pcall( function() Enemy:gotoState( {} ) end )

err1 = err1:match( '.-:%s(.*)' ) -- Cuts off the file-path
err2 = err2:match( '.-:%s(.*)' )
print( err1 == 'State Error: Attempt to goto non-existant state!' )
print( err2 == 'State Error: Attempt to goto non-existant state!' )
---------------------------------------- raises an error when the state doesn't exist", function()
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local e = Enemy()
local _, err1 = pcall( function() Enemy:gotoState( 'Inexistant' ) end )

err1 = err1:match( '.-:%s(.*)' ) -- Cuts off the file-path
print( err1 == 'State Error: Attempt to goto non-existant state!' )
---------------------------------------- uses the new state state for the lookaheads, before the pushed state
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

e:pushState( 'New' )
print( e:bar() == 'new bar' )
---------------------------------------- invokes the pushedState callback, if it exists
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function New:pushedState() self.mark = true end
e:pushState( 'New' )
print( e.mark == true )
---------------------------------------- invokes the enteredState callback, if it exists
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function New:enteredState() self.mark = true end
e:pushState( 'New' )
print( e.mark == true )
---------------------------------------- does not invoke the exitedState callback on the previous state
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function Piled:exitedState() self.mark = true end
e:pushState( 'New' )
print( e.mark == nil )
---------------------------------------- If the current state has a paused state, it gets invoked
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function Piled:pausedState() self.mark = true end
e:pushState( 'New' )
print( e.mark == true )
---------------------------------------- Renders the object stateless
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

e:pushState( 'New' )
e:popAllStates()
print( e:foo() == 'foo' )
---------------------------------------- Invokes callbacks in the right order
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function Piled:poppedState() self.popped = true end
function New:exitedState() self.exited = true end
e:pushState( 'New' )
e:popAllStates()
print( e.popped == true )
print( e.exited == true )
---------------------------------------- pops the state by name
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

e:pushState( 'New' )
e:popState( 'Piled' )
print( e:foo() == 'foo' )
print( e:bar() == 'new bar' )
---------------------------------------- invokes the poppedState on the popped state, if it exists
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function Piled:poppedState() self.popped = true end
e:pushState( 'New')
e:popState( 'Piled' )
print( e.popped == true )
---------------------------------------- invokes the exitstate on the state that is removed from the pile
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function Piled:exitedState() self.exited = true end
e:pushState( 'New' )
e:popState( 'Piled' )
print( e.exited == true )
---------------------------------------- pops the top state
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

e:pushState( 'New' )
e:popState()
print( e:foo() == 'foo2' )
print( e:bar() == 'bar' )
---------------------------------------- invokes the poppedState callback on the old state
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function Piled:poppedState() self.popped = true end
e:popState()
print( e.popped == true )
---------------------------------------- invokes the continuedState on the new state, if it exists
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

function Piled:continuedState() self.continued = true end
e:pushState( 'New' )
e:popState()
print( e.continued == true )
---------------------------------------- throws an error if the state doesn't exist
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local Pushed, New, e
function Enemy:foo() return 'foo' end

Piled = Enemy:addState( 'Piled' )
function Piled:foo() return 'foo2' end
function Piled:bar() return 'bar' end

New = Enemy:addState( 'New' )
function New:bar() return 'new bar' end

e = Enemy()
e:gotoState( 'Piled' )

e:popState()
local _, err = pcall( function() e:popState( 'Inexisting' ) end )

err = err:match( '.-:%s(.*)' ) -- Cuts off the file-path
print( err == 'State Error: Attempt to pop non-existant state!' )
---------------------------------------- returns an empty table on the nil state
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local e = Enemy()
local info = e:getStateStackDebugInfo()
print( #info == 0 )
---------------------------------------- returns the name of the current state
local Enemy = Class:extend( 'Enemy' )
Enemy:implement( State )

local State1 = Enemy:addState( 'State1' )
local State2 = Enemy:addState( 'State2' )
local e = Enemy()

e:gotoState( 'State1' )
e:pushState( 'State2' )

local info = e:getStateStackDebugInfo()
print( #info == 2 )
print( info[1] == '<State: State1>' )
print( info[2] == '<State: State2>' )