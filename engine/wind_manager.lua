---@class WindManager
---@field wind_x number
---@field wind_y number
---@field wind_timer number
---@field target_wind_x number
---@field target_wind_y number
---@field wind_lerp_speed number
local WindManager = {}
WindManager.__index = WindManager

function WindManager.new()
    local self           = setmetatable({}, WindManager)
    self.wind_x          = 0
    self.wind_y          = 0
    self.wind_timer      = 0
    self.target_wind_x   = 0
    self.target_wind_y   = 0
    self.wind_lerp_speed = 0.4
    return self
end

function WindManager:update(dt)
    self.wind_timer = self.wind_timer - dt
    if self.wind_timer <= 0 then
        local angle_deg
        if math.random() < 0.5 then
            angle_deg = math.random(315, 360)
        else
            angle_deg = math.random(180, 225)
        end
        local angle_rad = math.rad(angle_deg)
        local speed = 50
        self.target_wind_x = math.cos(angle_rad) * speed
        self.target_wind_y = math.sin(angle_rad) * speed
        self.wind_timer = math.random(5, 10)
    end

    local dx = self.target_wind_x - self.wind_x
    local dy = self.target_wind_y - self.wind_y
    local step = self.wind_lerp_speed * dt

    self.wind_x = self.wind_x + dx * step

    local divisor = (self.target_wind_x ~= 0) and self.target_wind_x or 1
    local progress = math.min(math.abs(self.wind_x / divisor), 1)

    self.wind_y = self.wind_y + dy * step * progress
end

return WindManager
