local Tile = require("engine.tile")
local LeafParticle = require("engine.particles.leaf_particle")
local WindManager = require("engine.wind_manager")

---@class TileMap
---@field tiles Tile[]                 List of all tiles in the map.
---@field tile_size number             Size (both width and height) of each tile.
---@field width number                 Width of the map in pixels.
---@field height number                Height of the map in pixels.
---@field player_spawn { tile_x: number, tile_y: number }
---@field enemy_spawns { tile_x: number, tile_y: number }[]
---@field collectible_spawns table<string, { tile_x: number, tile_y: number, type: string }>
---@field tile_grid table<string, Tile>  Hashmap for fast tile lookups (key: "x;y")
---@field particleSystem ParticleSystem
---@field wind_manager WindManager
---@field grass_manager GrassManager
local TileMap = {}
TileMap.__index = TileMap

---Sets the particle system for the tilemap.
---@param particleSystem ParticleSystem
function TileMap:setParticleSystem(particleSystem)
    self.particleSystem = particleSystem
end

---Sets the grass manager for the tilemap.
---@param grassManager GrassManager
function TileMap:setGrassManager(grassManager)
    self.grass_manager = grassManager
end

---Creates a new, empty TileMap.
---@return TileMap
function TileMap.new()
    local tm              = setmetatable({}, TileMap)
    tm.tiles              = {}
    tm.tile_grid          = {}
    tm.tile_size          = 0
    tm.width              = 0
    tm.height             = 0
    tm.player_spawn       = { tile_x = 0, tile_y = 0 }
    tm.enemy_spawns       = {}
    tm.collectible_spawns = {}
    tm.particleSystem     = nil
    tm.wind_manager       = WindManager.new()
    tm.grass_manager      = nil
    return tm
end

local function parse_grass_string(grass_str)
    local grass_types = {}
    for s in string.gmatch(grass_str, "%d+") do
        table.insert(grass_types, tonumber(s))
    end
    return grass_types
end

---Loads a tilemap from a Tiled-exported .lua file.
---@param filename string Path to the Tiled map file.
function TileMap:loadFromTiled(filename)
    print("TileMap:loadFromTiled(): self = " .. tostring(self))
    local map_data = love.filesystem.load(filename)()
    if not map_data then
        error("TileMap:loadFromTiled - Could not load map file: " .. filename)
    end

    self.tile_size = map_data.tilewidth
    self.width = map_data.width * self.tile_size
    self.height = map_data.height * self.tile_size

    if self.grass_manager then
        self.grass_manager:setTileSize(self.tile_size)
    end

    local spawn_point_gid = -1
    local tile_properties = {}

    for _, tileset in ipairs(map_data.tilesets) do
        local image_path = "assets/" .. tileset.image
        if not (love.filesystem.getInfo(image_path) and love.filesystem.getInfo(image_path).type == "file") then
            error("TileMap:loadFromTiled - Tileset image not found: " .. image_path)
        end
        local image_data = love.image.newImageData(image_path)
        local tileset_image = love.graphics.newImage(image_data)

        if tileset.tiles and #tileset.tiles > 0 then
            for _, tile_data in ipairs(tileset.tiles) do
                local gid = tileset.firstgid + tile_data.id
                tile_properties[gid] = {}
                if tile_data.properties and tile_data.properties.collision ~= nil then
                    tile_properties[gid].collides = tile_data.properties.collision
                end
                if tile_data.properties and tile_data.properties.grass_density ~= nil then
                    tile_properties[gid].grass_density = tile_data.properties.grass_density
                end
                if tile_data.properties and tile_data.properties.grass_types ~= nil then
                    tile_properties[gid].grass_types = tile_data.properties.grass_types
                end
                if tile_data.properties and tile_data.properties.leafs ~= nil then
                    tile_properties[gid].leafs = tile_data.properties.leafs
                end
                if tile_data.properties and tile_data.properties.grass ~= nil then
                    tile_properties[gid].grass = tile_data.properties.grass
                end
                if tile_data.properties and tile_data.properties.playerSpawn ~= nil then
                    tile_properties[gid].playerSpawn = tile_data.properties.playerSpawn
                    if tile_data.properties.playerSpawn == true then
                        spawn_point_gid = gid
                    end
                end
                if tile_data.properties and tile_data.properties.enemy ~= nil then
                    tile_properties[gid].enemy = tile_data.properties.enemy
                end
                if tile_data.properties and tile_data.properties.collectible ~= nil then
                    tile_properties[gid].collectible = tile_data.properties.collectible
                end
            end
        end

        for i = 0, tileset.tilecount - 1 do
            -- local tile_x = (i % tileset.columns) * self.tile_size
            -- local tile_y = math.floor(i / tileset.columns) * self.tile_size
            local current_gid = i + tileset.firstgid
            if not tile_properties[current_gid] then
                tile_properties[current_gid] = { collides = true }
            end
        end

        local quads = {}
        for i = 0, tileset.tilecount - 1 do
            local x = (i % tileset.columns) * self.tile_size
            local y = math.floor(i / tileset.columns) * self.tile_size
            quads[i + tileset.firstgid] = love.graphics.newQuad(x, y, self.tile_size, self.tile_size,
                tileset_image:getDimensions())
        end

        for _, layer in ipairs(map_data.layers) do
            if layer.type == "tilelayer" then
                for i, chunk in ipairs(layer.chunks) do
                    for y = 0, chunk.height - 1 do
                        for x = 0, chunk.width - 1 do
                            local tile_gid = chunk.data[y * chunk.width + x + 1]
                            if tile_gid ~= 0 then
                                if tile_properties[tile_gid] and tile_properties[tile_gid].playerSpawn == true then
                                    self.player_spawn = { tile_x = chunk.x + x, tile_y = chunk.y + y }
                                elseif tile_properties[tile_gid] and tile_properties[tile_gid].enemy then
                                    table.insert(self.enemy_spawns, { tile_x = chunk.x + x, tile_y = chunk.y + y, type = tile_properties[tile_gid].enemy })
                                elseif tile_properties[tile_gid] and tile_properties[tile_gid].collectible then
                                    self.collectible_spawns[string.format("%d;%d", chunk.x + x, chunk.y + y)] = {
                                        tile_x = chunk.x + x,
                                        tile_y = chunk.y + y,
                                        type = tile_properties[tile_gid].collectible
                                    }
                                    
                                    local grass_density_prop = tile_properties[tile_gid].grass_density
                                    local grass_types_prop = tile_properties[tile_gid].grass_types

                                    if grass_density_prop or grass_types_prop then
                                        local final_density = 5                     -- Default density
                                        local final_grass_types = { 1, 2, 3, 4, 5 } -- Default types

                                        if type(grass_density_prop) == "number" then
                                            final_density = grass_density_prop
                                        end

                                        if type(grass_types_prop) == "string" then
                                            local parsed_types = parse_grass_string(grass_types_prop)
                                            if #parsed_types > 0 then
                                                final_grass_types = parsed_types
                                            end
                                        end

                                        if final_density > 0 then -- Only place grass if density is positive
                                            self.grass_manager:place_tile({ x = chunk.x + x, y = chunk.y + y }, final_density,
                                                final_grass_types)
                                        end
                                    end
                                else
                                    local quad = quads[tile_gid]
                                    if quad then
                                        local tile_x = (chunk.x + x)
                                        local tile_y = (chunk.y + y)
                                        local collides = tile_properties[tile_gid] and tile_properties[tile_gid]
                                            .collides
                                        local leafs = tile_properties[tile_gid] and tile_properties[tile_gid].leafs
                                        local grass_density_prop = tile_properties[tile_gid] and
                                            tile_properties[tile_gid].grass_density
                                        local grass_types_prop = tile_properties[tile_gid] and
                                            tile_properties[tile_gid].grass_types

                                        local final_density = 5                     -- Default density
                                        local final_grass_types = { 1, 2, 3, 4, 5 } -- Default types

                                        if type(grass_density_prop) == "number" then
                                            final_density = grass_density_prop
                                        end

                                        if type(grass_types_prop) == "string" then
                                            local parsed_types = parse_grass_string(grass_types_prop)
                                            if #parsed_types > 0 then
                                                final_grass_types = parsed_types
                                            end
                                        end

                                        local tile = Tile.new(tile_x * self.tile_size, tile_y * self.tile_size,
                                            tileset_image, tileset.image, collides, quad, leafs, final_density) -- Pass final_density here
                                        table.insert(self.tiles, tile)
                                        self.tile_grid[string.format("%d;%d", tile_x, tile_y)] = tile

                                        if grass_density_prop or grass_types_prop then
                                            if final_density > 0 then -- Only place grass if density is positive
                                                self.grass_manager:place_tile({ x = tile_x, y = tile_y }, final_density,
                                                    final_grass_types)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if spawn_point_gid == -1 then
        -- Fallback if no spawn point is found
        self.player_spawn = { tile_x = 5, tile_y = 5 }
    end
end

---Returns the player spawn position in absolute pixel coordinates.
---@return number, number The x and y coordinates in pixels.
function TileMap:getPlayerSpawnAbsolute()
    return self.player_spawn.tile_x * self.tile_size, self.player_spawn.tile_y * self.tile_size
end

function TileMap:update(dt)
    self.wind_manager:update(dt)

    if self.particleSystem then
        for _, tile in ipairs(self.tiles) do
            if tile.leafs and math.random() < 0.02 then
                local random_vx = self.wind_manager.wind_x + math.random(-10, 10)
                local random_vy = self.wind_manager.wind_y + math.random(-10, 10)
                self.particleSystem:emit(
                    tile.x + math.random(0, self.tile_size),
                    tile.y + math.random(0, self.tile_size - 4),
                    random_vx,
                    random_vy,
                    math.random(2, 5),
                    nil,
                    LeafParticle
                )
            end
        end

        self.particleSystem:update(dt)
        for _, p in ipairs(self.particleSystem.particles) do
            p.vx = p.vx + self.wind_manager.wind_x * dt
            p.vy = p.vy + self.wind_manager.wind_y * dt
        end
    end
end

---Draws all tiles in the map.
function TileMap:draw(camera, canvas_w, canvas_h)
    love.graphics.setColor(1, 1, 1)

    local start_tile_x = math.floor(camera.x / self.tile_size)
    local start_tile_y = math.floor(camera.y / self.tile_size)
    local end_tile_x   = start_tile_x + math.ceil(canvas_w / self.tile_size) + 1
    local end_tile_y   = start_tile_y + math.ceil(canvas_h / self.tile_size) + 1

    for y = start_tile_y, end_tile_y do
        for x = start_tile_x, end_tile_x do
            local tile = self.tile_grid[string.format("%d;%d", x, y)]
            if tile then
                tile:draw()
            end
        end
    end

    if self.particleSystem then
        self.particleSystem:draw()
    end
end

---Returns the tile at the given pixel coordinates.
---@param pixel_x number
---@param pixel_y number
---@return Tile|nil
function TileMap:getTileAtPixel(pixel_x, pixel_y)
    local tile_x = math.floor(pixel_x / self.tile_size)
    local tile_y = math.floor(pixel_y / self.tile_size)
    return self.tile_grid[string.format("%d;%d", tile_x, tile_y)]
end

---Checks AABB collision against all collidable tiles.
---@param x number The X position of the object.
---@param y number The Y position of the object.
---@param w number The object's width.
---@param h number The object's height.
---@return boolean True if any collidable tile overlaps the box.
function TileMap:checkCollision(x, y, w, h)
    local start_tile_x = math.floor(x / self.tile_size)
    local end_tile_x   = math.floor((x + w) / self.tile_size)
    local start_tile_y = math.floor(y / self.tile_size)
    local end_tile_y   = math.floor((y + h) / self.tile_size)

    for ty = start_tile_y, end_tile_y do
        for tx = start_tile_x, end_tile_x do
            local tile = self.tile_grid[string.format("%d;%d", tx, ty)]
            if tile and tile.collides then
                -- Simple AABB check between object and tile
                if x < tile.x + self.tile_size and
                    x + w > tile.x and
                    y < tile.y + self.tile_size and
                    y + h > tile.y then
                    return true
                end
            end
        end
    end
    return false
end

return TileMap
