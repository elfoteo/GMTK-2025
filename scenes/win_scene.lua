local Scene = require("engine.scene")
local SceneManager = require("engine.scene_manager")
local CustomFont = require("engine.custom_font")
local StyledButton = require("engine.ui.styled_button")
local ParticleSystem = require("engine.particles.particle_system")

local CANVAS_W, CANVAS_H = 384, 216

--@class WinScene : Scene
--@field customFont8px CustomFont
--@field backButton StyledButton
--@field particleSystem ParticleSystem
local WinScene = setmetatable({}, { __index = Scene })
WinScene.__index = WinScene

function WinScene.new()
    local self = Scene.new(CANVAS_W, CANVAS_H)
    --@cast self WinScene
    setmetatable(self, WinScene)

    self.customFont8px = CustomFont.new(
        "assets/font/font8x8_basic_8.fnt",
        "assets/font/font8x8_basic_8.png"
    )

    self.particleSystem = ParticleSystem.new()

    self.backButton = StyledButton.new(
        (CANVAS_W - 150) / 2,
        CANVAS_H - 30,
        150,
        20,
        "Return to Main Menu",
        function()
            -- Because the main menu scene is not passed, this will require a new instance of it
            SceneManager.gotoScene(require("scenes.main_menu_scene").new())
        end,
        self.customFont8px,
        { 0.6, 0.6, 0.6, 1 },
        self.particleSystem
    )

    return self
end

function WinScene:load()
    love.mouse.setVisible(true)
end

function WinScene:update(dt)
    Scene.update(self, dt)
    local mx, my = love.mouse.getPosition()
    local cx, cy = self:toCanvas(mx, my)
    self.backButton:update(dt, cx, cy)
    self.particleSystem:update(dt)
end

function WinScene:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1) -- Black background

    love.graphics.setFont(self.customFont8px.font)
    love.graphics.setColor(1, 1, 1, 1) -- White text

    local message = "Congratulations!\nYou have won the game!\nThank you for playing"
    love.graphics.printf(message, 0, 80, CANVAS_W, "center")

    self.backButton:draw()
    self.particleSystem:draw()

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

function WinScene:keypressed(key)
    if key == "escape" then
        SceneManager.gotoScene(require("scenes.main_menu_scene").new())
    end
end

function WinScene:mousepressed(x, y, button)
    local cx, cy = self:toCanvas(x, y)
    if button == 1 then
        self.backButton:mousepressed(button)
    end
end

function WinScene:mousereleased(x, y, button)
    if button == 1 then
        self.backButton:mousereleased(button)
    end
end

return WinScene
