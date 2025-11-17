#!/usr/bin/env lua
--[[
    Looting Module Unit Tests
    Tests all looting functionality including bag checking, corpse detection, and skinning
]]

-- Load the looting module
local lootingPath = "../core/looting.lua"
local file = io.open(lootingPath, "r")
if not file then
    error("Failed to open looting.lua - run from test/ directory")
end
local lootingCode = file:read("*all")
file:close()

-- ============================================
-- MOCK WOW API
-- ============================================

-- Mock time
local mockTime = 0
function GetTime()
    return mockTime
end

-- Mock bag system
local mockBags = {}

function GetContainerNumSlots(bag)
    if mockBags[bag] then
        return mockBags[bag].numSlots
    end
    return nil
end

function GetContainerItemInfo(bag, slot)
    if mockBags[bag] and mockBags[bag].items[slot] then
        return mockBags[bag].items[slot]
    end
    return nil
end

-- Mock objects system
local mockObjects = {}
local mockPlayer = nil

function Objects()
    return mockObjects
end

function ObjectType(obj)
    return obj.type
end

function ObjectPosition(obj)
    return obj.x, obj.y, obj.z
end

function UnitExists(unit)
    return unit ~= nil
end

function UnitCanBeLooted(unit)
    return unit.canLoot or false
end

function UnitCanBeSkinned(unit)
    return unit.canSkin or false
end

function UnitGUID(unit)
    return unit.guid or tostring(unit)
end

-- Mock interaction
local mockInteractCalled = false
local mockInteractUnit = nil

function InteractUnit(unit)
    mockInteractCalled = true
    mockInteractUnit = unit
end

function TargetUnit(unit)
    -- No-op for testing
end

function CastSpellByName(spell)
    -- No-op for testing
end

-- Mock loot frame
_G.LootFrame = {
    shown = false,
    IsShown = function(self) return self.shown end
}

function CloseLoot()
    _G.LootFrame.shown = false
end

-- Mock spell checking
local mockHasSkinning = false

function IsPlayerSpell(spellId)
    if mockHasSkinning then
        return spellId == 8613 or spellId == 8617 or spellId == 8618 or spellId == 10768
    end
    return false
end

function GetSpellInfo(spellId)
    if mockHasSkinning and spellId == 8613 then
        return "Skinning"
    end
    return nil
end

-- Mock state machine
_G.StateMachine = {
    STATES = {
        LOOTING = "LOOTING",
        IDLE = "IDLE",
        FIGHTING = "FIGHTING"
    },
    currentState = "IDLE",
    SetState = function(state)
        _G.StateMachine.currentState = state
    end,
    IsState = function(state)
        return _G.StateMachine.currentState == state
    end
}

-- ============================================
-- LOAD LOOTING MODULE
-- ============================================

local loadFunc, loadErr = (load or loadstring)(lootingCode, "looting.lua")
if not loadFunc then
    error("Failed to compile looting.lua: " .. tostring(loadErr))
end

local Looting = loadFunc()
if not Looting then
    error("looting.lua did not return a module table")
end

-- ============================================
-- TEST FRAMEWORK
-- ============================================

local totalTests = 0
local passedTests = 0
local failedTests = 0

local function assert_true(condition, testName)
    totalTests = totalTests + 1
    if condition then
        passedTests = passedTests + 1
        print("Testing: " .. testName .. " ... ✓ PASSED")
    else
        failedTests = failedTests + 1
        print("Testing: " .. testName .. " ... ✗ FAILED")
        error("ASSERTION FAILED: " .. testName)
    end
end

local function assert_equals(actual, expected, testName)
    totalTests = totalTests + 1
    if actual == expected then
        passedTests = passedTests + 1
        print("Testing: " .. testName .. " ... ✓ PASSED")
    else
        failedTests = failedTests + 1
        print("Testing: " .. testName .. " ... ✗ FAILED")
        error(string.format("ASSERTION FAILED: %s (expected %s, got %s)", testName, tostring(expected), tostring(actual)))
    end
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function resetMocks()
    mockTime = 0
    mockBags = {}
    mockObjects = {}
    mockPlayer = nil
    mockInteractCalled = false
    mockInteractUnit = nil
    mockHasSkinning = false
    _G.LootFrame.shown = false
    _G.StateMachine.currentState = "IDLE"
    Looting.skinnedCorpses = {}
    Looting.lastLootTime = 0
    Looting.lastSkinTime = 0
end

local function createBag(bag, numSlots, filledSlots)
    mockBags[bag] = {
        numSlots = numSlots,
        items = {}
    }
    for i = 1, filledSlots do
        mockBags[bag].items[i] = {itemID = 1234}
    end
end

local function createPlayer(x, y, z)
    mockPlayer = {type = 7, x = x or 0, y = y or 0, z = z or 0}
    table.insert(mockObjects, mockPlayer)
    return mockPlayer
end

local function createCorpse(x, y, z, canLoot, canSkin, guid)
    local corpse = {
        type = 5,
        x = x,
        y = y,
        z = z,
        canLoot = canLoot,
        canSkin = canSkin,
        guid = guid or string.format("corpse_%d_%d", x, y)
    }
    table.insert(mockObjects, corpse)
    return corpse
end

-- ============================================
-- TESTS: BAG SPACE
-- ============================================

print("\n=== Running Looting Module Unit Tests ===\n")

-- Test 1: GetFreeBagSlots returns 0 when no bags
resetMocks()
assert_equals(Looting.GetFreeBagSlots(), 0, "GetFreeBagSlots returns 0 with no bags")

-- Test 2: GetFreeBagSlots counts empty slots
resetMocks()
createBag(0, 16, 0)  -- Backpack with 16 empty slots
assert_equals(Looting.GetFreeBagSlots(), 16, "GetFreeBagSlots counts empty slots")

-- Test 3: GetFreeBagSlots ignores filled slots
resetMocks()
createBag(0, 16, 10)  -- 10 filled, 6 empty
assert_equals(Looting.GetFreeBagSlots(), 6, "GetFreeBagSlots ignores filled slots")

-- Test 4: GetFreeBagSlots counts multiple bags
resetMocks()
createBag(0, 16, 10)  -- 6 free
createBag(1, 12, 8)   -- 4 free
createBag(2, 14, 14)  -- 0 free
assert_equals(Looting.GetFreeBagSlots(), 10, "GetFreeBagSlots counts multiple bags")

-- Test 5: HasBagSpace returns true with space
resetMocks()
createBag(0, 16, 10)
assert_true(Looting.HasBagSpace(1), "HasBagSpace returns true with space")

-- Test 6: HasBagSpace returns false without space
resetMocks()
createBag(0, 16, 16)
assert_true(not Looting.HasBagSpace(1), "HasBagSpace returns false without space")

-- Test 7: HasBagSpace checks minimum slots
resetMocks()
createBag(0, 16, 10)  -- 6 free
assert_true(not Looting.HasBagSpace(10), "HasBagSpace checks minimum slots")

-- ============================================
-- TESTS: CORPSE DETECTION
-- ============================================

-- Test 8: GetLootableCorpses returns empty with no corpses
resetMocks()
createPlayer(0, 0, 0)
local corpses = Looting.GetLootableCorpses()
assert_equals(#corpses, 0, "GetLootableCorpses returns empty with no corpses")

-- Test 9: GetLootableCorpses finds nearby lootable corpse
resetMocks()
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, true, false)  -- 3 yards away, lootable
corpses = Looting.GetLootableCorpses()
assert_equals(#corpses, 1, "GetLootableCorpses finds nearby lootable corpse")

-- Test 10: GetLootableCorpses ignores non-lootable corpses
resetMocks()
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, false, false)  -- Not lootable
corpses = Looting.GetLootableCorpses()
assert_equals(#corpses, 0, "GetLootableCorpses ignores non-lootable corpses")

-- Test 11: GetLootableCorpses filters by distance
resetMocks()
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, true, false)   -- In range
createCorpse(10, 0, 0, true, false)  -- Out of range
corpses = Looting.GetLootableCorpses()
assert_equals(#corpses, 1, "GetLootableCorpses filters by distance")

-- Test 12: GetLootableCorpses sorts by distance
resetMocks()
createPlayer(0, 0, 0)
createCorpse(5, 0, 0, true, false)  -- Further
createCorpse(2, 0, 0, true, false)  -- Closer
corpses = Looting.GetLootableCorpses()
assert_true(corpses[1].distance < corpses[2].distance, "GetLootableCorpses sorts by distance")

-- Test 13: GetSkinnableCorpses finds skinnable corpse
resetMocks()
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, false, true)  -- Skinnable
corpses = Looting.GetSkinnableCorpses()
assert_equals(#corpses, 1, "GetSkinnableCorpses finds skinnable corpse")

-- Test 14: GetSkinnableCorpses ignores non-skinnable corpses
resetMocks()
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, false, false)  -- Not skinnable
corpses = Looting.GetSkinnableCorpses()
assert_equals(#corpses, 0, "GetSkinnableCorpses ignores non-skinnable corpses")

-- Test 15: GetSkinnableCorpses skips already skinned corpses
resetMocks()
createPlayer(0, 0, 0)
local corpse = createCorpse(3, 0, 0, false, true, "test_guid_1")
Looting.MarkAsSkinned("test_guid_1")
corpses = Looting.GetSkinnableCorpses()
assert_equals(#corpses, 0, "GetSkinnableCorpses skips already skinned corpses")

-- ============================================
-- TESTS: LOOT WINDOW
-- ============================================

-- Test 16: IsLootWindowOpen detects open window
resetMocks()
_G.LootFrame.shown = true
assert_true(Looting.IsLootWindowOpen(), "IsLootWindowOpen detects open window")

-- Test 17: IsLootWindowOpen detects closed window
resetMocks()
_G.LootFrame.shown = false
assert_true(not Looting.IsLootWindowOpen(), "IsLootWindowOpen detects closed window")

-- Test 18: CloseLootWindow closes loot frame
resetMocks()
_G.LootFrame.shown = true
Looting.CloseLootWindow()
assert_true(not _G.LootFrame.shown, "CloseLootWindow closes loot frame")

-- ============================================
-- TESTS: LOOTING EXECUTION
-- ============================================

-- Test 19: LootCorpse interacts with corpse
resetMocks()
mockTime = 100
Looting.lastLootTime = 0
createPlayer(0, 0, 0)
local corpse = createCorpse(3, 0, 0, true, false)
local result = Looting.LootCorpse(corpse)
assert_true(result, "LootCorpse interacts with corpse")
assert_true(mockInteractCalled, "LootCorpse calls InteractUnit")

-- Test 20: LootCorpse respects loot delay
resetMocks()
mockTime = 100
Looting.lastLootTime = 99.8  -- 0.2 seconds ago (< 0.3 delay)
createPlayer(0, 0, 0)
corpse = createCorpse(3, 0, 0, true, false)
result = Looting.LootCorpse(corpse)
assert_true(not result, "LootCorpse respects loot delay")

-- Test 21: LootCorpse fails on non-lootable unit
resetMocks()
mockTime = 100
createPlayer(0, 0, 0)
corpse = createCorpse(3, 0, 0, false, false)  -- Not lootable
result = Looting.LootCorpse(corpse)
assert_true(not result, "LootCorpse fails on non-lootable unit")

-- ============================================
-- TESTS: SKINNING
-- ============================================

-- Test 22: HasBeenSkinned tracks skinned corpses
resetMocks()
assert_true(not Looting.HasBeenSkinned("guid1"), "HasBeenSkinned returns false initially")
Looting.MarkAsSkinned("guid1")
assert_true(Looting.HasBeenSkinned("guid1"), "HasBeenSkinned returns true after marking")

-- Test 23: CanPlayerSkin detects skinning skill
resetMocks()
mockHasSkinning = false
assert_true(not Looting.CanPlayerSkin(), "CanPlayerSkin returns false without skill")
mockHasSkinning = true
assert_true(Looting.CanPlayerSkin(), "CanPlayerSkin returns true with skill")

-- Test 24: SkinCorpse fails without skinning skill
resetMocks()
mockHasSkinning = false
mockTime = 100
createPlayer(0, 0, 0)
corpse = createCorpse(3, 0, 0, false, true)
result = Looting.SkinCorpse(corpse)
assert_true(not result, "SkinCorpse fails without skinning skill")

-- Test 25: SkinCorpse succeeds with skill
resetMocks()
mockHasSkinning = true
mockTime = 100
Looting.lastSkinTime = 0
createPlayer(0, 0, 0)
corpse = createCorpse(3, 0, 0, false, true, "skin_guid_1")
result = Looting.SkinCorpse(corpse)
assert_true(result, "SkinCorpse succeeds with skill")
assert_true(Looting.HasBeenSkinned("skin_guid_1"), "SkinCorpse marks corpse as skinned")

-- Test 26: SkinCorpse respects skin delay
resetMocks()
mockHasSkinning = true
mockTime = 100
Looting.lastSkinTime = 99.8  -- 0.2 seconds ago (< 0.5 delay)
createPlayer(0, 0, 0)
corpse = createCorpse(3, 0, 0, false, true)
result = Looting.SkinCorpse(corpse)
assert_true(not result, "SkinCorpse respects skin delay")

-- Test 27: SkinCorpse skips already skinned corpses
resetMocks()
mockHasSkinning = true
mockTime = 100
Looting.lastSkinTime = 0
createPlayer(0, 0, 0)
corpse = createCorpse(3, 0, 0, false, true, "skin_guid_2")
Looting.MarkAsSkinned("skin_guid_2")
result = Looting.SkinCorpse(corpse)
assert_true(not result, "SkinCorpse skips already skinned corpses")

-- ============================================
-- TESTS: MAIN LOOTING LOOP
-- ============================================

-- Test 28: ExecuteLooting sets LOOTING state
resetMocks()
createBag(0, 16, 0)  -- Has bag space
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, true, false)
mockTime = 100
Looting.ExecuteLooting()
assert_equals(_G.StateMachine.currentState, "LOOTING", "ExecuteLooting sets LOOTING state")

-- Test 29: ExecuteLooting prioritizes looting over skinning
resetMocks()
mockHasSkinning = true
createBag(0, 16, 0)
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, true, false)   -- Lootable
createCorpse(4, 0, 0, false, true)   -- Skinnable
mockTime = 100
Looting.ExecuteLooting()
-- Should interact with lootable corpse, not skin
assert_true(mockInteractCalled, "ExecuteLooting prioritizes looting")

-- Test 30: ExecuteLooting skins when no loot available
resetMocks()
mockHasSkinning = true
createBag(0, 16, 0)
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, false, true, "exec_guid_1")  -- Only skinnable
mockTime = 100
Looting.lastSkinTime = 0
Looting.ExecuteLooting()
assert_true(Looting.HasBeenSkinned("exec_guid_1"), "ExecuteLooting skins when no loot")

-- Test 31: ExecuteLooting skips when no bag space
resetMocks()
createBag(0, 16, 16)  -- No space
createPlayer(0, 0, 0)
createCorpse(3, 0, 0, true, false)
mockTime = 100
Looting.ExecuteLooting()
assert_true(not mockInteractCalled, "ExecuteLooting skips when no bag space")

-- Test 32: MarkAsSkinned cleans up old entries
resetMocks()
mockTime = 0
Looting.MarkAsSkinned("old_guid_1")
mockTime = 301  -- 5+ minutes later
Looting.MarkAsSkinned("new_guid_1")
-- Old GUID should be cleaned up
assert_true(not Looting.HasBeenSkinned("old_guid_1"), "MarkAsSkinned cleans up old entries")
assert_true(Looting.HasBeenSkinned("new_guid_1"), "MarkAsSkinned keeps recent entries")

-- ============================================
-- TEST RESULTS
-- ============================================

print("\n=== Test Results ===")
print("Passed: " .. passedTests)
print("Failed: " .. failedTests)
print("Total: " .. totalTests)

if failedTests == 0 then
    print("\n✓ ALL TESTS PASSED!\n")
    os.exit(0)
else
    print("\n✗ SOME TESTS FAILED\n")
    os.exit(1)
end
