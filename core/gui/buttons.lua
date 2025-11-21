--[[
    Buttons Module
    Creates all control buttons for the main frame
]]

local Buttons = {}

-- Create all buttons
-- @param parentFrame: the main frame to attach to
-- @return buttons table
function Buttons.Create(parentFrame)
    local buttons = {}

    -- Status text (keep for compatibility)
    buttons.status = parentFrame:CreateFontString(nil, "OVERLAY")
    buttons.status:SetFontObject("GameFontNormal")
    buttons.status:SetPoint("TOP", 0, -40)
    buttons.status:SetText("Status: Stopped")
    buttons.status:Hide()  -- Hidden in compact mode

    -- Start/Stop button (BANETO pattern - lines 72609-72657)
    buttons.startStopBtn = CreateFrame("Button", nil, parentFrame)
    buttons.startStopBtn:SetSize(40, 40)
    buttons.startStopBtn:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 5, -8)
    buttons.startStopBtn:SetNormalFontObject("GameFontNormalSmall")

    -- Normal texture
    local ssntex = buttons.startStopBtn:CreateTexture()
    ssntex:SetTexture(GetItemIcon(7971))
    ssntex:SetTexCoord(0, 0.955, 0, 0.955)
    ssntex:SetAllPoints()
    buttons.startStopBtn:SetNormalTexture(ssntex)

    -- Highlight texture
    local sshtex = buttons.startStopBtn:CreateTexture()
    sshtex:SetTexture(GetItemIcon(7971))
    sshtex:SetTexCoord(0, 0.955, 0, 0.955)
    sshtex:SetAllPoints()
    buttons.startStopBtn:SetHighlightTexture(sshtex)

    -- Pushed texture
    local ssptex = buttons.startStopBtn:CreateTexture()
    ssptex:SetTexture(GetItemIcon(7971))
    ssptex:SetTexCoord(0, 0.955, 0, 0.955)
    ssptex:SetAllPoints()
    buttons.startStopBtn:SetPushedTexture(ssptex)

    buttons.startStopBtn:SetScript("OnClick", function()
        if _G.BotEnabled then
            _G.StopBot()
        else
            _G.StartBot()
        end
    end)

    -- Old text-based toggle button (for dropdown menu)
    buttons.toggleBtn = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    buttons.toggleBtn:SetSize(120, 30)
    buttons.toggleBtn:SetPoint("TOP", 0, -70)
    buttons.toggleBtn:SetText("Start Bot")
    buttons.toggleBtn:SetScript("OnClick", function()
        if _G.BotEnabled then
            _G.StopBot()
        else
            _G.StartBot()
        end
    end)
    buttons.toggleBtn:Hide()  -- Hidden until dropdown expanded

    -- Rotation Builder button
    buttons.rotationBtn = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    buttons.rotationBtn:SetSize(120, 30)
    buttons.rotationBtn:SetPoint("TOP", 0, -110)
    buttons.rotationBtn:SetText("Rotation Builder")
    buttons.rotationBtn:SetScript("OnClick", function()
        _G.ToggleRotationBuilder()
    end)
    buttons.rotationBtn:Hide()  -- Hidden in compact mode

    -- Sell Junk button
    buttons.sellJunkBtn = CreateFrame("Button", nil, parentFrame, "GameMenuButtonTemplate")
    buttons.sellJunkBtn:SetSize(120, 30)
    buttons.sellJunkBtn:SetPoint("TOP", 0, -150)
    buttons.sellJunkBtn:SetText("Sell Junk")
    buttons.sellJunkBtn:SetScript("OnClick", function()
        if _G.Vendor and _G.Vendor.IsMerchantOpen() then
            _G.Vendor.SellGrayItems()
        else
            print("[Vendor] Please open a merchant window first!")
        end
    end)
    buttons.sellJunkBtn:Hide()  -- Hidden in compact mode

    -- Stats Toggle Button (BANETO pattern - lines 72435-72468)
    buttons.statsToggleBtn = CreateFrame("Button", nil, parentFrame)
    buttons.statsToggleBtn:SetSize(40, 40)
    buttons.statsToggleBtn:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 114, 69)
    buttons.statsToggleBtn:SetNormalFontObject("GameFontNormalSmall")

    -- Normal texture
    local ntex = buttons.statsToggleBtn:CreateTexture()
    ntex:SetTexture(GetItemIcon(17364))
    ntex:SetTexCoord(0, 0.955, 0, 0.955)
    ntex:SetAllPoints()
    buttons.statsToggleBtn:SetNormalTexture(ntex)

    -- Highlight texture
    local htex = buttons.statsToggleBtn:CreateTexture()
    htex:SetTexture(GetItemIcon(17364))
    htex:SetTexCoord(0, 0.955, 0, 0.955)
    htex:SetAllPoints()
    buttons.statsToggleBtn:SetHighlightTexture(htex)

    -- Pushed texture
    local ptex = buttons.statsToggleBtn:CreateTexture()
    ptex:SetTexture(GetItemIcon(17364))
    ptex:SetTexCoord(0, 0.955, 0, 0.955)
    ptex:SetAllPoints()
    buttons.statsToggleBtn:SetPushedTexture(ptex)

    -- OnClick handler (BANETO pattern - lines 72444-72451)
    buttons.statsToggleBtn:SetScript("OnClick", function()
        if not _G.BOTETO_SETTINGS_STATSTOGGLE or _G.BOTETO_SETTINGS_STATSTOGGLE == false then
            _G.BOTETO_SETTINGS_STATSTOGGLE = true
        else
            _G.BOTETO_SETTINGS_STATSTOGGLE = false
        end
    end)
    buttons.statsToggleBtn:Hide()  -- Hidden until LONG frame implemented

    -- Dropdown Button (BANETO pattern - lines 72557-72580)
    buttons.dropdownBtn = CreateFrame("Button", nil, parentFrame)
    buttons.dropdownBtn:SetSize(40, 40)
    buttons.dropdownBtn:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -7, -8)
    buttons.dropdownBtn:SetNormalFontObject("GameFontNormalSmall")

    -- Normal texture
    local dntex = buttons.dropdownBtn:CreateTexture()
    dntex:SetTexture(GetItemIcon(11855))
    dntex:SetTexCoord(0, 0.955, 0, 0.955)
    dntex:SetAllPoints()
    buttons.dropdownBtn:SetNormalTexture(dntex)

    -- Highlight texture
    local dhtex = buttons.dropdownBtn:CreateTexture()
    dhtex:SetTexture(GetItemIcon(11855))
    dhtex:SetTexCoord(0, 0.955, 0, 0.955)
    dhtex:SetAllPoints()
    buttons.dropdownBtn:SetHighlightTexture(dhtex)

    -- Pushed texture
    local dptex = buttons.dropdownBtn:CreateTexture()
    dptex:SetTexture(GetItemIcon(11855))
    dptex:SetTexCoord(0, 0.955, 0, 0.955)
    dptex:SetAllPoints()
    buttons.dropdownBtn:SetPushedTexture(dptex)

    -- OnClick handler - toggle LONG frame (BANETO pattern - lines 73108-73187)
    buttons.dropdownBtn:SetScript("OnClick", function()
        if _G.GUI and _G.GUI.LongFrame then
            _G.GUI.LongFrame.Toggle()
        end
    end)

    -- Fishing Button (BANETO pattern - lines 72470-72504)
    buttons.fishingBtn = CreateFrame("Button", nil, parentFrame)
    buttons.fishingBtn:SetSize(40, 40)
    buttons.fishingBtn:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 156, 69)
    buttons.fishingBtn:SetNormalFontObject("GameFontNormalSmall")

    -- Normal texture
    local fntex = buttons.fishingBtn:CreateTexture()
    fntex:SetTexture(GetSpellTexture(18248) or GetItemIcon(6256))  -- Fishing spell or Fishing Pole item
    fntex:SetTexCoord(0, 0.955, 0, 0.955)
    fntex:SetAllPoints()
    buttons.fishingBtn:SetNormalTexture(fntex)

    -- Highlight texture
    local fhtex = buttons.fishingBtn:CreateTexture()
    fhtex:SetTexture(GetSpellTexture(18248) or GetItemIcon(6256))
    fhtex:SetTexCoord(0, 0.955, 0, 0.955)
    fhtex:SetAllPoints()
    buttons.fishingBtn:SetHighlightTexture(fhtex)

    -- Pushed texture
    local fptex = buttons.fishingBtn:CreateTexture()
    fptex:SetTexture(GetSpellTexture(18248) or GetItemIcon(6256))
    fptex:SetTexCoord(0, 0.955, 0, 0.955)
    fptex:SetAllPoints()
    buttons.fishingBtn:SetPushedTexture(fptex)

    -- OnClick handler - load fishing rotation
    buttons.fishingBtn:SetScript("OnClick", function()
        if _G.BotEnabled then
            print("[Fishing] Bot is already running!")
            return
        end
        -- Try to load fishing rotation
        if _G.GUI and _G.GUI.RotationBuilder then
            _G.GUI.RotationBuilder.SetRotationName("fishing")
            _G.GUI.RotationBuilder.Load()
            print("[Fishing] Loaded fishing rotation")
        else
            print("[Fishing] Rotation builder not available")
        end
    end)
    buttons.fishingBtn:Hide()  -- Hidden until LONG frame implemented

    -- Update function for status text
    function buttons:Update(enabled)
        if self.status then
            if enabled then
                self.status:SetText("|cff00ff00Status: Running|r")
                if self.toggleBtn then
                    self.toggleBtn:SetText("Stop Bot")
                end
            else
                self.status:SetText("|cffff0000Status: Stopped|r")
                if self.toggleBtn then
                    self.toggleBtn:SetText("Start Bot")
                end
            end
        end
    end

    return buttons
end

return Buttons
