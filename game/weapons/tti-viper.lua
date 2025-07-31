local WeaponBase       = require("game.weapons.weapon_base")
local Projectile9MM = require("game.projectiles.9mm_projectile")

---@class Viper : WeaponBase
local Viper            = setmetatable({}, { __index = WeaponBase })
Viper.__index          = Viper

--- Creates a new AK‑47 instance.
---@return Viper
function Viper.new()
    -- damage=30, fire_rate=0.25s, projectile_speed=300, projectile class, repeating=false
    local viper = WeaponBase.new(35, 0.15, 300, Projectile9MM, false, "tti-viper")
    ---@cast viper Viper
    setmetatable(viper, Viper)

    -- Load the AK‑47 sprite
    viper.image = love.graphics.newImage("assets/weapons/tti-viper.png") -- LSP warning here, fields image cannot be injected into weapon, to do so use ---@class

    -- How far out from player center the weapon sits along aim direction
    viper.weaponOffset = 12

    -- Where the muzzle lives, relative to the weapon’s origin
    viper.muzzleOffsetX = 10 / 2
    viper.muzzleOffsetY = -2

    return viper
end

--- Draws the AK‑47 at the player’s position, rotated to aim.
-- @param playerX World X of player center
-- @param playerY World Y of player center
function Viper:draw(playerX, playerY)
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

return Viper
