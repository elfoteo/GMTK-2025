local RewindHandler = {}

local REWIND_SECONDS = 4
local HISTORY_INTERVAL = 0.1

function RewindHandler:new()
    local handler = {
        history = {},
        history_timer = 0,
    }
    return setmetatable(handler, { __index = RewindHandler })
end

function RewindHandler:update(dt, player)
    self.history_timer = self.history_timer + dt
    if self.history_timer >= HISTORY_INTERVAL then
        self.history_timer = 0
        local state = {
            x = player.x,
            y = player.y,
            vx = player.vx,
            vy = player.vy,
            health = player.health,
            timestamp = love.timer.getTime()
        }
        table.insert(self.history, state)
        if #self.history > (REWIND_SECONDS / HISTORY_INTERVAL) * 1.5 then
            table.remove(self.history, 1)
        end
    end
end

function RewindHandler:rewind(player)
    if player.mana < 100 then return end

    player.mana = player.mana - 100

    local now = love.timer.getTime()
    local target_time = now - REWIND_SECONDS
    local best_state = nil

    for i = #self.history, 1, -1 do
        local state = self.history[i]
        if state.timestamp <= target_time then
            best_state = state
            break
        end
    end

    if best_state then
        player.x = best_state.x
        player.y = best_state.y
        player.vx = best_state.vx
        player.vy = best_state.vy
        player.health = best_state.health
        for i = #self.history, 1, -1 do
            if self.history[i].timestamp > best_state.timestamp then
                table.remove(self.history, i)
            end
        end
    end
end

function RewindHandler:keypressed(key, player)
    if key == "r" then
        self:rewind(player)
    end
end

return RewindHandler
