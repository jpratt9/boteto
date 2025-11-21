--[[
    Profile Library Module
    BANETO pattern - lines 75540-75670, 87409-87950, 40421-40644
]]

local ProfileLibrary = {}

local mainFrame = nil
local subFrame = nil
local scrollFrame = nil
local searchBox = nil
local profileButtons = {}
local categoryButtons = {}

-- Categories for Classic (simplified from retail BANETO)
local CATEGORIES = {
    { name = "GRINDING", yOffset = -35 },
    { name = "GATHERING", yOffset = -75 },
    { name = "TRAVELING", yOffset = -115 },
    { name = "LOCAL PROFILES", yOffset = -155 },
    { name = "ROTATION MODE", yOffset = -195 },
}

local selectedCategory = "GRINDING"
local searchText = ""

-- Create the Profile Library main frame
-- BANETO lines 75540-75597
function ProfileLibrary.Create()
    -- Reuse existing frame if it exists
    if mainFrame then
        return mainFrame
    end
    if _G.BotetoProfileLibrary then
        mainFrame = _G.BotetoProfileLibrary
        return mainFrame
    end

    -- Main frame (BANETO lines 75540-75563)
    mainFrame = CreateFrame("Frame", "BotetoProfileLibrary", UIParent)
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", -100, 100)
    mainFrame:SetSize(900, 550)
    mainFrame:SetFrameLevel(20)

    -- Backdrop (BANETO pattern)
    mainFrame.Backdrop = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    mainFrame.Backdrop:SetAllPoints()
    mainFrame.Backdrop:SetFrameLevel(3)
    mainFrame.Backdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Draggable (BANETO lines 75592-75597)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

    -- Close button (BANETO lines 87921-87950)
    mainFrame.closeBtn = CreateFrame("Button", nil, mainFrame)
    mainFrame.closeBtn:SetSize(20, 20)
    mainFrame.closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -15, -15)
    mainFrame.closeBtn:SetText("X")
    mainFrame.closeBtn:SetNormalFontObject("GameFontNormalSmall")

    local cntex = mainFrame.closeBtn:CreateTexture()
    cntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
    cntex:SetTexCoord(0, 0.625, 0, 0.6875)
    cntex:SetAllPoints()
    mainFrame.closeBtn:SetNormalTexture(cntex)

    local chtex = mainFrame.closeBtn:CreateTexture()
    chtex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    chtex:SetTexCoord(0, 0.625, 0, 0.6875)
    chtex:SetAllPoints()
    mainFrame.closeBtn:SetHighlightTexture(chtex)

    local cptex = mainFrame.closeBtn:CreateTexture()
    cptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
    cptex:SetTexCoord(0, 0.625, 0, 0.6875)
    cptex:SetAllPoints()
    mainFrame.closeBtn:SetPushedTexture(cptex)

    mainFrame.closeBtn:SetScript("OnClick", function()
        ProfileLibrary.Hide()
    end)

    -- Title (BANETO lines 75606-75626)
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainFrame.title:SetPoint("TOP", 1, -15)
    mainFrame.title:SetText("PROFILE LIBRARY")
    local locale = GetLocale()
    if locale == "zhCN" or locale == "zhTW" or locale == "koKR" or locale == "ruRU" then
        mainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 25)
    else
        mainFrame.title:SetFont("Fonts\\MORPHEUS.ttf", 25)
    end

    -- Categories header (BANETO lines 75629-75649)
    mainFrame.categoriesHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainFrame.categoriesHeader:SetPoint("TOP", -318, -15)
    mainFrame.categoriesHeader:SetText("CATEGORIES")
    if locale == "zhCN" or locale == "zhTW" or locale == "koKR" or locale == "ruRU" then
        mainFrame.categoriesHeader:SetFont("Fonts\\FRIZQT__.TTF", 17)
    else
        mainFrame.categoriesHeader:SetFont("Fonts\\MORPHEUS.ttf", 17)
    end

    -- Create category tabs
    ProfileLibrary.CreateCategoryTabs()

    -- Create sub frame for content (BANETO lines 40421-40432)
    subFrame = CreateFrame("Frame", nil, mainFrame)
    subFrame:ClearAllPoints()
    subFrame:SetPoint("CENTER", mainFrame, "CENTER", 110, -18)
    subFrame:SetSize(610, 500)
    subFrame:SetFrameLevel(30)

    -- Search box (BANETO lines 40433-40445)
    searchBox = CreateFrame("EditBox", nil, subFrame, "InputBoxTemplate")
    searchBox:SetSize(250, 33)
    searchBox:SetAutoFocus(false)
    searchBox:SetPoint("TOP", subFrame, "TOP", -165, 0)
    searchBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText() or ""
        ProfileLibrary.RefreshProfileList()
    end)

    -- Scroll frame (BANETO lines 40447-40477)
    scrollFrame = CreateFrame("ScrollFrame", nil, subFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(295, 450)
    scrollFrame:SetPoint("TOPLEFT", subFrame, "TOPLEFT", -10, -30)

    scrollFrame.Backdrop = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
    scrollFrame.Backdrop:SetAllPoints()
    scrollFrame.Backdrop:SetFrameLevel(4)
    scrollFrame.Backdrop:SetBackdrop({
        bgFile = "",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Scroll child panel
    scrollFrame.panel = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame.panel:SetSize(295, 450)
    scrollFrame.panel:SetPoint("TOP", scrollFrame, "TOP", 0, -5)
    scrollFrame.panel:SetFrameLevel(35)
    scrollFrame:SetScrollChild(scrollFrame.panel)

    -- Initially hidden
    mainFrame:Hide()

    return mainFrame
end

-- Create category tab buttons (BANETO lines 87409-87919)
function ProfileLibrary.CreateCategoryTabs()
    for i, category in ipairs(CATEGORIES) do
        local btn = CreateFrame("Button", nil, mainFrame)
        btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 25, category.yOffset)
        btn:SetSize(211, 40)
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetFrameLevel(21 + i)

        -- Button text
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("LEFT", btn, "LEFT", 10, 0)
        btn.text:SetText("|cffC6C5C3" .. category.name)
        btn.text:SetFont("GameFontNormal", 15)

        -- Highlight texture
        local htex = btn:CreateTexture()
        htex:SetColorTexture(1, 1, 1, 0.2)
        htex:SetAllPoints()
        btn:SetHighlightTexture(htex)

        -- Store category name for click handler
        btn.categoryName = category.name

        btn:SetScript("OnClick", function(self)
            ProfileLibrary.SelectCategory(self.categoryName)
        end)

        categoryButtons[category.name] = btn
    end
end

-- Select a category
function ProfileLibrary.SelectCategory(categoryName)
    selectedCategory = categoryName

    -- Update button text colors
    for name, btn in pairs(categoryButtons) do
        if name == categoryName then
            btn.text:SetText(name)  -- Active (white)
        else
            btn.text:SetText("|cffC6C5C3" .. name)  -- Inactive (gray)
        end
    end

    -- Refresh profile list for this category
    ProfileLibrary.RefreshProfileList()
end

-- Get profiles for current category
function ProfileLibrary.GetProfiles()
    local profiles = {}

    -- Get profiles from rotations directory
    if _G.FileManagement and _G.FileManagement.ListFiles then
        local rotationFiles = _G.FileManagement.ListFiles(_G.BOTETO_BASE_PATH .. "rotations/")
        if rotationFiles then
            for _, file in ipairs(rotationFiles) do
                if file:match("%.lua$") then
                    local name = file:gsub("%.lua$", "")
                    table.insert(profiles, { name = name, path = "rotations/" .. file })
                end
            end
        end
    end

    -- Filter by search text
    if searchText and searchText ~= "" then
        local filtered = {}
        local searchLower = string.lower(searchText)
        for _, profile in ipairs(profiles) do
            if string.lower(profile.name):find(searchLower) then
                table.insert(filtered, profile)
            end
        end
        profiles = filtered
    end

    return profiles
end

-- Refresh the profile list display
function ProfileLibrary.RefreshProfileList()
    -- Clear existing buttons
    for _, btn in ipairs(profileButtons) do
        btn:Hide()
    end
    profileButtons = {}

    if not scrollFrame or not scrollFrame.panel then return end

    local profiles = ProfileLibrary.GetProfiles()
    local yOffset = -4

    for i, profile in ipairs(profiles) do
        local btn = CreateFrame("Button", nil, scrollFrame.panel)
        btn:SetPoint("TOP", scrollFrame.panel, "TOP", 0, yOffset)
        btn:SetSize(291, 20)
        btn:SetNormalFontObject("GameFontNormalSmall")
        btn:SetText("|cffC6C5C3" .. profile.name)
        btn:SetFrameLevel(36)

        -- Highlight texture
        local htex = btn:CreateTexture()
        htex:SetColorTexture(1, 1, 1, 0.2)
        htex:SetAllPoints()
        btn:SetHighlightTexture(htex)

        -- Store profile info
        btn.profileName = profile.name
        btn.profilePath = profile.path

        btn:SetScript("OnClick", function(self)
            ProfileLibrary.LoadProfile(self.profileName, self.profilePath)
        end)

        table.insert(profileButtons, btn)
        yOffset = yOffset - 20
    end

    -- Update scroll child height
    local totalHeight = math.max(450, #profiles * 20 + 10)
    scrollFrame.panel:SetHeight(totalHeight)
end

-- Load a profile
function ProfileLibrary.LoadProfile(name, path)
    print("[Profile Library] Loading profile: " .. name)

    if _G.GUI and _G.GUI.RotationBuilder then
        _G.GUI.RotationBuilder.SetRotationName(name)
        _G.GUI.RotationBuilder.Load()
    end

    -- Hide the library after loading
    ProfileLibrary.Hide()
end

-- Show the Profile Library
function ProfileLibrary.Show()
    if mainFrame then
        mainFrame:Show()
        ProfileLibrary.RefreshProfileList()
    end
end

-- Hide the Profile Library
function ProfileLibrary.Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

-- Toggle the Profile Library
function ProfileLibrary.Toggle()
    if mainFrame then
        if mainFrame:IsShown() then
            ProfileLibrary.Hide()
        else
            ProfileLibrary.Show()
        end
    end
end

-- Check if visible
function ProfileLibrary.IsVisible()
    return mainFrame and mainFrame:IsShown()
end

return ProfileLibrary
