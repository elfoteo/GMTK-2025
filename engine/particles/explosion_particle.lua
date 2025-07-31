---@class ExplosionParticle : SparkParticle
local SparkParticle = require("engine.particles.spark_particle")

local ExplosionParticle = {}
ExplosionParticle.__index = ExplosionParticle
setmetatable(ExplosionParticle, { __index = SparkParticle })

--- Creates a new ExplosionParticle object.
---@param x number The x-coordinate of the particle.
---@param y number The y-coordinate of the particle.
---@param vx number The x-velocity of the particle.
---@param vy number The y-velocity of the particle.
---@param lifetime number The lifetime of the particle.
---@return ExplosionParticle
function ExplosionParticle.new(x, y, vx, vy, lifetime)
    local p = SparkParticle.new(x, y, vx, vy, lifetime)
    setmetatable(p, ExplosionParticle)
    -- override the randomly generated color:
    p.color = { 1, math.random(150, 255) / 255, 0 } -- More vibrant orange/yellow
    -- give it a chunkier “explosion” shape:
    p.shape = ExplosionParticle.generateExplosionShape()
    return p
end

--- Generates a random shape for the explosion particle.
---@return number[] A list of vertices for the particle's shape.
function ExplosionParticle.generateExplosionShape()
    local size = math.random(4, 8) -- Larger, more impactful
    return {
        size, 0,
        0, -size,
        -size, 0,
        0, size
    }
end

return ExplosionParticle
