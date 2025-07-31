---@class Button
---@field x number
---@field y number
---@field width number
---@field height number
---@field isHovered boolean
---@field isPressed boolean
---@field isActive boolean
local Button = {}
Button.__index = Button

function Button.new(x, y, width, height)
    local self = setmetatable({}, Button)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.isHovered = false
    self.isPressed = false
    self.isActive = false
    return self
end

function Button:update(dt, mouse_x, mouse_y)
    self.isHovered = mouse_x > self.x and mouse_x < self.x + self.width
        and mouse_y > self.y and mouse_y < self.y + self.height
    self.isActive = self.isPressed and self.isHovered
end

function Button:mousepressed(button)
    if button == 1 and self.isHovered then
        self.isPressed = true
        self.isActive = true
    end
end

function Button:mousereleased(button)
    local clicked = false
    if button == 1 and self.isHovered and self.isPressed then
        clicked = true
    end
    self.isPressed = false
    self.isActive = false
    return clicked
end

function Button:draw()
    -- Base button does not draw anything
end

return Button
