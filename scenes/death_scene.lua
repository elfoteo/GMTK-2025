local Scene              = require("engine.scene")
local SceneManager       = require("engine.scene_manager")
local CustomFont         = require("engine.custom_font")
local ParticleSystem     = require("engine.particles.particle_system")

local CANVAS_W, CANVAS_H = 384, 216

---@class DeathScene : Scene
---@field customFont24px CustomFont
---@field customFont16px CustomFont
---@field customFont12px CustomFont
---@field retryButton StyledButton
---@field quitButton StyledButton
---@field particleSystem ParticleSystem
local DeathScene         = setmetatable({}, { __index = Scene })
DeathScene.__index       = DeathScene

function DeathScene.new()
    local self = Scene.new(CANVAS_W, CANVAS_H)
    ---@cast self DeathScene
    setmetatable(self, DeathScene)

    local StyledButton = require("engine.ui.styled_button")

    self.customFont24px = CustomFont.new(
        "assets/font/font8x8_basic_24.fnt",
        "assets/font/font8x8_basic_24.png"
    )
    self.customFont16px = CustomFont.new(
        "assets/font/font8x8_basic_16.fnt",
        "assets/font/font8x8_basic_16.png"
    )
    self.customFont12px = CustomFont.new(
        "assets/font/font8x8_basic_12.fnt",
        "assets/font/font8x8_basic_12.png"
    )

    love.mouse.setVisible(true)

    local button_width = 150
    local button_height = 30
    local button_spacing = 30

    local start_x = (CANVAS_W - button_width) / 2
    local button_y_start = 30 + 24 + 30

    self.particleSystem = ParticleSystem.new()

    self.retryButton = StyledButton.new(
        start_x,
        button_y_start,
        button_width,
        button_height,
        "Retry",
        function()
            SceneManager.gotoScene(require("scenes.main_scene").new())
        end,
        self.customFont12px,
        { 0.6, 0.6, 0.6, 1 }, -- White
        self.particleSystem
    )

    if love.system.getOS() ~= "Web" then
        self.quitButton = StyledButton.new(
            start_x,
            button_y_start + button_height + button_spacing,
            button_width,
            button_height,
            "Rage quit",
            function()
                love.event.quit()
            end,
            self.customFont12px,
            { 0.6, 0, 0, 1 }, -- Red
            self.particleSystem
        )
    end

    return self
end

function DeathScene:load()
    -- All initialization moved to new()
end

function DeathScene:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1) -- Black background

    -- Draw "You died"
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.setFont(self.customFont24px.font)
    local text_width = self.customFont24px.font:getWidth("You died")
    love.graphics.print("You died", (CANVAS_W - text_width) / 2, 30) -- 10 pixels from top

    -- Draw buttons
    self.retryButton:draw()
    if self.quitButton then
        self.quitButton:draw()
    end

    self.particleSystem:draw()

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

function DeathScene:update(dt)
    Scene.update(self, dt)

    local mx, my = love.mouse.getPosition()
    local cx, cy = self:toCanvas(mx, my)

    self.retryButton:update(dt, cx, cy)
    if self.quitButton then
        self.quitButton:update(dt, cx, cy)
    end

    self.particleSystem:update(dt)
end

---Handle key presses.
function DeathScene:keypressed(key)
    if key == "f11" then
        love.window.setFullscreen(
            not love.window.getFullscreen(),
            "desktop"
        )
    end
end

function DeathScene:mousepressed(x, y, button)
    local cx, cy = self:toCanvas(x, y)
    if button == 1 then
        self.retryButton:mousepressed(button)
        if self.quitButton then
            self.quitButton:mousepressed(button)
        end
    end
end

function DeathScene:mousereleased(x, y, button)
    if button == 1 then
        self.retryButton:mousereleased(button)
        if self.quitButton then
            self.quitButton:mousereleased(button)
        end
    end
end

return DeathScene
