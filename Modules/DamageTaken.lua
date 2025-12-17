-- DamageTaken.lua - Damage taken tracking (stub)

local DamageTaken = {}
DPSLight_DamageTaken = DamageTaken

local ModuleBase = DPSLight_ModuleBase

setmetatable(DamageTaken, {__index = ModuleBase})

function DamageTaken:Initialize()
    self.name = "damageTaken"
    self.dataType = "damageTaken"
    self.cache = {}
    self.cacheTime = 0
    self.cacheDuration = 0.5
end

return DamageTaken
