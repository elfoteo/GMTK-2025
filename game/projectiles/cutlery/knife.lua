-- game/projectiles/cutlery/knife.lua
local CutleryProjectile = require("game.projectiles.cutlery.cutlery_projectile")

---@class Knife : CutleryProjectile
local Knife = setmetatable({}, { __index = CutleryProjectile })
Knife.__index = Knife

function Knife.new(x, y, speed, angle)
    local self = CutleryProjectile.new(x, y, speed, angle, "assets/projectiles/waiterbot-knife.png")
    setmetatable(self, Knife)
    return self
end

return Knife
