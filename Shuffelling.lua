math.randomseed(os.time())

local function fisherYatesShuffle(arr)
    local count = #arr
    for i = count, 2, -1 do
        local j = math.random(i)
        arr[i], arr[j] = arr[j], arr[i]
    end
end

local function flatten2DArray(arr2D)
    local flatArr = {}
    for i = 1, #arr2D do
        for j = 1, #arr2D[i] do
            table.insert(flatArr, arr2D[i][j])
        end
    end
    return flatArr
end

local function unflattenTo2DArray(flatArr, rows, cols)
    local arr2D = {}
    local index = 1
    for i = 1, rows do
        arr2D[i] = {}
        for j = 1, cols do
            arr2D[i][j] = flatArr[index]
            index = index + 1
        end
    end
    return arr2D
end

local function Shuffle2DArray(arr2D)
    local flatArr = flatten2DArray(arr2D)
    fisherYatesShuffle(flatArr)
    return unflattenTo2DArray(flatArr, #arr2D, #arr2D[1])
end

return Shuffle2DArray
