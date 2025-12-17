-- HealingTaken.lua - Healing taken tracking (stub)

local HealingTaken = {}
DPSLight_HealingTaken = HealingTaken

local ModuleBase = DPSLight_ModuleBase

setmetatable(HealingTaken, {__index = ModuleBase})

function HealingTaken:Initialize()
    self.name = "healingTaken"
    self.dataType = "healingTaken"
    self.cache = {}
    self.cacheTime = 0
    self.cacheDuration = 0.5
end

return HealingTaken
