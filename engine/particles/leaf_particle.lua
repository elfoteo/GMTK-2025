local ParticleBase = require("engine.particles.particle_base")

---@class LeafParticle : ParticleBase
---@field angle number
---@field angular_velocity number
---@field size number
---@field color {number, number, number, number?}
---@field shape number[]
---@field radius number
---@field bounciness number
local LeafParticle = setmetatable({}, { __index = ParticleBase })
LeafParticle.__index = LeafParticle

--- Creates a new LeafParticle object.
---@param x number The x-coordinate of the particle.
---@param y number The y-coordinate of the particle.
---@param vx number The x-velocity of the particle.
---@param vy number The y-velocity of the particle.
---@param lifetime number The lifetime of the particle.
---@param color? {number, number, number, number?} The color of the particle.
---@param size? number The size of the particle.
---@return LeafParticle
function LeafParticle.new(x, y, vx, vy, lifetime, color, size)
    local p = ParticleBase.new(x, y, vx, vy, lifetime)
    setmetatable(p, LeafParticle)
    ---@cast p LeafParticle

    p.angle = math.random() * 2 * math.pi
    p.angular_velocity = math.random(-math.pi, math.pi)
    p.size = size or 1
    p.color = color or {
        math.random(50, 100) / 255,
        math.random(150, 200) / 255,
        math.random(50, 100) / 255
    }
    p.shape = LeafParticle.generateLeafShape(p.size)
    p.radius = 1       -- Default radius for collision
    p.bounciness = 0.2 -- Bounciness similar to physics particles
    return p
end

--- Generates a shape for the leaf particle.
---@param size number The size of the particle.
---@return number[] A list of vertices for the particle's shape.
function LeafParticle.generateLeafShape(size)
    local length = (math.random() * 4 + 2) * size
    local width = (math.random() * 2 + 1) * size
    return {
        -length / 2, 0,
        0, -width / 2,
        length / 2, 0,
        0, width / 2,
    }
end

--- Updates the particle.
---@param dt number The time since the last frame.
---@param tilemap TileMap The tilemap for collision detection.
function LeafParticle:update(dt, tilemap)
    -- Gravity
    self.vy = self.vy + 18 * dt -- Lower gravity for leaf particles

    -- Update position
    local newX = self.x + self.vx * dt
    local newY = self.y + self.vy * dt

    -- Collision detection
    local collided_tile = tilemap and tilemap:getTileAtPixel(newX, newY)
    if collided_tile and collided_tile.collides then
        -- On collision, bounce and lose some velocity
        self.vy = -self.vy * self.bounciness
        self.vx = self.vx * self.bounciness

        -- Apply a small force to unstick the particle
        local dx = self.x - (collided_tile.x + tilemap.tile_size / 2)
        local dy = self.y - (collided_tile.y + tilemap.tile_size / 2)
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            self.x = self.x + (dx / dist) * 0.5
            self.y = self.y + (dy / dist) * 0.5
        end
    else
        self.x = newX
        self.y = newY
    end

    self.time = self.time + dt
    if self.vx * self.vx + self.vy * self.vy > 100 then
        self.angle = self.angle + self.angular_velocity * dt
    else
        self.vy = 10
    end
end

--- Draws the particle.
function LeafParticle:draw()
    local alpha = 1 - (self.time / self.life)
    love.graphics.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)
    love.graphics.polygon("fill", self.shape)
    love.graphics.pop()
end

return LeafParticle
