-- DataStore.lua - High-performance data storage with hash indexing
-- Optimized for fast lookups and minimal memory overhead

local DataStore = {}
DPSLight_DataStore = DataStore

-- Lazy load ObjectPool
local function GetObjectPool()
    return DPSLight_ObjectPool
end

-- User and ability ID caches
local userCache = {}      -- [username] = userID
local abilityCache = {}   -- [abilityname] = abilityID
local guidCache = {}      -- [GUID] = username (for SuperWoW)

local nextUserID = 1
local nextAbilityID = 1

-- Reverse lookups
local userNames = {}      -- [userID] = username
local abilityNames = {}   -- [abilityID] = abilityname

-- Main data storage: [dataType][segment][userID][abilityID][targetID] = data
local dataStore = {
    damage = {},
    damageTaken = {},
    healing = {},
    healingTaken = {},
    deaths = {},
}

-- Current segment
local currentSegment = 0  -- 0 = overall/current

-- Segment metadata: {startTime, endTime, duration, zone, boss, totalDPS, totalHPS}
local segmentMetadata = {}
local maxSegments = 20  -- Keep last 20 combats
local combatStartTime = nil
local inCombat = false

-- Get or create user ID
function DataStore:GetUserID(username)
    if not username or username == "" then return nil end
    
    local userID = userCache[username]
    if not userID then
        userID = nextUserID
        userCache[username] = userID
        userNames[userID] = username
        nextUserID = nextUserID + 1
    end
    
    return userID
end

-- Get username from ID
function DataStore:GetUsername(userID)
    return userNames[userID]
end

-- Get or create ability ID
function DataStore:GetAbilityID(abilityName)
    if not abilityName or abilityName == "" then return nil end
    
    local abilityID = abilityCache[abilityName]
    if not abilityID then
        abilityID = nextAbilityID
        abilityCache[abilityName] = abilityID
        abilityNames[abilityID] = abilityName
        nextAbilityID = nextAbilityID + 1
    end
    
    return abilityID
end

-- Get ability name from ID
function DataStore:GetAbilityName(abilityID)
    return abilityNames[abilityID]
end

-- GUID cache for SuperWoW
function DataStore:CacheGUID(guid, username)
    if guid and username then
        guidCache[guid] = username
    end
end

function DataStore:GetUsernameByGUID(guid)
    return guidCache[guid]
end

-- Add damage data
function DataStore:AddDamage(username, targetName, abilityName, amount, isCrit, damageType)
    local userID = self:GetUserID(username)
    local targetID = self:GetUserID(targetName)
    local abilityID = self:GetAbilityID(abilityName)
    
    if not userID or not abilityID then return end
    
    local segment = dataStore.damage[currentSegment]
    if not segment then
        segment = {}
        dataStore.damage[currentSegment] = segment
    end
    
    local userData = segment[userID]
    if not userData then
        userData = {}
        segment[userID] = userData
    end
    
    local abilityData = userData[abilityID]
    if not abilityData then
        abilityData = {
            total = 0,
            hits = 0,
            crits = 0,
            min = 999999,
            max = 0,
            targets = {}
        }
        userData[abilityID] = abilityData
    end
    
    -- Update aggregates
    abilityData.total = abilityData.total + amount
    abilityData.hits = abilityData.hits + 1
    if isCrit then
        abilityData.crits = abilityData.crits + 1
    end
    abilityData.min = min(abilityData.min, amount)
    abilityData.max = max(abilityData.max, amount)
    
    -- Track per-target data
    if targetID then
        local targetData = abilityData.targets[targetID]
        if not targetData then
            targetData = {total = 0, hits = 0}
            abilityData.targets[targetID] = targetData
        end
        targetData.total = targetData.total + amount
        targetData.hits = targetData.hits + 1
    end
    
    -- Update advanced stats
    local AdvancedStats = DPSLight_AdvancedStats
    if AdvancedStats then
        AdvancedStats:RecordDamage(username, amount, GetTime())
    end
    
    -- Register target in boss detector
    local BossDetector = DPSLight_BossDetector
    if BossDetector and targetName then
        BossDetector:RegisterTarget(targetName)
    end
end

-- Add healing data
function DataStore:AddHealing(username, targetName, abilityName, amount, overhealing, isCrit)
    local userID = self:GetUserID(username)
    local targetID = self:GetUserID(targetName)
    local abilityID = self:GetAbilityID(abilityName)
    
    if not userID or not abilityID then return end
    
    local segment = dataStore.healing[currentSegment]
    if not segment then
        segment = {}
        dataStore.healing[currentSegment] = segment
    end
    
    local userData = segment[userID]
    if not userData then
        userData = {}
        segment[userID] = userData
    end
    
    local abilityData = userData[abilityID]
    if not abilityData then
        abilityData = {
            total = 0,
            effective = 0,
            overhealing = 0,
            hits = 0,
            crits = 0,
            targets = {}
        }
        userData[abilityID] = abilityData
    end
    
    local effective = amount - (overhealing or 0)
    abilityData.total = abilityData.total + amount
    abilityData.effective = abilityData.effective + effective
    abilityData.overhealing = abilityData.overhealing + (overhealing or 0)
    abilityData.hits = abilityData.hits + 1
    if isCrit then
        abilityData.crits = abilityData.crits + 1
    end
    
    if targetID then
        local targetData = abilityData.targets[targetID]
        if not targetData then
            targetData = {total = 0, effective = 0, overhealing = 0}
            abilityData.targets[targetID] = targetData
        end
        targetData.total = targetData.total + amount
        targetData.effective = targetData.effective + effective
        targetData.overhealing = targetData.overhealing + (overhealing or 0)
    end
end

-- Record death
function DataStore:AddDeath(username, timestamp, killer, killerAbility)
    local userID = self:GetUserID(username)
    if not userID then return end
    
    local segment = dataStore.deaths[currentSegment]
    if not segment then
        segment = {}
        dataStore.deaths[currentSegment] = segment
    end
    
    local deathList = segment[userID]
    if not deathList then
        deathList = {}
        segment[userID] = deathList
    end
    
    table.insert(deathList, {
        timestamp = timestamp or GetTime(),
        killer = killer,
        killerAbility = killerAbility,
    })
    
    -- Also call Deaths module
    if DPSLight_Deaths and DPSLight_Deaths.AddDeath then
        DPSLight_Deaths:AddDeath(username, timestamp)
    end
end

-- Get damage data for a user
function DataStore:GetDamageData(segment, userID)
    segment = segment or currentSegment
    if not dataStore.damage[segment] then return nil end
    return dataStore.damage[segment][userID]
end

-- Get healing data for a user
function DataStore:GetHealingData(segment, userID)
    segment = segment or currentSegment
    if not dataStore.healing[segment] then return nil end
    return dataStore.healing[segment][userID]
end

-- Calculate total damage for a user
function DataStore:GetTotalDamage(segment, userID)
    local data = self:GetDamageData(segment, userID)
    if not data then return 0 end
    
    local total = 0
    for abilityID, abilityData in pairs(data) do
        total = total + abilityData.total
    end
    return total
end

-- Calculate total healing for a user
function DataStore:GetTotalHealing(segment, userID)
    local data = self:GetHealingData(segment, userID)
    if not data then return 0 end
    
    local total = 0
    for abilityID, abilityData in pairs(data) do
        total = total + abilityData.effective
    end
    return total
end

-- Get sorted damage list
function DataStore:GetSortedDamage(segment)
    segment = segment or currentSegment
    local segmentData = dataStore.damage[segment]
    if not segmentData then return {} end
    
    local ObjectPool = GetObjectPool()
    if not ObjectPool then return {} end
    local result = ObjectPool:GetTable(50)
    
    for userID, userData in pairs(segmentData) do
        local total = 0
        for abilityID, abilityData in pairs(userData) do
            total = total + abilityData.total
        end
        
        table.insert(result, {
            userID = userID,
            username = userNames[userID],
            total = total,
        })
    end
    
    table.sort(result, function(a, b) return a.total > b.total end)
    return result
end

-- Get sorted healing list
function DataStore:GetSortedHealing(segment)
    segment = segment or currentSegment
    local segmentData = dataStore.healing[segment]
    if not segmentData then return {} end
    
    local ObjectPool = GetObjectPool()
    if not ObjectPool then return {} end
    local result = ObjectPool:GetTable(50)
    
    for userID, userData in pairs(segmentData) do
        local total = 0
        for abilityID, abilityData in pairs(userData) do
            total = total + abilityData.effective
        end
        
        table.insert(result, {
            userID = userID,
            username = userNames[userID],
            total = total,
        })
    end
    
    table.sort(result, function(a, b) return a.total > b.total end)
    return result
end

-- Segment management
function DataStore:NewSegment()
    currentSegment = currentSegment + 1
    return currentSegment
end

function DataStore:GetCurrentSegment()
    return currentSegment
end

function DataStore:SetSegment(segment)
    currentSegment = segment
end

function DataStore:SetCurrentSegment(segment)
    currentSegment = segment or 0
end

-- Start new combat segment
function DataStore:StartCombat()
    if inCombat then return end
    
    inCombat = true
    combatStartTime = GetTime()
    
    -- Find next available segment ID
    local nextSegment = 1
    while segmentMetadata[nextSegment] do
        nextSegment = nextSegment + 1
    end
    
    currentSegment = nextSegment
    
    -- Initialize metadata
    segmentMetadata[currentSegment] = {
        startTime = combatStartTime,
        endTime = nil,
        duration = 0,
        zone = GetRealZoneText() or "Unknown",
        boss = nil,
        totalDPS = 0,
        totalHPS = 0,
    }
    
    DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Combat started (Segment " .. currentSegment .. ")", 0, 1, 0)
end

-- End combat segment
function DataStore:EndCombat()
    if not inCombat or not combatStartTime then return end
    
    inCombat = false
    local endTime = GetTime()
    local duration = endTime - combatStartTime
    
    if segmentMetadata[currentSegment] then
        segmentMetadata[currentSegment].endTime = endTime
        segmentMetadata[currentSegment].duration = duration
        
        -- Calculate total DPS/HPS for this segment
        local totalDmg = 0
        local totalHeal = 0
        
        if dataStore.damage[currentSegment] then
            for userID, userData in pairs(dataStore.damage[currentSegment]) do
                for abilityID, abilityData in pairs(userData) do
                    totalDmg = totalDmg + (abilityData.total or 0)
                end
            end
        end
        
        if dataStore.healing[currentSegment] then
            for userID, userData in pairs(dataStore.healing[currentSegment]) do
                for abilityID, abilityData in pairs(userData) do
                    totalHeal = totalHeal + (abilityData.total or 0)
                end
            end
        end
        
        if duration > 0 then
            segmentMetadata[currentSegment].totalDPS = totalDmg / duration
            segmentMetadata[currentSegment].totalHPS = totalHeal / duration
        end
        
        -- Detect boss name (most damaged target)
        local BossDetector = DPSLight_BossDetector
        if BossDetector then
            local bossName = BossDetector:GetCurrentBoss()
            if bossName then
                segmentMetadata[currentSegment].boss = bossName
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage(string.format("DPSLight: Combat ended - %ds, %.1f DPS, %.1f HPS", 
            duration, segmentMetadata[currentSegment].totalDPS, segmentMetadata[currentSegment].totalHPS), 0, 1, 0)
    end
    
    -- Clean old segments if too many
    local segmentCount = 0
    for _ in pairs(segmentMetadata) do
        segmentCount = segmentCount + 1
    end
    
    if segmentCount > maxSegments then
        -- Find oldest segment and remove
        local oldestSegment = nil
        local oldestTime = GetTime()
        
        for segID, meta in pairs(segmentMetadata) do
            if meta.startTime < oldestTime then
                oldestTime = meta.startTime
                oldestSegment = segID
            end
        end
        
        if oldestSegment then
            segmentMetadata[oldestSegment] = nil
            dataStore.damage[oldestSegment] = nil
            dataStore.healing[oldestSegment] = nil
            dataStore.deaths[oldestSegment] = nil
        end
    end
    
    -- Return to overall segment
    currentSegment = 0
end

-- Get segment list
function DataStore:GetSegmentList()
    local segments = {}
    
    for segID, meta in pairs(segmentMetadata) do
        table.insert(segments, {
            id = segID,
            startTime = meta.startTime,
            endTime = meta.endTime,
            duration = meta.duration,
            zone = meta.zone,
            boss = meta.boss,
            totalDPS = meta.totalDPS,
            totalHPS = meta.totalHPS,
        })
    end
    
    -- Sort by start time (newest first)
    table.sort(segments, function(a, b)
        return (a.startTime or 0) > (b.startTime or 0)
    end)
    
    return segments
end

-- Get segment metadata
function DataStore:GetSegmentMetadata(segmentID)
    return segmentMetadata[segmentID]
end

-- Check if in combat
function DataStore:IsInCombat()
    return inCombat
end

-- Clear segment data
function DataStore:ClearSegment(segment)
    segment = segment or currentSegment
    
    for dataType, segments in pairs(dataStore) do
        segments[segment] = nil
    end
end

-- Reset all data
function DataStore:Reset()
    for dataType, segments in pairs(dataStore) do
        for k in pairs(segments) do
            segments[k] = nil
        end
    end
    
    currentSegment = 1
    nextUserID = 1
    nextAbilityID = 1
    
    for k in pairs(userCache) do userCache[k] = nil end
    for k in pairs(abilityCache) do abilityCache[k] = nil end
    for k in pairs(guidCache) do guidCache[k] = nil end
    for k in pairs(userNames) do userNames[k] = nil end
    for k in pairs(abilityNames) do abilityNames[k] = nil end
end

-- Get memory usage estimate
function DataStore:GetMemoryUsage()
    local total = 0
    
    -- Count users
    local userCount = 0
    for _ in pairs(userCache) do userCount = userCount + 1 end
    
    -- Count abilities
    local abilityCount = 0
    for _ in pairs(abilityCache) do abilityCount = abilityCount + 1 end
    
    -- Estimate data size
    for dataType, segments in pairs(dataStore) do
        for segment, segmentData in pairs(segments) do
            for userID, userData in pairs(segmentData) do
                total = total + 1
                for abilityID, abilityData in pairs(userData) do
                    total = total + 1
                end
            end
        end
    end
    
    return {
        users = userCount,
        abilities = abilityCount,
        dataEntries = total,
        estimatedKB = (total * 100 + userCount * 50 + abilityCount * 50) / 1024
    }
end

return DataStore
