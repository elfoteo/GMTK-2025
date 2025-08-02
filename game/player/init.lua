local Living = require("game.living")
local AnimationHandler = require("game.player.animation_handler")
local CombatHandler = require("game.player.combat_handler")
local MovementHandler = require("game.player.movement_handler")
local RewindHandler = require("game.player.rewind_handler")

--- The main player character.
--- This class is responsible for managing the player's state, including movement,
--- combat, animations, and special abilities like rewinding time. It aggregates
--- several handlers to delegate specific logic.
---@class Player : Living
---@field x number The player's x-coordinate.
---@field y number The player's y-coordinate.
---@field speed number The base movement speed of the player.
---@field size number The visual size of the player sprite.
---@field hitboxW number The width of the player's collision hitbox.
---@field hitboxH number The height of the player's collision hitbox.
---@field vx number The player's current velocity on the x-axis.
---@field vy number The player's current velocity on the y-axis.
---@field onGround boolean True if the player is currently standing on solid ground.
---@field isClimbing boolean True if the player is currently on a climbable surface.
---@field direction number The direction the player is facing (1 for right, -1 for left).
---@field lastDownPressTime number The timestamp of the last time the down key was pressed, for platform drop-through logic.
---@field dropThrough boolean True if the player is currently intentionally falling through a platform.
---@field fall_distance number The distance the player has fallen, used for calculating fall damage.
---@field mana number The player's current mana, used for special abilities.
---@field mana_regeneration_rate number The rate at which the player regenerates mana per second.
---@field animation_handler AnimationHandler The handler for the player's animations.
---@field combat_handler CombatHandler The handler for the player's combat logic.
---@field movement_handler MovementHandler The handler for the player's movement physics.
---@field rewind_handler RewindHandler The handler for the player's time rewind ability.
local Player = setmetatable({}, { __index = Living })
Player.__index = Player

--- Creates a new Player instance.
---@param scene MainScene The main scene object that contains the player.
---@param x number The initial x-coordinate for the player.
---@param y number The initial y-coordinate for the player.
---@param speed number The movement speed for the player.
---@return Player The new player instance.
function Player.new(scene, x, y, speed)
    local p = Living.new(scene, x, y, speed)
    setmetatable(p, Player)
    ---@cast p Player
    p.vx, p.vy = 0, 0
    p.onGround = false
    p.isClimbing = false
    p.size = 26
    p.hitboxW, p.hitboxH = 16, 26
    p.direction = 1
    p.lastDownPressTime = 0
    p.dropThrough = false
    p.fall_distance = 0
    p.mana = 0
    p.mana_regeneration_rate = 10 -- Mana per second

    p.animation_handler = AnimationHandler:new(p)
    p.combat_handler = CombatHandler:new()
    p.movement_handler = MovementHandler
    p.rewind_handler = RewindHandler:new()

    return p
end

--- Updates the player's state for the current frame.
--- This calls the update methods of all the player's handlers.
---@param dt number The time elapsed since the last frame (delta time).
---@param level TileMap The level's tilemap for collision detection.
---@param particle_system ParticleSystem The main particle system for creating effects.
function Player:update(dt, level, particle_system)
    local wasOnGround = self.onGround
    local wasClimbing = self.isClimbing

    self.movement_handler:update(dt, level, self)
    self.rewind_handler:update(dt, self, particle_system)
    self.animation_handler:update(dt, self, wasClimbing, wasOnGround)

    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 8, 16)

    self.mana = math.min(100, self.mana + self.mana_regeneration_rate * dt)
end

--- Updates the state of all projectiles fired by the player.
---@param dt number The time elapsed since the last frame (delta time).
---@param particleSystem ParticleSystem The main particle system for creating effects.
---@param tilemap TileMap The level's tilemap for collision detection.
---@param enemies Enemy[] A table containing all active enemies.
---@param world_min_x number The minimum x-boundary of the world.
---@param world_max_x number The maximum x-boundary of the world.
---@param world_min_y number The minimum y-boundary of the world.
---@param world_max_y number The maximum y-boundary of the world.
function Player:updateProjectiles(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y,
                                  world_max_y)
    self.combat_handler:update(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y,
        self.scene)
end

--- Draws the player on the screen.
--- Applies a transparency effect if the player is currently rewinding.
function Player:draw()
    if self.rewind_handler.is_rewinding then
        love.graphics.setColor(1, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    self.animation_handler:draw(self.x, self.y, self.direction, self.size)
    love.graphics.setColor(1, 1, 1, 1)
end

--- Draws all projectiles fired by the player.
function Player:drawProjectiles()
    self.combat_handler:draw()
end

--- Checks for AABB collision between the player and another object.
---@param other Living The other object to check for collision against.
---@return boolean True if the hitboxes are overlapping.
function Player:checkCollision(other)
    local hw, hh = self.hitboxW / 2, self.hitboxH / 2
    local ohw, ohh = other.hitboxW / 2, other.hitboxH / 2
    return (self.x - hw) < (other.x + ohw) and (self.x + hw) > (other.x - ohw) and (self.y - hh) < (other.y + ohh) and
        (self.y + hh) > (other.y - ohh)
end

--- Handles key press events for the player.
---@param key string The key that was pressed.
function Player:keypressed(key)
    self.movement_handler:keypressed(key, self)
    self.rewind_handler:keypressed(key, self)
end

--- Handles mouse press events for the player.
---@param x number The x-coordinate of the mouse press.
---@param y number The y-coordinate of the mouse press.
---@param button number The mouse button that was pressed.
function Player:mousepressed(x, y, button)
    self.combat_handler:mousepressed(x, y, button, self)
end

return Player