-- Reporter.lua - Report combat statistics to chat
local Reporter = {}
DPSLight_Reporter = Reporter

-- Lazy load
local function GetDamage() return DPSLight_Damage end
local function GetHealing() return DPSLight_Healing end
local function GetUtils() return DPSLight_Utils end
local function GetDatabase() return DPSLight_Database end

-- Report channels
local CHANNELS = {
    PARTY = "PARTY",
    RAID = "RAID",
    GUILD = "GUILD",
    SAY = "SAY",
    YELL = "YELL",
}

-- Format damage report
function Reporter:FormatDamage(maxLines)
    maxLines = maxLines or 5
    local Damage = GetDamage()
    local Utils = GetUtils()
    local DataStore = DPSLight_DataStore
    
    if not Damage or not Utils or not DataStore then return {} end
    
    local currentSegment = DataStore:GetCurrentSegment() or 0
    local data = Damage:GetSortedData(currentSegment)
    if not data then return {} end
    
    local lines = {}
    local dataLen = table.getn(data)
    
    table.insert(lines, "=== DPS Meter ===")
    
    for i = 1, math.min(maxLines, dataLen) do
        local entry = data[i]
        local dps = Damage:GetDPS(nil, entry.userID)
        local percent = Damage:GetPercent(nil, entry.userID)
        
        local medal = ""
        if i == 1 then medal = "[1] "
        elseif i == 2 then medal = "[2] "
        elseif i == 3 then medal = "[3] "
        end
        
        table.insert(lines, string.format(
            "%s%d. %s - %s (%.1f%%)",
            medal,
            i,
            entry.username,
            Utils:FormatNumber(dps),
            percent
        ))
    end
    
    return lines
end

-- Format healing report
function Reporter:FormatHealing(maxLines)
    maxLines = maxLines or 5
    local Healing = GetHealing()
    local Utils = GetUtils()
    local DataStore = DPSLight_DataStore
    
    if not Healing or not Utils or not DataStore then return {} end
    
    local currentSegment = DataStore:GetCurrentSegment() or 0
    local data = Healing:GetSortedData(currentSegment)
    if not data then return {} end
    
    local lines = {}
    local dataLen = table.getn(data)
    
    table.insert(lines, "=== HPS Meter ===")
    
    for i = 1, math.min(maxLines, dataLen) do
        local entry = data[i]
        local hps = Healing:GetHPS(nil, entry.userID)
        local percent = Healing:GetPercent(nil, entry.userID)
        
        local medal = ""
        if i == 1 then medal = "[1] "
        elseif i == 2 then medal = "[2] "
        elseif i == 3 then medal = "[3] "
        end
        
        table.insert(lines, string.format(
            "%s%d. %s - %s (%.1f%%)",
            medal,
            i,
            entry.username,
            Utils:FormatNumber(hps),
            percent
        ))
    end
    
    return lines
end

-- Format summary report
function Reporter:FormatSummary()
    local Utils = GetUtils()
    if not Utils then return {} end
    
    local duration = Utils:GetCombatDuration()
    local lines = {}
    
    table.insert(lines, string.format("Combat Duration: %s", Utils:FormatTime(duration)))
    
    return lines
end

-- Send report to channel
function Reporter:SendReport(channel, reportType, maxLines, whisperTarget)
    reportType = reportType or "damage"
    maxLines = maxLines or 5
    
    local lines = {}
    
    if reportType == "damage" then
        lines = self:FormatDamage(maxLines)
    elseif reportType == "healing" then
        lines = self:FormatHealing(maxLines)
    elseif reportType == "both" then
        local damageLines = self:FormatDamage(3)
        local healingLines = self:FormatHealing(3)
        
        for _, line in ipairs(damageLines) do
            table.insert(lines, line)
        end
        
        for _, line in ipairs(healingLines) do
            table.insert(lines, line)
        end
    end
    
    -- Add summary
    local summary = self:FormatSummary()
    for _, line in ipairs(summary) do
        table.insert(lines, line)
    end
    
    -- Send lines
    if channel == "WHISPER" then
        if not whisperTarget or whisperTarget == "" then
            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: No whisper target specified")
            return
        end
        for _, line in ipairs(lines) do
            SendChatMessage(line, "WHISPER", nil, whisperTarget)
        end
    else
        for _, line in ipairs(lines) do
            SendChatMessage(line, channel)
        end
    end
end

-- Detect best channel
function Reporter:GetBestChannel()
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    else
        return "SAY"
    end
end

-- Quick report
function Reporter:QuickReport(reportType)
    local channel = self:GetBestChannel()
    self:SendReport(channel, reportType or "damage", 5)
end

return Reporter
