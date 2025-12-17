-- ParserClassic.lua - Classic vanilla parser (no SuperWoW)
-- Compatible with Lua 5.0 (WoW 1.12.1)

local ParserClassic = {}
DPSLight_ParserClassic = ParserClassic

local PatternCache = DPSLight_PatternCache
local DataStore = DPSLight_DataStore
local Utils = DPSLight_Utils
local ObjectPool = DPSLight_ObjectPool

-- Lua 5.0 compatible strMatch (using string.find)
local function strMatch(text, pattern)
    local startPos, endPos, capture1, capture2, capture3, capture4, capture5 = string.find(text, pattern)
    if startPos then
        return capture1, capture2, capture3, capture4, capture5
    end
    return nil
end

-- Pre-allocate result table
local parseResult = {}

local function ClearResult()
    for k in pairs(parseResult) do
        parseResult[k] = nil
    end
end

-- Parse damage event
function ParserClassic:ParseDamage(event, text)
    ClearResult()
    
    local playerName = UnitName("player")
    
    -- Self melee attacks
    if event == "CHAT_MSG_COMBAT_SELF_HITS" then
        local target, amount, suffix = strMatch(text, "You hit (.+) for (%d+)(.*)")
        if target then
            parseResult.type = "DAMAGE"
            parseResult.source = playerName
            parseResult.target = target
            parseResult.ability = "Attack"
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
        
        -- Critical hit
        target, amount, suffix = strMatch(text, "You crit (.+) for (%d+)(.*)")
        if target then
            parseResult.type = "DAMAGE"
            parseResult.source = playerName
            parseResult.target = target
            parseResult.ability = "Attack"
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = true
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
    end
    
    -- Self spell damage
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        local ability, target, amount, suffix = strMatch(text, "Your (.+) hits (.+) for (%d+)(.*)")
        if target then
            parseResult.type = "DAMAGE"
            parseResult.source = playerName
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
        
        -- Critical spell hit
        ability, target, amount, suffix = strMatch(text, "Your (.+) crits (.+) for (%d+)(.*)")
        if target then
            parseResult.type = "DAMAGE"
            parseResult.source = playerName
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = true
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
    end
    
    -- Party/friendly damage
    if event == "CHAT_MSG_COMBAT_PARTY_HITS" or event == "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS" then
        local source, target, amount, suffix = strMatch(text, "(.+) hits (.+) for (%d+)(.*)")
        if source then
            parseResult.type = "DAMAGE"
            parseResult.source = source
            parseResult.target = target
            parseResult.ability = "Attack"
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
        
        source, target, amount, suffix = strMatch(text, "(.+) crits (.+) for (%d+)(.*)")
        if source then
            parseResult.type = "DAMAGE"
            parseResult.source = source
            parseResult.target = target
            parseResult.ability = "Attack"
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = true
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
    end
    
    -- Party/friendly spell damage
    if event == "CHAT_MSG_SPELL_PARTY_DAMAGE" or event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE" then
        local source, ability, target, amount, suffix = strMatch(text, "(.+)'s (.+) hits (.+) for (%d+)(.*)")
        if source then
            parseResult.type = "DAMAGE"
            parseResult.source = source
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
        
        source, ability, target, amount, suffix = strMatch(text, "(.+)'s (.+) crits (.+) for (%d+)(.*)")
        if source then
            parseResult.type = "DAMAGE"
            parseResult.source = source
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = true
            parseResult.damageType = PatternCache:ParseDamageType(suffix)
            return parseResult
        end
    end
    
    return nil
end

-- Parse healing event
function ParserClassic:ParseHealing(event, text)
    ClearResult()
    
    local playerName = UnitName("player")
    
    -- Self healing
    if event == "CHAT_MSG_SPELL_SELF_BUFF" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        local ability, target, amount = strMatch(text, "Your (.+) heals (.+) for (%d+)")
        if target then
            parseResult.type = "HEALING"
            parseResult.source = playerName
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            return parseResult
        end
        
        ability, target, amount = strMatch(text, "Your (.+) critically heals (.+) for (%d+)")
        if target then
            parseResult.type = "HEALING"
            parseResult.source = playerName
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = true
            return parseResult
        end
        
        -- HoT ticks
        target, amount, ability = strMatch(text, "(.+) gains (%d+) health from your (.+)")
        if target then
            parseResult.type = "HEALING"
            parseResult.source = playerName
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            return parseResult
        end
    end
    
    -- Party/friendly healing
    if event == "CHAT_MSG_SPELL_PARTY_BUFF" or event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF" or 
       event == "CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS" or event == "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS" then
        local source, ability, target, amount = strMatch(text, "(.+)'s (.+) heals (.+) for (%d+)")
        if source then
            parseResult.type = "HEALING"
            parseResult.source = source
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            return parseResult
        end
        
        source, ability, target, amount = strMatch(text, "(.+)'s (.+) critically heals (.+) for (%d+)")
        if source then
            parseResult.type = "HEALING"
            parseResult.source = source
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = true
            return parseResult
        end
        
        -- HoT ticks
        target, amount, source, ability = strMatch(text, "(.+) gains (%d+) health from (.+)'s (.+)")
        if target then
            parseResult.type = "HEALING"
            parseResult.source = source
            parseResult.target = target
            parseResult.ability = ability
            parseResult.amount = tonumber(amount)
            parseResult.isCrit = false
            return parseResult
        end
    end
    
    return nil
end

-- Parse death event
function ParserClassic:ParseDeath(event, text)
    if event ~= "CHAT_MSG_COMBAT_FRIENDLY_DEATH" then return nil end
    
    ClearResult()
    
    local victim = strMatch(text, "(.+) dies%.")
    if victim then
        parseResult.type = "DEATH"
        parseResult.victim = victim
        parseResult.timestamp = GetTime()
        return parseResult
    end
    
    victim, killer = strMatch(text, "(.+) is killed by (.+)%.")
    if victim then
        parseResult.type = "DEATH"
        parseResult.victim = victim
        parseResult.killer = killer
        parseResult.timestamp = GetTime()
        return parseResult
    end
    
    return nil
end

-- Parse dispel/decurse event
function ParserClassic:ParseDispel(event, text)
    ClearResult()
    
    local playerName = UnitName("player")
    
    -- Self dispel: "Your Dispel Magic removes Curse from Target"
    local ability, target = strMatch(text, "Your (.+) removes .+ from (.+)%.")
    if ability and target then
        parseResult.type = "DISPEL"
        parseResult.source = playerName
        parseResult.target = target
        parseResult.ability = ability
        parseResult.timestamp = GetTime()
        return parseResult
    end
    
    -- Party dispel: "Player's Dispel Magic removes Curse from Target"
    local source, ability, target = strMatch(text, "(.+)'s (.+) removes .+ from (.+)%.")
    if source and ability and target then
        parseResult.type = "DISPEL"
        parseResult.source = source
        parseResult.target = target
        parseResult.ability = ability
        parseResult.timestamp = GetTime()
        return parseResult
    end
    
    -- Cure Disease/Poison: "Your Cure Disease was resisted by Target"
    ability, target = strMatch(text, "Your (.+) was resisted by (.+)%.")
    if ability and target and (string.find(ability, "Cure") or string.find(ability, "Dispel") or string.find(ability, "Remove")) then
        parseResult.type = "DISPEL"
        parseResult.source = playerName
        parseResult.target = target
        parseResult.ability = ability
        parseResult.timestamp = GetTime()
        return parseResult
    end
    
    return nil
end

-- Main parse function
function ParserClassic:Parse(event, text)
    if not text or text == "" then return nil end
    
    -- Damage events
    if string.find(event, "DAMAGE") or string.find(event, "HITS") or string.find(event, "MISSES") then
        return self:ParseDamage(event, text)
    end
    
    -- Healing events
    if string.find(event, "BUFF") then
        local healResult = self:ParseHealing(event, text)
        if healResult then return healResult end
        
        -- Also check for dispels in BUFF events
        local dispelResult = self:ParseDispel(event, text)
        if dispelResult then return dispelResult end
    end
    
    -- Death events
    if string.find(event, "DEATH") then
        return self:ParseDeath(event, text)
    end
    
    -- Dispel events (also check in AURA events)
    if string.find(event, "AURA") or string.find(event, "SPELL") then
        return self:ParseDispel(event, text)
    end
    
    return nil
end

-- Get statistics
function ParserClassic:GetStats()
    return {
        parserType = "Classic Vanilla",
    }
end

return ParserClassic
