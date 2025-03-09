-- Polygonization utility functions for LÖVE2D
-- Converted from Python implementation

-- Split an image into segments of specified size
function splitImageIntoSegments(imageData, segmentSize)
    segmentSize = segmentSize or 64
    local segments = {}
    
    -- Get image dimensions
    local width, height = imageData:getDimensions()
    
    -- Calculate number of complete segments
    local rows = math.floor(height / segmentSize)
    local cols = math.floor(width / segmentSize)
    
    -- Extract each segment
    for i = 0, rows-1 do
        for j = 0, cols-1 do
            -- Calculate segment boundaries
            local yStart = i * segmentSize
            local xStart = j * segmentSize
            
            -- Create a new ImageData for the segment
            local segmentData = love.image.newImageData(segmentSize, segmentSize)
            
            -- Copy pixel data from the original image to the segment
            for y = 0, segmentSize-1 do
                for x = 0, segmentSize-1 do
                    if (xStart + x) < width and (yStart + y) < height then
                        local r, g, b, a = imageData:getPixel(xStart + x, yStart + y)
                        segmentData:setPixel(x, y, r, g, b, a)
                    end
                end
            end
            
            -- Add segment data to the list
            table.insert(segments, segmentData)
        end
    end
    
    return segments
end

-- Map RGB color to a specific value
local function colorMap(r, g, b)
    -- LÖVE uses 0-1 color values
    if r < 0.1 and g < 0.1 and b < 0.1 then return 1 end         -- Black
    if r > 0.9 and g > 0.9 and b > 0.9 then return 1 end         -- White
    if r > 0.9 and g < 0.1 and b < 0.1 then return 2 end         -- Red
    if r < 0.1 and g < 0.1 and b > 0.9 then return 3 end         -- Blue
    return -1 -- Default for other colors
end

-- Convert a segment image into rectangles by analyzing runs of similar colors
function extractRectangles(segmentData)
    local width, height = segmentData:getDimensions()
    local lastPixelValue = nil
    local runs = {}
    
    -- For each row, find runs of pixels with the same value
    for y = 0, height-1 do
        local currentRun = {{startX = 0, startY = y, endX = 0, value = nil}}
        for x = 0, width-1 do
            local r, g, b, _ = segmentData:getPixel(x, y)
            local pixelValue = colorMap(r, g, b)
            
            if pixelValue == lastPixelValue or lastPixelValue == nil then
                currentRun[#currentRun].endX = x
                currentRun[#currentRun].value = pixelValue
            else
                table.insert(currentRun, {startX = x, startY = y, endX = x, value = pixelValue})
            end
            
            lastPixelValue = pixelValue
        end
        
        table.insert(runs, currentRun)
        lastPixelValue = nil -- Reset for next row
    end
    
    local activeRectangles = {}
    local finishedRectangles = {}
    
    for y, row in ipairs(runs) do
        y = y - 1 -- Adjust for 1-indexed tables in Lua vs 0-indexed in the algorithm
        
        for _, run in ipairs(row) do
            local new = true
            
            -- Check if run can be added to an active rectangle
            for _, activeRect in ipairs(activeRectangles) do
                if activeRect.value == run.value and 
                   activeRect.endX == run.endX and 
                   activeRect.startX == run.startX and
                   activeRect.endY == y - 1 then
                    activeRect.endY = y
                    new = false
                    break
                end
            end
            
            if new then
                -- Start a new rectangle
                table.insert(activeRectangles, {
                    startX = run.startX,
                    startY = run.startY,
                    endX = run.endX,
                    endY = y,
                    value = run.value
                })
            end
        end
        
        -- Check if any active rectangles are finished
        local remainingRectangles = {}
        for _, activeRect in ipairs(activeRectangles) do
            if activeRect.endY == y - 1 then
                table.insert(finishedRectangles, activeRect)
            else
                table.insert(remainingRectangles, activeRect)
            end
        end
        activeRectangles = remainingRectangles
    end
    
    -- Add any remaining active rectangles
    for _, activeRect in ipairs(activeRectangles) do
        table.insert(finishedRectangles, activeRect)
    end
    
    return finishedRectangles
end

-- Draw rectangles from the extracted data
function drawRectangles(rectangles)
    -- Color map for different values
    local colorMap = {
        [1] = {0, 0, 1, 0.7},     -- Blue
        [2] = {1, 0, 0, 0.7},     -- Red
        [3] = {0, 1, 0, 0.7},     -- Green
        [-1] = {1, 1, 0, 0.7}     -- Yellow
    }
    
    for _, rect in ipairs(rectangles) do
        local x = rect.startX
        local y = rect.startY
        local width = rect.endX - rect.startX + 1
        local height = rect.endY - rect.startY + 1
        
        -- Get color based on value
        local color = colorMap[rect.value] or {0.5, 0, 0.5, 0.7} -- Default purple
        
        -- Draw rectangle outline
        love.graphics.setColor(unpack(color))
        love.graphics.rectangle("line", x, y, width, height)
        
        -- Draw value label in the middle of the rectangle
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(tostring(rect.value), x + width/2 - 5, y + height/2 - 5)
    end
end