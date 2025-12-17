-- Modules/Deaths.lua - Death tracking module

local Deaths = {}
DPSLight_Deaths = Deaths

local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils
local ClassIcons = DPSLight_ClassIcons

-- Death data structure: {username: {count, times: {timestamp}}}
local deathData = {}

-- Add death
function Deaths:AddDeath(username, timestamp)
    if not username then return end
    
    if not deathData[username] then
        deathData[username] = {
            count = 0,
            times = {}
        }
    end
    
    deathData[username].count = deathData[username].count + 1
    table.insert(deathData[username].times, timestamp or time())
end

-- Get sorted data
function Deaths:GetSortedData(segment)
    segment = segment or 0  -- 0 = overall
    
    local sorted = {}
    for username, data in pairs(deathData) do
        local classID = ClassIcons:GetUserClass(username)
        
        table.insert(sorted, {
            username = username,
            total = data.count,
            userID = username,  -- Use username as userID
            class = classID
        })
    end
    
    -- Sort by deaths (descending)
    table.sort(sorted, function(a, b)
        return (a.total or 0) > (b.total or 0)
    end)
    
    return sorted
end

-- Get total deaths
function Deaths:GetTotal(segment, userID)
    segment = segment or 0
    if not userID then return 0 end
    
    -- userID is actually username
    if deathData[userID] then
        return deathData[userID].count or 0
    end
    return 0
end

-- Get percent (always 100% for deaths)
function Deaths:GetPercent(segment, userID)
    return 100
end

-- Get death times
function Deaths:GetDeathTimes(segment, userID)
    segment = segment or 0
    if not userID then return {} end
    
    -- userID is actually username
    if deathData[userID] then
        return deathData[userID].times or {}
    end
    return {}
end

-- Get tooltip data
function Deaths:GetTooltipData(segment, userID)
    segment = segment or 0
    if not userID then return {} end
    
    local times = self:GetDeathTimes(segment, userID)
    local tooltipData = {}
    
    for i, timestamp in ipairs(times) do
        local timeStr = date("%H:%M:%S", timestamp)
        table.insert(tooltipData, {
            text = "Death " .. i .. ": " .. timeStr,
            value = ""
        })
    end
    
    return tooltipData
end

-- Clear all data
function Deaths:Clear()
    deathData = {}
end

return Deaths
