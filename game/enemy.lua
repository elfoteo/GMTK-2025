local Living = require("game.living")

---@class Enemy : Living
---@field size number
---@field health number
---@field vx number
---@field vy number
---@field onGround boolean
local Enemy = setmetatable({}, { __index = Living })
Enemy.__index = Enemy

local GRAVITY = 450

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
    e.health = 100
    e.vx = 0
    e.vy = 0
    e.onGround = false
    return e
end

function Enemy:ai(dt, player)
    -- Default AI: move toward the player
    local playerX, playerY = player.x, player.y
    local dx, dy           = playerX - self.x, playerY - self.y
    local dist             = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        self.x = self.x + (dx / dist) * self.speed * dt
        self.y = self.y + (dy / dist) * self.speed * dt
    end
end

---Move toward the player.
---@param dt number
function Enemy:update(dt, player)
    self:ai(dt, player)

    -- Apply gravity
    self.vy = self.vy + GRAVITY * dt

    -- Compute tentative positions
    local oldX, oldY = self.x, self.y
    local halfW      = self.hitboxW / 2
    local halfH      = self.hitboxH / 2

    -- Apply horizontal movement
    self.x           = self.x + self.vx * dt
    if self.vx ~= 0 then
        if self.scene.tilemap:checkCollision(self.x - halfW, self.y - halfH, self.hitboxW, self.hitboxH) then
            self.x = oldX -- Reset on collision
        end
    end

    -- Apply vertical movement
    self.y = self.y + self.vy * dt
    if self.vy ~= 0 then
        if self.scene.tilemap:checkCollision(self.x - halfW, self.y - halfH, self.hitboxW, self.hitboxH) then
            if self.vy > 0 then
                self.onGround = true
            end
            self.y = oldY -- Reset on collision
            self.vy = 0
        else
            self.onGround = false
        end
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
