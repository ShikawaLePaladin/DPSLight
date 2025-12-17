-- ParserOptimized.lua - SuperWoW optimized parser using RAW_COMBATLOG
-- Uses GUIDs directly, eliminates regex parsing for massive performance gain

local ParserOptimized = {}
DPSLight_ParserOptimized = ParserOptimized

local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils

-- GUID cache for fast lookups
local guidToName = {}
local nameToGuid = {}

-- Parse GUID to extract unit type and ID
local function ParseGUID(guid)
    if not guid then return nil end
    
    -- SuperWoW GUID format: 0xF130XXXXXXXXXXXX (example)
    -- Extract creature ID, player name, etc.
    -- This is a simplified version - actual implementation depends on GUID structure
    
    return guid
end

-- Cache unit name with GUID
local function CacheUnit(guid, name)
    if guid and name then
        guidToName[guid] = name
        nameToGuid[name] = guid
        DataStore:CacheGUID(guid, name)
    end
end

-- Get unit name from GUID
local function GetNameFromGUID(guid)
    if not guid then return nil end
    
    local cached = guidToName[guid]
    if cached then return cached end
    
    -- Try to resolve from current units
    if UnitExists("target") then
        local targetGuid = UnitExists("target")
        if targetGuid == guid then
            local name = UnitName("target")
            CacheUnit(guid, name)
            return name
        end
    end
    
    -- Check raid members
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local memberGuid = UnitExists(unit)
                if memberGuid == guid then
                    local name = UnitName(unit)
                    CacheUnit(guid, name)
                    return name
                end
            end
        end
    end
    
    -- Check party members
    local numParty = GetNumPartyMembers()
    if numParty > 0 then
        for i = 1, numParty do
            local unit = "party" .. i
            if UnitExists(unit) then
                local memberGuid = UnitExists(unit)
                if memberGuid == guid then
                    local name = UnitName(unit)
                    CacheUnit(guid, name)
                    return name
                end
            end
        end
    end
    
    return nil
end
-- Parse RAW_COMBATLOG event
function ParserOptimized:ParseRawCombat(eventName, combatText)
    if not combatText then return nil end
    
    -- RAW_COMBATLOG format (SuperWoW):
    -- "GUID1,GUID2,SpellID,Amount,Flags,..."
    -- Example: "0xF1300000,0xF1300001,12345,500,..."
    
    local parts = {}
    local pos = 1
    for part in string.gfind(combatText, "([^,]+)") do
        table.insert(parts, part)
    end
    
    if table.getn(parts) < 4 then return nil end
    
    local sourceGuid = parts[1]
    local targetGuid = parts[2]
    local spellID = tonumber(parts[3])
    local amount = tonumber(parts[4])
    
    local sourceName = GetNameFromGUID(sourceGuid)
    local targetName = GetNameFromGUID(targetGuid)
    
    if not sourceName then return nil end
    
    -- Determine action type from original event name
    local result = {
        sourceGuid = sourceGuid,
        targetGuid = targetGuid,
        source = sourceName,
        target = targetName,
        spellID = spellID,
        amount = amount,
    }
    
    -- Parse event type
    if string.find(eventName, "DAMAGE") then
        result.type = "DAMAGE"
        result.ability = SpellInfo(spellID) or "Attack"
        result.isCrit = string.find(eventName, "CRIT") ~= nil
        
    elseif string.find(eventName, "HEAL") then
        result.type = "HEALING"
        result.ability = SpellInfo(spellID) or "Healing"
        result.isCrit = string.find(eventName, "CRIT") ~= nil
        
    elseif string.find(eventName, "DEATH") then
        result.type = "DEATH"
    end
    
    return result
end

-- Handle UNIT_CASTEVENT (SuperWoW)
function ParserOptimized:ParseUnitCast(casterGuid, targetGuid, eventType, spellID, duration)
    local casterName = GetNameFromGUID(casterGuid)
    local targetName = GetNameFromGUID(targetGuid)
    
    if not casterName then return nil end
    
    local spellName = SpellInfo(spellID)
    
    return {
        type = "CAST",
        eventType = eventType, -- "START", "CAST", "FAIL", "CHANNEL", etc.
        source = casterName,
        target = targetName,
        spellID = spellID,
        spell = spellName,
        duration = duration,
    }
end

-- Update GUID cache from visible units
function ParserOptimized:UpdateGUIDCache()
    -- Cache player
    local playerGuid = UnitExists("player")
    if playerGuid then
        CacheUnit(playerGuid, UnitName("player"))
    end
    
    -- Cache target
    if UnitExists("target") then
        local targetGuid = UnitExists("target")
        local targetName = UnitName("target")
        CacheUnit(targetGuid, targetName)
    end
    
    -- Cache raid
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local guid = UnitExists(unit)
                local name = UnitName(unit)
                CacheUnit(guid, name)
            end
        end
    end
    
    -- Cache party
    local numParty = GetNumPartyMembers()
    if numParty > 0 then
        for i = 1, numParty do
            local unit = "party" .. i
            if UnitExists(unit) then
                local guid = UnitExists(unit)
                local name = UnitName(unit)
                CacheUnit(guid, name)
            end
        end
    end
end

-- Initialize
function ParserOptimized:Initialize()
    self:UpdateGUIDCache()
    
    -- Update cache periodically
    local frame = CreateFrame("Frame")
    local timer = 0
    frame:SetScript("OnUpdate", function()
        timer = timer + arg1
        if timer >= 5 then
            self:UpdateGUIDCache()
            timer = 0
        end
    end)
end

-- Get statistics
function ParserOptimized:GetStats()
    local guidCount = 0
    for _ in pairs(guidToName) do
        guidCount = guidCount + 1
    end
    
    return {
        guidsCached = guidCount,
        parserType = "SuperWoW Optimized",
    }
end

return ParserOptimized
