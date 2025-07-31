local Projectile = require("game.projectiles.projectile_base")
local ProjectileTrailParticle = require("engine.particles.projectile_trail_particle")

---@class ClockHandProjectile : ProjectileBase
local ClockHandProjectile = setmetatable({}, { __index = Projectile })
ClockHandProjectile.__index = ClockHandProjectile

--- Creates a new ClockHand projectile.
---@param x number The x-coordinate.
---@param y number The y-coordinate.
---@param speed number The speed of the projectile.
---@param angle number The angle of the projectile.
---@return ClockHandProjectile
function ClockHandProjectile.new(x, y, speed, angle)
    local trail_options = {
        particle_type = ProjectileTrailParticle,
        spread = 0.1,
        count = 1,
        speed_range = { 5, 15 },
        lifetime_range = { 0.2, 0.4 },
        scale = 0.2,
        color = { 0.8, 0.8, 0.8 }
    }
    local self = Projectile.new(x, y, speed, angle, "assets/entities/clock-hand.png", trail_options)
    setmetatable(self, ClockHandProjectile)
    self.damage = 25
    return self
end

return ClockHandProjectile
