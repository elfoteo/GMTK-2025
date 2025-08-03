local Collectible = require("game.collectible")
local FountainParticle = require("engine.particles.fountain_particle")

---@class HealthFountain : Collectible
---@field used boolean
---@field heal_rate number
local HealthFountain = {}
setmetatable(HealthFountain, { __index = Collectible })
HealthFountain.__index = HealthFountain

function HealthFountain.new(x, y)
    local self = setmetatable(Collectible.new(x, y, "health_fountain"), HealthFountain)
    self.image = nil -- Not used
    self.used = false
    self.promptTextAfter = " to heal"
    self.heal_rate = 25 -- Health per second
    return self
end

function HealthFountain:update(dt, player, particle_system)
    if self.used then
        self.showPrompt = false
        return
    end

    Collectible.update(self, dt, player)

    -- Emit particles if not used
    if particle_system and not self.used then
        if math.random() < 0.3 then -- 30% of the ticks spawn a particle if the fountain has not been used
            particle_system:emit(self.x, self.y, nil, nil, 1, nil, FountainParticle)
        end
    end
end

function HealthFountain:draw(font)
    -- We only draw the interaction prompt here.
    if self.showPrompt and font then
        love.graphics.push()
        local promptX = math.floor(self.x)
        local promptY = math.floor(self.y - self.height / 2 - 20)

        local textBeforeWidth = font:getWidth(self.promptTextBefore)
        local textAfterWidth = font:getWidth(self.promptTextAfter)
        local imgWidth = self.promptImage:getWidth()

        local spacing = -5
        local totalWidth = textBeforeWidth + spacing + imgWidth + spacing + textAfterWidth

        local currentX = promptX - totalWidth / 2

        font:print(self.promptTextBefore, math.floor(currentX), math.floor(promptY - font:getHeight() / 2))
        currentX = currentX + textBeforeWidth + spacing

        love.graphics.draw(self.promptImage, math.floor(currentX), math.floor(promptY), 0, 1, 1, 0,
            math.floor(self.promptImage:getHeight() / 2))
        currentX = currentX + imgWidth + spacing

        font:print(self.promptTextAfter, math.floor(currentX), math.floor(promptY - font:getHeight() / 2))
        love.graphics.pop()
    end
end

function HealthFountain:checkInteractionRange()
    return self.showPrompt and not self.used
end

function HealthFountain:use()
    self.used = true
end

return HealthFountain
