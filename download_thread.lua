-- Download thread
-- Downloads images from URLs and saves them to the SOURCE directory (not LÖVE save dir)

require("love.timer")

local IMAGES_DIR = "images"

local function ensureImagesDirectory(sourceDir)
    local imagesPath = sourceDir .. "/" .. IMAGES_DIR
    -- Use os.execute to create directory (works on Windows and Unix)
    local cmd
    if package.config:sub(1,1) == '\\' then
        -- Windows
        cmd = 'mkdir "' .. imagesPath .. '" 2>nul'
    else
        -- Unix
        cmd = 'mkdir -p "' .. imagesPath .. '" 2>/dev/null'
    end
    os.execute(cmd)
    return imagesPath
end

local function generateFilename(prefix)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("%s_%d_%d.png", prefix or "downloaded", timestamp, random)
end

-- Download using curl (works for both HTTP and HTTPS without LuaSec)
local function downloadWithCurl(imageUrl, tempFile)
    -- Use curl to download to a temp file
    local cmd
    if package.config:sub(1,1) == '\\' then
        -- Windows
        cmd = string.format('curl -sL -o "%s" "%s"', tempFile, imageUrl)
    else
        -- Unix
        cmd = string.format("curl -sL -o '%s' '%s'", tempFile, imageUrl)
    end

    print("[DownloadThread] Running: " .. cmd)
    local result = os.execute(cmd)

    if result == 0 or result == true then
        -- Read the downloaded file
        local file = io.open(tempFile, "rb")
        if file then
            local data = file:read("*a")
            file:close()
            os.remove(tempFile)
            if data and #data > 0 then
                return true, data
            else
                return false, "Downloaded file is empty"
            end
        else
            return false, "Failed to read downloaded file"
        end
    else
        return false, "curl failed with exit code: " .. tostring(result)
    end
end

local function downloadImage(imageUrl)
    print("[DownloadThread] Downloading: " .. imageUrl)

    -- For HTTPS, try LuaSec first, then fall back to curl
    if imageUrl:match("^https://") then
        -- Try LuaSec first
        local success, https = pcall(require, "ssl.https")
        if success then
            local ltn12 = require("ltn12")
            local responseBody = {}
            local result, statusCode, headers = https.request({
                url = imageUrl,
                method = "GET",
                sink = ltn12.sink.table(responseBody),
                protocol = "any"
            })
            if statusCode == 200 then
                local imageData = table.concat(responseBody)
                print("[DownloadThread] Downloaded " .. #imageData .. " bytes (LuaSec)")
                return true, imageData
            end
        end

        -- Fall back to curl for HTTPS
        print("[DownloadThread] LuaSec not available, using curl...")
        local tempFile = os.tmpname()
        return downloadWithCurl(imageUrl, tempFile)
    else
        -- HTTP - use socket.http
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
            print("[DownloadThread] Downloaded " .. #imageData .. " bytes (socket.http)")
            return true, imageData
        else
            -- Fall back to curl for HTTP too (in case of redirects)
            print("[DownloadThread] HTTP failed, trying curl...")
            local tempFile = os.tmpname()
            return downloadWithCurl(imageUrl, tempFile)
        end
    end
end

local function saveImageLocally(imageData, sourceDir, prefix)
    local imagesPath = ensureImagesDirectory(sourceDir)
    local filename = generateFilename(prefix)
    local fullPath = imagesPath .. "/" .. filename
    local relativePath = IMAGES_DIR .. "/" .. filename

    print("[DownloadThread] Saving to: " .. fullPath)

    -- Use native Lua io to write to source directory
    local file, err = io.open(fullPath, "wb")
    if file then
        file:write(imageData)
        file:close()
        print("[DownloadThread] Saved successfully: " .. relativePath)
        return true, relativePath
    else
        print("[DownloadThread] ERROR: Failed to save: " .. tostring(err))
        return false, "Failed to save image: " .. tostring(err)
    end
end

-- Thread communication channels
local requestChannel = love.thread.getChannel("download_request")
local responseChannel = love.thread.getChannel("download_response")

print("[DownloadThread] Thread started, waiting for requests...")

while true do
    -- Wait for request with timeout
    local request = requestChannel:demand(1)

    if request then
        if request == "quit" then
            print("[DownloadThread] Quit requested")
            break
        end

        if type(request) == "table" and request.url then
            print("[DownloadThread] Processing request for: " .. request.url)
            local downloadSuccess, imageData = downloadImage(request.url)

            if downloadSuccess then
                local prefix = request.targetField == "cover" and "cover" or ("page" .. tostring(request.targetField))
                local saveSuccess, localPath = saveImageLocally(imageData, request.sourceDir, prefix)
                if saveSuccess then
                    responseChannel:push({
                        success = true,
                        originalUrl = request.url,
                        targetField = request.targetField,
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

print("[DownloadThread] Thread exiting")
