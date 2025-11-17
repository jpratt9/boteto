#!/usr/bin/env lua
--[[
    State Machine Unit Tests
    Run with: lua test_state_machine.lua
]]

-- Mock WoW API functions for testing
local mockTime = 0
function GetTime()
    mockTime = mockTime + 1
    return mockTime
end

-- Mock global state
_G = _G or {}

-- Load the state machine module from the combined file
-- For now, we'll inline it here. Later we can extract it to a separate file.
local StateMachine = {}

-- State constants
StateMachine.STATES = {
    IDLE = "IDLE",
    FIGHTING = "FIGHTING",
    LOOTING = "LOOTING",
    MOVING = "MOVING",
    RESTING = "RESTING",
    VENDORING = "VENDORING",
    REPAIRING = "REPAIRING",
    TRAINING = "TRAINING",
    QUESTING = "QUESTING",
    GATHERING = "GATHERING",
    SKINNING = "SKINNING",
    DEAD = "DEAD",
    TRAVELING = "TRAVELING",
    MOUNTING = "MOUNTING",
    DISMOUNTING = "DISMOUNTING"
}

-- Current state (global for easy access)
_G.BOTETO_CURRENT_STATE = StateMachine.STATES.IDLE

-- State change history (for debugging)
local stateHistory = {}
local maxHistorySize = 20

-- State change callbacks
local stateChangeCallbacks = {}

-- Set the current bot state
function StateMachine.SetState(newState)
    -- Validate state
    local validState = false
    for _, state in pairs(StateMachine.STATES) do
        if state == newState then
            validState = true
            break
        end
    end

    if not validState then
        print("[StateMachine] Warning: Invalid state '" .. tostring(newState) .. "'")
        return
    end

    local oldState = _G.BOTETO_CURRENT_STATE

    -- Only change if different
    if oldState == newState then
        return
    end

    -- Update state
    _G.BOTETO_CURRENT_STATE = newState

    -- Add to history
    table.insert(stateHistory, {
        from = oldState,
        to = newState,
        timestamp = GetTime()
    })

    -- Trim history if too large
    if #stateHistory > maxHistorySize then
        table.remove(stateHistory, 1)
    end

    -- Call callbacks
    for _, callback in ipairs(stateChangeCallbacks) do
        pcall(callback, oldState, newState)
    end
end

-- Get the current bot state
function StateMachine.GetState()
    return _G.BOTETO_CURRENT_STATE
end

-- Check if bot is in a specific state
function StateMachine.IsState(state)
    return _G.BOTETO_CURRENT_STATE == state
end

-- Check if bot is in any of the specified states
function StateMachine.IsAnyState(states)
    for _, state in ipairs(states) do
        if _G.BOTETO_CURRENT_STATE == state then
            return true
        end
    end
    return false
end

-- Register a callback for state changes
function StateMachine.OnStateChange(callback)
    table.insert(stateChangeCallbacks, callback)
end

-- Get state history
function StateMachine.GetHistory(count)
    count = count or #stateHistory
    local result = {}

    local startIndex = math.max(1, #stateHistory - count + 1)
    for i = startIndex, #stateHistory do
        table.insert(result, stateHistory[i])
    end

    return result
end

-- Get a human-readable state description
function StateMachine.GetStateDescription(state)
    state = state or _G.BOTETO_CURRENT_STATE

    local descriptions = {
        IDLE = "Standing idle, waiting for tasks",
        FIGHTING = "Engaged in combat",
        LOOTING = "Looting corpses",
        MOVING = "Moving to destination",
        RESTING = "Eating/drinking to restore resources",
        VENDORING = "Selling items at vendor",
        REPAIRING = "Repairing equipment",
        TRAINING = "Training new spells/abilities",
        QUESTING = "Completing quest objectives",
        GATHERING = "Gathering herbs/ore",
        SKINNING = "Skinning corpses",
        DEAD = "Dead, waiting for resurrection",
        TRAVELING = "Traveling to location",
        MOUNTING = "Mounting up",
        DISMOUNTING = "Dismounting"
    }

    return descriptions[state] or "Unknown state"
end

-- Clear state history
function StateMachine.ClearHistory()
    stateHistory = {}
end

-- Get time spent in current state
function StateMachine.GetTimeInCurrentState()
    if #stateHistory == 0 then
        return 0
    end

    local lastChange = stateHistory[#stateHistory]
    if lastChange.to == _G.BOTETO_CURRENT_STATE then
        return GetTime() - lastChange.timestamp
    end

    return 0
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

-- Reset state before tests
local function resetState()
    _G.BOTETO_CURRENT_STATE = StateMachine.STATES.IDLE
    StateMachine.ClearHistory()
    stateChangeCallbacks = {}
    mockTime = 0
end

print("\n=== Running State Machine Unit Tests ===\n")

-- Test 1: State transitions
runTest("State transitions", function()
    resetState()
    StateMachine.SetState(StateMachine.STATES.IDLE)
    assert_test(StateMachine.GetState() == StateMachine.STATES.IDLE, "Should be IDLE")

    StateMachine.SetState(StateMachine.STATES.FIGHTING)
    assert_test(StateMachine.GetState() == StateMachine.STATES.FIGHTING, "Should be FIGHTING")

    StateMachine.SetState(StateMachine.STATES.LOOTING)
    assert_test(StateMachine.GetState() == StateMachine.STATES.LOOTING, "Should be LOOTING")
end)

-- Test 2: Invalid states rejected
runTest("Invalid state rejection", function()
    resetState()
    local oldState = StateMachine.GetState()
    StateMachine.SetState("INVALID_STATE")
    assert_test(StateMachine.GetState() == oldState, "State should not change for invalid state")
end)

-- Test 3: IsState function
runTest("IsState check", function()
    resetState()
    StateMachine.SetState(StateMachine.STATES.RESTING)
    assert_test(StateMachine.IsState(StateMachine.STATES.RESTING), "IsState should return true for current state")
    assert_test(not StateMachine.IsState(StateMachine.STATES.FIGHTING), "IsState should return false for different state")
end)

-- Test 4: IsAnyState function
runTest("IsAnyState check", function()
    resetState()
    StateMachine.SetState(StateMachine.STATES.FIGHTING)
    assert_test(StateMachine.IsAnyState({
        StateMachine.STATES.FIGHTING,
        StateMachine.STATES.LOOTING
    }), "IsAnyState should return true if in one of the states")

    assert_test(not StateMachine.IsAnyState({
        StateMachine.STATES.RESTING,
        StateMachine.STATES.VENDORING
    }), "IsAnyState should return false if not in any state")
end)

-- Test 5: State history tracking
runTest("State history", function()
    resetState()
    StateMachine.ClearHistory()

    StateMachine.SetState(StateMachine.STATES.IDLE)
    StateMachine.SetState(StateMachine.STATES.MOVING)
    StateMachine.SetState(StateMachine.STATES.FIGHTING)

    local history = StateMachine.GetHistory()
    assert_test(#history >= 2, "History should have at least 2 entries, got " .. #history)

    local lastChange = history[#history]
    assert_test(lastChange.to == StateMachine.STATES.FIGHTING, "Last change should be to FIGHTING")
end)

-- Test 6: State descriptions
runTest("State descriptions", function()
    resetState()
    local desc = StateMachine.GetStateDescription(StateMachine.STATES.FIGHTING)
    assert_test(desc ~= nil and desc ~= "", "State description should not be empty")
    assert_test(desc ~= "Unknown state", "FIGHTING should have a description")
end)

-- Test 7: Duplicate state changes ignored
runTest("Duplicate state changes", function()
    resetState()
    StateMachine.SetState(StateMachine.STATES.IDLE)
    local history1 = StateMachine.GetHistory()
    local count1 = #history1

    StateMachine.SetState(StateMachine.STATES.IDLE)  -- Same state again
    local history2 = StateMachine.GetHistory()
    local count2 = #history2

    assert_test(count1 == count2, "Duplicate state change should not add to history")
end)

-- Test 8: State callbacks
runTest("State callbacks", function()
    resetState()
    local callbackCalled = false
    local callbackOldState = nil
    local callbackNewState = nil

    StateMachine.OnStateChange(function(oldState, newState)
        callbackCalled = true
        callbackOldState = oldState
        callbackNewState = newState
    end)

    StateMachine.SetState(StateMachine.STATES.DEAD)

    assert_test(callbackCalled, "Callback should be called")
    assert_test(callbackNewState == StateMachine.STATES.DEAD, "Callback should receive new state")
end)

-- Test 9: History size limit
runTest("History size limit", function()
    resetState()
    StateMachine.ClearHistory()

    -- Add more than maxHistorySize state changes
    for i = 1, 25 do
        if i % 2 == 0 then
            StateMachine.SetState(StateMachine.STATES.FIGHTING)
        else
            StateMachine.SetState(StateMachine.STATES.IDLE)
        end
    end

    local history = StateMachine.GetHistory()
    assert_test(#history <= 20, "History should not exceed max size of 20, got " .. #history)
end)

-- Test 10: Time in state
runTest("Time in state tracking", function()
    resetState()
    StateMachine.SetState(StateMachine.STATES.FIGHTING)

    local time1 = StateMachine.GetTimeInCurrentState()
    assert_test(time1 >= 0, "Time in state should be non-negative")

    -- Advance mock time
    GetTime()
    GetTime()

    local time2 = StateMachine.GetTimeInCurrentState()
    assert_test(time2 > time1, "Time in state should increase")
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
