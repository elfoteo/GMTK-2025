---@class Wall
---@field x number
---@field y number
---@field w number
---@field h number
local Wall = {}
Wall.__index = Wall

--- Creates a new Wall object.
---@param x number The x-coordinate of the wall.
---@param y number The y-coordinate of the wall.
---@param w number The width of the wall.
---@param h number The height of the wall.
---@return Wall
function Wall.new(x, y, w, h)
    local wall = setmetatable({}, Wall)
    wall.x = x
    wall.y = y
    wall.w = w
    wall.h = h
    return wall
end

--- Draws the wall.
function Wall:draw()
    love.graphics.push()
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.pop()
end

return Wall