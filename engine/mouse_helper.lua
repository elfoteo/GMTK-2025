---@class MouseHelper
local MouseHelper = {}

--- Converts canvas coordinates to world coordinates.
---@param camera Camera The camera object.
---@param canvas_coords {x: number, y: number} The canvas coordinates.
---@return {x: number, y: number} The world coordinates.
function MouseHelper.get_world_coords(camera, canvas_coords)
    local world_x = canvas_coords.x + camera.x
    local world_y = canvas_coords.y + camera.y
    return { x = world_x, y = world_y }
end

return MouseHelper
