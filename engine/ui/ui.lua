local Crosshair = require("engine.ui.crosshair")
local Bars = require("engine.ui.bars")

---@class UI
---@field crosshair Crosshair
---@field bars Bars
---@field scene MainScene
local UI = {}
UI.__index = UI

---@param scene MainScene
function UI.new(scene)
    local self = setmetatable({}, UI)
    self.crosshair = Crosshair.new("assets/gui/crosshair.png", 1)
    self.bars = Bars.new(11, 184)
    self.scene = scene
    return self
end

function UI:draw()
    local player = self.scene.player
    local score = self.scene.score
    local font8px = self.scene.customFont8px
    local avg_fps = self.scene.avg_fps
    -- Draw Bars
    self.bars:draw(player.health / 100, player.mana / 100)

    -- Draw Score and FPS
    font8px:print("Score: " .. score, 4, 4, { 1, 1, 0, 1 })
    font8px:print("FPS: " .. math.floor(avg_fps), 4, 14, { 1, 1, 0, 1 })

    -- Draw Crosshair
    local mx, my = love.mouse.getPosition()
    local cx, cy = self.scene:toCanvas(mx, my) -- This will need to be adjusted
    self.crosshair:draw(math.floor(cx) + 0.5, math.floor(cy) + 0.5)
end

return UI
