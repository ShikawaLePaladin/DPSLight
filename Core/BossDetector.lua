-- BossDetector.lua - Detect boss fights and filter targets
local BossDetector = {}
DPSLight_BossDetector = BossDetector

-- Known boss names (will be expanded)
local bossNames = {
    -- Molten Core
    ["Lucifron"] = true,
    ["Magmadar"] = true,
    ["Gehennas"] = true,
    ["Garr"] = true,
    ["Shazzrah"] = true,
    ["Baron Geddon"] = true,
    ["Sulfuron Harbinger"] = true,
    ["Golemagg the Incinerator"] = true,
    ["Majordomo Executus"] = true,
    ["Ragnaros"] = true,
    
    -- Onyxia
    ["Onyxia"] = true,
    
    -- Blackwing Lair
    ["Razorgore the Untamed"] = true,
    ["Vaelastrasz the Corrupt"] = true,
    ["Broodlord Lashlayer"] = true,
    ["Firemaw"] = true,
    ["Ebonroc"] = true,
    ["Flamegor"] = true,
    ["Chromaggus"] = true,
    ["Nefarian"] = true,
    
    -- Zul'Gurub
    ["High Priestess Jeklik"] = true,
    ["High Priest Venoxis"] = true,
    ["High Priestess Mar'li"] = true,
    ["High Priest Thekal"] = true,
    ["High Priestess Arlokk"] = true,
    ["Hakkar"] = true,
    ["Bloodlord Mandokir"] = true,
    ["Gahz'ranka"] = true,
    ["Jin'do the Hexxer"] = true,
    
    -- AQ20
    ["Kurinnaxx"] = true,
    ["Rajaxx"] = true,
    ["Moam"] = true,
    ["Buru the Gorger"] = true,
    ["Ayamiss the Hunter"] = true,
    ["Ossirian the Unscarred"] = true,
    
    -- AQ40
    ["The Prophet Skeram"] = true,
    ["Silithid Royalty"] = true,
    ["Battleguard Sartura"] = true,
    ["Fankriss the Unyielding"] = true,
    ["Viscidus"] = true,
    ["Princess Huhuran"] = true,
    ["Emperor Vek'lor"] = true,
    ["Emperor Vek'nilash"] = true,
    ["Ouro"] = true,
    ["C'Thun"] = true,
    
    -- Naxxramas
    ["Anub'Rekhan"] = true,
    ["Grand Widow Faerlina"] = true,
    ["Maexxna"] = true,
    ["Noth the Plaguebringer"] = true,
    ["Heigan the Unclean"] = true,
    ["Loatheb"] = true,
    ["Instructor Razuvious"] = true,
    ["Gothik the Harvester"] = true,
    ["The Four Horsemen"] = true,
    ["Patchwerk"] = true,
    ["Grobbulus"] = true,
    ["Gluth"] = true,
    ["Thaddius"] = true,
    ["Sapphiron"] = true,
    ["Kel'Thuzad"] = true,
}

-- Detected bosses in current combat
local currentBosses = {}
local bossMode = false

-- Initialize
function BossDetector:Initialize()
    currentBosses = {}
    bossMode = false
end

-- Check if target is a boss
function BossDetector:IsBoss(targetName)
    if not targetName then return false end
    return bossNames[targetName] == true
end

-- Register boss in combat
function BossDetector:RegisterTarget(targetName)
    if self:IsBoss(targetName) then
        currentBosses[targetName] = true
        bossMode = true
    end
end

-- Check if in boss fight
function BossDetector:IsInBossFight()
    return bossMode
end

-- Get current boss name
function BossDetector:GetCurrentBoss()
    for bossName, _ in pairs(currentBosses) do
        return bossName
    end
    return nil
end

-- Reset boss detection
function BossDetector:Reset()
    currentBosses = {}
    bossMode = false
end

-- Add custom boss
function BossDetector:AddBoss(bossName)
    if bossName and bossName ~= "" then
        bossNames[bossName] = true
    end
end

-- Get all boss names
function BossDetector:GetBossNames()
    return bossNames
end

return BossDetector
