local ProjectileBase = require("game.projectiles.projectile_base")
local ProjectileTrailParticle = require("engine.particles.projectile_trail_particle")

---@class NineMMProjectile : ProjectileBase
local NineMMProjectile = setmetatable({}, { __index = ProjectileBase })
NineMMProjectile.__index = NineMMProjectile

--- Creates a new 9mm Projectile.
---@param x number The x-coordinate.
---@param y number The y-coordinate.
---@param speed number The speed of the projectile.
---@param angle number The angle of the projectile.
---@param trail_options table optional options for the particle trail
---@return NineMMProjectile
function NineMMProjectile.new(x, y, speed, angle)
    local trail_options = {
        particle_type = ProjectileTrailParticle,
        spread = 0.2,
        count = 1,
        color = { 1, 0.9, 0.5 },
        speed_range = { 10, 30 },
        lifetime_range = { 0.1, 0.2 },
        scale = 0.1
    }
    local self = ProjectileBase.new(x, y, speed, angle, "assets/ammo/9mm.png", trail_options)
    setmetatable(self, NineMMProjectile)
    return self
end

return NineMMProjectile
