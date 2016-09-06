-- Run using `lua tsc -f acceptance_spec.lua`
require 'telescope'
local Class = require 'classic.classic'
local State = require 'stately' ( Class )

context( 'Stately acceptance spec', function()
	local Enemy
	before( function()
		Enemy = Class:extend()

		function Enemy:new( health )
			self.health = health
		end

		function Enemy:speak()
			return 'My health is ' .. tostring( self.health )
		end
	end )

	test( 'Basic case', function()
		local Immortal = Enemy:addState( 'Immortal' )
		function Immortal:speak() return 'I am UNBREAKABLE!!' end
		function Immortal:die() return 'I cannot die now!' end

		local peter = Enemy( 10 )

		assert_equal( peter:speak(), 'My health is 10' )

		peter:gotoState( 'Immortal' )
		assert_equal( peter:speak(), 'I am UNBREAKABLE!!' )
		assert_equal( peter:die(), 'I cannot die now!' )

		peter:gotoState()
		assert_equal( peter:speak(), 'My health is 10' )
	end )
	test( 'Basic callbacks', function()
		local Drunk = Enemy:addState( 'Drunk' )
		function Drunk:enteredState() self.health = self.health - 1 end
		function Drunk:exitedState() self.health = self.health + 1 end

		local john = Enemy( 10 )
		assert_equal( john:speak(), 'My health is 10' )

		john:gotoState( 'Drunk' )
		assert_equal( john:speak(), 'My health is 9' )
		assert_nil( john.enteredState )
		assert_nil( john.exitedState )

		john:gotoState()
		assert_equal( john:speak(), 'My health is 10' )
	end )
	test( 'Inheritance', function()
		function Enemy:sing() return 'dadadada' end
		function Enemy:singMore() return 'lalalala' end

		local Happy = Enemy:addState( 'Happy' )
		function Happy:speak() return 'hehehe' end

		local Stalker = Enemy:extend()
		function Stalker.states.Happy:sing() return 'I\'ll be watching you' end

		local VeryHappy = Stalker:addState( 'VeryHappy', Happy )
		function VeryHappy:sing() return 'hehey' end

		local jimmy = Stalker( 10 )
		assert_equal( jimmy:speak(), 'My health is 10' )
		assert_equal( jimmy:sing(), 'dadadada' )
		jimmy:gotoState( 'Happy' )
		assert_equal( jimmy:sing(), 'I\'ll be watching you' )
		assert_equal( jimmy:singMore(), 'lalalala' )
		assert_equal( jimmy:speak(), 'hehehe' )
		jimmy:gotoState( 'VeryHappy' )
		assert_equal( jimmy:sing(), 'hehey' )
		assert_equal( jimmy:singMore(), 'lalalala' )
		assert_equal( jimmy:speak(), 'hehehe' )
	end )

	test( 'Stacking', function()
		function Enemy:dance() return 'up down left right' end
		function Enemy:sing() return 'la donna e mobile' end
		function Enemy:all() return table.concat( { self:dance(), self:sing(), self:speak() }, ' - ' ) end

		local StevieWonder = Enemy:addState( 'StevieWonder' )
		function StevieWonder:sing() return 'you are the sunshine of my life' end

		local FredAstaire = Enemy:addState( 'FredAstaire' )
		function FredAstaire:dance() return 'clap clap clappity clap' end

		local PhilCollins = Enemy:addState( 'PhilCollins' )
		function PhilCollins:dance() return 'I can\'t dance' end
		function PhilCollins:sing() return 'I can\'t sing' end
		function PhilCollins:speak() return 'Only thing about me is the way I walk' end

		local artist = Enemy( 10 )
		assert_equal( artist:all(), 'up down left right - la donna e mobile - My health is 10' )
		
		artist:gotoState( 'PhilCollins' )
		assert_equal( artist:all(), 'I can\'t dance - I can\'t sing - Only thing about me is the way I walk' )

		artist:pushState( 'FredAstaire' )
		assert_equal( artist:all(), 'clap clap clappity clap - I can\'t sing - Only thing about me is the way I walk' )

		artist:pushState( 'StevieWonder' )
		assert_equal( artist:all(), 'clap clap clappity clap - you are the sunshine of my life - Only thing about me is the way I walk' )

		artist:popAllStates()
		assert_equal( artist:all(), 'up down left right - la donna e mobile - My health is 10' )

		artist:pushState( 'PhilCollins' )
		artist:pushState( 'FredAstaire' )
		artist:pushState( 'StevieWonder' )
		artist:popState( 'FredAstaire' )
		assert_equal( artist:all(), 'I can\'t dance - you are the sunshine of my life - Only thing about me is the way I walk' )

		artist:popState()
		assert_equal( artist:all(), 'I can\'t dance - I can\'t sing - Only thing about me is the way I walk' )

		artist:popState( 'FredAstaire' )
		assert_equal( artist:all(), 'I can\'t dance - I can\'t sing - Only thing about me is the way I walk' )

		artist:gotoState( 'FredAstaire' )
		assert_equal( artist:all(), 'clap clap clappity clap - la donna e mobile - My health is 10' )
	end )

	test( 'Stack-related callbacks', function()
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
		assert_nil( e.tweet )
		e:pushState( 'TootContinued' )
		assert_true( e.tweet )

		e:pushState( 'PopPopped' )
		e:popState()
		assert_true( e.tweet )
		assert_true( e.pop )

		e:pushState( 'PopPopped' )
		e:pushState( 'PamPushed' )
		assert_true( e.pam )

		e.toot = false
		e.pop = false
		
		e:popState( 'PopPopped' )
		assert_true( e.pop )

		e:popState()
		assert_true( e.toot )

		e:pushState( 'QuackExited' )
		e:pushState( 'MooEntered' )
		assert_true( e.moo )
		assert_nil( e.quack )

		e.quack = false
		e:popState( 'QuackExited' )
		assert_true( e.quack )

		e = Enemy()
		e:pushState( 'PopPopped' )
		e:pushState( 'QuackExited' )
		e:popAllStates()
		assert_true( e.pop )
		assert_true( e.quack )
	end )

	test( 'Debug', function()
		local State1 = Enemy:addState( 'State1' )
		local State2 = Enemy:addState( 'State2' )

		local e = Enemy()
		local info = e:getStateStackDebugInfo()
		assert_equal( #info, 0 )

		e:pushState( 'State1' )
		info = e:getStateStackDebugInfo()
		assert_equal( #info, 1 )
		assert_equal( info[1], 'State1' )

		e:pushState( 'State2' )
		info = e:getStateStackDebugInfo()
		assert_equal( #info, 2 )
		assert_equal( info[1], 'State1' )
		assert_equal( info[2], 'State2' )
	end )

	context( 'Errors', function()
		test( '`:addState` errors if the state is already present or if not valid', function()
			local Immortal = Enemy:addState( 'Immortal' )
			assert_error( function() Enemy:addState( 'Immortal' ) end )
			assert_error( function() Enemy:addState( 1 ) end )
			assert_error( function() Enemy:addState() end )
		end )
		test( '`:gotoState` errors if the id is invalid', function()
			local e = Enemy()
			assert_error( function() e:gotoState( 'Inexisting' ) end )
			assert_error( function() e:gotoState( 1 ) end )
			assert_error( function() e:gotoState( {} ) end )
		end )
		test( '`:popState` errors if the id is invalid', function()
			local e = Enemy()
			assert_error( function() e:popState( 'Inexisting' ) end )
		end )
		test( '`:pushState` errors if the id is invalide', function()
			local e = Enemy()
			assert_error( function() e:pushState( 'Inexisting' ) end )
		end )
	end )
end )
