-- Image generation thread
-- Runs HTTP POST request to backend without blocking main thread
-- Downloads generated images and saves them locally

require("love.timer")
require("love.filesystem")
local json = require("libraries.json")

local IMAGES_DIR = "images"

local function ensureImagesDirectory()
    if not love.filesystem.getInfo(IMAGES_DIR) then
        love.filesystem.createDirectory(IMAGES_DIR)
    end
end

local function generateFilename()
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("%s/image_%d_%d.png", IMAGES_DIR, timestamp, random)
end

local function downloadImage(imageUrl)
    local http = require("socket.http")
    local ltn12 = require("ltn12")

    local responseBody = {}

    local result, statusCode, headers = http.request({
        url = imageUrl,
        method = "GET",
        sink = ltn12.sink.table(responseBody)
    })

    if statusCode == 200 then
        local imageData = table.concat(responseBody)
        return true, imageData
    else
        return false, "Download failed: HTTP " .. tostring(statusCode)
    end
end

local function saveImageLocally(imageData)
    ensureImagesDirectory()

    local filename = generateFilename()
    local success, err = love.filesystem.write(filename, imageData)

    if success then
        return true, filename
    else
        return false, "Failed to save image: " .. tostring(err)
    end
end

local function makeRequest(url, description, question)
    local socket = require("socket")
    local http = require("socket.http")
    local ltn12 = require("ltn12")

    local requestBody = json.encode({
        description = description,
        question = question
    })

    local responseBody = {}

    local result, statusCode, headers = http.request({
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = #requestBody
        },
        source = ltn12.source.string(requestBody),
        sink = ltn12.sink.table(responseBody)
    })

    if statusCode == 200 then
        local responseStr = table.concat(responseBody)
        local response = json.decode(responseStr)
        if response.success and response.imageUrl then
            -- Download the image from URL
            local downloadSuccess, imageData = downloadImage(response.imageUrl)
            if not downloadSuccess then
                return false, imageData -- imageData contains error message
            end

            -- Save image locally
            local saveSuccess, localPath = saveImageLocally(imageData)
            if not saveSuccess then
                return false, localPath -- localPath contains error message
            end

            return true, localPath
        else
            return false, response.error or "Unknown error"
        end
    else
        return false, "HTTP Error: " .. tostring(statusCode)
    end
end

-- Thread communication channels
local requestChannel = love.thread.getChannel("image_request")
local responseChannel = love.thread.getChannel("image_response")

while true do
    -- Wait for request with timeout to allow graceful shutdown
    local request = requestChannel:demand(1)

    if request then
        if request == "quit" then
            break
        end

        if type(request) == "table" then
            local success, data = makeRequest(request.url, request.description, request.question)
            responseChannel:push({
                success = success,
                data = data
            })
        end
    end
end
