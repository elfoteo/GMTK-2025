local Living = require("game.living")
local AnimationHandler = require("game.player.animation_handler")
local CombatHandler = require("game.player.combat_handler")
local MovementHandler = require("game.player.movement_handler")
local RewindHandler = require("game.player.rewind_handler")
local SceneManager = require("engine.scene_manager")
local SparkParticle = require("engine.particles.spark_particle")

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
---@field dash_vx number The player's current dash velocity on the x-axis.
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
---@field touch_damage_cooldown number A cooldown to prevent taking damage every frame from the same source.
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
    p.mana_regeneration_rate = 10 -- Mana per second
    p.touch_damage_cooldown = 0
    p.is_dashing = false
    p.dash_timer = 0
    p.dash_direction = 0
    p.dash_speed = 400
    p.dash_cost = 10

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

    self.touch_damage_cooldown = math.max(0, self.touch_damage_cooldown - dt)

    self:update_dash(dt, particle_system)
    self.movement_handler:update(dt, level, self)
    self.rewind_handler:update(dt, self, particle_system)
    self.animation_handler:update(dt, self, wasClimbing, wasOnGround)

    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 8, 16)

    self.mana = math.min(100, self.mana + self.mana_regeneration_rate * dt)
end

function Player:update_dash(dt, particle_system)
    if self.is_dashing then
        self.dash_timer = self.dash_timer - dt
        local dash_decay = (self.dash_timer / 0.2) -- a 0-1 value
        self.dash_vx = self.dash_speed * self.dash_direction * dash_decay

        -- Emit particles throughout the dash
        local particle_angle = (self.dash_direction == 1) and math.pi or 0
        particle_system:emitCone(
            self.x, self.y,
            particle_angle,
            0.4, 2, { 50, 100 }, { 0.1, 0.3 },
            {1, 1, 1}, SparkParticle, 0.6
        )

        if self.dash_timer <= 0 then
            self.is_dashing = false
            self.dash_vx = 0
        end
    end
end

--- Inflicts damage on the player and checks for death.
---@param damage number The amount of damage to inflict.
---@param source Living The object that is the source of the damage.
function Player:take_damage(damage, source)
    Living.take_damage(self, damage)
    if self.health <= 0 then
        SceneManager.gotoScene(require("scenes.death_scene").new())
    end
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
    if (key == "lshift" or key == "rshift") and self.mana >= self.dash_cost and not self.is_dashing then
        self.mana = self.mana - self.dash_cost
        self.is_dashing = true
        self.dash_timer = 0.2
        self.dash_direction = self.direction
    end
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
