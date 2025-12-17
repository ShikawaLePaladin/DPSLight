-- ParserMain.lua - Main parser controller
-- Automatically selects SuperWoW or Classic parser

local ParserMain = {}
DPSLight_ParserMain = ParserMain

-- Lazy load dependencies
local function GetConfig() return DPSLight_Config end
local function GetEventEngine() return DPSLight_EventEngine end
local function GetDataStore() return DPSLight_DataStore end
local function GetPatternCache() return DPSLight_PatternCache end
local function GetParserOptimized() return DPSLight_ParserOptimized end
local function GetParserClassic() return DPSLight_ParserClassic end
local function GetUtils() return DPSLight_Utils end

-- Active parser
local activeParser = nil
local useSuperWoW = false

-- Event counters
local eventCount = 0
local parseTime = 0

-- Initialize parser system
function ParserMain:Initialize()
    local PatternCache = GetPatternCache()
    local Config = GetConfig()
    local ParserOptimized = GetParserOptimized()
    local Utils = GetUtils()
    local EventEngine = GetEventEngine()
    
    if not PatternCache or not Config then return end
    
    PatternCache:Initialize()
    
    -- Detect SuperWoW
    if Config.IsSuperWoWAvailable and Config:IsSuperWoWAvailable() and Config:Get("preferSuperWoW") then
        useSuperWoW = true
        activeParser = ParserOptimized
        if ParserOptimized and ParserOptimized.Initialize then
            ParserOptimized:Initialize()
        end
        
        -- Register SuperWoW events
        if EventEngine and Config:Get("useSuperWoWEvents") then
            EventEngine:RegisterEvent("RAW_COMBATLOG", function(event, eventName, combatText)
                self:HandleRawCombatLog(eventName, combatText)
            end, EventEngine.PRIORITY and EventEngine.PRIORITY.HIGH or nil)
            
            EventEngine:RegisterEvent("UNIT_CASTEVENT", function(event, casterGuid, targetGuid, eventType, spellID, duration)
                self:HandleUnitCast(casterGuid, targetGuid, eventType, spellID, duration)
            end, EventEngine.PRIORITY and EventEngine.PRIORITY.HIGH or nil)
        end
    else
        useSuperWoW = false
        local ParserClassic = GetParserClassic()
        activeParser = ParserClassic
        
        -- Register classic combat log events
        if EventEngine then
            EventEngine:RegisterCombatEvents(function(event, text)
                self:HandleCombatEvent(event, text)
            end)
        end
    end
end

-- Handle RAW_COMBATLOG (SuperWoW)
function ParserMain:HandleRawCombatLog(eventName, combatText)
    local startTime = debugprofilestop()
    local ParserOptimized = GetParserOptimized()
    if not ParserOptimized then return end
    
    local result = ParserOptimized:ParseRawCombat(eventName, combatText)
    
    if result then
        self:ProcessResult(result)
    end
    
    parseTime = parseTime + (debugprofilestop() - startTime)
    eventCount = eventCount + 1
end

-- Handle UNIT_CASTEVENT (SuperWoW)
function ParserMain:HandleUnitCast(casterGuid, targetGuid, eventType, spellID, duration)
    local ParserOptimized = GetParserOptimized()
    if not ParserOptimized then return end
    
    local result = ParserOptimized:ParseUnitCast(casterGuid, targetGuid, eventType, spellID, duration)
    
    if result then
        -- Process cast events (for interrupts, etc.)
        -- Not implemented yet, but structure is here
    end
end

-- Handle classic combat events
function ParserMain:HandleCombatEvent(event, text)
    local startTime = debugprofilestop()
    local ParserClassic = GetParserClassic()
    if not ParserClassic then return end
    
    -- Debug
    if DPSLight and DPSLight.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("[PARSER] Parsing: " .. event)
    end
    
    local result = ParserClassic:Parse(event, text)
    
    if result then
        self:ProcessResult(result)
    end
    
    parseTime = parseTime + (debugprofilestop() - startTime)
    eventCount = eventCount + 1
end

-- Process parsed result
function ParserMain:ProcessResult(result)
    if not result then return end
    local DataStore = GetDataStore()
    if not DataStore then return end
    
    if result.type == "DAMAGE" then
        DataStore:AddDamage(
            result.source,
            result.target,
            result.ability,
            result.amount,
            result.isCrit,
            result.damageType
        )
        
    elseif result.type == "HEALING" then
        DataStore:AddHealing(
            result.source,
            result.target,
            result.ability,
            result.amount,
            result.overhealing,
            result.isCrit
        )
        
    elseif result.type == "DEATH" then
        DataStore:AddDeath(
            result.victim,
            result.timestamp,
            result.killer,
            result.killerAbility
        )
        
    elseif result.type == "DISPEL" then
        -- Call Dispels module
        if DPSLight_Dispels and DPSLight_Dispels.AddDispel then
            DPSLight_Dispels:AddDispel(result.source, result.target, result.ability)
        end
        
        -- Also call Decurse module if it's a curse/disease/poison removal
        if DPSLight_Decurse and DPSLight_Decurse.AddDecurse then
            local ability = result.ability or ""
            if string.find(ability, "Cure") or string.find(ability, "Remove") or string.find(ability, "Cleanse") then
                DPSLight_Decurse:AddDecurse(result.source, result.target, result.ability)
            end
        end
    end
end

-- Get parser statistics
function ParserMain:GetStats()
    local avgTime = eventCount > 0 and (parseTime / eventCount) or 0
    
    local stats = {
        parserType = useSuperWoW and "SuperWoW" or "Classic",
        eventsProcessed = eventCount,
        totalParseTime = parseTime,
        averageParseTime = avgTime,
    }
    
    -- Merge parser-specific stats
    if activeParser and activeParser.GetStats then
        local parserStats = activeParser:GetStats()
        for key, value in pairs(parserStats) do
            stats[key] = value
        end
    end
    
    return stats
end

-- Reset statistics
function ParserMain:ResetStats()
    eventCount = 0
    parseTime = 0
end

-- Check if using SuperWoW
function ParserMain:IsUsingSuperWoW()
    return useSuperWoW
end

return ParserMain
