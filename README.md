Stately
====

A library based off of Kikito's awesome library [stateful](https://github.com/kikito/stateful.lua), but uses rxi's class library [classic](https://github.com/rxi/classic).

Note: I currently do NOT have all of the library's features integrated (e.g. :popAll(), etc.), but I plan on doing so.
This is still very much a work in progress. Read as: NOT TESTED ENOUGH. Please help test if you can!

##Usage
Usage is simple and easy.
```lua
-- Car.lua
local Class = require 'Utilities.classic'
local State = require 'Utilities.stately'

local Car = Class:extend( 'Car' )
Car:implement( State ) -- This gives the class the ability to use Stately's functions.

function Car:new( name ) 
	self.name = name
end

function Car:stop() print( 'Stopping the car!' ) end
function Car:speak() print( string.format( 'I am a car named "%s!"', self.name ) ) end
function Car:crash() print( 'This is an example of a fallback. Only the main class has this.' ) end

local Running = Car:addState( 'Running' ) -- Add a new state like so.
function Running:speak() print( string.format( 'I am a running car named "%s!"', self.name ) ) end
function Running:stop() print( 'STOP STOP STOP!' ) end

local Broken = Car:addState( 'Broken' )
function Broken:speak() print( string.format( 'I am a broken car name "%s!" :(', self.name ) ) end
function Broken:stop() print( 'I am broken and therefore already stopped...' ) end

-- Note that none of the states have a :crash() function. Stately supports fallbacks.

return Car
```
```lua
-- main.lua
Car = require 'Source.Car'
Car:pushState( 'Running' ) -- This gives all the cars a default state of 'running'

function love.load()
	Cars = {
		-- Create your cars.
		Honda = Car( 'Honda' ), 
		Chevy = Car( 'Chevy' ), 
		Ford = Car( 'Ford' ), 
	}
	
	local function printCars()
		for _, v in pairs( Cars ) do
			v:speak()
		end
		print'---'
	end
	
	Cars.Honda:pushState( 'Broken' )
	printCars()
	--[[ Output:
		I am a broken car named "Honda"! :(
		I am a running car named "Chevy"!
		I am a running car named "Ford"!
	]]
	
	Cars.Honda:popState() -- You can exit the last state by popping.
	printCars()
	--[[ Output:
		I am a running car named "Honda"!
		I am a running car named "Chevy"!
		I am a running car named "Ford"!
	]]
	
	Cars.Honda:popState() 
	printCars()
	--[[ Output:
		I am a car named "Honda"!
		I am a running car named "Chevy"!
		I am a running car named "Ford"!
	]]
	for _, v in pairs( Cars ) do
		v:crash()
	end
	--[[ Output:
		This is an example of a fallback. Only the main class has this.
		This is an example of a fallback. Only the main class has this.
		This is an example of a fallback. Only the main class has this.
	]]
end
```

##Differences
There are some minor differences in the implementations of Stateful vs. Stately
- `State:getStateStackDebugInfo` returns the states in the reverse order when compared to Stateful.
```lua
local Guy = Class:extend( 'Guy' )
Guy:implement( State )

local Happy = Guy:addState( 'Happy' )
local Sad = Guy:addState( 'Sad' )

local Person = Guy()
Person:pushState( 'Happy' )
Person:pushState( Sad ) -- Either style works, as long as you are in the same context of the state (if the state is local).
Person:getStateStackDebugInfo() 
-- [[ Output: (table)
	<State: Happy>
	<State: Sad>
]] 
```
- `State:addState` does _not_ error when you try to add a new state. Stateful will error if you try to add a state that the class already has. Stately will *not*.

##Requirements
Make sure you are using Lua 5.2 and this slightly modified version of [classic](https://github.com/davisdude/Stately/tree/master/Tests/classic.lua)..

##License
A state library made in Lua
Copyright (C) 2015 Davis Claiborne
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
Contact me at davisclaib at gmail.com
