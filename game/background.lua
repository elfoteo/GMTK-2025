local SceneManager = require "engine.scene_manager"

-- Configuration: maximum square size
local MAX_SIZE = 40
-- Configuration: target number of squares per layer
local TARGET_SQUARES_PER_LAYER = 10

---@class Square
---@field x number
---@field y number
---@field size number
---@field rotation number
---@field color number[]  -- {r, g, b, a}
---@field direction number
local Square = {}
Square.__index = Square

---Create a new square.
---@param x number
---@param y number
---@param size number
---@param rotation number
---@param color number[]
---@return Square
function Square.new(x, y, size, rotation, color)
    return setmetatable({
        x         = x,
        y         = y,
        size      = size,
        rotation  = rotation,
        color     = color,
        direction = (math.random(0, 1) == 0) and -1 or 1,
    }, Square)
end

---Animate the square.
---@param self Square
---@param dt number
function Square:update(dt)
    -- Rise at a constant speed, rotate slowly, and shrink gradually
    self.y        = self.y - 10 * dt                           -- Constant rise speed
    self.rotation = self.rotation + dt * 0.05 * self.direction -- Slower rotation
    self.size     = self.size - dt * 0.05                      -- Gradual shrinking
end

---Draw centered at (x,y).
---@param self Square
function Square:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", -self.size / 2, -self.size / 2, self.size, self.size)
    love.graphics.pop()
end

---@class Layer
---@field speed number       -- parallax factor
---@field z number           -- draw order
---@field squares Square[]   -- active squares

---@class Background
---@field color number[]      -- background RGBA
---@field layers Layer[]      -- parallax layers
---@field worldcamera Camera
---@field scene Scene
---@field gradient_shader love.Shader
---@field shader_color1 number[]
---@field shader_color2 number[]
local Background = {}
Background.__index = Background

-- Define three layers: far (z=1), mid (z=2), near (z=3)
local LAYER_DEFS = {
    { z = 1, speed = 0.8 },
    { z = 2, speed = 0.9 },
    { z = 3, speed = 0.95 },
}

---Compute world-space view bounds for a given layer.
---Returns x_min, x_max, y_min, y_max.
local function getViewBounds(layer, camera, scene)
    local s = layer.speed
    local dx = camera.x * (s - 1)
    local dy = camera.y * (s - 1)
    local w, h = scene.canvas_w, scene.canvas_h

    local x_min = -dx
    local x_max = x_min + w
    local y_min = -dy
    local y_max = y_min + h

    return x_min, x_max, y_min, y_max
end

local function saturateColor(color_table, factor)
    local r, g, b, a = color_table[1], color_table[2], color_table[3], color_table[4] or 1.0

    -- Calculate luminance (perceived brightness)
    local luminance = 0.299 * r + 0.587 * g + 0.114 * b

    -- Interpolate between grayscale and original color
    local new_r = luminance + (r - luminance) * factor
    local new_g = luminance + (g - luminance) * factor
    local new_b = luminance + (b - luminance) * factor

    -- Clamp values to [0, 1]
    new_r = math.max(0, math.min(1, new_r))
    new_g = math.max(0, math.min(1, new_g))
    new_b = math.max(0, math.min(1, new_b))

    return { new_r, new_g, new_b, a }
end

---Spawn a square completely outside the current view rectangle.
---@param layer table  -- must have .speed
---@param camera Camera
---@param scene Scene
local function spawnSquareInZone(layer, camera, scene, shader_color1, shader_color2)
    -- First compute current view bounds for this layer
    local x_min, x_max, _, y_max = getViewBounds(layer, camera, scene)
    local w, h = scene.canvas_w, scene.canvas_h

    -- Randomize size, then use half-size to inset spawn zone
    local size = math.random(5, MAX_SIZE)
    local half = size * 0.5

    -- Horizontal spawn: allow a margin equal to one screen width + half the size
    local extra = w
    local spawn_x_min = x_min - extra - half
    local spawn_x_max = x_max + extra + half

    -- Vertical spawn: start just below the bottom of the view by half the size
    local spawn_y_min = y_max + half
    local spawn_y_max = y_max + h + half

    -- Pick a random position in that zone
    local x = math.random(spawn_x_min, spawn_x_max)
    local y = math.random(spawn_y_min, spawn_y_max)

    -- Random rotation and a bluish-green color range
    local rot = math.random() * math.pi * 2
    local r = shader_color1[1] + math.random() * (shader_color2[1] - shader_color1[1])
    local g = shader_color1[2] + math.random() * (shader_color2[2] - shader_color1[2])
    local b = shader_color1[3] + math.random() * (shader_color2[3] - shader_color1[3])
    local random_shader_color = { r, g, b, 0.8 }
    local color = saturateColor(random_shader_color, 1.8)

    return Square.new(x, y, size, rot, color)
end

---Initialize background with parallax layers.
---@param camera Camera
---@param scene Scene
---@param shader_color1 number[]
---@param shader_color2 number[]
---@return Background
function Background.new(camera, scene, shader_color1, shader_color2)
    local self = setmetatable({
        shader_color1   = shader_color1,
        shader_color2   = shader_color2,
        layers          = {},
        worldcamera     = camera,
        scene           = scene,
        gradient_shader = love.graphics.newShader([[
            uniform vec4 color1_uniform;
            uniform vec4 color2_uniform;

            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
            {
                vec2 screen_size = love_ScreenSize.xy;

                // Normalize screen coords from 0.0 to 1.0
                vec2 norm = love_PixelCoord / screen_size;

                // Compute gradient factor along the diagonal (top-left to bottom-right)
                float diag = (norm.x + norm.y) * 0.5;

                return mix(color1_uniform, color2_uniform, diag);
            }
        ]])
    }, Background)

    -- Create layers and spawn initial squares
    for _, def in ipairs(LAYER_DEFS) do
        local layer = { speed = def.speed, z = def.z, squares = {} }
        -- Spawn initial squares to reach target count
        for _ = 1, TARGET_SQUARES_PER_LAYER do
            local sq = spawnSquareInZone(layer, camera, scene, self.shader_color1, self.shader_color2)
            -- Randomize initial Y position within the visible canvas area
            sq.y = camera.y + math.random(0, scene.canvas_h)
            table.insert(layer.squares, sq)
        end
        -- Sort squares by size (descending) for consistent depth within layer
        table.sort(layer.squares, function(a, b) return a.size > b.size end)
        table.insert(self.layers, layer)
    end

    -- Sort layers by z (descending) for correct draw order (nearer layers last)
    table.sort(self.layers, function(a, b) return a.z > b.z end)

    return self
end

---Update all squares; spawn new ones and remove those out of view.
---@param self Background
---@param dt number
function Background:update(dt)
    for _, layer in ipairs(self.layers) do
        local squares = layer.squares
        local _, _, y_min, y_max = getViewBounds(layer, self.worldcamera, self.scene)

        local i = 1
        for j = 1, #squares do
            local sq = squares[j]
            sq:update(dt)

            local half_size = sq.size * 0.5
            local visible = sq.size > 0 and (sq.y + half_size >= y_min and sq.y - half_size <= y_max)
            if visible then
                squares[i] = sq
                i = i + 1
            end
        end

        for j = i, #squares do
            squares[j] = nil
        end

        while #squares < TARGET_SQUARES_PER_LAYER do
            squares[#squares + 1] =
                spawnSquareInZone(layer, self.worldcamera, self.scene, self.shader_color1, self.shader_color2)
        end

        table.sort(squares, function(a, b) return a.size > b.size end)
    end
end

---Draw background and all parallax layers.
---@param self Background
function Background:draw()
    local scene_camera = SceneManager.currentScene.camera
    love.graphics.push()
    love.graphics.translate(scene_camera.x - scene_camera.shakeX - scene_camera.recoilX,
        scene_camera.y - scene_camera.shakeY - scene_camera.recoilY)
    love.graphics.setShader(self.gradient_shader)
    self.gradient_shader:send("color1_uniform", self.shader_color1)
    self.gradient_shader:send("color2_uniform", self.shader_color2)
    love.graphics.rectangle("fill", 0, 0, self.scene.canvas_w, self.scene.canvas_h)
    love.graphics.setShader()
    love.graphics.pop()

    for _, layer in ipairs(self.layers) do
        love.graphics.push()
        love.graphics.translate(
            self.worldcamera.x * layer.speed,
            self.worldcamera.y * layer.speed
        )
        for _, sq in ipairs(layer.squares) do
            sq:draw()
        end
        love.graphics.pop()
    end
end

return Background
