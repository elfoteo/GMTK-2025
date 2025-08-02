local Animated = require("engine.animated")

local AnimationHandler = {}

function AnimationHandler:new(player)
    local p = player
    local handler = {}
    handler.animation = Animated:new({
        idle = { images = {}, path_pattern = "assets/entities/player-idle%d.png", frames = 4, delay = 0.4 },
        walk = { images = {}, path_pattern = "assets/entities/player-walk%d.png", frames = 4, delay = 0.1 },
        jump_start = {
            images = {},
            path_pattern = "assets/entities/player-jump-start%d.png",
            frames = 2,
            delay = 0.2,
            loops = false,
            on_complete = function() handler.animation:set_state("jump_fall") end
        },
        jump_fall = { images = {}, path_pattern = "assets/entities/player-jump-start%d.png", frames = 2, delay = 0.2 },
        jump_end = {
            images = {},
            path_pattern = "assets/entities/player-jump-end%d.png",
            frames = 5,
            delay = 0.08,
            loops = false,
            on_complete = function() handler.animation:set_state("idle") end
        },
        attack = {
            images = {},
            path_pattern = "assets/entities/player-attack%d.png",
            frames = 4,
            delay = 0.05,
            loops = false,
            on_complete = function() handler.animation:set_state("idle") end
        },
        climb_idle = {
            images = { love.graphics.newImage("assets/entities/player-climbing1.png") },
            delay = 0.1,
        },
        climb = { images = {}, path_pattern = "assets/entities/player-walk%d.png", frames = 4, delay = 0.1 },
        turn_to_climb = {
            images = {},
            path_pattern = "assets/entities/player-turning%d.png",
            frames = 14,
            delay = 0.02,
            loops = false,
            on_complete = function() handler.animation:set_state("climb_idle") end
        },
        climbing = { images = {}, path_pattern = "assets/entities/player-climbing%d.png", frames = 8, delay = 0.1 },
        descending = {
            images = {},
            path_pattern = "assets/entities/player-climbing%d.png",
            frames = 8,
            delay = 0.1,
            reversed_pattern = true
        },
        turn_from_climb = {
            images = {},
            path_pattern = "assets/entities/player-turning%d.png",
            frames = 14,
            delay = 0.02,
            loops = false,
            reversed_pattern = true,
            on_complete = function() handler.animation:set_state("idle") end
        },
    })
    handler.animation:set_state("idle")
    return setmetatable(handler, { __index = AnimationHandler })
end

function AnimationHandler:update(dt, player, wasClimbing, wasOnGround)
    if player.rewind_handler.is_rewinding then
        self.animation:update(dt)
        return
    end
    self.animation:update(dt)

    local dx = 0
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    local dy = 0
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end

    local next_anim
    local current_anim = self.animation.current_state

    if current_anim == "attack" and not self.animation.is_finished then
        next_anim = "attack"
    elseif current_anim == "turn_to_climb" and not self.animation.is_finished then
        next_anim = "turn_to_climb"
    elseif current_anim == "turn_from_climb" and not self.animation.is_finished then
        next_anim = "turn_from_climb"
    elseif player.isClimbing then
        if not wasClimbing then
            next_anim = "turn_to_climb"
        elseif dy < 0 then
            next_anim = "climbing"
        elseif dy > 0 then
            next_anim = "descending"
        else
            next_anim = "climb_idle"
        end
    elseif wasClimbing and not player.isClimbing then
        next_anim = "turn_from_climb"
    elseif not player.onGround then
        next_anim = (player.vy < 0) and "jump_start" or "jump_fall"
    elseif not wasOnGround and player.onGround then
        next_anim = "jump_end"
    else
        next_anim = (dx == 0) and "idle" or "walk"
    end

    if next_anim and next_anim ~= current_anim then
        self.animation:set_state(next_anim)
    end
end

function AnimationHandler:draw(x, y, direction, size)
    local ox, oy = size / 2, size / 2
    self.animation:draw(x, y, 0, direction, 1, ox, oy)
end

return AnimationHandler
