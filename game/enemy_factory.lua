---
-- A factory for creating different types of enemies.
-- This module centralizes the logic for instantiating enemies, making it easy
-- to add new enemy types without modifying the level loading code.
-- @module EnemyFactory

local EnemyFactory = {}

-- A mapping of enemy type names to their respective modules.
local enemy_classes = {
    sandwraith = "game.enemies.sandwraith",
    cogmauler = "game.enemies.cogmauler"
}

---
-- Creates and returns an enemy instance based on its type name.
-- @param type string The type of enemy to create (e.g., "sandwraith").
-- @param scene Scene The scene the enemy will belong to.
-- @param x number The initial x-coordinate for the enemy.
-- @param y number The initial y-coordinate for the enemy.
-- @return Enemy|nil The created enemy instance, or nil if the type is unknown.
function EnemyFactory.create(type, scene, x, y)
    local enemy_path = enemy_classes[type]
    if enemy_path then
        local EnemyClass = require(enemy_path)
        -- The y-offset of -8 seems to be intentional for the sandwraith to spawn
        -- correctly relative to the tile, so we'll keep it for all enemies for now.
        return EnemyClass.new(scene, x, y - 8)
    end
    print("Warning: Unknown enemy type '" .. tostring(type) .. "'")
    return nil
end

return EnemyFactory
