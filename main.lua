--[[
    BOTETO Main Bot Logic
    Loaded by wow-boteto.lua entrypoint
    The entrypoint exposes Tinkr functions (ReadFile, WriteFile, etc.) as globals
]]

print("=== Loading BOTETO Main ===")
print("[DEBUG] main.lua start - Lua version: " .. tostring(_VERSION))
print("[DEBUG] main.lua start - ReadFile type: " .. type(ReadFile))
print("[DEBUG] main.lua start - _G.ReadFile type: " .. type(_G.ReadFile))
print("[DEBUG] main.lua start - getfenv level: " .. tostring(getfenv and getfenv(1) == _G))

-- ============================================
-- CONFIGURATION
-- ============================================

-- Set base path (configure this to match your installation directory)
-- This should point to the directory containing core/, test/, rotations/, etc.
_G.BOTETO_BASE_PATH = _G.BOTETO_BASE_PATH or "/path/to/boteto/"

-- Stats toggle setting (BANETO pattern - line 8766 default true)
_G.BOTETO_SETTINGS_STATSTOGGLE = true

-- ============================================
-- LOAD MODULES
-- ============================================

-- Load state machine module
print("Loading state_machine.lua...")
local stateCode = ReadFile(_G.BOTETO_BASE_PATH .. "core/state_machine.lua")
if not stateCode then
    error("Failed to load state_machine.lua")
end

local loadFunc, loadErr = (load or loadstring)(stateCode, "state_machine.lua")
if not loadFunc then
    error("Failed to compile state_machine.lua: " .. tostring(loadErr))
end

-- CRITICAL FIX: Force loaded function to use current environment (LOADSTRING_ENVIRONMENT_BUG.md)
setfenv(loadFunc, getfenv())

StateMachine = loadFunc()
if not StateMachine then
    error("state_machine.lua did not return a module table")
end
_G.StateMachine = StateMachine

-- Initialize global state (must be done in caller scope, not module scope)
_G.BOTETO_CURRENT_STATE = StateMachine.STATES.IDLE

print("[✓] State Machine loaded")

-- Load file management module
print("Loading file_management.lua...")
local fileCode = ReadFile(_G.BOTETO_BASE_PATH .. "core/file_management.lua")
if not fileCode then
    error("Failed to load file_management.lua")
end

loadFunc, loadErr = (load or loadstring)(fileCode, "file_management.lua")
if not loadFunc then
    error("Failed to compile file_management.lua: " .. tostring(loadErr))
end

-- CRITICAL FIX: Force loaded function to use current environment (LOADSTRING_ENVIRONMENT_BUG.md)
setfenv(loadFunc, getfenv())

FileManagement = loadFunc()
if not FileManagement then
    error("file_management.lua did not return a module table")
end
_G.FileManagement = FileManagement
print("[✓] File Management loaded")

-- Load combat module
print("Loading combat.lua...")
local combatCode = ReadFile(_G.BOTETO_BASE_PATH .. "core/combat.lua")
if not combatCode then
    print("=== COMBAT LOAD ERROR ===")
    print("Failed to read combat.lua from: " .. _G.BOTETO_BASE_PATH .. "core/combat.lua")
    print("========================")
    error("Failed to load combat.lua")
end

print("[DEBUG] Combat code loaded, length: " .. #combatCode)

loadFunc, loadErr = (load or loadstring)(combatCode, "combat.lua")
if not loadFunc then
    print("=== COMBAT COMPILE ERROR ===")
    print("Error: " .. tostring(loadErr))
    print("===========================")
    error("Failed to compile combat.lua: " .. tostring(loadErr))
end

print("[DEBUG] Combat code compiled, executing...")

-- CRITICAL FIX: Force loaded function to use current environment (LOADSTRING_ENVIRONMENT_BUG.md)
setfenv(loadFunc, getfenv())

local success, result = pcall(loadFunc)
if not success then
    print("=== COMBAT EXECUTION ERROR ===")
    print("Error: " .. tostring(result))
    print("==============================")
    error("Failed to execute combat.lua: " .. tostring(result))
end

Combat = result
if not Combat then
    print("=== COMBAT MODULE ERROR ===")
    print("combat.lua did not return a module table")
    print("Returned: " .. tostring(Combat))
    print("===========================")
    error("combat.lua did not return a module table")
end

_G.Combat = Combat
print("[✓] Combat loaded")

-- Load looting module
print("Loading looting.lua...")
local lootingCode = ReadFile(_G.BOTETO_BASE_PATH .. "core/looting.lua")
if not lootingCode then
    error("Failed to load looting.lua")
end

loadFunc, loadErr = (load or loadstring)(lootingCode, "looting.lua")
if not loadFunc then
    error("Failed to compile looting.lua: " .. tostring(loadErr))
end

-- CRITICAL FIX: Force loaded function to use current environment (LOADSTRING_ENVIRONMENT_BUG.md)
setfenv(loadFunc, getfenv())

Looting = loadFunc()
if not Looting then
    error("looting.lua did not return a module table")
end
_G.Looting = Looting
print("[✓] Looting loaded")

-- Load vendor module
print("Loading vendor.lua...")
local vendorCode = ReadFile(_G.BOTETO_BASE_PATH .. "core/vendor.lua")
if not vendorCode then
    error("Failed to load vendor.lua")
end

loadFunc, loadErr = (load or loadstring)(vendorCode, "vendor.lua")
if not loadFunc then
    error("Failed to compile vendor.lua: " .. tostring(loadErr))
end

-- CRITICAL FIX: Force loaded function to use current environment (LOADSTRING_ENVIRONMENT_BUG.md)
setfenv(loadFunc, getfenv())

Vendor = loadFunc()
if not Vendor then
    error("vendor.lua did not return a module table")
end
_G.Vendor = Vendor
print("[✓] Vendor loaded")

-- Load movement module
print("Loading movement.lua...")
local movementCode = ReadFile(_G.BOTETO_BASE_PATH .. "core/movement.lua")
if not movementCode then
    error("Failed to load movement.lua")
end

loadFunc, loadErr = (load or loadstring)(movementCode, "movement.lua")
if not loadFunc then
    error("Failed to compile movement.lua: " .. tostring(loadErr))
end

setfenv(loadFunc, getfenv())

Movement = loadFunc()
if not Movement then
    error("movement.lua did not return a module table")
end
_G.Movement = Movement
print("[✓] Movement loaded")

-- ============================================
-- DEBUG COMMANDS (defined early so they work even if GUI errors)
-- ============================================

function PrintState()
    local success, err = pcall(function()
        if not StateMachine then
            error("StateMachine is nil")
        end
        if not StateMachine.PrintStatus then
            error("StateMachine.PrintStatus is nil")
        end
        if not _G.BOTETO_CURRENT_STATE then
            error("BOTETO_CURRENT_STATE is nil")
        end
        print("[DEBUG] Calling StateMachine.PrintStatus()")
        StateMachine.PrintStatus()
        print("[DEBUG] PrintStatus completed")
    end)

    if not success then
        print("=== ERROR IN PrintState ===")
        print(tostring(err))
        print("===========================")
    end
end

function SetBotState(state)
    local success, err = pcall(function()
        if not StateMachine then
            error("StateMachine is nil")
        end
        StateMachine.SetState(state)
    end)

    if not success then
        print("=== ERROR IN SetBotState ===")
        print(tostring(err))
        print("============================")
    end
end

-- Export immediately
_G.PrintState = PrintState
_G.SetBotState = SetBotState

-- ============================================
-- BOT CORE
-- ============================================

-- Bot state (make it global)
_G.BotEnabled = true
local updateCount = 0

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

-- Get nearby alive enemies (BANETO pattern)
local lastGetEnemiesDebug = 0
function GetEnemies(maxDistance)
    local enemies = {}

    -- Get units only (Objects(5) returns only units, not all objects)
    local units = Objects(5)
    local px, py, pz = ObjectPosition("player")

    if not px then
        if GetTime() >= lastGetEnemiesDebug + 1 then
            print("[DEBUG] Could not get player position!")
            lastGetEnemiesDebug = GetTime()
        end
        return enemies
    end

    for i = 1, #units do
        local unit = units[i]
        local ux, uy, uz = ObjectPosition(unit)

        if ux then
            local dist = math.sqrt((px-ux)^2 + (py-uy)^2 + (pz-uz)^2)

            if dist <= maxDistance then
                -- Filter out critters
                local creatureType = UnitCreatureType(unit)

                if creatureType ~= "Critter" then
                    -- Check if attackable (BANETO pattern)
                    if UnitCanAttack("player", unit) then
                        -- Skip if dead/lootable
                        local canLoot = UnitCanBeLooted and UnitCanBeLooted(unit)
                        if not canLoot then
                            table.insert(enemies, {obj = unit, distance = dist})
                        end
                    end
                end
            end
        end
    end

    table.sort(enemies, function(a, b) return a.distance < b.distance end)

    -- Debug output once per second
    if GetTime() >= lastGetEnemiesDebug + 1 then
        print(string.format("[DEBUG] GetEnemies: Units=%d, Enemies=%d", #units, #enemies))
        lastGetEnemiesDebug = GetTime()
    end

    return enemies
end

-- Make combat helper functions globally accessible
_G.GetEnemies = GetEnemies

-- Main update function (BANETO pattern)
local BANETO_TARGET = nil
local lastFaceTime = 0  -- Timer for facing (BANETO pattern line 69572)
local lastRetargetCheck = 0  -- Timer for re-targeting (BANETO pattern)
local function BotUpdate()
    if not _G.BotEnabled then return end

    updateCount = updateCount + 1

    local currentState = StateMachine.GetState()

    -- FIGHTING STATE
    if currentState == StateMachine.STATES.FIGHTING or currentState == StateMachine.STATES.IDLE then
        -- Find target if none exists
        if not UnitExists("target") then
            local enemies = GetEnemies(70)
            if #enemies > 0 then
                BANETO_TARGET = enemies[1].obj
                TargetUnit(BANETO_TARGET)
                StateMachine.SetState(StateMachine.STATES.FIGHTING)
            else
                -- No enemies, check for looting
                StateMachine.SetState(StateMachine.STATES.IDLE)
                BANETO_TARGET = nil
            end
        end

        -- Re-target to closer enemies during combat (BANETO pattern - every 5 seconds)
        if UnitExists("target") and UnitAffectingCombat("player") then
            if GetTime() >= lastRetargetCheck + 5 then
                local currentTargetDist = nil
                local tx, ty, tz = ObjectPosition("target")
                local px, py, pz = ObjectPosition("player")

                if tx and px then
                    currentTargetDist = math.sqrt((px-tx)^2 + (py-ty)^2 + (pz-tz)^2)
                end

                local enemies = GetEnemies(70)
                -- Switch if new enemy is 15+ yards closer
                if #enemies > 0 and currentTargetDist and enemies[1].distance < (currentTargetDist - 15) then
                    BANETO_TARGET = enemies[1].obj
                    TargetUnit(BANETO_TARGET)
                end

                lastRetargetCheck = GetTime()
            end
        end

        -- If target exists, execute combat
        if UnitExists("target") then
            local tx, ty, tz = ObjectPosition("target")
            local targetHealth = UnitHealth("target")

            -- BANETO line 69566: Check target position AND health > 0
            if tx and targetHealth and targetHealth > 0 then
                local px, py, pz = ObjectPosition("player")
                if px then
                    local dist = math.sqrt((px-tx)^2 + (py-ty)^2 + (pz-tz)^2)

                    -- BANETO line 69567: If within combat range (5 yards)
                    if dist <= 5 then
                        -- BANETO line 69582-69586: Stop movement if moving
                        local currentSpeed = GetUnitSpeed("player")
                        if currentSpeed and currentSpeed > 0 then
                            Movement.StopMovement()
                        end

                        -- BANETO line 69572-69575: Face target every 0.3 seconds
                        if not lastFaceTime or GetTime() > lastFaceTime + 0.3 then
                            FaceObject("target")
                            lastFaceTime = GetTime()
                        end

                        -- BANETO line 69613: Execute rotation
                        Combat.ExecuteRotation()

                    -- BANETO line 69616-69617: NOT in range AND not casting/channeling
                    elseif dist > 5 and dist <= 70 and not UnitCastingInfo("player") and not UnitChannelInfo("player") then
                        Movement.MeshTo(tx, ty, tz)
                    end
                end
            else
                -- BANETO line 69620-69621: Target dead, clear it
                BANETO_TARGET = nil
                ClearTarget()
            end
        -- No target and not in combat, check if we should loot
        elseif not UnitAffectingCombat("player") then
            -- Only switch to LOOTING if corpses actually exist
            local lootableCorpses = Looting.GetLootableCorpses()
            local skinnableCorpses = Looting.CanPlayerSkin() and Looting.GetSkinnableCorpses() or {}

            if #lootableCorpses > 0 or #skinnableCorpses > 0 then
                StateMachine.SetState(StateMachine.STATES.LOOTING)
            else
                -- No corpses to loot, stay in IDLE
                StateMachine.SetState(StateMachine.STATES.IDLE)
            end
        end
    end

    -- LOOTING STATE
    if currentState == StateMachine.STATES.LOOTING then
        Looting.ExecuteLooting()

        -- Return to IDLE when done looting
        local lootableCorpses = Looting.GetLootableCorpses()
        local skinnableCorpses = Looting.CanPlayerSkin() and Looting.GetSkinnableCorpses() or {}

        if #lootableCorpses == 0 and #skinnableCorpses == 0 then
            StateMachine.SetState(StateMachine.STATES.IDLE)
        end
    end
end

-- Reuse existing frame or create new one (prevents multiple frames on reload)
local frame = _G.WowBotFrame
if not frame then
    frame = CreateFrame("Frame", "WowBotFrame")
    _G.WowBotFrame = frame
    print("Created new bot frame")
else
    -- Clear any existing script first
    frame:SetScript("OnUpdate", nil)
    print("Reusing existing bot frame")
end

-- Make update function global so it can be reused
_G.WowBotUpdateFunc = function()
    -- Update GUI every frame (whether bot is enabled or not)
    if _G.GUI and _G.GUI.Update then
        pcall(_G.GUI.Update)
    end

    -- Only run bot logic if enabled
    if not _G.BotEnabled then return end
    pcall(BotUpdate)
end

frame:SetScript("OnUpdate", _G.WowBotUpdateFunc)

-- Control functions
function StopBot()
    _G.BotEnabled = false
    -- Reference the global frame
    if _G.WowBotFrame then
        _G.WowBotFrame:SetScript("OnUpdate", nil)
    end
    -- Only stop movement if bot has active path (don't interrupt player-initiated movement)
    if _G.BOTETO_PATH then
        Movement.StopMovement()
    end
    StateMachine.SetState(StateMachine.STATES.IDLE)
    print("=== Bot Stopped ===")
end

function StartBot()
    _G.BotEnabled = true
    updateCount = 0
    -- Reference the global frame and function
    if _G.WowBotFrame and _G.WowBotUpdateFunc then
        _G.WowBotFrame:SetScript("OnUpdate", _G.WowBotUpdateFunc)
    end
    StateMachine.SetState(StateMachine.STATES.IDLE)
    print("=== Bot Started ===")
end

-- Make control functions globally accessible
_G.StopBot = StopBot
_G.StartBot = StartBot

-- ============================================
-- GUI SYSTEM
-- ============================================

-- Load GUI module
print("Loading GUI...")
local guiCode = ReadFile(_G.BOTETO_BASE_PATH .. "core/gui/init.lua")
if not guiCode then
    error("Failed to load gui/init.lua")
end

loadFunc, loadErr = (load or loadstring)(guiCode, "gui/init.lua")
if not loadFunc then
    error("Failed to compile gui/init.lua: " .. tostring(loadErr))
end

-- CRITICAL FIX: Force loaded function to use current environment
setfenv(loadFunc, getfenv())

GUI = loadFunc()
if not GUI then
    error("gui/init.lua did not return a module table")
end

-- Initialize GUI
GUI.Initialize()
_G.GUI = GUI

-- Show GUI by default
GUI.Show()

print("[✓] GUI loaded")

-- Make GUI toggle function globally accessible
_G.ToggleGUI = GUI.Toggle

-- Modules and debug commands already exported at top of file

