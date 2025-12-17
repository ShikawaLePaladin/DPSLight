-- Modules/Healing.lua - Healing module

local Healing = {}
DPSLight_Healing = Healing

local ModuleBase = DPSLight_ModuleBase
local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils

-- Inherit from ModuleBase
setmetatable(Healing, {__index = ModuleBase})

-- Initialize module
function Healing:Initialize()
    self.name = "healing"
    self.dataType = "healing"
    self.cache = {}
    self.cacheTime = 0
    self.cacheDuration = 0.5
end

-- Get ability breakdown for a user
function Healing:GetAbilityBreakdown(segment, userID)
    local userData = self:GetUserDetail(segment, userID)
    if not userData then return {} end
    
    local abilities = {}
    
    for abilityID, abilityData in pairs(userData) do
        local abilityName = DataStore:GetAbilityName(abilityID)
        
        table.insert(abilities, {
            name = abilityName,
            total = abilityData.total,
            effective = abilityData.effective,
            overhealing = abilityData.overhealing,
            hits = abilityData.hits,
            crits = abilityData.crits,
            overhealPercent = (abilityData.overhealing / abilityData.total) * 100,
            critPercent = (abilityData.crits / abilityData.hits) * 100,
        })
    end
    
    -- Sort by effective healing
    table.sort(abilities, function(a, b) return a.effective > b.effective end)
    
    return abilities
end

-- Get target breakdown for a user's healing spell
function Healing:GetTargetBreakdown(segment, userID, abilityID)
    local userData = self:GetUserDetail(segment, userID)
    if not userData or not userData[abilityID] then return {} end
    
    local abilityData = userData[abilityID]
    local targets = {}
    
    for targetID, targetData in pairs(abilityData.targets) do
        local targetName = DataStore:GetUsername(targetID)
        
        table.insert(targets, {
            name = targetName,
            total = targetData.total,
            effective = targetData.effective,
            overhealing = targetData.overhealing,
            percent = (targetData.effective / abilityData.effective) * 100,
        })
    end
    
    -- Sort by effective healing
    table.sort(targets, function(a, b) return a.effective > b.effective end)
    
    return targets
end

-- Get HPS (healing per second)
function Healing:GetHPS(segment, userID)
    local total = self:GetTotal(segment, userID)
    local duration = Utils:GetCombatDuration()
    
    -- If no combat time, return total healing instead
    if duration <= 0 then
        return total
    end
    
    return total / duration
end

-- Get total overhealing percentage
function Healing:GetOverhealPercent(segment, userID)
    local userData = self:GetUserDetail(segment, userID)
    if not userData then return 0 end
    
    local totalHealing = 0
    local totalOverhealing = 0
    
    for _, abilityData in pairs(userData) do
        totalHealing = totalHealing + abilityData.total
        totalOverhealing = totalOverhealing + abilityData.overhealing
    end
    
    if totalHealing == 0 then return 0 end
    return (totalOverhealing / totalHealing) * 100
end

-- Get formatted tooltip data for a player
function Healing:GetTooltipData(segment, userID)
    local username = DataStore:GetUsername(userID)
    if not username then return nil end
    
    local total = self:GetTotal(segment, userID)
    local hps = self:GetHPS(segment, userID)
    local overhealPercent = self:GetOverhealPercent(segment, userID)
    local topAbility = self:GetTopAbility(segment, userID)
    
    local AdvancedStats = DPSLight_AdvancedStats
    local activityPercent = AdvancedStats and AdvancedStats:GetActivityPercent(username, DPSLight_Utils:GetCombatDuration()) or 0
    
    local details = {}
    table.insert(details, string.format("Total: %s", DPSLight_Utils:FormatNumber(total)))
    table.insert(details, string.format("HPS: %s", DPSLight_Utils:FormatNumber(hps)))
    table.insert(details, string.format("Overheal: %.1f%%", overhealPercent))
    table.insert(details, string.format("Activity: %.1f%%", activityPercent))
    
    if topAbility then
        table.insert(details, string.format("Top: %s (%s)", topAbility.name, DPSLight_Utils:FormatNumber(topAbility.effective)))
    end
    
    return {
        name = username,
        details = details
    }
end

-- Get top ability for a user
function Healing:GetTopAbility(segment, userID)
    local abilities = self:GetAbilityBreakdown(segment, userID)
    if table.getn(abilities) == 0 then return nil end
    
    return abilities[1]
end

return Healing
