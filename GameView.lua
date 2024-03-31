-- Utils
local function convertDirectionToAxes(from, letter)
    local directions = {l = {-1, 0}, u = {0, -1}, r = {1, 0}, d = {0, 1}}
    local delta = directions[letter]
    return {from[1] + delta[1], from[2] + delta[2]}
end

-- Init
local GameModel = require("GameModel")
local gameInstance = GameModel:new()

gameInstance:init()
gameInstance:dump()

-- Game loop
repeat
    io.write("> ")
    local input = io.read()
    local command, x, y, dir = string.match(input, "([m])%s+(%d+)%s+(%d+)%s+([lrud])")

    if command then
        local from = {tonumber(x)+1, tonumber(y)+1} -- lua starts arrays from 1
        gameInstance:move(from, convertDirectionToAxes(from, dir))
        gameInstance:tick()
        gameInstance:dump()
    elseif input == "mix" then
        gameInstance:mix()
        gameInstance:dump()
    elseif not (input == "q") then
        print("Unknown command. Try again")
    end
until input == "q"