local RewindHandler = {}
local SparkParticle = require("engine.particles.spark_particle")

local REWIND_ABILITY_CAST_TIME = 2 -- seconds for the rewind effect
local TOTAL_REWIND_TIME = 4        -- seconds of history to play back
local HISTORY_INTERVAL = 0.1       -- seconds between history snapshots
local HISTORY_LENGTH = TOTAL_REWIND_TIME -- for clarity
local PARTICLE_SPAWN_INTERVAL = 0.1

function RewindHandler:new()
    local handler = {
        history = {},
        history_timer = 0,
        is_rewinding = false,
        rewind_timer = 0,
        rewind_path = {},
        particle_spawn_timer = 0,
    }
    return setmetatable(handler, { __index = RewindHandler })
end

function RewindHandler:update(dt, player, particle_system)
    if self.is_rewinding then
        self.rewind_timer = self.rewind_timer - dt
        self.particle_spawn_timer = self.particle_spawn_timer - dt

        if self.particle_spawn_timer <= 0 then
            self.particle_spawn_timer = PARTICLE_SPAWN_INTERVAL
            particle_system:emitBurst(
                player.x, player.y, 20,
                { 50, 100 }, { 0.2, 0.5 }, { 1, 1, 1, 1 },
                SparkParticle, 0.8
            )
        end

        if self.rewind_timer <= 0 then
            self.is_rewinding = false
            if #self.rewind_path > 0 then
                local final_state = self.rewind_path[#self.rewind_path]
                player.x = final_state.x
                player.y = final_state.y
                player.animation_handler.animation.current_state = final_state.anim_state
                player.animation_handler.animation.current_frame = final_state.anim_frame
            end
        else
            local progress = 1 - (self.rewind_timer / REWIND_ABILITY_CAST_TIME)
            local index_float = 1 + progress * (#self.rewind_path - 1)
            local index1 = math.floor(index_float)
            local index2 = math.ceil(index_float)
            local t = index_float - index1

            if self.rewind_path[index1] and self.rewind_path[index2] then
                player.x = self.rewind_path[index1].x * (1 - t) + self.rewind_path[index2].x * t
                player.y = self.rewind_path[index1].y * (1 - t) + self.rewind_path[index2].y * t
                player.animation_handler.animation.current_state = self.rewind_path[index1].anim_state
                player.animation_handler.animation.current_frame = self.rewind_path[index1].anim_frame
            elseif self.rewind_path[index1] then
                player.x = self.rewind_path[index1].x
                player.y = self.rewind_path[index1].y
                player.animation_handler.animation.current_state = self.rewind_path[index1].anim_state
                player.animation_handler.animation.current_frame = self.rewind_path[index1].anim_frame
            end
        end
    else
        self.history_timer = self.history_timer + dt
        if self.history_timer >= HISTORY_INTERVAL then
            self.history_timer = 0
            table.insert(self.history, {
                x = player.x,
                y = player.y,
                timestamp = love.timer.getTime(),
                anim_state = player.animation_handler.animation.current_state,
                anim_frame = player.animation_handler.animation.current_frame
            })
            if #self.history > (HISTORY_LENGTH / HISTORY_INTERVAL) * 1.2 then
                table.remove(self.history, 1)
            end
        end
    end
end

function RewindHandler:start_rewind(player)
    if player.mana < 100 or self.is_rewinding then return end
    player.mana = player.mana - 100

    self.rewind_path = {}
    local now = love.timer.getTime()
    local rewind_target_time = now - TOTAL_REWIND_TIME

    table.insert(self.rewind_path, {
        x = player.x,
        y = player.y,
        anim_state = player.animation_handler.animation.current_state,
        anim_frame = player.animation_handler.animation.current_frame
    })

    for i = #self.history, 1, -1 do
        local state = self.history[i]
        if state.timestamp >= rewind_target_time then
            table.insert(self.rewind_path, state)
        else
            break
        end
    end

    if #self.rewind_path > 1 then
        self.is_rewinding = true
        self.rewind_timer = REWIND_ABILITY_CAST_TIME
        self.particle_spawn_timer = 0
    else
        player.mana = player.mana + 100
    end
end

function RewindHandler:keypressed(key, player)
    if key == "r" then
        self:start_rewind(player)
    end
end

return RewindHandler