-- game/projectiles/paintball_projectile.lua
local ProjectileBase = require("game.projectiles.projectile_base")

---@class PaintballProjectile : ProjectileBase
local PaintballProjectile = setmetatable({}, { __index = ProjectileBase })
PaintballProjectile.__index = PaintballProjectile

function PaintballProjectile.new(x, y, speed, angle, image_path)
    local self = ProjectileBase.new(x, y, speed, angle, image_path, nil, 10)
    setmetatable(self, PaintballProjectile)
    self.width = 6
    self.height = 6
    self.gravity = 0
    return self
end

return PaintballProjectile