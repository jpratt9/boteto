--[[
    Long Frame Module (Dropdown Panel)
    Creates the expandable panel that appears when dropdown is clicked
    BANETO pattern - lines 71739-71758
]]

local LongFrame = {}

local longFrame = nil

-- Create the LONG frame (dropdown panel)
-- @param parentFrame: the main SHORT frame to attach to
-- @return frame object
function LongFrame.Create(parentFrame)
    -- Reuse existing frame if it exists (prevents duplicates on reload)
    if longFrame then
        return longFrame
    end
    if _G.BotetoLongFrame then
        longFrame = _G.BotetoLongFrame
        return longFrame
    end

    -- Create LONG frame (BANETO lines 71739-71744)
    longFrame = CreateFrame("Frame", "BotetoLongFrame", parentFrame)
    longFrame:ClearAllPoints()
    longFrame:SetPoint("TOP", parentFrame, "TOP", 0, 0)
    longFrame:SetSize(220, 440)

    -- Backdrop (BANETO lines 71746-71757)
    longFrame.Backdrop = CreateFrame("Frame", nil, longFrame, "BackdropTemplate")
    longFrame.Backdrop:SetAllPoints()
    longFrame.Backdrop:SetFrameLevel(2)
    longFrame.Backdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Menu buttons container
    longFrame.menuButtons = {}

    -- Profile Library button (BANETO line 72765-72774, Y=-53)
    longFrame.menuButtons.libraryBtn = LongFrame.CreateMenuButton(longFrame, "Profile Library", -53, function()
        if _G.GUI and _G.GUI.ProfileLibrary then
            _G.GUI.ProfileLibrary.Toggle()
        end
    end)

    -- Class Settings button (BANETO line 72820-72831, Y=-98)
    longFrame.menuButtons.classBtn = LongFrame.CreateMenuButton(longFrame, "Class Settings", -98, function()
        print("[BOTETO] Class Settings not implemented yet")
    end)

    -- Bot Settings button (BANETO line 72881-72887, Y=-143)
    longFrame.menuButtons.settingsBtn = LongFrame.CreateMenuButton(longFrame, "Bot Settings", -143, function()
        print("[BOTETO] Bot Settings not implemented yet")
    end)

    -- Rotation Builder button (Y=-188)
    longFrame.menuButtons.rotationBtn = LongFrame.CreateMenuButton(longFrame, "Rotation Builder", -188, function()
        _G.ToggleRotationBuilder()
    end)

    -- Support/Credits button (BANETO line 72995-73001, Y=-233)
    longFrame.menuButtons.creditsBtn = LongFrame.CreateMenuButton(longFrame, "Credits", -233, function()
        print("[BOTETO] Credits not implemented yet")
    end)

    -- Stats Toggle button (BANETO lines 72435-72468)
    -- Position: TOPLEFT, LONG, BOTTOM, 114, 69
    longFrame.statsToggleBtn = CreateFrame("Button", nil, longFrame)
    longFrame.statsToggleBtn:SetSize(40, 40)
    longFrame.statsToggleBtn:SetPoint("TOPLEFT", longFrame, "BOTTOM", 114, 69)
    longFrame.statsToggleBtn:SetNormalFontObject("GameFontNormalSmall")

    local stntex = longFrame.statsToggleBtn:CreateTexture()
    stntex:SetTexture(GetItemIcon(17364))
    stntex:SetTexCoord(0, 0.955, 0, 0.955)
    stntex:SetAllPoints()
    longFrame.statsToggleBtn:SetNormalTexture(stntex)

    local sthtex = longFrame.statsToggleBtn:CreateTexture()
    sthtex:SetTexture(GetItemIcon(17364))
    sthtex:SetTexCoord(0, 0.955, 0, 0.955)
    sthtex:SetAllPoints()
    longFrame.statsToggleBtn:SetHighlightTexture(sthtex)

    local stptex = longFrame.statsToggleBtn:CreateTexture()
    stptex:SetTexture(GetItemIcon(17364))
    stptex:SetTexCoord(0, 0.955, 0, 0.955)
    stptex:SetAllPoints()
    longFrame.statsToggleBtn:SetPushedTexture(stptex)

    longFrame.statsToggleBtn:SetScript("OnClick", function()
        if not _G.BOTETO_SETTINGS_STATSTOGGLE or _G.BOTETO_SETTINGS_STATSTOGGLE == false then
            _G.BOTETO_SETTINGS_STATSTOGGLE = true
        else
            _G.BOTETO_SETTINGS_STATSTOGGLE = false
        end
    end)

    -- Fishing button (BANETO lines 72470-72504)
    -- Position: TOPLEFT, LONG, BOTTOM, 114, 115
    longFrame.fishingBtn = CreateFrame("Button", nil, longFrame)
    longFrame.fishingBtn:SetSize(40, 40)
    longFrame.fishingBtn:SetPoint("TOPLEFT", longFrame, "BOTTOM", 114, 115)
    longFrame.fishingBtn:SetNormalFontObject("GameFontNormalSmall")

    local fntex = longFrame.fishingBtn:CreateTexture()
    fntex:SetTexture(GetSpellTexture(18248) or GetItemIcon(6256))
    fntex:SetTexCoord(0, 0.955, 0, 0.955)
    fntex:SetAllPoints()
    longFrame.fishingBtn:SetNormalTexture(fntex)

    local fhtex = longFrame.fishingBtn:CreateTexture()
    fhtex:SetTexture(GetSpellTexture(18248) or GetItemIcon(6256))
    fhtex:SetTexCoord(0, 0.955, 0, 0.955)
    fhtex:SetAllPoints()
    longFrame.fishingBtn:SetHighlightTexture(fhtex)

    local fptex = longFrame.fishingBtn:CreateTexture()
    fptex:SetTexture(GetSpellTexture(18248) or GetItemIcon(6256))
    fptex:SetTexCoord(0, 0.955, 0, 0.955)
    fptex:SetAllPoints()
    longFrame.fishingBtn:SetPushedTexture(fptex)

    longFrame.fishingBtn:SetScript("OnClick", function()
        if _G.BotEnabled then
            print("[Fishing] Bot is already running!")
            return
        end
        if _G.GUI and _G.GUI.RotationBuilder then
            _G.GUI.RotationBuilder.SetRotationName("fishing")
            _G.GUI.RotationBuilder.Load()
            print("[Fishing] Loaded fishing rotation")
        else
            print("[Fishing] Rotation builder not available")
        end
    end)

    -- Initially hidden
    longFrame:Hide()

    return longFrame
end

-- Helper function to create menu buttons (BANETO pattern)
-- @param parent: parent frame
-- @param text: button text
-- @param yOffset: Y position offset from TOP
-- @param onClick: click handler function
-- @return button frame
function LongFrame.CreateMenuButton(parent, text, yOffset, onClick)
    local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    btn:SetSize(211, 45)
    btn:SetPoint("TOP", parent, "TOP", 1, yOffset)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Show the LONG frame
function LongFrame.Show()
    if longFrame then
        longFrame:Show()
    end
end

-- Hide the LONG frame
function LongFrame.Hide()
    if longFrame then
        longFrame:Hide()
    end
end

-- Toggle the LONG frame
function LongFrame.Toggle()
    if longFrame then
        if longFrame:IsShown() then
            longFrame:Hide()
        else
            longFrame:Show()
        end
    end
end

-- Check if LONG frame is visible
function LongFrame.IsVisible()
    return longFrame and longFrame:IsShown()
end

-- Get the frame
function LongFrame.GetFrame()
    return longFrame
end

return LongFrame
