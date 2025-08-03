---@class ProjectileBase
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field speed number
---@field angle number
---@field width number
---@field height number
---@field image love.Image
---@field trail_options table
---@field damage number
local ProjectileBase = {}
ProjectileBase.__index = ProjectileBase

--- Creates a new Projectile.
---@param x number The x-coordinate.
---@param y number The y-coordinate.
---@param speed number The speed of the projectile.
---@param angle number The angle of the projectile.
---@param image_path string The path to the image for the projectile.
---@param trail_options table optional options for the particle trail
---@param damage number The damage the projectile deals.
---@return ProjectileBase
function ProjectileBase.new(x, y, speed, angle, image_path, trail_options, damage)
    local self = setmetatable({}, ProjectileBase)
    self.x = x
    self.y = y
    self.speed = speed
    self.angle = angle
    self.vx = math.cos(angle) * speed
    self.vy = math.sin(angle) * speed
    self.image = love.graphics.newImage(image_path)
    self.width = self.image:getWidth()
    self.height = self.image:getHeight()
    self.trail_options = trail_options or {}
    self.damage = damage or 10
    return self
end

--- Updates the projectile's position and handles collisions and trails.
---@param dt number The time since the last frame.
---@param particleSystem ParticleSystem The particle system to emit particles.
---@param tilemap TileMap The tilemap for collision detection.
---@param enemies table A table of enemies for collision detection.
---@param world_min_x number The minimum x-coordinate of the world boundaries.
---@param world_max_x number The maximum x-coordinate of the world boundaries.
---@param world_min_y number The minimum y-coordinate of the world boundaries.
---@param world_max_y number The maximum y-coordinate of the world boundaries.
---@return table|nil A hit result if a collision occurred, otherwise nil.
function ProjectileBase:update(dt, particleSystem, tilemap, enemies, world_min_x, world_max_x, world_min_y, world_max_y, player)
    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Emit trail particles
    if self.trail_options and particleSystem then
        particleSystem:emitCone(
            self.x, self.y,
            math.atan2(self.vy, self.vx),
            self.trail_options.spread or 0.2,
            self.trail_options.count or 1,
            self.trail_options.speed_range or { 10, 30 },
            self.trail_options.lifetime_range or { 0.1, 0.2 },
            self.trail_options.color or nil,
            self.trail_options.particle_type,
            self.trail_options.scale or 0.1
        )
    end

    -- Check for wall collision
    if tilemap:checkCollision(self.x - self.width / 2, self.y - self.height / 2, self.width, self.height) then
        local tipX = self.x + (self.width / 2) * math.cos(self.angle)
        local tipY = self.y + (self.height / 2) * math.sin(self.angle)
        return { type = "wall", x = tipX, y = tipY, vx = self.vx, vy = self.vy }
    end

    tilemap.grass_manager:apply_force({ x = self.x, y = self.y }, 5, 10)
    -- Check for out of bounds
    if self.x + self.width / 2 < world_min_x or self.x - self.width / 2 > world_max_x or self.y + self.height / 2 < world_min_y or self.y - self.height / 2 > world_max_y then
        return { type = "out_of_bounds" }
    end

    -- Check for enemy collision
    for _, enemy_data in ipairs(enemies) do
        local enemy_obj = enemy_data.enemy
        if enemy_obj then
            local bl, br = self.x - self.width / 2, self.x + self.width / 2
            local bt, bb = self.y - self.height / 2, self.y + self.height / 2
            local el, er = enemy_obj.x - enemy_obj.hitboxW / 2, enemy_obj.x + enemy_obj.hitboxW / 2
            local et, eb = enemy_obj.y - enemy_obj.hitboxH / 2, enemy_obj.y + enemy_obj.hitboxH / 2

            if br > el and bl < er and bb > et and bt < eb then
                if enemy_obj == player and player.is_dashing then
                    return nil -- Ignore collision if player is dashing
                end
                return { type = "enemy", enemy = enemy_obj, enemy_data = enemy_data }
            end
        end
    end

    return nil
end

--- Draws the projectile.
function ProjectileBase:draw()
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image, self.x, self.y, self.angle, 1, 1, self.width / 2, self.height / 2)
    love.graphics.pop()
end

return ProjectileBase
