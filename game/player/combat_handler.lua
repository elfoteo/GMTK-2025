local ClockHandProjectile = require("game.projectiles.clock-hand_projectile")
local SparkParticle = require("engine.particles.spark_particle")

--- Manages the player's combat abilities.
--- This handler is responsible for creating projectiles when the player attacks,
--- managing attack timing (including a combo system for triple shots), and
--- updating active projectiles.
---@class CombatHandler
---@field projectiles table A list of active projectiles fired by the player.
---@field lastAttackTime number|nil The timestamp of the last attack.
---@field secondLastAttackTime number|nil The timestamp of the second to last attack, for combo tracking.
local CombatHandler = {}

--- Creates a new CombatHandler instance.
---@return CombatHandler The new combat handler instance.
function CombatHandler:new()
    local handler = {
        projectiles = {},
        lastAttackTime = nil,
        secondLastAttackTime = nil,
    }
    return setmetatable(handler, { __index = CombatHandler })
end

function CombatHandler:interrupt_combo()
    self.lastAttackTime = nil
    self.secondLastAttackTime = nil
end

--- Updates all active projectiles.
--- It checks for collisions and removes projectiles that have hit something or gone off-screen.
---@param dt number The time elapsed since the last frame (delta time).
---@param particleSystem ParticleSystem The main particle system for creating effects.
---@param tilemap TileMap The level's tilemap for collision detection.
---@param enemies Enemy[] A table containing all active enemies.
---@param world_min_x number The minimum x-boundary of the world.
---@param world_max_x number The maximum x-boundary of the world.
---@param world_min_y number The minimum y-boundary of the world.
---@param world_max_y number The maximum y-boundary of the world.
---@param scene MainScene The main scene object.
function CombatHandler:update(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y, scene)
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        local hitResult = p:update(dt, particleSystem, tilemap, enemies,
            world_min_x, world_max_x, world_min_y, world_max_y)
        if hitResult then
            local ignore_hit = hitResult.type == "enemy" and hitResult.enemy and hitResult.enemy.isVanished
            if not ignore_hit then
                scene:handleBulletCollision(hitResult, p)
                table.remove(self.projectiles, i)
            end
        end
    end
end

--- Draws all active projectiles.
function CombatHandler:draw()
    for _, p in ipairs(self.projectiles) do p:draw() end
end

--- Handles mouse press events to trigger attacks.
---@param x number The x-coordinate of the mouse press.
---@param y number The y-coordinate of the mouse press.
---@param button number The mouse button that was pressed.
---@param player Player The player instance.
function CombatHandler:mousepressed(x, y, button, player)
    if button == 1 then
        if player.isClimbing and (love.keyboard.isDown("w", "up") or love.keyboard.isDown("s", "down")) then
            return
        end

        local now = love.timer.getTime()

        if self.lastAttackTime and (now - self.lastAttackTime < 0.25) then
            return
        end

        local shootTriple = false
        if self.lastAttackTime and self.secondLastAttackTime then
            local t1 = self.secondLastAttackTime
            local t2 = self.lastAttackTime
            if (t2 - t1 <= 0.6) and (now - t2 <= 0.6) then
                shootTriple = true
            end
        end

        if player.isClimbing then
            player.isClimbing = false
            player.vy = 0
            player.onGround = false
        end

        player.animation_handler.animation:set_state("attack")
        local angle = math.atan2(y - 216 / 2, x - 384 / 2)

        -- Turn player based on mouse position
        if x < 384 / 2 then
            player.direction = -1
        else
            player.direction = 1
        end

        if shootTriple then
            local spread = math.rad(2)
            for _, a in ipairs({ angle - spread, angle, angle + spread }) do
                local proj = ClockHandProjectile.new(player.x, player.y, 400, a)
                table.insert(self.projectiles, proj)
            end
            self.lastAttackTime = nil
            self.secondLastAttackTime = nil
        else
            local proj = ClockHandProjectile.new(player.x, player.y, 400, angle)
            table.insert(self.projectiles, proj)

            self.secondLastAttackTime = self.lastAttackTime
            self.lastAttackTime = now
        end

        player.scene.particleSystem:emitCone(
            player.x, player.y, angle, 0.8, 15,
            { 50, 150 }, { 0.1, 0.3 }, { 1, 1, 1, 1 },
            SparkParticle, 0.6
        )
    end
end

return CombatHandler