function love.conf(t)
    t.identity = "logictales"
    t.version = "11.4"
    t.console = true

    -- Window configuration (1280x720 virtual resolution)
    t.window.title = "LogicTales"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 640
    t.window.minheight = 360
    t.window.vsync = 1

    -- Disabled modules
    t.modules.audio = false
    t.modules.physics = false
    t.modules.video = false

    -- Enabled for controller support
    t.modules.joystick = true

    -- Keyboard settings
    t.keyboard = {}
    t.keyboard.keyrepeat = true
end
