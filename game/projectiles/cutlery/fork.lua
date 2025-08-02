-- game/projectiles/cutlery/fork.lua
local CutleryProjectile = require("game.projectiles.cutlery.cutlery_projectile")

---@class Fork : CutleryProjectile
local Fork = setmetatable({}, { __index = CutleryProjectile })
Fork.__index = Fork

function Fork.new(x, y, speed, angle)
    local self = CutleryProjectile.new(x, y, speed, angle, "assets/projectiles/waiterbot-fork.png")
    setmetatable(self, Fork)
    return self
end

return Fork
