---
-- Base class for all enemies in the game.
--
-- @description
-- This class provides the fundamental properties and methods for any enemy,
-- including health, physics, and a basic AI structure. It is intended to be
-- extended by specific enemy types (e.g., SandWraith).
--
-- @classmod Enemy

local Living = require("game.living")

---@class Enemy : Living
---@field hitboxW number The width of the physics collision box.
---@field hitboxH number The height of the physics collision box.
---@field vx number The horizontal velocity.
---@field vy number The vertical velocity.
---@field on_ground boolean True if the enemy is standing on solid ground.
---@field stun_timer number A countdown timer for how long the enemy is stunned.
---@field is_knocked_back boolean A flag indicating if the enemy is currently being knocked back.
---@field attack_cooldown number The time remaining until the enemy can attack again.
---@field isVanished boolean If it is vanished/invisible or not
local Enemy = setmetatable({}, { __index = Living })
Enemy.__index = Enemy

local GRAVITY = 450

---
-- Creates a new Enemy.
-- @param scene Scene The scene the enemy belongs to.
-- @param x number The initial x-coordinate.
-- @param y number The initial y-coordinate.
-- @param speed number The base movement speed.
-- @param hitboxW number The width of the collision box.
-- @param hitboxH number The height of the collision box.
-- @return Enemy
function Enemy.new(scene, x, y, speed, hitboxW, hitboxH)
    local e = Living.new(scene, x, y, speed)
    setmetatable(e, Enemy)
    ---@cast e Enemy
    e.hitboxW = hitboxW or 16
    e.hitboxH = hitboxH or 16
    e.vx = 0
    e.vy = 0
    e.on_ground = false
    e.stun_timer = 0
    e.is_knocked_back = false
    e.attack_cooldown = 0
    return e
end

---
-- Handles the enemy's AI logic. This should be overridden by subclasses.
-- @param dt number The time since the last frame.
-- @param player Player The player object.
function Enemy:ai(dt, player)
    -- Do not run AI logic if stunned or knocked back
    if self.stun_timer > 0 or self.is_knocked_back then
        return
    end

    -- Default AI: move toward the player
    local playerX, playerY = player.x, player.y
    local dx, dy = playerX - self.x, playerY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        self.vx = (dx / dist) * self.speed
    else
        self.vx = 0
    end
end

---
-- Updates the enemy's physics, including gravity, friction, and tile collisions.
-- @param dt number The time since the last frame.
function Enemy:update_physics(dt)
    -- Apply gravity
    if not self.on_ground then
        self.vy = self.vy + GRAVITY * dt
    end

    -- Store old position for collision rollback
    local old_x, old_y = self.x, self.y
    local half_w, half_h = self.hitboxW / 2, self.hitboxH / 2

    -- Apply horizontal movement
    self.x = self.x + self.vx * dt
    if self.vx ~= 0 and self.scene.tilemap:checkCollision(self.x - half_w, self.y - half_h, self.hitboxW, self.hitboxH) then
        self.x = old_x           -- Reset on collision
        self.vx = -self.vx * 0.4 -- Bounce off wall with some energy loss
    end

    -- Apply vertical movement
    self.y = self.y + self.vy * dt
    if self.vy ~= 0 and self.scene.tilemap:checkCollision(self.x - half_w, self.y - half_h, self.hitboxW, self.hitboxH) then
        if self.vy > 0 then -- If moving down (colliding with floor)
            self.on_ground = true
            if self.is_knocked_back then
                self.is_knocked_back = false -- Knockback ends on landing
            end
        end
        self.y = old_y -- Reset on collision
        self.vy = 0
    else
        self.on_ground = false
    end

    -- Apply friction only when on the ground and not being knocked back
    if self.on_ground and not self.is_knocked_back then
        local friction = 0.85
        self.vx = self.vx * friction
        if math.abs(self.vx) < 1 then
            self.vx = 0
        end
    end
end

-- Main update loop for the enemy.
-- @param dt number The time since the last frame.
-- @param player Player The player object.
function Enemy:update(dt, player)
    -- Update stun timer
    if self.stun_timer > 0 then
        self.stun_timer = self.stun_timer - dt
    end

    -- Update attack cooldown
    if self.attack_cooldown > 0 then
        self.attack_cooldown = self.attack_cooldown - dt
    end

    self:ai(dt, player)
    self:update_physics(dt)

    if self.health <= 0 then
        self:die()
    end
end

-- Inflicts damage on the enemy, applying stun and knockback.
-- @param damage number The amount of damage to inflict.
-- @param source table The source of the damage (e.g., the player), must have `x` and `y` properties.
function Enemy:take_damage(damage, source)
    if self.isVanished then return end

    Living.take_damage(self, damage)

    -- Apply stun
    self.stun_timer = 0.3 -- A longer stun allows the knockback to play out

    -- Apply knockback
    if not self.is_knocked_back then
        local knockback_strength = 50
        local dx = self.x - source.x
        if dx ~= 0 then
            self.vx = (dx / math.abs(dx)) * knockback_strength
        end
        self.vy = -25 -- A small upward hop to make the knockback visible
        self.is_knocked_back = true
        self.on_ground = false
    end

    -- Increase attack cooldown
    self.attack_cooldown = self.attack_cooldown + 0.2
end

---
-- Draws the enemy. This is a placeholder for debugging.
-- Subclasses should override this with their own animation.
function Enemy:draw()
    love.graphics.push()
    if self.stun_timer > 0 then
        love.graphics.setColor(0.5, 0.5, 1) -- Blue when stunned
    else
        love.graphics.setColor(1, 0.2, 0.2) -- Red otherwise
    end
    love.graphics.rectangle(
        "fill",
        self.x - self.hitboxW / 2,
        self.y - self.hitboxH / 2,
        self.hitboxW,
        self.hitboxH
    )
    love.graphics.pop()
end

return Enemy