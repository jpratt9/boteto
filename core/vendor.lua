--[[
    Vendor Module
    Handles auto-selling items with BANETO's blacklist system
]]

local Vendor = {}

-- ============================================
-- CONFIGURATION
-- ============================================

Vendor.AUTO_SELL_GRAY = true  -- Toggle for auto-selling gray items
Vendor.SELL_DELAY = 0.2  -- Delay between sells (seconds)
Vendor.lastSellTime = 0

-- User-configurable "Never Sell" blacklist
Vendor.NEVER_SELL = {
    6948,  -- Hearthstone
}

-- ============================================
-- MERCHANT WINDOW DETECTION
-- ============================================

-- Check if merchant window is open
-- @return boolean - true if merchant window is visible
function Vendor.IsMerchantOpen()
    if MerchantFrame then
        return MerchantFrame:IsVisible()
    end
    return false
end

-- ============================================
-- BLACKLIST SYSTEM (BANETO PATTERN)
-- ============================================

-- Check if item is blacklisted from selling (BANETO pattern - line 29088-29240)
-- @param itemID: number - item ID to check
-- @return boolean - true if item should NOT be sold
function Vendor.IsItemBlacklisted(itemID)
    if not itemID then
        return true
    end

    -- Check user "Never Sell" list
    for _, id in ipairs(Vendor.NEVER_SELL) do
        if id == itemID then
            return true
        end
    end

    -- Get item info
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType,
          itemStackCount, itemEquipLoc, itemIcon, itemSellPrice = GetItemInfo(itemID)

    if not itemName then
        return true  -- Unknown item, don't sell
    end

    -- BANETO pattern: Check item type for blacklisted categories

    -- Quest items (BANETO line 29095)
    if itemType == "Quest" or itemType == "Quest Item" then
        return true
    end

    -- Hearthstone (BANETO line 29098)
    if itemID == 6948 then
        return true
    end

    -- Conjured items (BANETO line 29100)
    if itemName and string.find(itemName, "Conjured") then
        return true
    end

    -- Enchanting materials (BANETO line 29115-29130)
    if itemType == "Trade Goods" and itemSubType == "Enchanting" then
        return true
    end

    -- Check for specific enchanting item patterns
    local enchantingKeywords = {"Dust", "Essence", "Shard", "Crystal", "Nexus"}
    for _, keyword in ipairs(enchantingKeywords) do
        if itemName and string.find(itemName, keyword) then
            return true
        end
    end

    -- Food and drink (BANETO line 29132)
    if itemType == "Consumable" and (itemSubType == "Food & Drink" or itemSubType == "Food" or itemSubType == "Drink") then
        return true
    end

    -- Bandages (BANETO line 29135)
    if itemSubType == "Bandage" or (itemName and string.find(itemName, "Bandage")) then
        return true
    end

    -- Arrows and bullets (BANETO line 29137)
    if itemType == "Projectile" or itemSubType == "Arrow" or itemSubType == "Bullet" then
        return true
    end

    -- Poisons (BANETO line 29139)
    if itemType == "Consumable" and itemSubType == "Poison" then
        return true
    end

    -- Soulbound items (BANETO line 29141)
    -- Check tooltip for "Soulbound" text
    if itemLink then
        -- Use tooltip to check for soulbound
        local tooltipData = C_TooltipInfo and C_TooltipInfo.GetHyperlink(itemLink)
        if tooltipData and tooltipData.lines then
            for _, line in ipairs(tooltipData.lines) do
                if line.leftText and string.find(line.leftText, "Soulbound") then
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================
-- SELLING FUNCTIONS
-- ============================================

-- Sell all gray items in bags (BANETO pattern - line 30678-30719)
-- @return boolean - true if selling was attempted
function Vendor.SellGrayItems()
    if not Vendor.IsMerchantOpen() then
        print("[Vendor] Merchant window not open!")
        return false
    end

    if not Vendor.AUTO_SELL_GRAY then
        print("[Vendor] Auto-sell grays is disabled")
        return false
    end

    local soldCount = 0
    local moneyBefore = GetMoney()

    print("[Vendor] Selling gray items...")

    -- Iterate through all bags (0-4 in Classic)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)

        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                -- Get item ID
                local itemID = C_Container and C_Container.GetContainerItemID(bag, slot)
                             or GetContainerItemID(bag, slot)

                if itemID then
                    -- Get item quality
                    local _, _, _, quality = GetContainerItemInfo(bag, slot)

                    -- Check if item is gray (quality 0) and not blacklisted
                    if quality == 0 and not Vendor.IsItemBlacklisted(itemID) then
                        -- Sell the item
                        if C_Container and C_Container.UseContainerItem then
                            C_Container.UseContainerItem(bag, slot)
                        else
                            UseContainerItem(bag, slot)
                        end

                        soldCount = soldCount + 1
                        Vendor.lastSellTime = GetTime()
                    end
                end
            end
        end
    end

    -- Calculate and display profit
    if soldCount > 0 then
        -- Wait a moment for transactions to complete
        C_Timer.After(1.0, function()
            local moneyAfter = GetMoney()
            local profit = moneyAfter - moneyBefore
            local gold = math.floor(profit / 10000)
            local silver = math.floor((profit % 10000) / 100)
            local copper = profit % 100

            print(string.format("[Vendor] Sold %d items for %dg %ds %dc",
                soldCount, gold, silver, copper))
        end)
    else
        print("[Vendor] No gray items to sell")
    end

    return true
end

-- ============================================
-- BLACKLIST MANAGEMENT
-- ============================================

-- Add item to "Never Sell" blacklist
-- @param itemID: number - item ID to add
function Vendor.AddToBlacklist(itemID)
    table.insert(Vendor.NEVER_SELL, itemID)
    print("[Vendor] Added item " .. itemID .. " to blacklist")
end

-- Remove item from "Never Sell" blacklist
-- @param itemID: number - item ID to remove
-- @return boolean - true if item was removed
function Vendor.RemoveFromBlacklist(itemID)
    for i, id in ipairs(Vendor.NEVER_SELL) do
        if id == itemID then
            table.remove(Vendor.NEVER_SELL, i)
            print("[Vendor] Removed item " .. itemID .. " from blacklist")
            return true
        end
    end
    print("[Vendor] Item " .. itemID .. " not found in blacklist")
    return false
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Print vendor status (debugging)
function Vendor.PrintStatus()
    print("=== Vendor Status ===")
    print("Merchant Open: " .. tostring(Vendor.IsMerchantOpen()))
    print("Auto-Sell Gray: " .. tostring(Vendor.AUTO_SELL_GRAY))
    print("Blacklist Size: " .. #Vendor.NEVER_SELL)

    local money = GetMoney()
    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100
    print(string.format("Current Money: %dg %ds %dc", gold, silver, copper))
    print("====================")
end

return Vendor
