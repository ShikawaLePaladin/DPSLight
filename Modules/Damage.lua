-- Modules/Damage.lua - Damage module

local Damage = {}
DPSLight_Damage = Damage

local ModuleBase = DPSLight_ModuleBase
local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils

-- Inherit from ModuleBase
setmetatable(Damage, {__index = ModuleBase})

-- Initialize module
function Damage:Initialize()
    self.name = "damage"
    self.dataType = "damage"
    self.cache = {}
    self.cacheTime = 0
    self.cacheDuration = 0.5
end

-- Get ability breakdown for a user
function Damage:GetAbilityBreakdown(segment, userID)
    local userData = self:GetUserDetail(segment, userID)
    if not userData then return {} end
    
    local abilities = {}
    
    for abilityID, abilityData in pairs(userData) do
        local abilityName = DataStore:GetAbilityName(abilityID)
        
        table.insert(abilities, {
            name = abilityName,
            total = abilityData.total,
            hits = abilityData.hits,
            crits = abilityData.crits,
            min = abilityData.min,
            max = abilityData.max,
            avg = abilityData.total / abilityData.hits,
            critPercent = (abilityData.crits / abilityData.hits) * 100,
        })
    end
    
    -- Sort by total damage
    table.sort(abilities, function(a, b) return a.total > b.total end)
    
    return abilities
end

-- Get target breakdown for a user's ability
function Damage:GetTargetBreakdown(segment, userID, abilityID)
    local userData = self:GetUserDetail(segment, userID)
    if not userData or not userData[abilityID] then return {} end
    
    local abilityData = userData[abilityID]
    local targets = {}
    
    for targetID, targetData in pairs(abilityData.targets) do
        local targetName = DataStore:GetUsername(targetID)
        
        table.insert(targets, {
            name = targetName,
            total = targetData.total,
            hits = targetData.hits,
            percent = (targetData.total / abilityData.total) * 100,
        })
    end
    
    -- Sort by total damage
    table.sort(targets, function(a, b) return a.total > b.total end)
    
    return targets
end

-- Get DPS (damage per second)
function Damage:GetDPS(segment, userID)
    local total = self:GetTotal(segment, userID)
    local duration = Utils:GetCombatDuration()
    
    -- If no combat time, return total damage instead
    if duration <= 0 then
        return total
    end
    
    return total / duration
end

-- Get top ability for a user
function Damage:GetTopAbility(segment, userID)
    local abilities = self:GetAbilityBreakdown(segment, userID)
    if table.getn(abilities) == 0 then return nil end
    
    return abilities[1]
end

-- Get formatted tooltip data for a player
function Damage:GetTooltipData(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username then return nil end
    
    local total = self:GetTotal(segment, userID)
    local dps = self:GetDPS(segment, userID)
    local topAbility = self:GetTopAbility(segment, userID)
    
    local AdvancedStats = DPSLight_AdvancedStats
    local burstDPS = AdvancedStats and AdvancedStats:GetBurstDPS(username) or 0
    local activityPercent = AdvancedStats and AdvancedStats:GetActivityPercent(username, Utils:GetCombatDuration()) or 0
    
    local details = {}
    table.insert(details, string.format("Total: %s", Utils:FormatNumber(total)))
    table.insert(details, string.format("DPS: %s", Utils:FormatNumber(dps)))
    table.insert(details, string.format("Burst: %s", Utils:FormatNumber(burstDPS)))
    table.insert(details, string.format("Activity: %.1f%%", activityPercent))
    
    if topAbility then
        table.insert(details, string.format("Top: %s (%s)", topAbility.name, Utils:FormatNumber(topAbility.total)))
    end
    
    return {
        name = username,
        details = details
    }
end

return Damage
