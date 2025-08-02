-- engine/camera.lua

---@class Camera
---@field x number
---@field y number
---@field shakeX number
---@field shakeY number
---@field shakeMagnitude number
---@field shakeTimer number
---@field recoilX number
---@field recoilY number
---@field recoilMagnitude number
---@field recoilAngle number
---@field recoilTimer number
---@field recoilDuration number
---@field follow fun(self: Camera, targetX: number, targetY: number, targetVX: number, targetVY: number, dt: number)
---@field shake fun(self: Camera, magnitude: number, duration: number, x: number, y: number, cameraX: number, cameraY: number)
---@field recoil fun(self: Camera, magnitude: number, duration: number, angle: number)
---@field attach fun(self: Camera)
---@field detach fun(self: Camera)
---@field teleport fun(self: Camera, x: number, y: number)
---@field scene Scene
local Camera = {}
Camera.__index = Camera

function Camera.new(x, y, scene)
    local cam = setmetatable({}, Camera)
    cam.x = x
    cam.y = y
    cam.scene = scene

    -- Shake properties
    cam.shakeX = 0
    cam.shakeY = 0
    cam.shakeMagnitude = 0
    cam.shakeTimer = 0

    -- Recoil properties
    cam.recoilX = 0
    cam.recoilY = 0
    cam.recoilMagnitude = 0
    cam.recoilAngle = 0
    cam.recoilTimer = 0
    cam.recoilDuration = 0

    return cam
end

function Camera:follow(targetX, targetY, targetVX, targetVY, dt)
    local predictionFactor = 0.5 -- How much to predict player movement
    local predictedX = targetX + targetVX * predictionFactor
    local predictedY = targetY + targetVY * predictionFactor

    local targetCameraX = predictedX - self.scene.canvas_w / 2
    local targetCameraY = predictedY - self.scene.canvas_h / 2

    local lerpFactor = 4 -- Controls camera smoothness
    self.x = self.x + (targetCameraX - self.x) * lerpFactor * dt
    self.y = self.y + (targetCameraY - self.y) * lerpFactor * dt

    -- Update shake
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        self.shakeX = (math.random() * 2 - 1) * self.shakeMagnitude
        self.shakeY = (math.random() * 2 - 1) * self.shakeMagnitude
    else
        self.shakeX = 0
        self.shakeY = 0
    end

    -- Update recoil
    if self.recoilTimer > 0 then
        self.recoilTimer = self.recoilTimer - dt
        local progress = self.recoilTimer / self.recoilDuration
        local currentMagnitude = self.recoilMagnitude * progress
        self.recoilX = math.cos(self.recoilAngle) * currentMagnitude
        self.recoilY = math.sin(self.recoilAngle) * currentMagnitude
    else
        self.recoilX = 0
        self.recoilY = 0
    end
end

function Camera:shake(magnitude, duration, x, y, cameraX, cameraY)
    local dist = math.sqrt((x - (cameraX + self.scene.canvas_w / 2)) ^ 2 + (y - (cameraY + self.scene.canvas_h / 2)) ^ 2)
    local maxDist = math.max(self.scene.canvas_w, self.scene.canvas_h) / 2 -- Max distance from center of screen
    local intensity = magnitude * (1 - math.min(dist / maxDist, 1))

    self.shakeMagnitude = intensity
    self.shakeTimer = duration
end

function Camera:recoil(magnitude, duration, angle)
    self.recoilMagnitude = magnitude
    self.recoilDuration = duration
    self.recoilTimer = duration
    self.recoilAngle = angle + math.pi -- Recoil in opposite direction
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(math.floor(-self.x + self.shakeX + self.recoilX), math.floor(-self.y + self.shakeY + self.recoilY))
end

function Camera:detach()
    love.graphics.pop()
end

--- Instantly moves the camera to a new position.
---@param x number The new x-coordinate for the camera.
---@param y number The new y-coordinate for the camera.
function Camera:teleport(x, y)
    self.x = x - self.scene.canvas_w / 2
    self.y = y - self.scene.canvas_h / 2
end

function Camera:toWorld(cx, cy)
    return cx + self.x, cy + self.y
end

return Camera
