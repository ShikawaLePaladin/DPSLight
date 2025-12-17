-- EventEngine.lua - Optimized event handling system
-- Pre-allocated handlers, minimal function calls, fast dispatch

local EventEngine = {}
DPSLight_EventEngine = EventEngine

-- Pre-allocated handler storage
local eventHandlers = {}
local eventFrame = CreateFrame("Frame", "DPSLight_EventFrame")

-- Event priority system (higher = processed first)
local EVENT_PRIORITY = {
    CRITICAL = 3,
    HIGH = 2,
    NORMAL = 1,
    LOW = 0,
}

-- Registered events with their handlers
local registeredEvents = {}

-- Fast event dispatcher (no table lookups in hot path)
local function OnEvent()
    local handlers = eventHandlers[event]
    if handlers then
        for i = 1, table.getn(handlers) do
            handlers[i].handler(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        end
    end
end

eventFrame:SetScript("OnEvent", OnEvent)

-- Register an event handler
function EventEngine:RegisterEvent(eventName, handler, priority)
    if not eventName or not handler then return end
    
    priority = priority or EVENT_PRIORITY.NORMAL
    
    -- Create handler list if it doesn't exist
    if not eventHandlers[eventName] then
        eventHandlers[eventName] = {}
        registeredEvents[eventName] = true
        eventFrame:RegisterEvent(eventName)
    end
    
    -- Insert handler with priority sorting
    local handlers = eventHandlers[eventName]
    local inserted = false
    
    for i = 1, table.getn(handlers) do
        if (handlers[i].priority or 0) < priority then
            table.insert(handlers, i, {handler = handler, priority = priority})
            inserted = true
            break
        end
    end
    
    if not inserted then
        table.insert(handlers, {handler = handler, priority = priority})
    end
end

-- Unregister an event handler
function EventEngine:UnregisterEvent(eventName, handler)
    if not eventHandlers[eventName] then return end
    
    local handlers = eventHandlers[eventName]
    for i = table.getn(handlers), 1, -1 do
        if handlers[i].handler == handler then
            table.remove(handlers, i)
        end
    end
    
    -- Unregister from frame if no handlers left
    if table.getn(handlers) == 0 then
        eventHandlers[eventName] = nil
        registeredEvents[eventName] = nil
        eventFrame:UnregisterEvent(eventName)
    end
end

-- Check if an event is registered
function EventEngine:IsEventRegistered(eventName)
    return registeredEvents[eventName] == true
end

-- Get event handler count
function EventEngine:GetHandlerCount(eventName)
    if not eventHandlers[eventName] then return 0 end
    return table.getn(eventHandlers[eventName])
end

-- Suspend event processing (for batch operations)
local suspended = false

function EventEngine:Suspend()
    suspended = true
    eventFrame:UnregisterAllEvents()
end

function EventEngine:Resume()
    suspended = false
    for eventName in pairs(registeredEvents) do
        eventFrame:RegisterEvent(eventName)
    end
end

function EventEngine:IsSuspended()
    return suspended
end

-- Trigger custom event
function EventEngine:TriggerEvent(eventName, a1, a2, a3, a4, a5)
    local handlers = eventHandlers[eventName]
    if handlers then
        for i = 1, table.getn(handlers) do
            handlers[i].handler(eventName, a1, a2, a3, a4, a5)
        end
    end
end

-- Event statistics
local eventStats = {}
local statsEnabled = false

function EventEngine:EnableStats()
    statsEnabled = true
end

function EventEngine:DisableStats()
    statsEnabled = false
    for k in pairs(eventStats) do
        eventStats[k] = nil
    end
end

function EventEngine:GetStats()
    return eventStats
end

-- Wrap handler for stats collection
local function WrapHandlerWithStats(eventName, handler)
    return function()
        local start = debugprofilestop()
        handler()
        local elapsed = debugprofilestop() - start
        
        if not eventStats[eventName] then
            eventStats[eventName] = {count = 0, totalTime = 0, maxTime = 0}
        end
        
        local stats = eventStats[eventName]
        stats.count = stats.count + 1
        stats.totalTime = stats.totalTime + elapsed
        stats.maxTime = max(stats.maxTime, elapsed)
    end
end

-- Combat event optimization - pre-register common events
local COMBAT_EVENTS = {
    "CHAT_MSG_COMBAT_SELF_HITS",
    "CHAT_MSG_COMBAT_SELF_MISSES",
    "CHAT_MSG_SPELL_SELF_DAMAGE",
    "CHAT_MSG_COMBAT_PARTY_HITS",
    "CHAT_MSG_SPELL_PARTY_DAMAGE",
    "CHAT_MSG_COMBAT_PARTY_MISSES",
    "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
    "CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES",
    "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
    "CHAT_MSG_SPELL_SELF_BUFF",
    "CHAT_MSG_SPELL_PARTY_BUFF",
    "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
    "CHAT_MSG_COMBAT_FRIENDLY_DEATH",
}

function EventEngine:RegisterCombatEvents(handler)
    for _, eventName in ipairs(COMBAT_EVENTS) do
        self:RegisterEvent(eventName, handler, EVENT_PRIORITY.HIGH)
    end
end

function EventEngine:UnregisterCombatEvents(handler)
    for _, eventName in ipairs(COMBAT_EVENTS) do
        self:UnregisterEvent(eventName, handler)
    end
end

-- Export priority constants
EventEngine.PRIORITY = EVENT_PRIORITY

return EventEngine
