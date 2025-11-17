--[[
    State Machine Module
    Manages bot state transitions and current state
]]

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
-- @param newState: string - one of the STATES constants
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

    -- Log state change
    print(string.format("[StateMachine] State: %s -> %s", oldState, newState))

    -- Call callbacks
    for _, callback in ipairs(stateChangeCallbacks) do
        pcall(callback, oldState, newState)
    end
end

-- Get the current bot state
-- @return state: string - current state
function StateMachine.GetState()
    return _G.BOTETO_CURRENT_STATE
end

-- Check if bot is in a specific state
-- @param state: string - state to check
-- @return isInState: boolean
function StateMachine.IsState(state)
    return _G.BOTETO_CURRENT_STATE == state
end

-- Check if bot is in any of the specified states
-- @param states: table - array of states to check
-- @return isInAnyState: boolean
function StateMachine.IsAnyState(states)
    for _, state in ipairs(states) do
        if _G.BOTETO_CURRENT_STATE == state then
            return true
        end
    end
    return false
end

-- Register a callback for state changes
-- @param callback: function(oldState, newState)
function StateMachine.OnStateChange(callback)
    table.insert(stateChangeCallbacks, callback)
end

-- Get state history
-- @param count: number - number of recent state changes to return (default: all)
-- @return history: table - array of state change records
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
-- @param state: string - state to describe (default: current state)
-- @return description: string
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
    print("[StateMachine] State history cleared")
end

-- Get time spent in current state
-- @return duration: number - seconds in current state
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

-- Print current state and recent history
function StateMachine.PrintStatus()
    print("=== State Machine Status ===")
    print("Current State: " .. _G.BOTETO_CURRENT_STATE)
    print("Description: " .. StateMachine.GetStateDescription())
    print("Time in state: " .. string.format("%.1f", StateMachine.GetTimeInCurrentState()) .. "s")

    if #stateHistory > 0 then
        print("\nRecent State Changes:")
        local recentHistory = StateMachine.GetHistory(5)
        for i, change in ipairs(recentHistory) do
            print(string.format("  %d. %s -> %s (%.1fs ago)",
                i,
                change.from,
                change.to,
                GetTime() - change.timestamp
            ))
        end
    end

    print("===========================")
end

return StateMachine
