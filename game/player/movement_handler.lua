--- Handles all player physics and movement-related logic.
--- This includes gravity, jumping, walking, climbing, and collision detection
--- with the level geometry. It is a stateless handler, consisting only of functions.
---@class MovementHandler
local MovementHandler = {}

local GRAVITY = 450
local JUMP_FORCE = -180

--- Updates the player's position and velocity based on input and physics.
---@param dt number The time elapsed since the last frame (delta time).
---@param level TileMap The level's tilemap for collision detection.
---@param player Player The player instance to update.
function MovementHandler:update(dt, level, player)
    if player.rewind_handler.is_rewinding then return end

    local dx = 0
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    local dy = 0
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end

    local jump_pressed = love.keyboard.isDown("space") or love.keyboard.isDown("w")

    local tile_top = level:getTileAtPixel(player.x, player.y)
    local tile_bottom = level:getTileAtPixel(player.x, player.y + player.hitboxH * 0.7)
    local onClimbable = (tile_top and tile_top.climbable) or (tile_bottom and tile_bottom.climbable)

    -- Climbing logic
    if ((tile_top and tile_top.climbable) and not player.isClimbing and dy < 0) or (onClimbable and not player.isClimbing and dy > 0) then
        player.isClimbing = true
        local snap_tile = (tile_bottom and tile_bottom.climbable and tile_bottom)
            or (tile_top and tile_top.climbable and tile_top)
        if snap_tile then
            player.x = snap_tile.x + level.tile_size / 2
        end
    elseif player.isClimbing and not onClimbable then
        player.isClimbing = false
    end

    if player.isClimbing then
        if dy < 0 then
            local tile = level:getTileAtPixel(player.x, player.y + player.hitboxH * 0.5)
            if not (tile and tile.climbable) then
                player.isClimbing = false
            end
        end

        if player.isClimbing then
            player.vy = dy * player.speed
            player.onGround = false
            player.hitboxW = 12

            local tile_below = level:getTileAtPixel(player.x, player.y + player.hitboxH / 2 + 1)
            if (not tile_below or not tile_below.climbable) and dx ~= 0 then
                player.isClimbing = false
            end
        end
    end

    -- Standard movement physics
    if not player.isClimbing then
        player.vy = player.vy + GRAVITY * dt
        player.hitboxW = (tile_bottom and tile_bottom.climbable) and 17 or 16
        if not player.onGround then
            player.fall_distance = player.fall_distance + player.vy * dt
        end
    else
        player.fall_distance = 0
    end

    if player.onGround and jump_pressed and not player.isClimbing then
        player.vy = JUMP_FORCE
        player.onGround = false
    end

    local oldX, oldY = player.x, player.y
    local halfW, halfH = player.hitboxW / 2, player.hitboxH / 2

    -- Horizontal movement and collision
    if not player.isClimbing then
        player.x = player.x + dx * player.speed * dt
        if dx ~= 0 and level:checkCollision(player.x - halfW, player.y - halfH, player.hitboxW, player.hitboxH) then
            player.x = oldX
        end
    end

    -- Vertical movement and collision
    player.y = player.y + player.vy * dt

    if player.vy ~= 0 then
        local ignorePlatforms = player.dropThrough
        local collided = level:checkCollision(player.x - halfW, player.y - halfH, player.hitboxW, player.hitboxH,
            ignorePlatforms)

        if collided then
            if player.vy > 0 then
                player.onGround = true
                if player.fall_distance > 5 * level.tile_size then
                    local damage = math.floor((player.fall_distance - 5 * level.tile_size) / level.tile_size) * 10
                    player:take_damage(damage)
                end
                player.fall_distance = 0
            end
            player.y = oldY
            player.vy = 0
        else
            player.onGround = false
        end
    end

    if player.dropThrough and player.onGround then
        player.dropThrough = false
    end

    if dx ~= 0 and not player.isClimbing then
        player.direction = (dx > 0) and 1 or -1
    end

    -- Update final velocities for this frame
    player.vx = (player.x - oldX) / dt
    player.vy = (player.y - oldY) / dt
end

--- Handles key press events for movement-specific actions.
--- Specifically, this handles the "drop through platform" mechanic.
---@param key string The key that was pressed.
---@param player Player The player instance.
function MovementHandler:keypressed(key, player)
    if key == "s" or key == "down" then
        local now = love.timer.getTime()
        if now - player.lastDownPressTime < 0.25 then
            local tileBelow = player.scene.tilemap:getTileAtPixel(player.x, player.y + player.hitboxH + 1)
            if tileBelow and tileBelow.platform then
                player.dropThrough = true
            end
        end
        player.lastDownPressTime = now
    end
end

return MovementHandler

