local ProjectileBase = require("game.projectiles.projectile_base")
local SparkParticle  = require("engine.particles.spark_particle")

---@class WeaponBase
---@field damage           number                    Damage per shot.
---@field fire_rate        number                    Minimum interval between shots (seconds).
---@field projectile_speed number                    Speed of spawned projectiles.
---@field projectile_type  table                     Projectile class (must implement new(x,y,speed,angle)).
---@field repeating        boolean                   If true, holding fire will repeat shots.
---@field last_shot_time   number                    Timestamp of last shot.
---@field angle            number                    Current aim angle (radians).
---@field weaponOffset     number                    Base offset from the player’s center along the aim direction.
---@field muzzleOffsetX    number                    Local X offset from weapon origin to muzzle.
---@field muzzleOffsetY    number                    Local Y offset from weapon origin to muzzle.
---@field image?           love.Image                Optional sprite to draw for this weapon.
---@field name             string                    The name of the weapon.
local WeaponBase     = {}
WeaponBase.__index   = WeaponBase

---Creates a new Weapon.
---@param damage           number                    Damage per shot.
---@param fire_rate        number                    Minimum interval between shots (seconds).
---@param projectile_speed number                    Speed of spawned projectiles.
---@param projectile_type  table                     Projectile class (must implement new(x,y,speed,angle)).
---@param repeating        boolean                   If true, holding fire will repeat shots.
---@param name             string                    The name of the weapon.
---@return WeaponBase                              The new weapon instance.
function WeaponBase.new(damage, fire_rate, projectile_speed, projectile_type, repeating, name)
    local self            = setmetatable({}, WeaponBase)
    self.damage           = damage
    self.fire_rate        = fire_rate
    self.projectile_speed = projectile_speed
    self.projectile_type  = projectile_type or ProjectileBase
    self.repeating        = repeating or false
    self.last_shot_time   = 0
    self.angle            = 0
    self.name             = name

    -- Base offsets; subclasses will typically override these
    self.weaponOffset     = 0
    self.muzzleOffsetX    = 0
    self.muzzleOffsetY    = 0

    -- Now every weapon has this field available for subclasses to populate:
    self.image            = nil

    return self
end

---Updates the weapon’s aim angle.
---@param playerX number World X of player center.
---@param playerY number World Y of player center.
---@param mouseX  number World X of pointer.
---@param mouseY  number World Y of pointer.
function WeaponBase:update(playerX, playerY, mouseX, mouseY)
    self.angle = math.atan2(mouseY - playerY, mouseX - playerX)
end

---Returns true if enough time has passed since last shot.
---@return boolean
function WeaponBase:canShoot()
    return (love.timer.getTime() - self.last_shot_time) >= self.fire_rate
end

---Checks if the weapon can shoot without colliding with a tile.
---@param playerX number World X of player center.
---@param playerY number World Y of player center.
---@param angle number The angle of the weapon (radians).
---@param tilemap TileMap The tilemap for collision checks.
---@param projectile_radius number The radius of the projectile.
---@return boolean True if shooting is possible without collision, false otherwise.
function WeaponBase:canShootAt(playerX, playerY, angle, tilemap, projectile_radius)
    local muzzleX, muzzleY = self:getMuzzlePosition(playerX, playerY, angle)
    return not tilemap:checkCollision(muzzleX - projectile_radius, muzzleY - projectile_radius, projectile_radius * 2,
        projectile_radius * 2)
end

---Gets the muzzle position of the weapon.
---@param playerX number World X of player center.
---@param playerY number World Y of player center.
---@param angle   number The angle of the weapon (radians).
---@return number, number The x,y coordinates of the muzzle.
function WeaponBase:getMuzzlePosition(playerX, playerY, angle)
    local cosA, sinA = math.cos(angle), math.sin(angle)
    local baseX      = playerX + (self.weaponOffset * cosA)
    local baseY      = playerY + (self.weaponOffset * sinA)
    local flip       = (angle > math.pi / 2 or angle < -math.pi / 2) and -1 or 1

    local localX     = self.muzzleOffsetX
    local localY     = self.muzzleOffsetY * flip

    local spawnX     = baseX + (localX * cosA - localY * sinA)
    local spawnY     = baseY + (localX * sinA + localY * cosA)
    return spawnX, spawnY
end

---Fires a projectile (if cooldown allows), spawns muzzle flash, and returns it.
---@param playerX       number                    World X of player center.
---@param playerY       number                    World Y of player center.
---@param angle         number                    Angle at which to fire (radians).
---@param particleSystem ParticleSystem?          Optional particle system for muzzle flash.
---@param tilemap TileMap The tilemap for collision checks.
---@return ProjectileBase|nil                     The new projectile, or nil if on cooldown or collision.
function WeaponBase:shoot(playerX, playerY, angle, particleSystem, tilemap)
    if not self:canShoot() then return nil end

    -- Determine projectile size for collision check
    -- Assuming projectile_type has a 'width' and 'height' property after instantiation
    -- For now, using a default radius. A better solution would be to pass it or query it from projectile_type.
    local temp_proj = self.projectile_type.new(0, 0, 0, 0, "assets/ammo/762x39.png") -- Dummy instantiation to get dimensions
    local projectile_radius = math.max(temp_proj.width, temp_proj.height) / 2

    if not self:canShootAt(playerX, playerY, angle, tilemap, projectile_radius) then
        return nil
    end

    self.last_shot_time = love.timer.getTime()

    local spawnX, spawnY = self:getMuzzlePosition(playerX, playerY, angle)
    local proj = self.projectile_type.new(spawnX, spawnY, self.projectile_speed, angle, "assets/ammo/762x39.png")

    if particleSystem then
        particleSystem:emitCone(
            spawnX, spawnY, angle,
            1.0, 5,        -- spread & count
            { 10, 20 },    -- speed range
            { 0.2, 0.05 }, -- lifetime range
            nil,           -- color (default)
            SparkParticle, -- particle class
            1              -- size
        )
    end

    return proj
end

---Default draw (simple rectangle). Subclasses normally override.
---@param playerX number World X of player center.
---@param playerY number World Y of player center.
function WeaponBase:draw(playerX, playerY)
    love.graphics.push()
    love.graphics.translate(playerX, playerY)
    love.graphics.rotate(self.angle)
    if self.image then
        -- if subclass provided image, use it
        love.graphics.draw(self.image, self.weaponOffset, 0, 0, 1, 1,
            self.image:getWidth() / 2, self.image:getHeight() / 2)
    else
        -- fallback rectangle
        love.graphics.rectangle("fill", 0, -2, 10, 4)
    end
    love.graphics.pop()
end

return WeaponBase
