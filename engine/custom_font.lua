---@class CustomFont
---@field font love.Font
local CustomFont = {}
CustomFont.__index = CustomFont

--- Creates a new CustomFont object.
---@param fntPath string The path to the .fnt file.
---@param pngPath string The path to the .png file.
---@return CustomFont
function CustomFont.new(fntPath, pngPath)
    local font = setmetatable({}, CustomFont)
    font.font = love.graphics.newFont(fntPath)
    return font
end

--- Prints text using the custom font.
---@param text string The text to print.
---@param x number The x-coordinate to print at.
---@param y number The y-coordinate to print at.
---@param color? {number, number, number, number} The color to use for the text.
function CustomFont:print(text, x, y, color)
    love.graphics.push()
    love.graphics.setFont(self.font)
    if color then
        love.graphics.setColor(color)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.print(text, x, y)
    love.graphics.pop()
end

return CustomFont