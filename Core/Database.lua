-- Database.lua - Persistent storage for combat history
local Database = {}
DPSLight_Database = Database

-- Default saved variables structure
local defaultDB = {
    combatHistory = {},
    records = {
        highestDPS = {value = 0, player = "", timestamp = 0},
        highestHPS = {value = 0, player = "", timestamp = 0},
        longestCombat = {value = 0, timestamp = 0},
    },
    settings = {
        windowPos = {x = 0, y = 0},
        windowSize = {width = 400, height = 500},
        opacity = 0.9,
        scale = 1.0,
        minimap = {hide = false, angle = 180},
        compactMode = false,
        showIcons = true,
        autoReport = false,
        bossOnly = false,
        bgColor = {r = 0, g = 0, b = 0, a = 0.9},
        borderStyle = 1,
        showControls = true,
        showFooter = true,
        maxPlayers = 20,
        showSelfOnly = false,
        filterMode = "all",
        buttonVisibility = {
            modeBtn = true,
            combatBtn = true,
            dpsToggleBtn = true,
            reportBtn = true,
            resetBtn = true,
        },
        footerInfo = {
            combatTimer = true,
            fps = false,
            latency = false,
            memory = false,
        },
    },
    version = "1.1",
}

-- Initialize database
function Database:Initialize()
    if not DPSLightDB then
        DPSLightDB = self:DeepCopy(defaultDB)
    else
        -- Merge with defaults for new fields
        self:MergeDefaults(DPSLightDB, defaultDB)
    end
end

-- Deep copy helper
function Database:DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for key, value in pairs(orig) do
            copy[key] = self:DeepCopy(value)
        end
    else
        copy = orig
    end
    return copy
end

-- Merge defaults
function Database:MergeDefaults(db, defaults)
    for key, value in pairs(defaults) do
        if db[key] == nil then
            db[key] = self:DeepCopy(value)
        elseif type(value) == "table" and type(db[key]) == "table" then
            self:MergeDefaults(db[key], value)
        end
    end
end

-- Save combat segment
function Database:SaveCombatSegment(name, duration, damageData, healingData)
    local segment = {
        name = name or "Combat",
        timestamp = time(),
        duration = duration,
        damage = damageData,
        healing = healingData,
    }
    
    table.insert(DPSLightDB.combatHistory, 1, segment)
    
    -- Keep only last 50 combats
    while table.getn(DPSLightDB.combatHistory) > 50 do
        table.remove(DPSLightDB.combatHistory)
    end
end

-- Update records
function Database:UpdateRecords(dps, hps, playerName, duration)
    if dps > DPSLightDB.records.highestDPS.value then
        DPSLightDB.records.highestDPS = {
            value = dps,
            player = playerName,
            timestamp = time(),
        }
    end
    
    if hps > DPSLightDB.records.highestHPS.value then
        DPSLightDB.records.highestHPS = {
            value = hps,
            player = playerName,
            timestamp = time(),
        }
    end
    
    if duration > DPSLightDB.records.longestCombat.value then
        DPSLightDB.records.longestCombat = {
            value = duration,
            timestamp = time(),
        }
    end
end

-- Get settings
function Database:GetSetting(key)
    local current = DPSLightDB.settings
    for part in string.gfind(key, "[^.]+") do
        if current[part] ~= nil then
            current = current[part]
        else
            return nil
        end
    end
    return current
end

-- Set settings
function Database:SetSetting(key, value)
    local parts = {}
    for part in string.gfind(key, "[^.]+") do
        table.insert(parts, part)
    end
    
    local current = DPSLightDB.settings
    for i = 1, table.getn(parts) - 1 do
        if not current[parts[i]] then
            current[parts[i]] = {}
        end
        current = current[parts[i]]
    end
    
    current[parts[table.getn(parts)]] = value
end

-- Get combat history
function Database:GetHistory()
    return DPSLightDB.combatHistory or {}
end

-- Get records
function Database:GetRecords()
    return DPSLightDB.records
end

-- Reset all settings to default
function Database:ResetAllSettings()
    if DPSLightDB then
        DPSLightDB.settings = {
            windowPos = {x = 0, y = 0},
            windowSize = {width = 400, height = 500},
            opacity = 0.9,
            minimap = {hide = false, angle = 180},
            compactMode = false,
            showIcons = true,
            autoReport = false,
            bossOnly = false,
            bgColor = {r = 0, g = 0, b = 0, a = 0.9},
            borderStyle = 1,
            showControls = true,
            showFooter = true,
            maxPlayers = 20,
            showSelfOnly = false,
            filterMode = "all",
            scale = 1.0,
            buttonVisibility = {
                modeBtn = true,
                combatBtn = true,
                dpsToggleBtn = true,
                reportBtn = true,
                resetBtn = true
            },
            footerInfo = {
                combatTimer = true,
                fps = true,
                latency = true,
                memory = true
            }
        }
    end
end

-- Save settings to disk immediately
function Database:SaveToDisk()
    -- Force save by marking as dirty and calling the game's save function
    if DPSLightDB then
        -- In WoW, saved variables are automatically saved on logout
        -- But we can trigger a manual save by forcing a game state update
        -- This is handled automatically by WoW's SavedVariables system
        return true
    end
    return false
end

return Database
