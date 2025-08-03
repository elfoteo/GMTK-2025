local ParticleBase = require("engine.particles.particle_base")

---@class PhysicsParticle : ParticleBase
---@field radius number
---@field bounciness number
---@field gravity number
local PhysicsParticle = setmetatable({}, { __index = ParticleBase })
PhysicsParticle.__index = PhysicsParticle

--- Creates a new PhysicsParticle object.
---@param x number The x-coordinate of the particle.
---@param y number The y-coordinate of the particle.
---@param vx number The x-velocity of the particle.
---@param vy number The y-velocity of the particle.
---@param lifetime number The lifetime of the particle.
---@return PhysicsParticle
function PhysicsParticle.new(x, y, vx, vy, lifetime)
    local p = ParticleBase.new(x, y, vx, vy, lifetime)
    setmetatable(p, PhysicsParticle)
    ---@cast p PhysicsParticle

    p.radius = 5 -- Default radius
    p.bounciness = 0.7
    p.gravity = 400
    return p
end

--- Updates the particle.
---@param dt number The time since the last frame.
---@param tilemap TileMap The tilemap of the scene
function PhysicsParticle:update(dt, tilemap)
    -- Gravity
    self.vy = self.vy + self.gravity * dt

    -- Update position
    local newX = self.x + self.vx * dt
    local newY = self.y + self.vy * dt

    -- Collision detection
    if tilemap and tilemap:checkCollision(newX - self.radius, newY - self.radius, self.radius * 2, self.radius * 2, false) then
        -- On collision, bounce and lose some velocity
        self.vy = -self.vy * self.bounciness
        self.vx = self.vx * self.bounciness
    else
        self.x = newX
        self.y = newY
    end

    self.time = self.time + dt
end

--- Draws the particle.
function PhysicsParticle:draw()
    -- Default draw function (a simple white circle)
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.pop()
end

return PhysicsParticle
