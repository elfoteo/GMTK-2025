local Scene = require("engine.scene")
local SceneManager = require("engine.scene_manager")
local CustomFont = require("engine.custom_font")
local StyledButton = require("engine.ui.styled_button")
local ParticleSystem = require("engine.particles.particle_system")

local CANVAS_W, CANVAS_H = 384, 216

---@class MainMenuScene : Scene
---@field customFont16px CustomFont
---@field playButton StyledButton
---@field creditsButton StyledButton
---@field quitButton StyledButton
---@field particleSystem ParticleSystem
local MainMenuScene = setmetatable({}, { __index = Scene })
MainMenuScene.__index = MainMenuScene

function MainMenuScene.new()
    local self = Scene.new(CANVAS_W, CANVAS_H)
    ---@cast self MainMenuScene
    setmetatable(self, MainMenuScene)

    self.customFont16px = CustomFont.new(
        "assets/font/font8x8_basic_16.fnt",
        "assets/font/font8x8_basic_16.png"
    )

    love.mouse.setVisible(true)

    local button_width = 100
    local button_height = 20
    local button_spacing = 25
    local total_height = (button_height * 3) + (button_spacing * 2)
    local start_y = (CANVAS_H - total_height) / 2
    local start_x = (CANVAS_W - button_width) / 2

    self.particleSystem = ParticleSystem.new()

    self.playButton = StyledButton.new(
        start_x,
        start_y,
        button_width,
        button_height,
        "Play",
        function()
            SceneManager.gotoScene(require("scenes.main_scene").new())
        end,
        self.customFont16px,
        { 0.6, 0.6, 0.6, 1 },
        self.particleSystem
    )

    self.creditsButton = StyledButton.new(
        start_x,
        start_y + button_height + button_spacing,
        button_width,
        button_height,
        "Credits",
        function()
            SceneManager.gotoScene(require("scenes.credits_scene").new())
        end,
        self.customFont16px,
        { 0.6, 0.6, 0.6, 1 },
        self.particleSystem
    )

    if love.system.getOS() ~= "Web" then
        self.quitButton = StyledButton.new(
            start_x,
            start_y + (button_height + button_spacing) * 2,
            button_width,
            button_height,
            "Exit",
            function()
                love.event.quit()
            end,
            self.customFont16px,
            { 0.6, 0.6, 0.6, 1 },
            self.particleSystem
        )
    end

    return self
end

function MainMenuScene:update(dt)
    Scene.update(self, dt)
    local mx, my = love.mouse.getPosition()
    local cx, cy = self:toCanvas(mx, my)

    self.playButton:update(dt, cx, cy)
    self.creditsButton:update(dt, cx, cy)
    if self.quitButton then
        self.quitButton:update(dt, cx, cy)
    end
    self.particleSystem:update(dt)
end

function MainMenuScene:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)

    self.playButton:draw()
    self.creditsButton:draw()
    if self.quitButton then
        self.quitButton:draw()
    end

    self.particleSystem:draw()

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

function MainMenuScene:mousepressed(x, y, button)
    local cx, cy = self:toCanvas(x, y)
    if button == 1 then
        self.playButton:mousepressed(button)
        self.creditsButton:mousepressed(button)
        if self.quitButton then
            self.quitButton:mousepressed(button)
        end
    end
end

function MainMenuScene:mousereleased(x, y, button)
    if button == 1 then
        self.playButton:mousereleased(button)
        self.creditsButton:mousereleased(button)
        if self.quitButton then
            self.quitButton:mousereleased(button)
        end
    end
end

return MainMenuScene
