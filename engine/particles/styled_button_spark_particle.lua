local SparkParticle = require("engine.particles.spark_particle")

---@class StyledButtonSparkParticle : SparkParticle
---@field angleVel number
local StyledButtonSparkParticle = setmetatable({}, { __index = SparkParticle })
StyledButtonSparkParticle.__index = StyledButtonSparkParticle

function StyledButtonSparkParticle.new(x, y, vx, vy, lifetime, color, size)
    local self = setmetatable(SparkParticle.new(x, y, vx, vy, lifetime, color, size), StyledButtonSparkParticle)
    self.angleVel = math.random() * 4 - 2
    return self
end

function StyledButtonSparkParticle:update(dt)
    SparkParticle.update(self, dt)
    self.angle = self.angle + self.angleVel * dt
end

return StyledButtonSparkParticle
