---@class Collectible
---@field x number
---@field y number
---@field width number
---@field height number
---@field image love.Image
---@field type string
---@field time number
local Collectible = {}
Collectible.__index = Collectible

--- Creates a new Collectible.
---@param x number The x-coordinate.
---@param y number The y-coordinate.
---@param type string The type of collectible (e.g., "tti-viper").
---@param image_path string The path to the image for the collectible.
---@return Collectible
function Collectible.new(x, y, type, image_path)
    local self = setmetatable({}, Collectible)
    self.x = x
    self.y = y
    self.type = type
    self.image = love.graphics.newImage(image_path)
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.time = 0
    return self
end

--- Draws the collectible.
---@param dt number
function Collectible:update(dt)
    self.time = self.time + dt
end

function Collectible:draw()
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    local bob_offset = math.sin(self.time * 3) * 2 -- Bob up and down by 2 pixels
    love.graphics.draw(self.image, self.x, self.y + bob_offset, 0, 1, 1, self.width / 2, self.height / 2)
    love.graphics.pop()
end

--- Checks collision with a player.
---@param player Player
---@return boolean
function Collectible:checkCollision(player)
    local pl, pr = player.x - player.size / 2, player.x + player.size / 2
    local pt, pb = player.y - player.size / 2, player.y + player.size / 2
    local cl, cr = self.x - self.width / 2, self.x + self.width / 2
    local ct, cb = self.y - self.height / 2, self.y + self.height / 2

    return pr > cl and pl < cr and pb > ct and pt < cb
end

return Collectible