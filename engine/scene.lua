local Camera = require("engine.camera")

---@class Scene
---@field canvas_w number            Width of the virtual canvas.
---@field canvas_h number            Height of the virtual canvas.
---@field windowW number             Actual window width.
---@field windowH number             Actual window height.
---@field scale number               Scale factor from canvas to window.
---@field offsetX number             X offset to center the canvas.
---@field offsetY number             Y offset to center the canvas.
---@field camera Camera              The scene's camera.
---@field canvas love.Canvas         The scene's camera.
---@field scheduled_events table     A list of events to be executed at a later time.
local Scene = {}
Scene.__index = Scene

---Creates a new Scene.
---@param canvas_w number Width of the virtual canvas.
---@param canvas_h number Height of the virtual canvas.
---@return Scene
function Scene.new(canvas_w, canvas_h)
    local self = setmetatable({
        canvas_w = canvas_w,
        canvas_h = canvas_h,
        windowW  = 0,
        windowH  = 0,
        scale    = 1,
        offsetX  = 0,
        offsetY  = 0,
        canvas   = love.graphics.newCanvas(canvas_w, canvas_h),
        scheduled_events = {}
    }, Scene)
    self.camera = Camera.new(0, 0, self)
    self.canvas:setFilter("nearest", "nearest")
    return self
end

---Recalculates viewport scaling and centering.
function Scene:recalcViewport()
    self.windowW, self.windowH = love.graphics.getDimensions()
    self.scale                 = math.min(self.windowW / self.canvas_w, self.windowH / self.canvas_h)
    self.offsetX               = (self.windowW - self.canvas_w * self.scale) / 2
    self.offsetY               = (self.windowH - self.canvas_h * self.scale) / 2
end

---Converts window coordinates to canvas coordinates.
---@param mx number Window X.
---@param my number Window Y.
---@return number cx Canvas X.
---@return number cy Canvas Y.
function Scene:toCanvas(mx, my)
    return (mx - self.offsetX) / self.scale, (my - self.offsetY) / self.scale
end

---Converts window coordinates to world coordinates.
---@param mx number Window X.
---@param my number Window Y.
---@return number wx World X.
---@return number wy World Y.
function Scene:toWorld(mx, my)
    local cx, cy = self:toCanvas(mx, my)
    return self.camera:toWorld(cx, cy)
end

---Schedules a function to be called after a certain amount of time.
---@param delay number The delay in seconds.
---@param func function The function to call.
function Scene:schedule(delay, func)
    table.insert(self.scheduled_events, { delay = delay, func = func })
end

---Called once when the scene is loaded.
---Override to load assets, initialize entities, etc.
function Scene:load()
    -- Override in subclass
    print("Scene:load()")
end

---Called once when the scene is unloaded.
---Override to clean up assets, entities, etc.
function Scene:unload()
    -- Override in subclass
    print("Scene:unload()")
end

---Updates the scene each frame: viewport + entities.
---@param dt number Time (in seconds) since last frame.
function Scene:update(dt)
    -- Recalculate viewport if window resized or on demandscene
    self:recalcViewport()

    -- Process scheduled events
    for i = #self.scheduled_events, 1, -1 do
        local event = self.scheduled_events[i]
        event.delay = event.delay - dt
        if event.delay <= 0 then
            event.func()
            table.remove(self.scheduled_events, i)
        end
    end
end

---Draws the scene each frame: apply transform + draw entities.
function Scene:draw()
    -- Override in subclass
end

---Called when a key is pressed.
---@param key string
function Scene:keypressed(key)
    -- Override in subclass
end

---Called when the mouse is pressed.
---@param x number Window X.
---@param y number Window Y.
---@param button number Mouse button.
function Scene:mousepressed(x, y, button)
    -- Override in subclass
end

---Called when the mouse is released.
---@param x number Window X.
---@param y number Window Y.
---@param button number Mouse button.
function Scene:mousereleased(x, y, button)
    -- Override in subclass
end

return Scene