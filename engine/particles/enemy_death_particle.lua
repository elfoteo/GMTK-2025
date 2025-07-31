local PhysicsParticle = require("engine.particles.physics_particle")

---@class EnemyDeathParticle : PhysicsParticle
---@field initialRadius number
local EnemyDeathParticle = setmetatable({}, { __index = PhysicsParticle })
EnemyDeathParticle.__index = EnemyDeathParticle

--- Creates a new EnemyDeathParticle object.
---@param x number The x-coordinate of the particle.
---@param y number The y-coordinate of the particle.
---@param vx number The x-velocity of the particle.
---@param vy number The y-velocity of the particle.
---@param lifetime number The lifetime of the particle.
---@return EnemyDeathParticle
function EnemyDeathParticle.new(x, y, vx, vy, lifetime)
    local p = PhysicsParticle.new(x, y, vx, vy, lifetime)
    setmetatable(p, EnemyDeathParticle)
    ---@cast p EnemyDeathParticle

    p.initialRadius = math.random(2, 8)
    p.radius = p.initialRadius
    -- Random shade of red
    p.color = {
        math.random(200, 255) / 255,
        math.random(0, 50) / 255,
        math.random(0, 50) / 255
    }
    return p
end

--- Updates the particle.
---@param dt number The time since the last frame.
function EnemyDeathParticle:update(dt, tilemap)
    PhysicsParticle.update(self, dt, tilemap)

    local lifeRatio = self.time / self.life
    self.radius = self.initialRadius * (1 - lifeRatio)
end

--- Checks if the particle is dead.
---@return boolean
function EnemyDeathParticle:isDead()
    return self.radius <= 0.1
end

--- Draws the particle.
function EnemyDeathParticle:draw()
    love.graphics.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.pop()
end

return EnemyDeathParticle
