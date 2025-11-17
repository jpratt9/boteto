--[[
    BOTETO Main Bot Logic
    Loaded by wow-bot.lua entrypoint
]]

local Tinkr = ...

print("=== Loading BOTETO Main ===")

-- ============================================
-- CONFIGURATION
-- ============================================

-- Set base path (absolute path to dev folder)
_G.BOTETO_BASE_PATH = "/Users/john/dev/boteto/"

-- ============================================
-- LOAD MODULES
-- ============================================

-- Load state machine module
print("Loading state_machine.lua...")
local stateCode = ReadFile("/Users/john/dev/boteto/core/state_machine.lua")
if not stateCode then
    error("Failed to load state_machine.lua")
end

local loadFunc, loadErr = (load or loadstring)(stateCode, "state_machine.lua")
if not loadFunc then
    error("Failed to compile state_machine.lua: " .. tostring(loadErr))
end

local StateMachine = loadFunc()
if not StateMachine then
    error("state_machine.lua did not return a module table")
end
print("[✓] State Machine loaded")

-- Load file management module
print("Loading file_management.lua...")
local fileCode = ReadFile("/Users/john/dev/boteto/core/file_management.lua")
if not fileCode then
    error("Failed to load file_management.lua")
end

loadFunc, loadErr = (load or loadstring)(fileCode, "file_management.lua")
if not loadFunc then
    error("Failed to compile file_management.lua: " .. tostring(loadErr))
end

local FileManagement = loadFunc()
if not FileManagement then
    error("file_management.lua did not return a module table")
end
print("[✓] File Management loaded")

-- Load combat module
print("Loading combat.lua...")
local combatCode = ReadFile("/Users/john/dev/boteto/core/combat.lua")
if not combatCode then
    error("Failed to load combat.lua")
end

loadFunc, loadErr = (load or loadstring)(combatCode, "combat.lua")
if not loadFunc then
    error("Failed to compile combat.lua: " .. tostring(loadErr))
end

local Combat = loadFunc()
if not Combat then
    error("combat.lua did not return a module table")
end
print("[✓] Combat loaded")

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

-- Get nearby alive enemies (global so Combat module can use it)
function GetEnemies(maxDistance)
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

-- Main update function
local function BotUpdate()
    if not _G.BotEnabled then return end

    updateCount = updateCount + 1

    -- Execute combat rotation
    Combat.ExecuteRotation()
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

-- ============================================
-- GUI SYSTEM
-- ============================================

-- Create main GUI window
local gui = _G.WowBotGUI
if not gui then
    -- Create main frame
    gui = CreateFrame("Frame", "WowBotGUI", UIParent, "BasicFrameTemplateWithInset")
    gui:SetSize(300, 400)
    gui:SetPoint("CENTER")
    gui:SetMovable(true)
    gui:EnableMouse(true)
    gui:RegisterForDrag("LeftButton")
    gui:SetScript("OnDragStart", gui.StartMoving)
    gui:SetScript("OnDragStop", gui.StopMovingOrSizing)
    gui:SetFrameStrata("HIGH")

    -- Title
    gui.title = gui:CreateFontString(nil, "OVERLAY")
    gui.title:SetFontObject("GameFontHighlight")
    gui.title:SetPoint("TOP", 0, -5)
    gui.title:SetText("WoW Bot Control")

    -- Status text
    gui.status = gui:CreateFontString(nil, "OVERLAY")
    gui.status:SetFontObject("GameFontNormal")
    gui.status:SetPoint("TOP", 0, -40)
    gui.status:SetText("Status: Stopped")

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

    -- Rotation Builder button
    gui.rotationBtn = CreateFrame("Button", nil, gui, "GameMenuButtonTemplate")
    gui.rotationBtn:SetSize(120, 30)
    gui.rotationBtn:SetPoint("TOP", 0, -110)
    gui.rotationBtn:SetText("Rotation Builder")
    gui.rotationBtn:SetScript("OnClick", function()
        ToggleRotationBuilder()
    end)

    -- Stats frame
    gui.statsText = gui:CreateFontString(nil, "OVERLAY")
    gui.statsText:SetFontObject("GameFontNormalSmall")
    gui.statsText:SetPoint("TOPLEFT", 20, -150)
    gui.statsText:SetJustifyH("LEFT")
    gui.statsText:SetText("Targets Found: 0\nBot State: Idle")

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
        local enemies = GetEnemies(40)
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

    -- Load spells from file
    if rotation.spells then
        for _, spell in ipairs(rotation.spells) do
            table.insert(_G.CurrentRotation, {
                id = spell.id,
                name = spell.name,
                icon = spell.icon
            })
        end
    end

    -- Update display
    UpdateRotationList()

    print("=== Rotation Loaded Successfully ===")
    print("Name: " .. rotation.name)
    print("Spells: " .. #_G.CurrentRotation)
    print("====================================")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Rotation '" .. rotName .. "' loaded successfully!|r")
end

-- Toggle rotation builder visibility
function ToggleRotationBuilder()
    if rotBuilder:IsShown() then
        rotBuilder:Hide()
    else
        rotBuilder:Show()
        UpdateRotationList()
    end
end

-- ============================================
-- HELPER COMMANDS
-- ============================================

-- State machine helper commands
function PrintState()
    StateMachine.PrintStatus()
end

function SetBotState(state)
    StateMachine.SetState(state)
end

-- Make StateMachine globally accessible for debugging
_G.StateMachine = StateMachine

-- Make Combat globally accessible for debugging
_G.Combat = Combat

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
print("  /run SetBotState(StateMachine.STATES.FIGHTING) - Manually set state")
print("Click 'Rotation Builder' button to build rotations!")
print("Build a rotation and start the bot to auto-fight enemies!")
