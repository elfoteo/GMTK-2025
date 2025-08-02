--- A state machine for handling animations.
-- This class manages multiple animation states, each with its own set of frames and delay.
--
---@class AnimationState
---@field images? love.Image[] A list of images (frames) for this state.
---@field path_pattern? string A pattern for the image paths.
---@field frames? number The number of frames in the animation.
---@field reversed_pattern? boolean Whether to load the frames in reverse order.
---@field delay number The delay in seconds between each frame.
---@field loops? boolean Whether the animation should loop. Defaults to true.
---@field on_complete? function An optional function to call when a non-looping animation finishes.

---@class Animated
---@field states table<string, AnimationState> A dictionary of animation states.
---@field current_state string | nil The name of the currently active animation state.
---@field timer number The internal timer used to track elapsed time for frame changes.
---@field current_frame number The index of the current image frame being displayed from the active state.
---@field is_reversed boolean For non-looping animations, indicates if the animation is playing in reverse.
local Animated = {}
Animated.__index = Animated

--- Creates a new Animated state machine.
--- The `states` parameter can now also accept a `path_pattern` and `frames` to automatically load images.
---
--- Example with path_pattern:
---
---    local anim = Animated:new({
---        walk = {
---            path_pattern = "assets/entities/player-walk%d.png",
---            frames = 4,
---            delay = 0.2,
---        }
---    })
---
---@param states table<string, AnimationState> A table of animation states.
---@return Animated The new animated state machine instance.
function Animated:new(states)
    local animation = {}
    setmetatable(animation, Animated)

    for state_name, state_data in pairs(states) do
        state_data.images = state_data.images or {}
        if state_data.path_pattern and state_data.frames then
            if state_data.reversed_pattern then
                for i = state_data.frames, 1, -1 do
                    table.insert(state_data.images, love.graphics.newImage(string.format(state_data.path_pattern, i)))
                end
            else
                for i = 1, state_data.frames do
                    table.insert(state_data.images, love.graphics.newImage(string.format(state_data.path_pattern, i)))
                end
            end
        end
    end

    animation.states = states
    animation.current_state = nil
    animation.timer = 0
    animation.current_frame = 1
    animation.is_finished = false
    animation.is_reversed = false

    return animation
end

---Sets the current animation state, resetting the animation timer and frame.
---If the provided state_name is the same as the current one, this function does nothing.
---@param state_name string The name of the state to switch to. Must be a key in the `states` table.
---@param reversed? boolean Whether to play the animation in reverse. Defaults to false.
function Animated:set_state(state_name, reversed)
    if self.current_state ~= state_name or self.is_reversed ~= reversed then
        self.current_state = state_name
        self.timer = 0
        self.is_reversed = reversed or false
        self.current_frame = self.is_reversed and #self.states[state_name].images or 1
        self.is_finished = false
    end
end

---Updates the animation frame based on the elapsed time for the current state.
---This should be called once per frame.
---@param dt number The time elapsed since the last update in seconds (delta time).
function Animated:update(dt)
    if not self.current_state or self.is_finished then return end

    local state = self.states[self.current_state]
    if not state or not state.images or #state.images == 0 then return end

    self.timer = self.timer + dt
    if self.timer >= state.delay then
        self.timer = self.timer - state.delay
        local loops = state.loops == nil or state.loops -- Default to true

        if self.is_reversed then
            if self.current_frame > 1 then
                self.current_frame = self.current_frame - 1
            else
                if loops then
                    self.current_frame = #state.images
                else
                    self.is_finished = true
                    if state.on_complete then
                        state.on_complete()
                    end
                end
            end
        else
            if self.current_frame < #state.images then
                self.current_frame = self.current_frame + 1
            else
                if loops then
                    self.current_frame = 1
                else
                    self.is_finished = true
                    if state.on_complete then
                        state.on_complete()
                    end
                end
            end
        end
    end
end

---Draws the current frame of the active animation state.
---@param x number The x-coordinate to draw the animation at.
---@param y number The y-coordinate to draw the animation at.
---@param r? number The rotation of the animation in radians. Defaults to 0.
---@param sx? number The scale factor in the x-direction. Defaults to 1.
---@param sy? number The scale factor in the y-direction. Defaults to 1.
---@param ox? number The origin offset in the x-direction. Defaults to 0.
---@param oy? number The origin offset in the y-direction. Defaults to 0.
function Animated:draw(x, y, r, sx, sy, ox, oy)
    if not self.current_state then return end

    local state = self.states[self.current_state]
    if not state or not state.images or #state.images == 0 then return end

    local image = state.images[self.current_frame]
    if image then
        love.graphics.draw(image, x, y, r, sx, sy, ox, oy)
    end
end

return Animated