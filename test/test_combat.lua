#!/usr/bin/env lua
--[[
    Combat Module Unit Tests
    Run with: lua test_combat.lua
]]

-- Mock WoW API functions
local mockSpellCooldowns = {}
local mockSpellUsability = {}
local mockSpellInfo = {}
local mockUnits = {}
local mockTime = 0

function GetSpellCooldown(spellId)
    local cd = mockSpellCooldowns[spellId]
    if cd then
        return cd.start, cd.duration
    end
    return 0, 0
end

function GetTime()
    return mockTime
end

-- Mock C_Spell API
_G.C_Spell = {
    GetSpellInfo = function(spellId)
        return mockSpellInfo[spellId]
    end,
    IsSpellUsable = function(spellId)
        local usability = mockSpellUsability[spellId]
        if usability then
            return usability.usable, usability.nomana
        end
        return false, false
    end
}

function UnitExists(unit)
    return mockUnits[unit] ~= nil
end

function UnitHealth(unit)
    local u = mockUnits[unit]
    return u and u.health or 100
end

function UnitHealthMax(unit)
    local u = mockUnits[unit]
    return u and u.maxHealth or 100
end

function UnitAffectingCombat(unit)
    local u = mockUnits[unit]
    return u and u.inCombat or false
end

function CastSpellByName(spellName, target)
    -- Mock function, does nothing
    return true
end

function TargetUnit(target)
    -- Mock function, does nothing
    return true
end

-- Mock global functions
_G.GetEnemies = function(maxDistance)
    return {}  -- Return empty by default
end

_G.StateMachine = {
    STATES = {
        IDLE = "IDLE",
        FIGHTING = "FIGHTING"
    },
    IsState = function(state)
        return _G.CURRENT_STATE == state
    end,
    SetState = function(state)
        _G.CURRENT_STATE = state
    end
}

_G.CURRENT_STATE = "IDLE"

_G.CurrentRotation = nil

-- Load the combat module
local Combat = {}

-- Copy the combat module code inline for testing
-- (In production, this would be loaded from combat.lua)

Combat.CAST_DELAY = 0.5
Combat.GCD_THRESHOLD = 1.5
Combat.lastCastTime = 0

function Combat.IsSpellOnCooldown(spellId)
    local start, duration = GetSpellCooldown(spellId)
    if start and duration then
        if duration > Combat.GCD_THRESHOLD then
            return (start > 0)
        end
    end
    return false
end

function Combat.GetSpellCooldownRemaining(spellId)
    local start, duration = GetSpellCooldown(spellId)
    if start and duration and duration > Combat.GCD_THRESHOLD then
        local remaining = (start + duration) - GetTime()
        return math.max(0, remaining)
    end
    return 0
end

function Combat.IsSpellUsable(spellId)
    local spellInfo = C_Spell and C_Spell.GetSpellInfo(spellId)
    if not spellInfo then
        return false
    end

    local usable, nomana = false, false
    if C_Spell and C_Spell.IsSpellUsable then
        usable, nomana = C_Spell.IsSpellUsable(spellId)
    end

    local onCooldown = Combat.IsSpellOnCooldown(spellId)
    return usable and not onCooldown
end

function Combat.IsOnGCD()
    local start, duration = GetSpellCooldown(61304)
    if not start then
        if _G.CurrentRotation and #_G.CurrentRotation > 0 then
            local firstSpell = _G.CurrentRotation[1]
            start, duration = GetSpellCooldown(firstSpell.id)
        end
    end

    if start and duration then
        if duration > 0.5 and duration <= Combat.GCD_THRESHOLD then
            local remaining = (start + duration) - GetTime()
            return remaining > 0
        end
    end
    return false
end

function Combat.CanCastSpell(spellId, target)
    if not Combat.IsSpellUsable(spellId) then
        return false
    end
    if Combat.IsOnGCD() then
        return false
    end
    if GetTime() < Combat.lastCastTime + Combat.CAST_DELAY then
        return false
    end
    if target and not UnitExists(target) then
        return false
    end
    return true
end

function Combat.CastSpell(spellId, target)
    local spellInfo = C_Spell and C_Spell.GetSpellInfo(spellId)
    if not spellInfo then
        return false
    end

    local spellName = spellInfo.name
    local success = false
    if target then
        success = pcall(CastSpellByName, spellName, target)
    else
        success = pcall(CastSpellByName, spellName)
    end

    if success then
        Combat.lastCastTime = GetTime()
        return true
    else
        return false
    end
end

function Combat.GetHealthPercent()
    if UnitHealth and UnitHealthMax then
        local current = UnitHealth("player")
        local max = UnitHealthMax("player")
        if max > 0 then
            return (current / max) * 100
        end
    end
    return 100
end

function Combat.IsInCombat()
    if UnitAffectingCombat then
        return UnitAffectingCombat("player")
    end
    return false
end

-- ============================================
-- TEST SUITE
-- ============================================

local testsPassed = 0
local testsFailed = 0

local function assert_test(condition, message)
    if not condition then
        error("ASSERTION FAILED: " .. message)
    end
end

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

local function resetState()
    mockSpellCooldowns = {}
    mockSpellUsability = {}
    mockSpellInfo = {}
    mockUnits = {}
    mockTime = 0
    Combat.lastCastTime = 0
    _G.CurrentRotation = nil
    _G.CURRENT_STATE = "IDLE"
end

print("\n=== Running Combat Module Unit Tests ===\n")

-- Test 1: IsSpellOnCooldown returns false when no cooldown
runTest("IsSpellOnCooldown returns false when ready", function()
    resetState()
    mockSpellCooldowns[123] = {start = 0, duration = 0}
    assert_test(not Combat.IsSpellOnCooldown(123), "Spell should not be on cooldown")
end)

-- Test 2: IsSpellOnCooldown returns true when on cooldown
runTest("IsSpellOnCooldown returns true when on cooldown", function()
    resetState()
    mockTime = 100
    mockSpellCooldowns[123] = {start = 95, duration = 10}  -- Started 5s ago, 10s duration
    assert_test(Combat.IsSpellOnCooldown(123), "Spell should be on cooldown")
end)

-- Test 3: IsSpellOnCooldown ignores GCD
runTest("IsSpellOnCooldown ignores GCD duration", function()
    resetState()
    mockTime = 100
    mockSpellCooldowns[123] = {start = 99.5, duration = 1.0}  -- GCD-length cooldown
    assert_test(not Combat.IsSpellOnCooldown(123), "GCD should be ignored")
end)

-- Test 4: GetSpellCooldownRemaining calculates correctly
runTest("GetSpellCooldownRemaining calculates time", function()
    resetState()
    mockTime = 100
    mockSpellCooldowns[123] = {start = 95, duration = 10}  -- 5 seconds remaining
    local remaining = Combat.GetSpellCooldownRemaining(123)
    assert_test(math.abs(remaining - 5) < 0.01, "Should have ~5 seconds remaining")
end)

-- Test 5: GetSpellCooldownRemaining returns 0 for ready spell
runTest("GetSpellCooldownRemaining returns 0 when ready", function()
    resetState()
    mockSpellCooldowns[123] = {start = 0, duration = 0}
    assert_test(Combat.GetSpellCooldownRemaining(123) == 0, "Ready spell should have 0 remaining")
end)

-- Test 6: IsSpellUsable checks spell info exists
runTest("IsSpellUsable returns false without spell info", function()
    resetState()
    mockSpellInfo[123] = nil
    assert_test(not Combat.IsSpellUsable(123), "Should return false without spell info")
end)

-- Test 7: IsSpellUsable checks usability
runTest("IsSpellUsable returns true when usable", function()
    resetState()
    mockSpellInfo[123] = {name = "Test Spell"}
    mockSpellUsability[123] = {usable = true, nomana = false}
    mockSpellCooldowns[123] = {start = 0, duration = 0}
    assert_test(Combat.IsSpellUsable(123), "Spell should be usable")
end)

-- Test 8: IsSpellUsable returns false when on cooldown
runTest("IsSpellUsable returns false when on cooldown", function()
    resetState()
    mockTime = 100
    mockSpellInfo[123] = {name = "Test Spell"}
    mockSpellUsability[123] = {usable = true, nomana = false}
    mockSpellCooldowns[123] = {start = 95, duration = 10}
    assert_test(not Combat.IsSpellUsable(123), "Spell on cooldown should not be usable")
end)

-- Test 9: IsOnGCD detects active GCD
runTest("IsOnGCD detects active GCD", function()
    resetState()
    mockTime = 100
    mockSpellCooldowns[61304] = {start = 99.5, duration = 1.0}  -- GCD active
    assert_test(Combat.IsOnGCD(), "Should detect active GCD")
end)

-- Test 10: IsOnGCD returns false when no GCD
runTest("IsOnGCD returns false when GCD expired", function()
    resetState()
    mockTime = 100
    mockSpellCooldowns[61304] = {start = 0, duration = 0}
    assert_test(not Combat.IsOnGCD(), "Should not detect GCD")
end)

-- Test 11: CanCastSpell validates all conditions
runTest("CanCastSpell validates all conditions", function()
    resetState()
    mockTime = 100
    Combat.lastCastTime = 0  -- Ensure no cast delay
    mockSpellInfo[123] = {name = "Test Spell"}
    mockSpellUsability[123] = {usable = true, nomana = false}
    mockSpellCooldowns[123] = {start = 0, duration = 0}
    mockSpellCooldowns[61304] = {start = 0, duration = 0}  -- No GCD
    mockUnits["target"] = {health = 100, maxHealth = 100}

    assert_test(Combat.CanCastSpell(123, "target"), "Should be able to cast")
end)

-- Test 12: CanCastSpell respects cast delay
runTest("CanCastSpell respects cast delay", function()
    resetState()
    mockTime = 100
    Combat.lastCastTime = 99.8  -- Cast 0.2s ago (delay is 0.5s)
    mockSpellInfo[123] = {name = "Test Spell"}
    mockSpellUsability[123] = {usable = true, nomana = false}
    mockSpellCooldowns[123] = {start = 0, duration = 0}

    assert_test(not Combat.CanCastSpell(123), "Should respect cast delay")
end)

-- Test 13: CanCastSpell checks target exists
runTest("CanCastSpell checks target existence", function()
    resetState()
    mockSpellInfo[123] = {name = "Test Spell"}
    mockSpellUsability[123] = {usable = true, nomana = false}
    mockSpellCooldowns[123] = {start = 0, duration = 0}
    mockSpellCooldowns[61304] = {start = 0, duration = 0}

    assert_test(not Combat.CanCastSpell(123, "nonexistent"), "Should fail without target")
end)

-- Test 14: CastSpell executes successfully
runTest("CastSpell executes successfully", function()
    resetState()
    mockTime = 100
    mockSpellInfo[123] = {name = "Test Spell"}

    local result = Combat.CastSpell(123)
    assert_test(result, "CastSpell should return true")
    assert_test(Combat.lastCastTime == 100, "Should update lastCastTime")
end)

-- Test 15: CastSpell fails without spell info
runTest("CastSpell fails without spell info", function()
    resetState()
    mockSpellInfo[123] = nil

    local result = Combat.CastSpell(123)
    assert_test(not result, "CastSpell should fail without spell info")
end)

-- Test 16: GetHealthPercent calculates correctly
runTest("GetHealthPercent calculates correctly", function()
    resetState()
    mockUnits["player"] = {health = 50, maxHealth = 100}

    local hp = Combat.GetHealthPercent()
    assert_test(math.abs(hp - 50) < 0.01, "Health should be 50%")
end)

-- Test 17: GetHealthPercent handles full health
runTest("GetHealthPercent handles full health", function()
    resetState()
    mockUnits["player"] = {health = 100, maxHealth = 100}

    local hp = Combat.GetHealthPercent()
    assert_test(math.abs(hp - 100) < 0.01, "Health should be 100%")
end)

-- Test 18: IsInCombat detects combat state
runTest("IsInCombat detects combat state", function()
    resetState()
    mockUnits["player"] = {inCombat = true}

    assert_test(Combat.IsInCombat(), "Should be in combat")
end)

-- Test 19: IsInCombat detects non-combat state
runTest("IsInCombat detects non-combat state", function()
    resetState()
    mockUnits["player"] = {inCombat = false}

    assert_test(not Combat.IsInCombat(), "Should not be in combat")
end)

-- Test 20: Cast delay prevents spell spam
runTest("Cast delay prevents spell spam", function()
    resetState()
    mockTime = 100
    mockSpellInfo[123] = {name = "Test Spell"}

    -- First cast
    Combat.CastSpell(123)
    assert_test(Combat.lastCastTime == 100, "First cast should succeed")

    -- Try to cast again immediately
    mockTime = 100.1  -- Only 0.1s later
    mockSpellUsability[123] = {usable = true, nomana = false}
    mockSpellCooldowns[123] = {start = 0, duration = 0}
    assert_test(not Combat.CanCastSpell(123), "Should be blocked by cast delay")

    -- Try after delay expires
    mockTime = 100.6  -- 0.6s later (> 0.5s delay)
    assert_test(Combat.CanCastSpell(123), "Should be castable after delay")
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
