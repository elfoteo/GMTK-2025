---@class ParticleBase
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field life number
---@field time number
local ParticleBase = {}
ParticleBase.__index = ParticleBase

--- Creates a new ParticleBase object.
---@param x number The x-coordinate of the particle.
---@param y number The y-coordinate of the particle.
---@param vx number The x-velocity of the particle.
---@param vy number The y-velocity of the particle.
---@param lifetime number The lifetime of the particle.
---@return ParticleBase
function ParticleBase.new(x, y, vx, vy, lifetime)
    local p = setmetatable({}, ParticleBase)
    p.x = x
    p.y = y
    p.vx = vx
    p.vy = vy
    p.life = lifetime
    p.time = 0
    return p
end

--- Updates the particle.
---@param dt number The time since the last frame.
---@param tilemap TileMap The tilemap may be needed for some particle types
function ParticleBase:update(dt, tilemap)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.time = self.time + dt
end

--- Checks if the particle is dead.
---@return boolean
function ParticleBase:isDead()
    return self.time >= self.life
end

--- Draws the particle.
function ParticleBase:draw()
    -- Base particles are not drawn
end

return ParticleBase
