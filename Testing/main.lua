Object = require 'classic'
stately = require 'stately'

local tests = 0
function isEqual( a, b )
    tests = tests + 1
    return assert( a == b, 'Error, failed test ' .. tests .. ': "' .. tostring( a ) .. '" vs "' .. tostring( b ) .. '".' )
end

require 'acceptance_spec'

function love.keyreleased( key )
    if key == 'escape' then love.event.quit() end
end
