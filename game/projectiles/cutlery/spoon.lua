-- game/projectiles/cutlery/spoon.lua
local CutleryProjectile = require("game.projectiles.cutlery.cutlery_projectile")

---@class Spoon : CutleryProjectile
local Spoon = setmetatable({}, { __index = CutleryProjectile })
Spoon.__index = Spoon

function Spoon.new(x, y, speed, angle)
    local self = CutleryProjectile.new(x, y, speed, angle, "assets/projectiles/waiterbot-spoon.png")
    setmetatable(self, Spoon)
    return self
end

return Spoon
