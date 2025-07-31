-- engine/crosshair.lua

---@class Crosshair
---@field image love.Image     -- The crosshair image.
---@field width number         -- Width of the image (in pixels).
---@field height number        -- Height of the image (in pixels).
---@field scale number         -- Optional scale factor when drawing.
local Crosshair = {}
Crosshair.__index = Crosshair

---Creates a new Crosshair.
---@param imagePath string      -- Path to the crosshair image (e.g. "assets/gui/crosshair.png").
---@param scale? number         -- Optional scale factor (defaults to 1).
---@return Crosshair
function Crosshair.new(imagePath, scale)
    local self  = setmetatable({}, Crosshair)
    self.image  = love.graphics.newImage(imagePath)
    self.width  = self.image:getWidth()
    self.height = self.image:getHeight()
    self.scale  = scale or 1
    return self
end

---Draws the crosshair centered at the given canvas coordinates.
---@param x number              -- X coordinate (canvas space) to center the crosshair.
---@param y number              -- Y coordinate (canvas space) to center the crosshair.
function Crosshair:draw(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        self.image,
        x, y,             -- position
        0,                -- rotation
        self.scale,       -- scaleX
        self.scale,       -- scaleY
        self.width * 0.5, -- originX (center)
        self.height * 0.5 -- originY (center)
    )
end

return Crosshair
