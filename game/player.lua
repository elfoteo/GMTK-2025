local Living              = require("game.living")
local Animated            = require("engine.animated")
local ClockHandProjectile = require("game.projectiles.clock-hand_projectile")
local SparkParticle       = require("engine.particles.spark_particle")

---@class Player : Living
---@field x            number
---@field y            number
---@field speed        number
---@field size         number
---@field hitboxW      number
---@field hitboxH      number
---@field vx           number
---@field vy           number
---@field onGround     boolean
---@field isClimbing   boolean
---@field animation    Animated
---@field direction    number
---@field projectiles  table
---@field lastAttackTime number
---@field secondLastAttackTime number
local Player              = setmetatable({}, { __index = Living })
Player.__index            = Player

local GRAVITY             = 450
local JUMP_FORCE          = -180
local REWIND_SECONDS      = 4
local HISTORY_INTERVAL    = 0.1

function Player.new(scene, x, y, speed)
    local p = Living.new(scene, x, y, speed)
    setmetatable(p, Player)

    p.vx, p.vy             = 0, 0
    p.onGround             = false
    p.isClimbing           = false
    p.size                 = 26
    p.hitboxW, p.hitboxH   = 16, 26
    p.direction            = 1
    p.projectiles          = {}
    p.lastAttackTime       = nil
    p.secondLastAttackTime = nil
    p.lastDownPressTime    = 0
    p.dropThrough          = false
    p.history              = {}
    p.history_timer        = 0
    p.fall_distance        = 0

    p.animation            = Animated:new({
        idle = { images = {}, path_pattern = "assets/entities/player-idle%d.png", frames = 4, delay = 0.4 },
        walk = { images = {}, path_pattern = "assets/entities/player-walk%d.png", frames = 4, delay = 0.1 },
        jump_start = {
            images = {},
            path_pattern = "assets/entities/player-jump-start%d.png",
            frames = 2,
            delay = 0.2,
            loops = false,
            on_complete = function() p.animation:set_state("jump_fall") end
        },
        jump_fall = { images = {}, path_pattern = "assets/entities/player-jump-start%d.png", frames = 2, delay = 0.2 },
        jump_end = {
            images = {},
            path_pattern = "assets/entities/player-jump-end%d.png",
            frames = 5,
            delay = 0.08,
            loops = false,
            on_complete = function() p.animation:set_state("idle") end
        },
        attack = {
            images = {},
            path_pattern = "assets/entities/player-attack%d.png",
            frames = 4,
            delay = 0.05,
            loops = false,
            on_complete = function() p.animation:set_state("idle") end
        },
        climb_idle = {
            images = { love.graphics.newImage("assets/entities/player-climbing1.png") },
            delay = 0.1,
        },
        climb = { images = {}, path_pattern = "assets/entities/player-walk%d.png", frames = 4, delay = 0.1 },
        turn_to_climb = {
            images = {},
            path_pattern = "assets/entities/player-turning%d.png",
            frames = 14,
            delay = 0.02,
            loops = false,
            on_complete = function() p.animation:set_state("climb_idle") end
        },
        climbing = { images = {}, path_pattern = "assets/entities/player-climbing%d.png", frames = 8, delay = 0.1 },
        descending = {
            images = {},
            path_pattern = "assets/entities/player-climbing%d.png",
            frames = 8,
            delay = 0.1,
            reversed_pattern = true
        },
        turn_from_climb = {
            images = {},
            path_pattern = "assets/entities/player-turning%d.png",
            frames = 14,
            delay = 0.02,
            loops = false,
            reversed_pattern = true,
            on_complete = function() p.animation:set_state("idle") end
        },
    })
    p.animation:set_state("idle")

    return p
end

function Player:update(dt, level, particle_system)
    self.history_timer = self.history_timer + dt
    if self.history_timer >= HISTORY_INTERVAL then
        self.history_timer = 0
        local state = {
            x = self.x,
            y = self.y,
            vx = self.vx,
            vy = self.vy,
            health = self.health,
            timestamp = love.timer.getTime()
        }
        table.insert(self.history, state)
        -- Keep history at a manageable size, assuming 60fps
        if #self.history > (REWIND_SECONDS / HISTORY_INTERVAL) * 1.5 then
            table.remove(self.history, 1)
        end
    end

    local dx = 0
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    local dy = 0
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end

    local jump_pressed = love.keyboard.isDown("space")
    self.animation:update(dt)

    local wasClimbing = self.isClimbing
    local tile_top    = level:getTileAtPixel(self.x, self.y)
    local tile_bottom = level:getTileAtPixel(self.x, self.y + self.hitboxH * 0.7)
    local onClimbable = (tile_top and tile_top.climbable) or (tile_bottom and tile_bottom.climbable)

    -- Enter or exit climbing
    if onClimbable and not self.isClimbing and dy ~= 0 then
        self.isClimbing = true
        local snap_tile = (tile_bottom and tile_bottom.climbable and tile_bottom)
            or (tile_top and tile_top.climbable and tile_top)
        if snap_tile then
            self.x = snap_tile.x + level.tile_size / 2
        end
    elseif self.isClimbing and not onClimbable then
        self.isClimbing = false
    end

    if self.isClimbing then
        -- If climbing up but nothing above, stop climbing
        if dy < 0 then
            local tile = level:getTileAtPixel(self.x, self.y + self.hitboxH * 0.5)
            if not (tile and tile.climbable) then
                self.isClimbing = false
            end
        end

        if self.isClimbing then
            self.vy          = dy * self.speed
            self.onGround    = false
            self.hitboxW     = 12

            local tile_below = level:getTileAtPixel(self.x, self.y + self.hitboxH / 2 + 1)
            if (not tile_below or not tile_below.climbable) and dx ~= 0 then
                self.isClimbing = false
            end
        end
    end

    if not self.isClimbing then
        self.vy = self.vy + GRAVITY * dt
        self.hitboxW = (tile_bottom and tile_bottom.climbable) and 17 or 16
        if not self.onGround then
            self.fall_distance = self.fall_distance + self.vy * dt
        end
    else
        self.fall_distance = 0
    end

    if self.onGround and jump_pressed and not self.isClimbing then
        self.vy       = JUMP_FORCE
        self.onGround = false
    end

    local oldX, oldY = self.x, self.y
    local halfW, halfH = self.hitboxW / 2, self.hitboxH / 2

    if not self.isClimbing then
        self.x = self.x + dx * self.speed * dt
        if dx ~= 0 and level:checkCollision(self.x - halfW, self.y - halfH, self.hitboxW, self.hitboxH) then
            self.x = oldX
        end
    end

    local wasOnGround = self.onGround
    self.y = self.y + self.vy * dt

    if self.vy ~= 0 then
        local ignorePlatforms = self.dropThrough
        local collided = level:checkCollision(self.x - halfW, self.y - halfH, self.hitboxW, self.hitboxH, ignorePlatforms)

        if collided then
            if self.vy > 0 then
                self.onGround = true
                if self.fall_distance > 5 * level.tile_size then
                    local damage = math.floor((self.fall_distance - 5 * level.tile_size) / level.tile_size) * 10
                    self:take_damage(damage)
                end
                self.fall_distance = 0
            end
            self.y = oldY
            self.vy = 0
        else
            self.onGround = false
        end
    end

    if self.dropThrough and self.onGround then
        self.dropThrough = false
    end

    -- Animation state logic (unchanged) ...
    local next_anim
    local current_anim = self.animation.current_state

    if current_anim == "attack" and not self.animation.is_finished then
        next_anim = "attack"
    elseif current_anim == "turn_to_climb" and not self.animation.is_finished then
        next_anim = "turn_to_climb"
    elseif current_anim == "turn_from_climb" and not self.animation.is_finished then
        next_anim = "turn_from_climb"
    elseif self.isClimbing then
        if not wasClimbing then
            next_anim = "turn_to_climb"
        elseif dy < 0 then
            next_anim = "climbing"
        elseif dy > 0 then
            next_anim = "descending"
        else
            next_anim = "climb_idle"
        end
    elseif wasClimbing and not self.isClimbing then
        next_anim = "turn_from_climb"
    elseif not self.onGround then
        next_anim = (self.vy < 0) and "jump_start" or "jump_fall"
    elseif not wasOnGround and self.onGround then
        next_anim = "jump_end"
    else
        next_anim = (dx == 0) and "idle" or "walk"
    end

    if next_anim and next_anim ~= current_anim then
        self.animation:set_state(next_anim)
    end

    if dx ~= 0 and not self.isClimbing then
        self.direction = (dx > 0) and 1 or -1
    end

    self.vx = (self.x - oldX) / dt
    self.vy = (self.y - oldY) / dt

    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 8, 16)
end

function Player:rewind()
    local now = love.timer.getTime()
    local target_time = now - REWIND_SECONDS
    local best_state = nil

    for i = #self.history, 1, -1 do
        local state = self.history[i]
        if state.timestamp <= target_time then
            best_state = state
            break
        end
    end

    if best_state then
        self.x = best_state.x
        self.y = best_state.y
        self.vx = best_state.vx
        self.vy = best_state.vy
        self.health = best_state.health
        -- Clear future history
        for i = #self.history, 1, -1 do
            if self.history[i].timestamp > best_state.timestamp then
                table.remove(self.history, i)
            end
        end
    end
end

function Player:updateProjectiles(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y,
                                  world_max_y)
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        local hitResult = p:update(dt, particleSystem, tilemap, enemies,
            world_min_x, world_max_x, world_min_y, world_max_y)
        if hitResult then
            local ignore_hit = hitResult.type == "enemy" and hitResult.enemy and hitResult.enemy.isVanished
            if not ignore_hit then
                self.scene:handleBulletCollision(hitResult, p)
                table.remove(self.projectiles, i)
            end
        end
    end
end

function Player:draw()
    local ox, oy = self.size / 2, self.size / 2
    self.animation:draw(self.x, self.y, 0, self.direction, 1, ox, oy)
end

function Player:drawProjectiles()
    for _, p in ipairs(self.projectiles) do p:draw() end
end

function Player:checkCollision(other)
    local hw, hh = self.hitboxW / 2, self.hitboxH / 2
    local ohw, ohh = other.hitboxW / 2, other.hitboxH / 2
    return
        (self.x - hw) < (other.x + ohw) and
        (self.x + hw) > (other.x - ohw) and
        (self.y - hh) < (other.y + ohh) and
        (self.y + hh) > (other.y - ohh)
end

function Player:keypressed(key)
    if key == "s" or key == "down" then
        local now = love.timer.getTime()
        if now - self.lastDownPressTime < 0.25 then
            local tileBelow = self.scene.tilemap:getTileAtPixel(self.x, self.y + self.hitboxH + 1)
            if tileBelow and tileBelow.platform then
                self.dropThrough = true
            end
        end
        self.lastDownPressTime = now
    elseif key == "r" then
        self:rewind()
    end
end

function Player:mousepressed(x, y, button)
    if button == 1 then
        if self.isClimbing and (love.keyboard.isDown("w", "up") or love.keyboard.isDown("s", "down")) then
            return
        end

        local now = love.timer.getTime()

        -- Enforce 0.25s cooldown
        if self.lastAttackTime and (now - self.lastAttackTime < 0.25) then
            return
        end

        -- Determine if this attack should shoot 3 projectiles
        local shootTriple = false
        if self.lastAttackTime and self.secondLastAttackTime then
            local t1 = self.secondLastAttackTime
            local t2 = self.lastAttackTime
            if (t2 - t1 <= 0.6) and (now - t2 <= 0.6) then
                shootTriple = true
            end
        end

        -- Cancel climbing on shoot
        if self.isClimbing then
            self.isClimbing = false
            self.vy = 0
            self.onGround = false
        end

        self.animation:set_state("attack")
        local angle = math.atan2(y - 216 / 2, x - 384 / 2)

        if shootTriple then
            local spread = math.rad(2)
            for _, a in ipairs({ angle - spread, angle, angle + spread }) do
                local proj = ClockHandProjectile.new(self.x, self.y, 400, a)
                table.insert(self.projectiles, proj)
            end
            -- Reset combo state after triple shot
            self.lastAttackTime = nil
            self.secondLastAttackTime = nil
        else
            local proj = ClockHandProjectile.new(self.x, self.y, 400, angle)
            table.insert(self.projectiles, proj)

            -- Only update timers after a regular shot
            self.secondLastAttackTime = self.lastAttackTime
            self.lastAttackTime = now
        end

        self.scene.particleSystem:emitCone(
            self.x, self.y, angle, 0.8, 15,
            { 50, 150 }, { 0.1, 0.3 }, { 1, 1, 1, 1 },
            SparkParticle, 0.6
        )
    end
end

return Player
