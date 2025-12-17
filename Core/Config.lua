-- Config.lua - Configuration management

local Config = {}
DPSLight_Config = Config

-- Default settings
local defaults = {
    -- Performance
    updateInterval = 0.5,           -- UI update frequency (seconds)
    maxVisibleRows = 15,            -- Virtual scroll window size
    enableObjectPooling = true,     -- Use object pooling
    
    -- Features
    autoStartCombat = true,         -- Auto-start on combat
    autoNewSegment = true,          -- New segment on boss engage
    syncEnabled = true,             -- Raid sync enabled
    syncInterval = 30,              -- Sync frequency (seconds)
    
    -- SuperWoW
    preferSuperWoW = false,         -- Use SuperWoW if available (disabled for now - parser incomplete)
    useSuperWoWEvents = false,      -- Use RAW_COMBATLOG, UNIT_CASTEVENT
    
    -- UI
    windowAlpha = 0.9,
    windowScale = 1.0,
    showMinimap = true,
    lockFrames = false,
    
    -- Display
    showDPS = true,
    showHPS = true,
    showPercent = true,
    numberFormat = "short",         -- "short" or "full"
    
    -- Modules
    enabledModules = {
        damage = true,
        damageTaken = true,
        healing = true,
        healingTaken = true,
        deaths = true,
    },
}

-- Current settings (will be populated from SavedVariables)
local settings = {}

-- Initialize settings
function Config:Initialize()
    -- Load from SavedVariables or use defaults
    if not DPSLightSettings then
        DPSLightSettings = {}
    end
    
    -- Deep copy defaults
    for key, value in pairs(defaults) do
        if DPSLightSettings[key] == nil then
            if type(value) == "table" then
                DPSLightSettings[key] = {}
                for k, v in pairs(value) do
                    DPSLightSettings[key][k] = v
                end
            else
                DPSLightSettings[key] = value
            end
        end
    end
    
    -- FORCE SuperWoW to false (parser not fully implemented)
    DPSLightSettings.preferSuperWoW = false
    DPSLightSettings.useSuperWoWEvents = false
    
    settings = DPSLightSettings
end

-- Get setting value
function Config:Get(key)
    return settings[key]
end

-- Set setting value
function Config:Set(key, value)
    settings[key] = value
    DPSLightSettings[key] = value
end

-- Get nested setting (e.g., "enabledModules.damage")
function Config:GetNested(path)
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end
    
    local value = settings
    for _, key in ipairs(keys) do
        value = value[key]
        if value == nil then return nil end
    end
    
    return value
end

-- Set nested setting
function Config:SetNested(path, value)
    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end
    
    local current = settings
    for i = 1, table.getn(keys) - 1 do
        local key = keys[i]
        if not current[key] then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[table.getn(keys)]] = value
end

-- Reset to defaults
function Config:ResetToDefaults()
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            settings[key] = {}
            for k, v in pairs(value) do
                settings[key][k] = v
            end
        else
            settings[key] = value
        end
    end
end

-- Export settings
function Config:Export()
    local export = {}
    for key, value in pairs(settings) do
        export[key] = value
    end
    return export
end

-- Detect SuperWoW
function Config:IsSuperWoWAvailable()
    return SUPERWOW_VERSION ~= nil
end

-- Get SuperWoW features
function Config:GetSuperWoWFeatures()
    if not self:IsSuperWoWAvailable() then
        return {
            available = false,
            version = nil,
        }
    end
    
    return {
        available = true,
        version = SUPERWOW_VERSION,
        rawCombatLog = true,
        unitCastEvent = true,
        guidSupport = true,
        unitPosition = true,
    }
end

return Config
