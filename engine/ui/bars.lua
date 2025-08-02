---@class Bars
---@field x number
---@field y number
---@field barFrame love.Image
---@field healthBarMask love.Image
---@field healthBarShader love.Shader
---@field manaBarMask love.Image
---@field manaBarShader love.Shader
local Bars = {}
Bars.__index = Bars

function Bars.new(x, y)
    local self = setmetatable({}, Bars)
    self.x = x
    self.y = y

    -- Bar frame
    self.barFrame = love.graphics.newImage("assets/gui/bar-frame.png")

    -- Health Bar
    self.healthBarMask = love.graphics.newImage("assets/gui/health-bar-mask.png")
    self.healthBarShader = love.graphics.newShader("engine/shaders/health_bar_tint.glsl")

    -- Mana Bar
    self.manaBarMask = love.graphics.newImage("assets/gui/ability-bar-mask.png")
    self.manaBarShader = love.graphics.newShader("engine/shaders/ability_bar_tint.glsl")

    return self
end

function Bars:draw(health_ratio, mana_ratio)
    -- Draw Health Bar
    love.graphics.draw(self.barFrame, self.x, self.y)
    love.graphics.setShader(self.healthBarShader)
    self.healthBarShader:send("health_ratio", health_ratio)
    love.graphics.draw(self.healthBarMask, self.x, self.y)
    love.graphics.setShader()

    -- Draw Mana Bar
    love.graphics.setShader(self.manaBarShader)
    self.manaBarShader:send("mana_ratio", mana_ratio)
    love.graphics.draw(self.manaBarMask, self.x, self.y)
    love.graphics.setShader()
end

return Bars
