-- ClassIcons.lua - Class icon textures mapping
local ClassIcons = {}
DPSLight_ClassIcons = ClassIcons

-- Class icon texture paths
local ICON_COORDS = {
    WARRIOR = {0, 0.25, 0, 0.25},
    MAGE = {0.25, 0.5, 0, 0.25},
    ROGUE = {0.5, 0.75, 0, 0.25},
    DRUID = {0.75, 1, 0, 0.25},
    HUNTER = {0, 0.25, 0.25, 0.5},
    SHAMAN = {0.25, 0.5, 0.25, 0.5},
    PRIEST = {0.5, 0.75, 0.25, 0.5},
    WARLOCK = {0.75, 1, 0.25, 0.5},
    PALADIN = {0, 0.25, 0.5, 0.75},
}

-- Get class icon texture coordinates
function ClassIcons:GetCoords(class)
    class = string.upper(class or "")
    return ICON_COORDS[class] or {0, 1, 0, 1}
end

-- Set class icon on texture
function ClassIcons:SetIcon(texture, class)
    if not texture then return end
    
    texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    
    local coords = self:GetCoords(class)
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end

return ClassIcons
