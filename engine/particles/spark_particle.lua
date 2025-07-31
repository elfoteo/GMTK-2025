local ParticleBase = require("engine.particles.particle_base")

---@class SparkParticle : ParticleBase
---@field speed number
---@field angle number
---@field size number
---@field color {number, number, number, number?}
---@field shape number[]
local SparkParticle = setmetatable({}, { __index = ParticleBase })
SparkParticle.__index = SparkParticle

--- Creates a new SparkParticle object.
---@param x number The x-coordinate of the particle.
---@param y number The y-coordinate of the particle.
---@param vx number The x-velocity of the particle.
---@param vy number The y-velocity of the particle.
---@param lifetime number The lifetime of the particle.
---@param color? {number, number, number, number?} The color of the particle.
---@param size? number The size of the particle.
---@return SparkParticle
function SparkParticle.new(x, y, vx, vy, lifetime, color, size)
    local p = ParticleBase.new(x, y, vx, vy, lifetime)
    setmetatable(p, SparkParticle)
    ---@cast p SparkParticle

    p.speed = math.sqrt(vx * vx + vy * vy)
    p.angle = math.atan2(vy, vx)
    p.size = size or 1
    -- Use provided color or generate a random red/orange/yellow
    p.color = color or {
        math.random(200, 255) / 255,
        math.random(100, 200) / 255,
        math.random(20, 50) / 255
    }
    p.shape = SparkParticle.generateSparkShape(p.speed, p.size)
    return p
end

--- Generates a shape for the spark particle.
---@param speed number The speed of the particle.
---@param size number The size of the particle.
---@return number[] A list of vertices for the particle's shape.
function SparkParticle.generateSparkShape(speed, size)
    local baseLength = speed * 0.1 * size
    local lengthTip = (math.random() * 4 + 2 + baseLength) * size
    local lengthTail = (math.random() * 6 + 6 + baseLength) * size
    local widthTail = (math.random() * 2 + 1) * size
    local shift = lengthTail
    return {
        lengthTip + shift, 0,
        shift, -widthTail * 0.5,
        0, 0,
        shift, widthTail * 0.5
    }
end

--- Updates the particle.
---@param dt number The time since the last frame.
function SparkParticle:update(dt)
    ParticleBase.update(self, dt)
end

--- Draws the particle.
function SparkParticle:draw()
    local alpha = 1 - (self.time / self.life)
    love.graphics.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)
    love.graphics.polygon("fill", self.shape)
    love.graphics.pop()
end

return SparkParticle
