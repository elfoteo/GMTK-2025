--- Represents a single tile of grass, containing multiple grass blades.
---@class GrassTile
---@field grass_assets GrassAssets The grass assets to use for rendering.
---@field grass_manager GrassManager The parent grass manager.
---@field loc table The world location {x, y} of the tile.
---@field size number The size of the tile.
---@field blades table A list of the grass blades in the tile.
---@field master_rotation number The overall rotation of the entire tile.
---@field padding number The padding around the tile.
---@field precision number The precision of the rotation calculation.
---@field inc number The rotation increment.
---@field base_id number The base ID of the tile.
---@field custom_blade_data table Custom data for individual blades, used for forces.
---@field render_data string A string used to cache rendering data.
---@field true_rotation number The actual rotation value used for rendering.
local GrassTile = {}
GrassTile.__index = GrassTile

-- Normalizes a value towards a target by a given amount.
local function normalize(val, amt, target)
    if val > target + amt then
        val = val - amt
    elseif val < target - amt then
        val = val + amt
    else
        val = target
    end
    return val
end

--- Creates a new GrassTile.
---@param tile_size number The size of the tile.
---@param location table The world location {x, y} of the tile.
---@param amt number The number of grass blades in the tile.
---@param config table Configuration for the grass blades.
---@param grass_assets GrassAssets The grass assets to use for rendering.
---@param grass_manager GrassManager The parent grass manager.
---@return GrassTile grassTile A new GrassTile instance.
function GrassTile:new(tile_size, location, amt, config, grass_assets, grass_manager)
    local tile = {}
    setmetatable(tile, GrassTile)

    tile.grass_assets = grass_assets
    tile.grass_manager = grass_manager
    tile.loc = location
    tile.size = tile_size
    tile.blades = {}
    tile.master_rotation = 0
    tile.padding = grass_manager.padding
    tile.precision = 30
    tile.inc = 90 / tile.precision

    local y_range = grass_manager.vertical_place_range[2] - grass_manager.vertical_place_range[1]
    for i = 1, amt do
        local new_blade = config[math.random(#config)]
        local y_pos = grass_manager.vertical_place_range[1]
        if y_range > 0 then
            y_pos = math.random() * y_range + grass_manager.vertical_place_range[1]
        end
        table.insert(tile.blades, {
            pos = { x = math.random() * tile.size, y = y_pos * tile.size },
            id = new_blade,
            rot = math.random() * 30 - 15
        })
    end

    table.sort(tile.blades, function(a, b) return a.pos.y < b.pos.y end)

    tile.base_id = grass_manager.grass_id
    grass_manager.grass_id = grass_manager.grass_id + 1

    local format_id = tostring(amt) .. table.concat(config)
    local overwrite = grass_manager:get_format(format_id, tile.blades, tile.base_id)
    if overwrite then
        tile.blades = overwrite[2]
        tile.base_id = overwrite[1]
    end

    tile.custom_blade_data = nil
    tile:update_render_data()

    return tile
end

--- Applies a force to the blades of grass in the tile.
---@param force_point table The world location {x, y} of the force.
---@param force_radius number The radius of the force.
---@param force_dropoff number The distance over which the force diminishes.
function GrassTile:apply_force(force_point, force_radius, force_dropoff)
    if not self.custom_blade_data then
        self.custom_blade_data = {}
        for _, b in ipairs(self.blades) do
            table.insert(self.custom_blade_data, { pos = b.pos, id = b.id, rot = b.rot })
        end
    end

    for i, blade in ipairs(self.blades) do
        local dis = math.sqrt((self.loc.x + blade.pos.x - force_point.x) ^ 2 +
            (self.loc.y + blade.pos.y - force_point.y) ^ 2)
        local force
        if dis < force_radius then
            force = 2
        else
            dis = math.max(0, dis - force_radius)
            force = 1 - math.min(dis / force_dropoff, 1)
        end
        local dir = 1
        if force_point.x > (self.loc.x + blade.pos.x) then
            dir = -1
        end

        if not self.custom_blade_data[i] or math.abs(self.custom_blade_data[i].rot - self.blades[i].rot) <= math.abs(force) * 90 then
            self.custom_blade_data[i].rot = self.blades[i].rot + dir * force * 90
        end
    end
end

--- Updates the render data for the tile.
function GrassTile:update_render_data()
    self.render_data = tostring(self.base_id) .. tostring(self.master_rotation)
    self.true_rotation = self.inc * self.master_rotation
end

--- Sets the master rotation for the entire tile.
---@param rotation number The new rotation value.
function GrassTile:set_rotation(rotation)
    self.master_rotation = rotation
    self:update_render_data()
end

--- Renders the tile to a canvas.
---@return love.Canvas canvas The canvas with the rendered tile.
function GrassTile:render_tile()
    local canvas = love.graphics.newCanvas(self.size + self.padding * 2, self.size + self.padding * 2)
    love.graphics.setCanvas(canvas)

    love.graphics.setCanvas()
    return canvas
end

--- Updates the state of the grass tile.
-- @param dt number The time since the last update.
function GrassTile:update(dt)
    if self.custom_blade_data then
        local matching = true
        for i, blade in ipairs(self.custom_blade_data) do
            blade.rot = normalize(blade.rot, self.grass_manager.stiffness * dt, self.blades[i].rot)
            if blade.rot ~= self.blades[i].rot then
                matching = false
            end
        end
        if matching then
            self.custom_blade_data = nil
        end
    end
end

--- Draws the grass tile.
function GrassTile:draw()
    love.graphics.push()
    love.graphics.translate(self.loc.x, self.loc.y)

    local blades_to_render = self.custom_blade_data or self.blades

    for _, blade in ipairs(blades_to_render) do
        local rotation = math.max(-90, math.min(90, blade.rot + self.true_rotation))
        local shade_val = 1 - (self.grass_manager.shade_amount / 255) * (math.abs(rotation) / 90)
        love.graphics.setColor(shade_val, shade_val, shade_val, 1)
        self.grass_assets:render_blade(blade.id, blade.pos, rotation)
    end

    love.graphics.pop()
end

return GrassTile
