-- MainFrame.lua - Main DPSLight window
-- @module DPSLight_MainFrame
-- @description Main display window with virtual scrolling, mode switching, and filtering

local MainFrame = {}
DPSLight_MainFrame = MainFrame

-- Main frame reference
local frame = nil
local scrollList = nil
local currentMode = "damage" -- damage, healing, deaths, dispels, decurse
local showPerSecond = true -- true = DPS/HPS, false = Total
local updateTimer = 0

-- Display filters (module-level variables, reloaded via ReloadSettings)
local maxPlayersToShow = 20  -- Max number of players to display
local showSelfOnly = false   -- Only show player's own stats
local filterMode = "all"     -- "all", "group", "raid"

---Reloads settings from database into module-level variables
---@description Must be called after Database:SetSetting() to apply changes
---@usage Database:SetSetting("maxPlayers", 30) → MainFrame:ReloadSettings() → MainFrame:UpdateDisplay()
function MainFrame:ReloadSettings()
    local Database = DPSLight_Database
    if not Database then return end

    local savedMaxPlayers = Database:GetSetting("maxPlayers")
    if savedMaxPlayers then
        maxPlayersToShow = savedMaxPlayers
    end

    local savedFilterMode = Database:GetSetting("filterMode")
    if savedFilterMode then
        filterMode = savedFilterMode
    end

    local savedShowSelfOnly = Database:GetSetting("showSelfOnly")
    if savedShowSelfOnly ~= nil then
        showSelfOnly = savedShowSelfOnly
    end
end

-- Apply unified style to a frame (for secondary windows)
local function ApplyUnifiedStyle(targetFrame)
    if not targetFrame then return end
    local Database = DPSLight_Database
    if not Database then return end

    -- Get settings from database (same as main window)
    local opacity = Database:GetSetting("opacity") or 0.9
    local borderStyle = Database:GetSetting("borderStyle") or 1
    local bgColor = Database:GetSetting("bgColor") or {r=0, g=0, b=0, a=opacity}

    -- Border styles mapping (with corresponding edgeSize)
    local borders = {
        {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16},
        {edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32},
        {edgeFile = "Interface\\GLUES\\COMMON\\TextPanel-Border", edgeSize = 16},
        {edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border", edgeSize = 12},
        {edgeFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-WoodBorder", edgeSize = 32},
        {edgeFile = "Interface\\COMMON\\Indicator-Gray", edgeSize = 8},
    }

    local border = borders[borderStyle] or borders[1]

    -- Apply backdrop with unified style
    targetFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = border.edgeFile,
        tile = true,
        tileSize = 16,
        edgeSize = border.edgeSize,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })

    -- Apply colors with opacity
    targetFrame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, opacity)
    targetFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
end

-- Public function to update all secondary windows
function MainFrame:UpdateSecondaryWindowsStyle()
    -- Update DetailFrame
    local DetailFrame = DPSLight_DetailFrame
    if DetailFrame and DetailFrame.GetFrame then
        local detailFrame = DetailFrame:GetFrame()
        if detailFrame then
            ApplyUnifiedStyle(detailFrame)
        end
    end

    -- Update CombatHistory
    if frame and frame.combatHistory then
        ApplyUnifiedStyle(frame.combatHistory)
    end

    -- Update CombatDetail
    if frame and frame.combatDetail then
        ApplyUnifiedStyle(frame.combatDetail)
    end
end

-- Row constants (must match VirtualScroll.lua)
local ROW_HEIGHT = 18
local ROW_SPACING = 2

-- Get module references (lazy loaded)
local function GetVirtualScroll()
    return DPSLight_VirtualScroll
end

local function GetUtils()
    return DPSLight_Utils
end

local function GetConfig()
    return DPSLight_Config
end

local function GetDamage()
    return DPSLight_Damage
end

local function GetHealing()
    return DPSLight_Healing
end

-- Create main frame
function MainFrame:Create()
    if frame then return frame end

    local Database = DPSLight_Database

    -- Create main window
    frame = CreateFrame("Frame", "DPSLight_MainWindow", UIParent)

    -- Restore saved position and size
    local savedSize = Database and Database:GetSetting("windowSize")
    local savedPos = Database and Database:GetSetting("windowPos")

    local width = savedSize and savedSize.width or 350
    local height = savedSize and savedSize.height or 450  -- Augmenté de 400 à 450

    frame:SetWidth(width)
    frame:SetHeight(height)

    if savedPos and savedPos.x ~= 0 then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedPos.x, savedPos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetMinResize(200, 200)  -- Réduit de 250 à 200
    frame:SetMaxResize(1200, 800)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    -- Load saved settings
    local bgColor = Database and Database:GetSetting("bgColor") or {r = 0, g = 0, b = 0, a = 0.9}
    local borderStyle = Database and Database:GetSetting("borderStyle") or 1
    local showControls = Database and Database:GetSetting("showControls")
    if showControls == nil then showControls = true end
    local showFooter = Database and Database:GetSetting("showFooter")
    if showFooter == nil then showFooter = true end

    -- Load max players and filter settings
    local savedMaxPlayers = Database and Database:GetSetting("maxPlayers")
    if savedMaxPlayers then
        maxPlayersToShow = savedMaxPlayers
    end

    local savedFilterMode = Database and Database:GetSetting("filterMode")
    if savedFilterMode then
        filterMode = savedFilterMode
    end

    local savedShowSelfOnly = Database and Database:GetSetting("showSelfOnly")
    if savedShowSelfOnly ~= nil then
        showSelfOnly = savedShowSelfOnly
    end

    -- Border styles (MUST match ApplyUnifiedStyle exactly!)
    local borders = {
        {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16},
        {edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32},
        {edgeFile = "Interface\\GLUES\\COMMON\\TextPanel-Border", edgeSize = 16},
        {edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border", edgeSize = 12},
        {edgeFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-WoodBorder", edgeSize = 32},
        {edgeFile = "Interface\\COMMON\\Indicator-Gray", edgeSize = 8},
    }

    local border = borders[borderStyle] or borders[1]
    local opacity = Database and Database:GetSetting("opacity") or 0.9

    -- Apply backdrop with unified style (MUST match ApplyUnifiedStyle exactly!)
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

    -- Draggable area (top of frame, no visible title)
    local dragArea = CreateFrame("Frame", nil, frame)
    dragArea:SetHeight(10)
    dragArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    dragArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    dragArea:EnableMouse(true)
    dragArea:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    dragArea:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()

        -- Apply window snapping
        if SnapToNearbyWindows then
            SnapToNearbyWindows(frame)
        end

        -- Save position
        local Database = DPSLight_Database
        if Database then
            local point, _, _, x, y = frame:GetPoint()
            Database:SetSetting("windowPos", {x = x, y = y})
        end
    end)

    -- Close button (top right corner - always visible)
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetWidth(24)
    closeBtn:SetHeight(24)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.closeBtn = closeBtn

    -- Function to update layout on resize
    local function UpdateLayout()
        local width = frame:GetWidth()
        local height = frame:GetHeight()

        -- Adapt button layout based on window width
        if modeBtn and combatBtn and dpsToggleBtn and reportBtn then
            -- Calculate total button width
            local buttonSpacing = 4
            local totalButtonWidth = modeBtn:GetWidth() + combatBtn:GetWidth() + dpsToggleBtn:GetWidth() + reportBtn:GetWidth() + (buttonSpacing * 3)

            -- If window too narrow, adjust button sizes proportionally
            local availableWidth = width - 45  -- Accounting for margins and close button
            if totalButtonWidth > availableWidth and availableWidth > 100 then
                local scale = availableWidth / totalButtonWidth

                -- Resize buttons proportionally (minimum sizes)
                local modeBtnW = math.max(60, modeBtn:GetWidth() * scale)
                local combatBtnW = math.max(20, combatBtn:GetWidth() * scale)
                local dpsToggleBtnW = math.max(24, dpsToggleBtn:GetWidth() * scale)
                local reportBtnW = math.max(26, reportBtn:GetWidth() * scale)

                modeBtn:SetWidth(modeBtnW)
                combatBtn:SetWidth(combatBtnW)
                dpsToggleBtn:SetWidth(dpsToggleBtnW)
                reportBtn:SetWidth(reportBtnW)
            end
        end

        -- Update scroll list size (dynamic calculation)
        if scrollList then
            local scrollWidth = width - 20
            local headerSpace = 35  -- Button row height
            local footerSpace = 30  -- Footer height
            local scrollHeight = height - headerSpace - footerSpace

            -- Minimum scroll area
            if scrollWidth < 200 then scrollWidth = 200 end
            if scrollHeight < 100 then scrollHeight = 100 end

            -- Calculate max visible rows based on available height
            local ROW_HEIGHT = 18
            local ROW_SPACING = 2
            local rowSize = ROW_HEIGHT + ROW_SPACING
            local maxRows = math.floor(scrollHeight / rowSize)
            if maxRows < 5 then maxRows = 5 end

            -- Update scroll list properties
            scrollList.maxVisibleRows = maxRows
            scrollList.height = scrollHeight
            scrollList:GetFrame():SetWidth(scrollWidth)
            scrollList:GetFrame():SetHeight(scrollHeight)

            -- Update scrollbar range
            local totalRows = scrollList.totalRows or 0
            if totalRows > maxRows then
                scrollList.scrollBar:SetMinMaxValues(0, totalRows - maxRows)
                scrollList.scrollBar:Show()
            else
                scrollList.scrollBar:SetMinMaxValues(0, 0)
                scrollList.scrollBar:Hide()
            end

            if scrollList.UpdateAll then
                scrollList:UpdateAll()  -- Force redraw
            end
        end

        -- Update footer position
        if frame.footer then
            frame.footer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
        end

        -- Save size
        local Database = DPSLight_Database
        if Database then
            Database:SetSetting("windowSize", {width = width, height = height})
        end
    end

    -- Resize button (bottom-right corner)
    local resizeBtn = CreateFrame("Button", nil, frame)
    resizeBtn:SetWidth(16)
    resizeBtn:SetHeight(16)
    resizeBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeBtn:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()

        -- Apply window snapping
        if SnapToNearbyWindows then
            SnapToNearbyWindows(frame)
        end

        UpdateLayout()
    end)

    -- Update on manual resize
    frame:SetScript("OnSizeChanged", function()
        UpdateLayout()
    end)

    -- Mode cycle button (first button, anchored to frame)
    local modeBtn = CreateFrame("Button", nil, frame)
    modeBtn:SetWidth(85)
    modeBtn:SetHeight(20)
    modeBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)

    modeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    modeBtn:SetBackdropColor(0.2, 0.5, 0.2, 1)

    local modeBtnText = modeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeBtnText:SetPoint("CENTER", modeBtn, "CENTER", 0, 0)
    modeBtnText:SetText("Damage")
    modeBtn.text = modeBtnText

    local modeOrder = {"damage", "healing", "dispels", "decurse", "deaths"}
    local modeLabels = {
        damage = "Damage",
        healing = "Healing",
        dispels = "Dispels",
        decurse = "Decurse",
        deaths = "Deaths"
    }

    modeBtn:SetScript("OnClick", function()
        -- Find next mode
        local currentIndex = 1
        for i, mode in ipairs(modeOrder) do
            if mode == currentMode then
                currentIndex = i
                break
            end
        end

        local nextIndex = currentIndex + 1
        if nextIndex > table.getn(modeOrder) then
            nextIndex = 1
        end

        currentMode = modeOrder[nextIndex]
        this.text:SetText(modeLabels[currentMode])
        MainFrame:UpdateDisplay()
    end)

    modeBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine("Click to cycle modes", 1, 1, 1)
        GameTooltip:AddLine("Current: " .. modeLabels[currentMode], 0.5, 1, 0.5)
        GameTooltip:Show()
    end)
    modeBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.modeBtn = modeBtn

    -- Combat history button "C" (second button, relative to mode button)
    local combatBtn = CreateFrame("Button", nil, frame)
    combatBtn:SetWidth(22)
    combatBtn:SetHeight(22)
    combatBtn:SetPoint("LEFT", modeBtn, "RIGHT", 4, 0)
    combatBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    combatBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    combatBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    local combatBtnText = combatBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    combatBtnText:SetPoint("CENTER", combatBtn, "CENTER", 0, 0)
    combatBtnText:SetText("C")
    combatBtnText:SetTextColor(1, 0.82, 0)
    combatBtn:SetScript("OnClick", function()
        MainFrame:ShowCombatHistory()
    end)
    combatBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Combat History", 1, 1, 1)
        GameTooltip:AddLine("Click to view past combats", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    combatBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.combatBtn = combatBtn

    -- DPS/Total toggle button (third button, relative to C button)
    local dpsToggleBtn = CreateFrame("Button", nil, frame)
    dpsToggleBtn:SetWidth(28)
    dpsToggleBtn:SetHeight(22)
    dpsToggleBtn:SetPoint("LEFT", combatBtn, "RIGHT", 2, 0)
    dpsToggleBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    dpsToggleBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    dpsToggleBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    local dpsToggleText = dpsToggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dpsToggleText:SetPoint("CENTER", dpsToggleBtn, "CENTER", 0, 0)
    dpsToggleText:SetText("/s")
    dpsToggleText:SetTextColor(0, 1, 0)
    dpsToggleBtn:SetScript("OnClick", function()
        showPerSecond = not showPerSecond
        if showPerSecond then
            dpsToggleText:SetText("/s")
            dpsToggleText:SetTextColor(0, 1, 0)
        else
            dpsToggleText:SetText("T")
            dpsToggleText:SetTextColor(1, 0.82, 0)
        end
        MainFrame:UpdateDisplay()
    end)
    dpsToggleBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        if showPerSecond then
            GameTooltip:AddLine("Per Second (/s)", 1, 1, 1)
            GameTooltip:AddLine("Click for Total", 0.5, 0.5, 0.5)
        else
            GameTooltip:AddLine("Total (T)", 1, 1, 1)
            GameTooltip:AddLine("Click for Per Second", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    dpsToggleBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.dpsToggleBtn = dpsToggleBtn

    -- Report button (fourth button, relative to DPS/Total button)
    local reportBtn = CreateFrame("Button", nil, frame)
    reportBtn:SetWidth(32)
    reportBtn:SetHeight(22)
    reportBtn:SetPoint("LEFT", dpsToggleBtn, "RIGHT", 2, 0)

    reportBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    reportBtn:SetBackdropColor(0.3, 0.6, 1, 1)

    local reportBtnText = reportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reportBtnText:SetPoint("CENTER", reportBtn, "CENTER", 0, 0)
    reportBtnText:SetText("R")

    reportBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    reportBtn:SetScript("OnClick", function()
        MainFrame:ShowReportMenu()
    end)

    reportBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Report Stats", 1, 1, 1)
        GameTooltip:AddLine("Right-click for channel menu", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    reportBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.reportBtn = reportBtn

    -- Reset button (fifth button - clear data)
    local resetBtn = CreateFrame("Button", nil, frame)
    resetBtn:SetWidth(22)
    resetBtn:SetHeight(22)
    resetBtn:SetPoint("LEFT", reportBtn, "RIGHT", 2, 0)

    resetBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    resetBtn:SetBackdropColor(0.6, 0.2, 0.2, 1)

    local resetBtnText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetBtnText:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    resetBtnText:SetText("X")

    resetBtn:SetScript("OnClick", function()
        local DataStore = DPSLight_DataStore
        if not DataStore then return end

        -- Reset data for current segment
        DataStore:ClearSegment()
        MainFrame:UpdateDisplay()
        DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Data reset for current segment", 1, 1, 0)
    end)

    resetBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Reset Data", 1, 1, 1)
        local modeLabels = {
            damage = "Damage",
            healing = "Healing",
            dispels = "Dispels",
            decurse = "Decurse",
            deaths = "Deaths"
        }
        GameTooltip:AddLine("Clear stats for " .. (modeLabels[currentMode] or "current mode"), 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    resetBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.resetBtn = resetBtn

    -- Create scroll list (positioned BELOW controls, dynamically sized)
    local VirtualScroll = GetVirtualScroll()
    if VirtualScroll then
        -- Initial size will be updated by UpdateLayout
        local initialWidth = 330
        local initialHeight = 380
        local initialMaxRows = math.floor(initialHeight / (ROW_HEIGHT + ROW_SPACING))
        if initialMaxRows < 5 then initialMaxRows = 5 end

        scrollList = VirtualScroll:New(frame, initialWidth, initialHeight, initialMaxRows)
        if scrollList then
            scrollList:GetFrame():SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)
        end
    end

    -- Info footer (dynamic content based on settings)
    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    footer:SetPoint("LEFT", frame, "LEFT", 5, 10)
    footer:SetPoint("RIGHT", frame, "RIGHT", -5, 10)
    footer:SetJustifyH("CENTER")
    footer:SetText("DPSLight v1.1")
    frame.footer = footer

    -- Update footer function
    local function UpdateFooter()
        local Database = DPSLight_Database
        if not Database then return end

        local footerInfo = Database:GetSetting("footerInfo") or {}
        local parts = {}

        if footerInfo.combatTimer then
            local Utils = DPSLight_Utils
            if Utils then
                local duration = Utils:GetCombatDuration() or 0
                local mins = math.floor(duration / 60)
                local secs = duration - (mins * 60)
                table.insert(parts, string.format("Combat: %d:%02d", mins, secs))
            end
        end

        if footerInfo.fps then
            table.insert(parts, string.format("FPS: %d", GetFramerate()))
        end

        if footerInfo.latency then
            local _, _, lag = GetNetStats()
            table.insert(parts, string.format("Latency: %dms", lag))
        end

        if footerInfo.memory then
            local mem = gcinfo()
            table.insert(parts, string.format("Mem: %.1fMB", mem / 1024))
        end

        if table.getn(parts) == 0 then
            footer:SetText("DPSLight v1.1")
        else
            -- Limit text width to prevent overflow
            local text = table.concat(parts, " | ")
            footer:SetText(text)
        end
    end
    frame.UpdateFooter = UpdateFooter

    -- Apply saved button visibility settings
    local buttonVisibility = Database and Database:GetSetting("buttonVisibility") or {}
    if buttonVisibility.modeBtn == false and frame.modeBtn then
        frame.modeBtn:Hide()
    end
    if buttonVisibility.combatBtn == false and frame.combatBtn then
        frame.combatBtn:Hide()
    end
    if buttonVisibility.dpsToggleBtn == false and frame.dpsToggleBtn then
        frame.dpsToggleBtn:Hide()
    end
    if buttonVisibility.reportBtn == false and frame.reportBtn then
        frame.reportBtn:Hide()
    end
    if buttonVisibility.resetBtn == false and frame.resetBtn then
        frame.resetBtn:Hide()
    end

    -- Apply showControls setting (hide all buttons if false)
    if not showControls then
        if frame.modeBtn then frame.modeBtn:Hide() end
        if frame.combatBtn then frame.combatBtn:Hide() end
        if frame.dpsToggleBtn then frame.dpsToggleBtn:Hide() end
        if frame.reportBtn then frame.reportBtn:Hide() end
        if frame.resetBtn then frame.resetBtn:Hide() end
    end

    -- Apply showFooter setting
    if not showFooter and frame.footer then
        frame.footer:Hide()
    end

    -- Update timer
    frame:SetScript("OnUpdate", function()
        updateTimer = updateTimer + arg1
        local Config = GetConfig()
        local interval = Config and Config.Get and Config:Get("updateInterval") or 0.5

        if updateTimer >= interval then
            MainFrame:UpdateDisplay()
            updateTimer = 0
        end
    end)

    return frame
end

-- Initialize main window for snapping
function MainFrame:InitializeForSnapping()
    if frame then
        if not DPSLight_AllWindows then
            DPSLight_AllWindows = {}
        end

        -- Check if not already in table
        local alreadyExists = false
        for _, existingFrame in ipairs(DPSLight_AllWindows) do
            if existingFrame == frame then
                alreadyExists = true
                break
            end
        end

        if not alreadyExists then
            table.insert(DPSLight_AllWindows, frame)
        end
    end
end

-- Set display mode
function MainFrame:SetMode(mode)
    currentMode = mode

    local modeLabels = {
        damage = "Damage",
        healing = "Healing",
        dispels = "Dispels",
        decurse = "Decurse",
        deaths = "Deaths"
    }

    if frame and frame.modeBtn and frame.modeBtn.text then
        frame.modeBtn.text:SetText(modeLabels[mode] or "Damage")
    end

    self:UpdateDisplay()
end

-- Show report menu
function MainFrame:ShowReportMenu()
    if not frame then return end

    local Reporter = DPSLight_Reporter
    if not Reporter then return end

    -- Show simple menu (EasyMenu doesn't exist in 1.12.1)
    if not frame.reportMenu then
        frame.reportMenu = CreateFrame("Frame", "DPSLight_ReportMenu", UIParent)
        frame.reportMenu:SetWidth(180)
        frame.reportMenu:SetHeight(220)
        frame.reportMenu:SetFrameStrata("FULLSCREEN_DIALOG")  -- Highest strata for visibility
        frame.reportMenu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        frame.reportMenu:SetBackdropColor(0, 0, 0, 1)  -- Fully opaque background
        frame.reportMenu:SetBackdropBorderColor(1, 0.8, 0, 1)  -- Gold border for visibility
        frame.reportMenu:EnableMouse(true)
        frame.reportMenu:Hide()

        local yOffset = -10
        local buttons = {
            {text = "Raid (/raid)", channel = "RAID"},
            {text = "Party (/p)", channel = "PARTY"},
            {text = "Guild (/g)", channel = "GUILD"},
            {text = "Say (/s)", channel = "SAY"},
            {text = "Whisper (/w)", channel = "WHISPER"},
        }

        for i, btnData in ipairs(buttons) do
            local btn = CreateFrame("Button", nil, frame.reportMenu)
            btn:SetWidth(150)
            btn:SetHeight(25)
            btn:SetPoint("TOP", frame.reportMenu, "TOP", 0, yOffset)

            -- Button backdrop with hover effect
            btn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = {left = 4, right = 4, top = 4, bottom = 4}
            })
            btn:SetBackdropColor(0.2, 0.2, 0.2, 1)

            -- Create text for button
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btnText:SetText(btnData.text)

            -- Hover effects (save btnData in button)
            btn.btnData = btnData
            btn:SetScript("OnEnter", function()
                this:SetBackdropColor(0.4, 0.4, 0.8, 1)
                if this.btnData then
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Click to report to " .. this.btnData.channel, 1, 1, 1)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function()
                this:SetBackdropColor(0.2, 0.2, 0.2, 1)
                GameTooltip:Hide()
            end)

            btn:SetScript("OnClick", function()
                if not btnData then return end
                if btnData.channel == "WHISPER" then
                    -- Show whisper target popup
                    frame.reportMenu:Hide()
                    if not frame.whisperPopup then
                        local popup = CreateFrame("Frame", "DPSLight_WhisperPopup", UIParent)
                        popup:SetWidth(250)
                        popup:SetHeight(100)
                        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                        popup:SetFrameStrata("DIALOG")
                        popup:SetBackdrop({
                            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                            tile = true, tileSize = 32, edgeSize = 32,
                            insets = {left = 8, right = 8, top = 8, bottom = 8}
                        })
                        popup:SetBackdropColor(0, 0, 0, 0.9)
                        popup:Hide()

                        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        title:SetPoint("TOP", popup, "TOP", 0, -15)
                        title:SetText("Whisper Target:")

                        local editbox = CreateFrame("EditBox", nil, popup)
                        editbox:SetWidth(200)
                        editbox:SetHeight(20)
                        editbox:SetPoint("TOP", popup, "TOP", 0, -40)
                        editbox:SetFontObject(GameFontHighlight)
                        editbox:SetAutoFocus(true)
                        editbox:SetBackdrop({
                            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                            tile = true, tileSize = 16, edgeSize = 16,
                            insets = {left = 4, right = 4, top = 4, bottom = 4}
                        })
                        editbox:SetBackdropColor(0, 0, 0, 0.8)
                        editbox:SetScript("OnEnterPressed", function()
                            local target = this:GetText()
                            if target and target ~= "" then
                                local mode = frame.currentMode or "damage"
                                Reporter:SendReport("WHISPER", mode, 5, target)
                            end
                            popup:Hide()
                            this:SetText("")
                        end)
                        editbox:SetScript("OnEscapePressed", function()
                            popup:Hide()
                            this:SetText("")
                        end)

                        popup.editbox = editbox
                        frame.whisperPopup = popup
                    end
                    frame.whisperPopup:Show()
                else
                    -- Get current mode from MainFrame
                    local mode = frame.currentMode or "damage"
                    Reporter:SendReport(btnData.channel, mode, 5)
                    frame.reportMenu:Hide()
                end
            end)
            yOffset = yOffset - 30
        end

        -- Add title at top
        local title = frame.reportMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", frame.reportMenu, "TOP", 0, -15)
        title:SetText("Report to Channel")
        title:SetTextColor(1, 0.8, 0, 1)

        frame.reportMenu:SetHeight(-yOffset + 30)  -- Dynamic height based on buttons
    end

    if frame.reportMenu:IsVisible() then
        frame.reportMenu:Hide()
    else
        -- Position menu near report button, not at cursor
        local reportBtn = frame.reportBtn
        if reportBtn then
            frame.reportMenu:ClearAllPoints()
            frame.reportMenu:SetPoint("TOPLEFT", reportBtn, "BOTTOMLEFT", 0, -5)
        else
            -- Fallback to cursor position
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            frame.reportMenu:ClearAllPoints()
            frame.reportMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
        end
        frame.reportMenu:Show()

        -- Close menu on any click outside (stays open otherwise)
        frame.reportMenu:EnableMouse(true)
        frame.reportMenu:SetScript("OnUpdate", function()
            -- Check if mouse button is down and mouse is NOT over menu
            if arg1 and not MouseIsOver(this) then
                -- User clicked outside, close menu
                this:Hide()
            end
        end)
    end
end

-- Show config menu
function MainFrame:ShowConfigMenu()
    if not frame then return end

    -- Create config frame if it doesn't exist
    if not frame.configFrame then
        local cf = CreateFrame("Frame", "DPSLight_ConfigFrame", UIParent)
        cf:SetWidth(320)
        cf:SetHeight(450)
        cf:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        cf:SetFrameStrata("DIALOG")
        cf:SetMovable(true)
        cf:EnableMouse(true)
        cf:SetResizable(true)
        cf:SetMinResize(250, 350)  -- Réduit de 280x400
        cf:SetMaxResize(500, 800)

        cf:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = {left = 8, right = 8, top = 8, bottom = 8}
        })
        cf:SetBackdropColor(0, 0, 0, 0.9)

        -- Title
        local title = cf:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", cf, "TOP", 0, -15)
        title:SetText("DPSLight Configuration")

        -- Draggable
        local titleBg = CreateFrame("Frame", nil, cf)
        titleBg:SetHeight(30)
        titleBg:SetPoint("TOPLEFT", cf, "TOPLEFT", 8, -8)
        titleBg:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -8, -8)
        titleBg:EnableMouse(true)
        titleBg:SetScript("OnMouseDown", function() cf:StartMoving() end)
        titleBg:SetScript("OnMouseUp", function() cf:StopMovingOrSizing() end)

        -- Close button (increased size for better clicking)
        local closeBtn = CreateFrame("Button", nil, cf)
        closeBtn:SetWidth(32)
        closeBtn:SetHeight(32)
        closeBtn:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -2, -2)
        closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
        closeBtn:SetScript("OnClick", function() cf:Hide() end)

        -- Resize button for config
        local resizeBtnCf = CreateFrame("Button", nil, cf)
        resizeBtnCf:SetWidth(16)
        resizeBtnCf:SetHeight(16)
        resizeBtnCf:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", -2, 2)
        resizeBtnCf:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeBtnCf:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeBtnCf:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeBtnCf:SetScript("OnMouseDown", function() cf:StartSizing("BOTTOMRIGHT") end)
        resizeBtnCf:SetScript("OnMouseUp", function() cf:StopMovingOrSizing() end)

        -- Scroll frame for options
        local scrollFrame = CreateFrame("ScrollFrame", nil, cf)
        scrollFrame:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -45)
        scrollFrame:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", -30, 10)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(270)
        scrollChild:SetHeight(1400)
        scrollFrame:SetScrollChild(scrollChild)
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function()
            local current = scrollFrame:GetVerticalScroll()
            local maxScroll = scrollFrame:GetVerticalScrollRange()
            local delta = arg1 * 25
            local newScroll = math.max(0, math.min(maxScroll, current - delta))
            scrollFrame:SetVerticalScroll(newScroll)
        end)

        -- Scrollbar
        local scrollBar = CreateFrame("Slider", nil, cf)
        scrollBar:SetPoint("TOPRIGHT", cf, "TOPRIGHT", -8, -45)
        scrollBar:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", -8, 10)
        scrollBar:SetWidth(16)
        scrollBar:SetOrientation("VERTICAL")
        scrollBar:SetMinMaxValues(0, 1)
        scrollBar:SetValue(0)
        scrollBar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = nil,
            tile = false,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        scrollBar:SetBackdropColor(0, 0, 0, 0.4)
        local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
        thumb:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        thumb:SetWidth(12)
        thumb:SetHeight(25)
        thumb:SetVertexColor(0.6, 0.6, 0.6, 1)
        scrollBar:SetThumbTexture(thumb)
        scrollBar:SetScript("OnValueChanged", function()
            scrollFrame:SetVerticalScroll(arg1)
        end)

        -- Update scrollbar
        local function UpdateScrollRange()
            local maxScroll = math.max(0, scrollChild:GetHeight() - scrollFrame:GetHeight())
            scrollBar:SetMinMaxValues(0, maxScroll)
            scrollBar:Show()
        end
        cf:SetScript("OnSizeChanged", UpdateScrollRange)
        UpdateScrollRange()

        -- Load saved settings from Database
        local Database = DPSLight_Database
        if Database then
            -- Load button visibility settings
            cf.buttonVisibility = Database:GetSetting("buttonVisibility") or {
                modeBtn = true,
                combatBtn = true,
                dpsToggleBtn = true,
                reportBtn = true,
                resetBtn = true,
            }

            -- Load footer info settings
            cf.footerInfo = Database:GetSetting("footerInfo") or {
                combatTimer = true,
                fps = false,
                latency = false,
                memory = false,
            }

            -- Load border style
            cf.currentBorder = Database:GetSetting("borderStyle") or 1

            -- Load colors
            local bgColor = Database:GetSetting("bgColor") or {r = 0, g = 0, b = 0, a = 0.9}
            cf.bgR = bgColor.r
            cf.bgG = bgColor.g
            cf.bgB = bgColor.b
            cf.bgA = bgColor.a

            -- Load show controls/footer
            cf.showControls = Database:GetSetting("showControls")
            if cf.showControls == nil then cf.showControls = true end

            cf.showFooter = Database:GetSetting("showFooter")
            if cf.showFooter == nil then cf.showFooter = true end

            -- IMPORTANT: Load settings into MODULE-LEVEL variables (not just cf.*)
            -- This is critical so UpdateDisplay uses the correct values
            local savedMaxPlayers = Database:GetSetting("maxPlayers")
            if savedMaxPlayers then
                maxPlayersToShow = savedMaxPlayers
            end

            local savedFilterMode = Database:GetSetting("filterMode")
            if savedFilterMode then
                filterMode = savedFilterMode
            end

            local savedShowSelfOnly = Database:GetSetting("showSelfOnly")
            if savedShowSelfOnly ~= nil then
                showSelfOnly = savedShowSelfOnly
            end
        else
            cf.buttonVisibility = {}
            cf.footerInfo = {}
        end

        local yOffset = -10

        -- Button visibility options with frame and master toggle
        local buttonVisFrame = CreateFrame("Frame", nil, scrollChild)
        buttonVisFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
        buttonVisFrame:SetWidth(260)
        buttonVisFrame:SetHeight(155)
        buttonVisFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        buttonVisFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        buttonVisFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        -- Master toggle for all buttons
        local buttonVisMasterCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        buttonVisMasterCheck:SetPoint("TOPLEFT", buttonVisFrame, "TOPLEFT", 8, -8)
        buttonVisMasterCheck:SetChecked(cf.showControls)
        local buttonVisText = buttonVisMasterCheck:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        buttonVisText:SetPoint("LEFT", buttonVisMasterCheck, "RIGHT", 5, 0)
        buttonVisText:SetText("Button Visibility")
        buttonVisText:SetTextColor(1, 0.8, 0)

        buttonVisMasterCheck:SetScript("OnClick", function()
            cf.showControls = this:GetChecked()
            local Database = DPSLight_Database
            if Database then
                Database:SetSetting("showControls", cf.showControls)
            end

            -- Show/hide all control buttons
            if cf.showControls then
                if frame.modeBtn then frame.modeBtn:Show() end
                if frame.combatBtn then frame.combatBtn:Show() end
                if frame.dpsToggleBtn then frame.dpsToggleBtn:Show() end
                if frame.reportBtn then frame.reportBtn:Show() end
                if frame.resetBtn then frame.resetBtn:Show() end
            else
                if frame.modeBtn then frame.modeBtn:Hide() end
                if frame.combatBtn then frame.combatBtn:Hide() end
                if frame.dpsToggleBtn then frame.dpsToggleBtn:Hide() end
                if frame.reportBtn then frame.reportBtn:Hide() end
                if frame.resetBtn then frame.resetBtn:Hide() end
            end
        end)

        local btnVisYOffset = -35

        local buttons = {
            {key = "modeBtn", label = "Mode Button", ref = "modeBtn"},
            {key = "combatBtn", label = "Combat History (C)", ref = "combatBtn"},
            {key = "dpsToggleBtn", label = "Per Second Toggle (/s)", ref = "dpsToggleBtn"},
            {key = "reportBtn", label = "Report Button (R)", ref = "reportBtn"},
            {key = "resetBtn", label = "Reset Button (X)", ref = "resetBtn"},
        }

        for _, btnData in ipairs(buttons) do
            if not btnData then break end
            local check = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", buttonVisFrame, "TOPLEFT", 15, btnVisYOffset)
            if not cf.buttonVisibility then cf.buttonVisibility = {} end
            check:SetChecked(cf.buttonVisibility[btnData.key] ~= false)
            cf.buttonVisibility[btnData.key] = check:GetChecked()

            local checkText = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            checkText:SetPoint("LEFT", check, "RIGHT", 5, 0)
            checkText:SetText(btnData.label)

            check:SetScript("OnClick", function()
                if not cf.buttonVisibility then cf.buttonVisibility = {} end
                if not btnData then return end
                cf.buttonVisibility[btnData.key] = this:GetChecked()

                -- Save immediately to Database
                local Database = DPSLight_Database
                if Database then
                    Database:SetSetting("buttonVisibility", cf.buttonVisibility)
                end

                -- Show/hide button
                local btn = frame[btnData.ref]
                if btn then
                    if this:GetChecked() then
                        btn:Show()
                    else
                        btn:Hide()
                    end
                end
            end)

            btnVisYOffset = btnVisYOffset - 25
        end
        yOffset = yOffset - 165

        -- Footer Info Options with frame
        local footerInfoFrame = CreateFrame("Frame", nil, scrollChild)
        footerInfoFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
        footerInfoFrame:SetWidth(260)
        footerInfoFrame:SetHeight(130)
        footerInfoFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        footerInfoFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        footerInfoFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        -- Master toggle for footer
        local footerMasterCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        footerMasterCheck:SetPoint("TOPLEFT", footerInfoFrame, "TOPLEFT", 8, -8)
        footerMasterCheck:SetChecked(cf.showFooter)
        local footerInfoText = footerMasterCheck:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        footerInfoText:SetPoint("LEFT", footerMasterCheck, "RIGHT", 5, 0)
        footerInfoText:SetText("Footer Information")
        footerInfoText:SetTextColor(1, 0.8, 0)

        footerMasterCheck:SetScript("OnClick", function()
            cf.showFooter = this:GetChecked()
            local Database = DPSLight_Database
            if Database then
                Database:SetSetting("showFooter", cf.showFooter)
            end

            -- Show/hide footer
            if frame.footer then
                if cf.showFooter then
                    frame.footer:Show()
                else
                    frame.footer:Hide()
                end
            end
        end)

        local footerYOffset = -35

        local footerOptions = {
            {key = "combatTimer", label = "Combat Timer"},
            {key = "fps", label = "FPS"},
            {key = "latency", label = "Latency"},
            {key = "memory", label = "Memory"},
        }

        for _, opt in ipairs(footerOptions) do
            if not opt then break end
            local check = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", footerInfoFrame, "TOPLEFT", 15, footerYOffset)
            if not cf.footerInfo then cf.footerInfo = {} end
            check:SetChecked(cf.footerInfo[opt.key] == true or (opt.key == "combatTimer"))
            cf.footerInfo[opt.key] = check:GetChecked()

            local checkText = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            checkText:SetPoint("LEFT", check, "RIGHT", 5, 0)
            checkText:SetText(opt.label)

            check:SetScript("OnClick", function()
                if not cf.footerInfo then cf.footerInfo = {} end
                if not opt then return end
                cf.footerInfo[opt.key] = this:GetChecked()

                -- Save immediately to Database so UpdateFooter sees the change
                local Database = DPSLight_Database
                if Database then
                    Database:SetSetting("footerInfo", cf.footerInfo)
                end

                -- Update footer display
                if frame and frame.UpdateFooter then
                    frame:UpdateFooter()
                end
            end)

            footerYOffset = footerYOffset - 25
        end
        yOffset = yOffset - 140

        -- Data Filters section
        local dataFiltersFrame = CreateFrame("Frame", nil, scrollChild)
        dataFiltersFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
        dataFiltersFrame:SetWidth(260)
        dataFiltersFrame:SetHeight(130)
        dataFiltersFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        dataFiltersFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        dataFiltersFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        local dataFiltersText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        dataFiltersText:SetPoint("TOPLEFT", dataFiltersFrame, "TOPLEFT", 8, -8)
        dataFiltersText:SetText("Data Filters")
        dataFiltersText:SetTextColor(1, 0.8, 0)

        local filterYOffset = -30

        -- Filter Mode button
        local filterModeText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        filterModeText:SetPoint("TOPLEFT", dataFiltersFrame, "TOPLEFT", 15, filterYOffset)
        filterModeText:SetText("Filter Mode:")
        filterYOffset = filterYOffset - 20

        local filterBtn = CreateFrame("Button", nil, scrollChild)
        filterBtn:SetWidth(230)
        filterBtn:SetHeight(24)
        filterBtn:SetPoint("TOPLEFT", dataFiltersFrame, "TOPLEFT", 15, filterYOffset)
        filterBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        filterBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        local filterBtnText = filterBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        filterBtnText:SetPoint("CENTER", filterBtn, "CENTER", 0, 0)
        filterBtnText:SetJustifyH("CENTER")

        local filterModes = {"all", "group", "raid"}
        local filterLabels = {all = "Show All Players", group = "Group Only", raid = "Raid Only"}

        -- Initialize filterIndex based on current filterMode
        local filterIndex = 1
        for i, mode in ipairs(filterModes) do
            if mode == filterMode then
                filterIndex = i
                break
            end
        end

        filterBtnText:SetText(filterLabels[filterMode])
        filterYOffset = filterYOffset - 30

        -- Show Self Only checkbox
        local selfOnlyCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        selfOnlyCheck:SetPoint("TOPLEFT", dataFiltersFrame, "TOPLEFT", 15, filterYOffset)
        selfOnlyCheck:SetChecked(showSelfOnly)
        local selfOnlyText = selfOnlyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        selfOnlyText:SetPoint("LEFT", selfOnlyCheck, "RIGHT", 5, 0)
        selfOnlyText:SetText("Show Self Only")

        -- Logic: Filter Mode and Show Self Only interaction
        -- When Show Self Only is enabled, only show player's own data regardless of filter mode
        filterBtn:SetScript("OnClick", function()
            filterIndex = filterIndex + 1
            if filterIndex > 3 then filterIndex = 1 end
            filterMode = filterModes[filterIndex]
            filterBtnText:SetText(filterLabels[filterMode])

            -- When switching away from "Show All", uncheck "Show Self Only" as it's redundant
            if filterMode ~= "all" and showSelfOnly then
                showSelfOnly = false
                selfOnlyCheck:SetChecked(false)
                if Database then
                    Database:SetSetting("showSelfOnly", false)
                end
            end

            if Database then
                Database:SetSetting("filterMode", filterMode)
            end
            MainFrame:UpdateDisplay()
        end)

        selfOnlyCheck:SetScript("OnClick", function()
            showSelfOnly = this:GetChecked()

            -- When enabling Show Self Only, switch to "Show All Players" mode
            -- This prevents confusion about showing yourself in group/raid
            if showSelfOnly and filterMode ~= "all" then
                filterMode = "all"
                filterIndex = 1
                filterBtnText:SetText(filterLabels[filterMode])
                if Database then
                    Database:SetSetting("filterMode", filterMode)
                end
            end

            if Database then
                Database:SetSetting("showSelfOnly", showSelfOnly)
            end
            MainFrame:UpdateDisplay()
        end)

        yOffset = yOffset - 140

        -- Max players to show
        local maxPlayersText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        maxPlayersText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        maxPlayersText:SetText("Max Players to Show:")
        yOffset = yOffset - 25

        local maxPlayersSlider = CreateFrame("Slider", "DPSLight_MaxPlayersSlider", scrollChild, "OptionsSliderTemplate")
        maxPlayersSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
        maxPlayersSlider:SetWidth(200)
        maxPlayersSlider:SetMinMaxValues(5, 40)
        maxPlayersSlider:SetValueStep(1)
        maxPlayersSlider:SetValue(maxPlayersToShow)
        maxPlayersSlider:SetScript("OnValueChanged", function()
            local val = math.floor(this:GetValue())
            maxPlayersToShow = val
            getglobal(this:GetName() .. "Text"):SetText("Max Players: " .. val)

            -- Save immediately to Database
            local Database = DPSLight_Database
            if Database then
                Database:SetSetting("maxPlayers", val)
            end

            MainFrame:UpdateDisplay()
        end)
        getglobal(maxPlayersSlider:GetName() .. "Text"):SetText("Max Players: " .. maxPlayersToShow)
        getglobal(maxPlayersSlider:GetName() .. "Low"):SetText("5")
        getglobal(maxPlayersSlider:GetName() .. "High"):SetText("40")
        yOffset = yOffset - 35

        -- Hide class icons option
        local hideIconsCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        hideIconsCheck:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        hideIconsCheck:SetChecked(false)
        local hideIconsText = hideIconsCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hideIconsText:SetPoint("LEFT", hideIconsCheck, "RIGHT", 5, 0)
        hideIconsText:SetText("Hide Class Icons")
        hideIconsCheck:SetScript("OnClick", function()
            local hideIcons = this:GetChecked()
            if scrollList and scrollList.SetShowIcons then
                scrollList:SetShowIcons(not hideIcons)
            end
        end)
        yOffset = yOffset - 30

        -- Border style selector
        local borderText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        borderText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        borderText:SetText("Border Style:")
        yOffset = yOffset - 25

        local borders = {
            {name = "Dialog", edge = "Interface\\DialogFrame\\UI-DialogBox-Border"},
            {name = "Tooltip", edge = "Interface\\Tooltips\\UI-Tooltip-Border"},
            {name = "Glues", edge = "Interface\\Glues\\Common\\Glue-Tooltip-Border"},
            {name = "Metal", edge = "Interface\\OptionsFrame\\UI-OptionsFrame-Border"},
            {name = "Button", edge = "Interface\\Buttons\\UI-SliderBar-Border"},
            {name = "None", edge = nil}
        }

        -- cf.currentBorder already loaded from settings above

        local borderBtn = CreateFrame("Button", nil, scrollChild)
        borderBtn:SetWidth(220)
        borderBtn:SetHeight(28)
        borderBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        borderBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        borderBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        borderBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
            tile = false
        })
        local borderBtnText = borderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        borderBtnText:SetPoint("CENTER", borderBtn, "CENTER", 0, 0)
        borderBtnText:SetText(borders[cf.currentBorder].name)
        borderBtnText:SetJustifyH("CENTER")
        borderBtn:SetScript("OnClick", function()
            cf.currentBorder = cf.currentBorder + 1
            if cf.currentBorder > getn(borders) then cf.currentBorder = 1 end
            borderBtnText:SetText(borders[cf.currentBorder].name)

            -- Save immediately to Database
            local Database = DPSLight_Database
            if Database then
                Database:SetSetting("borderStyle", cf.currentBorder)
            end

            -- Apply border to main frame
            if frame then
                frame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = borders[cf.currentBorder].edge,
                    tile = true, tileSize = 32, edgeSize = 32,
                    insets = {left = 8, right = 8, top = 8, bottom = 8}
                })
                frame:SetBackdropColor(cf.bgR or 0, cf.bgG or 0, cf.bgB or 0, cf.bgA or 0.9)
            end
        end)
        yOffset = yOffset - 35

        -- Initialize color values FIRST
        if not cf.bgR then cf.bgR = 0 end
        if not cf.bgG then cf.bgG = 0 end
        if not cf.bgB then cf.bgB = 0 end
        if not cf.bgA then cf.bgA = 0.9 end

        -- Apply initial color to main frame
        if frame and frame.SetBackdropColor then
            frame:SetBackdropColor(cf.bgR, cf.bgG, cf.bgB, cf.bgA)
        end

        -- Save button
        local saveBtn = CreateFrame("Button", nil, scrollChild)
        saveBtn:SetWidth(220)
        saveBtn:SetHeight(30)
        saveBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        saveBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        saveBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        local saveText = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        saveText:SetPoint("CENTER", saveBtn, "CENTER", 0, 0)
        saveText:SetText("Save Settings")
        saveText:SetTextColor(0, 1, 0)
        saveText:SetJustifyH("CENTER")
        saveBtn:SetScript("OnClick", function()
            -- Save ALL settings
            local Database = DPSLight_Database
            if Database then
                -- Save window size and position
                if frame then
                    Database:SetSetting("windowSize", {
                        width = frame:GetWidth(),
                        height = frame:GetHeight()
                    })
                    local x, y = frame:GetLeft(), frame:GetTop()
                    if x and y then
                        Database:SetSetting("windowPos", {x = x, y = y})
                    end
                end
                -- Save colors
                Database:SetSetting("bgColor", {
                    r = cf.bgR or 0,
                    g = cf.bgG or 0,
                    b = cf.bgB or 0,
                    a = cf.bgA or 0.9
                })
                -- Save border style
                if cf.currentBorder then
                    Database:SetSetting("borderStyle", cf.currentBorder)
                end
                -- Save max players
                Database:SetSetting("maxPlayers", maxPlayersToShow)
                -- Save filters (already saved via callbacks)
                Database:SetSetting("filterMode", filterMode)
                -- Save button visibility
                Database:SetSetting("buttonVisibility", cf.buttonVisibility or {})
                -- Save footer info
                Database:SetSetting("footerInfo", cf.footerInfo or {})
                -- Save show controls/footer
                Database:SetSetting("showControls", cf.showControls)
                Database:SetSetting("showFooter", cf.showFooter)
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Settings saved!", 0, 1, 0)
            end
        end)
        yOffset = yOffset - 40

        -- Background Color Section with frame
        local colorFrame = CreateFrame("Frame", nil, scrollChild)
        colorFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
        colorFrame:SetWidth(260)
        colorFrame:SetHeight(135)
        colorFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        colorFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        colorFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        local colorText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        colorText:SetPoint("TOPLEFT", colorFrame, "TOPLEFT", 8, -8)
        colorText:SetText("Background Color")
        colorText:SetTextColor(1, 0.8, 0)

        local colorYOffset = -30

        -- Red slider
        local rText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rText:SetPoint("TOPLEFT", colorFrame, "TOPLEFT", 15, colorYOffset)
        rText:SetText("Red: " .. string.format("%.2f", cf.bgR or 0))
        cf.rText = rText
        local rSlider = CreateFrame("Slider", "DPSLight_RedSlider", scrollChild, "OptionsSliderTemplate")
        rSlider:SetPoint("LEFT", rText, "RIGHT", 5, 0)
        rSlider:SetWidth(140)
        rSlider:SetMinMaxValues(0, 1)
        rSlider:SetValueStep(0.05)
        rSlider:SetValue(cf.bgR or 0)
        rSlider:SetScript("OnValueChanged", function()
            local val = this:GetValue()
            cf.bgR = val
            cf.rText:SetText("Red: " .. string.format("%.2f", val))
            if frame and frame.SetBackdropColor then
                frame:SetBackdropColor(cf.bgR, cf.bgG, cf.bgB, cf.bgA)
            end
        end)
        colorYOffset = colorYOffset - 25

        -- Green slider
        local gText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        gText:SetPoint("TOPLEFT", colorFrame, "TOPLEFT", 15, colorYOffset)
        gText:SetText("Green: " .. string.format("%.2f", cf.bgG or 0))
        cf.gText = gText
        local gSlider = CreateFrame("Slider", "DPSLight_GreenSlider", scrollChild, "OptionsSliderTemplate")
        gSlider:SetPoint("LEFT", gText, "RIGHT", 5, 0)
        gSlider:SetWidth(140)
        gSlider:SetMinMaxValues(0, 1)
        gSlider:SetValueStep(0.05)
        gSlider:SetValue(cf.bgG or 0)
        gSlider:SetScript("OnValueChanged", function()
            local val = this:GetValue()
            cf.bgG = val
            cf.gText:SetText("Green: " .. string.format("%.2f", val))
            if frame and frame.SetBackdropColor then
                frame:SetBackdropColor(cf.bgR, cf.bgG, cf.bgB, cf.bgA)
            end
        end)
        colorYOffset = colorYOffset - 25

        -- Blue slider
        local bText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        bText:SetPoint("TOPLEFT", colorFrame, "TOPLEFT", 15, colorYOffset)
        bText:SetText("Blue: " .. string.format("%.2f", cf.bgB or 0))
        cf.bText = bText
        local bSlider = CreateFrame("Slider", "DPSLight_BlueSlider", scrollChild, "OptionsSliderTemplate")
        bSlider:SetPoint("LEFT", bText, "RIGHT", 5, 0)
        bSlider:SetWidth(140)
        bSlider:SetMinMaxValues(0, 1)
        bSlider:SetValueStep(0.05)
        bSlider:SetValue(cf.bgB or 0)
        bSlider:SetScript("OnValueChanged", function()
            local val = this:GetValue()
            cf.bgB = val
            cf.bText:SetText("Blue: " .. string.format("%.2f", val))
            if frame and frame.SetBackdropColor then
                frame:SetBackdropColor(cf.bgR, cf.bgG, cf.bgB, cf.bgA)
            end
        end)
        colorYOffset = colorYOffset - 25

        -- Transparency slider
        local transText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        transText:SetPoint("TOPLEFT", colorFrame, "TOPLEFT", 15, colorYOffset)
        transText:SetText("Alpha: " .. string.format("%.2f", cf.bgA or 0.9))
        cf.transText = transText
        local transSlider = CreateFrame("Slider", "DPSLight_AlphaSlider", scrollChild, "OptionsSliderTemplate")
        transSlider:SetPoint("LEFT", transText, "RIGHT", 5, 0)
        transSlider:SetWidth(140)
        transSlider:SetMinMaxValues(0, 1)
        transSlider:SetValueStep(0.05)
        transSlider:SetValue(cf.bgA or 0.9)
        transSlider:SetScript("OnValueChanged", function()
            local val = this:GetValue()
            cf.bgA = val
            cf.transText:SetText("Alpha: " .. string.format("%.2f", val))
            if frame and frame.SetBackdropColor then
                frame:SetBackdropColor(cf.bgR, cf.bgG, cf.bgB, cf.bgA)
            end
        end)

        -- Update yOffset after color section
        yOffset = yOffset - 145

        frame.configFrame = cf
    end

    frame.configFrame:Show()
end

-- Show window selector for secondary window
function MainFrame:ShowWindowSelector()
    if not frame then return end

    if not frame.windowSelector then
        local ws = CreateFrame("Frame", "DPSLight_WindowSelector", UIParent)
        ws:SetWidth(200)
        ws:SetHeight(220)
        ws:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        ws:SetFrameStrata("DIALOG")
        ws:SetMovable(true)
        ws:EnableMouse(true)
        ws:SetResizable(true)
        ws:SetMinResize(150, 180)  -- Réduit de 180x200
        ws:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = {left = 8, right = 8, top = 8, bottom = 8}
        })
        ws:SetBackdropColor(0, 0, 0, 0.9)
        ws:Hide()

        local title = ws:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", ws, "TOP", 0, -15)
        title:SetText("Select Window Type")
        title:SetTextColor(1, 0.82, 0)  -- Gold color

        local closeBtn = CreateFrame("Button", nil, ws)
        closeBtn:SetWidth(32)
        closeBtn:SetHeight(32)
        closeBtn:SetPoint("TOPRIGHT", ws, "TOPRIGHT", -2, -2)
        closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
        closeBtn:SetScript("OnClick", function() ws:Hide() end)

        -- Make draggable
        local wsDragArea = CreateFrame("Frame", nil, ws)
        wsDragArea:SetHeight(30)
        wsDragArea:SetPoint("TOPLEFT", ws, "TOPLEFT", 8, -8)
        wsDragArea:SetPoint("TOPRIGHT", ws, "TOPRIGHT", -8, -8)
        wsDragArea:EnableMouse(true)
        wsDragArea:RegisterForDrag("LeftButton")
        wsDragArea:SetScript("OnDragStart", function() ws:StartMoving() end)
        wsDragArea:SetScript("OnDragStop", function() ws:StopMovingOrSizing() end)

        -- Resize button
        local resizeBtnWs = CreateFrame("Button", nil, ws)
        resizeBtnWs:SetWidth(16)
        resizeBtnWs:SetHeight(16)
        resizeBtnWs:SetPoint("BOTTOMRIGHT", ws, "BOTTOMRIGHT", -2, 2)
        resizeBtnWs:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeBtnWs:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeBtnWs:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeBtnWs:SetScript("OnMouseDown", function() ws:StartSizing("BOTTOMRIGHT") end)
        resizeBtnWs:SetScript("OnMouseUp", function() ws:StopMovingOrSizing() end)

        local yOffset = -45
        local types = {
            {text = "Damage", mode = "damage"},
            {text = "Healing", mode = "healing"},
            {text = "Dispels", mode = "dispels"},
            {text = "Decurse", mode = "decurse"},
            {text = "Deaths", mode = "deaths"},
        }

        for i, typeData in ipairs(types) do
            local btn = CreateFrame("Button", nil, ws)
            btn:SetWidth(160)
            btn:SetHeight(24)
            btn:SetPoint("TOP", ws, "TOP", 0, yOffset)
            btn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
            btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")

            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btnText:SetText(typeData.text)
            btnText:SetJustifyH("CENTER")

            btn:SetScript("OnClick", function()
                -- Create secondary window
                if typeData and typeData.mode then
                    MainFrame:CreateSecondaryWindow(typeData.mode)
                end
                ws:Hide()
            end)

            yOffset = yOffset - 30
        end

        frame.windowSelector = ws
    end

    frame.windowSelector:Show()
end

-- Show combat history
function MainFrame:ShowCombatHistory()
    if not frame then return end

    if not frame.combatHistory then
        local Database = DPSLight_Database
        local opacity = Database and Database:GetSetting("opacity") or 0.9
        local borderStyle = Database and Database:GetSetting("borderStyle") or 1
        local bgColor = Database and Database:GetSetting("bgColor") or {r=0, g=0, b=0, a=opacity}

        -- Border styles mapping
        local borders = {
            "Interface\\Tooltips\\UI-Tooltip-Border",
            "Interface\\DialogFrame\\UI-DialogBox-Border",
            "Interface\\AddOns\\DPSLight\\images\\border2",
            "Interface\\AddOns\\DPSLight\\images\\border3",
            "Interface\\AddOns\\DPSLight\\images\\border4",
            "Interface\\AddOns\\DPSLight\\images\\border5",
        }
        local edgeFile = borders[borderStyle] or borders[1]

        local ch = CreateFrame("Frame", "DPSLight_CombatHistory", UIParent)
        ch:SetWidth(300)
        ch:SetHeight(400)
        ch:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        ch:SetFrameStrata("DIALOG")
        ch:SetMovable(true)
        ch:EnableMouse(true)
        ch:SetResizable(true)
        ch:SetMinResize(280, 300)
        ch:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = edgeFile,
            tile = true, tileSize = 32, edgeSize = 32,
            insets = {left = 8, right = 8, top = 8, bottom = 8}
        })
        ch:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, opacity)
        ch:Hide()

        local title = ch:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", ch, "TOP", 0, -15)
        title:SetText("Combat History")
        title:SetTextColor(1, 0.82, 0)

        -- Reset button
        local resetBtn = CreateFrame("Button", nil, ch)
        resetBtn:SetWidth(60)
        resetBtn:SetHeight(20)
        resetBtn:SetPoint("TOPRIGHT", ch, "TOPRIGHT", -35, -10)
        resetBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
            edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        resetBtn:SetBackdropColor(0.6, 0.2, 0.2, 1)
        local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        resetText:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
        resetText:SetText("Reset")
        resetBtn:SetScript("OnClick", function()
            local Database = DPSLight_Database
            if Database and Database.ClearHistory then
                Database:ClearHistory()
                MainFrame:UpdateCombatHistoryList()
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Combat history cleared", 1, 1, 0)
            end
        end)
        resetBtn:SetScript("OnEnter", function()
            this:SetBackdropColor(0.8, 0.3, 0.3, 1)
        end)
        resetBtn:SetScript("OnLeave", function()
            this:SetBackdropColor(0.6, 0.2, 0.2, 1)
        end)

        local closeBtn = CreateFrame("Button", nil, ch)
        closeBtn:SetWidth(32)
        closeBtn:SetHeight(32)
        closeBtn:SetPoint("TOPRIGHT", ch, "TOPRIGHT", -2, -2)
        closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
        closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeBtn:SetScript("OnClick", function() ch:Hide() end)

        -- Drag area
        local chDragArea = CreateFrame("Frame", nil, ch)
        chDragArea:SetHeight(30)
        chDragArea:SetPoint("TOPLEFT", ch, "TOPLEFT", 8, -8)
        chDragArea:SetPoint("TOPRIGHT", ch, "TOPRIGHT", -8, -8)
        chDragArea:EnableMouse(true)
        chDragArea:RegisterForDrag("LeftButton")
        chDragArea:SetScript("OnDragStart", function() ch:StartMoving() end)
        chDragArea:SetScript("OnDragStop", function() ch:StopMovingOrSizing() end)

        -- Resize button
        local resizeBtnCh = CreateFrame("Button", nil, ch)
        resizeBtnCh:SetWidth(16)
        resizeBtnCh:SetHeight(16)
        resizeBtnCh:SetPoint("BOTTOMRIGHT", ch, "BOTTOMRIGHT", -2, 2)
        resizeBtnCh:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeBtnCh:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeBtnCh:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeBtnCh:SetScript("OnMouseDown", function() ch:StartSizing("BOTTOMRIGHT") end)
        resizeBtnCh:SetScript("OnMouseUp", function() ch:StopMovingOrSizing() end)

        local yOffset = -45

        -- Scroll frame for combat list
        local scrollFrame = CreateFrame("ScrollFrame", nil, ch)
        scrollFrame:SetPoint("TOPLEFT", ch, "TOPLEFT", 10, yOffset)
        scrollFrame:SetPoint("BOTTOMRIGHT", ch, "BOTTOMRIGHT", -10, 10)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(260)
        scrollChild:SetHeight(1)  -- Will be updated dynamically
        scrollFrame:SetScrollChild(scrollChild)
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function()
            local current = scrollFrame:GetVerticalScroll()
            local maxScroll = scrollFrame:GetVerticalScrollRange()
            local delta = arg1 * 20
            local newScroll = math.max(0, math.min(maxScroll, current - delta))
            scrollFrame:SetVerticalScroll(newScroll)
        end)

        ch.scrollFrame = scrollFrame
        ch.scrollChild = scrollChild
        ch.combatButtons = {}

        frame.combatHistory = ch
    end

    -- Update style to match main window settings
    MainFrame:UpdateSecondaryWindowsStyle()

    -- Update combat list
    MainFrame:UpdateCombatHistoryList()

    frame.combatHistory:Show()
end

-- Update combat history list
function MainFrame:UpdateCombatHistoryList()
    if not frame or not frame.combatHistory then return end

    local ch = frame.combatHistory
    local Database = DPSLight_Database
    if not Database then return end

    -- Clear existing buttons
    for i, btn in ipairs(ch.combatButtons) do
        btn:Hide()
    end
    ch.combatButtons = {}

    local yOffset = -10
    local btnHeight = 50
    local btnSpacing = 5

    -- Get combat history
    local history = Database:GetHistory()
    if not history then history = {} end

    -- Current combat button (always first)
    local currentBtn = CreateFrame("Button", nil, ch.scrollChild)
    currentBtn:SetWidth(270)
    currentBtn:SetHeight(btnHeight)
    currentBtn:SetPoint("TOP", ch.scrollChild, "TOP", 0, yOffset)
    currentBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    currentBtn:SetBackdropColor(0.2, 0.4, 0.2, 0.9)
    currentBtn:SetBackdropBorderColor(0.4, 0.8, 0.4, 1)

    local currentText = currentBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    currentText:SetPoint("TOP", currentBtn, "TOP", 0, -8)
    currentText:SetText("Current Combat")
    currentText:SetTextColor(0.5, 1, 0.5)

    local currentTime = currentBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentTime:SetPoint("TOP", currentText, "BOTTOM", 0, -4)
    currentTime:SetText("In Progress")
    currentTime:SetTextColor(0.8, 0.8, 0.8)

    currentBtn:SetScript("OnClick", function()
        ch:Hide()
        -- Show current combat data
    end)

    currentBtn:SetScript("OnEnter", function()
        this:SetBackdropColor(0.3, 0.5, 0.3, 1)
    end)
    currentBtn:SetScript("OnLeave", function()
        this:SetBackdropColor(0.2, 0.4, 0.2, 0.9)
    end)

    table.insert(ch.combatButtons, currentBtn)
    yOffset = yOffset - btnHeight - btnSpacing

    -- Previous combats
    for i = 1, math.min(20, table.getn(history)) do
        local segment = history[i]
        if segment then
            local btn = CreateFrame("Button", nil, ch.scrollChild)
            btn:SetWidth(270)
            btn:SetHeight(btnHeight)
            btn:SetPoint("TOP", ch.scrollChild, "TOP", 0, yOffset)
            btn:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 12,
                insets = {left = 2, right = 2, top = 2, bottom = 2}
            })
            btn:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
            btn:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)

            local combatName = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            combatName:SetPoint("TOP", btn, "TOP", 0, -8)
            combatName:SetText("Combat #" .. i)
            combatName:SetTextColor(1, 1, 1)

            local combatInfo = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            combatInfo:SetPoint("TOP", combatName, "BOTTOM", 0, -4)
            local duration = segment.duration or 0
            local durationStr = string.format("%.0fs", duration)
            combatInfo:SetText(date("%H:%M", segment.timestamp or 0) .. " - " .. durationStr)
            combatInfo:SetTextColor(0.7, 0.7, 0.7)

            btn.segmentData = segment
            btn:SetScript("OnClick", function()
                MainFrame:ShowCombatDetails(this.segmentData)
            end)

            btn:SetScript("OnEnter", function()
                this:SetBackdropColor(0.25, 0.25, 0.35, 1)
            end)
            btn:SetScript("OnLeave", function()
                this:SetBackdropColor(0.15, 0.15, 0.2, 0.9)
            end)

            table.insert(ch.combatButtons, btn)
            yOffset = yOffset - btnHeight - btnSpacing
        end
    end

    -- Update scroll child height
    local totalHeight = math.abs(yOffset) + 20
    ch.scrollChild:SetHeight(totalHeight)
end

-- Show combat details
function MainFrame:ShowCombatDetails(segmentData)
    if not segmentData then return end

    -- Create detail window for combat stats
    if not frame.combatDetail then
        local cd = CreateFrame("Frame", "DPSLight_CombatDetail", UIParent)
        cd:SetWidth(400)
        cd:SetHeight(450)
        cd:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        cd:SetFrameStrata("DIALOG")
        cd:SetMovable(true)
        cd:EnableMouse(true)
        cd:Hide()

        -- Apply unified style
        ApplyUnifiedStyle(cd)

        -- Title
        local title = cd:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", cd, "TOP", 0, -15)
        title:SetText("Combat Details")
        title:SetTextColor(1, 0.82, 0)
        cd.title = title

        -- Close button
        local closeBtn = CreateFrame("Button", nil, cd)
        closeBtn:SetWidth(32)
        closeBtn:SetHeight(32)
        closeBtn:SetPoint("TOPRIGHT", cd, "TOPRIGHT", -2, -2)
        closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
        closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
        closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
        closeBtn:SetScript("OnClick", function() cd:Hide() end)

        -- Drag
        local dragArea = CreateFrame("Frame", nil, cd)
        dragArea:SetHeight(30)
        dragArea:SetPoint("TOPLEFT", cd, "TOPLEFT", 8, -8)
        dragArea:SetPoint("TOPRIGHT", cd, "TOPRIGHT", -8, -8)
        dragArea:EnableMouse(true)
        dragArea:RegisterForDrag("LeftButton")
        dragArea:SetScript("OnDragStart", function() cd:StartMoving() end)
        dragArea:SetScript("OnDragStop", function() cd:StopMovingOrSizing() end)

        -- Content text
        local content = cd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        content:SetPoint("TOPLEFT", cd, "TOPLEFT", 15, -50)
        content:SetPoint("TOPRIGHT", cd, "TOPRIGHT", -15, -50)
        content:SetJustifyH("LEFT")
        content:SetJustifyV("TOP")
        cd.content = content

        frame.combatDetail = cd
    end

    local cd = frame.combatDetail

    -- Build stats text
    local text = ""
    text = text .. "|cFFFFD700Duration:|r " .. string.format("%.1fs", segmentData.duration or 0) .. "\n"
    text = text .. "|cFFFFD700Time:|r " .. date("%H:%M:%S", segmentData.timestamp or 0) .. "\n\n"

    -- Get detailed stats from segment
    local DataStore = DPSLight_DataStore
    if DataStore and segmentData.segmentID then
        -- Damage stats
        local damageData = DataStore:GetTopN("damage", 10, segmentData.segmentID)
        if damageData and table.getn(damageData) > 0 then
            text = text .. "|cFFFF6060=== Damage ===|r\n"
            for i, entry in ipairs(damageData) do
                local dps = (segmentData.duration and segmentData.duration > 0) and (entry.total / segmentData.duration) or 0
                text = text .. string.format("%d. %s: %d (%.1f DPS)\n", i, entry.username, entry.total, dps)
            end
            text = text .. "\n"
        end

        -- Healing stats
        local healingData = DataStore:GetTopN("healing", 10, segmentData.segmentID)
        if healingData and table.getn(healingData) > 0 then
            text = text .. "|cFF60FF60=== Healing ===|r\n"
            for i, entry in ipairs(healingData) do
                local hps = (segmentData.duration and segmentData.duration > 0) and (entry.total / segmentData.duration) or 0
                text = text .. string.format("%d. %s: %d (%.1f HPS)\n", i, entry.username, entry.total, hps)
            end
            text = text .. "\n"
        end

        -- Deaths
        local deathsData = DataStore:GetTopN("deaths", 10, segmentData.segmentID)
        if deathsData and table.getn(deathsData) > 0 then
            text = text .. "|cFFFF0000=== Deaths ===|r\n"
            for i, entry in ipairs(deathsData) do
                text = text .. string.format("%d. %s: %d\n", i, entry.username, entry.total)
            end
        end
    else
        text = text .. "|cFFFF0000No detailed data available|r\n"
    end

    cd.content:SetText(text)
    cd:Show()
end

-- Snap window to nearby windows
function SnapToNearbyWindows(movingFrame)
    if not movingFrame or not DPSLight_AllWindows then return end

    local snapThreshold = 15
    local left, bottom = movingFrame:GetLeft(), movingFrame:GetBottom()
    local right, top = movingFrame:GetRight(), movingFrame:GetTop()
    local width, height = movingFrame:GetWidth(), movingFrame:GetHeight()

    if not left or not bottom or not right or not top then return end

    local bestSnapX, bestSnapY = nil, nil
    local minDistX, minDistY = snapThreshold + 1, snapThreshold + 1

    for _, otherFrame in ipairs(DPSLight_AllWindows) do
        if otherFrame ~= movingFrame and otherFrame:IsVisible() then
            local oLeft = otherFrame:GetLeft()
            local oBottom = otherFrame:GetBottom()
            local oRight = otherFrame:GetRight()
            local oTop = otherFrame:GetTop()

            if oLeft and oBottom and oRight and oTop then
                -- Check horizontal snapping (left/right edges)
                local distRightToLeft = math.abs(right - oLeft)
                if distRightToLeft < minDistX and distRightToLeft <= snapThreshold then
                    if not (bottom > oTop or top < oBottom) then
                        bestSnapX = oLeft - width
                        minDistX = distRightToLeft
                    end
                end

                local distLeftToRight = math.abs(left - oRight)
                if distLeftToRight < minDistX and distLeftToRight <= snapThreshold then
                    if not (bottom > oTop or top < oBottom) then
                        bestSnapX = oRight
                        minDistX = distLeftToRight
                    end
                end

                -- Check vertical snapping (top/bottom)
                local distBottomToTop = math.abs(bottom - oTop)
                if distBottomToTop < minDistY and distBottomToTop <= snapThreshold then
                    if not (left > oRight or right < oLeft) then
                        bestSnapY = oTop + height
                        minDistY = distBottomToTop
                    end
                end

                local distTopToBottom = math.abs(top - oBottom)
                if distTopToBottom < minDistY and distTopToBottom <= snapThreshold then
                    if not (left > oRight or right < oLeft) then
                        bestSnapY = oBottom
                        minDistY = distTopToBottom
                    end
                end
            end
        end
    end

    -- Apply snapping
    if bestSnapX or bestSnapY then
        movingFrame:ClearAllPoints()
        local finalX = bestSnapX or left
        local finalY = bestSnapY or top
        movingFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", finalX, finalY)
    end
end

-- Global table to track all DPSLight windows for snapping
if not DPSLight_AllWindows then
    DPSLight_AllWindows = {}
end

-- Create a secondary window
function MainFrame:CreateSecondaryWindow(mode)
    if not mode then
        DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Invalid window mode", 1, 0, 0)
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Creating secondary window for " .. mode, 1, 1, 0)

    -- Create a new independent window
    local secFrame = CreateFrame("Frame", "DPSLight_SecondaryFrame_" .. mode, UIParent)
    secFrame:SetWidth(380)
    secFrame:SetHeight(450)
    secFrame:SetPoint("CENTER", UIParent, "CENTER", 100, 0)
    secFrame:SetFrameStrata("MEDIUM")
    secFrame:SetMovable(true)
    secFrame:EnableMouse(true)
    secFrame:SetResizable(true)
    secFrame:SetMinResize(250, 300)

    -- Use same backdrop as main frame (UNIFIED STYLE)
    local Database = DPSLight_Database
    local opacity = Database and Database:GetSetting("opacity") or 0.9
    local borderStyle = Database and Database:GetSetting("borderStyle") or 1
    local bgColor = Database and Database:GetSetting("bgColor") or {r=0, g=0, b=0}

    local borders = {
        {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16},
        {edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32},
        {edgeFile = "Interface\\GLUES\\COMMON\\TextPanel-Border", edgeSize = 16},
        {edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border", edgeSize = 12},
        {edgeFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-WoodBorder", edgeSize = 32},
        {edgeFile = "Interface\\COMMON\\Indicator-Gray", edgeSize = 8},
    }
    local border = borders[borderStyle] or borders[1]

    secFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = border.edgeFile,
        tile = true,
        tileSize = 16,
        edgeSize = border.edgeSize,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    secFrame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, opacity)
    secFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    -- Add to global windows table for snapping
    table.insert(DPSLight_AllWindows, secFrame)

    -- Title/drag area
    local titleBg = CreateFrame("Frame", nil, secFrame)
    titleBg:SetHeight(20)
    titleBg:SetPoint("TOPLEFT", secFrame, "TOPLEFT", 8, -8)
    titleBg:SetPoint("TOPRIGHT", secFrame, "TOPRIGHT", -8, -8)
    titleBg:EnableMouse(true)
    titleBg:RegisterForDrag("LeftButton")
    titleBg:SetScript("OnDragStart", function() secFrame:StartMoving() end)
    titleBg:SetScript("OnDragStop", function()
        secFrame:StopMovingOrSizing()
        SnapToNearbyWindows(secFrame)
    end)

    -- Control buttons row (no title to save space)
    secFrame.showPerSecond = true
    secFrame.mode = mode  -- Initialize mode from parameter

    -- Mode button (first button - cycles through modes)
    local modeBtn = CreateFrame("Button", nil, secFrame)
    modeBtn:SetWidth(85)
    modeBtn:SetHeight(18)
    modeBtn:SetPoint("TOPLEFT", secFrame, "TOPLEFT", 10, -10)
    modeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 16, edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    modeBtn:SetBackdropColor(0.2, 0.5, 0.2, 1)
    local modeBtnText = modeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeBtnText:SetPoint("CENTER", modeBtn, "CENTER", 0, 0)

    local modeOrder = {"damage", "healing", "dispels", "decurse", "deaths"}
    local modeLabels = {
        damage = "Damage",
        healing = "Healing",
        dispels = "Dispels",
        decurse = "Decurse",
        deaths = "Deaths"
    }

    -- Set initial mode text
    modeBtnText:SetText(modeLabels[mode] or "Damage")

    modeBtn:SetScript("OnClick", function()
        -- Find current mode index
        local currentIndex = 1
        for i, m in ipairs(modeOrder) do
            if m == secFrame.mode then
                currentIndex = i
                break
            end
        end

        -- Cycle to next mode
        local nextIndex = currentIndex + 1
        if nextIndex > table.getn(modeOrder) then
            nextIndex = 1
        end

        local newMode = modeOrder[nextIndex]
        modeBtnText:SetText(modeLabels[newMode])

        -- Update the secondary window with new mode
        secFrame.mode = newMode
        MainFrame:UpdateSecondaryWindow(secFrame)
    end)

    modeBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Mode: " .. (modeLabels[secFrame.mode] or secFrame.mode), 1, 1, 1)
        GameTooltip:AddLine("Click to cycle modes", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    modeBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    secFrame.modeBtn = modeBtn

    -- Combat History button
    local combatBtn = CreateFrame("Button", nil, secFrame)
    combatBtn:SetWidth(18)
    combatBtn:SetHeight(18)
    combatBtn:SetPoint("LEFT", modeBtn, "RIGHT", 1, 0)
    combatBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    combatBtn:SetBackdropColor(0.2, 0.5, 0.8, 1)
    local combatText = combatBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    combatText:SetPoint("CENTER", combatBtn, "CENTER", 0, 0)
    combatText:SetText("C")
    combatBtn:SetScript("OnClick", function()
        MainFrame:ShowCombatHistory()
    end)
    combatBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Combat History", 1, 1, 1)
        GameTooltip:AddLine("View past combats", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    combatBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Toggle DPS/Total button
    local toggleBtn = CreateFrame("Button", nil, secFrame)
    toggleBtn:SetWidth(26)
    toggleBtn:SetHeight(18)
    toggleBtn:SetPoint("LEFT", combatBtn, "RIGHT", 1, 0)
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
    toggleBtn:SetScript("OnClick", function()
        secFrame.showPerSecond = not secFrame.showPerSecond
        if secFrame.showPerSecond then
            toggleText:SetText("/s")
        else
            toggleText:SetText("T")
        end
        MainFrame:UpdateSecondaryWindow(secFrame)
    end)
    toggleBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        if secFrame.showPerSecond then
            GameTooltip:SetText("Per Second (/s)", 1, 1, 1)
            GameTooltip:AddLine("Click for Total", 0.8, 0.8, 0.8)
        else
            GameTooltip:SetText("Total (T)", 1, 1, 1)
            GameTooltip:AddLine("Click for Per Second", 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    toggleBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Report button
    local reportBtn = CreateFrame("Button", nil, secFrame)
    reportBtn:SetWidth(22)
    reportBtn:SetHeight(18)
    reportBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 1, 0)
    reportBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    reportBtn:SetBackdropColor(0.3, 0.6, 1, 1)
    local reportText = reportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reportText:SetPoint("CENTER", reportBtn, "CENTER", 0, 0)
    reportText:SetText("R")
    reportBtn:SetScript("OnClick", function()
        MainFrame:ShowReportMenu()
    end)
    reportBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Report Stats", 1, 1, 1)
        GameTooltip:AddLine("Output stats to chat", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    reportBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Reset button (X) - fifth button
    local resetBtn = CreateFrame("Button", nil, secFrame)
    resetBtn:SetWidth(18)
    resetBtn:SetHeight(18)
    resetBtn:SetPoint("LEFT", reportBtn, "RIGHT", 1, 0)
    resetBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    resetBtn:SetBackdropColor(0.6, 0.2, 0.2, 1)
    local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetText:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    resetText:SetText("X")

    resetBtn:SetScript("OnClick", function()
        local DataStore = DPSLight_DataStore
        if not DataStore then return end

        -- Reset data for current segment
        DataStore:ClearSegment()
        MainFrame:UpdateSecondaryWindow(secFrame)
        DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Data reset for current segment", 1, 1, 0)
    end)

    resetBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Reset Data", 1, 1, 1)
        GameTooltip:AddLine("Clear stats for current segment", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    resetBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    secFrame.resetBtn = resetBtn

    -- Footer (like main window)
    local footer = secFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOM", secFrame, "BOTTOM", 0, 10)
    footer:SetPoint("LEFT", secFrame, "LEFT", 5, 10)
    footer:SetPoint("RIGHT", secFrame, "RIGHT", -5, 10)
    footer:SetJustifyH("CENTER")
    footer:SetText("Secondary Window")
    secFrame.footer = footer

    -- Update footer function for secondary window
    local function UpdateSecondaryFooter()
        local Database = DPSLight_Database
        if not Database then return end

        local footerInfo = Database:GetSetting("footerInfo") or {}
        local parts = {}

        if footerInfo.fps then
            table.insert(parts, string.format("FPS: %d", GetFramerate()))
        end

        if footerInfo.latency then
            local _, _, lag = GetNetStats()
            table.insert(parts, string.format("Latency: %dms", lag))
        end

        if footerInfo.memory then
            local mem = gcinfo()
            table.insert(parts, string.format("Mem: %.1fMB", mem / 1024))
        end

        if table.getn(parts) == 0 then
            local modeLabels = {damage = "Damage", healing = "Healing", dispels = "Dispels", decurse = "Decurse", deaths = "Deaths"}
            footer:SetText(modeLabels[mode] or mode)
        else
            local text = table.concat(parts, " | ")
            footer:SetText(text)
        end
    end
    secFrame.UpdateFooter = UpdateSecondaryFooter

    -- Close button
    local closeBtn = CreateFrame("Button", nil, secFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", secFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        -- Remove from global windows table
        if DPSLight_AllWindows then
            for i = table.getn(DPSLight_AllWindows), 1, -1 do
                if DPSLight_AllWindows[i] == secFrame then
                    table.remove(DPSLight_AllWindows, i)
                    break
                end
            end
        end
        secFrame:Hide()
    end)

    -- Resize button
    local resizeBtn = CreateFrame("Button", nil, secFrame)
    resizeBtn:SetWidth(16)
    resizeBtn:SetHeight(16)
    resizeBtn:SetPoint("BOTTOMRIGHT", secFrame, "BOTTOMRIGHT", -2, 2)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function() secFrame:StartSizing("BOTTOMRIGHT") end)
    resizeBtn:SetScript("OnMouseUp", function()
        secFrame:StopMovingOrSizing()
        SnapToNearbyWindows(secFrame)
    end)

    -- Create scroll list for secondary window
    local VirtualScroll = GetVirtualScroll()
    if VirtualScroll then
        local secScrollList = VirtualScroll:New(secFrame, 360, 370, 18)
        if secScrollList then
            secScrollList:GetFrame():SetPoint("TOPLEFT", secFrame, "TOPLEFT", 10, -40)
            secFrame.scrollList = secScrollList
            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Scroll list created", 0, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Failed to create scroll list", 1, 0, 0)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("DPSLight: VirtualScroll not found", 1, 0, 0)
    end

    -- Store mode
    secFrame.mode = mode

    -- Update timer for secondary window
    secFrame.updateTimer = 0
    secFrame.footerTimer = 0
    secFrame:SetScript("OnUpdate", function()
        this.updateTimer = this.updateTimer + arg1
        if this.updateTimer >= 0.5 then
            MainFrame:UpdateSecondaryWindow(this)
            this.updateTimer = 0
        end

        -- Update footer every 1 second
        this.footerTimer = this.footerTimer + arg1
        if this.footerTimer >= 1.0 then
            if this.UpdateFooter then
                this:UpdateFooter()
            end
            this.footerTimer = 0
        end
    end)

    secFrame:Show()
    DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Secondary window created for " .. mode, 0, 1, 0)
end

-- Update secondary window
function MainFrame:UpdateSecondaryWindow(secFrame)
    if not secFrame or not secFrame:IsVisible() or not secFrame.scrollList then return end

    local mode = secFrame.mode
    local data = {}

    -- Get data based on mode (reuse logic from UpdateDisplay)
    if mode == "damage" then
        local Damage = GetDamage()
        local Utils = GetUtils()
        if not Damage or not Utils then return end

        local damageData = Damage:GetSortedData()
        if not damageData then return end

        for i, entry in ipairs(damageData) do
            local displayValue
            if secFrame.showPerSecond then
                displayValue = Damage:GetDPS(nil, entry.userID)
            else
                displayValue = entry.total or 0
            end
            local percent = Damage:GetPercent(nil, entry.userID)
            local class = Utils:GetUnitClass(entry.username)

            table.insert(data, {
                name = entry.username,
                value = displayValue,
                percent = percent,
                color = {r = 0.8, g = 0.2, b = 0.2},
                classColor = Utils:GetClassColor(class),
                class = class,
                userID = entry.userID,
                module = "damage",
            })
        end
    elseif mode == "healing" then
        local Healing = GetHealing()
        local Utils = GetUtils()
        if not Healing or not Utils then return end

        local healingData = Healing:GetSortedData()
        if not healingData then return end

        for i, entry in ipairs(healingData) do
            local displayValue
            if secFrame.showPerSecond then
                displayValue = Healing:GetHPS(nil, entry.userID)
            else
                displayValue = entry.total or 0
            end
            local percent = Healing:GetPercent(nil, entry.userID)
            local class = Utils:GetUnitClass(entry.username)

            table.insert(data, {
                name = entry.username,
                value = displayValue,
                percent = percent,
                color = {r = 0.2, g = 0.8, b = 0.2},
                classColor = Utils:GetClassColor(class),
                class = class,
                userID = entry.userID,
                module = "healing",
            })
        end
    elseif mode == "dispels" then
        local Dispels = DPSLight_Dispels
        if Dispels then
            local dispelData = Dispels:GetSortedData()
            if dispelData then
                for i, entry in ipairs(dispelData) do
                    table.insert(data, {
                        name = entry.username,
                        value = entry.total,
                        percent = 0,
                        color = {r = 0.5, g = 0.5, b = 1},
                        class = entry.class,
                        userID = entry.userID,
                        module = "dispels",
                    })
                end
            end
        end
    elseif mode == "decurse" then
        local Decurse = DPSLight_Decurse
        if Decurse then
            local decurseData = Decurse:GetSortedData()
            if decurseData then
                for i, entry in ipairs(decurseData) do
                    table.insert(data, {
                        name = entry.username,
                        value = entry.total,
                        percent = 0,
                        color = {r = 0.5, g = 1, b = 0.5},
                        class = entry.class,
                        userID = entry.userID,
                        module = "decurse",
                    })
                end
            end
        end
    elseif mode == "deaths" then
        local Deaths = DPSLight_Deaths
        if Deaths then
            local deathData = Deaths:GetSortedData()
            if deathData then
                for i, entry in ipairs(deathData) do
                    table.insert(data, {
                        name = entry.username,
                        value = entry.total,
                        percent = 0,
                        color = {r = 0.7, g = 0.7, b = 0.7},
                        class = entry.class,
                        userID = entry.userID,
                        module = "deaths",
                    })
                end
            end
        end
    end

    secFrame.scrollList:SetData(data)
end

-- Update display
function MainFrame:UpdateDisplay()
    if not frame or not frame:IsVisible() then return end

    local data = {}

    if currentMode == "damage" then
        local Damage = GetDamage()
        local Utils = GetUtils()
        if not Damage or not Utils then return end

        local damageData = Damage:GetSortedData()
        if not damageData then return end

        -- Apply filters (cache values to reduce API calls)
        local playerName = UnitName("player")
        local filteredData = {}
        local numRaid = GetNumRaidMembers()
        local numParty = GetNumPartyMembers()
        local maxToShow = maxPlayersToShow

        -- Build group/raid member cache if needed
        local groupMembers = {}
        if filterMode == "group" or filterMode == "raid" then
            -- Always include player
            groupMembers[playerName] = true

            if numRaid > 0 and filterMode == "raid" then
                for j = 1, numRaid do
                    local name = UnitName("raid" .. j)
                    if name then groupMembers[name] = true end
                end
            elseif filterMode == "group" then
                for j = 1, numParty do
                    local name = UnitName("party" .. j)
                    if name then groupMembers[name] = true end
                end
            end
        end

        for _, entry in ipairs(damageData) do
            local shouldShow = false

            -- Filter: Show self only
            if showSelfOnly then
                shouldShow = (entry.username == playerName)
            -- Filter: Group/Raid (use cached members)
            elseif filterMode == "group" or filterMode == "raid" then
                shouldShow = groupMembers[entry.username]
            -- Filter: All
            else
                shouldShow = true
            end

            if shouldShow then
                table.insert(filteredData, entry)
                if table.getn(filteredData) >= maxPlayersToShow then
                    break
                end
            end
        end

        for i, entry in ipairs(filteredData) do
            -- Show DPS or Total based on toggle
            local displayValue
            if showPerSecond then
                displayValue = Damage:GetDPS(nil, entry.userID)
            else
                displayValue = entry.total or 0
            end

            local percent = Damage:GetPercent(nil, entry.userID)
            local class = Utils:GetUnitClass(entry.username)
            local tooltip = Damage:GetTooltipData(nil, entry.userID)

            -- Medal colors for top 3
            local color = {0.8, 0.2, 0.2}
            if i == 1 then
                color = {1.0, 0.84, 0} -- Gold
            elseif i == 2 then
                color = {0.75, 0.75, 0.75} -- Silver
            elseif i == 3 then
                color = {0.8, 0.5, 0.2} -- Bronze
            end

            table.insert(data, {
                name = entry.username,
                value = displayValue,
                percent = percent,
                color = color,
                classColor = Utils:GetClassColor(class),
                class = class,
                tooltip = tooltip,
                userID = entry.userID,
                module = "damage",
            })
        end

    elseif currentMode == "healing" then
        local Healing = GetHealing()
        local Utils = GetUtils()
        if not Healing or not Utils then return end

        local healingData = Healing:GetSortedData()
        if not healingData then return end

        -- Apply filters (reuse cache from damage section)
        local playerName = UnitName("player")
        local filteredData = {}
        local numRaid = GetNumRaidMembers()
        local numParty = GetNumPartyMembers()

        -- Build group/raid member cache if needed
        local groupMembers = {}
        if filterMode == "group" or filterMode == "raid" then
            -- Always include player
            groupMembers[playerName] = true

            if numRaid > 0 and filterMode == "raid" then
                for j = 1, numRaid do
                    local name = UnitName("raid" .. j)
                    if name then groupMembers[name] = true end
                end
            elseif filterMode == "group" then
                for j = 1, numParty do
                    local name = UnitName("party" .. j)
                    if name then groupMembers[name] = true end
                end
            end
        end

        for _, entry in ipairs(healingData) do
            local shouldShow = false

            -- Filter: Show self only
            if showSelfOnly then
                shouldShow = (entry.username == playerName)
            elseif filterMode == "group" or filterMode == "raid" then
                shouldShow = groupMembers[entry.username]
            else
                shouldShow = true
            end

            if shouldShow then
                table.insert(filteredData, entry)
                if table.getn(filteredData) >= maxPlayersToShow then
                    break
                end
            end
        end

        for i, entry in ipairs(filteredData) do
            -- Show HPS or Total based on toggle
            local displayValue
            if showPerSecond then
                displayValue = Healing:GetHPS(nil, entry.userID)
            else
                displayValue = entry.total or 0
            end

            local percent = Healing:GetPercent(nil, entry.userID)
            local class = Utils:GetUnitClass(entry.username)
            local tooltip = Healing:GetTooltipData(nil, entry.userID)

            -- Medal colors for top 3
            local color = Healing:GetBarColor(i, class)
            if i == 1 then
                color = {1.0, 0.84, 0}
            elseif i == 2 then
                color = {0.75, 0.75, 0.75}
            elseif i == 3 then
                color = {0.8, 0.5, 0.2}
            end

            table.insert(data, {
                name = entry.username,
                value = displayValue,
                percent = percent,
                color = color,
                classColor = Utils:GetClassColor(class),
                class = class,
                userID = entry.userID,
                module = "healing",
                tooltip = tooltip,
            })
        end

    elseif currentMode == "dispels" then
        local Dispels = DPSLight_Dispels
        local Utils = GetUtils()
        if not Dispels or not Utils or not Dispels.GetSortedData then return end

        local dispelsData = Dispels:GetSortedData()
        if not dispelsData then return end

        for i, entry in ipairs(dispelsData) do
            local total = entry.total or Dispels:GetTotal(nil, entry.userID)
            local percent = Dispels:GetPercent(nil, entry.userID)
            local class = Utils:GetUnitClass(entry.username)
            local tooltip = Dispels:GetTooltipData(nil, entry.userID)

            table.insert(data, {
                name = entry.username,
                value = total,
                percent = percent,
                color = {0.5, 0.5, 1.0},
                classColor = Utils:GetClassColor(class),
                class = class,
                userID = entry.userID,
                module = "dispels",
                tooltip = tooltip,
            })
        end

    elseif currentMode == "decurse" then
        local Decurse = DPSLight_Decurse
        local Utils = GetUtils()
        if not Decurse or not Utils or not Decurse.GetSortedData then return end

        local decurseData = Decurse:GetSortedData()
        if not decurseData then return end

        for i, entry in ipairs(decurseData) do
            local total = entry.total or Decurse:GetTotal(nil, entry.userID)
            local percent = Decurse:GetPercent(nil, entry.userID)
            local class = Utils:GetUnitClass(entry.username)
            local tooltip = Decurse:GetTooltipData(nil, entry.userID)

            table.insert(data, {
                name = entry.username,
                value = total,
                percent = percent,
                color = {0.8, 0.4, 0.8},
                classColor = Utils:GetClassColor(class),
                class = class,
                userID = entry.userID,
                module = "decurse",
                tooltip = tooltip,
            })
        end

    elseif currentMode == "deaths" then
        local Deaths = DPSLight_Deaths
        local Utils = GetUtils()
        if not Deaths or not Utils or not Deaths.GetSortedData then return end

        local deathData = Deaths:GetSortedData()
        if not deathData then return end

        for i, entry in ipairs(deathData) do
            local deathCount = entry.deaths or 0
            local class = Utils:GetUnitClass(entry.username)

            table.insert(data, {
                name = entry.username,
                value = deathCount,
                percent = 0,
                color = {0.5, 0.5, 0.5},
                classColor = Utils:GetClassColor(class),
                class = class,
                userID = entry.userID,
                module = "deaths",
                tooltip = string.format("Deaths: %d", deathCount),
            })
        end
    end

    if scrollList then
        scrollList:SetData(data)
    end

    -- Update footer using the proper function that respects user preferences
    if frame and frame.UpdateFooter then
        frame:UpdateFooter()
    end
end

-- Show frame
function MainFrame:Show()
    if not frame then
        self:Create()
    end
    frame:Show()
    self:UpdateDisplay()
end

-- Hide frame
function MainFrame:Hide()
    if frame then
        frame:Hide()
    end
end

-- Toggle frame
function MainFrame:Toggle()
    if frame and frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

-- Update button layout based on saved order
function MainFrame:UpdateButtonLayout()
    if not frame then return end

    local Database = DPSLight_Database
    if not Database then return end

    -- Get button order from database
    local defaultOrder = {"modeBtn", "combatBtn", "dpsToggleBtn", "reportBtn", "resetBtn"}
    local buttonOrder = Database:GetSetting("buttonOrder") or defaultOrder

    -- Reposition buttons according to order
    local prevButton = nil
    local leftMargin = 10

    for i, btnKey in ipairs(buttonOrder) do
        local btn = frame[btnKey]
        if btn then
            btn:ClearAllPoints()
            if not prevButton then
                -- First button - anchor to frame left
                btn:SetPoint("TOPLEFT", frame, "TOPLEFT", leftMargin, -10)
            else
                -- Subsequent buttons - anchor to previous button
                btn:SetPoint("LEFT", prevButton, "RIGHT", 4, 0)
            end
            prevButton = btn
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Button layout updated", 1, 1, 0)
end

-- Get frame
function MainFrame:GetFrame()
    return frame
end

-- Initialize combat detection
function MainFrame:InitializeCombatDetection()
    if not frame then return end

    frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entered combat
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Left combat

    local oldOnEvent = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function()
        if oldOnEvent then oldOnEvent() end

        local DataStore = DPSLight_DataStore
        if not DataStore then return end

        if event == "PLAYER_REGEN_DISABLED" then
            -- Entered combat
            DataStore:StartCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Left combat (with 3 second delay)
            this.combatEndTimer = 3
        end
    end)

    -- Add to OnUpdate for delayed combat end
    local oldOnUpdate = frame:GetScript("OnUpdate")
    frame:SetScript("OnUpdate", function()
        if oldOnUpdate then oldOnUpdate() end

        if this.combatEndTimer and this.combatEndTimer > 0 then
            this.combatEndTimer = this.combatEndTimer - arg1
            if this.combatEndTimer <= 0 then
                local DataStore = DPSLight_DataStore
                if DataStore then
                    DataStore:EndCombat()
                    -- Update combat history if window is open
                    if frame.combatHistory and frame.combatHistory:IsVisible() then
                        MainFrame:UpdateCombatHistoryList()
                    end
                end
                this.combatEndTimer = nil
            end
        end
    end)
end

-- Update controls visibility based on settings
function MainFrame:UpdateControlsVisibility()
    if not frame then return end
    local Database = DPSLight_Database
    local showControls = Database and Database:GetSetting("showControls")
    if showControls == nil then showControls = true end

    -- Update button visibility based on both showControls and buttonVisibility settings
    local btnVisibility = Database and Database:GetSetting("buttonVisibility") or {}

    if frame.modeBtn then
        local visible = showControls and (btnVisibility.modeBtn ~= false)
        if visible then frame.modeBtn:Show() else frame.modeBtn:Hide() end
    end
    if frame.combatHistoryBtn then
        local visible = showControls and (btnVisibility.combatBtn ~= false)
        if visible then frame.combatHistoryBtn:Show() else frame.combatHistoryBtn:Hide() end
    end
    if frame.dpsToggleBtn then
        local visible = showControls and (btnVisibility.dpsToggleBtn ~= false)
        if visible then frame.dpsToggleBtn:Show() else frame.dpsToggleBtn:Hide() end
    end
    if frame.reportBtn then
        local visible = showControls and (btnVisibility.reportBtn ~= false)
        if visible then frame.reportBtn:Show() else frame.reportBtn:Hide() end
    end
    if frame.resetBtn then
        local visible = showControls and (btnVisibility.resetBtn ~= false)
        if visible then frame.resetBtn:Show() else frame.resetBtn:Hide() end
    end
end

-- Update button visibility
function MainFrame:UpdateButtonVisibility()
    MainFrame:UpdateControlsVisibility()
end

-- Update border style
function MainFrame:UpdateBorderStyle()
    if not frame then return end
    local Database = DPSLight_Database
    local borderStyle = Database and Database:GetSetting("borderStyle") or 1
    local opacity = Database and Database:GetSetting("opacity") or 0.9
    local bgColor = Database and Database:GetSetting("bgColor") or {r=0, g=0, b=0, a=opacity}

    -- Border styles mapping (MUST match ApplyUnifiedStyle exactly!)
    local borders = {
        {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16},
        {edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32},
        {edgeFile = "Interface\\GLUES\\COMMON\\TextPanel-Border", edgeSize = 16},
        {edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border", edgeSize = 12},
        {edgeFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-WoodBorder", edgeSize = 32},
        {edgeFile = "Interface\\COMMON\\Indicator-Gray", edgeSize = 8},
    }

    local border = borders[borderStyle] or borders[1]

    -- Update backdrop with unified style
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = border.edgeFile,
        tile = true,
        tileSize = 16,
        edgeSize = border.edgeSize,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })

    -- Reapply colors
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, opacity)
    frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
end

-- Update footer display
function MainFrame:UpdateFooter()
    if not frame or not frame.footer then return end
    local Database = DPSLight_Database
    local showFooter = Database and Database:GetSetting("showFooter")
    if showFooter == nil then showFooter = true end

    if showFooter then
        frame.footer:Show()
    else
        frame.footer:Hide()
    end
end

return MainFrame
