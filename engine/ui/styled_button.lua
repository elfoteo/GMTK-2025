local Button = require("engine.ui.button")
local StyledButtonSparkParticle = require("engine.particles.styled_button_spark_particle")

---@class StyledButton : Button
---@field text string
---@field callback fun()
---@field customFont CustomFont
---@field baseColor number[]
---@field currentColor number[]
---@field underlineProgress number
---@field particleSystem ParticleSystem
---@field particleEmitTimer number
local StyledButton = setmetatable({}, { __index = Button })
StyledButton.__index = StyledButton

function StyledButton.new(x, y, width, height, text, callback, customFont, baseColor, particleSystem)
    local self = setmetatable(Button.new(x, y, width, height), StyledButton)
    self.text = text
    self.callback = callback
    self.customFont = customFont
    self.baseColor = baseColor or { 1, 1, 1, 1 }
    self.currentColor = self.baseColor
    self.underlineProgress = 0
    self.particleSystem = particleSystem
    self.particleEmitTimer = 0
    return self
end

function StyledButton:update(dt, mouse_x, mouse_y)
    Button.update(self, dt, mouse_x, mouse_y)

    local speed = dt / 0.3
    if self.isHovered then
        self.underlineProgress = math.min(self.underlineProgress + speed, 1)
    else
        self.underlineProgress = math.max(self.underlineProgress - speed, 0)
    end

    if self.isActive then
        self.currentColor = {
            self.baseColor[1] * 1.7,
            self.baseColor[2] * 1.7,
            self.baseColor[3] * 1.7,
            self.baseColor[4]
        }
    elseif self.isHovered then
        self.currentColor = {
            self.baseColor[1] * 1.5,
            self.baseColor[2] * 1.5,
            self.baseColor[3] * 1.5,
            self.baseColor[4]
        }
    else
        self.currentColor = self.baseColor
    end

    self.particleEmitTimer = self.particleEmitTimer + dt
    if self.particleEmitTimer > 0.05 then
        self.particleEmitTimer = 0
        if (self.isHovered or self.isActive) and self.underlineProgress > 0 then
            local x, y, width = self:getUnderlinePosition()
            local emitX = x + math.random() * width
            self.particleSystem:emitCone(emitX, y, math.pi / 2, math.pi / 4, 1, { 40, 80 }, { 0.5, 1 }, self
                .currentColor, StyledButtonSparkParticle, 0.4)
        end
    end
end

function StyledButton:mousereleased(button)
    if Button.mousereleased(self, button) then
        self.callback()
    end
end

function StyledButton:draw()
    local fontObj = self.customFont or love.graphics.getFont()
    local font = fontObj.font or fontObj
    love.graphics.setFont(font)
    love.graphics.setColor(self.currentColor)

    local textW = font:getWidth(self.text)
    local textH = font:getHeight()
    local tx = self.x + (self.width - textW) / 2
    local ty = self.y + (self.height - textH) / 2

    love.graphics.print(self.text, tx, ty)

    if self.underlineProgress > 0 then
        love.graphics.setLineWidth(1)
        local drawW = textW * self.underlineProgress
        love.graphics.line(tx, ty + textH + 2, tx + drawW, ty + textH + 2)
    end
end

function StyledButton:getUnderlinePosition()
    local fontObj = self.customFont or love.graphics.getFont()
    local font = fontObj.font or fontObj
    local textW = font:getWidth(self.text)
    local textH = font:getHeight()
    local tx = self.x + (self.width - textW) / 2
    local ty = self.y + (self.height - textH) / 2
    return tx, ty + textH + 2, textW * self.underlineProgress
end

return StyledButton
