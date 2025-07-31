local PhysicsParticle = require('engine.particles.physics_particle')

local ExhaustParticle = {}
ExhaustParticle.__index = ExhaustParticle
setmetatable(ExhaustParticle, { __index = PhysicsParticle })

function ExhaustParticle.new(x, y, vx, vy, lifetime)
    local p = PhysicsParticle.new(x, y, vx, vy, lifetime)
    setmetatable(p, ExhaustParticle)

    p.initialRadius = math.random(1, 3)
    p.radius = p.initialRadius
    -- Random red/orange/yellow color
    local rand = math.random()
    if rand < 0.33 then
        p.color = {1, math.random(0, 50) / 255, 0} -- Reddish
    elseif rand < 0.66 then
        p.color = {1, math.random(100, 150) / 255, 0} -- Orange
    else
        p.color = {1, 1, math.random(0, 50) / 255} -- Yellowish
    end
    return p
end

function ExhaustParticle:update(dt, tilemap)
    PhysicsParticle.update(self, dt, tilemap)

    local lifeRatio = self.time / self.life
    self.radius = self.initialRadius * (1 - lifeRatio)
end

function ExhaustParticle:isDead()
    return self.radius <= 0.1
end

function ExhaustParticle:draw()
    local alpha = 1 - (self.time / self.life)
    love.graphics.push()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.pop()
end

return ExhaustParticle