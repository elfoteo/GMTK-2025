---@alias RGBAColor table<number, number, number, number>  Four‑element array: R, G, B, A in 0–1 range.
---@alias Range2      table<number, number>               Two‑element array: {min, max}.

---@class ParticleSystem
---@field particles   ParticleBase[] List of active particles.
---@field tilemap     TileMap The tilemap
local ParticleSystem = {}
ParticleSystem.__index = ParticleSystem

---Create a new ParticleSystem.
---@param tilemap TileMap The tilemap for collision detection.
---@return ParticleSystem
function ParticleSystem.new(tilemap)
    local ps = setmetatable({ particles = {} }, ParticleSystem)
    ps.tilemap = tilemap
    return ps
end

---Update all particles and remove dead ones.
---@param self ParticleSystem
---@param dt   number Time elapsed since last update (seconds).
---@param player Player
function ParticleSystem:update(dt, player)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p:update(dt, self.tilemap, player)
        if p:isDead() then
            table.remove(self.particles, i)
        end
    end
end

---Draw all particles.
---@param self ParticleSystem
function ParticleSystem:draw()
    for _, p in ipairs(self.particles) do
        p:draw()
    end
end

---Emit a single particle.
---@param self         ParticleSystem
---@param x            number      X coordinate.
---@param y            number      Y coordinate.
---@param vx           number      Velocity X.
---@param vy           number      Velocity Y.
---@param lifetime     number      Lifetime in seconds.
---@param color?       RGBAColor   Optional RGBA color.
---@param particleType? ParticleBase Optional particle class (defaults to SparkParticle).
---@param size?        number      Optional size (radius).
---@return ParticleBase           The newly created particle.
function ParticleSystem:emit(x, y, vx, vy, lifetime, color, particleType, size)
    local pType = particleType or require("engine.particles.spark_particle")
    local p = pType.new(x, y, vx, vy, lifetime, color, size)

    if type(color) == "table"
        and type(color[1]) == "number"
        and type(color[2]) == "number"
        and type(color[3]) == "number"
    then
        p.color = color
    end

    table.insert(self.particles, p)
    return p
end

---Emit a cone of particles.
---@param self         ParticleSystem
---@param x            number      X coordinate.
---@param y            number      Y coordinate.
---@param angle        number      Central angle in radians.
---@param spread       number      Angular spread in radians.
---@param count        number      Number of particles.
---@param speedRange   Range2      {minSpeed, maxSpeed}.
---@param lifeRange    Range2      {minLifetime, maxLifetime}.
---@param color?       RGBAColor   Optional RGBA color.
---@param particleType? SparkParticle Optional particle class.
---@param size?        number      Optional size (radius).
function ParticleSystem:emitCone(x, y, angle, spread, count, speedRange, lifeRange, color, particleType, size)
    for _ = 1, count do
        local a = angle - spread * 0.5 + math.random() * spread
        local spd = speedRange[1] + math.random() * (speedRange[2] - speedRange[1])
        local life = lifeRange[1] + math.random() * (lifeRange[2] - lifeRange[1])
        local vx = math.cos(a) * spd
        local vy = math.sin(a) * spd
        self:emit(x, y, vx, vy, life, color, particleType, size)
    end
end

---Emit a burst of particles in all directions.
---@param self         ParticleSystem
---@param x            number      X coordinate.
---@param y            number      Y coordinate.
---@param count        number      Number of particles.
---@param speedRange   Range2      {minSpeed, maxSpeed}.
---@param lifeRange    Range2      {minLifetime, maxLifetime}.
---@param color?       RGBAColor   Optional RGBA color.
---@param particleType? SparkParticle Optional particle class.
---@param size?        number      Optional size (radius).
function ParticleSystem:emitBurst(x, y, count, speedRange, lifeRange, color, particleType, size)
    for _ = 1, count do
        local angle = math.random() * 2 * math.pi
        local speed = speedRange[1] + math.random() * (speedRange[2] - speedRange[1])
        local life = lifeRange[1] + math.random() * (lifeRange[2] - lifeRange[1])
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        self:emit(x, y, vx, vy, life, color, particleType, size)
    end
end

return ParticleSystem
