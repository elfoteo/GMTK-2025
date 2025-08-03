local CustomFont = require("engine.custom_font")
local SceneManager = require("engine.scene_manager")

---@class NoteUI
---@field x number
---@field y number
---@field width number
---@field height number
---@field image any
---@field font CustomFont
---@field text string
---@field active boolean
---@field isBossNote boolean
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
    self.isBossNote = false
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

    local text_to_display = self.text
    if self.isBossNote then
        text_to_display = string.sub(self.text, 2)
    end

    love.graphics.printf(text_to_display, self.x + 45, self.y + 40, self.width - 60, "left")

    love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Grey color for the hint
    love.graphics.setFont(self.font.font)
    love.graphics.printf("Press 'Q' to exit", self.x + 45, self.y + self.height - 40, self.width - 60, "center")
end

function NoteUI:show(text)
    self.text = text
    if string.sub(text, 1, 1) == "." then
        self.isBossNote = true
    else
        self.isBossNote = false
    end
    self.active = true
end

function NoteUI:hide()
    self.active = false
    if self.isBossNote then
        SceneManager.gotoScene(require("scenes.boss_scene").new())
    end
end

return NoteUI
