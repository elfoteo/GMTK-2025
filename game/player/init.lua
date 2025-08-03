local Living = require("game.living")
local AnimationHandler = require("game.player.animation_handler")
local CombatHandler = require("game.player.combat_handler")
local MovementHandler = require("game.player.movement_handler")
local RewindHandler = require("game.player.rewind_handler")
local SceneManager = require("engine.scene_manager")
local SparkParticle = require("engine.particles.spark_particle")
local loveTimer = require("love.timer")

---@class Player : Living
---@field x number
---@field y number
---@field speed number
---@field size number
---@field hitboxW number
---@field hitboxH number
---@field vx number
---@field vy number
---@field dash_vx number
---@field onGround boolean
---@field isClimbing boolean
---@field direction number
---@field lastDownPressTime number
---@field dropThrough boolean
---@field fall_distance number
---@field mana number
---@field mana_regeneration_rate number
---@field animation_handler AnimationHandler
---@field combat_handler CombatHandler
---@field movement_handler MovementHandler
---@field rewind_handler RewindHandler
---@field touch_damage_cooldown number
---@field is_dashing boolean
---@field dash_timer number
---@field dash_direction number
---@field dash_speed number
---@field dash_cost number
---@field lastLeftPressTime number
---@field lastRightPressTime number
---@field doubleTapThreshold number
---@field is_stunned boolean
---@field stun_timer number
local Player = setmetatable({}, { __index = Living })
Player.__index = Player

function Player.new(scene, x, y, speed)
    local p = Living.new(scene, x, y, speed)
    setmetatable(p, Player)
    ---@cast p Player
    p.vx, p.vy = 0, 0
    p.dash_vx = 0
    p.onGround = false
    p.isClimbing = false
    p.size = 26
    p.hitboxW, p.hitboxH = 16, 26
    p.direction = 1
    p.lastDownPressTime = 0
    p.dropThrough = false
    p.fall_distance = 0
    p.mana = 0
    p.mana_regeneration_rate = 10
    p.touch_damage_cooldown = 0

    p.is_dashing = false
    p.dash_timer = 0
    p.dash_direction = 0
    p.dash_speed = 400
    p.dash_cost = 5

    -- double-tap dash tracking
    p.lastLeftPressTime = 0
    p.lastRightPressTime = 0
    p.doubleTapThreshold = 0.25

    p.is_healing = false
    p.healing_timer = 0
    p.levitation_offset = 0

    p.is_stunned = false
    p.stun_timer = 0

    p.animation_handler = AnimationHandler:new(p)
    p.combat_handler = CombatHandler:new()
    p.movement_handler = MovementHandler
    p.rewind_handler = RewindHandler:new()

    return p
end

function Player:update(dt, level, particle_system)
    if self.is_healing then
        self:update_healing(dt, particle_system)
        return
    end

    if self.is_stunned then
        self.stun_timer = self.stun_timer - dt
        if self.stun_timer <= 0 then
            self.is_stunned = false
        end
        -- Only prevent movement, don't set vx/vy to 0 here to allow for natural falling/sliding
        return
    end

    local wasOnGround = self.onGround
    local wasClimbing = self.isClimbing

    self.touch_damage_cooldown = math.max(0, self.touch_damage_cooldown - dt)

    self:update_dash(dt, particle_system)
    self.movement_handler:update(dt, level, self)
    self.rewind_handler:update(dt, self, particle_system)
    self.animation_handler:update(dt, self, wasClimbing, wasOnGround)

    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 8, 16)

    self.mana = math.min(100, self.mana + self.mana_regeneration_rate * dt)
end

function Player:heal(amount)
    self.health = math.min(100, self.health + amount)
end

function Player:startHealing(duration)
    if not self.is_healing then
        self.is_healing = true
        self.healing_timer = duration
    end
end

function Player:update_healing(dt, particle_system)
    if not self.is_healing then return end

    self.healing_timer = self.healing_timer - dt
    self.vx, self.vy = 0, 0

    local health_to_restore = (100 / 1.5) * dt
    self:heal(health_to_restore)

    local levitation_duration = 0.3
    local total_duration = 1.5
    local max_levitation = -5
    if self.healing_timer > total_duration - levitation_duration then
        local progress = (total_duration - self.healing_timer) / levitation_duration
        self.levitation_offset = progress * max_levitation
    elseif self.healing_timer < levitation_duration then
        local progress = self.healing_timer / levitation_duration
        self.levitation_offset = progress * max_levitation
    else
        self.levitation_offset = max_levitation
    end

    local fade_duration = 0.1
    if self.healing_timer > total_duration - fade_duration then
        self.scene.ui.alpha = (total_duration - self.healing_timer) / fade_duration
    elseif self.healing_timer < fade_duration then
        self.scene.ui.alpha = 1 - (self.healing_timer / fade_duration)
    else
        self.scene.ui.alpha = 0
    end
    self.scene.ui.alpha = 1 - self.scene.ui.alpha

    for _ = 1, 3 do
        local angle = math.random() * 2 * math.pi
        local speed = 20 + math.random() * 20
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        local lifespan = 0.4 + math.random() * 0.4
        particle_system:emit(self.x, self.y, vx, vy, lifespan, { 1, 0.5, 0 }, SparkParticle, 0.5)
    end

    if self.healing_timer <= 0 then
        self.is_healing = false
        self.health = 100
        self.scene.ui.alpha = 1
        self.levitation_offset = 0
    end
end

function Player:update_dash(dt, particle_system)
    if self.is_dashing then
        self.dash_timer = self.dash_timer - dt
        local decay = self.dash_timer / 0.2
        self.dash_vx = self.dash_speed * self.dash_direction * decay

        local base_angle = (self.dash_direction == 1) and math.pi or 0
        for _ = 1, 2 do
            local y_pos = self.y - self.hitboxH / 2 + math.random() * self.hitboxH
            local angle = base_angle + (math.random() - 0.5) * 0.8
            local speed = 50 + math.random() * 50
            local vx = math.cos(angle) * speed
            local vy = math.sin(angle) * speed
            local lifespan = 0.1 + math.random() * 0.2
            particle_system:emit(self.x, y_pos, vx, vy, lifespan, { 1, 1, 1 }, SparkParticle, 0.6)
        end

        if self.dash_timer <= 0 then
            self.is_dashing = false
            self.dash_vx = 0
        end
    end
end

function Player:take_damage(damage, source)
    if self.is_dashing then
        return -- Ignore damage while dashing
    end
    Living.take_damage(self, damage)
    self.is_stunned = true
    self.stun_timer = 0.1
    self.combat_handler:interrupt_combo() -- Interrupt combo
    if self.health <= 0 then
        SceneManager.gotoScene(require("scenes.death_scene").new())
    end
end

function Player:updateProjectiles(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y,
                                  world_max_y)
    self.combat_handler:update(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y,
        self.scene)
end

function Player:draw()
    if self.rewind_handler.is_rewinding then
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    self.animation_handler:draw(self.x, self.y + self.levitation_offset, self.direction, self.size)

    local clock_center = self.animation_handler:get_current_clock_hand_center()
    if clock_center then
        local health_ratio = self.health / 100
        local total_minutes = (1 - health_ratio) * 12 * 60
        local hours = math.floor(total_minutes / 60)
        local minutes = total_minutes % 60

        local minute_angle = (minutes / 60) * 2 * math.pi - math.pi / 2
        local hour_angle = ((hours % 12 + minutes / 60) / 12) * 2 * math.pi - math.pi / 2

        local cx = self.x - self.size / 2 + clock_center.x
        local cy = self.y - self.size / 2 + clock_center.y + self.levitation_offset

        if self.animation_handler.clock_hand_color then
            love.graphics.setColor(self.animation_handler.clock_hand_color)
        end

        local ml, hl = 7, 5
        local mdx, mdy = ml * math.cos(minute_angle), ml * math.sin(minute_angle)
        local points = {}
        for i = 0, ml do
            local t = i / ml
            table.insert(points, cx + mdx * t)
            table.insert(points, cy + mdy * t)
        end
        love.graphics.points(points)

        local hdx, hdy = hl * math.cos(hour_angle), hl * math.sin(hour_angle)
        local hpoints = {}
        for i = 0, hl do
            local t = i / hl
            table.insert(hpoints, cx + hdx * t)
            table.insert(hpoints, cy + hdy * t)
        end
        love.graphics.points(hpoints)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Player:drawProjectiles()
    self.combat_handler:draw()
end

function Player:checkCollision(other)
    local hw, hh = self.hitboxW / 2, self.hitboxH / 2
    local ohw, ohh = other.hitboxW / 2, other.hitboxH / 2
    return (self.x - hw) < (other.x + ohw)
        and (self.x + hw) > (other.x - ohw)
        and (self.y - hh) < (other.y + ohh)
        and (self.y + hh) > (other.y - ohh)
end

function Player:keypressed(key)
    if self.is_stunned then return end
    local now = loveTimer.getTime()

    if (key == "lshift" or key == "rshift")
        and self.mana >= self.dash_cost
        and not self.is_dashing
        and not self.isClimbing
    then
        self.mana = self.mana - self.dash_cost
        self.is_dashing = true
        self.dash_timer = 0.2
        self.dash_direction = self.direction
    end

    if key == "left" or key == "a" then
        if now - self.lastLeftPressTime <= self.doubleTapThreshold
            and self.mana >= self.dash_cost
            and not self.is_dashing
            and not self.isClimbing
        then
            self.mana = self.mana - self.dash_cost
            self.is_dashing = true
            self.dash_timer = 0.2
            self.dash_direction = -1
        end
        self.lastLeftPressTime = now
    elseif key == "right" or key == "d" then
        if now - self.lastRightPressTime <= self.doubleTapThreshold
            and self.mana >= self.dash_cost
            and not self.is_dashing
            and not self.isClimbing
        then
            self.mana = self.mana - self.dash_cost
            self.is_dashing = true
            self.dash_timer = 0.2
            self.dash_direction = 1
        end
        self.lastRightPressTime = now
    end

    self.movement_handler:keypressed(key, self)
    self.rewind_handler:keypressed(key, self)
end

function Player:mousepressed(x, y, button)
    if self.is_stunned then return end
    self.combat_handler:mousepressed(x, y, button, self)
end

return Player
