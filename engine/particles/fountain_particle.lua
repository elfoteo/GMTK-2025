local ParticleBase       = require("engine.particles.particle_base")

---@class FountainParticle : ParticleBase
---@field color table
---@field initial_lifetime number
---@field spawnX number
---@field spawnY number
---@field myVx number
---@field peakHeight number
local FountainParticle   = setmetatable({}, { __index = ParticleBase })
FountainParticle.__index = FountainParticle

function FountainParticle.new(x, y, _, _, lifetime)
    local tileX = math.floor(x / 16) * 16 + 8
    local tileY = math.floor(y / 16) * 16 + 9

    local self = ParticleBase.new(tileX, tileY, 0, 0, lifetime)
    setmetatable(self, FountainParticle)

    self.spawnX           = tileX
    self.spawnY           = tileY
    self.initial_lifetime = lifetime

    -- horizontal speed ~ Normal(mean=0, σ=8)
    self.myVx             = math.random() * 8 - 4

    -- peak height ~ |Normal(6, 4)|
    self.peakHeight       = math.abs(love.math.randomNormal(6, 4))

    self.color            = { 1, 0.5, 0, 1 }
    return self
end

function FountainParticle:update(dt)
    self.time = self.time + dt
    if self.time >= self.life then
        self.dead = true
        return
    end

    local u = self.time / self.life
    local h = 4 * self.peakHeight * u * (1 - u)

    self.x = self.spawnX + self.myVx * self.time
    self.y = self.spawnY - h
end

function FountainParticle:draw()
    local fadePoint = self.initial_lifetime * 0.8
    local alpha = 1
    if self.time >= fadePoint then
        alpha = (self.life - self.time) / (self.life - fadePoint)
    end

    love.graphics.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.points(self.x, self.y)
    love.graphics.pop()
end

return FountainParticle
