-- AdvancedStats.lua - Track burst DPS, activity time, etc.
local AdvancedStats = {}
DPSLight_AdvancedStats = AdvancedStats

-- Lazy load
local function GetUtils() return DPSLight_Utils end

-- Storage for advanced stats
local playerStats = {}

-- Window for burst calculation (seconds)
local BURST_WINDOW = 10

-- Initialize
function AdvancedStats:Initialize()
    playerStats = {}
end

-- Record damage event for burst calculation
function AdvancedStats:RecordDamage(playerName, amount, timestamp)
    if not playerName then return end
    
    if not playerStats[playerName] then
        playerStats[playerName] = {
            damageEvents = {},
            lastActivity = 0,
            totalActiveTime = 0,
            burstDPS = 0,
        }
    end
    
    local stats = playerStats[playerName]
    
    -- Store event
    table.insert(stats.damageEvents, {
        amount = amount,
        time = timestamp or GetTime(),
    })
    
    -- Update activity time
    local now = GetTime()
    if stats.lastActivity > 0 and (now - stats.lastActivity) < 5 then
        stats.totalActiveTime = stats.totalActiveTime + (now - stats.lastActivity)
    end
    stats.lastActivity = now
    
    -- Clean old events (keep only last 30 seconds)
    while table.getn(stats.damageEvents) > 0 and 
          (now - stats.damageEvents[1].time) > 30 do
        table.remove(stats.damageEvents, 1)
    end
    
    -- Calculate burst DPS
    self:CalculateBurstDPS(playerName)
end

-- Calculate burst DPS (highest damage in X second window)
function AdvancedStats:CalculateBurstDPS(playerName)
    local stats = playerStats[playerName]
    if not stats or not stats.damageEvents then return 0 end
    
    local events = stats.damageEvents
    local eventCount = table.getn(events)
    if eventCount == 0 then return 0 end
    
    local maxDPS = 0
    
    -- Try each possible window
    for i = 1, eventCount do
        local windowStart = events[i].time
        local windowEnd = windowStart + BURST_WINDOW
        local windowDamage = 0
        
        for j = i, table.getn(events) do
            if events[j].time <= windowEnd then
                windowDamage = windowDamage + events[j].amount
            else
                break
            end
        end
        
        local dps = windowDamage / BURST_WINDOW
        if dps > maxDPS then
            maxDPS = dps
        end
    end
    
    stats.burstDPS = maxDPS
    return maxDPS
end

-- Get burst DPS
function AdvancedStats:GetBurstDPS(playerName)
    if not playerStats[playerName] then return 0 end
    return playerStats[playerName].burstDPS or 0
end

-- Get activity time percentage
function AdvancedStats:GetActivityPercent(playerName, totalDuration)
    if not playerStats[playerName] or totalDuration == 0 then return 0 end
    
    local activeTime = playerStats[playerName].totalActiveTime or 0
    return (activeTime / totalDuration) * 100
end

-- Get activity time
function AdvancedStats:GetActivityTime(playerName)
    if not playerStats[playerName] then return 0 end
    return playerStats[playerName].totalActiveTime or 0
end

-- Reset stats
function AdvancedStats:Reset()
    playerStats = {}
end

-- Reset player stats
function AdvancedStats:ResetPlayer(playerName)
    playerStats[playerName] = nil
end

return AdvancedStats
