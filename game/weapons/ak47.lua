local WeaponBase       = require("game.weapons.weapon_base")
local Projectile762x39 = require("game.projectiles.762x39_projectile")

---@class AK47 : WeaponBase
local AK47             = setmetatable({}, { __index = WeaponBase })
AK47.__index           = AK47

--- Creates a new AK‑47 instance.
---@return AK47
function AK47.new()
    -- damage=30, fire_rate=0.25s, projectile_speed=300, projectile class, repeating=true
    local ak47 = WeaponBase.new(30, 0.25, 300, Projectile762x39, true, "ak-47")
    ---@cast ak47 AK47
    setmetatable(ak47, AK47)

    -- Load the AK‑47 sprite
    ak47.image = love.graphics.newImage("assets/weapons/ak-47.png") -- LSP warning here, fields image cannot be injected into weapon, to do so use ---@class

    -- How far out from player center the weapon sits along aim direction
    ak47.weaponOffset = 10

    -- Where the muzzle lives, relative to the weapon’s origin
    ak47.muzzleOffsetX = 28 / 2
    ak47.muzzleOffsetY = -2

    return ak47
end

--- Draws the AK‑47 at the player’s position, rotated to aim.
-- @param playerX World X of player center
-- @param playerY World Y of player center
function AK47:draw(playerX, playerY)
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    -- Move into world space
    love.graphics.translate(playerX, playerY)
    love.graphics.rotate(self.angle)

    -- Determine horizontal flip
    local scaleY = 1
    if self.angle > math.pi / 2 or self.angle < -math.pi / 2 then
        scaleY = -1
    end

    -- Flip on X axis if needed
    love.graphics.scale(1, scaleY)

    -- Draw sprite offset by weaponOffset along X, centering it on its origin
    love.graphics.draw(
        self.image,
        self.weaponOffset, 0,      -- position
        0,                         -- rotation
        1, 1,                      -- scale
        self.image:getWidth() / 2, -- originX
        self.image:getHeight() / 2 -- originY
    )
    love.graphics.pop()
end

return AK47
