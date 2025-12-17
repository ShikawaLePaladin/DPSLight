-- DPSLight.lua - Main initialization file
-- Ultra-optimized combat analysis addon

DPSLight = {}
DPSLight.Version = "1.1.0"
DPSLight.Build = "Advanced"

-- Global references (populated by modules)
local Config = nil
local EventEngine = nil
local DataStore = nil
local ParserMain = nil
local Damage = nil
local Healing = nil
local Deaths = nil
local DiffSync = nil
local MainFrame = nil
local Utils = nil
local Database = nil
local AdvancedStats = nil
local MinimapButton = nil
local BossDetector = nil
local Reporter = nil

-- Initialization state
local initialized = false

-- Initialize addon
function DPSLight:Initialize()
    if initialized then return end
    
    -- Load global references FIRST
    Utils = DPSLight_Utils
    Config = DPSLight_Config
    EventEngine = DPSLight_EventEngine
    DataStore = DPSLight_DataStore
    ParserMain = DPSLight_ParserMain
    Damage = DPSLight_Damage
    Healing = DPSLight_Healing
    Deaths = DPSLight_Deaths
    DiffSync = DPSLight_DiffSync
    MainFrame = DPSLight_MainFrame
    Database = DPSLight_Database
    AdvancedStats = DPSLight_AdvancedStats
    MinimapButton = DPSLight_MinimapButton
    BossDetector = DPSLight_BossDetector
    Reporter = DPSLight_Reporter
    
    Utils:Print("Initializing DPSLight v" .. self.Version, 0, 1, 0.5)
    
    -- Initialize database first
    if Database and Database.Initialize then
        Database:Initialize()
    end
    
    -- Initialize advanced stats
    if AdvancedStats and AdvancedStats.Initialize then
        AdvancedStats:Initialize()
    end
    
    -- Initialize boss detector
    if BossDetector and BossDetector.Initialize then
        BossDetector:Initialize()
    end
    
    -- Initialize configuration
    if Config and Config.Initialize then
        Config:Initialize()
    end
    
    -- Detect SuperWoW
    local superWow = false
    if Config and Config.IsSuperWoWAvailable then
        superWow = Config:IsSuperWoWAvailable()
    end
    if superWow then
        Utils:Print("SuperWoW detected! Using optimized parser.", 0, 1, 0)
    else
        Utils:Print("Using classic parser.", 1, 1, 0)
    end
    
    -- Initialize modules
    if Damage and Damage.Initialize then
        Damage:Initialize()
    end
    if Healing and Healing.Initialize then
        Healing:Initialize()
    end
    
    -- Initialize parser
    if ParserMain and ParserMain.Initialize then
        ParserMain:Initialize()
    end
    
    -- Initialize sync system
    if Config and Config.Get and Config:Get("syncEnabled") and DiffSync and DiffSync.Initialize then
        DiffSync:Initialize()
    end
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Register combat events
    EventEngine:RegisterEvent("PLAYER_REGEN_DISABLED", function()
        self:OnCombatStart()
    end)
    
    EventEngine:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:OnCombatEnd()
    end)
    
    -- Register raid/party roster events to update class cache
    EventEngine:RegisterEvent("RAID_ROSTER_UPDATE", function()
        if Utils and Utils.UpdateClassCache then
            Utils:UpdateClassCache()
        end
    end)
    
    EventEngine:RegisterEvent("PARTY_MEMBERS_CHANGED", function()
        if Utils and Utils.UpdateClassCache then
            Utils:UpdateClassCache()
        end
    end)
    
    -- Force initial class cache scan
    if Utils and Utils.UpdateClassCache then
        Utils:UpdateClassCache()
    end
    
    -- Create minimap button
    if MinimapButton and MinimapButton.Create then
        MinimapButton:Create()
        local hideButton = Database and Database:GetSetting("minimap.hide")
        if not hideButton then
            MinimapButton:Show()
        end
    end
    
    -- Initialize combat detection for MainFrame
    if MainFrame and MainFrame.InitializeCombatDetection then
        MainFrame:InitializeCombatDetection()
    end
    
    -- Initialize window snapping system
    if MainFrame and MainFrame.InitializeForSnapping then
        MainFrame:InitializeForSnapping()
    end
    
    initialized = true
    Utils:Print("DPSLight initialized successfully!", 0, 1, 0)
    
    -- Show performance info
    local stats = ParserMain:GetStats()
    Utils:Print("Parser: " .. (stats.parserType or "Unknown"), 0.5, 0.5, 1)
end

-- Combat start handler
function DPSLight:OnCombatStart()
    Utils:StartCombatTimer()
    
    if Config:Get("autoNewSegment") then
        DataStore:NewSegment()
        if AdvancedStats then
            AdvancedStats:Reset()
        end
        if BossDetector then
            BossDetector:Reset()
        end
    end
    
    if Config:Get("autoStartCombat") then
        Utils:Print("Combat started!", 1, 1, 0)
    end
end

-- Combat end handler
function DPSLight:OnCombatEnd()
    local duration = Utils:EndCombatTimer()
    
    if Config:Get("autoStartCombat") then
        Utils:Print(string.format("Combat ended (Duration: %s)", Utils:FormatTime(duration)), 1, 1, 0)
    end
    
    -- Save to history
    if Database then
        local damageData = Damage and Damage:GetSortedData() or {}
        local healingData = Healing and Healing:GetSortedData() or {}
        
        Database:SaveCombatSegment("Combat", duration, damageData, healingData)
        
        -- Update records
        if table.getn(damageData) > 0 then
            local topDPS = Damage:GetDPS(nil, damageData[1].userID)
            Database:UpdateRecords(topDPS, 0, damageData[1].username, duration)
        end
    end
end

-- Slash command handler
function DPSLight:SlashCommandHandler(msg)
    msg = string.lower(msg or "")
    
    if msg == "" or msg == "show" then
        MainFrame:Show()
        
    elseif msg == "hide" then
        MainFrame:Hide()
        
    elseif msg == "toggle" then
        MainFrame:Toggle()
        
    elseif msg == "reset" then
        DataStore:Reset()
        Utils:Print("All data reset.", 1, 0.5, 0)
        
    elseif msg == "sync" then
        local syncEnabled = not DiffSync:IsEnabled()
        DiffSync:SetEnabled(syncEnabled)
        Utils:Print("Sync " .. (syncEnabled and "enabled" or "disabled"), 0, 1, 0)
        
    elseif msg == "stats" or msg == "info" then
        self:ShowStats()
        
    elseif msg == "test" then
        -- Add test data
        local playerName = UnitName("player")
        DataStore:AddDamage(playerName, "Test Target", "Attack", 100, false, "Physical")
        DataStore:AddDamage(playerName, "Test Target", "Attack", 150, true, "Physical")
        DataStore:AddDamage(playerName, "Test Target", "Fireball", 300, false, "Fire")
        Utils:Print("Test data added. Check the damage window.", 0, 1, 0)
        MainFrame:Show()
        
    elseif msg == "report" or string.find(msg, "^report ") then
        -- Report to chat
        local args = {}
        for word in string.gfind(msg, "%S+") do
            table.insert(args, word)
        end
        
        if Reporter then
            if table.getn(args) == 1 then
                Reporter:QuickReport("damage")
            elseif args[2] == "damage" or args[2] == "dps" then
                Reporter:QuickReport("damage")
            elseif args[2] == "healing" or args[2] == "hps" then
                Reporter:QuickReport("healing")
            elseif args[2] == "both" then
                Reporter:QuickReport("both")
            else
                Utils:Print("Usage: /dps report [damage|healing|both]", 1, 1, 0)
            end
        end
        
    elseif msg == "debug" then
        -- Toggle debug mode
        if not DPSLight.debugMode then
            DPSLight.debugMode = true
            Utils:Print("Debug mode enabled - combat events will be printed to chat", 0, 1, 0)
            -- Add a test event listener
            local frame = CreateFrame("Frame")
            frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
            frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
            frame:SetScript("OnEvent", function()
                DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] Event: " .. event .. " | Text: " .. arg1)
            end)
            DPSLight.debugFrame = frame
        else
            DPSLight.debugMode = false
            if DPSLight.debugFrame then
                DPSLight.debugFrame:UnregisterAllEvents()
            end
            Utils:Print("Debug mode disabled", 1, 0.5, 0)
        end
        
    elseif msg == "help" then
        self:ShowHelp()
        
    else
        Utils:Print("Unknown command. Type /dps help for commands.", 1, 0, 0)
    end
end

-- Show statistics
function DPSLight:ShowStats()
    Utils:Print("=== DPSLight Statistics ===", 0, 1, 1)
    
    -- Parser stats
    local parserStats = ParserMain:GetStats()
    Utils:Print(string.format("Parser: %s", parserStats.parserType), 1, 1, 1)
    Utils:Print(string.format("Events: %d (Avg: %.2fms)", 
        parserStats.eventsProcessed, 
        parserStats.averageParseTime), 1, 1, 1)
    
    -- Memory stats
    local memStats = DataStore:GetMemoryUsage()
    Utils:Print(string.format("Memory: ~%.1f KB", memStats.estimatedKB), 1, 1, 1)
    Utils:Print(string.format("Users: %d | Abilities: %d", memStats.users, memStats.abilities), 1, 1, 1)
    
    -- Sync stats
    local syncStats = DiffSync:GetStats()
    Utils:Print(string.format("Sync: %s (%d pending)", 
        syncStats.syncEnabled and "Enabled" or "Disabled",
        syncStats.pendingChanges), 1, 1, 1)
end

-- Show help
function DPSLight:ShowHelp()
    Utils:Print("=== DPSLight Commands ===", 0, 1, 1)
    Utils:Print("/dps or /dps show - Show main window", 1, 1, 1)
    Utils:Print("/dps hide - Hide main window", 1, 1, 1)
    Utils:Print("/dps toggle - Toggle main window", 1, 1, 1)
    Utils:Print("/dps reset - Reset all data", 1, 1, 1)
    Utils:Print("/dps sync - Toggle raid sync", 1, 1, 1)
    Utils:Print("/dps stats - Show statistics", 1, 1, 1)
    Utils:Print("/dps help - Show this help", 1, 1, 1)
end

-- Register slash commands
function DPSLight:RegisterSlashCommands()
    SLASH_DPSLIGHT1 = "/dps"
    SLASH_DPSLIGHT2 = "/dpslight"
    
    SlashCmdList["DPSLIGHT"] = function(msg)
        DPSLight:SlashCommandHandler(msg)
    end
end

-- Event: VARIABLES_LOADED
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("VARIABLES_LOADED")
loadFrame:RegisterEvent("PLAYER_LOGIN")

loadFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" or event == "PLAYER_LOGIN" then
        -- Wait a bit for other addons to load
        local timer = 0
        local initFrame = CreateFrame("Frame")
        initFrame:SetScript("OnUpdate", function()
            timer = timer + arg1
            if timer >= 1 then
                DPSLight:Initialize()
                initFrame:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

-- Global API
_G.DPSLight = DPSLight
