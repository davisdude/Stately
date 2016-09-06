-- Run using `lua tsc -f unit_spec.lua`
require 'telescope'
local Class = require 'classic.classic'
local State = require 'stately' ( Class )

context( 'Stately unit spec', function()
	local Enemy
	before( function()
		Enemy = Class:extend()
	end )
	test( 'Creates a new table called "states"', function()
		assert_type( Enemy.states, 'table' )
	end )

	context( 'Parent inheritance', function()
		test( 'The states of the class and the parent class are different', function()
			local SubEnemy = Enemy:extend()
			assert_type( SubEnemy.states, 'table' )
			assert_not_equal( Enemy.states, SubEnemy.states )
		end )
		test( 'Inherits parent\'s states and functions', function()
			local Scary = Enemy:addState( 'Scary' )
			function Scary:speak() return 'boo!' end
			function Scary:fly() return 'like the wind' end

			local Clown = Enemy:extend()
			function Clown.states.Scary.speak() return 'mock, mock' end

			local it = Clown()
			it:gotoState( 'Scary' )

			assert_equal( it:fly(), 'like the wind' )
			assert_equal( it:speak(), 'mock, mock' )
		end )
		test( 'Individual state inheritance', function()
			function Enemy:speak() return 'booboo' end

			local Funny = Enemy:addState( 'Funny' )
			function Funny:laugh() return 'hahaha' end

			local VeryFunny = Enemy:addState( 'VeryFunny', Funny )
			function VeryFunny:laughMore() return 'hehehe' end

			local albert = Enemy()
			albert:gotoState( 'VeryFunny' )
			assert_equal( albert:speak(), 'booboo' )
			assert_equal( albert:laugh(), 'hahaha' )
			assert_equal( albert:laughMore(), 'hehehe' )
		end )
	end )

	context( ':addState', function()
		test( 'Creates a new entry in class.states when given a valid name', function()
			Enemy:addState( 'State' )
			assert_type( Enemy.states['State'], 'table' )
		end )
		test( 'Errors when duplicate state names are given', function()
			Enemy:addState( 'State' )
			assert_error( function() Enemy:addState( 'State' ) end )
		end )
		test( 'Errors when non-string names are given', function()
			assert_error( function() Enemy:addState( 1 ) end )
			assert_error( function() Enemy:addState() end )
		end )
		test( 'State callbacks are not a part of a class', function()
			Enemy:addState( 'State' )
			local e = Enemy()
			e:gotoState( 'State' )
			assert_nil( e.enterState )
			assert_nil( e.exitState )
		end )
	end )

	context( '`:gotoState`', function()
		context( 'Given a valid state name', function()
			test( 'The class will use the state\'s functions instead of its own', function()
				function Enemy:foo() return 'foo' end
				local SayBar = Enemy:addState( 'SayBar' )
				function SayBar:foo() return 'bar' end

				local e = Enemy()
				assert_equal( e:foo(), 'foo' )
				e:gotoState( 'SayBar' )
				assert_equal( e:foo(), 'bar' )
			end )
			test( 'Calls the `:enteredState` callback', function()
				local Marked = Enemy:addState( 'Marked' )
				function Marked:enteredState() self.mark = true end

				e = Enemy()
				assert_nil( e.mark )
				e:gotoState( 'Marked' )
				assert_true( e.mark )
			end )
			test( 'Passes all additional arguments to `:enteredState` and `:exitedState`', function()
				local State1 = Enemy:addState( 'State1' )
				local State2 = Enemy:addState( 'State2' )

				State1.exitedState = function( self, x ) assert_equal( x, 'foobar' ) end
				State2.enteredState = function( self, x ) assert_equal( x, 'foobar' ) end

				local e = Enemy()
				e:gotoState( 'State1' )
				e:gotoState( 'State2', 'foobar' )
			end )
			context( 'Accepts state objects', function()
				test( 'Basic Case', function()
					local State = Enemy:addState( 'ReallyLongName' )
					function State:foo() return 'foo' end

					local e = Enemy()
					e:gotoState( State )
					assert_equal( e:foo(), 'foo' )
				end )
				test( 'Accepts only valid table structures', function()
					local e = Enemy()
					assert_error( function() e:gotoState( { continuedState = true } ) end )
					assert_error( function()
						e:gotoState( { enteredState = 0, exitedState = 0, pushedState = 0, poppedState = 0, continuedState = 0, pausedState = 0 } )
					end )
				end )
			end )

			context( 'When there are multiple states in the stack', function()
				test( '`:exitedState` is called in all the stacked states', function()
					local counter = 0
					local function count() counter = counter + 1 end

					local Jumping = Enemy:addState( 'Jumping' )
					local Firing = Enemy:addState( 'Firing' )
					local Shouting = Enemy:addState( 'Shouting' )

					Jumping.exitedState = count
					Firing.exitedState = count

					local e = Enemy()
					e:pushState( 'Jumping' )
					e:pushState( 'Firing' )

					e:gotoState( 'Shouting' )
					assert_equal( counter, 2 )
				end )
			end )
		end )

		test( 'Errors when given an invalid id', function()
			local e = Enemy()
			assert_error( function() e:gotoState( 1 ) end )
			assert_error( function() e:gotoState( {} ) end )
			assert_error( function() e:gotoState( 'Inexisting' ) end )
		end )
	end )

	context( 'State stacking', function()
		local Piled, New, e
		before( function()
			function Enemy:foo() return 'foo' end

			Piled = Enemy:addState( 'Piled' )
			function Piled:foo() return 'foo2' end
			function Piled:bar() return 'bar' end

			New = Enemy:addState( 'New' )
			function New:bar() return 'new bar' end

			e = Enemy()
			e:gotoState( 'Piled' )
		end )

		context( '`:pushState`', function()
			test( 'Uses the most recently pushed state before the others', function()
				e:pushState( 'New' )
				assert_equal( e:bar(), 'new bar' )
			end )
			test( 'Goes through the stack if the top state doesn\'t have the method', function()
				e:pushState( 'New' )
				assert_equal( e:foo(), 'foo2' )
			end )
			test( 'Calls the `:pushedState` callback', function()
				function New:pushedState() self.mark = true end
				e:pushState( 'New' )
				assert_true( e.mark )
			end )
			test( 'Calls the `:enteredState` callback', function()
				function New:enteredState() self.mark = true end
				e:pushState( 'New' )
				assert_true( e.mark )
			end )
			test( 'Does not call the `:exitedState` callback', function()
				function Piled:exitedState() self.mark = true end
				e:pushState( 'New' )
				assert_nil( e.mark )
			end )
			test( 'Calls the `:pausedState` callback', function()
				function Piled:pausedState() self.mark = true end
				e:pushState( 'New' )
				assert_true( e.mark )
			end )

			context( 'Accepts state objects', function()
				test( 'Basic Case', function()
					local State = Enemy:addState( 'ReallyLongName' )
					function State:foo() return 'foo' end

					local e = Enemy()
					e:pushState( State )
					assert_equal( e:foo(), 'foo' )
				end )
				test( 'Accepts only valid table structures', function()
					local e = Enemy()
					assert_error( function() e:gotoState( { continuedState = true } ) end )
					assert_error( function()
						e:pushState( { enteredState = 0, exitedState = 0, pushedState = 0, poppedState = 0, continuedState = 0, pausedState = 0 } )
					end )
				end )
			end )
		end )

		context( '`:popAllStates`', function()
			test( 'Makes the object stateless', function()
				e:pushState( 'New' )
				e:popAllStates()
				assert_equal( e:foo(), 'foo' )
			end )

			test( 'Callbacks are invoked in the right order', function()
				local tab = {}
				function Piled:poppedState() table.insert( tab, 'pile popped' ) end
				function New:exitedState() table.insert( tab, 'new exited' ) end

				e:pushState( 'New' )
				e:popAllStates()

				assert_equal( tab[1], 'new exited' )
				assert_equal( tab[2], 'pile popped' )
			end )
		end )

		context( '`:popState`', function()
			context( 'Given a valid state name', function()
				test( 'Pops a state given a name', function()
					e:pushState( 'New' )
					e:popState( 'Piled' )
					assert_equal( e:foo(), 'foo' )
					assert_equal( e:bar(), 'new bar' )
				end )
				test( 'Calls `:poppedState` on the popped state', function()
					function Piled:poppedState() self.popped = true end
					e:pushState( 'New' )
					e:popState( 'Piled' )
					assert_true( e.popped )
				end )
				test( 'Calls `:exitState` on the state once removed from the pile', function()
					function Piled:exitedState() self.exited = true end
					e:pushState( 'New' )
					e:popState( 'Piled' )
					assert_true( e.exited )
				end )

				context( 'Accepts state objects', function()
					test( 'Basic Case', function()
						local State = Enemy:addState( 'ReallyLongName' )
						function State:poppedState() self.popped = true end

						local e = Enemy()
						e:pushState( 'ReallyLongName' )
						e:popState( State )
						assert_true( e.popped )
					end )
					test( 'Accepts only valid table structures', function()
						local e = Enemy()
						assert_error( function() e:popState( { continuedState = true } ) end )
						assert_error( function()
							e:popState( { enteredState = 0, exitedState = 0, pushedState = 0, poppedState = 0, continuedState = 0, pausedState = 0 } )
						end )
					end )
				end )
			end )

			context( 'Given `nil`', function()
				test( 'Pops the top state', function()
					e:pushState( 'New' )
					e:popState()
					assert_equal( e:foo(), 'foo2' )
					assert_equal( e:bar(), 'bar' )
				end )
				test( 'Calls `:poppedState` on the state', function()
					function Piled:poppedState() self.popped = true end
					e:popState()
					assert_true( e.popped )
				end )
				test( 'Calls `:exitedState` on the state', function()
					function Piled:continuedState() self.continued = true end
					e:pushState( 'New' )
					e:popState()
					assert_true( e.continued )
				end )
				test( 'Errors is input is invalid', function()
					e:popState()
					assert_error( function() e:popState( 'Inexisting' ) end )
				end)
			end )
		end )
	end )

	context( '`:getStateStackDebugInfo`', function()
		test( 'The table is empty when no state is set', function()
			local e = Enemy()
			local info = e:getStateStackDebugInfo()
			assert_equal( #info, 0 )
		end )
		test( 'Returns the names of the current states', function()
			local State1 = Enemy:addState( 'State1' )
			local State2 = Enemy:addState( 'State2' )
			local e = Enemy()

			e:gotoState( 'State1' )
			e:pushState( 'State2' )

			local info = e:getStateStackDebugInfo()
			assert_equal( #info, 2 )
			assert_equal( info[1], 'State1' )
			assert_equal( info[2], 'State2' )
		end )
	end )
end )
