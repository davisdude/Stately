# Stately

* This is intended to be [stateful] but for [classic].
* There are some minor differences between __stately__ and [stateful].

# Table of Contents

* [Example](#example)
* [Installation](#installation)
* [Differences](#differences)
* [Functions](#functions)
* [Specs](#specs)

# Example

```lua
local Class = require 'classic.classic'
local State = require 'stately' ( Class )

local Enemy = Class:extend()

function Enemy:new( health )
	self.health = health
end

function Enemy:speak()
	return 'My health is ' .. tostring( self.health )
end

local Immortal = Enemy:addState( 'Immortal' )

-- Overridden function
function Immortal:speak()
	return 'I am UNBREAKABLE!!'
end

-- Added function
function Immortal:die()
	return 'I cannot die now!'
end

local peter = Enemy( 10 )
peter:speak() -- My health is 10
peter:gotoState( 'Immortal' )
peter:speak() -- I am UNBREAKABLE!!
peter:die() -- I cannot die now!
peter:gotoState() -- Go to default state when nil is passed
peter:speak() -- My health is 10
peter:die() -- Error - not a function
```

# Installation

You need a copy of [classic] in your project. Then, download this repo and put it in that folder, too.

To use it, simply require it.

```lua
local Class = require 'path.to.classic'
-- Make sure to pass the table of classic when you require stately.
local State = require 'path.to.stately' ( Class )
```

Be __SURE__ to require `classic` _before_ `stately`.

# Differences

There are some minor differences between __stately__ and [stateful]:

* [Class:gotoState](#classgotostate), [Class:pushState](#classpushstate), and [Class:popState](#classpopstate) all accept the state table return by [Class:addState](#classaddstate) as well as the string used to identify it.
* There is no need to `:implement` like with [stateful]; instead, you need to pass the table returned by Classic when you `require` it (see [Installation](#installation) for more).

# Functions

### Class:addState

* `State = Class:addState( name, parent )`
	* Adds a new state to the class.
	* `name`: string. The name of the state.
	* `parent`: `nil` or `State`. The parent class that this state should inherit.
	* `State`: `State`. The state of the class.

#### State:enteredState

* `function State:enteredState( ... ) end`
	* This callback is invoked by [Class:gotoState[(#classgotostate) (if the state to go to is defined) and [Class:pushState](#classpushstate). You can define this function, but cannot call it; it is used internally.
	* `State`: `State`. A state object.
	* `...`: varargs. Whatever is passed to [Class:gotoState](#classgotostate) or [Class:pushState](#classpushstate).

#### State:exitedState

* `function State:exitedState( ... ) end`
	* This callback is invoked by [Class:popState](#classpopstate) (which itself is invoked by [Class:gotoState](#classgotostate) and [Class:popAllStates](#classpopallstates)). You can define this function, but cannot call it; it is used internally.
	* `State`: `State`. A state object.
	* `...`: varargs. Whatever is passed to [Class:popState](#classpopstate) or [Class:gotoState](#classgotostate) and [Class:popState](#classpopstate).

#### State:pushedState

* `function State:pushedState( ... ) end`
	* This callback is invoked by [Class:pushState](#classpushstate). You can define this function, but cannot call it; it is used internally.
	* `State`: `State`. A state object.
	* `...`: varargs. Whatever is passed to [Class:pushState](#classpushstate).

#### State:poppedState

* `function State:poppedState( ... ) end`
	* This callback is invoked by [Class:popState](#classpopstate) (which itself is invoked by [Class:gotoState](#classgotostate) and [Class:popAllStates](#classpopallstates)) . You can define this function, but cannot call it; it is used internally.
	* `State`: `State`. A state object.
	* `...`: varargs. Whatever is passed to [Class:popState](#classpopstate) and [Class:popAllStates](#classpopallstates).

#### State:pausedState

* `function State:pausedState( ... ) end`
	* This callback is invoked by [Class:pushstate](#classpushstate). You can define this function, but cannot call it; it is used internally.
	* `State`: `State`. A state object.
	* `...`: varargs. Whatever is passed to [Class:pushState](#classpushstate).

#### State:continuedState

* `function State:continuedState( ... ) end`
	* This callback is invoked by [Class:popState](#classpopstate) (which itself is invoked by [Class:gotoState](#classgotostate) and [Class:popAllStates](#classpopallstates)). You can define this function, but cannot call it; it is used internally.
	* `State`: `State`. A state object.
	* `...`: varargs. Whatever is passed to [Class:popState](#classpopstate) or [Class:gotoState](#classgotostate) and [Class:popState](#classpopstate).

### Class:gotoState

* `Class:gotoState( State, ... )`
	* [Flushes](#classpopallstates) the current state stack and sets the state.
	* `State`: `nil`, string, `State`.
		* `nil`: Go to the default of the class, with no state set.
		* string: Go to the state of that name.
		* `State`: Go to that state object.
	* `...`: variables. Data top be passed to any of the other `Class` functions.

### Class:pushState

* `Class:pushState( State, ... )`
	* Pushes a new state to the stack.
	* `State`: string, `State`.
		* string: Push the state by that particular name to the stack.
		* `State`: Push that state to the stack.
	* `...`: variables. Data top be passed to any of the other `Class` functions.

### Class:popState

* `Class:popState( State, ... )`
	* Pops a specific state from the stack.
	* `State`: `nil`, string, `State`.
		* `nil`: Pop the last state in the stack.
		* string: Pop the last state in the stack with that particular name.
		* `State`: Pop the last occurrence of that state in the stack.
	* `...`: variables. Data top be passed to any of the other `Class` functions.

### Class:popAllStates

* `Class:popAllStates( ... )`
	* Flushes the state stack, [popping](#classpopstate) each class in order as it does so.
	* `...`: variables. Data top be passed to any of the other `Class` functions.

### Class:getStateStackDebugInfo

* `info = Class:getStateStackDebugInfo()`
	* Gets the names of the states in the stack in the order they were pushed.
	* `info`: table. Contains the names of all the states in the order they were pushed.

# Specs

This project uses [telescope] for the specifications. To run, make sure you can run Lua via the command line.
Next, within the spec folder, clone in [telescope], then clone in [classic] inside of the folder holding [telescope].
Copy the files [acceptance_spec.lua](spec/acceptance_spec.lua) and [unit_spec.lua](spec/unit_spec.lua) to that same folder.
Finally, test each file with the command `lua tsc -f <name.lua>`.

I've automated it with the following file (put in the [spec](spec) folder):

```batch
@echo off
cd %~dp0

git clone https://github.com/norman/telescope
copy * telescope
copy ..\stately.lua telescope\stately.lua

pushd telescope

git clone https://github.com/rxi/classic

lua tsc -f acceptance_spec.lua
pause

lua tsc -f unit_spec.lua
pause

popd

rmdir /s /q telescope
```

Alternatively, if you already have [telescope] and [classic] installed in the same directory as stately, the following should work:

```batch
@echo off
pushd %~dp0\..\..\telescope

set p="..\Stately"

copy %p%\spec\"*.lua" > nul
copy %p%\stately.lua > nul
if not exist classic mkdir classic
copy "..\classic\classic.lua" "classic\classic.lua" > nul

for %%f in (%p%\spec\"*lua") do cmd /c "lua -e "package.path = './?.lua;' .. package.path" tsc -f "%%~nxf" & pause"

for %%f in (%p%\spec\*.lua) do del "%%~nxf"
del Stately.lua
rmdir /s /q classic
popd
```

[stateful]: https://github.com/kikito/stateful.lua
[classic]: https://github.com/rxi/classic
[telescope]: https://github.com/norman/telescope
