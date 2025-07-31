-- game/762x39_projectile.lua
local Projectile = require("game.projectiles.projectile_base")
local ProjectileTrailParticle = require("engine.particles.projectile_trail_particle")

---@class Projectile762x39 : ProjectileBase
local Projectile762x39 = setmetatable({}, { __index = Projectile })
Projectile762x39.__index = Projectile762x39

--- Creates a new 7.62x39mm projectile.
---@param x number The x-coordinate.
---@param y number The y-coordinate.
---@param speed number The speed of the projectile.
---@param angle number The angle of the projectile.
---@return Projectile762x39
function Projectile762x39.new(x, y, speed, angle)
    local trail_options = {
        particle_type = ProjectileTrailParticle,
        spread = 0.2,
        count = 1,
        speed_range = { 10, 30 },
        lifetime_range = { 0.1, 0.2 },
        scale = 0.1
    }
    local self = Projectile.new(x, y, speed, angle, "assets/ammo/762x39.png", trail_options)
    setmetatable(self, Projectile762x39)
    return self
end

return Projectile762x39
