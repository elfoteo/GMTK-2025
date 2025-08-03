-- game/enemies/waiterbot.lua
local Enemy = require("game.enemy")
local Animated = require("engine.animated")
local Fork = require("game.projectiles.cutlery.fork")
local Knife = require("game.projectiles.cutlery.knife")
local Spoon = require("game.projectiles.cutlery.spoon")

---@class WaiterBot : Enemy
---@field animation Animated
---@field direction number
---@field patrol_center_x number
---@field patrol_radius number
---@field ai_state string
---@field idle_timer number
---@field attack_timer number
---@field detection_range number
---@field optimal_distance number
---@field reposition_buffer number
local WaiterBot = setmetatable({}, { __index = Enemy })
WaiterBot.__index = WaiterBot

local SPEED = 30

function WaiterBot.new(scene, x, y)
    local self = Enemy.new(scene, x, y, SPEED, 21, 32)
    setmetatable(self, WaiterBot)
    ---@cast self WaiterBot
    self.health = 30
    self.max_health = 30

    self.animation = Animated:new({
        walk = {
            path_pattern = "assets/entities/waiterbot-walk%d.png",
            frames = 4,
            delay = 0.15,
        },
        idle = {
            path_pattern = "assets/entities/waiterbot-idle%d.png",
            frames = 2,
            delay = 0.5,
        },
        attack = {
            path_pattern = "assets/entities/waiterbot-attack%d.png",
            frames = 2,
            delay = 0.1,
            loops = false,
        }
    })
    self.animation:set_state("walk")

    self.direction = 1
    self.patrol_center_x = x
    self.patrol_radius = 100
    self.ai_state = "patrol"
    self.idle_timer = 0
    self.attack_timer = 0
    self.cutlery_phase = 0
    self.detection_range = 150
    self.disengage_range = 200 -- Hysteresis: Must be larger than detection_range
    self.optimal_distance = 50
    self.reposition_buffer = 100

    return self
end

function WaiterBot:ai(dt, player)
    if self.stun_timer > 0 or self.is_knocked_back then
        self.vx = 0
        return
    end

    local distance_to_player = math.sqrt((player.x - self.x) ^ 2 + (player.y - self.y) ^ 2)

    -- State transitions with hysteresis
    if self.ai_state == "patrol" then
        if distance_to_player <= self.detection_range and self.on_ground and math.abs(player.y - self.y) < 50 then
            self.ai_state = "attack"
        end
    elseif self.ai_state == "attack" then
        if distance_to_player > self.disengage_range or math.abs(player.y - self.y) > 100 then
            self.ai_state = "patrol"
        end
    end

    -- State logic
    if self.ai_state == "patrol" then
        if self.idle_timer > 0 then
            self.idle_timer = self.idle_timer - dt
            self.vx = 0
            self.animation:set_state("idle")
        else
            if self.animation.current_state ~= "walk" then
                self.animation:set_state("walk")
            end
            if math.random() < 0.01 then
                self.idle_timer = math.random(1, 3)
            end

            if self.x > self.patrol_center_x + self.patrol_radius then
                self.direction = -1
            elseif self.x < self.patrol_center_x - self.patrol_radius then
                self.direction = 1
            end

            -- Ledge detection
            local nextX = self.x + self.direction * self.hitboxW / 2
            local groundCheckY = self.y + self.hitboxH / 2 + 1
            if not self.scene.tilemap:getTileAtPixel(nextX, groundCheckY) then
                self.direction = -self.direction
            end

            self.vx = self.direction * self.speed
        end
    elseif self.ai_state == "attack" then
        if math.abs(distance_to_player - self.optimal_distance) > self.reposition_buffer then
            -- Move to optimal distance
            if self.animation.current_state ~= "walk" then
                self.animation:set_state("walk")
            end

            if distance_to_player < self.optimal_distance then
                -- Too close, move away from player
                self.direction = player.x > self.x and -1 or 1
            else
                -- Too far, move towards player
                self.direction = player.x > self.x and 1 or -1
            end
            self.vx = self.direction * self.speed
        else
            -- At optimal distance, so stop and attack
            self.vx = 0
            -- Face the player
            self.direction = player.x > self.x and 1 or -1

            self.attack_timer = self.attack_timer - dt

            if self.attack_timer <= 0 then
                if self.cutlery_phase < 3 then
                    self.animation:set_state("attack")
                    self:throw_cutlery(player)
                    self.cutlery_phase = self.cutlery_phase + 1
                    self.attack_timer = 0.1 -- short delay between throws
                else
                    self.cutlery_phase = 0
                    self.attack_timer = 1.5 -- cooldown after 3 throws
                end
            else
                if self.animation.is_finished then
                    self.animation:set_state("idle")
                end
            end
        end
    end

    self.animation:update(dt)
end

function WaiterBot:throw_cutlery(player)
    local speed = 400
    local gravity = -90 -- Must match projectile gravity
    local dx = player.x - self.x
    local dy = player.y - self.y

    local discriminant = speed ^ 4 - gravity * (gravity * dx ^ 2 + 2 * dy * speed ^ 2)

    local angle
    if discriminant >= 0 then
        -- Use the lower trajectory for a more direct shot
        local tan_theta = (speed ^ 2 - math.sqrt(discriminant)) / (gravity * dx)
        angle = math.atan(tan_theta)
        if dx < 0 then
            angle = angle + math.pi
        end
    else
        -- Target is out of range for a ballistic shot, fire directly
        angle = math.atan2(dy, dx)
    end

    local inaccuracy = math.rad(math.random(-5, 5))
    angle = angle + inaccuracy

    local projectile_type = math.random(1, 3)
    local projectile
    if projectile_type == 1 then
        projectile = Fork.new(self.x, self.y, speed, angle)
    elseif projectile_type == 2 then
        projectile = Knife.new(self.x, self.y, speed, angle)
    else
        projectile = Spoon.new(self.x, self.y, speed, angle)
    end

    table.insert(self.scene.enemy_projectiles, projectile)
end

function WaiterBot:draw()
    local ox = self.hitboxW / 2
    local oy = self.hitboxH / 2
    self.animation:draw(self.x, self.y, 0, self.direction, 1, ox, oy)
    self:draw_health_bar()
end

return WaiterBot
