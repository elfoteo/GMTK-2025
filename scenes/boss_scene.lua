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
local HealthFountain = require("game.health_fountain")
local PainterBoss = require("game.enemies.painter_boss")


local EnemyDeathParticle = require("engine.particles.enemy_death_particle")
local SparkParticle      = require("engine.particles.spark_particle")
local GrassManager       = require("engine.grass.grass_manager")

local CANVAS_W, CANVAS_H = 384, 216

---@class BossScene : Scene
---@field crosshair Crosshair
---@field customFont CustomFont
---@field customFont8px CustomFont
---@field tilemap TileMap
---@field player Player
---@field enemies table<number, {enemy: Enemy, respawn_timer: number|nil}>
---@field particleSystem ParticleSystem
---@field background Background
---@field collectibles table<string, Collectible>
---@field health_fountains table<string, HealthFountain>
---@field spawn_x number
---@field spawn_y number
---@field grassManager GrassManager
---@field t number
---@field frame_times table
---@field frame_time_index number
---@field avg_fps number
---@field ui UI
---@field boss PainterBoss
---@field health_bar_particles table
local BossScene          = setmetatable({}, { __index = Scene })
BossScene.__index        = BossScene

---Constructs a new BossScene.
---@return BossScene
function BossScene.new()
    local self = Scene.new(CANVAS_W, CANVAS_H)
    setmetatable(self, BossScene)
    ---@cast self BossScene
    -- placeholders; real init in load()
    self.crosshair              = nil
    self.customFont             = nil
    self.customFont8px          = nil
    self.player                 = nil
    self.enemies                = {}
    self.background             = nil
    self.collectibles           = {}
    self.health_fountains       = {}
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
    self.boss                   = nil
    self.health_bar_particles   = {}
    
    self.is_fading_out          = false
    self.fade_alpha             = 0
    return self
end

---Called once when the scene is loaded.
function BossScene:load()
    self:recalcViewport()

    -- mouse
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(false)

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
    self.tilemap:loadFromTiled("assets/boss-map.lua")
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
                if new_enemy:is(PainterBoss) then
                    self.boss = new_enemy
                end
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
    for key, spawn_point in pairs(self.tilemap.health_fountain_spawns) do
        local fountain_x = spawn_point.tile_x * self.tilemap.tile_size + self.tilemap.tile_size / 2
        local fountain_y = spawn_point.tile_y * self.tilemap.tile_size + self.tilemap.tile_size / 2
        self.health_fountains[key] = HealthFountain.new(fountain_x, fountain_y)
    end
    self.background = Background.new(self.camera, self, { 0.60, 0.22, 0.10, 1.0 },
        { 0.84, 0.68, 0.38, 1.0 })

    self.camera:teleport(self.player.x, self.player.y)
end

---Handles the result of a bullet collision.
---@param hitResult table The collision information from Projectile:update.
---@param projectile ProjectileBase The projectile that hit.
function BossScene:handleBulletCollision(hitResult, projectile)
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
            { 1, 1, 1 }, SparkParticle, 0.6
        )
        if enemy.health <= 0 then
            if enemy == self.boss then
                self.is_fading_out = true
            end

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

---Update all scene elements.
---@param dt number
function BossScene:update(dt)
    if self.is_fading_out then
        self.fade_alpha = self.fade_alpha + dt * 0.5
        if self.fade_alpha >= 1 then
            SceneManager.gotoScene(require("scenes.win_scene").new())
        end
        return
    end

    if self.game_frozen then
        return
    end

    Scene.update(self, dt)

    -- Update health bar particles
    for i = #self.health_bar_particles, 1, -1 do
        local p = self.health_bar_particles[i]
        p.y = p.y + p.vy * dt * 2
        p.alpha = p.alpha - dt * 1
        if p.alpha <= 0 then
            table.remove(self.health_bar_particles, i)
        end
    end

    self.player_damage_cooldown = math.max(0, self.player_damage_cooldown - dt)

    -- background
    self.background:update(dt)

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
            world_max_x, world_min_y, world_max_y, self.player)
        if hit_result then
            if hit_result.type == "enemy" and hit_result.enemy == self.player then
                -- Only take damage if not dashing
                if not self.player.is_dashing then
                    self.player:take_damage(p.damage, p)
                    table.remove(self.enemy_projectiles, i)
                end
            else -- Hit a wall or other enemy
                table.remove(self.enemy_projectiles, i)
            end
        end
    end

    -- Collectible collision
    for key, collectible in pairs(self.collectibles) do
        collectible:update(dt, self.player)
    end

    for key, fountain in pairs(self.health_fountains) do
        fountain:update(dt, self.player, self.particleSystem)
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

function BossScene:create_health_bar_particle(health_lost)
    if self.boss then
        local bar_width = self.canvas_w - 40
        local bar_height = 10
        local bar_x = 20
        local bar_y = 35

        local health_percentage = self.boss.health / self.boss.max_health
        local particle_width = (health_lost / self.boss.max_health) * bar_width
        local particle_x = bar_x + bar_width * health_percentage

        table.insert(self.health_bar_particles, {
            x = particle_x,
            y = bar_y,
            width = particle_width,
            height = bar_height,
            alpha = 1,
            vy = 20
        })
    end
end

function BossScene:draw_boss_health_bar()
    if self.boss then
        local bar_width = self.canvas_w - 40
        local bar_height = 10
        local bar_x = 20
        local bar_y = 35

        -- Name
        love.graphics.setFont(self.customFont.font)
        love.graphics.print("The Painter", CANVAS_W / 2 - self.customFont.font:getWidth("The Painter") / 2, bar_y - 22)

        -- Background
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4)

        -- Health
        local health_percentage = self.boss.health / self.boss.max_health
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", bar_x, bar_y, bar_width * health_percentage, bar_height)

        -- Health drop particles
        for _, p in ipairs(self.health_bar_particles) do
            love.graphics.setColor(1, 1, 1, p.alpha)
            love.graphics.rectangle("fill", p.x, p.y, p.width, p.height)
        end

        love.graphics.setColor(1, 1, 1, 1) -- Reset color
    end
end

---Draw the entire scene.
function BossScene:draw()
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

    for _, fountain in pairs(self.health_fountains) do
        fountain:draw(self.customFont8px)
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
    self:draw_boss_health_bar()

    if self.is_fading_out then
        love.graphics.setColor(0, 0, 0, self.fade_alpha)
        love.graphics.rectangle("fill", 0, 0, self.canvas_w, self.canvas_h)
    end

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

---Handle key presses.
function BossScene:keypressed(key)
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

        for k, fountain in pairs(self.health_fountains) do
            if fountain:checkInteractionRange() then
                self.player:startHealing(1.5)
                fountain:use()
                break
            end
        end
    end

    self.player:keypressed(key)
end

---Handle mouse presses.
function BossScene:mousepressed(x, y, button)
    local cx, cy = self:toCanvas(x, y)
    self.player:mousepressed(cx, cy, button)
end

return BossScene
