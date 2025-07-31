-- game/player.lua

local Living      = require("game.living")
local MouseHelper = require("engine.mouse_helper")
local AK47        = require("game.weapons.ak47")
local Viper       = require("game.weapons.tti-viper")
local Animated    = require("engine.animated")

---@class Player : Living
---@field x            number        The x-coordinate of the player.
---@field y            number        The y-coordinate of the player.
---@field speed        number        Movement speed of the player.
---@field size         number        Size of the player (width and height).
---@field vx           number        Current horizontal velocity.
---@field vy           number        Current vertical velocity.
---@field onGround     boolean       Whether the player is standing on solid ground.
---@field weapons WeaponBase[] A list of the player's available weapons.
---@field current_weapon_index number The index of the currently equipped weapon.
---@field animation    Animated      The player's animation.
---@field direction    number        The direction the player is facing.
---@field weapon_y_offset number   The vertical offset for drawing the weapon.
local Player      = setmetatable({}, { __index = Living })
Player.__index    = Player

local GRAVITY     = 450
local JUMP_FORCE  = -220 -- Upward velocity applied when jumping

---Create a new Player.
---@param scene DemoScene The scene the player belongs to.
---@param x     number  Initial x-coordinate.
---@param y     number  Initial y-coordinate.
---@param speed number  Movement speed.
---@return Player       The new player instance.
function Player.new(scene, x, y, speed)
    local p = Living.new(scene, x, y, speed)
    ---@cast p Player
    setmetatable(p, Player)

    p.vx                   = 0
    p.vy                   = 0
    p.onGround             = false
    p.size                 = 8
    p.weapons              = { AK47.new() }
    p.current_weapon_index = 1
    p.direction            = 1
    p.weapon_y_offset      = -4
    p.animation            = Animated:new({
        ["idle"] = {
            images = {
                love.graphics.newImage("assets/entities/player-idle-0.png"),
                love.graphics.newImage("assets/entities/player-idle-1.png")
            },
            delay  = 0.5
        },
        ["walk"] = {
            images = {
                love.graphics.newImage("assets/entities/player-walk-0.png"),
                love.graphics.newImage("assets/entities/player-walk-1.png")
            },
            delay  = 0.2
        }
    })
    p.animation:set_state("idle")

    return p
end

---Switches to the next weapon in the player's inventory.
function Player:switchWeapon()
    self.current_weapon_index = self.current_weapon_index % #self.weapons + 1
end

---Update the player's state: movement, gravity, collision, and shooting.
---@param dt    number     Time since last frame (in seconds).
---@param level TileMap    The current level for collision checks.
---@param particle_system ParticleSystem The particle system of the scene
---@return ProjectileBase?
function Player:update(dt, level, particle_system)
    local dx = 0
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    if dx ~= 0 then
        self.animation:set_state("walk")
        self.direction = dx > 0 and 1 or -1
    else
        self.animation:set_state("idle")
    end
    self.animation:update(dt)

    -- Apply gravity
    self.vy = self.vy + GRAVITY * dt

    -- Jump
    if self.onGround and (love.keyboard.isDown("w", "space")) then
        self.vy       = JUMP_FORCE
        self.onGround = false
    end

    local oldX, oldY = self.x, self.y
    local nextX      = self.x + dx * self.speed * dt
    local nextY      = self.y + self.vy * dt

    local half       = 4 -- Half-width/height of an 8×8 player

    -- Horizontal collision
    if dx ~= 0 then
        if level:checkCollision(nextX - half, self.y - half, half * 2, half * 2) then
            nextX = self.x
        end
    end

    -- Vertical collision
    if self.vy ~= 0 then
        if level:checkCollision(self.x - half, nextY - half, half * 2, half * 2) then
            if self.vy > 0 then
                self.onGround = true
            end
            self.vy = 0
            nextY   = self.y
        else
            self.onGround = false
        end
    end

    -- Apply position and compute actual velocities
    self.x  = nextX
    self.y  = nextY
    self.vx = (self.x - oldX) / dt
    self.vy = (self.y - oldY) / dt
    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 8, 15)

    local proj           = nil
    local current_weapon = self.weapons[self.current_weapon_index]
    -- Shooting
    if current_weapon then
        -- weapon aiming
        local mx, my       = love.mouse.getPosition()
        local cx, cy       = self.scene:toCanvas(mx, my)
        local world_coords = MouseHelper.get_world_coords(self.scene.camera, { x = cx, y = cy })

        current_weapon:update(self.x, self.y + self.weapon_y_offset, world_coords.x, world_coords.y)

        if current_weapon.repeating then
            if love.mouse.isDown(1) then
                proj = current_weapon:shoot(self.x, self.y + self.weapon_y_offset, current_weapon.angle, particle_system,
                    level)
            end
        end
    end

    return proj
end

---@param particle_system ParticleSystem
---@return ProjectileBase|nil
function Player:singleShoot(particle_system)
    local proj           = nil;
    local current_weapon = self.weapons[self.current_weapon_index]
    if current_weapon then
        proj = current_weapon:shoot(self.x, self.y + self.weapon_y_offset, current_weapon.angle, particle_system,
            self.scene.tilemap)
    end
    return proj
end

function Player:draw()
    self.animation:draw(self.x, self.y, 0, self.direction, 1, 8, 12)
end

---Draws the player's currently equipped weapon.
function Player:drawWeapon()
    local current_weapon = self.weapons[self.current_weapon_index]
    if current_weapon then
        current_weapon:draw(self.x, self.y + self.weapon_y_offset)
    end
end

--- Checks for collision between the player and another entity.
---@param other_entity table The other entity to check collision against (must have x, y, width, height properties).
---@return boolean True if a collision occurs, false otherwise.
function Player:checkCollision(other_entity)
    local player_half_width  = 4
    local player_half_height = 4

    local player_left        = self.x - player_half_width
    local player_right       = self.x + player_half_width
    local player_top         = self.y - player_half_height
    local player_bottom      = self.y + player_half_height

    local other_left         = other_entity.x - other_entity.size / 2
    local other_right        = other_entity.x + other_entity.size / 2
    local other_top          = other_entity.y - other_entity.size / 2
    local other_bottom       = other_entity.y + other_entity.size / 2

    return player_left < other_right and
        player_right > other_left and
        player_top < other_bottom and
        player_bottom > other_top
end

---Handles key presses for the player.
---@param key string The key that was pressed.
function Player:keypressed(key)
    if key == "tab" then
        self:switchWeapon()
    end
end

--- Adds a weapon to the player's inventory.
---@param weapon WeaponBase The weapon to add.
function Player:addWeapon(weapon)
    table.insert(self.weapons, weapon)
end

--- Sets the current weapon by its name.
---@param weapon_name string The name of the weapon to set as current.
function Player:setCurrentWeapon(weapon_name)
    for i, weapon in ipairs(self.weapons) do
        if weapon.name == weapon_name then
            self.current_weapon_index = i
            return
        end
    end
end

return Player
