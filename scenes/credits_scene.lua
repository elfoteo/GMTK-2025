local Scene = require("engine.scene")
local SceneManager = require("engine.scene_manager")
local CustomFont = require("engine.custom_font")
local StyledButton = require("engine.ui.styled_button")
local ParticleSystem = require("engine.particles.particle_system")

local CANVAS_W, CANVAS_H = 384, 216

---@class CreditsScene : Scene
---@field customFont8px CustomFont
---@field backButton StyledButton
---@field particleSystem ParticleSystem
---@field rainbowShader any
---@field time number
local CreditsScene = setmetatable({}, { __index = Scene })
CreditsScene.__index = CreditsScene

function CreditsScene.new()
    local self = Scene.new(CANVAS_W, CANVAS_H)
    ---@cast self CreditsScene
    setmetatable(self, CreditsScene)

    self.customFont8px = CustomFont.new(
        "assets/font/font8x8_basic_8.fnt",
        "assets/font/font8x8_basic_8.png"
    )

    self.credits = {
        { role = "Coder",      names = { "elfoteo" } },
        { role = "Artist",     names = { "Khaos", "elfomarco" } },
        { role = "Soundtrack", names = { "Khaos" } },
    }

    self.particleSystem = ParticleSystem.new()

    self.backButton = StyledButton.new(
        (CANVAS_W - 100) / 2,
        CANVAS_H - 30,
        100,
        20,
        "Back",
        function()
            -- Because the main menu scene is not passed, this will require a new instance of it
            SceneManager.gotoScene(require("scenes.main_menu_scene").new())
        end,
        self.customFont8px,
        { 0.6, 0.6, 0.6, 1 },
        self.particleSystem
    )

    self.rainbowShader = love.graphics.newShader("engine/shaders/rainbow.glsl")
    self.time = 0

    return self
end

function CreditsScene:update(dt)
    Scene.update(self, dt)
    local mx, my = love.mouse.getPosition()
    local cx, cy = self:toCanvas(mx, my)
    self.backButton:update(dt, cx, cy)
    self.particleSystem:update(dt)
    self.time = self.time + dt
end

function CreditsScene:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1) -- Black background

    love.graphics.setFont(self.customFont8px.font)
    love.graphics.setColor(1, 1, 1, 1) -- White text

    local line_height = self.customFont8px.font:getHeight()
    local y_start = 30
    local current_y = y_start

    for _, credit in ipairs(self.credits) do
        -- Draw role
        local role_text = credit.role
        love.graphics.printf(role_text, 0, current_y, CANVAS_W, "center")
        current_y = current_y + line_height

        -- Draw names with shader
        love.graphics.setShader(self.rainbowShader)
        self.rainbowShader:send("time", self.time)
        for _, name in ipairs(credit.names) do
            love.graphics.printf(name, 0, current_y, CANVAS_W, "center")
            current_y = current_y + line_height
        end
        love.graphics.setShader()
        current_y = current_y + line_height -- Add extra space between roles
    end

    self.backButton:draw()
    self.particleSystem:draw()

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

function CreditsScene:keypressed(key)
    if key == "escape" then
        SceneManager.gotoScene(require("scenes.main_menu_scene").new())
    end
end

function CreditsScene:mousepressed(x, y, button)
    local cx, cy = self:toCanvas(x, y)
    if button == 1 then
        self.backButton:mousepressed(button)
    end
end

function CreditsScene:mousereleased(x, y, button)
    if button == 1 then
        self.backButton:mousereleased(button)
    end
end

return CreditsScene
