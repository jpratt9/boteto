--[[
    Combat Module
    Handles spell casting and rotation execution
]]

local Combat = {}

-- ============================================
-- CONFIGURATION
-- ============================================

Combat.CAST_DELAY = 0.5  -- Minimum delay between casts (seconds)
Combat.GCD_THRESHOLD = 1.5  -- GCD duration threshold (ignore cooldowns < this)
Combat.lastCastTime = 0

-- ============================================
-- SPELL COOLDOWN CHECKING
-- ============================================

-- Check if a spell is on cooldown
-- @param spellId: number - spell ID to check
-- @return boolean - true if on cooldown, false if ready
function Combat.IsSpellOnCooldown(spellId)
    local start, duration = GetSpellCooldown(spellId)

    if start and duration then
        -- Ignore GCD (durations <= 1.5 seconds)
        if duration > Combat.GCD_THRESHOLD then
            return (start > 0)
        end
    end

    return false
end

-- Get remaining cooldown time for a spell
-- @param spellId: number - spell ID to check
-- @return number - seconds remaining on cooldown
function Combat.GetSpellCooldownRemaining(spellId)
    local start, duration = GetSpellCooldown(spellId)

    if start and duration and duration > Combat.GCD_THRESHOLD then
        local remaining = (start + duration) - GetTime()
        return math.max(0, remaining)
    end

    return 0
end

-- ============================================
-- SPELL USABILITY CHECKING
-- ============================================

-- Check if a spell is usable
-- @param spellId: number - spell ID to check
-- @return boolean - true if usable, false otherwise
function Combat.IsSpellUsable(spellId)
    -- Check if spell info exists
    local spellInfo = C_Spell and C_Spell.GetSpellInfo(spellId)
    if not spellInfo then
        return false
    end

    -- Check if spell is usable (has resources, not locked, etc.)
    local usable, nomana = false, false
    if C_Spell and C_Spell.IsSpellUsable then
        usable, nomana = C_Spell.IsSpellUsable(spellId)
    end

    -- Check if on cooldown
    local onCooldown = Combat.IsSpellOnCooldown(spellId)

    return usable and not onCooldown
end

-- ============================================
-- GLOBAL COOLDOWN (GCD) CHECKING
-- ============================================

-- Check if player is on global cooldown
-- @return boolean - true if on GCD, false otherwise
function Combat.IsOnGCD()
    -- Check GCD by looking at a common spell (spell ID 61304 is GCD in retail)
    -- For Classic, we'll check any spell's cooldown
    local start, duration = GetSpellCooldown(61304)

    if not start then
        -- Fallback: check if any spell in rotation has active GCD
        if _G.CurrentRotation and #_G.CurrentRotation > 0 then
            local firstSpell = _G.CurrentRotation[1]
            start, duration = GetSpellCooldown(firstSpell.id)
        end
    end

    if start and duration then
        -- GCD is active if duration is between 0.5 and 1.5 seconds
        if duration > 0.5 and duration <= Combat.GCD_THRESHOLD then
            local remaining = (start + duration) - GetTime()
            return remaining > 0
        end
    end

    return false
end

-- ============================================
-- SPELL CASTING VALIDATION
-- ============================================

-- Check if a spell can be cast (combines all checks)
-- @param spellId: number - spell ID to check
-- @param target: object - optional target object
-- @return boolean - true if spell can be cast
function Combat.CanCastSpell(spellId, target)
    -- Check if spell is usable
    if not Combat.IsSpellUsable(spellId) then
        return false
    end

    -- Check GCD
    if Combat.IsOnGCD() then
        return false
    end

    -- Check cast delay (prevent spam)
    if GetTime() < Combat.lastCastTime + Combat.CAST_DELAY then
        return false
    end

    -- Check if target exists (if target is required)
    if target and not UnitExists(target) then
        return false
    end

    return true
end

-- ============================================
-- SPELL CASTING EXECUTION
-- ============================================

-- Cast a spell with safety checks
-- @param spellId: number - spell ID to cast
-- @param target: object - optional target object
-- @return boolean - true if cast was attempted, false otherwise
function Combat.CastSpell(spellId, target)
    -- Get spell info
    local spellInfo = C_Spell and C_Spell.GetSpellInfo(spellId)
    if not spellInfo then
        print("[Combat] Failed to get spell info for ID: " .. tostring(spellId))
        return false
    end

    local spellName = spellInfo.name

    -- Cast the spell (target should already be set via Combat.SetTarget)
    local success = pcall(CastSpellByName, spellName)

    if success then
        Combat.lastCastTime = GetTime()
        print("[Combat] Cast: " .. spellName .. " (ID: " .. spellId .. ")")
        return true
    else
        print("[Combat] Failed to cast: " .. spellName)
        return false
    end
end

-- ============================================
-- TARGETING SYSTEM
-- ============================================

-- Get the best target for combat (uses existing GetEnemies function)
-- @return object - best target object, or nil if none found
function Combat.GetBestTarget()
    -- Use the existing GetEnemies function from main.lua
    if not GetEnemies then
        return nil
    end

    local enemies = GetEnemies(40) -- 40 yard range

    if #enemies == 0 then
        return nil
    end

    -- Return closest enemy (GetEnemies already sorts by distance)
    return enemies[1].obj
end

-- Set the current target
-- @param target: object - target to set
-- @return boolean - true if target was set successfully
function Combat.SetTarget(target)
    if target and UnitExists(target) then
        local success = pcall(TargetUnit, target)
        return success
    end
    return false
end

-- ============================================
-- ROTATION EXECUTION
-- ============================================

-- Execute the current rotation (priority-based system)
-- This is the main function called every frame by the bot
function Combat.ExecuteRotation()
    -- Check if we have a rotation loaded
    if not _G.CurrentRotation or #_G.CurrentRotation == 0 then
        return
    end

    -- Get or set target
    local target = Combat.GetBestTarget()
    if not target then
        -- No enemies nearby, go idle
        if StateMachine and StateMachine.IsState and StateMachine.STATES then
            if not StateMachine.IsState(StateMachine.STATES.IDLE) then
                StateMachine.SetState(StateMachine.STATES.IDLE)
            end
        end
        return
    end

    -- Set target
    Combat.SetTarget(target)

    -- Enter fighting state
    if StateMachine and StateMachine.SetState and StateMachine.STATES then
        if not StateMachine.IsState(StateMachine.STATES.FIGHTING) then
            StateMachine.SetState(StateMachine.STATES.FIGHTING)
        end
    end

    -- Loop through rotation in priority order
    for i, spell in ipairs(_G.CurrentRotation) do
        if Combat.CanCastSpell(spell.id, target) then
            Combat.CastSpell(spell.id, target)
            return -- Only cast one spell per update
        end
    end
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Get player's current health percentage
-- @return number - health percentage (0-100)
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

-- Check if player is in combat
-- @return boolean - true if in combat
function Combat.IsInCombat()
    if UnitAffectingCombat then
        return UnitAffectingCombat("player")
    end
    return false
end

-- Print current rotation status (debugging)
function Combat.PrintRotationStatus()
    print("=== Combat Rotation Status ===")

    if not _G.CurrentRotation or #_G.CurrentRotation == 0 then
        print("No rotation loaded")
        return
    end

    print("Rotation has " .. #_G.CurrentRotation .. " spells:")
    for i, spell in ipairs(_G.CurrentRotation) do
        local usable = Combat.IsSpellUsable(spell.id)
        local onCD = Combat.IsSpellOnCooldown(spell.id)
        local cdRemaining = Combat.GetSpellCooldownRemaining(spell.id)

        print(string.format("  %d. %s (ID: %d) - Usable: %s, OnCD: %s, CD Remaining: %.1fs",
            i, spell.name, spell.id, tostring(usable), tostring(onCD), cdRemaining))
    end

    print("GCD Active: " .. tostring(Combat.IsOnGCD()))
    print("Health: " .. string.format("%.1f%%", Combat.GetHealthPercent()))
    print("In Combat: " .. tostring(Combat.IsInCombat()))
    print("============================")
end

return Combat
