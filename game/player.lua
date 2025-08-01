local Living              = require("game.living")
local Animated            = require("engine.animated")
local ClockHandProjectile = require("game.projectiles.clock-hand_projectile")
local SparkParticle       = require("engine.particles.spark_particle")

---@class Player : Living
---@field x            number        The x-coordinate of the player.
---@field y            number        The y-coordinate of the player.
---@field speed        number        Movement speed of the player.
---@field size         number        The visual size of the player sprite.
---@field hitboxW      number        The width of the collision hitbox.
---@field hitboxH      number        The height of the collision hitbox.
---@field vx           number        Current horizontal velocity.
---@field vy           number        Current vertical velocity.
---@field onGround     boolean       Whether the player is standing on solid ground.
---@field isClimbing   boolean       Whether the player is climbing.
---@field animation    Animated      The player's animation.
---@field direction    number        The direction the player is facing (1 or -1).
---@field projectiles  table         The projectiles shot by the player.
local Player              = setmetatable({}, { __index = Living })
Player.__index            = Player

-- Physics constants
local GRAVITY             = 450
local JUMP_FORCE          = -180 -- Upward velocity applied when jumping

---Create a new Player.
---@param scene MainScene     The scene the player belongs to.
---@param x     number        Initial x-coordinate.
---@param y     number        Initial y-coordinate.
---@param speed number        Movement speed.
---@return Player             The new player instance.
function Player.new(scene, x, y, speed)
    -- base Living constructor sets x, y, speed, etc.
    local p = Living.new(scene, x, y, speed)
    ---@cast p Player
    setmetatable(p, Player)

    -- Physics state
    p.vx          = 0
    p.vy          = 0
    p.onGround    = false
    p.isClimbing  = false

    -- Sizing
    p.size        = 26 -- Visual size
    p.hitboxW     = 16 -- Collision width
    p.hitboxH     = 26 -- Collision height

    -- Facing: 1 = right, -1 = left
    p.direction   = 1

    p.projectiles = {}

    -- Animation setup
    p.animation   = Animated:new({
        idle = {
            path_pattern = "assets/entities/player-idle%d.png",
            frames = 4,
            delay  = 0.4,
        },
        walk = {
            path_pattern = "assets/entities/player-walk%d.png",
            frames = 4,
            delay  = 0.1,
        },
        jump_start = {
            path_pattern = "assets/entities/player-jump-start%d.png",
            frames = 2,
            delay = 0.2,
            loops = false,
            on_complete = function() p.animation:set_state("jump_fall") end
        },
        jump_fall = {
            path_pattern = "assets/entities/player-jump-start%d.png",
            frames = 2,
            delay = 0.2,
        },
        jump_end = {
            path_pattern = "assets/entities/player-jump-end%d.png",
            frames = 5,
            delay = 0.08,
            loops = false,
            on_complete = function() p.animation:set_state("idle") end
        },
        attack = {
            path_pattern = "assets/entities/player-attack%d.png",
            frames = 4,
            delay = 0.05,
            loops = false,
            on_complete = function() p.animation:set_state("idle") end
        },
        climb_idle = {
            images = {
                love.graphics.newImage("assets/entities/player-climbing1.png"),
            },
            delay = 0.1,
        },
        climb = {
            path_pattern = "assets/entities/player-walk%d.png",
            frames = 4,
            delay = 0.1,
        },
        turn_to_climb = {
            path_pattern = "assets/entities/player-turning%d.png",
            frames = 14,
            delay = 0.02,
            loops = false,
            on_complete = function() p.animation:set_state("climbing") end
        },
        climbing = {
            path_pattern = "assets/entities/player-climbing%d.png",
            frames = 8,
            delay = 0.1,
        },
        descending = {
            images = {
                love.graphics.newImage("assets/entities/player-climbing8.png"),
                love.graphics.newImage("assets/entities/player-climbing7.png"),
                love.graphics.newImage("assets/entities/player-climbing6.png"),
                love.graphics.newImage("assets/entities/player-climbing5.png"),
                love.graphics.newImage("assets/entities/player-climbing4.png"),
                love.graphics.newImage("assets/entities/player-climbing3.png"),
                love.graphics.newImage("assets/entities/player-climbing2.png"),
                love.graphics.newImage("assets/entities/player-climbing1.png"),
            },
            delay = 0.1,
        },
        turn_from_climb = {
            images = {
                love.graphics.newImage("assets/entities/player-turning14.png"),
                love.graphics.newImage("assets/entities/player-turning13.png"),
                love.graphics.newImage("assets/entities/player-turning12.png"),
                love.graphics.newImage("assets/entities/player-turning11.png"),
                love.graphics.newImage("assets/entities/player-turning10.png"),
                love.graphics.newImage("assets/entities/player-turning9.png"),
                love.graphics.newImage("assets/entities/player-turning8.png"),
                love.graphics.newImage("assets/entities/player-turning7.png"),
                love.graphics.newImage("assets/entities/player-turning6.png"),
                love.graphics.newImage("assets/entities/player-turning5.png"),
                love.graphics.newImage("assets/entities/player-turning4.png"),
                love.graphics.newImage("assets/entities/player-turning3.png"),
                love.graphics.newImage("assets/entities/player-turning2.png"),
                love.graphics.newImage("assets/entities/player-turning1.png"),
            },
            delay = 0.02,
            loops = false,
            on_complete = function() p.animation:set_state("idle") end
        }
    })
    p.animation:set_state("idle")

    return p
end

---Update the player's state: movement, gravity, collision, and grass-force.
---@param dt               number            Time since last frame (in seconds).
---@param level            TileMap           The current level for collision checks.
---@param particle_system  ParticleSystem    (unused here) placeholder for future shooting/particles.
function Player:update(dt, level, particle_system)
    -- Input
    local dx = 0
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    local dy = 0
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end

    local jump_pressed = love.keyboard.isDown("space")

    -- Update animation timer
    self.animation:update(dt)

    -- Climbing logic
    local onClimbable = level:getTileAtPixel(self.x, self.y) and level:getTileAtPixel(self.x, self.y).climbable or
        level:getTileAtPixel(self.x, self.y + self.hitboxH * 0.7) and
        level:getTileAtPixel(self.x, self.y + self.hitboxH * 0.7).climbable

    if onClimbable and not self.isClimbing and dy ~= 0 then
        self.isClimbing = true
    elseif self.isClimbing and not onClimbable then
        self.isClimbing = false
    end

    -- Physics and movement
    if self.isClimbing then
        self.vy = dy * self.speed
        self.onGround = false
        self.hitboxW = 12
    else
        self.vy = self.vy + GRAVITY * dt
        self.hitboxW = 16
    end

    if self.onGround and jump_pressed and not self.isClimbing then
        self.vy = JUMP_FORCE
        self.onGround = false
    end

    local oldX, oldY = self.x, self.y
    local halfW = self.hitboxW / 2
    local halfH = self.hitboxH / 2

    self.x = self.x + dx * self.speed * dt
    if dx ~= 0 then
        if level:checkCollision(self.x - halfW, self.y - halfH, self.hitboxW, self.hitboxH) then
            self.x = oldX
        end
    end

    local wasOnGround = self.onGround
    self.y = self.y + self.vy * dt
    if self.vy ~= 0 then
        if level:checkCollision(self.x - halfW, self.y - halfH, self.hitboxW, self.hitboxH) then
            if self.vy > 0 then
                self.onGround = true
            end
            self.y = oldY
            self.vy = 0
        else
            self.onGround = false
        end
    end

    -- Animation state machine
    local next_anim
    local current_anim = self.animation.current_state

    if current_anim == "attack" and not self.animation.is_finished then
        next_anim = "attack"
    elseif current_anim == "turn_to_climb" and not self.animation.is_finished then
        next_anim = "turn_to_climb"
    elseif current_anim == "turn_from_climb" and not self.animation.is_finished then
        next_anim = "turn_from_climb"
    elseif self.isClimbing then
        if dy < 0 then
            next_anim = "climbing"
        elseif dy > 0 then
            next_anim = "descending"
        else
            next_anim = "climb_idle"
        end
    elseif not self.onGround then
        if self.vy < 0 then
            next_anim = "jump_start"
        else
            next_anim = "jump_fall"
        end
    elseif not wasOnGround and self.onGround then
        next_anim = "jump_end"
    else
        if dx == 0 then
            next_anim = "idle"
        else
            next_anim = "walk"
        end
    end

    if next_anim and next_anim ~= current_anim then
        self.animation:set_state(next_anim)
    end

    if dx ~= 0 then
        self.direction = dx > 0 and 1 or -1
    end

    self.vx = (self.x - oldX) / dt
    self.vy = (self.y - oldY) / dt

    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 8, 16)
end

function Player:updateProjectiles(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y,
                                  world_max_y)
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        local hitResult = p:update(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y,
            world_max_y)
        if hitResult then
            self.scene:handleBulletCollision(hitResult)
            table.remove(self.projectiles, i)
        end
    end
end

---Draw the player, always centered on its (x,y) regardless of facing.
function Player:draw()
    -- Center the sprite on its midpoint so flipping doesn’t shift it
    local ox = self.size / 2
    local oy = self.size / 2
    -- sx = direction (1 or -1), sy = 1
    self.animation:draw(self.x, self.y, 0, self.direction, 1, ox, oy)
end

function Player:drawProjectiles()
    for _, p in ipairs(self.projectiles) do
        p:draw()
    end
end

---Simple AABB collision check against another entity.
---@param other_entity table The other entity (must have x, y, size).
---@return boolean True if overlapping.
function Player:checkCollision(other_entity)
    local halfW     = self.hitboxW / 2
    local halfH     = self.hitboxH / 2
    local halfOther = other_entity.size / 2

    return
        (self.x - halfW) < (other_entity.x + halfOther) and
        (self.x + halfW) > (other_entity.x - halfOther) and
        (self.y - halfH) < (other_entity.y + halfOther) and
        (self.y + halfH) > (other_entity.y - halfOther)
end

---Handle discrete keypresses.
---@param key string
function Player:keypressed(key)
    if key == "e" then
        -- e.g. interact with doors, levers, NPCs…
    end
end

function Player:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        self.animation:set_state("attack")
        local angle = math.atan2(y - 216 / 2, x - 384 / 2)
        local projectile = ClockHandProjectile.new(self.x, self.y, 400, angle)
        table.insert(self.projectiles, projectile)

        self.scene.particleSystem:emitCone(
            self.x,
            self.y,
            angle,
            0.8,
            15,
            { 50, 150 },
            { 0.1, 0.3 },
            { 1, 1, 1, 1 },
            SparkParticle,
            0.6
        )
    end
end

return Player
