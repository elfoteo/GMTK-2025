local PhysicsParticle = require("engine.particles.physics_particle")

---@class SandParticle : PhysicsParticle
---@field color number[]
---@field initial_lifetime number
---@field lifetime number
local SandParticle = setmetatable({}, { __index = PhysicsParticle })
SandParticle.__index = SandParticle

local SAND_COLORS = {
    { 0.74, 0.63, 0.28, 1 },
    { 0.68, 0.56, 0.22, 1 },
    { 0.61, 0.50, 0.18, 1 }
}

---Constructor
---@param x number
---@param y number
---@param vx number
---@param vy number
---@param lifetime number
---@return SandParticle
function SandParticle.new(x, y, vx, vy, lifetime)
    lifetime = lifetime or 1
    local self = PhysicsParticle.new(x, y, vx, vy, lifetime)
    setmetatable(self, SandParticle)
    ---@cast self SandParticle

    self.radius = 1
    self.bounciness = 0.1
    self.gravity = 100

    self.color = SAND_COLORS[math.random(#SAND_COLORS)]
    self.initial_lifetime = lifetime
    self.lifetime = lifetime -- self-managed countdown
    return self
end

---Update physics and lifetime
---@param dt number
---@param tilemap TileMap
function SandParticle:update(dt, tilemap)
    PhysicsParticle.update(self, dt, tilemap)

    -- Decrement lifetime
    self.lifetime = self.lifetime - dt
end

function SandParticle:draw()
    local fade_start_point = self.initial_lifetime * 0.2
    local alpha = 1

    if self.lifetime <= fade_start_point then
        alpha = self.lifetime / fade_start_point
    end

    love.graphics.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.points(self.x, self.y)
    love.graphics.pop()
end

return SandParticle
