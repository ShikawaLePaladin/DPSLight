-- PatternCache.lua - Pre-compiled regex patterns for combat log parsing
-- Eliminates repeated string.gfind calls and pattern compilation

local PatternCache = {}
DPSLight_PatternCache = PatternCache

-- English patterns (enUS)
local patternsEN = {
    -- Self hits
    SELF_HIT = "You hit (.+) for (%d+)(.*)",
    SELF_CRIT = "You crit (.+) for (%d+)(.*)",
    SELF_MISS = "You miss (.+)",
    
    -- Self spells
    SELF_SPELL_HIT = "Your (.+) hits (.+) for (%d+)(.*)",
    SELF_SPELL_CRIT = "Your (.+) crits (.+) for (%d+)(.*)",
    SELF_SPELL_MISS = "Your (.+) misses (.+)",
    
    -- Friendly hits
    FRIENDLY_HIT = "(.+) hits (.+) for (%d+)(.*)",
    FRIENDLY_CRIT = "(.+) crits (.+) for (%d+)(.*)",
    FRIENDLY_MISS = "(.+) misses (.+)",
    
    -- Friendly spells
    FRIENDLY_SPELL_HIT = "(.+)'s (.+) hits (.+) for (%d+)(.*)",
    FRIENDLY_SPELL_CRIT = "(.+)'s (.+) crits (.+) for (%d+)(.*)",
    
    -- Healing
    SELF_HEAL = "Your (.+) heals (.+) for (%d+)%.",
    SELF_HEAL_CRIT = "Your (.+) critically heals (.+) for (%d+)%.",
    FRIENDLY_HEAL = "(.+)'s (.+) heals (.+) for (%d+)%.",
    FRIENDLY_HEAL_CRIT = "(.+)'s (.+) critically heals (.+) for (%d+)%.",
    
    -- Periodic heals (HoTs)
    SELF_HOT = "(.+) gains (%d+) health from your (.+)%.",
    FRIENDLY_HOT = "(.+) gains (%d+) health from (.+)'s (.+)%.",
    
    -- Damage taken
    CREATURE_HIT_SELF = "(.+) hits you for (%d+)(.*)",
    CREATURE_CRIT_SELF = "(.+) crits you for (%d+)(.*)",
    
    -- Deaths
    DEATH = "(.+) dies%.",
    DEATH_KILL = "(.+) is killed by (.+)%.",
    
    -- Absorb
    ABSORB_ALL = "(.+) absorbs all the damage%.",
    ABSORB_PARTIAL = "%((%d+) absorbed%)",
}

-- French patterns (frFR)
local patternsFR = {
    SELF_HIT = "Vous touchez (.+) et infligez (%d+) points de dégâts(.*)",
    SELF_CRIT = "Vous infligez un coup critique à (.+) %((%d+) points de dégâts(.*)%)",
    SELF_SPELL_HIT = "Votre (.+) touche (.+) et inflige (%d+) points de dégâts(.*)",
    SELF_SPELL_CRIT = "Votre (.+) inflige un coup critique à (.+) %((%d+) points de dégâts(.*)%)",
    SELF_HEAL = "Votre (.+) rend (%d+) points de vie à (.+)%.",
    -- Add more French patterns as needed
}

-- Current locale patterns
local currentPatterns = patternsEN

-- Initialize patterns based on locale
function PatternCache:Initialize()
    local locale = GetLocale()
    
    if locale == "frFR" then
        -- Merge French patterns with English fallbacks
        currentPatterns = {}
        for key, pattern in pairs(patternsEN) do
            currentPatterns[key] = patternsFR[key] or pattern
        end
    else
        -- Default to English
        currentPatterns = patternsEN
    end
end

-- Get pattern by key
function PatternCache:Get(key)
    return currentPatterns[key]
end

-- Fast pattern matching - returns captures or nil
function PatternCache:Match(text, patternKey)
    local pattern = currentPatterns[patternKey]
    if not pattern then return nil end
    
    return string.match(text, pattern)
end

-- Try multiple patterns in order (for ambiguous messages)
function PatternCache:MatchAny(text)
    for i = 1, table.getn(arg) do
        local patternKey = arg[i]
        local pattern = currentPatterns[patternKey]
        if pattern then
            local a, b, c, d, e = string.match(text, pattern)
            if a then
                return a, b, c, d, e
            end
        end
    end
    return nil
end

-- Extract damage type from suffix (e.g., " Fire damage")
local damageTypes = {
    ["Fire"] = "FIRE",
    ["Nature"] = "NATURE",
    ["Frost"] = "FROST",
    ["Shadow"] = "SHADOW",
    ["Arcane"] = "ARCANE",
    ["Holy"] = "HOLY",
    ["Physical"] = "PHYSICAL",
}

function PatternCache:ParseDamageType(suffix)
    if not suffix or suffix == "" then return "PHYSICAL" end
    
    for typeName, typeConst in pairs(damageTypes) do
        if string.find(suffix, typeName) then
            return typeConst
        end
    end
    
    return "PHYSICAL"
end

-- Extract absorbed amount from text
function PatternCache:ParseAbsorbed(text)
    local absorbed = string.match(text, "%((%d+) absorbed%)")
    return tonumber(absorbed) or 0
end

-- Check if hit was critical
function PatternCache:IsCritical(text)
    return string.find(text, "crit") ~= nil or string.find(text, "critical") ~= nil
end

-- Optimized combat log parser using patterns
function PatternCache:ParseCombatMessage(event, text)
    -- Fast path: check event type first
    if string.find(event, "SELF_HITS") then
        local target, amount, suffix = self:Match(text, "SELF_HIT")
        if target then
            return {
                type = "DAMAGE",
                source = UnitName("player"),
                target = target,
                ability = "Attack",
                amount = tonumber(amount),
                damageType = self:ParseDamageType(suffix),
                isCrit = false,
            }
        end
        
        target, amount, suffix = self:Match(text, "SELF_CRIT")
        if target then
            return {
                type = "DAMAGE",
                source = UnitName("player"),
                target = target,
                ability = "Attack",
                amount = tonumber(amount),
                damageType = self:ParseDamageType(suffix),
                isCrit = true,
            }
        end
        
    elseif string.find(event, "SPELL_SELF_DAMAGE") then
        local ability, target, amount, suffix = self:Match(text, "SELF_SPELL_HIT")
        if target then
            return {
                type = "DAMAGE",
                source = UnitName("player"),
                target = target,
                ability = ability,
                amount = tonumber(amount),
                damageType = self:ParseDamageType(suffix),
                isCrit = false,
            }
        end
        
        ability, target, amount, suffix = self:Match(text, "SELF_SPELL_CRIT")
        if target then
            return {
                type = "DAMAGE",
                source = UnitName("player"),
                target = target,
                ability = ability,
                amount = tonumber(amount),
                damageType = self:ParseDamageType(suffix),
                isCrit = true,
            }
        end
        
    elseif string.find(event, "SPELL_SELF_BUFF") or string.find(event, "SPELL_PERIODIC_SELF_BUFFS") then
        local ability, target, amount = self:Match(text, "SELF_HEAL")
        if target then
            return {
                type = "HEALING",
                source = UnitName("player"),
                target = target,
                ability = ability,
                amount = tonumber(amount),
                isCrit = false,
            }
        end
        
        ability, target, amount = self:Match(text, "SELF_HEAL_CRIT")
        if target then
            return {
                type = "HEALING",
                source = UnitName("player"),
                target = target,
                ability = ability,
                amount = tonumber(amount),
                isCrit = true,
            }
        end
    end
    
    return nil
end

return PatternCache
