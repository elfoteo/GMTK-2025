---
-- A mechanical melee enemy that patrols and chases the player.
--
-- @description
-- The Cogmauler is a ground-based enemy with a two-state AI. In its "wander"
-- state, it patrols back and forth around its spawn point, occasionally
-- stopping to idle. When the player comes within its detection range, it
-- enters the "chase" state, where it will relentlessly pursue and attempt to
-- attack the player with its wide-swinging claw.
--
-- @classmod Cogmauler

local Enemy = require("game.enemy")
local Animated = require("engine.animated")

---@class Cogmauler : Enemy
---@field animation Animated The animation controller for the Cogmauler.
---@field direction number The direction the Cogmauler is facing (1 for right, -1 for left).
---@field ai_state string The current state of the AI ('wander' or 'chase').
---@field spawn_pos table The {x, y} position where the Cogmauler was spawned.
---@field patrol_dir number The current direction of its patrol movement (1 or -1).
---@field idle_timer number A countdown timer for its idle state.
---@field attack_timer number A countdown timer for its attack cooldown.
---@field has_hit_this_attack boolean A flag to ensure its attack only hits once per animation.
local Cogmauler = setmetatable({}, { __index = Enemy })
Cogmauler.__index = Cogmauler

-- Constants
local HEALTH = 150
local SPEED = 40
local ATTACK_DAMAGE = 25
local DETECTION_RADIUS = 180
local ATTACK_RANGE = 45
local ATTACK_COOLDOWN = 1.5
local PATROL_DISTANCE = 100
local IDLE_CHANCE = 0.01
local IDLE_DURATION = 2.5

-- Animation dimensions
local IDLE_WALK_WIDTH = 90
local ATTACK_WIDTH = 108
local ANIM_HEIGHT = 81

---
-- Creates a new Cogmauler.
-- @param scene Scene The scene the enemy belongs to.
-- @param x number The initial x-coordinate.
-- @param y number The initial y-coordinate.
-- @return Cogmauler
function Cogmauler.new(scene, x, y)
    local cg = Enemy.new(scene, x, y, SPEED, 38, 81) -- Using a tighter hitbox than the full sprite
    setmetatable(cg, Cogmauler)
    ---@cast cg Cogmauler

    cg.health = HEALTH
    cg.max_health = HEALTH
    cg.animation = Animated:new({
        idle = { path_pattern = "assets/entities/cogmauler-idle%d.png", frames = 3, delay = 0.25 },
        walk = { path_pattern = "assets/entities/cogmauler-walk%d.png", frames = 6, delay = 0.15 },
        attack = {
            path_pattern = "assets/entities/cogmauler-attack%d.png",
            frames = 6,
            delay = 0.1,
            loops = false,
            on_complete = function() cg.has_hit_this_attack = false end
        }
    })
    cg.animation:set_state("idle")

    cg.direction = 1
    cg.ai_state = 'wander'
    cg.spawn_pos = { x = x, y = y }
    cg.patrol_dir = 1
    cg.idle_timer = 0
    cg.attack_timer = 0
    cg.has_hit_this_attack = false

    return cg
end

---
-- The main AI state machine for the Cogmauler.
-- @param dt number The time since the last frame.
-- @param player Player The player object.
function Cogmauler:ai(dt, player)
    if self.stun_timer > 0 or self.is_knocked_back then
        -- self.vx is already set by the knockback function, so we just return.
        return
    end

    -- If attacking, lock state until animation is finished
    if self.animation.current_state == 'attack' and not self.animation.is_finished then
        self.vx = 0
        self:update_animation() -- Still need to update the animation timer
        return
    end

    self.attack_timer = math.max(0, self.attack_timer - dt)
    self.idle_timer = math.max(0, self.idle_timer - dt)

    local distance_to_player = math.sqrt((player.x - self.x) ^ 2 + (player.y - self.y) ^ 2)

    -- State transition logic
    if distance_to_player < DETECTION_RADIUS then
        self.ai_state = 'chase'
    elseif distance_to_player > DETECTION_RADIUS * 1.2 then -- Add a buffer to prevent state flickering
        self.ai_state = 'wander'
    end

    if self.ai_state == 'wander' then
        self:wander_state(dt)
    elseif self.ai_state == 'chase' then
        self:chase_state(dt, player, distance_to_player)
    end

    -- Update direction based on velocity
    if self.vx ~= 0 then
        self.direction = self.vx > 0 and 1 or -1
    end

    -- Ledge detection
    local next_x = self.x + self.direction * self.hitboxW / 2
    local ground_check_y = self.y + self.hitboxH / 2 + 1
    if self.on_ground and not self.scene.tilemap:getTileAtPixel(next_x, ground_check_y) then
        self.vx = 0
        self.patrol_dir = -self.patrol_dir -- Turn around at ledges
    end

    self:update_animation()
end

---
-- AI logic for the 'wander' state.
-- @param dt number The time since the last frame.
function Cogmauler:wander_state(dt)
    if self.idle_timer > 0 then
        self.vx = 0
        return
    end

    -- Patrol logic
    self.vx = self.patrol_dir * self.speed
    if math.abs(self.x - self.spawn_pos.x) > PATROL_DISTANCE then
        self.patrol_dir = -self.patrol_dir
    end

    -- Randomly decide to go idle
    if math.random() < IDLE_CHANCE then
        self.idle_timer = IDLE_DURATION
    end
end

---
-- AI logic for the 'chase' state.
-- @param dt number The time since the last frame.
-- @param player Player The player object.
-- @param distance_to_player number The current distance to the player.
function Cogmauler:chase_state(dt, player, distance_to_player)
    if distance_to_player < ATTACK_RANGE and math.abs(player.y - self.y) < 50 then
        -- In attack range
        if self.attack_timer <= 0 then
            -- Ready to attack
            self.vx = 0
            self.animation:set_state('attack')
            self.attack_timer = ATTACK_COOLDOWN
            self.has_hit_this_attack = false
        else
            -- In range, but on cooldown, so wait.
            self.vx = 0
        end
    else
        -- Out of range, so chase
        local chase_dir = player.x > self.x and 1 or -1
        self.vx = chase_dir * self.speed
    end
end

---
-- Updates the current animation based on the enemy's state.
function Cogmauler:update_animation()
    local current_anim = self.animation.current_state
    local next_anim = current_anim

    if current_anim == 'attack' and not self.animation.is_finished then
        -- Let the attack animation finish
        next_anim = 'attack'
    elseif self.vx == 0 then
        next_anim = 'idle'
    else
        next_anim = 'walk'
    end

    if next_anim ~= current_anim then
        self.animation:set_state(next_anim)
    end
    self.animation:update(love.timer.getDelta())
end

---
-- Overrides the base update to include attack logic.
-- @param dt number The time since the last frame.
-- @param player Player The player object.
function Cogmauler:update(dt, player)
    Enemy.update(self, dt, player) -- Calls ai() and update_physics()

    -- Handle attack hitbox logic
    if self.animation.current_state == 'attack' and not self.has_hit_this_attack then
        local frame = self.animation.current_frame
        local should_check_hit = (frame == 5 or frame == 6)

        if should_check_hit then
            local attack_hitbox = {
                x = self.x + (self.direction * 20),
                y = self.y,
                hitboxW = 50,
                hitboxH = 40
            }
            if player:checkCollision(attack_hitbox) then
                player:take_damage(ATTACK_DAMAGE, self)
                self.has_hit_this_attack = true -- Ensure it only hits once
            end
        end
    end
end

---
-- Draws the Cogmauler, handling the offset for the attack animation.
function Cogmauler:draw()
    local offset_x = 0
    local current_anim_name = self.animation.current_state
    local sprite_width = (current_anim_name == 'attack') and ATTACK_WIDTH or IDLE_WALK_WIDTH

    -- The offset is half the difference in width, multiplied by the direction
    -- to ensure the sprite expands outwards from the center.
    if current_anim_name == 'attack' then
        offset_x = (ATTACK_WIDTH - IDLE_WALK_WIDTH) / 2 * self.direction
    end

    local ox = sprite_width / 2
    local oy = ANIM_HEIGHT / 2

    self.animation:draw(self.x + offset_x, self.y, 0, -self.direction, 1, ox, oy)
    self:draw_health_bar()
end

---
-- Overrides the default knockback to give the Cogmauler a heavier feel.
-- @param source table The source of the damage.
function Cogmauler:apply_knockback(source)
    if not self.is_knocked_back then
        local knockback_strength = 20
        local dx = self.x - source.x
        if dx ~= 0 then
            self.vx = (dx / math.abs(dx)) * knockback_strength
        end
        self.vy = -20 -- A much stronger upward hop
        self.is_knocked_back = true
        self.on_ground = false
    end
end

return Cogmauler
