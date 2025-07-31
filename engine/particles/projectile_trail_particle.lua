---@class ProjectileTrailParticle : SparkParticle
local SparkParticle = require("engine.particles.spark_particle")

local ProjectileTrailParticle = {}
ProjectileTrailParticle.__index = ProjectileTrailParticle
setmetatable(ProjectileTrailParticle, { __index = SparkParticle })

--- Creates a new ProjectileTrailParticle object.
---@param x number The x-coordinate of the particle.
---@param y number The y-coordinate of the particle.
---@param vx number The x-velocity of the particle.
---@param vy number The y-velocity of the particle.
---@param lifetime number The lifetime of the particle.
---@return ProjectileTrailParticle
function ProjectileTrailParticle.new(x, y, vx, vy, lifetime)
    local p = SparkParticle.new(x, y, vx, vy, lifetime, { 1, 1, 1 }, 1)
    setmetatable(p, ProjectileTrailParticle)

    -- Override the shape so that pivot is at the tip (0, 0)
    p.shape = ProjectileTrailParticle.generateTrailShape(p.speed)
    return p
end

--- Generates a shape for the projectile trail.
---@param speed number The speed of the projectile.
---@return number[] A list of vertices for the particle's shape.
function ProjectileTrailParticle.generateTrailShape(speed)
    local size = math.random(1, 3) * 0.5
    local length = speed * 0.05 + size -- trail length based on speed

    -- Pivot is now at the tip (0, 0)
    return {
        0, 0,                 -- tip (pivot)
        -length, -size * 0.5, -- upper tail
        -length * 1.2, 0,     -- far tail point
        -length, size * 0.5   -- lower tail
    }
end

return ProjectileTrailParticle
