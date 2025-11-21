--[[
    Main Frame Module
    Creates the compact BOTETO main window (225×55)
]]

local MainFrame = {}

-- Create the main compact frame
-- @return frame object
function MainFrame.Create()
    -- Reuse existing frame if it exists (prevents duplicates on reload)
    if _G.WowBotGUI then
        return _G.WowBotGUI
    end

    -- Create main frame (BANETO style - lines 71652-71733)
    local frame = CreateFrame("Frame", "WowBotGUI", UIParent)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 23, -120)
    frame:SetSize(225, 55)
    frame:SetFrameLevel(10)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Create backdrop (BANETO pattern)
    frame.Backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.Backdrop:SetAllPoints()
    frame.Backdrop:SetFrameLevel(8)
    frame.Backdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame.Backdrop:EnableMouse(false)

    -- Title with MORPHEUS font (BANETO pattern - line 72544-72555)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("CENTER", 1, -3)
    frame.title:SetText("BOTETO")

    -- Check locale for font choice
    local locale = GetLocale()
    if locale == "zhCN" or locale == "zhTW" or locale == "koKR" or locale == "ruRU" then
        frame.title:SetFont("Fonts\\FRIZQT__.TTF", 29)
    else
        frame.title:SetFont("Fonts\\MORPHEUS.ttf", 29)
    end

    return frame
end

return MainFrame
