---
-- Base class for all living entities in the game that have health
-- and can take damage.
--
-- @classmod Living

---@class Living
---@field x number The x-coordinate.
---@field y number The y-coordinate.
---@field speed number The base movement speed.
---@field health number The current health.
---@field scene Scene The scene the entity belongs to.
local Living = {}
Living.__index = Living

--- Creates a new Living object.
---@param scene Scene The scene the entity belongs to.
---@param x number The initial x-coordinate.
---@param y number The initial y-coordinate.
---@param speed number The base movement speed.
---@return Living
function Living.new(scene, x, y, speed)
    local self = {}
    setmetatable(self, Living)
    self.scene = scene
    self.x = x
    self.y = y
    self.speed = speed
    self.health = 100
    return self
end

---
-- Inflicts damage on the entity.
-- This is the base implementation and should be extended by subclasses.
-- @param damage number The amount of damage to inflict.
-- @param source table? The source of the damage (optional).
function Living:take_damage(damage, source)
    self.health = self.health - damage
end

---
-- Handles the entity's death.
-- The default behavior is to remove the entity from the scene.
function Living:die()
    if self.scene and self.scene.remove then
        self.scene:remove(self)
    end
end

---
-- Main update loop. Should be overridden by subclasses.
-- @param dt number The time since the last frame.
function Living:update(dt)
    -- Override in subclasses
end

---
-- Draws the entity. Should be overridden by subclasses.
function Living:draw()
    -- Example: Draw a simple white square
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 10, 10)
end

return Living

