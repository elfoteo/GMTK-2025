-- game/enemy.lua
local Living = require("game.living")

---@class Enemy : Living
---@field size number
local Enemy = setmetatable({}, { __index = Living })
Enemy.__index = Enemy

---Creates a new Enemy.
---@param scene Scene     -- The scene the enemy is in
---@param x number        -- The x-coordinate.
---@param y number        -- The y-coordinate.
---@param speed number    -- Movement speed.
---@param size number?    -- Optional size (defaults to 16).
---@return Enemy
function Enemy.new(scene, x, y, speed, size)
    local e = Living.new(scene, x, y, speed)
    ---@cast e Enemy
    setmetatable(e, Enemy)
    e.size = size or 16
    return e
end

---Move toward the player.
---@param dt number
function Enemy:update(dt, player)
    local playerX, playerY = player.x, player.y
    local dx, dy           = playerX - self.x, playerY - self.y
    local dist             = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        self.x = self.x + (dx / dist) * self.speed * dt
        self.y = self.y + (dy / dist) * self.speed * dt
    end
end

---Draw as a colored square.
function Enemy:draw()
    love.graphics.push()
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle(
        "fill",
        self.x - self.size / 2,
        self.y - self.size / 2,
        self.size,
        self.size
    )
    love.graphics.pop()
end

return Enemy
