local GrassAssets = require('engine.grass.grass_assets')
local GrassTile = require('engine.grass.grass_tile')

--- Manages the creation, update, and rendering of all grass tiles.
---@class GrassManager
---@field grass_assets GrassAssets The loaded grass assets.
---@field grass_id number A unique ID for each grass tile.
---@field grass_cache table A cache for grass tile data.
---@field formats table A table to store different formats of grass tiles.
---@field grass_tiles table A table of all active grass tiles.
---@field tile_size number The size of each grass tile.
---@field shade_amount number The amount of shading to apply to the grass.
---@field stiffness number The stiffness of the grass blades.
---@field max_unique number The maximum number of unique grass tile formats.
---@field vertical_place_range table The vertical placement range for grass blades.
---@field padding number The padding around each grass tile.
---@field wind_manager WindManager The wind manager for the scene.
local GrassManager = {}
GrassManager.__index = GrassManager

--- Creates a new GrassManager.
---@param grass_path string The file path to the grass assets.
---@param wind_manager WindManager The wind manager for the scene.
---@param options table A table of options to configure the manager.
---@return GrassManager grassManager A new GrassManager instance.
function GrassManager:new(grass_path, wind_manager, options)
    options = options or {}
    local manager = {}
    setmetatable(manager, GrassManager)

    manager.grass_assets = GrassAssets:new(grass_path)
    manager.grass_id = 0
    manager.grass_cache = {}
    manager.formats = {}
    manager.grass_tiles = {}
    manager.wind_manager = wind_manager

    manager.tile_size = options.tile_size or 15
    manager.shade_amount = options.shade_amount or 100
    manager.stiffness = options.stiffness or 360
    manager.max_unique = options.max_unique or 10
    manager.vertical_place_range = options.place_range or { 1, 1 }
    manager.padding = options.padding or 13

    return manager
end

--- Sets the tile size for the grass manager.
-- @param tile_size number The new tile size.
function GrassManager:setTileSize(tile_size)
    self.tile_size = tile_size
end

--- Gets or creates a format for a grass tile.
-- This is used to cache and reuse similar tile layouts.
---@param format_id string A unique identifier for the format.
---@param data table The data for the tile format.
---@param tile_id number The ID of the tile.
---@return table formaData The format data.
function GrassManager:get_format(format_id, data, tile_id)
    if not self.formats[format_id] then
        self.formats[format_id] = { count = 1, data = { { tile_id, data } } }
    elseif self.formats[format_id].count >= self.max_unique then
        return self.formats[format_id].data[math.random(#self.formats[format_id].data)]
    else
        self.formats[format_id].count = self.formats[format_id].count + 1
        table.insert(self.formats[format_id].data, { tile_id, data })
    end
end

--- Places a new grass tile at a given location.
---@param location table The grid location {x, y} to place the tile.
---@param density number The density of grass blades in the tile.
---@param grass_options table Configuration options for the grass blades.
function GrassManager:place_tile(location, density, grass_options)
    local loc_str = location.x .. ',' .. location.y
    if not self.grass_tiles[loc_str] then
        self.grass_tiles[loc_str] = GrassTile:new(self.tile_size,
            { x = location.x * self.tile_size, y = location.y * self.tile_size }, density, grass_options,
            self.grass_assets, self)
    end
end

--- Applies a force to the grass tiles within a certain radius.
---@param location table The world location {x, y} of the force.
---@param radius number The radius of the force.
---@param dropoff number The distance over which the force diminishes.
function GrassManager:apply_force(location, radius, dropoff)
    local grid_pos = { x = math.floor(location.x / self.tile_size), y = math.floor(location.y / self.tile_size) }
    local tile_range = math.ceil((radius + dropoff) / self.tile_size)

    for y = -tile_range, tile_range do
        for x = -tile_range, tile_range do
            local pos = { x = grid_pos.x + x, y = grid_pos.y + y }
            local pos_str = pos.x .. ',' .. pos.y
            if self.grass_tiles[pos_str] then
                self.grass_tiles[pos_str]:apply_force(location, radius, dropoff)
            end
        end
    end
end

--- Updates the visible grass tiles.
---@param dt number The time since the last update.
---@param canvas_w number The width of the visible canvas.
---@param canvas_h number The height of the visible canvas.
---@param camera table The camera object with x and y properties.
function GrassManager:update(dt, canvas_w, canvas_h, camera)
    local start_tile_x = math.floor(camera.x / self.tile_size)
    local start_tile_y = math.floor(camera.y / self.tile_size)
    local end_tile_x = start_tile_x + math.ceil(canvas_w / self.tile_size) + 1
    local end_tile_y = start_tile_y + math.ceil(canvas_h / self.tile_size) + 1

    for y = start_tile_y, end_tile_y do
        for x = start_tile_x, end_tile_x do
            local pos_str = x .. ',' .. y
            if self.grass_tiles[pos_str] then
                local tile = self.grass_tiles[pos_str]

                -- Get the horizontal wind speed
                local wind_x = self.wind_manager.wind_x

                -- 1. Calculate a base lean based on the wind's direction and strength.
                -- This makes the grass lean consistently in the direction of the wind.
                local base_lean = wind_x * 0.30

                -- 2. Calculate the amplitude of the swaying motion.
                -- The grass sways more when the wind is stronger, but still sways gently when calm.
                local sway_amplitude = 2 + math.abs(wind_x) * 0.1

                -- 3. Calculate the swaying motion, keeping the x-position dependency for the wave effect.
                local sway = math.sin(love.timer.getTime() * 2 + tile.loc.x / 20) * sway_amplitude

                -- 4. Combine the base lean and the sway for the final rotation.
                local total_rotation = base_lean + sway

                tile:set_rotation(total_rotation)
                tile:update(dt)
            end
        end
    end
end

--- Draws the visible grass tiles.
---@param canvas_w number The width of the visible canvas.
---@param canvas_h number The height of the visible canvas.
---@param camera table The camera object with x and y properties.
function GrassManager:draw(canvas_w, canvas_h, camera)
    local start_tile_x = math.floor(camera.x / self.tile_size)
    local start_tile_y = math.floor(camera.y / self.tile_size)
    local end_tile_x = start_tile_x + math.ceil(canvas_w / self.tile_size) + 1
    local end_tile_y = start_tile_y + math.ceil(canvas_h / self.tile_size) + 1

    for y = start_tile_y, end_tile_y do
        for x = start_tile_x, end_tile_x do
            local pos_str = x .. ',' .. y
            if self.grass_tiles[pos_str] then
                self.grass_tiles[pos_str]:draw()
            end
        end
    end
end

return GrassManager
