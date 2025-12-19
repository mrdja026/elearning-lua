-- Wizard generation thread
-- Runs HTTP requests to backend wizard endpoints without blocking main thread
-- Downloads generated images and saves them locally
-- Communicates progress via channels

require("love.timer")
require("love.filesystem")
local json = require("libraries.json")

local IMAGES_DIR = "images"
local BACKEND_BASE_URL = "http://localhost:3000/api/flow-test"

local function ensureImagesDirectory()
    if not love.filesystem.getInfo(IMAGES_DIR) then
        love.filesystem.createDirectory(IMAGES_DIR)
    end
end

local function generateFilename(prefix)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("%s/wizard_%s_%d_%d.png", IMAGES_DIR, prefix, timestamp, random)
end

local function downloadImage(imageUrl)
    local ltn12 = require("ltn12")
    local responseBody = {}
    local result, statusCode, headers

    if imageUrl:match("^https://") then
        local success, https = pcall(require, "ssl.https")
        if not success then
            return false, "HTTPS not supported (LuaSec not installed)"
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

local function saveImageLocally(imageData, prefix)
    ensureImagesDirectory()
    local filename = generateFilename(prefix)
    local success, err = love.filesystem.write(filename, imageData)

    if success then
        return true, filename
    else
        return false, "Failed to save image: " .. tostring(err)
    end
end

local function makePostRequest(endpoint, body)
    local http = require("socket.http")
    local ltn12 = require("ltn12")

    local url = BACKEND_BASE_URL .. endpoint
    local requestBody = json.encode(body)
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
        local success, response = pcall(json.decode, responseStr)
        if success then
            return true, response
        else
            return false, "Failed to parse JSON response"
        end
    else
        return false, "HTTP Error: " .. tostring(statusCode)
    end
end

local function sendProgress(responseChannel, phase, data)
    local msg = {
        type = "progress",
        phase = phase
    }
    if data then
        for k, v in pairs(data) do
            msg[k] = v
        end
    end
    responseChannel:push(msg)
end

local function sendError(responseChannel, message)
    responseChannel:push({
        type = "error",
        message = message
    })
end

local function sendComplete(responseChannel, story)
    responseChannel:push({
        type = "complete",
        story = story
    })
end

local function runWizardFlow(request, responseChannel)
    local data = request.data

    print("[WizardThread] Starting wizard flow...")
    print("[WizardThread] Topic: " .. (data.topic or "nil"))
    print("[WizardThread] Art Style: " .. (data.artStyle or "nil"))
    print("[WizardThread] Page Count: " .. tostring(data.pageCount))

    -- Step 1: Start session
    sendProgress(responseChannel, "starting")

    local success, response = makePostRequest("/start", {
        topic = data.topic,
        artStyle = data.artStyle,
        targetAge = data.targetAge,
        pageCount = data.pageCount,
        pageHints = data.pageHints
    })

    if not success then
        print("[WizardThread] ERROR: Failed to start session: " .. tostring(response))
        sendError(responseChannel, "Failed to start session: " .. tostring(response))
        return
    end

    if not response.success then
        print("[WizardThread] ERROR: Start session failed: " .. (response.error or "unknown"))
        sendError(responseChannel, response.error or "Failed to start session")
        return
    end

    local sessionId = response.sessionId
    print("[WizardThread] Session started: " .. sessionId)

    -- Step 2: Confirm (enhances prompt)
    sendProgress(responseChannel, "enhancing")

    success, response = makePostRequest("/confirm", {
        sessionId = sessionId,
        answer = "yes"
    })

    if not success then
        sendError(responseChannel, "Failed to confirm: " .. tostring(response))
        return
    end

    if not response.success then
        sendError(responseChannel, response.error or "Failed to confirm")
        return
    end

    local enhancedPrompt = response.prompts and response.prompts.enhanced
    local suggestedCharacter = response.prompts and response.prompts.suggestedCharacter

    sendProgress(responseChannel, "enhancing", {
        character = suggestedCharacter or "Story Character"
    })

    -- Step 3: Generate cover
    sendProgress(responseChannel, "cover")

    success, response = makePostRequest("/generate-cover", {
        sessionId = sessionId,
        answer = "yes"
    })

    if not success then
        sendError(responseChannel, "Failed to generate cover: " .. tostring(response))
        return
    end

    if not response.success then
        sendError(responseChannel, response.error or "Failed to generate cover")
        return
    end

    local coverUrl = response.coverImage and response.coverImage.cloudinaryUrl

    -- Store cover URL (download happens on main thread with HTTPS support)
    local coverImagePath = coverUrl or ""
    print("[WizardThread] Cover URL: " .. (coverUrl or "none"))

    -- Step 4: Generate pages
    sendProgress(responseChannel, "pages", { current = 0, total = data.pageCount })

    success, response = makePostRequest("/generate-pages", {
        sessionId = sessionId,
        answer = "yes"
    })

    if not success then
        sendError(responseChannel, "Failed to generate pages: " .. tostring(response))
        return
    end

    if not response.success then
        sendError(responseChannel, response.error or "Failed to generate pages")
        return
    end

    -- Build story object from response
    local summary = response.summary
    if not summary then
        sendError(responseChannel, "No summary in response")
        return
    end

    -- Build pages with Cloudinary URLs (download happens on main thread)
    local pages = {}

    for i, img in ipairs(summary.images or {}) do
        if img.page ~= "cover" then
            local imageUrl = img.cloudinaryUrl or ""
            print("[WizardThread] Page " .. img.page .. " URL: " .. imageUrl)

            table.insert(pages, {
                id = img.page,
                image_path = imageUrl,  -- Store URL, download on main thread
                image_prompt = img.hint or img.visualMetaphor or img.originalPrompt or "",
                question_text = "What do you see in this picture about " .. (data.topic or "the topic") .. "?",
                hint_text = img.hint or "",
                choice_labels = {"Yes", "No"},
                question_type = "yesno",
                correct_answer_is_yes = true,
                correct_answer = "",
                questions = {}
            })
        end
    end

    -- Build final story object
    local story = {
        title = summary.topic or data.topic or "AI Generated Story",
        topic = summary.topic or data.topic or "",
        general_image_prompt = summary.enhancedStoryPrompt or "",
        cover_image_path = coverImagePath,  -- Cloudinary URL, download on main thread
        pages = pages
    }

    print("[WizardThread] Story built successfully!")
    print("[WizardThread] Title: " .. story.title)
    print("[WizardThread] Cover path: " .. (story.cover_image_path or "none"))
    print("[WizardThread] Pages: " .. #story.pages)

    sendComplete(responseChannel, story)
    print("[WizardThread] Complete message sent to channel")
end

-- Thread communication channels
local requestChannel = love.thread.getChannel("wizard_request")
local responseChannel = love.thread.getChannel("wizard_response")

print("[WizardThread] Thread started, waiting for requests...")

while true do
    -- Wait for request with timeout
    local request = requestChannel:demand(1)

    if request then
        if request == "quit" then
            print("[WizardThread] Quit requested, exiting...")
            break
        end

        if type(request) == "table" and request.action == "generate" then
            print("[WizardThread] Received generate request")
            -- Wrap in pcall to catch any errors
            local ok, err = pcall(function()
                runWizardFlow(request, responseChannel)
            end)
            if not ok then
                print("[WizardThread] FATAL ERROR: " .. tostring(err))
                responseChannel:push({
                    type = "error",
                    message = "Thread error: " .. tostring(err)
                })
            end
        end
    end
end

print("[WizardThread] Thread exiting")
