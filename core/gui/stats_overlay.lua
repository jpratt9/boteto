--[[
    Stats Overlay Module
    Creates the stats display frame that shows State | Targets | Deaths
]]

local StatsOverlay = {}

-- Create the stats overlay frame
-- @param parentFrame: the main frame to attach to
-- @return frame object with Update() function
function StatsOverlay.Create(parentFrame)
    -- Stats bar overlay (BANETO pattern - lines 71699-71733)
    local frame = CreateFrame("Frame", nil, parentFrame)
    frame:SetPoint("TOP", parentFrame, "TOP", 0, 35)
    frame:SetSize(218, 40)
    frame:SetFrameLevel(7)
    frame:EnableMouse(false)

    -- Stats bar backdrop
    frame.Backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.Backdrop:SetAllPoints()
    frame.Backdrop:SetFrameLevel(2)
    frame.Backdrop:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame.Backdrop:SetBackdropColor(0, 0, 0, 0.1)
    frame.Backdrop:EnableMouse(false)

    -- Stats text (BANETO pattern - lines 71730-71731)
    frame.statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.statsText:SetPoint("CENTER", 0, 6)
    local fontName, _, fontFlags = frame.statsText:GetFont()
    frame.statsText:SetFont(fontName, 14, fontFlags)
    frame.statsText:SetText("|cff0872B2IDLE|cffB9B9B9 | Targets: 0 | Deaths: 0")

    -- Update function
    function frame:Update(state, targets, deaths)
        if self.statsText then
            self.statsText:SetText(string.format(
                "|cff0872B2%s|cffB9B9B9 | Targets: %d | Deaths: %d",
                state or "IDLE",
                targets or 0,
                deaths or 0
            ))
        end
    end

    return frame
end

return StatsOverlay
