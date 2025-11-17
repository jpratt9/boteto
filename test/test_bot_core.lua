#!/usr/bin/env lua
--[[
    Bot Core Unit Tests
    Run with: lua test_bot_core.lua
]]

-- Mock WoW API
local mockObjects = {}
local mockObjectTypes = {}
local mockObjectPositions = {}

function Objects()
    return mockObjects
end

function ObjectType(obj)
    return mockObjectTypes[obj] or 0
end

function ObjectPosition(obj)
    local pos = mockObjectPositions[obj]
    if pos then
        return pos.x, pos.y, pos.z
    end
    return 0, 0, 0
end

function UnitCanBeLooted(obj)
    return false
end

function GetTime()
    return os.clock()
end

-- Mock global state
_G = _G or {}
_G.BotEnabled = false

-- ============================================
-- BOT CORE FUNCTIONS (extracted from main.lua)
-- ============================================

-- Get player
local function GetPlayer()
    local objs = Objects()
    for _, obj in pairs(objs) do
        if ObjectType(obj) == 7 then
            return obj
        end
    end
    return nil
end

-- Get nearby alive enemies
local function GetEnemies(maxDistance)
    local enemies = {}
    local player = GetPlayer()
    if not player then return enemies end

    local px, py, pz = ObjectPosition(player)
    local objs = Objects()

    for _, obj in pairs(objs) do
        local objType = ObjectType(obj)

        -- Only process units (type 3-6), but skip corpses (type 5)
        if objType >= 3 and objType <= 6 and objType ~= 5 then
            local ox, oy, oz = ObjectPosition(obj)
            local dist = math.sqrt((px-ox)^2 + (py-oy)^2 + (pz-oz)^2)

            if dist <= maxDistance then
                -- Skip if can be looted (dead)
                local canLoot = UnitCanBeLooted and UnitCanBeLooted(obj)
                if not canLoot then
                    table.insert(enemies, {obj = obj, distance = dist})
                end
            end
        end
    end

    table.sort(enemies, function(a, b) return a.distance < b.distance end)
    return enemies
end

-- ============================================
-- TEST SUITE
-- ============================================

local testsPassed = 0
local testsFailed = 0

-- Simple assertion helper
local function assert_test(condition, message)
    if not condition then
        error("ASSERTION FAILED: " .. message)
    end
end

-- Helper to run a test
local function runTest(name, testFunc)
    io.write("Testing: " .. name .. " ... ")
    local success, err = pcall(testFunc)
    if success then
        print("✓ PASSED")
        testsPassed = testsPassed + 1
    else
        print("✗ FAILED")
        print("  Error: " .. tostring(err))
        testsFailed = testsFailed + 1
    end
end

-- Reset state before each test
local function resetState()
    mockObjects = {}
    mockObjectTypes = {}
    mockObjectPositions = {}
    _G.BotEnabled = false
end

print("\n=== Running Bot Core Unit Tests ===\n")

-- Test 1: GetPlayer returns nil when no player exists
runTest("GetPlayer returns nil when no player", function()
    resetState()
    local player = GetPlayer()
    assert_test(player == nil, "Should return nil when no player exists")
end)

-- Test 2: GetPlayer finds player object
runTest("GetPlayer finds player object", function()
    resetState()
    local playerObj = "player_123"
    mockObjects = {playerObj, "npc_456", "mob_789"}
    mockObjectTypes[playerObj] = 7  -- Type 7 is player
    mockObjectTypes["npc_456"] = 3
    mockObjectTypes["mob_789"] = 3

    local player = GetPlayer()
    assert_test(player == playerObj, "Should find player object")
end)

-- Test 3: GetPlayer finds player among multiple objects
runTest("GetPlayer finds player among many objects", function()
    resetState()
    local playerObj = "player_123"
    mockObjects = {"npc_1", "npc_2", "npc_3", playerObj, "mob_1", "mob_2"}
    mockObjectTypes["npc_1"] = 3
    mockObjectTypes["npc_2"] = 3
    mockObjectTypes["npc_3"] = 3
    mockObjectTypes[playerObj] = 7
    mockObjectTypes["mob_1"] = 4
    mockObjectTypes["mob_2"] = 4

    local player = GetPlayer()
    assert_test(player == playerObj, "Should find player among many objects")
end)

-- Test 4: GetEnemies returns empty when no player
runTest("GetEnemies returns empty when no player", function()
    resetState()
    local enemies = GetEnemies(40)
    assert_test(#enemies == 0, "Should return empty table when no player")
end)

-- Test 5: GetEnemies finds nearby enemy
runTest("GetEnemies finds nearby enemy", function()
    resetState()
    local playerObj = "player_123"
    local enemyObj = "enemy_456"

    mockObjects = {playerObj, enemyObj}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[enemyObj] = 3  -- Type 3 is unit

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[enemyObj] = {x = 10, y = 0, z = 0}  -- 10 units away

    local enemies = GetEnemies(40)
    assert_test(#enemies == 1, "Should find 1 enemy")
    assert_test(enemies[1].obj == enemyObj, "Should be the correct enemy")
    assert_test(math.abs(enemies[1].distance - 10) < 0.01, "Distance should be ~10")
end)

-- Test 6: GetEnemies filters by distance
runTest("GetEnemies filters by distance", function()
    resetState()
    local playerObj = "player_123"
    local nearEnemy = "enemy_near"
    local farEnemy = "enemy_far"

    mockObjects = {playerObj, nearEnemy, farEnemy}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[nearEnemy] = 3
    mockObjectTypes[farEnemy] = 3

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[nearEnemy] = {x = 20, y = 0, z = 0}  -- 20 units away
    mockObjectPositions[farEnemy] = {x = 50, y = 0, z = 0}   -- 50 units away

    local enemies = GetEnemies(30)  -- Max 30 units
    assert_test(#enemies == 1, "Should find only 1 enemy within range")
    assert_test(enemies[1].obj == nearEnemy, "Should be the near enemy")
end)

-- Test 7: GetEnemies sorts by distance
runTest("GetEnemies sorts by distance", function()
    resetState()
    local playerObj = "player_123"
    local enemy1 = "enemy_1"
    local enemy2 = "enemy_2"
    local enemy3 = "enemy_3"

    mockObjects = {playerObj, enemy1, enemy2, enemy3}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[enemy1] = 3
    mockObjectTypes[enemy2] = 3
    mockObjectTypes[enemy3] = 3

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[enemy1] = {x = 30, y = 0, z = 0}  -- 30 units
    mockObjectPositions[enemy2] = {x = 10, y = 0, z = 0}  -- 10 units (closest)
    mockObjectPositions[enemy3] = {x = 20, y = 0, z = 0}  -- 20 units

    local enemies = GetEnemies(40)
    assert_test(#enemies == 3, "Should find 3 enemies")
    assert_test(enemies[1].obj == enemy2, "Closest should be first")
    assert_test(enemies[2].obj == enemy3, "Medium distance second")
    assert_test(enemies[3].obj == enemy1, "Farthest should be last")
end)

-- Test 8: GetEnemies skips corpses (type 5)
runTest("GetEnemies skips corpses", function()
    resetState()
    local playerObj = "player_123"
    local aliveEnemy = "enemy_alive"
    local corpse = "enemy_corpse"

    mockObjects = {playerObj, aliveEnemy, corpse}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[aliveEnemy] = 3
    mockObjectTypes[corpse] = 5  -- Type 5 is corpse

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[aliveEnemy] = {x = 10, y = 0, z = 0}
    mockObjectPositions[corpse] = {x = 15, y = 0, z = 0}

    local enemies = GetEnemies(40)
    assert_test(#enemies == 1, "Should find only 1 enemy (skip corpse)")
    assert_test(enemies[1].obj == aliveEnemy, "Should be the alive enemy")
end)

-- Test 9: GetEnemies handles 3D distance
runTest("GetEnemies calculates 3D distance", function()
    resetState()
    local playerObj = "player_123"
    local enemyObj = "enemy_456"

    mockObjects = {playerObj, enemyObj}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[enemyObj] = 3

    -- Player at origin, enemy at (3, 4, 0) - should be 5 units away
    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[enemyObj] = {x = 3, y = 4, z = 0}

    local enemies = GetEnemies(40)
    assert_test(#enemies == 1, "Should find 1 enemy")
    assert_test(math.abs(enemies[1].distance - 5) < 0.01, "Distance should be ~5 (3-4-5 triangle)")
end)

-- Test 10: GetEnemies handles multiple unit types (3-6, excluding 5)
runTest("GetEnemies handles multiple unit types", function()
    resetState()
    local playerObj = "player_123"
    local type3 = "unit_type3"
    local type4 = "unit_type4"
    local type5 = "unit_type5"  -- Should be excluded
    local type6 = "unit_type6"

    mockObjects = {playerObj, type3, type4, type5, type6}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[type3] = 3
    mockObjectTypes[type4] = 4
    mockObjectTypes[type5] = 5  -- Corpse - excluded
    mockObjectTypes[type6] = 6

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[type3] = {x = 10, y = 0, z = 0}
    mockObjectPositions[type4] = {x = 11, y = 0, z = 0}
    mockObjectPositions[type5] = {x = 12, y = 0, z = 0}
    mockObjectPositions[type6] = {x = 13, y = 0, z = 0}

    local enemies = GetEnemies(40)
    assert_test(#enemies == 3, "Should find 3 enemies (types 3, 4, 6)")

    -- Verify type 5 is excluded
    for _, enemy in ipairs(enemies) do
        assert_test(enemy.obj ~= type5, "Should not include type 5 (corpse)")
    end
end)

-- Test 11: GetEnemies with exact distance boundary
runTest("GetEnemies with exact distance boundary", function()
    resetState()
    local playerObj = "player_123"
    local exactEnemy = "enemy_exact"

    mockObjects = {playerObj, exactEnemy}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[exactEnemy] = 3

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[exactEnemy] = {x = 30, y = 0, z = 0}  -- Exactly 30 units

    local enemies = GetEnemies(30)  -- Max distance 30
    assert_test(#enemies == 1, "Enemy at exact max distance should be included")
end)

-- Test 12: GetEnemies with no enemies in range
runTest("GetEnemies with no enemies in range", function()
    resetState()
    local playerObj = "player_123"
    local farEnemy = "enemy_far"

    mockObjects = {playerObj, farEnemy}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[farEnemy] = 3

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[farEnemy] = {x = 100, y = 0, z = 0}

    local enemies = GetEnemies(40)
    assert_test(#enemies == 0, "Should find no enemies when all out of range")
end)

-- Test 13: GetEnemies with many enemies
runTest("GetEnemies with many enemies", function()
    resetState()
    local playerObj = "player_123"
    mockObjects = {playerObj}
    mockObjectTypes[playerObj] = 7
    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}

    -- Add 50 enemies at various distances
    for i = 1, 50 do
        local enemy = "enemy_" .. i
        table.insert(mockObjects, enemy)
        mockObjectTypes[enemy] = 3
        mockObjectPositions[enemy] = {x = i, y = 0, z = 0}  -- Distance = i
    end

    local enemies = GetEnemies(25)  -- Get enemies within 25 units
    assert_test(#enemies == 25, "Should find 25 enemies within range")

    -- Verify sorting
    for i = 1, #enemies - 1 do
        assert_test(enemies[i].distance <= enemies[i+1].distance, "Enemies should be sorted by distance")
    end
end)

-- Test 14: GetEnemies with Z-axis distance
runTest("GetEnemies with Z-axis distance", function()
    resetState()
    local playerObj = "player_123"
    local enemyObj = "enemy_456"

    mockObjects = {playerObj, enemyObj}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[enemyObj] = 3

    -- Player at origin, enemy 10 units above on Z axis
    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[enemyObj] = {x = 0, y = 0, z = 10}

    local enemies = GetEnemies(40)
    assert_test(#enemies == 1, "Should find enemy on different Z level")
    assert_test(math.abs(enemies[1].distance - 10) < 0.01, "Z-axis distance should be calculated")
end)

-- Test 15: GetEnemies ignores non-unit objects
runTest("GetEnemies ignores non-unit objects", function()
    resetState()
    local playerObj = "player_123"
    local enemy = "enemy_unit"
    local gameObject = "object_123"
    local item = "item_456"

    mockObjects = {playerObj, enemy, gameObject, item}
    mockObjectTypes[playerObj] = 7
    mockObjectTypes[enemy] = 3
    mockObjectTypes[gameObject] = 1  -- Type 1 is game object
    mockObjectTypes[item] = 2         -- Type 2 is item

    mockObjectPositions[playerObj] = {x = 0, y = 0, z = 0}
    mockObjectPositions[enemy] = {x = 10, y = 0, z = 0}
    mockObjectPositions[gameObject] = {x = 15, y = 0, z = 0}
    mockObjectPositions[item] = {x = 20, y = 0, z = 0}

    local enemies = GetEnemies(40)
    assert_test(#enemies == 1, "Should only find unit-type objects")
    assert_test(enemies[1].obj == enemy, "Should be the enemy unit")
end)

-- Print results
print("\n=== Test Results ===")
print("Passed: " .. testsPassed)
print("Failed: " .. testsFailed)
print("Total: " .. (testsPassed + testsFailed))

if testsFailed == 0 then
    print("\n✓ ALL TESTS PASSED!\n")
    os.exit(0)
else
    print("\n✗ SOME TESTS FAILED!\n")
    os.exit(1)
end
