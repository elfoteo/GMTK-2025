--- Manages loading and rendering of grass blade image assets.
---@class GrassAssets
---@field blades table A list of grass blade images.
local GrassAssets = {}
GrassAssets.__index = GrassAssets

--- Creates a new GrassAssets object.
-- Loads all images from the specified directory path as grass blades.
---@param path string The path to the directory containing the grass blade images.
---@return GrassAssets A new GrassAssets instance.
function GrassAssets:new(path)
    local assets = {}
    setmetatable(assets, GrassAssets)

    assets.blades = {}
    local files = love.filesystem.getDirectoryItems(path)
    table.sort(files)

    for _, file in ipairs(files) do
        local img = love.graphics.newImage(path .. '/' .. file)
        table.insert(assets.blades, img)
    end

    return assets
end

--- Renders a single grass blade.
---@param blade_id number The index of the blade image to render.
---@param location table A table with x and y coordinates for the blade's position.
---@param rotation number The rotation of the blade in degrees.
function GrassAssets:render_blade(blade_id, location, rotation)
    local blade = self.blades[blade_id]
    if not blade then return end

    local w, h = blade:getDimensions()
    love.graphics.draw(blade, location.x, location.y, math.rad(rotation), 1, 1, w / 2, h / 2)
end

return GrassAssets
