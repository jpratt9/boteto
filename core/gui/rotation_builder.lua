--[[
    Rotation Builder Module
    Creates the rotation builder window for drag-drop spell management
]]

local RotationBuilder = {}

local rotBuilder = nil

-- Create the rotation builder window
-- @return frame object with Toggle(), Show(), Hide() functions
function RotationBuilder.Create()
    if rotBuilder then
        return rotBuilder -- Already created
    end

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
            -- v4 is the actual spell ID
            local spellName, _, icon = GetSpellInfo(v4)

            if spellName then
                table.insert(_G.CurrentRotation, {
                    id = v4,
                    name = spellName,
                    icon = icon
                })
                RotationBuilder.UpdateList()
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
                RotationBuilder.UpdateList()
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
        RotationBuilder.Save()
    end)

    -- Load button
    rotBuilder.loadBtn = CreateFrame("Button", nil, rotBuilder.controls, "GameMenuButtonTemplate")
    rotBuilder.loadBtn:SetSize(60, 25)
    rotBuilder.loadBtn:SetPoint("LEFT", rotBuilder.saveBtn, "RIGHT", 5, 0)
    rotBuilder.loadBtn:SetText("Load")
    rotBuilder.loadBtn:SetScript("OnClick", function()
        RotationBuilder.Load()
    end)

    -- Clear rotation button
    rotBuilder.clearBtn = CreateFrame("Button", nil, rotBuilder.controls, "GameMenuButtonTemplate")
    rotBuilder.clearBtn:SetSize(60, 25)
    rotBuilder.clearBtn:SetPoint("LEFT", rotBuilder.loadBtn, "RIGHT", 5, 0)
    rotBuilder.clearBtn:SetText("Clear")
    rotBuilder.clearBtn:SetScript("OnClick", function()
        _G.CurrentRotation = {}
        RotationBuilder.UpdateList()
        print("Rotation cleared")
    end)

    return rotBuilder
end

-- Update rotation list display
function RotationBuilder.UpdateList()
    if not rotBuilder then return end

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
            RotationBuilder.UpdateList()
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
                RotationBuilder.UpdateList()
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
                RotationBuilder.UpdateList()
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
function RotationBuilder.Save()
    if not rotBuilder then return end

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

    -- Save to file
    local fileName = _G.BOTETO_BASE_PATH .. "rotations/" .. rotName .. ".lua"
    print("[SaveRotation] Attempting to save to: " .. fileName)

    local success = _G.FileManagement.WriteFile(fileName, content, false)

    if success then
        print("=== Rotation Saved Successfully ===")
        print("Name: " .. rotName)
        print("Spells: " .. #_G.CurrentRotation)
        print("File: " .. fileName)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Rotation '" .. rotName .. "' saved successfully!|r")
    else
        print("=== SAVE FAILED ===")
        print("Could not write to: " .. fileName)
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Failed to save rotation!|r")
    end
end

-- Load rotation from file
function RotationBuilder.Load()
    if not rotBuilder then return end

    local rotName = rotBuilder.nameBox:GetText()
    if not rotName or rotName == "" then
        print("Please enter a rotation name to load")
        return
    end

    print("[LoadRotation] Attempting to load: " .. rotName)

    local rotation = _G.FileManagement.LoadRotation(rotName)
    if not rotation then
        print("=== LOAD FAILED ===")
        print("Could not load rotation: " .. rotName)
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
    RotationBuilder.UpdateList()

    print("=== Rotation Loaded Successfully ===")
    print("Name: " .. rotation.name)
    print("Spells: " .. #_G.CurrentRotation)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Rotation '" .. rotName .. "' loaded successfully!|r")

    -- Save this as the last loaded rotation
    local configDir = _G.BOTETO_BASE_PATH .. "config/"
    if not _G.FileManagement.DirectoryExists(configDir) then
        _G.FileManagement.CreateDirectory(configDir)
    end

    local lastRotFile = configDir .. "last_rotation.txt"
    _G.FileManagement.WriteFile(lastRotFile, rotName, false)
end

-- Toggle rotation builder visibility
function RotationBuilder.Toggle()
    if not rotBuilder then
        rotBuilder = RotationBuilder.Create()
    end

    if rotBuilder:IsShown() then
        rotBuilder:Hide()
    else
        rotBuilder:Show()
        RotationBuilder.UpdateList()
    end
end

-- Show rotation builder
function RotationBuilder.Show()
    if not rotBuilder then
        rotBuilder = RotationBuilder.Create()
    end
    rotBuilder:Show()
    RotationBuilder.UpdateList()
end

-- Hide rotation builder
function RotationBuilder.Hide()
    if rotBuilder then
        rotBuilder:Hide()
    end
end

-- Get rotation name from textbox
function RotationBuilder.GetRotationName()
    if rotBuilder and rotBuilder.nameBox then
        return rotBuilder.nameBox:GetText()
    end
    return nil
end

-- Set rotation name in textbox
function RotationBuilder.SetRotationName(name)
    if rotBuilder and rotBuilder.nameBox then
        rotBuilder.nameBox:SetText(name or "")
    end
end

return RotationBuilder
