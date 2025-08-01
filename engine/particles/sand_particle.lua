local PhysicsParticle = require("engine.particles.physics_particle")

---@class SandParticle : PhysicsParticle
---@field color number[]
local SandParticle = setmetatable({}, { __index = PhysicsParticle })
SandParticle.__index = SandParticle

local SAND_COLORS = {
    { 0.74, 0.63, 0.28, 1 },
    { 0.68, 0.56, 0.22, 1 },
    { 0.61, 0.50, 0.18, 1 }
}

function SandParticle.new(x, y, vx, vy, lifetime)
    local self = PhysicsParticle.new(x, y, vx, vy, lifetime)
    setmetatable(self, SandParticle)
    self.radius = 1
    self.bounciness = 0.1
    self.gravity = 100
    ---@cast self SandParticle
    self.color = SAND_COLORS[math.random(#SAND_COLORS)]
    return self
end

function SandParticle:draw()
    love.graphics.push()
    love.graphics.setColor(self.color)
    love.graphics.points(self.x, self.y)
    love.graphics.pop()
end

return SandParticle
