-- Modules/Decurse.lua - Decurse tracking module
local Decurse = {}
DPSLight_Decurse = Decurse

local ModuleBase = DPSLight_ModuleBase
local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils

-- Inherit from ModuleBase
setmetatable(Decurse, {__index = ModuleBase})

-- Initialize module
function Decurse:Initialize()
    self.name = "decurse"
    self.dataType = "decurse"
    self.cache = {}
    self.cacheTime = 0
    self.cacheDuration = 0.5
end

-- Custom data structure for decurse (count based)
local decurseData = {}

-- Add decurse
function Decurse:AddDecurse(username, targetName, curseType)
    if not decurseData[username] then
        decurseData[username] = {
            total = 0,
            types = {}
        }
    end
    
    decurseData[username].total = decurseData[username].total + 1
    
    if not decurseData[username].types[curseType] then
        decurseData[username].types[curseType] = 0
    end
    
    decurseData[username].types[curseType] = decurseData[username].types[curseType] + 1
end

-- Get sorted data
function Decurse:GetSortedData(segment)
    local sorted = {}
    
    for username, data in pairs(decurseData) do
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

-- Get total decurses
function Decurse:GetTotal(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username or not decurseData[username] then return 0 end
    
    return decurseData[username].total
end

-- Get percent
function Decurse:GetPercent(segment, userID)
    local total = self:GetTotal(segment, userID)
    local max = 0
    
    for _, data in pairs(decurseData) do
        if data.total > max then
            max = data.total
        end
    end
    
    if max == 0 then return 0 end
    return (total / max) * 100
end

-- Get type breakdown
function Decurse:GetTypeBreakdown(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username or not decurseData[username] then return {} end
    
    local types = {}
    local total = decurseData[username].total
    
    for typeName, count in pairs(decurseData[username].types) do
        table.insert(types, {
            name = typeName,
            total = count,
            percent = (count / total) * 100
        })
    end
    
    table.sort(types, function(a, b) return a.total > b.total end)
    
    return types
end

-- Get tooltip data
function Decurse:GetTooltipData(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username then return nil end
    
    local total = self:GetTotal(segment, userID)
    local types = self:GetTypeBreakdown(segment, userID)
    
    local details = {}
    table.insert(details, string.format("Total: %d", total))
    
    if table.getn(types) > 0 then
        table.insert(details, string.format("Top: %s (%d)", types[1].name, types[1].total))
    end
    
    return {
        name = username,
        details = details
    }
end

-- Reset
function Decurse:Reset()
    decurseData = {}
end

return Decurse
