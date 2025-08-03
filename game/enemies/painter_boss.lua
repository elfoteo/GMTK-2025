local Enemy = require("game.enemy")
local Animated = require("engine.animated")
local Paintball = require("game.projectiles.paintball")
local SinePaintball = require("game.projectiles.sine_paintball")

-- Utility: rectangle overlap test
local function rects_overlap(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2
        and x2 < x1 + w1
        and y1 < y2 + h2
        and y2 < y1 + h1
end

---@class PainterBoss : Enemy
---@field animation Animated
---@field direction number
---@field permanently_aggroed boolean
---@field ai_state string
---@field attack_timer number
---@field melee_range number
---@field ranged_range number
---@field has_dealt_damage boolean
---@field hitboxOffsetX number
---@field hitboxOffsetY number
---@field attack_cooldown number
---@field is_teleporting boolean
---@field teleport_alpha number
---@field teleport_target_x number
---@field teleport_target_y number
---@field spawn_x number
---@field spawn_y number
---@field teleport_phase number
---@field has_teleported boolean
---@field original_speed number
---@field original_melee_damage number
---@field enraged boolean

local PainterBoss = setmetatable({}, { __index = Enemy })
PainterBoss.__index = PainterBoss

local SPEED = 40
local AGGRO_DISTANCE = 200
local MELEE_RANGE = 60
local MIN_DISTANCE = 50
local RANGED_RANGE = 150

local IDLE_WALK_WIDTH = 21
local ATTACK_WIDTH = 64
local ANIM_HEIGHT = 25

function PainterBoss.new(scene, x, y)
    local self = Enemy.new(scene, x, y, SPEED, 21, 32)
    setmetatable(self, PainterBoss)
    ---@cast self PainterBoss

    self.health = 1500
    self.max_health = 1500
    self.direction = 1
    self.permanently_aggroed = false
    self.ai_state = "idle"
    self.attack_timer = 0
    self.melee_range = MELEE_RANGE
    self.ranged_range = RANGED_RANGE
    self.has_dealt_damage = false
    self.attack_cooldown = 0
    self.is_teleporting = false
    self.teleport_alpha = 1
    self.teleport_target_x = 0
    self.teleport_target_y = 0
    self.spawn_x = x
    self.spawn_y = y
    self.teleport_phase = 0 -- 0: not teleporting, 1: fading out, 2: fading in
    self.has_teleported = false
    self.original_speed = SPEED
    self.original_melee_damage = 20 -- Assuming 20 is the base melee damage
    self.enraged = false

    -- hitbox offsets to handle larger melee sprite
    self.hitboxOffsetX = 0
    self.hitboxOffsetY = 0

    self.animation = Animated:new({
        idle = {
            path_pattern = "assets/entities/painter-idle%d.png",
            frames = 2,
            delay = 0.5,
        },
        walk = {
            path_pattern = "assets/entities/painter-walking%d.png",
            frames = 4,
            delay = 0.15,
        },
        ["attack-melee"] = {
            path_pattern = "assets/entities/painter-attack-meele%d.png",
            frames = 2,
            delay = 0.2,
            loops = false,
        },
    })
    self.animation:set_state("idle")

    return self
end

function PainterBoss:ai(dt, player)
    if self.is_teleporting then
        if self.teleport_phase == 1 then -- Fading out
            self.teleport_alpha = self.teleport_alpha - dt * 2
            if self.teleport_alpha <= 0 then
                self.x = self.teleport_target_x
                self.y = self.teleport_target_y
                self.teleport_alpha = 0.01 -- Start fade-in from almost 0
                self.teleport_phase = 2
            end
        elseif self.teleport_phase == 2 then -- Fading in
            self.teleport_alpha = self.teleport_alpha + dt * 2
            if self.teleport_alpha >= 1 then
                self.is_teleporting = false
                self.teleport_phase = 0
                self.ai_state = "idle"
                self.animation:set_state("idle")
                self:ranged_attack_spread(player, true)
            end
        end
        return
    end

    local dx = player.x - self.x
    local dy = player.y - self.y
    local distance_to_player = math.sqrt(dx * dx + dy * dy)

    if not self.permanently_aggroed and distance_to_player < AGGRO_DISTANCE then
        self.permanently_aggroed = true
    end

    if self.permanently_aggroed then
        self.attack_timer = self.attack_timer - dt
        self.attack_cooldown = self.attack_cooldown - dt

        if self.ai_state == "melee_attack" then
            if self.animation.is_finished then
                self.ai_state = "idle"
                self.attack_timer = 0.5
            end
        else
            if distance_to_player <= self.melee_range and self.attack_cooldown <= 0 then
                self.ai_state = "melee_attack"
                self.animation:set_state("attack-melee")
                self.has_dealt_damage = false
                self.attack_cooldown = 1
            elseif distance_to_player <= self.ranged_range and self.attack_cooldown <= 0 then
                self.ai_state = "ranged_attack"
                self:choose_ranged_attack(player)
            elseif distance_to_player > MIN_DISTANCE then
                self.ai_state = "chase"
            else
                self.ai_state = "idle"
            end
        end

        if self.ai_state == "chase" then
            self.direction = player.x > self.x and 1 or -1
            self.vx = self.direction * self.speed
            if self.animation.current_state ~= "walk" then
                self.animation:set_state("walk")
            end
        else
            self.vx = 0
            if self.ai_state == "idle" and self.animation.current_state ~= "idle" then
                self.animation:set_state("idle")
            end
        end
    else
        -- still passive
        self.vx = 0
        if self.animation.current_state ~= "idle" then
            self.animation:set_state("idle")
        end
    end

    self.animation:update(dt)

    -- Melee damage on second frame
    if self.animation.current_state == "attack-melee"
        and self.animation.current_frame == 2
        and not self.has_dealt_damage
    then
        local aw, ah = 64, 32
        local ax = self.x + (self.direction * (aw / 2)) - (self.direction * 10)
        local ay = self.y

        if rects_overlap(
                ax - aw / 2, ay, aw, ah,
                player.x - player.hitboxW / 2, player.y - player.hitboxH / 2,
                player.hitboxW, player.hitboxH
            ) then
            player:take_damage(self.original_melee_damage * (self.enraged and 1.20 or 1), self)
            self.has_dealt_damage = true
        end
    end
end

function PainterBoss:update(dt, player)
    if self.attack_cooldown and self.attack_cooldown > 0 then
        self.attack_cooldown = self.attack_cooldown - dt
    end

    -- adjust hitbox based on current animation state
    if self.animation.current_state == "attack-melee" then
        self.hitboxW = 64
        self.hitboxH = 32
        self.hitboxOffsetY = -10
    else
        self.hitboxW = 21
        self.hitboxH = 25
        self.hitboxOffsetY = 3.5
    end

    self:ai(dt, player)
    self:update_physics(dt)

    if self.health <= 0 then
        self:die()
    end
end

function PainterBoss:take_damage(damage, source)
    if self.is_teleporting then
        return -- Invincible during teleport
    end

    local old_health = self.health
    Enemy.take_damage(self, damage, source)
    local lost = old_health - self.health
    if lost > 0 then
        self.scene:create_health_bar_particle(lost)
    end

    if not self.has_teleported and self.health <= self.max_health / 2 then
        self.has_teleported = true
        self:teleport(self.spawn_x, self.spawn_y)
    end

    if not self.enraged and self.health <= self.max_health / 2 then
        self.enraged = true
        self.speed = self.speed * 1.20 -- 20% quicker movement
        -- Melee damage is applied in ai function, will adjust there
    end
end

function PainterBoss:choose_ranged_attack(player)
    local attack_type = math.random(1, 2)
    if attack_type == 1 then
        self:ranged_attack_spread(player)
    else
        self:ranged_attack_sine(player)
    end
end

function PainterBoss:ranged_attack_spread(player, after_teleport)
    if not after_teleport then
        if self.animation.current_state ~= "idle" then
            self.animation:set_state("idle")
        end
        self.attack_cooldown = 3
        return
    end

    for i = 1, 20 do
        local angle = (i / 20) * 2 * math.pi
        local proj = Paintball.new(self.x, self.y, 150, angle)
        table.insert(self.scene.enemy_projectiles, proj)
    end
end

function PainterBoss:ranged_attack_sine(player)
    if self.animation.current_state ~= "idle" then
        self.animation:set_state("idle")
    end
    self.attack_cooldown = 2
    local angle_to_player = math.atan2(player.y - self.y, player.x - self.x)
    for i = -1, 1 do
        local angle = angle_to_player + i * 0.2
        local proj = SinePaintball.new(self.x, self.y, 150, angle, 15, 8)
        table.insert(self.scene.enemy_projectiles, proj)
    end
end

function PainterBoss:teleport(x, y)
    self.is_teleporting = true
    self.teleport_alpha = 1
    self.teleport_target_x = x
    self.teleport_target_y = y
    self.teleport_phase = 1
end

function PainterBoss:draw()
    if self.is_teleporting then
        love.graphics.setColor(1, 1, 1, self.teleport_alpha)
    end
    local anim = self.animation.current_state
    local width = (anim == "attack-melee") and ATTACK_WIDTH or IDLE_WALK_WIDTH
    local offset = 0
    if anim == "attack-melee" then
        offset = ((ATTACK_WIDTH - IDLE_WALK_WIDTH) / 2) * self.direction
    end
    local ox, oy = width / 2, ANIM_HEIGHT / 2
    self.animation:draw(self.x + offset, self.y, 0, self.direction, 1, ox, oy)
    love.graphics.setColor(1, 1, 1, 1)
end

return PainterBoss
