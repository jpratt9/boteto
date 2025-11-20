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
    pcall(UpdateGUI)

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
    -- Stop character movement (BANETO pattern - line 4412)
    Movement.StopMovement()
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

-- Create main GUI window
local gui = _G.WowBotGUI
if not gui then
    -- Create main frame (BANETO style)
    gui = CreateFrame("Frame", "WowBotGUI", UIParent)
    gui:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 23, -120)
    gui:SetSize(225, 55)
    gui:SetFrameLevel(10)
    gui:SetMovable(true)
    gui:EnableMouse(true)
    gui:RegisterForDrag("LeftButton")
    gui:SetScript("OnDragStart", gui.StartMoving)
    gui:SetScript("OnDragStop", gui.StopMovingOrSizing)

    -- Create backdrop (BANETO pattern)
    gui.Backdrop = CreateFrame("Frame", nil, gui, "BackdropTemplate")
    gui.Backdrop:SetAllPoints()
    gui.Backdrop:SetFrameLevel(8)
    gui.Backdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    gui.Backdrop:EnableMouse(false)  -- Don't intercept mouse events

    -- Title with MORPHEUS font (BANETO pattern)
    gui.title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gui.title:SetPoint("CENTER", 1, -3)
    gui.title:SetText("BOTETO")
    -- Check locale for font choice
    local locale = GetLocale()
    if locale == "zhCN" or locale == "zhTW" or locale == "koKR" or locale == "ruRU" then
        gui.title:SetFont("Fonts\\FRIZQT__.TTF", 29)
    else
        gui.title:SetFont("Fonts\\MORPHEUS.ttf", 29)
    end

    -- Stats bar overlay (BANETO pattern)
    gui.statsFrame = CreateFrame("Frame", nil, gui)
    gui.statsFrame:SetPoint("TOP", 0, 35)
    gui.statsFrame:SetSize(218, 40)
    gui.statsFrame:SetFrameLevel(7)
    gui.statsFrame:EnableMouse(false)  -- Don't intercept mouse events

    -- Stats bar backdrop
    gui.statsFrame.Backdrop = CreateFrame("Frame", nil, gui.statsFrame, "BackdropTemplate")
    gui.statsFrame.Backdrop:SetAllPoints()
    gui.statsFrame.Backdrop:SetFrameLevel(2)
    gui.statsFrame.Backdrop:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    gui.statsFrame.Backdrop:SetBackdropColor(0, 0, 0, 0.1)
    gui.statsFrame.Backdrop:EnableMouse(false)  -- Don't intercept mouse events

    -- Stats text (BANETO pattern - line 71730-71731)
    gui.statsText = gui.statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gui.statsText:SetPoint("CENTER", 0, 6)
    local fontName, _, fontFlags = gui.statsText:GetFont()
    gui.statsText:SetFont(fontName, 18, fontFlags)
    gui.statsText:SetText("|cff0872B2IDLE|cffB9B9B9 | Targets: 0 | Deaths: 0")

    -- Status text (keep for compatibility)
    gui.status = gui:CreateFontString(nil, "OVERLAY")
    gui.status:SetFontObject("GameFontNormal")
    gui.status:SetPoint("TOP", 0, -40)
    gui.status:SetText("Status: Stopped")
    gui.status:Hide()  -- Hidden in compact mode

    -- Start/Stop button
    gui.toggleBtn = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
    gui.toggleBtn:SetSize(120, 30)
    gui.toggleBtn:SetPoint("TOP", 0, -70)
    gui.toggleBtn:SetText("Start Bot")
    gui.toggleBtn:SetScript("OnClick", function()
        if _G.BotEnabled then
            StopBot()
        else
            StartBot()
        end
    end)
    gui.toggleBtn:Hide()  -- Hidden in compact mode

    -- Rotation Builder button
    gui.rotationBtn = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
    gui.rotationBtn:SetSize(120, 30)
    gui.rotationBtn:SetPoint("TOP", 0, -110)
    gui.rotationBtn:SetText("Rotation Builder")
    gui.rotationBtn:SetScript("OnClick", function()
        ToggleRotationBuilder()
    end)
    gui.rotationBtn:Hide()  -- Hidden in compact mode

    -- Sell Junk button
    gui.sellJunkBtn = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
    gui.sellJunkBtn:SetSize(120, 30)
    gui.sellJunkBtn:SetPoint("TOP", 0, -150)
    gui.sellJunkBtn:SetText("Sell Junk")
    gui.sellJunkBtn:SetScript("OnClick", function()
        if Vendor.IsMerchantOpen() then
            Vendor.SellGrayItems()
        else
            print("[Vendor] Please open a merchant window first!")
        end
    end)
    gui.sellJunkBtn:Hide()  -- Hidden in compact mode

    _G.WowBotGUI = gui
    print("Created GUI window")
else
    print("Reusing existing GUI window")
end

-- Update GUI function
function UpdateGUI()
    if not gui then return end

    if _G.BotEnabled then
        gui.status:SetText("|cff00ff00Status: Running|r")
        gui.toggleBtn:SetText("Stop Bot")
    else
        gui.status:SetText("|cffff0000Status: Stopped|r")
        gui.toggleBtn:SetText("Start Bot")
    end

    -- Update stats
    local player = GetPlayer()
    if player then
        local x, y, z = ObjectPosition(player)
        local enemies = GetEnemies(70)
        local currentState = StateMachine.GetState()
        local timeInState = StateMachine.GetTimeInCurrentState()

        gui.statsText:SetText(string.format(
            "Position: %.0f, %.0f\nEnemies Nearby: %d\nState: %s (%.1fs)",
            x, y, #enemies, currentState, timeInState
        ))
    end
end

-- Show/hide GUI
function ToggleGUI()
    if gui:IsShown() then
        gui:Hide()
    else
        gui:Show()
    end
end

-- Make GUI functions globally accessible
_G.ToggleGUI = ToggleGUI

-- Show GUI by default
gui:Show()

-- ============================================
-- ROTATION BUILDER GUI
-- ============================================

-- Current rotation (list of spells in priority order)
_G.CurrentRotation = _G.CurrentRotation or {}

local rotBuilder = _G.WowBotRotationBuilder
if not rotBuilder then
    -- Create rotation builder frame
    rotBuilder = CreateFrame("Frame", "WowBotRotationBuilder", UIParent, "BasicFrameTemplateWithInset")
    rotBuilder:SetSize(400, 500)
    rotBuilder:SetPoint("CENTER", 100, 0)
    rotBuilder:SetMovable(true)
    rotBuilder:EnableMouse(true)
    rotBuilder:RegisterForDrag("LeftButton")
    rotBuilder:SetScript("OnDragStart", rotBuilder.StartMoving)
    rotBuilder:SetScript("OnDragStop", rotBuilder.StopMovingOrSizing)
    rotBuilder:SetFrameStrata("HIGH")
    rotBuilder:Hide() -- Hidden by default

    -- Title
    rotBuilder.title = rotBuilder:CreateFontString(nil, "OVERLAY")
    rotBuilder.title:SetFontObject("GameFontHighlight")
    rotBuilder.title:SetPoint("TOP", 0, -5)
    rotBuilder.title:SetText("Rotation Builder")

    -- Instructions
    rotBuilder.instructions = rotBuilder:CreateFontString(nil, "OVERLAY")
    rotBuilder.instructions:SetFontObject("GameFontNormalSmall")
    rotBuilder.instructions:SetPoint("TOP", 0, -35)
    rotBuilder.instructions:SetText("Drag spells from your spellbook here")

    -- Drop zone for spells (will resize dynamically)
    rotBuilder.dropZone = CreateFrame("Frame", nil, rotBuilder)
    rotBuilder.dropZone:SetSize(360, 100) -- Start with base size
    rotBuilder.dropZone:SetPoint("TOP", 0, -60)

    -- Drop zone background (tiled action bar slot texture)
    local textureSize = 64 -- UI-Quickslot is 64x64
    local dropZoneWidth = 360
    local dropZoneHeight = 100

    rotBuilder.dropZone.bg = rotBuilder.dropZone:CreateTexture(nil, "BACKGROUND")
    rotBuilder.dropZone.bg:SetAllPoints()
    rotBuilder.dropZone.bg:SetTexture("Interface\\Buttons\\UI-Quickslot")

    -- Calculate tiling based on frame dimensions
    local horizTile = dropZoneWidth / textureSize
    local vertTile = dropZoneHeight / textureSize
    rotBuilder.dropZone.bg:SetTexCoord(0, horizTile, 0, vertTile)

    -- Handle spell drops
    rotBuilder.dropZone:SetScript("OnReceiveDrag", function()
        local v1, v2, v3, v4 = GetCursorInfo()

        if v1 == "spell" then
            -- v4 is the actual spell ID (1784 for Stealth, not v2 which is slot 17)
            local spellName, _, icon = GetSpellInfo(v4)

            if spellName then
                table.insert(_G.CurrentRotation, {
                    id = v4,
                    name = spellName,
                    icon = icon
                })
                UpdateRotationList()
                print("Added " .. spellName .. " (ID: " .. v4 .. ") to rotation")
            end
            ClearCursor()
        end
    end)

    -- Also handle mouse up (alternative drop method)
    rotBuilder.dropZone:SetScript("OnMouseUp", function()
        local v1, v2, v3, v4 = GetCursorInfo()
        if v1 == "spell" then
            local spellName, _, icon = GetSpellInfo(v4)

            if spellName then
                table.insert(_G.CurrentRotation, {
                    id = v4,
                    name = spellName,
                    icon = icon
                })
                UpdateRotationList()
                print("Added " .. spellName .. " (ID: " .. v4 .. ") to rotation")
            end
            ClearCursor()
        end
    end)

    -- Rotation list display
    rotBuilder.rotationList = {}

    -- Save/load controls container
    rotBuilder.controls = CreateFrame("Frame", nil, rotBuilder)
    rotBuilder.controls:SetSize(360, 60)
    rotBuilder.controls:SetPoint("BOTTOM", 0, 60)

    -- Rotation name label
    rotBuilder.nameLabel = rotBuilder.controls:CreateFontString(nil, "OVERLAY")
    rotBuilder.nameLabel:SetFontObject("GameFontNormalSmall")
    rotBuilder.nameLabel:SetPoint("TOPLEFT", 10, -5)
    rotBuilder.nameLabel:SetText("Rotation Name:")

    -- Rotation name textbox
    rotBuilder.nameBox = CreateFrame("EditBox", nil, rotBuilder.controls, "InputBoxTemplate")
    rotBuilder.nameBox:SetSize(150, 25)
    rotBuilder.nameBox:SetPoint("TOPLEFT", 10, -20)
    rotBuilder.nameBox:SetAutoFocus(false)
    rotBuilder.nameBox:SetText("MyRotation")

    -- Save button
    rotBuilder.saveBtn = CreateFrame("Button", nil, rotBuilder.controls, "GameMenuButtonTemplate")
    rotBuilder.saveBtn:SetSize(60, 25)
    rotBuilder.saveBtn:SetPoint("LEFT", rotBuilder.nameBox, "RIGHT", 5, 0)
    rotBuilder.saveBtn:SetText("Save")
    rotBuilder.saveBtn:SetScript("OnClick", function()
        SaveRotation()
    end)

    -- Load button
    rotBuilder.loadBtn = CreateFrame("Button", nil, rotBuilder.controls, "GameMenuButtonTemplate")
    rotBuilder.loadBtn:SetSize(60, 25)
    rotBuilder.loadBtn:SetPoint("LEFT", rotBuilder.saveBtn, "RIGHT", 5, 0)
    rotBuilder.loadBtn:SetText("Load")
    rotBuilder.loadBtn:SetScript("OnClick", function()
        LoadRotationByName()
    end)

    -- Clear rotation button
    rotBuilder.clearBtn = CreateFrame("Button", nil, rotBuilder.controls, "GameMenuButtonTemplate")
    rotBuilder.clearBtn:SetSize(60, 25)
    rotBuilder.clearBtn:SetPoint("LEFT", rotBuilder.loadBtn, "RIGHT", 5, 0)
    rotBuilder.clearBtn:SetText("Clear")
    rotBuilder.clearBtn:SetScript("OnClick", function()
        _G.CurrentRotation = {}
        UpdateRotationList()
        print("Rotation cleared")
    end)

    _G.WowBotRotationBuilder = rotBuilder
    print("Created Rotation Builder GUI")
end

-- Update rotation list display
function UpdateRotationList()
    -- Clear old buttons
    for _, btn in pairs(rotBuilder.rotationList) do
        btn:Hide()
        btn:SetParent(nil)
    end
    rotBuilder.rotationList = {}

    -- Create buttons for current rotation
    local yOffset = -70
    for i, spell in ipairs(_G.CurrentRotation) do
        local btn = CreateFrame("Button", nil, rotBuilder.dropZone)
        btn:SetSize(340, 30)
        btn:SetPoint("TOP", 0, yOffset)

        -- Background
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.1, 0.3, 0.1, 0.8)

        -- Priority number
        btn.num = btn:CreateFontString(nil, "OVERLAY")
        btn.num:SetFontObject("GameFontNormalSmall")
        btn.num:SetPoint("LEFT", 5, 0)
        btn.num:SetText("#" .. i)

        -- Icon
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetSize(24, 24)
        btn.icon:SetPoint("LEFT", 30, 0)
        btn.icon:SetTexture(spell.icon)

        -- Spell name
        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetFontObject("GameFontNormalSmall")
        btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 5, 0)
        btn.text:SetText(spell.name)

        -- Remove button
        btn.removeBtn = CreateFrame("Button", nil, btn)
        btn.removeBtn:SetSize(20, 20)
        btn.removeBtn:SetPoint("RIGHT", -5, 0)
        btn.removeBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        btn.removeBtn:SetScript("OnClick", function()
            table.remove(_G.CurrentRotation, i)
            UpdateRotationList()
            print("Removed " .. spell.name .. " from rotation")
        end)

        -- Move up button
        if i > 1 then
            btn.upBtn = CreateFrame("Button", nil, btn)
            btn.upBtn:SetSize(20, 20)
            btn.upBtn:SetPoint("RIGHT", btn.removeBtn, "LEFT", -5, 0)
            btn.upBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
            btn.upBtn:SetScript("OnClick", function()
                _G.CurrentRotation[i], _G.CurrentRotation[i-1] = _G.CurrentRotation[i-1], _G.CurrentRotation[i]
                UpdateRotationList()
            end)
        end

        -- Move down button
        if i < #_G.CurrentRotation then
            btn.downBtn = CreateFrame("Button", nil, btn)
            btn.downBtn:SetSize(20, 20)
            btn.downBtn:SetPoint("RIGHT", btn.removeBtn, "LEFT", (i > 1 and -30 or -5), 0)
            btn.downBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
            btn.downBtn:SetScript("OnClick", function()
                _G.CurrentRotation[i], _G.CurrentRotation[i+1] = _G.CurrentRotation[i+1], _G.CurrentRotation[i]
                UpdateRotationList()
            end)
        end

        rotBuilder.rotationList[i] = btn
        yOffset = yOffset - 35
    end

    -- Dynamically resize drop zone based on number of spells
    local baseHeight = 100 -- Minimum height for empty state
    local spellHeight = 35 -- Height per spell
    local numSpells = #_G.CurrentRotation
    local newHeight = baseHeight + (numSpells * spellHeight)

    rotBuilder.dropZone:SetHeight(newHeight)

    -- Update texture tiling to match new height
    local textureSize = 64
    local dropZoneWidth = 360
    local horizTile = dropZoneWidth / textureSize
    local vertTile = newHeight / textureSize
    rotBuilder.dropZone.bg:SetTexCoord(0, horizTile, 0, vertTile)
end

-- Save rotation to file
function SaveRotation()
    local rotName = rotBuilder.nameBox:GetText()
    if not rotName or rotName == "" then
        print("Please enter a rotation name")
        return
    end

    if #_G.CurrentRotation == 0 then
        print("Rotation is empty, nothing to save")
        return
    end

    -- Serialize rotation to Lua code
    local content = "-- Saved Rotation: " .. rotName .. "\nreturn {\n"
    content = content .. "    name = \"" .. rotName .. "\",\n"
    content = content .. "    spells = {\n"

    for i, spell in ipairs(_G.CurrentRotation) do
        content = content .. "        {\n"
        content = content .. "            id = " .. spell.id .. ",\n"
        content = content .. "            name = \"" .. spell.name .. "\",\n"
        content = content .. "            icon = \"" .. spell.icon .. "\",\n"
        content = content .. "        },\n"
    end

    content = content .. "    }\n}\n"

    -- Save to file using WriteFile (uses global function)
    local fileName = _G.BOTETO_BASE_PATH .. "rotations/" .. rotName .. ".lua"

    print("[SaveRotation] Attempting to save to: " .. fileName)
    print("[SaveRotation] Rotation has " .. #_G.CurrentRotation .. " spells")

    local success = FileManagement.WriteFile(fileName, content, false)

    if success then
        -- Success messages
        print("=== Rotation Saved Successfully ===")
        print("Name: " .. rotName)
        print("Spells: " .. #_G.CurrentRotation)
        print("File: " .. fileName)
        print("===================================")

        -- Also show in chat frame
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Rotation '" .. rotName .. "' saved successfully!|r")
    else
        -- Error messages
        print("=== SAVE FAILED ===")
        print("Could not write to: " .. fileName)
        print("===================")

        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Failed to save rotation!|r")
    end
end

-- Make save rotation function globally accessible
_G.SaveRotation = SaveRotation

-- Load rotation from file
function LoadRotationByName()
    local rotName = rotBuilder.nameBox:GetText()
    if not rotName or rotName == "" then
        print("Please enter a rotation name to load")
        return
    end

    print("[LoadRotation] Attempting to load: " .. rotName)

    local rotation = FileManagement.LoadRotation(rotName)
    if not rotation then
        print("=== LOAD FAILED ===")
        print("Could not load rotation: " .. rotName)
        print("===================")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Failed to load rotation!|r")
        return
    end

    -- Clear current rotation
    _G.CurrentRotation = {}

    -- DEBUG: Check rotation structure
    print("[DEBUG] rotation type: " .. type(rotation))
    print("[DEBUG] rotation.name: " .. tostring(rotation.name))
    print("[DEBUG] rotation.spells type: " .. type(rotation.spells))
    if rotation.spells then
        print("[DEBUG] rotation.spells count: " .. #rotation.spells)
    end

    -- Load spells from file
    if rotation.spells then
        for _, spell in ipairs(rotation.spells) do
            print("[DEBUG] Loading spell: ID=" .. tostring(spell.id) .. ", Name=" .. tostring(spell.name))
            table.insert(_G.CurrentRotation, {
                id = spell.id,
                name = spell.name,
                icon = spell.icon
            })
        end
    end

    print("[DEBUG] _G.CurrentRotation count after load: " .. #_G.CurrentRotation)

    -- Update display
    UpdateRotationList()

    print("=== Rotation Loaded Successfully ===")
    print("Name: " .. rotation.name)
    print("Spells: " .. #_G.CurrentRotation)
    print("====================================")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Rotation '" .. rotName .. "' loaded successfully!|r")

    -- Save this as the last loaded rotation
    local configDir = _G.BOTETO_BASE_PATH .. "config/"
    if not FileManagement.DirectoryExists(configDir) then
        print("[LoadRotation] Creating config directory: " .. configDir)
        local dirSuccess = FileManagement.CreateDirectory(configDir)
        if not dirSuccess then
            print("[WARNING] Failed to create config directory")
        else
            -- Directory created, try to write file
            local lastRotFile = configDir .. "last_rotation.txt"
            local writeSuccess = FileManagement.WriteFile(lastRotFile, rotName, false)
            if writeSuccess then
                print("[LoadRotation] Saved as last rotation: " .. rotName)
            else
                print("[WARNING] Failed to save last rotation file")
            end
        end
    else
        -- Directory exists, write file
        local lastRotFile = configDir .. "last_rotation.txt"
        local writeSuccess = FileManagement.WriteFile(lastRotFile, rotName, false)
        if writeSuccess then
            print("[LoadRotation] Saved as last rotation: " .. rotName)
        else
            print("[WARNING] Failed to save last rotation file")
        end
    end
end

-- Make load rotation function globally accessible
_G.LoadRotationByName = LoadRotationByName

-- Toggle rotation builder visibility
function ToggleRotationBuilder()
    if rotBuilder:IsShown() then
        rotBuilder:Hide()
    else
        rotBuilder:Show()
        UpdateRotationList()
    end
end

-- Make rotation builder functions globally accessible
_G.ToggleRotationBuilder = ToggleRotationBuilder

-- Modules and debug commands already exported at top of file

-- ============================================
-- INITIALIZE CONFIG DIRECTORY
-- ============================================

-- Create config directory if it doesn't exist
local configDir = _G.BOTETO_BASE_PATH .. "config/"
if not FileManagement.DirectoryExists(configDir) then
    print("[Init] Creating config directory: " .. configDir)
    FileManagement.CreateDirectory(configDir)
end

-- ============================================
-- AUTO-LOAD LAST ROTATION
-- ============================================

-- Auto-load last rotation if available
local lastRotFile = configDir .. "last_rotation.txt"
if FileManagement.FileExists(lastRotFile) then
    local lastRotName = FileManagement.ReadFile(lastRotFile)
    if lastRotName and lastRotName ~= "" then
        -- Clean up any whitespace
        lastRotName = lastRotName:match("^%s*(.-)%s*$")
        print("[Init] Auto-loading last rotation: " .. lastRotName)

        -- Load the rotation
        local rotation = FileManagement.LoadRotation(lastRotName)
        if rotation and rotation.spells then
            _G.CurrentRotation = {}
            for _, spell in ipairs(rotation.spells) do
                table.insert(_G.CurrentRotation, {
                    id = spell.id,
                    name = spell.name,
                    icon = spell.icon
                })
            end
            UpdateRotationList()
            print("[Init] Rotation '" .. lastRotName .. "' loaded with " .. #_G.CurrentRotation .. " spells")
        else
            print("[Init] Failed to load rotation: " .. lastRotName)
        end
    end
end

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

print("=== BOTETO Loaded Successfully ===")
print("Commands:")
print("  /run StopBot() - Stop the bot")
print("  /run StartBot() - Start the bot")
print("  /run ToggleGUI() - Show/hide main GUI")
print("  /run PrintState() - Print state machine status")
print("  /run Combat.PrintRotationStatus() - Print rotation status")
print("  /run Looting.PrintLootingStatus() - Print looting status")
print("  /run SetBotState(StateMachine.STATES.FIGHTING) - Manually set state")
print("Click 'Rotation Builder' button to build rotations!")
print("Build a rotation and start the bot to auto-fight and loot!")
