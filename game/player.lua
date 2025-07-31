-- game/player.lua

local Living              = require("game.living")
local Animated            = require("engine.animated")
local ClockHandProjectile = require("game.projectiles.clock-hand_projectile")

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
            images = {
                love.graphics.newImage("assets/entities/player-idle1.png"),
                love.graphics.newImage("assets/entities/player-idle2.png"),
                love.graphics.newImage("assets/entities/player-idle3.png"),
                love.graphics.newImage("assets/entities/player-idle4.png"),
            },
            delay  = 0.4,
        },
        walk = {
            images = {
                love.graphics.newImage("assets/entities/player-walk1.png"),
                love.graphics.newImage("assets/entities/player-walk2.png"),
                love.graphics.newImage("assets/entities/player-walk3.png"),
                love.graphics.newImage("assets/entities/player-walk4.png"),
            },
            delay  = 0.1,
        },
        jump_start = {
            images = {
                love.graphics.newImage("assets/entities/player-jump-start1.png"),
                love.graphics.newImage("assets/entities/player-jump-start2.png"),
            },
            delay = 0.2,
            loops = false,
            on_complete = function() p.animation:set_state("jump_fall") end
        },
        jump_fall = {
            images = {
                love.graphics.newImage("assets/entities/player-jump-start2.png"),
            },
            delay = 0.2,
        },
        jump_end = {
            images = {
                love.graphics.newImage("assets/entities/player-jump-end1.png"),
                love.graphics.newImage("assets/entities/player-jump-end2.png"),
                love.graphics.newImage("assets/entities/player-jump-end3.png"),
                love.graphics.newImage("assets/entities/player-jump-end4.png"),
                love.graphics.newImage("assets/entities/player-jump-end5.png"),
            },
            delay = 0.08,
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

    -- Animation state & facing
    self.animation:update(dt)

    -- Apply gravity
    self.vy = self.vy + GRAVITY * dt

    -- Jump
    if self.onGround and love.keyboard.isDown("w", "space") then
        self.vy       = JUMP_FORCE
        self.onGround = false
        self.animation:set_state("jump_start")
    end

    -- Compute tentative positions
    local oldX, oldY = self.x, self.y
    local nextX      = self.x + dx * self.speed * dt
    local nextY      = self.y + self.vy * dt
    local halfW      = self.hitboxW / 2
    local halfH      = self.hitboxH / 2

    -- Horizontal collision
    if self.animation.current_state ~= "jump_end" then
        if dx ~= 0 then
            if level:checkCollision(nextX - halfW, self.y - halfH, self.hitboxW, self.hitboxH) then
                nextX = self.x
                if self.onGround then self.animation:set_state("idle") end
            else
                if self.onGround then self.animation:set_state("walk") end
                self.direction = dx > 0 and 1 or -1
            end
        else
            if self.onGround then self.animation:set_state("idle") end
        end
    end

    -- Vertical collision
    local wasOnGround = self.onGround
    if self.vy ~= 0 then
        if level:checkCollision(self.x - halfW, nextY - halfH, self.hitboxW, self.hitboxH) then
            if self.vy > 0 then
                self.onGround = true
                if not wasOnGround then
                    self.animation:set_state("jump_end")
                end
            end
            self.vy = 0
            nextY = self.y
        else
            self.onGround = false
        end
    end

    -- Apply final position and compute actual velocities
    self.x  = nextX
    self.y  = nextY
    self.vx = (self.x - oldX) / dt
    self.vy = (self.y - oldY) / dt

    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 16, 22)
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
        local angle = math.atan2(y - 216 / 2, x - 384 / 2)
        print(angle, y, x)
        local projectile = ClockHandProjectile.new(self.x, self.y, 400, angle)
        table.insert(self.projectiles, projectile)
    end
end

return Player
