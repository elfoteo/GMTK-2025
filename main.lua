package.path             = package.path ..
    ';./?.lua;./?/init.lua;engine/?.lua;engine/ui/?.lua;engine/particles/?.lua;game/?.lua;scenes/?.lua;game/weapons/?.lua;game/projectiles/?.lua'

local SceneManager       = require("engine.scene_manager")
local MainMenuScene    = require("scenes.main_menu_scene")
local WINDOW_W, WINDOW_H = 1280, 720

function love.load(arg)
    -- window & filtering
    love.window.setMode(WINDOW_W, WINDOW_H, {
        vsync = true,
        fullscreen = false,
        fullscreentype = "desktop",
    })
    love.graphics.setDefaultFilter("nearest", "nearest")
    SceneManager.gotoScene(MainMenuScene.new())
end

function love.resize()
    if SceneManager.currentScene and SceneManager.currentScene.recalcViewport then
        SceneManager.currentScene:recalcViewport()
    end
end

function love.update(dt)
    SceneManager.update(dt)
end

function love.draw()
    SceneManager.draw()
end

function love.keypressed(key)
    SceneManager.keypressed(key)
end

function love.mousepressed(x, y, button)
    SceneManager.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    SceneManager.mousereleased(x, y, button)
end
