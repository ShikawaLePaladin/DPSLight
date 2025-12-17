-- Locales/frFR.lua - French localization

if GetLocale() ~= "frFR" then return end

local L = DPSLight_L or {}
DPSLight_L = L

L["DPSLight"] = "DPSLight"
L["damage"] = "Dégâts"
L["dps"] = "DPS"
L["healing"] = "Soins"
L["hps"] = "SPS"
L["deaths"] = "Morts"
L["damageTaken"] = "Dégâts Subis"
L["healingTaken"] = "Soins Reçus"

-- UI
L["show"] = "Afficher"
L["hide"] = "Masquer"
L["reset"] = "Réinitialiser"
L["config"] = "Configuration"
L["close"] = "Fermer"

-- Stats
L["total"] = "Total"
L["percent"] = "Pourcent"
L["avg"] = "Moyenne"
L["min"] = "Min"
L["max"] = "Max"
L["hits"] = "Coups"
L["crits"] = "Critiques"
L["critPercent"] = "% Crit"

-- Combat
L["current"] = "Combat Actuel"
L["overall"] = "Général"
L["lastFight"] = "Dernier Combat"

-- Messages
L["combatStart"] = "Combat commencé"
L["combatEnd"] = "Combat terminé"
L["newSegment"] = "Nouveau segment démarré"
L["dataReset"] = "Données réinitialisées"
L["syncEnabled"] = "Synchronisation activée"
L["syncDisabled"] = "Synchronisation désactivée"

-- SuperWoW
L["superWowDetected"] = "SuperWoW détecté - parser optimisé activé"
L["superWowNotFound"] = "SuperWoW non trouvé - parser classique activé"

return L
