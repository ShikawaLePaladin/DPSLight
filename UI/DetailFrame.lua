-- DetailFrame.lua - Detailed breakdown window
local DetailFrame = {}
DPSLight_DetailFrame = DetailFrame

local frame = nil
local scrollList = nil
local currentUserID = nil
local currentModule = nil

-- Lazy load
local function GetDamage() return DPSLight_Damage end
local function GetHealing() return DPSLight_Healing end
local function GetUtils() return DPSLight_Utils end
local function GetVirtualScroll() return DPSLight_VirtualScroll end
local function GetDataStore() return DPSLight_DataStore end

-- Create detail frame
function DetailFrame:Create()
    if frame then return frame end

    local Database = DPSLight_Database
    local opacity = Database and Database:GetSetting("opacity") or 0.9
    local borderStyle = Database and Database:GetSetting("borderStyle") or 1
    local bgColor = Database and Database:GetSetting("bgColor") or {r=0, g=0, b=0, a=opacity}

    -- Border styles mapping (matching MainFrame exactly)
    local borders = {
        {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16},
        {edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32},
        {edgeFile = "Interface\\GLUES\\COMMON\\TextPanel-Border", edgeSize = 16},
        {edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border", edgeSize = 12},
        {edgeFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-WoodBorder", edgeSize = 32},
        {edgeFile = "Interface\\COMMON\\Indicator-Gray", edgeSize = 8},
    }
    local border = borders[borderStyle] or borders[1]

    frame = CreateFrame("Frame", "DPSLight_DetailWindow", UIParent)
    frame:SetWidth(450)
    frame:SetHeight(400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")

    -- Backdrop with unified style (matching MainFrame exactly)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = border.edgeFile,
        tile = true,
        tileSize = 16,
        edgeSize = border.edgeSize,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, opacity)
    frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    -- Title bar (unified style with MainFrame)
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(24)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 16,
    })
    titleBar:SetBackdropColor(0.1, 0.3, 0.5, 1)

    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    title:SetText("Ability Details")
    frame.title = title

    -- Make draggable
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", 2, 0)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Toggle /s button (Per Second toggle)
    frame.showPerSecond = true
    local toggleBtn = CreateFrame("Button", nil, titleBar)
    toggleBtn:SetWidth(28)
    toggleBtn:SetHeight(18)
    toggleBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    toggleBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    toggleBtn:SetBackdropColor(0.2, 0.7, 0.3, 1)
    local toggleText = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toggleText:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)
    toggleText:SetText("/s")
    toggleText:SetTextColor(0, 1, 0)
    toggleBtn:SetScript("OnClick", function()
        frame.showPerSecond = not frame.showPerSecond
        if frame.showPerSecond then
            toggleText:SetText("/s")
            toggleText:SetTextColor(0, 1, 0)
        else
            toggleText:SetText("T")
            toggleText:SetTextColor(1, 0.82, 0)
        end
        DetailFrame:Refresh()
    end)
    toggleBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        if frame.showPerSecond then
            GameTooltip:AddLine("Per Second (/s)", 1, 1, 1)
            GameTooltip:AddLine("Click for Total", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Total (T)", 1, 1, 1)
            GameTooltip:AddLine("Click for Per Second", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    toggleBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.toggleBtn = toggleBtn

    -- Stats header
    local statsHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsHeader:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -8)
    statsHeader:SetJustifyH("LEFT")
    frame.statsHeader = statsHeader

    -- Create scroll list for abilities
    local VirtualScroll = GetVirtualScroll()
    if VirtualScroll then
        scrollList = VirtualScroll:New(frame, 430, 300, 15)
        scrollList:GetFrame():SetPoint("TOPLEFT", statsHeader, "BOTTOMLEFT", 0, -8)
    end

    frame:Hide()
    return frame
end

-- Show detail window for a user
function DetailFrame:Show(userID, moduleName)
    if not frame then
        self:Create()
    end

    -- Update style to match main window settings
    local MainFrame = DPSLight_MainFrame
    if MainFrame and MainFrame.UpdateSecondaryWindowsStyle then
        MainFrame:UpdateSecondaryWindowsStyle()
    end

    currentUserID = userID
    currentModule = moduleName or "damage"

    self:UpdateDisplay()
    frame:Show()
end

-- Update display
function DetailFrame:UpdateDisplay()
    if not frame or not currentUserID then return end

    local DataStore = GetDataStore()
    local Utils = GetUtils()

    if not DataStore or not Utils then return end

    local username = DataStore:GetUsername(currentUserID)

    -- Update title
    frame.title:SetText(username .. " - Abilities")

    local data = {}

    if currentModule == "damage" then
        local Damage = GetDamage()
        if not Damage then return end

        local abilities = Damage:GetAbilityBreakdown(nil, currentUserID)
        local total = Damage:GetTotal(nil, currentUserID)
        local dps = Damage:GetDPS(nil, currentUserID)

        -- Update stats header with toggle (Total / DPS)
        if frame.showPerSecond then
            frame.statsHeader:SetText(string.format(
                "DPS: %s | Total: %s",
                Utils:FormatNumber(dps),
                Utils:FormatNumber(total)
            ))
        else
            frame.statsHeader:SetText(string.format(
                "Total: %s | DPS: %s",
                Utils:FormatNumber(total),
                Utils:FormatNumber(dps)
            ))
        end

        -- Build ability list
        for i, ability in ipairs(abilities) do
            local percent = (ability.total / total) * 100

            table.insert(data, {
                name = ability.name,
                value = ability.total,
                percent = percent,
                color = {0.8, 0.2, 0.2},
                tooltip = {
                    name = ability.name,
                    details = {
                        string.format("Total: %s (%.1f%%)", Utils:FormatNumber(ability.total), percent),
                        string.format("Hits: %d | Crits: %d (%.1f%%)", ability.hits, ability.crits, ability.critPercent),
                        string.format("Min: %s | Max: %s | Avg: %s",
                            Utils:FormatNumber(ability.min),
                            Utils:FormatNumber(ability.max),
                            Utils:FormatNumber(ability.avg))
                    }
                }
            })
        end

    elseif currentModule == "healing" then
        local Healing = GetHealing()
        if not Healing then return end

        local abilities = Healing:GetAbilityBreakdown(nil, currentUserID)
        local total = Healing:GetTotal(nil, currentUserID)
        local hps = Healing:GetHPS(nil, currentUserID)

        -- Update stats header with toggle (Total / HPS)
        if frame.showPerSecond then
            frame.statsHeader:SetText(string.format(
                "HPS: %s | Total: %s",
                Utils:FormatNumber(hps),
                Utils:FormatNumber(total)
            ))
        else
            frame.statsHeader:SetText(string.format(
                "Total: %s | HPS: %s",
                Utils:FormatNumber(total),
                Utils:FormatNumber(hps)
            ))
        end

        -- Build ability list
        for i, ability in ipairs(abilities) do
            local percent = (ability.total / total) * 100

            table.insert(data, {
                name = ability.name,
                value = ability.total,
                percent = percent,
                color = {0.2, 0.8, 0.2},
                tooltip = {
                    name = ability.name,
                    details = {
                        string.format("Total: %s (%.1f%%)", Utils:FormatNumber(ability.total), percent),
                        string.format("Hits: %d | Crits: %d (%.1f%%)", ability.hits, ability.crits, ability.critPercent),
                        string.format("Avg: %s", Utils:FormatNumber(ability.avg))
                    }
                }
            })
        end
    end

    if scrollList then
        scrollList:SetData(data)
    end
end

-- Hide frame
function DetailFrame:Hide()
    if frame then
        frame:Hide()
    end
end

-- Toggle frame
function DetailFrame:Toggle()
    if frame and frame:IsVisible() then
        self:Hide()
    else
        self:Show(currentUserID, currentModule)
    end
end

-- Refresh display (called by toggle button)
function DetailFrame:Refresh()
    self:UpdateDisplay()
end

-- Get frame reference
function DetailFrame:GetFrame()
    return frame
end

return DetailFrame
