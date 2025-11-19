--[[
    Looting Module
    Handles corpse looting and skinning
]]

local Looting = {}

-- ============================================
-- CONFIGURATION
-- ============================================

Looting.LOOT_RANGE = 5.0  -- Maximum distance to loot (yards)
Looting.SKIN_RANGE = 5.5  -- Maximum distance to skin (yards)
Looting.SKIN_DELAY = 0.5  -- Delay before skinning (seconds)
Looting.LOOT_DELAY = 0.3  -- Delay between loot actions (seconds)

-- GUID tracking for skinned corpses
Looting.skinnedCorpses = {}
Looting.lastLootTime = 0
Looting.lastSkinTime = 0

-- ============================================
-- BAG SPACE CHECKING
-- ============================================

-- Get number of free bag slots
-- @return number - count of free bag slots
function Looting.GetFreeBagSlots()
    local freeSlots = 0

    -- Iterate through bags (0-4 in Classic)
    -- Bag 0 is backpack, 1-4 are equipped bags
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots and GetContainerNumSlots(bag)

        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local itemInfo = GetContainerItemInfo and GetContainerItemInfo(bag, slot)
                if not itemInfo then
                    freeSlots = freeSlots + 1
                end
            end
        end
    end

    return freeSlots
end

-- Check if bags have free space
-- @param minSlots: number - minimum required free slots (default 1)
-- @return boolean - true if enough space available
function Looting.HasBagSpace(minSlots)
    minSlots = minSlots or 1
    return Looting.GetFreeBagSlots() >= minSlots
end

-- ============================================
-- CORPSE DETECTION
-- ============================================

-- Get nearby lootable corpses
-- @param maxDistance: number - maximum distance to search (default LOOT_RANGE)
-- @return table - list of {obj, distance, guid} sorted by distance
function Looting.GetLootableCorpses(maxDistance)
    maxDistance = maxDistance or Looting.LOOT_RANGE
    local corpses = {}

    -- Get player position
    local player = Looting.GetPlayer()
    if not player then return corpses end

    local px, py, pz = ObjectPosition(player)
    local objs = Objects()

    for _, obj in pairs(objs) do
        local objType = ObjectType(obj)

        -- Type 5 is corpse in WoW object types
        if objType == 5 then
            -- Check if can be looted and not tap-denied (BANETO pattern line 17881)
            local canLoot = UnitCanBeLooted and UnitCanBeLooted(obj)
            local isTapDenied = UnitIsTapDenied and UnitIsTapDenied(obj)

            if canLoot and not isTapDenied then
                local ox, oy, oz = ObjectPosition(obj)
                local dist = math.sqrt((px-ox)^2 + (py-oy)^2 + (pz-oz)^2)

                if dist <= maxDistance then
                    local guid = UnitGUID and UnitGUID(obj) or tostring(obj)
                    table.insert(corpses, {
                        obj = obj,
                        distance = dist,
                        guid = guid
                    })
                end
            end
        end
    end

    -- Sort by distance
    table.sort(corpses, function(a, b) return a.distance < b.distance end)
    return corpses
end

-- Get nearby skinnable corpses
-- @param maxDistance: number - maximum distance to search (default SKIN_RANGE)
-- @return table - list of {obj, distance, guid} sorted by distance
function Looting.GetSkinnableCorpses(maxDistance)
    maxDistance = maxDistance or Looting.SKIN_RANGE
    local corpses = {}

    -- Get player position
    local player = Looting.GetPlayer()
    if not player then return corpses end

    local px, py, pz = ObjectPosition(player)
    local objs = Objects()

    for _, obj in pairs(objs) do
        local objType = ObjectType(obj)

        -- Type 5 is corpse
        if objType == 5 then
            -- Check if can be skinned (UnitCanBeSkinned API)
            local canSkin = UnitCanBeSkinned and UnitCanBeSkinned(obj)

            if canSkin then
                local guid = UnitGUID and UnitGUID(obj) or tostring(obj)

                -- Skip if already skinned
                if not Looting.HasBeenSkinned(guid) then
                    local ox, oy, oz = ObjectPosition(obj)
                    local dist = math.sqrt((px-ox)^2 + (py-oy)^2 + (pz-oz)^2)

                    if dist <= maxDistance then
                        table.insert(corpses, {
                            obj = obj,
                            distance = dist,
                            guid = guid
                        })
                    end
                end
            end
        end
    end

    -- Sort by distance
    table.sort(corpses, function(a, b) return a.distance < b.distance end)
    return corpses
end

-- ============================================
-- LOOTING EXECUTION
-- ============================================

-- Check if loot window is open
-- @return boolean - true if loot window is open
function Looting.IsLootWindowOpen()
    -- Check if loot frame exists and is shown
    if LootFrame then
        return LootFrame:IsShown()
    end
    return false
end

-- Close loot window
function Looting.CloseLootWindow()
    if Looting.IsLootWindowOpen() then
        CloseLoot()
    end
end

-- Loot a corpse
-- @param unit: object - unit to loot
-- @return boolean - true if loot was attempted
function Looting.LootCorpse(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    -- Check loot delay
    if GetTime() < Looting.lastLootTime + Looting.LOOT_DELAY then
        return false
    end

    -- Check if unit can be looted
    local canLoot = UnitCanBeLooted and UnitCanBeLooted(unit)
    if not canLoot then
        return false
    end

    -- Interact with corpse to open loot window
    local success = pcall(InteractUnit, unit)

    if success then
        Looting.lastLootTime = GetTime()
        print("[Looting] Looted corpse")
        return true
    end

    return false
end

-- ============================================
-- SKINNING SYSTEM
-- ============================================

-- Check if corpse has been skinned (GUID tracking)
-- @param guid: string - GUID of corpse
-- @return boolean - true if already skinned
function Looting.HasBeenSkinned(guid)
    return Looting.skinnedCorpses[guid] ~= nil
end

-- Mark corpse as skinned
-- @param guid: string - GUID of corpse
function Looting.MarkAsSkinned(guid)
    Looting.skinnedCorpses[guid] = GetTime()

    -- Clean up old entries (older than 5 minutes)
    local cutoffTime = GetTime() - 300
    for g, time in pairs(Looting.skinnedCorpses) do
        if time < cutoffTime then
            Looting.skinnedCorpses[g] = nil
        end
    end
end

-- Check if player has skinning skill
-- @return boolean - true if player can skin
function Looting.CanPlayerSkin()
    -- Check if player knows Skinning spell (spell ID 8613 for Skinning in Classic)
    if IsPlayerSpell then
        return IsPlayerSpell(8613) or IsPlayerSpell(8617) or IsPlayerSpell(8618) or IsPlayerSpell(10768)
    end

    -- Fallback: check spell book
    local spellName = GetSpellInfo and GetSpellInfo(8613)
    if spellName then
        return true
    end

    return false
end

-- Skin a corpse
-- @param unit: object - unit to skin
-- @return boolean - true if skinning was attempted
function Looting.SkinCorpse(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    -- Check if player can skin
    if not Looting.CanPlayerSkin() then
        return false
    end

    -- Check skin delay
    if GetTime() < Looting.lastSkinTime + Looting.SKIN_DELAY then
        return false
    end

    -- Check if unit can be skinned
    local canSkin = UnitCanBeSkinned and UnitCanBeSkinned(unit)
    if not canSkin then
        return false
    end

    -- Get GUID
    local guid = UnitGUID and UnitGUID(unit) or tostring(unit)

    -- Check if already skinned
    if Looting.HasBeenSkinned(guid) then
        return false
    end

    -- Cast skinning on corpse
    local success = pcall(CastSpellByName, "Skinning")

    if success then
        -- Target the corpse
        TargetUnit(unit)

        -- Mark as skinned
        Looting.MarkAsSkinned(guid)
        Looting.lastSkinTime = GetTime()

        print("[Looting] Skinned corpse (GUID: " .. guid .. ")")
        return true
    end

    return false
end

-- ============================================
-- MAIN LOOTING LOOP
-- ============================================

-- Execute looting logic (called every frame)
function Looting.ExecuteLooting()
    -- First, try to loot nearby corpses
    local lootableCorpses = Looting.GetLootableCorpses()

    if #lootableCorpses > 0 then
        -- Check if we have bag space before trying to loot
        if not Looting.HasBagSpace(1) then
            print("[Looting] No bag space available, skipping loot")
            return
        end

        -- Enter looting state
        if StateMachine and StateMachine.SetState and StateMachine.STATES then
            if not StateMachine.IsState(StateMachine.STATES.LOOTING) then
                StateMachine.SetState(StateMachine.STATES.LOOTING)
            end
        end

        -- Get closest corpse
        local corpse = lootableCorpses[1]
        local cx, cy, cz = ObjectPosition(corpse.obj)

        if cx then
            -- Check if player is within 3.5 yards of corpse (BANETO pattern - line 11896)
            if not Movement.PlayerPosition(cx, cy, cz, 3.5) then
                -- Not in range, move to corpse
                Movement.MeshTo(cx, cy, cz)
            else
                -- In range, loot if window not visible
                if not Looting.IsLootWindowOpen() then
                    Looting.LootCorpse(corpse.obj)
                end
            end
        end
        return
    end

    -- If no loot, try skinning (if player has skinning)
    if Looting.CanPlayerSkin() then
        local skinnableCorpses = Looting.GetSkinnableCorpses()

        if #skinnableCorpses > 0 then
            -- Check if we have bag space before trying to skin
            if not Looting.HasBagSpace(1) then
                print("[Looting] No bag space available, skipping skinning")
                return
            end

            -- Enter looting state
            if StateMachine and StateMachine.SetState and StateMachine.STATES then
                if not StateMachine.IsState(StateMachine.STATES.LOOTING) then
                    StateMachine.SetState(StateMachine.STATES.LOOTING)
                end
            end

            -- Get closest skinnable corpse
            local corpse = skinnableCorpses[1]
            local cx, cy, cz = ObjectPosition(corpse.obj)

            if cx then
                -- Check if player is within 3.5 yards of corpse (BANETO pattern)
                if not Movement.PlayerPosition(cx, cy, cz, 3.5) then
                    -- Not in range, move to corpse
                    Movement.MeshTo(cx, cy, cz)
                else
                    -- In range, skin the corpse
                    Looting.SkinCorpse(corpse.obj)
                end
            end
            return
        end
    end

    -- No looting to do, close loot window if open
    if Looting.IsLootWindowOpen() then
        Looting.CloseLootWindow()
    end
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get player object
-- @return object - player object or nil
function Looting.GetPlayer()
    local objs = Objects()
    for _, obj in pairs(objs) do
        if ObjectType(obj) == 7 then
            return obj
        end
    end
    return nil
end

-- Print looting status (debugging)
function Looting.PrintLootingStatus()
    print("=== Looting Status ===")
    print("Free Bag Slots: " .. Looting.GetFreeBagSlots())
    print("Can Player Skin: " .. tostring(Looting.CanPlayerSkin()))

    local lootable = Looting.GetLootableCorpses()
    print("Lootable Corpses: " .. #lootable)

    if Looting.CanPlayerSkin() then
        local skinnable = Looting.GetSkinnableCorpses()
        print("Skinnable Corpses: " .. #skinnable)
        print("Skinned Corpses Tracked: " .. Looting.CountSkinnedCorpses())
    end

    print("Loot Window Open: " .. tostring(Looting.IsLootWindowOpen()))
    print("======================")
end

-- Count tracked skinned corpses
-- @return number - count of tracked skinned corpses
function Looting.CountSkinnedCorpses()
    local count = 0
    for _ in pairs(Looting.skinnedCorpses) do
        count = count + 1
    end
    return count
end

return Looting
