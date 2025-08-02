local Living = require("game.living")
local AnimationHandler = require("game.player.animation_handler")
local CombatHandler = require("game.player.combat_handler")
local MovementHandler = require("game.player.movement_handler")
local RewindHandler = require("game.player.rewind_handler")

---@class Player : Living
---@field x number
---@field y number
---@field speed number
---@field size number
---@field hitboxW number
---@field hitboxH number
---@field vx number
---@field vy number
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
local Player = setmetatable({}, { __index = Living })
Player.__index = Player

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

function Player:update(dt, level, particle_system)
    local wasOnGround = self.onGround
    local wasClimbing = self.isClimbing

    self.movement_handler:update(dt, level, self)
    self.rewind_handler:update(dt, self, particle_system)
    self.animation_handler:update(dt, self, wasClimbing, wasOnGround)

    self.scene.grassManager:apply_force({ x = self.x, y = self.y }, 8, 16)

    self.mana = math.min(100, self.mana + self.mana_regeneration_rate * dt)
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
    self.animation_handler:draw(self.x, self.y, self.direction, self.size)
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:drawProjectiles()
    self.combat_handler:draw()
end

function Player:checkCollision(other)
    local hw, hh = self.hitboxW / 2, self.hitboxH / 2
    local ohw, ohh = other.hitboxW / 2, other.hitboxH / 2
    return (self.x - hw) < (other.x + ohw) and (self.x + hw) > (other.x - ohw) and (self.y - hh) < (other.y + ohh) and
        (self.y + hh) > (other.y - ohh)
end

function Player:keypressed(key)
    self.movement_handler:keypressed(key, self)
    self.rewind_handler:keypressed(key, self)
end

function Player:mousepressed(x, y, button)
    self.combat_handler:mousepressed(x, y, button, self)
end

return Player
