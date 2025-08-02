-- game/projectiles/cutlery/cutlery_projectile.lua
local Projectile = require("game.projectiles.projectile_base")
local ProjectileTrailParticle = require("engine.particles.projectile_trail_particle")

---@class CutleryProjectile : ProjectileBase
---@field gravity number
local CutleryProjectile = setmetatable({}, { __index = Projectile })
CutleryProjectile.__index = CutleryProjectile

--- Creates a new CutleryProjectile.
---@param x number The x-coordinate.
---@param y number The y-coordinate.
---@param speed number The speed of the projectile.
---@param angle number The angle of the projectile.
---@param image_path string The path to the image for the projectile.
---@return CutleryProjectile
function CutleryProjectile.new(x, y, speed, angle, image_path)
    local trail_options = {
        particle_type = ProjectileTrailParticle,
        spread = 0.2,
        count = 1,
        speed_range = { 10, 30 },
        lifetime_range = { 0.1, 0.2 },
        scale = 0.1
    }
    local self = Projectile.new(x, y, speed, angle, image_path, trail_options, 10)
    setmetatable(self, CutleryProjectile)
    self.gravity = 30
    return self
end

function CutleryProjectile:update(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y)
    self.vy = self.vy + self.gravity * dt
    self.angle = math.atan2(self.vy, self.vx)
    return Projectile.update(self, dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y)
end

return CutleryProjectile
