local Enemy            = require("game.enemy")
local Animated         = require("engine.animated")

---@class Cogmauler : Enemy
local Cogmauler        = setmetatable({}, { __index = Enemy })
Cogmauler.__index      = Cogmauler

-- Constants
local HEALTH           = 150
local SPEED            = 40
local ATTACK_DAMAGE    = 25
local DETECTION_RADIUS = 180
local ATTACK_RANGE     = 45
local ATTACK_COOLDOWN  = 1.5
local PATROL_DISTANCE  = 300
local IDLE_CHANCE      = 0.001
local IDLE_DURATION    = 2.0
local LEDGE_CHECK_DIST = 10
local WALL_CHECK_DIST  = 5

-- Animation dimensions
local IDLE_WALK_WIDTH  = 90
local ATTACK_WIDTH     = 108
local ANIM_HEIGHT      = 81

function Cogmauler.new(scene, x, y)
    local cg = Enemy.new(scene, x, y, SPEED, 38, 81)
    setmetatable(cg, Cogmauler)
    ---@cast cg Cogmauler

    cg.health             = HEALTH
    cg.max_health         = HEALTH
    cg.animation_locked   = false
    cg.post_attack_freeze = 0
    cg.damage_applied     = false
    cg.tried_frame5       = false
    cg.tried_frame6       = false

    cg.animation          = Animated:new({
        idle = { path_pattern = "assets/entities/cogmauler-idle%d.png", frames = 3, delay = 0.25 },
        walk = { path_pattern = "assets/entities/cogmauler-walk%d.png", frames = 6, delay = 0.15 },
        attack = {
            path_pattern = "assets/entities/cogmauler-attack%d.png",
            frames       = 6,
            delay        = 0.1,
            loops        = false,
            on_complete  = function()
                cg.is_attacking            = false
                cg.post_attack_freeze      = 1.0
                cg.animation_locked        = true
                cg.animation.current_frame = 6
            end
        }
    })
    cg.animation:set_state("idle")

    cg.direction       = 1
    cg.ai_state        = "wander"
    cg.spawn_pos       = { x = x, y = y }
    cg.patrol_dir      = 1
    cg.idle_timer      = 0
    cg.attack_timer    = 0
    cg.is_attacking    = false
    cg.is_knocked_back = false
    cg.knockback_timer = 0
    cg.stun_timer      = 0

    return cg
end

function Cogmauler:ai(dt, player)
    if self.stun_timer > 0 or self.is_knocked_back then
        self:handle_stun_and_knockback(dt)
        return
    end

    if self.post_attack_freeze > 0 then
        self.post_attack_freeze = math.max(0, self.post_attack_freeze - dt)
        if self.post_attack_freeze == 0 then
            self.animation_locked = false
            self.animation:set_state("idle")
        end
        return
    end

    self.attack_timer = math.max(0, self.attack_timer - dt)
    self.idle_timer   = math.max(0, self.idle_timer - dt)

    local dx, dy      = player.x - self.x, player.y - self.y
    local dist        = math.sqrt(dx * dx + dy * dy)
    local ady         = math.abs(dy)

    if self.ai_state == "wander" then
        if dist < DETECTION_RADIUS and ady < 50 then
            self.ai_state = "chase"
        end
    elseif self.ai_state == "chase" then
        if dist > DETECTION_RADIUS * 1.5 or ady > 50 then
            self.ai_state = "wander"
        elseif dist <= ATTACK_RANGE and ady < 50 and self.attack_timer <= 0 then
            self.ai_state = "attack"
        end
    elseif self.ai_state == "attack" then
        if not self.is_attacking then
            self.ai_state = "chase"
        end
    end

    if self.ai_state == "wander" then
        self:wander_state(dt)
    elseif self.ai_state == "chase" then
        self:chase_state(dt, player)
    elseif self.ai_state == "attack" then
        self:attack_state(dt, player)
    end

    if self.vx ~= 0 then
        self.direction = (self.vx > 0) and 1 or -1
    end

    self:check_ledges_and_walls()
    self:update_animation(dt)
end

function Cogmauler:wander_state(dt)
    if self.idle_timer > 0 then
        self.vx = 0
        return
    end

    self.vx = self.patrol_dir * self.speed

    if math.abs(self.x - self.spawn_pos.x) > PATROL_DISTANCE then
        self.patrol_dir = -self.patrol_dir
    end

    if math.random() < IDLE_CHANCE then
        self.idle_timer = IDLE_DURATION
    end
end

function Cogmauler:chase_state(dt, player)
    local dir = (player.x > self.x) and 1 or -1
    self.vx = dir * self.speed
end

function Cogmauler:attack_state(dt, player)
    if not self.is_attacking then
        self.is_attacking     = true
        self.animation_locked = false
        self.damage_applied   = false
        self.tried_frame5     = false
        self.tried_frame6     = false
        self.animation:set_state("attack")
        self.attack_timer = ATTACK_COOLDOWN
        self.vx           = 0
    end
end

function Cogmauler:update_animation(dt)
    if self.animation_locked then
        return
    end

    local state = self.animation.current_state
    local next_state

    if self.is_attacking then
        next_state = "attack"
    elseif self.vx == 0 then
        next_state = "idle"
    else
        next_state = "walk"
    end

    if next_state ~= state then
        self.animation:set_state(next_state)
    end

    self.animation:update(dt)
end

function Cogmauler:update(dt, player)
    Enemy.update(self, dt, player)

    if self.is_attacking and self.animation.current_state == "attack" then
        local frame = self.animation.current_frame

        if frame == 5 and not self.tried_frame5 then
            self.tried_frame5 = true
            if not self.damage_applied then
                local hitbox = {
                    x       = self.x + self.direction * 20,
                    y       = self.y,
                    hitboxW = 50,
                    hitboxH = 40
                }
                if player:checkCollision(hitbox) then
                    player:take_damage(ATTACK_DAMAGE, self)
                    self.damage_applied = true
                end
            end
        end

        if frame == 6 and not self.tried_frame6 then
            self.tried_frame6 = true
            if not self.damage_applied then
                local hitbox = {
                    x       = self.x + self.direction * 20,
                    y       = self.y,
                    hitboxW = 50,
                    hitboxH = 40
                }
                if player:checkCollision(hitbox) then
                    player:take_damage(ATTACK_DAMAGE, self)
                    self.damage_applied = true
                end
            end
        end
    end
end

function Cogmauler:check_ledges_and_walls()
    if not self.on_ground then return end

    local front_x = self.x + self.direction * (self.hitboxW / 2 + LEDGE_CHECK_DIST)
    local ground_y = self.y + self.hitboxH / 2 + 1
    if not self.scene.tilemap:getTileAtPixel(front_x, ground_y) then
        self.vx = 0
        self.patrol_dir = -self.patrol_dir
    end

    local wall_x = self.x + self.direction * (self.hitboxW / 2 + WALL_CHECK_DIST)
    local wall_y = self.y
    if self.scene.tilemap:getTileAtPixel(wall_x, wall_y) then
        self.vx = 0
        self.patrol_dir = -self.patrol_dir
    end
end

function Cogmauler:handle_stun_and_knockback(dt)
    if self.stun_timer > 0 then
        self.stun_timer = math.max(0, self.stun_timer - dt)
        self.vx = 0
    end
    if self.is_knocked_back then
        self.knockback_timer = math.max(0, self.knockback_timer - dt)
        if self.knockback_timer <= 0 then
            self.is_knocked_back = false
        end
    end
end

function Cogmauler:draw()
    local anim = self.animation.current_state
    local width = (anim == "attack") and ATTACK_WIDTH or IDLE_WALK_WIDTH
    local offset = 0
    if anim == "attack" then
        offset = ((ATTACK_WIDTH - IDLE_WALK_WIDTH) / 2) * self.direction
    end
    local ox, oy = width / 2, ANIM_HEIGHT / 2
    self.animation:draw(self.x + offset, self.y, 0, -self.direction, 1, ox, oy)
    self:draw_health_bar()
end

function Cogmauler:apply_knockback(source)
    if not self.is_knocked_back then
        local strength = 200
        local dx = self.x - source.x
        self.vx = (dx ~= 0) and (dx / math.abs(dx)) * strength or 0
        self.vy = -100
        self.is_knocked_back = true
        self.knockback_timer = 0.5
        self.on_ground = false
    end
end

return Cogmauler
