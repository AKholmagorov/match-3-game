local GameModel = {}
GameModel.__index = GameModel

function GameModel:new()
    self.gameField = {}
    self.moveFrom = { 0, 0 }
    self.moveTo = { 0, 0 }

    return self
end

math.randomseed(os.time())
local emptinessSign = '*'
local gameFieldSize = 10

local function getRandomLetter()
    -- ASCII: 65 - A, 66 - B ...
    return string.char(math.random(1, 6) + 64)
end

local function hasFieldCompleteCombinations(field)
    for i = 1, #field do
        local overlaps = 0

        for j = 1, #field - 1 do
            if field[i][j] == field[i][j + 1] then
                overlaps = overlaps + 1
            else
                overlaps = 0
            end

            if overlaps == 2 then return true end
        end
    end

    for i = 1, #field[1] do
        local overlaps = 0

        for j = 1, #field - 1 do
            if field[j][i] == field[j + 1][i] then
                overlaps = overlaps + 1
            else
                overlaps = 0
            end

            if overlaps == 2 then return true end
        end
    end

    return false
end

local function isWithinBounds(field, x, y)
    return x >= 1 and x <= #field[1] and y >= 1 and y <= #field
end

local function isMatch(field, x, y, dx, dy)
    return isWithinBounds(field, x + dx, y + dy) and field[y][x] == field[y + dy][x + dx]
end

local function isCellSwappable(field, x, y)
    local directions = {
        -- Diagonal directions
        { { 1, -1 },  { 1, -2 },  { 2, -1 } },
        { { 1, 1 },   { 1, 2 },   { 2, 1 } },
        { { -1, 1 },  { -1, 2 },  { -2, 1 } },
        { { -1, -1 }, { -1, -2 }, { -2, -1 } },
        -- Horizontal and Vertical directions
        { { -2, 0 },  { -3, 0 } },
        { { 0, -2 },  { 0, -3 } },
        { { 2, 0 },   { 3, 0 } },
        { { 0, 2 },   { 0, 3 } }
    }

    -- Check current cell has at least 2 same neighbor on one of the directions,
    -- it means cell can be swapped
    for _, dir in ipairs(directions) do
        local dx, dy = dir[1][1], dir[1][2]
        local checkX1, checkY1 = dir[2][1], dir[2][2]

        if isMatch(field, x, y, dx, dy) then
            if isMatch(field, x, y, checkX1, checkY1) then
                return true
            end

            -- Additional check for diagonal directions
            if #dir == 3 then
                local checkX2, checkY2 = dir[3][1], dir[3][2]
                if isMatch(field, x, y, checkX2, checkY2) then
                    return true
                end
            end
        end
    end

    return false
end

local function isFieldSwappable(field)
    for i = 1, #field do
        for j = 1, #field[1] do
            if isCellSwappable(field, j, i) then
                return true
            end
        end
    end

    return false
end

local function generateField(size)
    local field = {}

    repeat
        for i = 1, size do
            field[i] = {}
            for j = 1, size do
                field[i][j] = getRandomLetter()
            end
        end
    until not hasFieldCompleteCombinations(field) and isFieldSwappable(field)

    return field
end

local function swap(field, from, to)
    if not isWithinBounds(field, from[1], from[2]) or
        not isWithinBounds(field, to[1], to[2]) then
        return false
    end

    local x1, y1 = from[1], from[2]
    local x2, y2 = to[1], to[2]
    local temp = field[y1][x1]

    field[y1][x1] = field[y2][x2]
    field[y2][x2] = temp

    return true
end

local function markCellsAsCleaned(coords, field)
    for _, coord in ipairs(coords) do
        local x, y = coord[1], coord[2]
        field[y][x] = emptinessSign
    end
end

local function getEmptyCellsCoords(field)
    local emptyCellsCoords = {}

    for i = 1, #field do
        for j = 1, #field[1] do
            if field[i][j] == emptinessSign then
                table.insert(emptyCellsCoords, { j, i })
            end
        end
    end

    return emptyCellsCoords
end

local function fillEmptiness(coords, field)
    for _, coord in ipairs(coords) do
        local x, y = coord[1], coord[2]
        field[y][x] = getRandomLetter()
    end
end

local function getEmptyLowestPointsOfColumns(emptyCellsCoords)
    local minYForX = {}

    for _, coord in pairs(emptyCellsCoords) do
        local x, y = coord[1], coord[2]

        if not minYForX[x] or y > minYForX[x] then
            minYForX[x] = y
        end
    end

    return minYForX
end

local function liftUpEmptinessAndGetAffectedCells(emptyCellsCoords, field)
    local affectedCells = {}
    local lowestEmptyPointsOfColumns = getEmptyLowestPointsOfColumns(emptyCellsCoords)

    -- Lift up cells from the lowest empty points
    for x, y in pairs(lowestEmptyPointsOfColumns) do
        local gap = 0
        local dy = y - 1

        while isWithinBounds(field, x, dy) do
            local curPosY = dy + 1

            if field[dy][x] == emptinessSign then
                gap = gap + 1
            else
                local temp = field[dy][x]
                field[dy][x] = emptinessSign
                field[curPosY + gap][x] = temp
                table.insert(affectedCells, { x, curPosY + gap })
            end
            dy = dy - 1
        end
    end

    return affectedCells
end

local function cleanMatchedCells(coords, field)
    local directions = { { 1, 0 }, { 0, 1 } } -- horizontal, vertical
    local coordsForCleaning = {}

    -- Search match of the cells and split them to horizontal or vertical group
    for _, coord in ipairs(coords) do
        local x, y = coord[1], coord[2]
        local groups = {
            { name = "hor_group",  data = {} },
            { name = "vert_group", data = {} }
        }

        for i = 1, #directions do
            local dx, dy = directions[i][1], directions[i][2]
            local group = groups[i].data
            local sideChecked = 0

            while sideChecked < 2 do
                if isWithinBounds(field, x + dx, y + dy) and field[y][x] == field[y + dy][x + dx] then
                    table.insert(group, { x + dx, y + dy })
                    dx = (dx > 0 and dx + 1) or (dx < 0 and dx - 1) or dx
                    dy = (dy > 0 and dy + 1) or (dy < 0 and dy - 1) or dy
                else
                    sideChecked = sideChecked + 1
                    dx, dy = directions[i][1] * -1, directions[i][2] * -1
                end
            end
        end

        -- Save matched cells coordinates to clean them later
        for _, group in ipairs(groups) do
            if #group.data >= 2 then
                for _, subgroup in ipairs(group.data) do
                    table.insert(coordsForCleaning, subgroup)
                end
                table.insert(coordsForCleaning, { x, y })
            end
        end
    end

    -- Clean match cells, lift them up and fill emptiness
    -- Repeat it untill all affected cells stop match
    if #coordsForCleaning > 2 then
        markCellsAsCleaned(coordsForCleaning, field)
        local affectedCoords = liftUpEmptinessAndGetAffectedCells(coordsForCleaning, field)

        if #affectedCoords > 0 then
            cleanMatchedCells(affectedCoords, field)
        else
            local newEmptyCellsCoords = getEmptyCellsCoords(field)
            fillEmptiness(newEmptyCellsCoords, field)
            cleanMatchedCells(newEmptyCellsCoords, field)
        end
    elseif #getEmptyCellsCoords(field) > 0 then
        local newEmptyCellsCoords = getEmptyCellsCoords(field)
        fillEmptiness(newEmptyCellsCoords, field)
        cleanMatchedCells(newEmptyCellsCoords, field)
    end

    -- boolean reflects something was matched
    -- if it didn't then swap must be canceled in called function
    return #coordsForCleaning > 2
end

function GameModel:init()
    self.gameField = generateField(gameFieldSize)
end

function GameModel:dump()
    -- Print underlined X coordinates
    io.write("    \027[4m")
    for i = 1, #self.gameField[1] do
        local outputType = i ~= #self.gameField[1] and i-1 .. " " or i-1
        io.write(outputType)
    end
    print("\027[0m")

    -- Print Y coordinates and cells
    for i = 1, #self.gameField do
        io.write(" "..i-1 .."| ")
        for j = 1, #self.gameField[1] do
            io.write(self.gameField[i][j] .. " ")
        end
        io.write("\n")
    end
    print("\n")
end

function GameModel:move(from, to)
    self.moveFrom = from
    self.moveTo = to
end

function GameModel:tick()
    if not swap(self.gameField, self.moveFrom, self.moveTo) then
        print("Not in bounds.\n")
        return
    end

    -- Unswap changes if nothing was matched
    if not cleanMatchedCells({ self.moveFrom, self.moveTo }, self.gameField) then
        swap(self.gameField, self.moveFrom, self.moveTo)
        print("No match. Changes was unswapped.\n")
        return
    else
        print("Swapped!\n")
        if not isFieldSwappable(self.gameField) then
            self:mix()
        end
    end
end

function GameModel:mix()
    Shuffle2DArray = require("Shuffelling")
    local boxtimer = 0

    repeat
        boxtimer = boxtimer + 1
        self.gameField = Shuffle2DArray(self.gameField)
    until not hasFieldCompleteCombinations(self.gameField) and isFieldSwappable(self.gameField)
          or boxtimer > 200

    if boxtimer < 200 then
        print("No available combinations. Game field has mixed.\n")
    else
        self.gameField = generateField(gameFieldSize)
        print("Game Field couldn't be mixed with available combinations and has regenerated.\n")
    end
end

return GameModel
