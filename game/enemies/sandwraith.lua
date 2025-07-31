local Enemy = require("game.enemy")
local Animated = require("engine.animated")

---@class SandWraith : Enemy
---@field animation Animated
---@field direction number
---@field wanderTimer number
local SandWraith = setmetatable({}, { __index = Enemy })
SandWraith.__index = SandWraith

function SandWraith.new(scene, x, y, speed, size)
    local sw = Enemy.new(scene, x, y, speed, size)
    ---@cast sw SandWraith
    setmetatable(sw, SandWraith)

    sw.hitboxW = 48
    sw.hitboxH = 56

    sw.animation = Animated:new({
        idle = {
            images = {
                love.graphics.newImage("assets/entities/sandwraith-idle1.png"),
                love.graphics.newImage("assets/entities/sandwraith-idle2.png"),
                love.graphics.newImage("assets/entities/sandwraith-idle3.png"),
            },
            delay = 0.2,
        }
    })
    sw.animation:set_state("idle")

    sw.direction = 1
    sw.wanderTimer = 0

    return sw
end

function SandWraith:ai(dt, player)
    self.wanderTimer = self.wanderTimer - dt
    if self.wanderTimer <= 0 then
        self.direction = math.random(0, 1) == 0 and -1 or 1
        self.wanderTimer = math.random(2, 5)
    end

    -- Ledge detection
    local nextX = self.x + self.direction * self.hitboxW / 2
    local groundCheckY = self.y + self.hitboxH / 2 + 1
    local groundTile = self.scene.tilemap:getTileAtPixel(nextX, groundCheckY)
    if not groundTile or not groundTile.collides then
        self.direction = -self.direction
        self.wanderTimer = 0
    end

    self.vx = self.direction * self.speed

    self.animation:update(dt)
end

function SandWraith:draw()
    local ox = self.hitboxW / 2
    local oy = self.hitboxH / 2
    self.animation:draw(self.x, self.y, 0, self.direction, 1, ox, oy)
end

return SandWraith
