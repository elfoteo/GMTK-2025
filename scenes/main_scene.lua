local SceneManager = require("engine.scene_manager")
local Scene = require("engine.scene")
local Player = require("game.player.init")
local EnemyFactory = require("game.enemy_factory") -- Use the factory
local ParticleSystem = require("engine.particles.particle_system")
local Crosshair = require("engine.ui.crosshair")
local Background = require("game.background")
local TileMap = require("engine.tilemap")
local CustomFont = require("engine.custom_font")
local Collectible = require("game.collectible")
local NoteUI = require("game.note_ui")
local UI = require("engine.ui.ui")


local EnemyDeathParticle = require("engine.particles.enemy_death_particle")
local SparkParticle      = require("engine.particles.spark_particle")
local GrassManager       = require("engine.grass.grass_manager")

local CANVAS_W, CANVAS_H = 384, 216

---@class MainScene : Scene
---@field crosshair Crosshair
---@field customFont CustomFont
---@field customFont8px CustomFont
---@field tilemap TileMap
---@field player Player
---@field enemies table<number, {enemy: Enemy, respawn_timer: number|nil}>
---@field particleSystem ParticleSystem
---@field background Background
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
---@field ui UI
local MainScene          = setmetatable({}, { __index = Scene })
MainScene.__index        = MainScene

---Constructs a new MainScene.
---@return MainScene
function MainScene.new()
    local self = Scene.new(CANVAS_W, CANVAS_H)
    setmetatable(self, MainScene)
    ---@cast self MainScene
    -- placeholders; real init in load()
    self.crosshair              = nil
    self.customFont             = nil
    self.customFont8px          = nil
    self.player                 = nil
    self.enemies                = {}
    self.background             = nil
    self.collectibles           = {}
    self.score                  = 0
    self.howtoMoveImage         = nil
    self.howtoShootImage        = nil
    self.showMoveInstruction    = true
    self.showShootInstruction   = true
    self.moveInstructionAlpha   = 1
    self.shootInstructionAlpha  = 1
    self.grassManager           = nil
    self.t                      = 0
    self.frame_times            = {}
    self.frame_time_index       = 1
    self.avg_fps                = 0
    self.note_ui                = nil
    self.game_frozen            = false
    self.spawned_enemies        = {}
    self.ui                     = nil
    self.player_damage_cooldown = 0
    self.enemy_projectiles      = {}
    return self
end

---Called once when the scene is loaded.
function MainScene:load()
    self:recalcViewport()

    -- mouse
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(false)

    -- instruction images
    self.howtoMoveImage = love.graphics.newImage("assets/misc/howto-move.png")
    self.howtoShootImage = love.graphics.newImage("assets/misc/howto-shoot.png")

    -- fonts
    self.customFont = CustomFont.new(
        "assets/font/font8x8_basic_16.fnt",
        "assets/font/font8x8_basic_16.png"
    )
    self.customFont8px = CustomFont.new(
        "assets/font/font8x8_basic_8.fnt",
        "assets/font/font8x8_basic_8.png"
    )

    -- ui
    self.ui = UI.new(self)

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
        local spawn_key = string.format("%d;%d", spawn_point.tile_x, spawn_point.tile_y)
        if not self.spawned_enemies[spawn_key] then
            local enemy_x = spawn_point.tile_x * self.tilemap.tile_size + self.tilemap.tile_size / 2
            local enemy_y = spawn_point.tile_y * self.tilemap.tile_size + self.tilemap.tile_size / 2
            local new_enemy = EnemyFactory.create(spawn_point.type, self, enemy_x, enemy_y)
            if new_enemy then
                table.insert(self.enemies, { enemy = new_enemy, respawn_timer = nil })
                self.spawned_enemies[spawn_key] = true
            end
        end
    end
    for key, spawn_point in pairs(self.tilemap.collectible_spawns) do
        local collectible_x = spawn_point.tile_x * self.tilemap.tile_size + self.tilemap.tile_size / 2
        local collectible_y = spawn_point.tile_y * self.tilemap.tile_size + self.tilemap.tile_size / 2
        if spawn_point.type == "note" then
            self.collectibles[key] = Collectible.new(collectible_x, collectible_y, spawn_point.type, spawn_point.text)
        end
    end
    self.background = Background.new(self.camera, self, { 0.60, 0.22, 0.10, 1.0 },
        { 0.84, 0.68, 0.38, 1.0 })

    self.score = 0

    self.camera:teleport(self.player.x, self.player.y)
end

---Handles the result of a bullet collision.
---@param hitResult table The collision information from Projectile:update.
---@param projectile ProjectileBase The projectile that hit.
function MainScene:handleBulletCollision(hitResult, projectile)
    if hitResult.type == "wall" then
        self.particleSystem:emitCone(
            hitResult.x, hitResult.y,
            math.atan2(-hitResult.vy, -hitResult.vx),
            0.8, 7, { 30, 80 }, { 0.2, 0.4 },
            nil, SparkParticle, 0.5
        )
    elseif hitResult.type == "enemy" then
        local enemy_data = hitResult.enemy_data
        local enemy = enemy_data.enemy
        enemy:take_damage(projectile.damage, projectile)
        self.particleSystem:emitCone(
            (hitResult.enemy.x + projectile.x) / 2, (hitResult.enemy.y + projectile.y) / 2,
            math.atan2(-projectile.vy, -projectile.vx),
            1.5, 15, { 40, 90 }, { 0.3, 0.6 },
            {1, 1, 1}, SparkParticle, 0.6
        )
        if enemy.health <= 0 then
            self.score = self.score + 1
            for _ = 1, 30 do
                local x = enemy.x + math.random(-enemy.hitboxW / 2, enemy.hitboxW / 2)
                local y = enemy.y + math.random(-enemy.hitboxH / 2, enemy.hitboxH / 2)
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
end

local startFading = false;

---Update all scene elements.
---@param dt number
function MainScene:update(dt)
    if self.game_frozen then
        return
    end

    Scene.update(self, dt)

    self.player_damage_cooldown = math.max(0, self.player_damage_cooldown - dt)

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
    self.player:update(dt, self.tilemap, self.particleSystem)

    for i = #self.enemies, 1, -1 do
        local enemy_data = self.enemies[i]
        if enemy_data.enemy then
            enemy_data.enemy:update(dt, self.player)
        else
            table.remove(self.enemies, i)
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
    if self.player.touch_damage_cooldown <= 0 then
        for _, enemy_data in ipairs(self.enemies) do
            if enemy_data.enemy and self.player:checkCollision(enemy_data.enemy) then
                self.player:take_damage(10, enemy_data.enemy) -- deal 10 damage
                self.player.touch_damage_cooldown = 1         -- 1 second cooldown
                break                                         -- only take damage from one enemy at a time
            end
        end
    end

    self.player.combat_handler:update(dt, self.particleSystem, self.tilemap, self.enemies, world_min_x, world_max_x,
        world_min_y, world_max_y, self)

    -- Update enemy projectiles
    for i = #self.enemy_projectiles, 1, -1 do
        local p = self.enemy_projectiles[i]
        local hit_result = p:update(dt, self.particleSystem, self.tilemap, { { enemy = self.player } }, world_min_x,
            world_max_x, world_min_y, world_max_y)
        if hit_result then
            if hit_result.type == "enemy" and hit_result.enemy == self.player then
                self.player:take_damage(p.damage, p)
            end
            table.remove(self.enemy_projectiles, i)
        end
    end

    -- Collectible collision
    for key, collectible in pairs(self.collectibles) do
        collectible:update(dt, self.player)
    end

    -- particles & camera follow
    self.particleSystem:update(dt, self.player)
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
function MainScene:draw()
    -- render into low‑res canvas
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    self.camera:attach()

    self.background:draw()
    self.tilemap:draw(self.camera, self.canvas_w, self.canvas_h)
    self.grassManager:draw(self.canvas_w, self.canvas_h, self.camera)

    -- Draw collectibles
    for _, collectible in pairs(self.collectibles) do
        collectible:draw(self.customFont8px)
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
    self.player:draw()
    self.player.combat_handler:draw()
    for _, p in ipairs(self.enemy_projectiles) do
        p:draw()
    end
    for _, enemy_data in ipairs(self.enemies) do
        if enemy_data.enemy then
            enemy_data.enemy:draw()
        end
    end

    self.camera:detach()

    -- Draw UI
    self.ui:draw()

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

---Handle key presses.
function MainScene:keypressed(key)
    if self.ui.note_ui.active then
        if key == "escape" or key == "e" or key == "q" then
            self.ui.note_ui:hide()
            self.game_frozen = false
        end
        return
    end

    if key == "f11" then
        love.window.setFullscreen(
            not love.window.getFullscreen(),
            "desktop"
        )
    end

    if key == "e" then
        for k, collectible in pairs(self.collectibles) do
            if collectible:checkPickupRange() then
                self.ui.note_ui:show(collectible.text)
                self.collectibles[k] = nil
                self.game_frozen = true
                break -- only pick up one at a time
            end
        end
    end

    self.player:keypressed(key)
end

---Handle mouse presses.
function MainScene:mousepressed(x, y, button)
    local cx, cy = self:toCanvas(x, y)
    self.player:mousepressed(cx, cy, button)
end

return MainScene
