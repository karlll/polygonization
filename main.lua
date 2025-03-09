-- Example implementation using the polygonization functions

-- Import the polygonization module
require "polygonization"

local imageData -- Original image data
local segmentImageDatas = {} -- Segment image data objects
local segmentImages = {} -- Segment image objects (for drawing)
local currentSegment = 1
local rectangles = {}

function love.load()
    -- Load the original image data directly
    local success, result = pcall(function()
        return love.image.newImageData("data/collision-tileset.png")
    end)
    
    if success then
        imageData = result
        print("Image loaded successfully: " .. imageData:getWidth() .. "x" .. imageData:getHeight())
        
        -- Split the image into 64x64 segments
        segmentImageDatas = splitImageIntoSegments(imageData, 64)
        
        -- Create Image objects for drawing each segment
        for i, segmentData in ipairs(segmentImageDatas) do
            segmentImages[i] = love.graphics.newImage(segmentData)
        end
        
        -- Extract rectangles from the first segment
        if #segmentImageDatas > 0 then
            rectangles = extractRectangles(segmentImageDatas[currentSegment])
        end
    else
        print("Failed to load image: " .. result)
    end
end

function love.update(dt)
    -- You could add any animation or updates here
end

function love.draw()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    
    if #segmentImages > 0 then
        -- Draw the current segment
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(segmentImages[currentSegment], 50, 50)
        
        -- Draw rectangles on top of the segment
        love.graphics.push()
        love.graphics.translate(50, 50)
        drawRectangles(rectangles)
        love.graphics.pop()
        
        -- Display segment number
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Segment " .. currentSegment .. " of " .. #segmentImages, 50, 20)
        love.graphics.print("Press arrow keys to navigate segments", 50, 550)
    else
        love.graphics.print("No segments found or image failed to load", 50, 50)
    end
end

function love.keypressed(key)
    if key == "right" then
        currentSegment = math.min(currentSegment + 1, #segmentImageDatas)
        if segmentImageDatas[currentSegment] then
            rectangles = extractRectangles(segmentImageDatas[currentSegment])
        end
    elseif key == "left" then
        currentSegment = math.max(currentSegment - 1, 1)
        if segmentImageDatas[currentSegment] then
            rectangles = extractRectangles(segmentImageDatas[currentSegment])
        end
    elseif key == "escape" then
        love.event.quit()
    end
end