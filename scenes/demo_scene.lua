local SceneManager   = require("engine.scene_manager")
local Scene          = require("engine.scene")
local Player         = require("game.player")
local Enemy          = require("game.enemy")
local ParticleSystem = require("engine.particles.particle_system")
local Crosshair      = require("engine.ui.crosshair")
local Background     = require("game.background")
local TileMap        = require("engine.tilemap")
local CustomFont     = require("engine.custom_font")
local Collectible    = require("game.collectible")


local EnemyDeathParticle = require("engine.particles.enemy_death_particle")
local SparkParticle      = require("engine.particles.spark_particle")
local GrassManager       = require("engine.grass.grass_manager")

local CANVAS_W, CANVAS_H = 384, 216

---@class DemoScene : Scene
---@field crosshair Crosshair
---@field customFont CustomFont
---@field customFont8px CustomFont
---@field tilemap TileMap
---@field player Player
---@field enemies table<number, {enemy: Enemy, respawn_timer: number|nil}>
---@field particleSystem ParticleSystem
---@field background Background
---@field bullets table<number, ProjectileBase>
---@field collectibles table<string, Collectible>
---@field score number
---@field howtoMoveImage any
---@field howtoShootImage any
---@field showMoveInstruction boolean
---@field showShootInstruction boolean
---@field moveInstructionAlpha number
---@field shootInstructionAlpha number
---@field spawn_x number
---@field spawn_y number
---@field grassManager GrassManager
---@field t number
---@field frame_times table
---@field frame_time_index number
---@field avg_fps number
local DemoScene          = setmetatable({}, { __index = Scene })
DemoScene.__index        = DemoScene

---Constructs a new DemoScene.
---@return DemoScene
function DemoScene.new()
    local self = Scene.new(CANVAS_W, CANVAS_H)
    setmetatable(self, DemoScene)
    ---@cast self DemoScene
    -- placeholders; real init in load()
    self.crosshair             = nil
    self.customFont            = nil
    self.customFont8px         = nil
    self.player                = nil
    self.enemies               = {}
    self.background            = nil
    self.bullets               = {}
    self.collectibles          = {}
    self.score                 = 0
    self.howtoMoveImage        = nil
    self.howtoShootImage       = nil
    self.showMoveInstruction   = true
    self.showShootInstruction  = true
    self.moveInstructionAlpha  = 1
    self.shootInstructionAlpha = 1
    self.grassManager          = nil
    self.t                     = 0
    self.frame_times           = {}
    self.frame_time_index      = 1
    self.avg_fps               = 0

    return self
end

---Called once when the scene is loaded.
function DemoScene:load()
    self:recalcViewport()

    -- mouse
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(false)

    -- assets
    self.crosshair = Crosshair.new("assets/gui/crosshair.png", 1)

    -- instruction images
    self.howtoMoveImage = love.graphics.newImage("assets/misc/howto-move.png")
    self.howtoShootImage = love.graphics.newImage("assets/misc/howto-shoot.png")

    -- fonts
    self.customFont = CustomFont.new(
        "assets/font/PressStart2P-Regular/PressStart2P-Regular-16px.fnt",
        "assets/font/PressStart2P-Regular/PressStart2P-Regular-16px.png"
    )
    self.customFont8px = CustomFont.new(
        "assets/font/PressStart2P-Regular/PressStart2P-Regular-8px.fnt",
        "assets/font/PressStart2P-Regular/PressStart2P-Regular-8px.png"
    )

    math.randomseed(os.time())

    self.tilemap = TileMap.new()
    self.grassManager = GrassManager:new("assets/grass", self.tilemap.wind_manager,
        { tile_size = self.tilemap.tile_size, stiffness = 600, max_unique = 5, place_range = { 0.8, 0.9 } })
    self.tilemap:setGrassManager(self.grassManager)
    self.tilemap:loadFromTiled("assets/map.lua")
    self.particleSystem = ParticleSystem.new(self.tilemap)
    self.tilemap:setParticleSystem(self.particleSystem)
    -- initialize game systems & entities
    self.spawn_x, self.spawn_y = self.tilemap:getPlayerSpawnAbsolute()
    self.player = Player.new(self, self.spawn_x, self.spawn_y, 80)
    for i, spawn_point in ipairs(self.tilemap.enemy_spawns) do
        local enemy_x = spawn_point.tile_x * self.tilemap.tile_size + self.tilemap.tile_size / 2
        local enemy_y = spawn_point.tile_y * self.tilemap.tile_size + self.tilemap.tile_size / 2
        self.enemies[i] = { enemy = Enemy.new(self, enemy_x, enemy_y, 109, 16), respawn_timer = nil }
    end
    for key, spawn_point in pairs(self.tilemap.collectible_spawns) do
        local collectible_x = spawn_point.tile_x * self.tilemap.tile_size + self.tilemap.tile_size / 2
        local collectible_y = spawn_point.tile_y * self.tilemap.tile_size + self.tilemap.tile_size / 2
        if spawn_point.type == "tti-viper" then
            self.collectibles[key] = Collectible.new(collectible_x, collectible_y, spawn_point.type,
                "assets/weapons/tti-viper.png")
        end
    end
    self.background = Background.new(self.camera, self, { 0.0, 0.5, 0.35, 1.0 }, { 0.0, 0.4, 0.55, 1.0 })
    self.bullets = {}
    self.score = 0

    self.camera:teleport(self.player.x, self.player.y)
end

---Handles the result of a bullet collision.
---@param hitResult table The collision information from Projectile:update.
function DemoScene:handleBulletCollision(hitResult)
    if hitResult.type == "wall" then
        self.particleSystem:emitCone(
            hitResult.x, hitResult.y,
            math.atan2(-hitResult.vy, -hitResult.vx),
            0.8, 7, { 30, 80 }, { 0.2, 0.4 },
            nil, SparkParticle, 0.5
        )
    elseif hitResult.type == "enemy" then
        self.score = self.score + 1
        local enemy_data = hitResult.enemy_data
        local enemy = enemy_data.enemy
        for _ = 1, 30 do
            local x = enemy.x + math.random(-enemy.size / 2, enemy.size / 2)
            local y = enemy.y + math.random(-enemy.size / 2, enemy.size / 2)
            local angle = math.random() * 2 * math.pi
            local speed = 80 + math.random() * 80
            local lifetime = 1 + math.random()
            local vx = math.cos(angle) * speed
            local vy = math.sin(angle) * speed
            self.particleSystem:emit(x, y, vx, vy, lifetime, nil, EnemyDeathParticle, 1.5)
        end
        self.camera:shake(
            5, 0.2,
            hitResult.enemy.x, hitResult.enemy.y,
            self.camera.x, self.camera.y
        )
        enemy_data.enemy = nil
        enemy_data.respawn_timer = 3
    end
end

local startFading = false;

---Update all scene elements.
---@param dt number
function DemoScene:update(dt)
    Scene.update(self, dt)

    -- background
    self.background:update(dt)

    -- instruction fading
    if self.showMoveInstruction then
        local playerMoved = love.keyboard.isDown("w") or love.keyboard.isDown("a") or love.keyboard.isDown("s") or
            love.keyboard.isDown("d")
        if playerMoved then
            self.moveInstructionAlpha = self.moveInstructionAlpha - dt * 2 -- Fade out over 0.5 seconds
            if self.moveInstructionAlpha <= 0 then
                self.showMoveInstruction = false
            end
        end
    end

    if self.showShootInstruction then
        local playerShot = love.mouse.isDown(1) or love.mouse.isDown(2)
        if playerShot then
            startFading = true
        end
    end

    if startFading then
        self.shootInstructionAlpha = self.shootInstructionAlpha - dt * 2 -- Fade out over 0.5 seconds
        if self.shootInstructionAlpha <= 0 then
            self.showShootInstruction = false
        end
    end

    -- player & enemy logic
    local proj = self.player:update(dt, self.tilemap, self.particleSystem)
    -- shooting
    if proj then
        table.insert(self.bullets, proj)
    end

    for i, enemy_data in ipairs(self.enemies) do
        if enemy_data.enemy then
            enemy_data.enemy:update(dt, self.player)
        else
            enemy_data.respawn_timer = enemy_data.respawn_timer - dt
            if enemy_data.respawn_timer <= 0 then
                local spawn_point = self.tilemap.enemy_spawns[i]
                local enemy_x = spawn_point.tile_x * self.tilemap.tile_size + self.tilemap.tile_size / 2
                local enemy_y = spawn_point.tile_y * self.tilemap.tile_size + self.tilemap.tile_size / 2
                enemy_data.enemy = Enemy.new(self, enemy_x, enemy_y, 59, 16)
                enemy_data.respawn_timer = nil
            end
        end
    end

    local world_min_x = -CANVAS_W * 1.5
    local world_max_x = self.tilemap.width + CANVAS_W * 1.5
    local world_min_y = -CANVAS_H * 1.5
    local world_max_y = self.tilemap.height + CANVAS_H * 1.5

    if self.player.y > world_max_y + world_max_y then
        SceneManager.gotoScene(require("scenes.death_scene").new())
        return -- Stop updating if player is dead
    end
    -- Check for player-enemy collision
    for _, enemy_data in ipairs(self.enemies) do
        if enemy_data.enemy and self.player:checkCollision(enemy_data.enemy) then
            SceneManager.gotoScene(require("scenes.death_scene").new())
            return -- Stop updating if player is dead
        end
    end

    -- bullet updates & collisions
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        local hitResult = b:update(dt, self.particleSystem, self.tilemap, self.enemies, world_min_x, world_max_x,
            world_min_y, world_max_y)

        if hitResult then
            self:handleBulletCollision(hitResult)
            table.remove(self.bullets, i)
        end
    end

    -- Collectible collision
    for key, collectible in pairs(self.collectibles) do
        collectible:update(dt)
        if collectible:checkCollision(self.player) then
            if collectible.type == "tti-viper" then
                self.player:addWeapon(require("game.weapons.tti-viper").new())
                self.player:setCurrentWeapon("tti-viper")
            end
            self.collectibles[key] = nil -- Remove collectible after collection
        end
    end

    -- particles & camera follow
    self.particleSystem:update(dt)
    self.tilemap:update(dt)
    self.camera:follow(
        self.player.x, self.player.y,
        self.player.vx, self.player.vy,
        dt
    )

    self.t = self.t + dt * 100
    self.grassManager:update(dt, self.canvas_w, self.canvas_h, self.camera)

    -- FPS calculation
    local total_time = 0
    for i = 1, #self.frame_times do
        total_time = total_time + self.frame_times[i]
    end

    if total_time > 1 then
        table.remove(self.frame_times, 1)
    end

    table.insert(self.frame_times, dt)

    total_time = 0
    for i = 1, #self.frame_times do
        total_time = total_time + self.frame_times[i]
    end

    if total_time > 0 then
        self.avg_fps = #self.frame_times / total_time
    end
end

---Draw the entire scene.
function DemoScene:draw()
    -- render into low‑res canvas
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    self.camera:attach()

    self.background:draw()
    self.tilemap:draw(self.camera, self.canvas_w, self.canvas_h)
    self.grassManager:draw(self.canvas_w, self.canvas_h, self.camera)

    -- Draw collectibles
    for _, collectible in pairs(self.collectibles) do
        collectible:draw()
    end

    -- Draw instructions in world space
    if self.showMoveInstruction then
        love.graphics.setColor(1, 1, 1, self.moveInstructionAlpha)
        love.graphics.draw(self.howtoMoveImage, self.spawn_x - self.howtoMoveImage:getWidth() / 2,
            self.spawn_y - self.howtoMoveImage:getHeight() - 50)
    end
    if self.showShootInstruction then
        love.graphics.setColor(1, 1, 1, self.shootInstructionAlpha)
        love.graphics.draw(self.howtoShootImage, self.spawn_x - self.howtoShootImage:getWidth() / 2 + 80,
            self.spawn_y - self.howtoShootImage:getHeight() - 20)
    end

    self.particleSystem:draw()
    self.player:drawWeapon()
    self.player:draw()
    for _, enemy_data in ipairs(self.enemies) do
        if enemy_data.enemy then
            enemy_data.enemy:draw()
        end
    end
    for _, b in ipairs(self.bullets) do
        b:draw()
    end

    self.camera:detach()

    -- HUD & crosshair
    love.graphics.setColor(1, 1, 1)
    self.customFont8px:print("Score: " .. self.score, 4, 4, { 1, 1, 0, 1 })
    self.customFont8px:print("FPS: " .. math.floor(self.avg_fps), 4, 14, { 1, 1, 0, 1 })

    local mx, my = love.mouse.getPosition()
    local cx, cy = self:toCanvas(mx, my)
    self.crosshair:draw(math.floor(cx) + 0.5, math.floor(cy) + 0.5)

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

---Handle key presses.
function DemoScene:keypressed(key)
    if key == "f11" then
        love.window.setFullscreen(
            not love.window.getFullscreen(),
            "desktop"
        )
    end
    self.player:keypressed(key)
end

---Handle mouse presses.
function DemoScene:mousepressed(_, _, button)
    local current_weapon = self.player.weapons[self.player.current_weapon_index]
    if button == 1 and not current_weapon.repeating then
        local proj = self.player:singleShoot(self.particleSystem)
        if proj then
            table.insert(self.bullets, proj)
        end
    end
end

return DemoScene
