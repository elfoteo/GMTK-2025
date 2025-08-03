--- Base class for all living entities in the game that have health
-- and can take damage.
-- @classmod Living

---@class Living
---@field public x number The current x-coordinate.
---@field public y number The current y-coordinate.
---@field public health number The current health of the entity.
---@field public max_health number The maximum health of the entity.
---@field public speed number The movement speed of the entity.
---@field public scene Scene The scene the entity belongs to.
local Living = {}
Living.__index = Living

--- Creates a new Living entity.
---@param scene Scene The scene the entity belongs to.
---@param x number The initial x-coordinate.
---@param y number The initial y-coordinate.
---@param speed number The movement speed.
---@param max_health number? Optional maximum health (defaults to 100).
---@return Living
function Living.new(scene, x, y, speed, max_health)
    local self = setmetatable({}, Living)
    self.scene = scene
    self.x = x or 0
    self.y = y or 0
    self.speed = speed or 0
    self.max_health = max_health or 100
    self.health = self.max_health
    return self
end

---
-- Inflicts damage on the entity.
-- If health drops to zero or below, calls `die`.
-- Subclasses may override but should call this base.
-- @param damage number The amount of damage to inflict.
-- @param source table? The source of the damage (optional).
function Living:take_damage(damage, source)
    if damage <= 0 then return end

    self.health = self.health - damage

    if self.health <= 0 then
        self.health = 0
        self:die(source)
    end
end

---
-- Heals the entity by a given amount, up to max_health.
-- @param amount number The amount to heal.
function Living:heal(amount)
    if amount <= 0 then return end

    self.health = math.min(self.health + amount, self.max_health)
end

-- Handles the death of a living entity
-- Subclasses need to override this
-- @param source table? The source that caused death (optional).
function Living:die(source)
end

---
-- Main update loop. Should be overridden by subclasses.
-- Called once per frame with the elapsed time.
-- @param dt number Time since the last frame.
function Living:update(dt)
    -- Override in subclasses
end

---
-- Draws the entity. Should be overridden by subclasses.
-- Default: draw a simple white square of size 10×10.
function Living:draw()
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 10, 10)
    love.graphics.pop()
end

---
-- Checks if the object is an instance of a given class.
-- @param class table The class to check against.
-- @return boolean True if the object is an instance of the class.
function Living:is(class)
    local mt = getmetatable(self)
    while mt do
        if mt == class or mt.__index == class then
            return true
        end
        if not mt.__index then
            return false
        end
        mt = getmetatable(mt.__index)
    end
    return false
end


return Living
