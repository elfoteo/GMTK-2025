---@class Tile
---@field x number
---@field y number
---@field image love.Image
---@field image_path string
---@field collides boolean
---@field leafs boolean
---@field grass number
---@field quad love.Quad
local Tile = {}
Tile.__index = Tile

--- Creates a new Tile object.
---@param x number The x-coordinate of the tile.
---@param y number The y-coordinate of the tile.
---@param image love.Image The image of the tile.
---@param image_path string The path to the image file.
---@param collides boolean Whether the tile is collidable.
---@param quad love.Quad An optional quad to use for drawing.
---@param leafs boolean Whether the tile emits leafs.
---@param grass number The number of grass blades to spawn.
---@return Tile
function Tile.new(x, y, image, image_path, collides, quad, leafs, grass)
    local tile = setmetatable({}, Tile)
    tile.x = x
    tile.y = y
    tile.image = image
    tile.image_path = image_path
    tile.collides = collides
    tile.quad = quad
    tile.leafs = leafs or false
    tile.grass = grass or 0
    return tile
end

--- Draws the tile.
function Tile:draw()
    if self.image then
        if self.quad then
            love.graphics.draw(self.image, self.quad, self.x, self.y)
        else
            love.graphics.draw(self.image, self.x, self.y)
        end
    end
end

return Tile
