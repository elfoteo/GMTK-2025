local CustomFont = require("engine.custom_font")

---@class NoteUI
---@field x number
---@field y number
---@field width number
---@field height number
---@field image any
---@field font CustomFont
---@field text string
---@field active boolean
local NoteUI = {}
NoteUI.__index = NoteUI

function NoteUI.new(x, y, width, height, text, font)
    local self = setmetatable({}, NoteUI)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.image = love.graphics.newImage("assets/gui/note_ui.png")
    self.font = font
    self.text = text
    self.active = false
    return self
end

function NoteUI:draw()
    if not self.active then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, 0, self.width / self.image:getWidth(),
        self.height / self.image:getHeight())

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setFont(self.font.font)
    love.graphics.printf(self.text, self.x + 45, self.y + 40, self.width - 60, "left")
end

function NoteUI:show()
    self.active = true
end

function NoteUI:hide()
    self.active = false
end

return NoteUI
