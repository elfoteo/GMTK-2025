---
-- An advanced enemy that can vanish and attack from a distance.
--
-- @description
-- The SandWraith is a complex enemy with multiple AI states. It attempts to
-- maintain an optimal distance from the player. When ready, it will stop,
-- perform an attack animation, and then vanish into a cloud of sand. While
-- vanished, it is immune to damage and will launch waves of sand particles
-- at the player before reappearing.
--
-- @classmod SandWraith

local Enemy = require("game.enemy")
local Animated = require("engine.animated")
local SandParticle = require("engine.particles.sand_particle")

---@class SandWraith : Enemy
---@field animation Animated The animation controller for the SandWraith.
---@field direction number The direction the SandWraith is facing (1 for right, -1 for left).
---@field wanderTimer number A timer for controlling how long it wanders in one direction.
---@field aiState string The current state of the AI state machine.
---@field isVanished boolean True if the SandWraith is currently vanished and untargetable.
---@field detectionRange number The maximum distance at which it will engage the player.
---@field optimalDistance number The ideal distance it tries to keep from the player.
---@field repositionBuffer number A margin of error for its optimal distance.
---@field vanishDuration number How long the vanish effect lasts.
---@field vanishTimer number A countdown timer for the vanish effect.
---@field attackCooldownDuration number The base time between attacks.
---@field attackCooldownTimer number A countdown timer for the next available attack.
---@field attackWaveCount number Tracks how many waves of sand have been shot during an attack.
---@field timeSinceLastWave number Tracks time during the multi-wave attack.
local SandWraith = setmetatable({}, { __index = Enemy })
SandWraith.__index = SandWraith

-- Constants
local SPEED = 20

---
-- Creates a new SandWraith.
-- @param scene Scene The scene the enemy belongs to.
-- @param x number The initial x-coordinate.
-- @param y number The initial y-coordinate.
-- @return SandWraith
function SandWraith.new(scene, x, y)
    -- Note: Hitbox dimensions are passed directly to the base Enemy constructor.
    local sw = Enemy.new(scene, x, y, SPEED, 48, 56)
    setmetatable(sw, SandWraith)
    ---@cast sw SandWraith

    sw.animation = Animated:new({
        idle = {
            images = {
                love.graphics.newImage("assets/entities/sandwraith-idle1.png"),
                love.graphics.newImage("assets/entities/sandwraith-idle2.png"),
                love.graphics.newImage("assets/entities/sandwraith-idle3.png"),
            },
            delay = 0.2,
        },
        attack = {
            images = {
                love.graphics.newImage("assets/entities/sandwraith-attack1.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack2.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack3.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack4.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack5.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack6.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack7.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack8.png"),
                love.graphics.newImage("assets/entities/sandwraith-attack9.png"),
            },
            delay = 0.1,
            loops = false,
        }
    })
    sw.animation:set_state("idle")

    sw.direction = 1
    sw.wanderTimer = 0

    -- AI State Management
    sw.aiState = "wandering" -- Can be: "wandering", "engaging", "attacking"
    sw.isVanished = false

    -- AI Parameters
    sw.detectionRange = 200
    sw.optimalDistance = 150
    sw.repositionBuffer = 20

    -- Attack Timers & Counters
    sw.vanishDuration = 2.2
    sw.vanishTimer = 0
    sw.attackCooldownDuration = 2
    sw.attackCooldownTimer = sw.attackCooldownDuration
    sw.attackWaveCount = 0
    sw.timeSinceLastWave = 0
    sw.vanishParticleTimer = 0
    sw.vanishParticleCounter = 0
    sw.attack_cast_timer = 0

    return sw
end

---
-- Overrides the base take_damage to add an attack interruption mechanic.
-- @param damage number The amount of damage to inflict.
-- @param source table The source of the damage (e.g., the player).
function SandWraith:take_damage(damage, source)
    -- Call the parent take_damage to apply stun, knockback, etc.
    Enemy.take_damage(self, damage, source)

    -- If hit while casting (in the attack animation, before vanishing), interrupt it.
    if self.aiState == "attacking" and not self.isVanished then
        self.aiState = "engaging"        -- Force back to engaging/cooldown state
        self.animation:set_state("idle") -- Reset the animation
        -- The base take_damage already adds to the cooldown.
    end
end

---
-- AI logic for moving to a better position relative to the player.
-- @param dt number The time since the last frame.
-- @param player Player The player object.
-- @param distanceToPlayer number The current distance to the player.
function SandWraith:reposition(dt, player, distanceToPlayer)
    if distanceToPlayer < self.optimalDistance - self.repositionBuffer then
        -- Too close, move away
        self.direction = player.x > self.x and -1 or 1
    else
        -- Too far, move closer
        self.direction = player.x > self.x and 1 or -1
    end
    self.vx = self.direction * self.speed
end

---
-- AI logic for wandering around when the player is not nearby.
-- @param dt number The time since the last frame.
function SandWraith:wander(dt)
    self.wanderTimer = self.wanderTimer - dt
    if self.wanderTimer <= 0 then
        self.direction = math.random(0, 1) == 0 and -1 or 1
        self.wanderTimer = math.random(2, 5)
    end
    self.vx = self.direction * self.speed
end

---
-- The main AI state machine for the SandWraith.
-- @param dt number The time since the last frame.
-- @param player Player The player object.
function SandWraith:ai(dt, player)
    -- Do not run AI if stunned or knocked back
    if self.stun_timer > 0 or self.is_knocked_back then
        return
    end

    -- Update timers
    self.vanishTimer = math.max(0, self.vanishTimer - dt)
    self.attackCooldownTimer = math.max(0, self.attackCooldownTimer - dt)
    self.timeSinceLastWave = self.timeSinceLastWave + dt
    self.vanishParticleTimer = self.vanishParticleTimer - dt

    local distanceToPlayer = math.sqrt((player.x - self.x) ^ 2 + (player.y - self.y) ^ 2)

    -- State: Attacking
    if self.aiState == "attacking" then
        self.vx = 0 -- Stand still while attacking
        self.attack_cast_timer = self.attack_cast_timer + dt

        if self.attack_cast_timer >= 0.2 and self.vanishParticleCounter == 0 and not self.isVanished then
            self.vanishParticleCounter = 2500 -- Set number of particles to spawn
        end

        if not self.isVanished and self.animation.is_finished then
            -- Animation finished, now vanish and spawn particles
            self.isVanished = true
            self.vanishTimer = self.vanishDuration
            self.timeSinceLastWave = 0 -- Reset timer for wave timing
        elseif self.isVanished then
            -- Spawn vanish particles over time
            if self.vanishParticleCounter > 0 and self.vanishParticleTimer <= 0 then
                for _ = 1, 50 do -- 50 particles per frame
                    -- X velocity from a short-range normal distribution
                    local xvel = love.math.randomNormal(16, 0)

                    -- Y velocity from a linear (uniform) distribution, favoring upward motion
                    local yvel = love.math.randomNormal(20, 0) - 40

                    self.scene.particleSystem:emit(self.x, self.y, xvel, yvel, 2, nil, SandParticle)
                    self.vanishParticleCounter = self.vanishParticleCounter - 1
                end

                self.vanishParticleTimer = 0.016 -- Spawn next batch in 1 frame
            end
            -- Handle wave shooting while vanished
            if self.attackWaveCount < 3 and self.timeSinceLastWave >= 0.6 * (self.attackWaveCount + 1) then
                self:shootSandWave(player)
                self.attackWaveCount = self.attackWaveCount + 1
            end

            if self.vanishTimer <= 0 then
                -- Vanish time is over, go back to engaging
                self.isVanished = false
                self.aiState = "engaging"
                self.attackCooldownTimer = self.attackCooldownDuration
                self.animation:set_state("idle")
                self.attackWaveCount = 0
                self.timeSinceLastWave = 0
                self.attack_cast_timer = 0
            end
        end
        -- States: Wandering or Engaging
    else
        if distanceToPlayer > self.detectionRange then
            self.aiState = "wandering"
            self:wander(dt)
        else -- in detection range
            self.aiState = "engaging"
            if self.attackCooldownTimer <= 0 then
                -- Ready to attack, transition to attacking state
                self.aiState = "attacking"
                self.animation:set_state("attack")
                self.vx = 0 -- Stop to attack
            else
                -- On cooldown, so reposition
                if math.abs(distanceToPlayer - self.optimalDistance) < self.repositionBuffer then
                    self.vx = 0                                   -- In position, so wait
                else
                    self:reposition(dt, player, distanceToPlayer) -- Out of position, so move
                end
            end
        end
    end

    -- Ledge detection (applied regardless of state to prevent falling)
    local nextX = self.x + self.direction * self.hitboxW / 2
    local groundCheckY = self.y + self.hitboxH / 2 + 1
    if not self.scene.tilemap:getTileAtPixel(nextX, groundCheckY) then
        self.direction = -self.direction
        self.wanderTimer = 0 -- Recalculate wander direction if we hit a ledge
    end

    self.animation:update(dt)
end

---
-- Draws the SandWraith's animation.
function SandWraith:draw()
    if self.isVanished then
        return -- Completely invisible
    end
    local ox = self.hitboxW / 2
    local oy = self.hitboxH / 2
    self.animation:draw(self.x, self.y, 0, self.direction, 1, ox, oy)
    self:draw_health_bar()
end

---
-- Shoots a wave of sand particles at the player.
-- @param player Player The player to target.
function SandWraith:shootSandWave(player)
    local ps_emit = self.scene.particleSystem.emit
    local base_x = self.x + (self.hitboxW / 2) * self.direction
    local base_y = self.y
    local hitboxH = self.hitboxH

    local angle_to_player = math.atan2(player.y - self.y, player.x - self.x)

    for _ = 1, 500 do -- Increased sand amount
        -- Random angle variation (-0.2 to 0.2)
        local angle = angle_to_player + (math.random() * 0.4 - 0.2)
        local speed = math.random(150, 250)

        local dx = math.cos(angle) * speed
        local dy = math.sin(angle) * speed

        -- Random vertical offset
        local spawn_y = base_y - (hitboxH * math.random())

        ps_emit(self.scene.particleSystem, base_x, spawn_y, dx, dy, 3, nil, SandParticle)
    end
end

return SandWraith
