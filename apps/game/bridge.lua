-- bridge.lua
-- PostMessage bridge for Love.js/React communication
-- Falls back to native HTTP for local development

local bridge = {}
local json = require("libraries.json")

-- Track pending requests
local pendingRequests = {}
local requestCounter = 0

-- Detect if running in web mode
local isWeb = love.system.getOS() == "Web"

-- Native HTTP configuration
local BACKEND_URL = "http://localhost:3001"

---Generate a unique request ID
---@return string
local function generateRequestId()
    requestCounter = requestCounter + 1
    return "req_" .. os.time() .. "_" .. requestCounter
end

---Initialize the bridge (call from main.lua)
function bridge.init()
    if isWeb then
        -- Setup global for receiving messages from React
        -- Love.js injects this via custom JavaScript
        _G.onReactMessage = function(jsonStr)
            local success, message = pcall(json.decode, jsonStr)
            if success and message then
                bridge.handleMessage(message)
            end
        end

        print("[bridge] Initialized in web mode")
    else
        print("[bridge] Initialized in native mode (HTTP fallback)")
    end
end

---Send a message to React (only works in web mode)
---@param message table
local function postToReact(message)
    if isWeb and _G.postToReact then
        local jsonStr = json.encode(message)
        _G.postToReact(jsonStr)
    end
end

---Handle incoming message from React
---@param message table
function bridge.handleMessage(message)
    if not message or not message.requestId then
        print("[bridge] Invalid message received")
        return
    end

    local pending = pendingRequests[message.requestId]
    if not pending then
        print("[bridge] No pending request for ID: " .. message.requestId)
        return
    end

    -- Remove from pending
    pendingRequests[message.requestId] = nil

    -- Call the callback
    if message.success then
        pending.callback(message.payload, nil)
    else
        pending.callback(nil, message.error or "Unknown error")
    end
end

---Request image generation via React/backend
---@param params table {description: string, question: string}
---@param callback function(result, error)
function bridge.requestImageGeneration(params, callback)
    local requestId = generateRequestId()

    if isWeb then
        -- Store pending request
        pendingRequests[requestId] = {
            type = "GENERATE_IMAGE",
            callback = callback
        }

        -- Send to React
        postToReact({
            type = "GENERATE_IMAGE",
            requestId = requestId,
            payload = params
        })
    else
        -- Native mode: use HTTP directly
        bridge.nativeImageGeneration(params, callback)
    end
end

---Native HTTP fallback for image generation
---@param params table
---@param callback function
function bridge.nativeImageGeneration(params, callback)
    local http = require("socket.http")
    local ltn12 = require("ltn12")

    local requestBody = json.encode({
        description = params.description,
        question = params.question
    })

    local responseBody = {}
    local result, code, headers = http.request({
        url = BACKEND_URL .. "/api/generate-image",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = #requestBody
        },
        source = ltn12.source.string(requestBody),
        sink = ltn12.sink.table(responseBody)
    })

    if code == 200 then
        local success, response = pcall(json.decode, table.concat(responseBody))
        if success then
            callback(response, nil)
        else
            callback(nil, "Failed to parse response")
        end
    else
        callback(nil, "HTTP error: " .. tostring(code))
    end
end

---Save a story file
---@param filename string
---@param data string
---@param callback function(success, error)
function bridge.saveStory(filename, data, callback)
    local requestId = generateRequestId()

    if isWeb then
        pendingRequests[requestId] = {
            type = "SAVE_STORY",
            callback = callback
        }

        postToReact({
            type = "SAVE_STORY",
            requestId = requestId,
            payload = {
                filename = filename,
                data = data
            }
        })
    else
        -- Native mode: use love.filesystem
        local success = love.filesystem.write(filename, data)
        if success then
            callback(true, nil)
        else
            callback(false, "Failed to write file")
        end
    end
end

---Load a story file
---@param filename string
---@param callback function(data, error)
function bridge.loadStory(filename, callback)
    local requestId = generateRequestId()

    if isWeb then
        pendingRequests[requestId] = {
            type = "LOAD_STORY",
            callback = callback
        }

        postToReact({
            type = "LOAD_STORY",
            requestId = requestId,
            payload = {
                filename = filename
            }
        })
    else
        -- Native mode: use love.filesystem
        local data, error = love.filesystem.read(filename)
        if data then
            callback(data, nil)
        else
            callback(nil, error or "Failed to read file")
        end
    end
end

---List story files
---@param callback function(files, error)
function bridge.listStories(callback)
    local requestId = generateRequestId()

    if isWeb then
        pendingRequests[requestId] = {
            type = "LIST_STORIES",
            callback = callback
        }

        postToReact({
            type = "LIST_STORIES",
            requestId = requestId,
            payload = {}
        })
    else
        -- Native mode: use love.filesystem
        local files = love.filesystem.getDirectoryItems("stories")
        local stories = {}
        for _, file in ipairs(files) do
            if file:match("%.json$") then
                table.insert(stories, file)
            end
        end
        callback(stories, nil)
    end
end

return bridge
