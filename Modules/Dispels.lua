-- Modules/Dispels.lua - Dispel tracking module
local Dispels = {}
DPSLight_Dispels = Dispels

local ModuleBase = DPSLight_ModuleBase
local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils

-- Inherit from ModuleBase
setmetatable(Dispels, {__index = ModuleBase})

-- Initialize module
function Dispels:Initialize()
    self.name = "dispels"
    self.dataType = "dispels"
    self.cache = {}
    self.cacheTime = 0
    self.cacheDuration = 0.5
end

-- Custom data structure for dispels (count based, not damage)
local dispelData = {}

-- Add dispel
function Dispels:AddDispel(username, targetName, spellName)
    if not dispelData[username] then
        dispelData[username] = {
            total = 0,
            spells = {}
        }
    end
    
    dispelData[username].total = dispelData[username].total + 1
    
    if not dispelData[username].spells[spellName] then
        dispelData[username].spells[spellName] = 0
    end
    
    dispelData[username].spells[spellName] = dispelData[username].spells[spellName] + 1
end

-- Get sorted data
function Dispels:GetSortedData(segment)
    local sorted = {}
    
    for username, data in pairs(dispelData) do
        local userID = DataStore:GetUserID(username)
        table.insert(sorted, {
            username = username,
            total = data.total,
            userID = userID
        })
    end
    
    table.sort(sorted, function(a, b) return a.total > b.total end)
    
    return sorted
end

-- Get total dispels
function Dispels:GetTotal(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username or not dispelData[username] then return 0 end
    
    return dispelData[username].total
end

-- Get percent
function Dispels:GetPercent(segment, userID)
    local total = self:GetTotal(segment, userID)
    local max = 0
    
    for _, data in pairs(dispelData) do
        if data.total > max then
            max = data.total
        end
    end
    
    if max == 0 then return 0 end
    return (total / max) * 100
end

-- Get spell breakdown
function Dispels:GetSpellBreakdown(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username or not dispelData[username] then return {} end
    
    local spells = {}
    local total = dispelData[username].total
    
    for spellName, count in pairs(dispelData[username].spells) do
        table.insert(spells, {
            name = spellName,
            total = count,
            percent = (count / total) * 100
        })
    end
    
    table.sort(spells, function(a, b) return a.total > b.total end)
    
    return spells
end

-- Get tooltip data
function Dispels:GetTooltipData(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username then return nil end
    
    local total = self:GetTotal(segment, userID)
    local spells = self:GetSpellBreakdown(segment, userID)
    
    local details = {}
    table.insert(details, string.format("Total Dispels: %d", total))
    
    if table.getn(spells) > 0 then
        table.insert(details, string.format("Top: %s (%d)", spells[1].name, spells[1].total))
    end
    
    return {
        name = username,
        details = details
    }
end

-- Reset
function Dispels:Reset()
    dispelData = {}
end

return Dispels
