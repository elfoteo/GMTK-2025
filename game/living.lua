---@class Living
---@field x number
---@field y number
---@field speed number
---@field scene DemoScene
local Living = {}
Living.__index = Living

--- Creates a new Living object.
---@param x number The x-coordinate of the living entity.
---@param y number The y-coordinate of the living entity.
---@param speed number The speed of the living entity.
---@return Living
function Living.new(scene, x, y, speed)
    local self = {}
    setmetatable(self, Living)
    self.scene = scene
    self.x = x
    self.y = y
    self.speed = speed
    return self
end

--- Updates the living entity.
---@param dt number The time since the last frame.
function Living:update(dt)
    -- Override in subclasses
end

--- Draws the living entity.
function Living:draw()
    -- Optionally call Renderable:draw(self)
    -- Example:
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 10, 10)
end

--- Converts tile coordinates to absolute pixel coordinates.
---@param tile_x number The x-coordinate in tiles.
---@param tile_y number The y-coordinate in tiles.
---@return number, number The x and y coordinates in pixels.
function Living:tileToAbsolute(tile_x, tile_y)
    local TILE_SIZE = 16 -- Assuming a consistent tile size
    return tile_x * TILE_SIZE, tile_y * TILE_SIZE
end

return Living
