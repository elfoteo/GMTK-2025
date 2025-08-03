local ProjectileBase = require("game.projectiles.projectile_base")

---@class SinePaintball : ProjectileBase
---@field amplitude number
---@field frequency number
---@field time number
local SinePaintball = setmetatable({}, { __index = ProjectileBase })
SinePaintball.__index = SinePaintball

function SinePaintball.new(x, y, speed, angle, amplitude, frequency)
    local self = ProjectileBase.new(x, y, speed, angle, "assets/projectiles/paintball.png", nil, 10)
    setmetatable(self, SinePaintball)
    ---@cast self SinePaintball

    self.amplitude = amplitude
    self.frequency = frequency
    self.time = 0

    return self
end

function SinePaintball:update(dt, particle_system, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y, player)
    self.time = self.time + dt

    -- Calculate the oscillating perpendicular velocity component
    local perpendicular_angle = self.angle + math.pi / 2
    local wiggle_speed = self.amplitude * self.frequency * math.cos(self.time * self.frequency)
    local wiggle_vx = math.cos(perpendicular_angle) * wiggle_speed
    local wiggle_vy = math.sin(perpendicular_angle) * wiggle_speed

    -- Temporarily modify the projectile's velocity for this frame
    local original_vx = self.vx
    local original_vy = self.vy
    self.vx = original_vx + wiggle_vx
    self.vy = original_vy + wiggle_vy

    -- Let the base class handle the movement and collisions with the modified velocity
    local hit_result = ProjectileBase.update(self, dt, particle_system, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y, player)

    -- Restore original velocity for next frame
    self.vx = original_vx
    self.vy = original_vy

    return hit_result
end

function SinePaintball:draw()
    ProjectileBase.draw(self)
end

return SinePaintball
