-- Download thread
-- Downloads images from URLs and saves them locally

require("love.timer")
require("love.filesystem")

local IMAGES_DIR = "images"

local function ensureImagesDirectory()
    if not love.filesystem.getInfo(IMAGES_DIR) then
        love.filesystem.createDirectory(IMAGES_DIR)
    end
end

local function generateFilename(url)
    -- Extract a meaningful name from the URL or generate one
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("%s/downloaded_%d_%d.png", IMAGES_DIR, timestamp, random)
end

local function downloadImage(imageUrl)
    local ltn12 = require("ltn12")
    local responseBody = {}
    local result, statusCode, headers

    if imageUrl:match("^https://") then
        -- Try to load HTTPS support
        local success, https = pcall(require, "ssl.https")
        if not success then
            return false, "HTTPS not supported (LuaSec not installed). Install luasec or use HTTP URLs."
        end
        result, statusCode, headers = https.request({
            url = imageUrl,
            method = "GET",
            sink = ltn12.sink.table(responseBody),
            protocol = "any"
        })
    else
        local http = require("socket.http")
        result, statusCode, headers = http.request({
            url = imageUrl,
            method = "GET",
            sink = ltn12.sink.table(responseBody)
        })
    end

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

-- Thread communication channels
local requestChannel = love.thread.getChannel("download_request")
local responseChannel = love.thread.getChannel("download_response")

while true do
    -- Wait for request with timeout
    local request = requestChannel:demand(1)

    if request then
        if request == "quit" then
            break
        end

        if type(request) == "table" and request.url then
            local downloadSuccess, imageData = downloadImage(request.url)

            if downloadSuccess then
                local saveSuccess, localPath = saveImageLocally(imageData)
                if saveSuccess then
                    responseChannel:push({
                        success = true,
                        originalUrl = request.url,
                        targetField = request.targetField,  -- "cover" or page index
                        localPath = localPath
                    })
                else
                    responseChannel:push({
                        success = false,
                        originalUrl = request.url,
                        targetField = request.targetField,
                        error = localPath
                    })
                end
            else
                responseChannel:push({
                    success = false,
                    originalUrl = request.url,
                    targetField = request.targetField,
                    error = imageData
                })
            end
        end
    end
end
