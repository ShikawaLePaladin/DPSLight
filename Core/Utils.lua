-- Utils.lua - Utility functions

local Utils = {}
DPSLight_Utils = Utils

-- Number formatting
function Utils:FormatNumber(num, format)
    if not num then return "0" end
    
    format = format or "short"
    
    if format == "short" then
        if num >= 1000000 then
            return string.format("%.1fM", num / 1000000)
        elseif num >= 1000 then
            return string.format("%.1fk", num / 1000)
        else
            return string.format("%d", num)
        end
    else
        -- Full format with commas
        local formatted = tostring(num)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then break end
        end
        return formatted
    end
end

-- Time formatting
function Utils:FormatTime(seconds)
    if not seconds or seconds < 0 then return "0:00" end
    
    local hours = math.floor(seconds / 3600)
    local mins = math.floor(mod(seconds, 3600) / 60)
    local secs = math.floor(mod(seconds, 60))
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%d:%02d", mins, secs)
    end
end

-- Calculate DPS/HPS
function Utils:CalculatePerSecond(total, duration)
    if not duration or duration <= 0 then return 0 end
    return total / duration
end

-- Get class color
local CLASS_COLORS = {
    WARRIOR = {r = 0.78, g = 0.61, b = 0.43},
    ROGUE = {r = 1.0, g = 0.96, b = 0.41},
    HUNTER = {r = 0.67, g = 0.83, b = 0.45},
    PALADIN = {r = 0.96, g = 0.55, b = 0.73},
    PRIEST = {r = 1.0, g = 1.0, b = 1.0},
    SHAMAN = {r = 0.0, g = 0.44, b = 0.87},
    MAGE = {r = 0.41, g = 0.8, b = 0.94},
    WARLOCK = {r = 0.58, g = 0.51, b = 0.79},
    DRUID = {r = 1.0, g = 0.49, b = 0.04},
}

-- Class cache to avoid UnitName errors
local classCache = {}
local lastCacheScan = 0

-- Scan and cache player classes (NO UnitName errors)
local function UpdateClassCache()
    local now = GetTime()
    if now - lastCacheScan < 3 then return end
    lastCacheScan = now
    
    -- Clear old cache
    classCache = {}
    
    -- Cache player (always safe)
    local playerName = UnitName("player")
    if playerName then
        local _, class = UnitClass("player")
        if class then 
            classCache[playerName] = class 
        end
    end
    
    -- Cache raid members
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unitID = "raid" .. i
            if UnitExists(unitID) then
                local name = UnitName(unitID)
                if name then
                    local _, class = UnitClass(unitID)
                    if class then
                        classCache[name] = class
                    end
                end
            end
        end
    else
        -- Cache party members
        local numParty = GetNumPartyMembers()
        if numParty > 0 then
            for i = 1, numParty do
                local unitID = "party" .. i
                if UnitExists(unitID) then
                    local name = UnitName(unitID)
                    if name then
                        local _, class = UnitClass(unitID)
                        if class then
                            classCache[name] = class
                        end
                    end
                end
            end
        end
    end
end

function Utils:GetClassColor(class)
    class = string.upper(class or "")
    return CLASS_COLORS[class] or {r = 0.5, g = 0.5, b = 0.5}
end

-- Get class from player name (uses cache only, NO errors)
function Utils:GetUnitClass(playerName)
    if not playerName then return "WARRIOR" end
    
    -- Update cache if needed
    UpdateClassCache()
    
    -- Return cached class or default
    return classCache[playerName] or "WARRIOR"
end

-- Force cache update (call when raid/party changes)
function Utils:UpdateClassCache()
    lastCacheScan = 0
    UpdateClassCache()
end

-- Get cached class count (for debugging)
function Utils:GetCachedClassCount()
    local count = 0
    for _ in pairs(classCache) do
        count = count + 1
    end
    return count
end

-- Deep copy table
function Utils:DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in pairs(original) do
            copy[key] = self:DeepCopy(value)
        end
    else
        copy = original
    end
    return copy
end

-- Table contains value
function Utils:TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

-- Get table size
function Utils:TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Clamp value between min and max
function Utils:Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Round number
function Utils:Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Get player name (without server)
function Utils:GetPlayerName(fullName)
    if not fullName then return nil end
    return string.match(fullName, "([^-]+)") or fullName
end

-- Color text
function Utils:ColorText(text, r, g, b)
    r = math.floor((r or 1) * 255)
    g = math.floor((g or 1) * 255)
    b = math.floor((b or 1) * 255)
    return string.format("|cff%02x%02x%02x%s|r", r, g, b, text)
end

-- Print message with addon prefix
function Utils:Print(msg, r, g, b)
    local color = {r = r or 0, g = g or 1, b = b or 0.5}
    local prefix = self:ColorText("[DPSLight]", color.r, color.g, color.b)
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. " " .. msg)
end

-- Debug print (only if debug enabled)
function Utils:Debug(msg)
    if DPSLightSettings and DPSLightSettings.debug then
        self:Print("[DEBUG] " .. msg, 1, 1, 0)
    end
end

-- Get current timestamp
function Utils:GetTimestamp()
    return time()
end

-- Get combat time
local combatStartTime = nil

function Utils:StartCombatTimer()
    combatStartTime = GetTime()
end

function Utils:GetCombatDuration()
    if not combatStartTime then return 0 end
    return GetTime() - combatStartTime
end

function Utils:EndCombatTimer()
    local duration = self:GetCombatDuration()
    combatStartTime = nil
    return duration
end

function Utils:IsInCombat()
    return combatStartTime ~= nil
end

-- Validate unit name
function Utils:IsValidUnitName(name)
    if not name or name == "" then return false end
    if string.match(name, "^Unknown") then return false end
    if string.match(name, "^%d") then return false end
    return true
end

return Utils
