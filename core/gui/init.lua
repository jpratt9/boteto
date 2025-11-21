--[[
    GUI Initialization Module
    Loads and initializes all GUI components
]]

local GUI = {}

-- Internal references
local mainFrame = nil
local statsFrame = nil
local buttons = nil

-- Load sub-modules
local function LoadModule(modulePath)
    local code = ReadFile(_G.BOTETO_BASE_PATH .. modulePath)
    if not code then
        error("Failed to load " .. modulePath)
    end

    local loadFunc, loadErr = (load or loadstring)(code, modulePath)
    if not loadFunc then
        error("Failed to compile " .. modulePath .. ": " .. tostring(loadErr))
    end

    -- CRITICAL FIX: Force loaded function to use current environment
    setfenv(loadFunc, getfenv())

    local module = loadFunc()
    if not module then
        error(modulePath .. " did not return a module table")
    end

    return module
end

-- Initialize all GUI components
function GUI.Initialize()
    print("[GUI] Initializing GUI modules...")

    -- Load modules
    local MainFrame = LoadModule("core/gui/main_frame.lua")
    local StatsOverlay = LoadModule("core/gui/stats_overlay.lua")
    local Buttons = LoadModule("core/gui/buttons.lua")
    local RotationBuilder = LoadModule("core/gui/rotation_builder.lua")
    local LongFrame = LoadModule("core/gui/long_frame.lua")
    local ProfileLibrary = LoadModule("core/gui/profile_library.lua")

    -- Create main frame
    mainFrame = MainFrame.Create()
    GUI.frame = mainFrame

    -- Create stats overlay
    statsFrame = StatsOverlay.Create(mainFrame)
    GUI.statsFrame = statsFrame

    -- Create buttons
    buttons = Buttons.Create(mainFrame)
    GUI.buttons = buttons

    -- Create LONG frame (dropdown panel)
    local longFrame = LongFrame.Create(mainFrame)
    GUI.LongFrame = LongFrame

    -- Create rotation builder (lazy-loaded, just expose the module)
    GUI.RotationBuilder = RotationBuilder

    -- Create profile library
    ProfileLibrary.Create()
    GUI.ProfileLibrary = ProfileLibrary

    -- Make frames globally accessible for compatibility
    _G.WowBotGUI = mainFrame
    _G.gui = mainFrame

    print("[GUI] GUI initialization complete")

    return GUI
end

-- Show GUI
function GUI.Show()
    if mainFrame then
        mainFrame:Show()
    end
end

-- Hide GUI
function GUI.Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

-- Toggle GUI visibility
function GUI.Toggle()
    if mainFrame then
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
    end
end

-- Update GUI (called every frame)
function GUI.Update()
    if not mainFrame then return end

    -- Update button states
    if buttons and buttons.Update then
        buttons:Update(_G.BotEnabled)
    end

    -- Update stats display
    if statsFrame and statsFrame.Update then
        local player = GetPlayer()
        if player then
            local x, y = ObjectPosition(player)
            local enemies = GetEnemies and GetEnemies(70) or {}
            local currentState = _G.StateMachine and _G.StateMachine.GetState() or "IDLE"
            local deaths = 0 -- TODO: track deaths

            statsFrame:Update(currentState, #enemies, deaths)
        end
    end

    -- Stats visibility sync (BANETO pattern - lines 58900-58904)
    if statsFrame then
        if not statsFrame:IsVisible() and _G.BOTETO_SETTINGS_STATSTOGGLE == true then
            statsFrame:Show()
        elseif statsFrame:IsVisible() and (not _G.BOTETO_SETTINGS_STATSTOGGLE or _G.BOTETO_SETTINGS_STATSTOGGLE == false) then
            statsFrame:Hide()
        end
    end
end

-- Expose rotation builder functions globally for compatibility
_G.ToggleRotationBuilder = function()
    if GUI.RotationBuilder then
        GUI.RotationBuilder.Toggle()
    end
end

_G.UpdateRotationList = function()
    if GUI.RotationBuilder then
        GUI.RotationBuilder.UpdateList()
    end
end

_G.SaveRotation = function()
    if GUI.RotationBuilder then
        GUI.RotationBuilder.Save()
    end
end

_G.LoadRotationByName = function()
    if GUI.RotationBuilder then
        GUI.RotationBuilder.Load()
    end
end

return GUI
