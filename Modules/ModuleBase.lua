-- ModuleBase.lua - Base module template with caching

local ModuleBase = {}
DPSLight_ModuleBase = ModuleBase

local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils
local ObjectPool = DPSLight_ObjectPool

-- Create new module
function ModuleBase:New(name, dataType)
    local module = {
        name = name,
        dataType = dataType,
        cache = {},
        cacheTime = 0,
        cacheDuration = 0.5, -- Cache for 0.5 seconds
    }
    
    setmetatable(module, {__index = self})
    return module
end

-- Get sorted data with caching
function ModuleBase:GetSortedData(segment, forceRefresh)
    segment = segment or DataStore:GetCurrentSegment()
    
    local now = GetTime()
    local cacheKey = "segment_" .. segment
    
    -- Return cached data if still valid
    if not forceRefresh and self.cache[cacheKey] and (now - self.cacheTime) < self.cacheDuration then
        return self.cache[cacheKey]
    end
    
    -- Fetch fresh data
    local data
    if self.dataType == "damage" then
        data = DataStore:GetSortedDamage(segment)
    elseif self.dataType == "healing" then
        data = DataStore:GetSortedHealing(segment)
    end
    
    -- Cache the result
    self.cache[cacheKey] = data
    self.cacheTime = now
    
    return data
end

-- Get detailed data for a specific user
function ModuleBase:GetUserDetail(segment, userID)
    segment = segment or DataStore:GetCurrentSegment()
    
    if self.dataType == "damage" then
        return DataStore:GetDamageData(segment, userID)
    elseif self.dataType == "healing" then
        return DataStore:GetHealingData(segment, userID)
    end
    
    return nil
end

-- Calculate totals
function ModuleBase:GetTotal(segment, userID)
    segment = segment or DataStore:GetCurrentSegment()
    
    if self.dataType == "damage" then
        return DataStore:GetTotalDamage(segment, userID)
    elseif self.dataType == "healing" then
        return DataStore:GetTotalHealing(segment, userID)
    end
    
    return 0
end

-- Get rank of a user
function ModuleBase:GetRank(segment, userID)
    local data = self:GetSortedData(segment)
    if not data then return 0 end
    
    for i, entry in ipairs(data) do
        if entry.userID == userID then
            return i
        end
    end
    
    return 0
end

-- Get percentage of total
function ModuleBase:GetPercent(segment, userID)
    local data = self:GetSortedData(segment)
    if not data or table.getn(data) == 0 then return 0 end
    
    local userTotal = self:GetTotal(segment, userID)
    local grandTotal = 0
    
    for _, entry in ipairs(data) do
        grandTotal = grandTotal + entry.total
    end
    
    if grandTotal == 0 then return 0 end
    return (userTotal / grandTotal) * 100
end

-- Clear cache
function ModuleBase:ClearCache()
    for k in pairs(self.cache) do
        self.cache[k] = nil
    end
    self.cacheTime = 0
end

-- Format display text
function ModuleBase:FormatValue(value, showDPS, duration)
    if showDPS and duration and duration > 0 then
        local perSecond = value / duration
        return Utils:FormatNumber(perSecond) .. "/s"
    else
        return Utils:FormatNumber(value)
    end
end

-- Get bar color based on class or rank
function ModuleBase:GetBarColor(rank, class)
    if class then
        return Utils:GetClassColor(class)
    end
    
    -- Default gradient from green to red based on rank
    if rank == 1 then
        return {r = 0, g = 1, b = 0.2}
    elseif rank <= 3 then
        return {r = 0.2, g = 0.8, b = 0.2}
    elseif rank <= 10 then
        return {r = 0.5, g = 0.7, b = 0.3}
    else
        return {r = 0.6, g = 0.6, b = 0.6}
    end
end

return ModuleBase
