---@class SceneManager
---@field currentScene Scene | nil
local SceneManager = {}
SceneManager.__index = SceneManager

SceneManager.currentScene = nil

--- Switches to a new scene.
--- If you pass a Scene *class* (a table with a `.new()`), it'll call `.new()` for you.
--- If you pass an already constructed Scene *instance*, it'll use it directly.
---@param sceneClassOrInstance table  Either a Scene class or a Scene instance.
function SceneManager.gotoScene(sceneClassOrInstance)
    -- 1) Unload old
    if SceneManager.currentScene and SceneManager.currentScene.unload then
        SceneManager.currentScene:unload()
    end

    -- 2) Instantiate if necessary
    local newScene
    if type(sceneClassOrInstance.new) == "function" then
        newScene = sceneClassOrInstance.new()
    else
        newScene = sceneClassOrInstance
    end

    -- 3) Set and load
    SceneManager.currentScene = newScene
    if newScene and newScene.load then
        newScene:load()
    end
end

--- Updates the current scene.
---@param dt number
function SceneManager.update(dt)
    if SceneManager.currentScene and SceneManager.currentScene.update then
        SceneManager.currentScene:update(dt)
    end
end

--- Draws the current scene.
function SceneManager.draw()
    if SceneManager.currentScene and SceneManager.currentScene.draw then
        SceneManager.currentScene:draw()
    end
end

--- Handles key presses.
---@param key string
function SceneManager.keypressed(key)
    if SceneManager.currentScene and SceneManager.currentScene.keypressed then
        SceneManager.currentScene:keypressed(key)
    end
end

--- Handles mouse presses.
---@param x number
---@param y number
---@param button number
function SceneManager.mousepressed(x, y, button)
    if SceneManager.currentScene and SceneManager.currentScene.mousepressed then
        SceneManager.currentScene:mousepressed(x, y, button)
    end
end

--- Handles mouse releases.
---@param x number
---@param y number
---@param button number
function SceneManager.mousereleased(x, y, button)
    if SceneManager.currentScene and SceneManager.currentScene.mousereleased then
        SceneManager.currentScene:mousereleased(x, y, button)
    end
end

return SceneManager
