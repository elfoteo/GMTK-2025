-- game/projectiles/paintball.lua
local PaintballProjectile = require("game.projectiles.paintball_projectile")

---@class Paintball : PaintballProjectile
local Paintball = setmetatable({}, { __index = PaintballProjectile })
Paintball.__index = Paintball

function Paintball.new(x, y, speed, angle)
    local self = PaintballProjectile.new(x, y, speed, angle, "assets/projectiles/paintball.png")
    setmetatable(self, Paintball)
    return self
end

return Paintball
