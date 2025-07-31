---@class Collectible
---@field x number
---@field y number
---@field width number
---@field height number
---@field image love.Image
---@field type string
---@field time number
---@field showPrompt boolean
---@field promptImage love.Image
---@field promptTextBefore string
---@field promptTextAfter string
local Collectible = {}
Collectible.__index = Collectible

--- Creates a new Collectible.
---@param x number The x-coordinate.
---@param y number The y-coordinate.
---@param type string The type of collectible (e.g., "note").
---@return Collectible
function Collectible.new(x, y, type)
    local self = setmetatable({}, Collectible)
    self.x = x
    self.y = y
    self.type = type
    self.image = love.graphics.newImage("assets/misc/note.png")
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.time = 0
    self.showPrompt = false
    self.promptImage = love.graphics.newImage("assets/misc/e-key.png")
    self.promptTextBefore = "Press "
    self.promptTextAfter = " to read"
    return self
end

--- Updates the collectible's state.
---@param dt number
---@param player Player
function Collectible:update(dt, player)
    self.time = self.time + dt
    local dx = self.x - player.x
    local dy = self.y - player.y
    local distance = math.sqrt(dx * dx + dy * dy)
    self.showPrompt = distance < 40
end

function Collectible:draw(font)
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    local bob_offset = math.sin(self.time * 3) * 2 -- Bob up and down by 2 pixels
    love.graphics.draw(self.image, math.floor(self.x), math.floor(self.y + bob_offset), 0, 1, 1, self.width / 2,
        self.height / 2)

    if self.showPrompt and font then
        local promptX = math.floor(self.x)
        local promptY = math.floor(self.y - self.height / 2 - 20)

        local textBeforeWidth = font:getWidth(self.promptTextBefore)
        local textAfterWidth = font:getWidth(self.promptTextAfter)
        local imgWidth = self.promptImage:getWidth()

        local spacing = -5 -- pixels between elements
        local totalWidth = textBeforeWidth + spacing + imgWidth + spacing + textAfterWidth

        local currentX = promptX - totalWidth / 2

        font:print(self.promptTextBefore, math.floor(currentX), math.floor(promptY - font:getHeight() / 2))
        currentX = currentX + textBeforeWidth + spacing

        love.graphics.draw(self.promptImage, math.floor(currentX), math.floor(promptY), 0, 1, 1, 0,
            math.floor(self.promptImage:getHeight() / 2))
        currentX = currentX + imgWidth + spacing

        font:print(self.promptTextAfter, math.floor(currentX), math.floor(promptY - font:getHeight() / 2))
    end

    love.graphics.pop()
end

--- Checks collision with a player.
---@return boolean
function Collectible:checkPickupRange()
    return self.showPrompt
end

return Collectible
