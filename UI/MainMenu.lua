-- MainMenu.lua - Modern multi-tab menu system inspired by modern UI design
-- Tabs: Configuration | Skins | Secondary Windows

local MainMenu = {}
DPSLight_MainMenu = MainMenu

local menuFrame = nil
local currentTab = "config" -- config, skins, windows

-- Theme definitions (9 classes + 4 elements + 3 legendary animals)
local THEMES = {
    -- Class themes
    warrior = {name = "Warrior", color = {r=0.78, g=0.61, b=0.43}, icon = "Interface\\Icons\\ClassIcon_Warrior"},
    mage = {name = "Mage", color = {r=0.41, g=0.8, b=0.94}, icon = "Interface\\Icons\\ClassIcon_Mage"},
    priest = {name = "Priest", color = {r=1, g=1, b=1}, icon = "Interface\\Icons\\ClassIcon_Priest"},
    rogue = {name = "Rogue", color = {r=1, g=0.96, b=0.41}, icon = "Interface\\Icons\\ClassIcon_Rogue"},
    druid = {name = "Druid", color = {r=1, g=0.49, b=0.04}, icon = "Interface\\Icons\\ClassIcon_Druid"},
    hunter = {name = "Hunter", color = {r=0.67, g=0.83, b=0.45}, icon = "Interface\\Icons\\ClassIcon_Hunter"},
    warlock = {name = "Warlock", color = {r=0.58, g=0.51, b=0.79}, icon = "Interface\\Icons\\ClassIcon_Warlock"},
    paladin = {name = "Paladin", color = {r=0.96, g=0.55, b=0.73}, icon = "Interface\\Icons\\ClassIcon_Paladin"},
    shaman = {name = "Shaman", color = {r=0, g=0.44, b=0.87}, icon = "Interface\\Icons\\ClassIcon_Shaman"},

    -- Element themes
    fire = {name = "Fire", color = {r=1, g=0.3, b=0}, icon = "Interface\\Icons\\Spell_Fire_FlameBolt"},
    water = {name = "Water", color = {r=0.2, g=0.6, b=1}, icon = "Interface\\Icons\\Spell_Frost_FrostBolt02"},
    earth = {name = "Earth", color = {r=0.6, g=0.4, b=0.2}, icon = "Interface\\Icons\\Spell_Nature_Earthquake"},
    air = {name = "Air", color = {r=0.9, g=1, b=1}, icon = "Interface\\Icons\\Spell_Nature_Cyclone"},

    -- Legendary animal themes
    dragon = {name = "Dragon", color = {r=0.8, g=0.1, b=0.1}, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01"},
    wolf = {name = "Wolf", color = {r=0.5, g=0.5, b=0.5}, icon = "Interface\\Icons\\Ability_Mount_WhiteDireWolf"},
    lion = {name = "Lion", color = {r=1, g=0.7, b=0.1}, icon = "Interface\\Icons\\INV_Misc_Head_Cat_01"},
}

-- Create main menu frame
function MainMenu:Create()
    if menuFrame then
        menuFrame:Show()
        return menuFrame
    end

    -- Main frame (larger, centered)
    menuFrame = CreateFrame("Frame", "DPSLight_MainMenu", UIParent)
    menuFrame:SetWidth(720)
    menuFrame:SetHeight(520)
    menuFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    menuFrame:SetFrameStrata("DIALOG")
    menuFrame:SetMovable(true)
    menuFrame:EnableMouse(true)
    menuFrame:SetClampedToScreen(true)

    -- Modern dark background
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    menuFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    menuFrame:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)

    -- Title bar (draggable)
    local titleBar = CreateFrame("Frame", nil, menuFrame)
    titleBar:SetHeight(35)
    titleBar:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", 0, 0)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() menuFrame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() menuFrame:StopMovingOrSizing() end)

    -- Title gradient background
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints(titleBar)
    titleBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    titleBg:SetGradientAlpha("VERTICAL", 0.15, 0.15, 0.2, 1, 0.08, 0.08, 0.12, 1)

    -- Title text
    local titleText = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 15, 0)
    titleText:SetText("DPSLight")
    titleText:SetTextColor(1, 0.85, 0)

    -- Version text
    local versionText = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, 0)
    versionText:SetText("v1.1.1")
    versionText:SetTextColor(0.5, 0.5, 0.5)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, menuFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -3, -3)
    closeBtn:SetWidth(28)
    closeBtn:SetHeight(28)
    closeBtn:SetScript("OnClick", function() menuFrame:Hide() end)

    -- Tab buttons (horizontal layout)
    local tabButtons = {}
    local tabs = {
        {key = "config", label = "Configuration", icon = "Interface\\Icons\\INV_Misc_Gear_01"},
        {key = "skins", label = "Skins & Themes", icon = "Interface\\Icons\\INV_Misc_PaintBrush_01"},
        {key = "windows", label = "Secondary Windows", icon = "Interface\\Icons\\INV_Misc_Note_01"}
    }

    local tabY = -40
    local tabX = 10
    local tabWidth = 230
    local tabHeight = 30
    local tabSpacing = 5

    for i, tab in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, menuFrame)
        btn:SetWidth(tabWidth)
        btn:SetHeight(tabHeight)
        btn:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", tabX + (i-1) * (tabWidth + tabSpacing), tabY)

        -- Button background
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })

        -- Icon
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(20)
        icon:SetHeight(20)
        icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
        icon:SetTexture(tab.icon)

        -- Label
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(tab.label)

        btn.tabKey = tab.key
        btn.label = label
        btn.bg = btn

        btn:SetScript("OnClick", function()
            MainMenu:SwitchTab(this.tabKey)
        end)

        btn:SetScript("OnEnter", function()
            if currentTab ~= this.tabKey then
                this:SetBackdropColor(0.2, 0.2, 0.3, 0.8)
            end
        end)

        btn:SetScript("OnLeave", function()
            if currentTab ~= this.tabKey then
                this:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
            end
        end)

        tabButtons[tab.key] = btn
    end

    menuFrame.tabButtons = tabButtons

    -- Content area (below tabs)
    local contentFrame = CreateFrame("Frame", nil, menuFrame)
    contentFrame:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 10, tabY - tabHeight - 10)
    contentFrame:SetPoint("BOTTOMRIGHT", menuFrame, "BOTTOMRIGHT", -10, 10)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = true, tileSize = 16,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    contentFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.9)

    menuFrame.contentFrame = contentFrame

    -- Create tab content frames
    self:CreateConfigTab()
    self:CreateSkinsTab()
    self:CreateWindowsTab()

    -- Set initial tab
    self:SwitchTab("config")

    menuFrame:Hide()
    return menuFrame
end

-- Switch between tabs
function MainMenu:SwitchTab(tabKey)
    currentTab = tabKey

    -- Update tab button appearances
    for key, btn in pairs(menuFrame.tabButtons) do
        if key == tabKey then
            btn:SetBackdropColor(0.25, 0.25, 0.35, 1)
            btn:SetBackdropBorderColor(0.5, 0.5, 0.7, 1)
            btn.label:SetTextColor(1, 0.85, 0)
        else
            btn:SetBackdropColor(0.1, 0.1, 0.15, 0.8)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)
            btn.label:SetTextColor(0.8, 0.8, 0.8)
        end
    end

    -- Show/hide content frames
    if menuFrame.configContent then
        if tabKey == "config" then
            menuFrame.configContent:Show()
        else
            menuFrame.configContent:Hide()
        end
    end
    if menuFrame.skinsContent then
        if tabKey == "skins" then
            menuFrame.skinsContent:Show()
        else
            menuFrame.skinsContent:Hide()
        end
    end
    if menuFrame.windowsContent then
        if tabKey == "windows" then
            menuFrame.windowsContent:Show()
        else
            menuFrame.windowsContent:Hide()
        end
    end
end

-- Create Configuration tab content
function MainMenu:CreateConfigTab()
    local scrollFrame = CreateFrame("ScrollFrame", nil, menuFrame.contentFrame)
    scrollFrame:SetPoint("TOPLEFT", menuFrame.contentFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", menuFrame.contentFrame, "BOTTOMRIGHT", -20, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(660)
    content:SetHeight(1800)
    scrollFrame:SetScrollChild(content)

    -- Scrollbar
    local scrollBar = CreateFrame("Slider", nil, scrollFrame)
    scrollBar:SetPoint("TOPRIGHT", menuFrame.contentFrame, "TOPRIGHT", -5, -10)
    scrollBar:SetPoint("BOTTOMRIGHT", menuFrame.contentFrame, "BOTTOMRIGHT", -5, 10)
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
    thumb:SetWidth(14)
    thumb:SetHeight(25)
    thumb:SetVertexColor(0.6, 0.6, 0.6, 0.9)
    scrollBar:SetThumbTexture(thumb)

    scrollBar:SetScript("OnValueChanged", function()
        local maxScroll = content:GetHeight() - scrollFrame:GetHeight()
        if maxScroll > 0 then
            scrollFrame:SetVerticalScroll(arg1 * maxScroll)
        end
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollBar:GetValue()
        local maxScroll = content:GetHeight() - scrollFrame:GetHeight()
        if maxScroll > 0 then
            local step = (arg1 > 0) and -0.05 or 0.05
            local newValue = math.max(0, math.min(1, current + step))
            scrollBar:SetValue(newValue)
        end
    end)

    local scrollChild = content

    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", scrollChild, "TOP", 0, -15)
    title:SetText("DPSLight Configuration")
    title:SetTextColor(1, 0.82, 0)

    -- Helper function to create collapsible section header
    local function CreateSection(parent, yPos, text, color)
        local section = CreateFrame("Button", nil, parent)
        section:SetWidth(630)
        section:SetHeight(30)
        section:SetPoint("TOP", parent, "TOP", 0, yPos)
        section:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        section:SetBackdropColor(color.r or 0.2, color.g or 0.2, color.b or 0.3, 0.7)
        section:SetBackdropBorderColor(color.r or 0.5, color.g or 0.5, color.b or 0.6, 1)

        -- Make clickable
        section:EnableMouse(true)
        section:RegisterForClicks("LeftButtonUp")

        -- Collapse indicator
        local indicator = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        indicator:SetPoint("LEFT", section, "LEFT", 10, 0)
        indicator:SetText("[-]")
        indicator:SetTextColor(1, 0.82, 0)
        section.indicator = indicator

        local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("LEFT", indicator, "RIGHT", 5, 0)
        label:SetText(text)
        label:SetTextColor(1, 1, 1)

        -- Track collapsed state
        section.isCollapsed = false
        section.content = {}

        -- Hover effect
        section:SetScript("OnEnter", function()
            this:SetBackdropColor((color.r or 0.2) * 1.3, (color.g or 0.2) * 1.3, (color.b or 0.3) * 1.3, 0.8)
        end)
        section:SetScript("OnLeave", function()
            this:SetBackdropColor(color.r or 0.2, color.g or 0.2, color.b or 0.3, 0.7)
        end)

        -- Store reference to reposition function
        section.repositionFunc = nil

        -- Toggle collapse/expand
        section:SetScript("OnClick", function()
            this.isCollapsed = not this.isCollapsed
            if this.isCollapsed then
                this.indicator:SetText("[+]")
                -- Hide all content in this section
                for _, frame in ipairs(this.content) do
                    if frame and frame.Hide then
                        frame:Hide()
                    end
                end
            else
                this.indicator:SetText("[-]")
                -- Show all content in this section
                for _, frame in ipairs(this.content) do
                    if frame and frame.Show then
                        frame:Show()
                    end
                end
            end

            -- Reposition all sections dynamically
            if this.repositionFunc then
                this.repositionFunc()
            end
        end)

        return section
    end

    local yOffset = -50
    local Database = DPSLight_Database

    -- Table to track all sections for dynamic repositioning
    local allSections = {}

    -- Function to reposition all sections dynamically
    local function RepositionSections()
        local currentY = -50
        for _, section in ipairs(allSections) do
            section:ClearAllPoints()
            section:SetPoint("TOP", scrollChild, "TOP", 0, currentY)
            currentY = currentY - 40

            -- Calculate content height if section is expanded
            if not section.isCollapsed then
                local contentHeight = 0
                for _, frame in ipairs(section.content) do
                    if frame and frame:IsVisible() then
                        local frameHeight = frame:GetHeight() or 25
                        contentHeight = contentHeight + frameHeight + 5
                    end
                end
                currentY = currentY - contentHeight
            end
            currentY = currentY - 10  -- Space between sections
        end
    end

    -- ========== SECTION: BUTTON VISIBILITY ==========
    local buttonVisSection = CreateSection(scrollChild, yOffset, "Button Visibility", {r=0.2, g=0.4, b=0.6})
    table.insert(allSections, buttonVisSection)
    yOffset = yOffset - 40

    -- Show Controls Master Toggle
    local controlsCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    controlsCheck:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    controlsCheck:SetChecked(Database and Database:GetSetting("showControls") ~= false)
    local controlsText = controlsCheck:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    controlsText:SetPoint("LEFT", controlsCheck, "RIGHT", 5, 0)
    controlsText:SetText("Show All Buttons")
    controlsText:SetTextColor(1, 0.8, 0)
    table.insert(buttonVisSection.content, controlsCheck)
    controlsCheck:SetScript("OnClick", function()
        if Database then
            Database:SetSetting("showControls", this:GetChecked())
            local MainFrame = DPSLight_MainFrame
            if MainFrame and MainFrame.GetFrame then
                local frame = MainFrame:GetFrame()
                if frame then
                    local buttons = {"modeBtn", "combatBtn", "dpsToggleBtn", "reportBtn", "resetBtn"}
                    for _, btnName in ipairs(buttons) do
                        if frame[btnName] then
                            if this:GetChecked() then
                                frame[btnName]:Show()
                            else
                                frame[btnName]:Hide()
                            end
                        end
                    end
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Control buttons " .. (this:GetChecked() and "shown" or "hidden"), 1, 1, 0)
        end
    end)
    yOffset = yOffset - 30

    -- Individual button visibility checkboxes with reorder buttons
    local buttonVisibility = Database and Database:GetSetting("buttonVisibility") or {}

    -- Get button order from database or use default
    local defaultOrder = {"modeBtn", "combatBtn", "dpsToggleBtn", "reportBtn", "resetBtn"}
    local buttonOrder = Database and Database:GetSetting("buttonOrder") or defaultOrder

    -- Button metadata lookup
    local buttonMetadata = {
        modeBtn = {label = "Mode Button"},
        combatBtn = {label = "Combat History (C)"},
        dpsToggleBtn = {label = "DPS/Total Toggle (/s)"},
        reportBtn = {label = "Report Button (R)"},
        resetBtn = {label = "Reset Button (X)"},
    }

    -- Function to save button order and refresh layout
    local function SaveButtonOrderAndRefresh()
        if Database then
            Database:SetSetting("buttonOrder", buttonOrder)
            local MainFrame = DPSLight_MainFrame
            if MainFrame and MainFrame.UpdateButtonLayout then
                MainFrame:UpdateButtonLayout()
            end
        end
    end

    -- Display buttons in current order with Up/Down controls
    for i, btnKey in ipairs(buttonOrder) do
        local btn = buttonMetadata[btnKey]
        if btn then
            local rowFrame = CreateFrame("Frame", nil, scrollChild)
            rowFrame:SetWidth(350)
            rowFrame:SetHeight(25)
            rowFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 50, yOffset)
            table.insert(buttonVisSection.content, rowFrame)

            -- Checkbox
            local check = CreateFrame("CheckButton", nil, rowFrame, "UICheckButtonTemplate")
            check:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            check:SetChecked(buttonVisibility[btnKey] ~= false)

            local checkText = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            checkText:SetPoint("LEFT", check, "RIGHT", 5, 0)
            checkText:SetText(btn.label)

            -- Capture variables in closure
            local capturedKey = btnKey

            check:SetScript("OnClick", function()
                if Database then
                    local vis = Database:GetSetting("buttonVisibility") or {}
                    vis[capturedKey] = this:GetChecked()
                    Database:SetSetting("buttonVisibility", vis)

                    -- Apply visibility immediately
                    local MainFrame = DPSLight_MainFrame
                    if MainFrame and MainFrame.GetFrame then
                        local frame = MainFrame:GetFrame()
                        if frame and frame[capturedKey] then
                            if this:GetChecked() then
                                frame[capturedKey]:Show()
                            else
                                frame[capturedKey]:Hide()
                            end
                        end
                    end
                end
            end)

            -- Up button (move earlier in order) - HIGH VISIBILITY
            if i > 1 then
                local upBtn = CreateFrame("Button", nil, rowFrame)
                upBtn:SetWidth(28)
                upBtn:SetHeight(22)
                upBtn:SetPoint("RIGHT", rowFrame, "RIGHT", -32, 0)
                upBtn:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 16,
                    insets = {left = 4, right = 4, top = 4, bottom = 4}
                })
                upBtn:SetBackdropColor(1, 0.84, 0, 1)  -- Gold color for high visibility
                upBtn:SetBackdropBorderColor(0.8, 0.6, 0, 1)
                local upText = upBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                upText:SetPoint("CENTER", upBtn, "CENTER", 0, 0)
                upText:SetText("↑")
                upText:SetTextColor(0, 0, 0, 1)  -- Black text on gold background

                -- Hover effects for better UX
                upBtn:SetScript("OnEnter", function()
                    this:SetBackdropColor(1, 0.95, 0.4, 1)  -- Lighter gold on hover
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Move Up", 1, 1, 1)
                    GameTooltip:AddLine("Move this button earlier in order", 0.8, 0.8, 0.8)
                    GameTooltip:Show()
                end)
                upBtn:SetScript("OnLeave", function()
                    this:SetBackdropColor(1, 0.84, 0, 1)  -- Back to gold
                    GameTooltip:Hide()
                end)

                -- Capture index in closure
                local capturedIndex = i
                upBtn:SetScript("OnClick", function()
                    -- Swap with previous button
                    local temp = buttonOrder[capturedIndex]
                    buttonOrder[capturedIndex] = buttonOrder[capturedIndex - 1]
                    buttonOrder[capturedIndex - 1] = temp
                    SaveButtonOrderAndRefresh()
                    -- Refresh config menu to show new order
                    local MainMenu = DPSLight_MainMenu
                    if MainMenu and MainMenu.Show then
                        MainMenu:Show()
                    end
                end)
            end

            -- Down button (move later in order) - HIGH VISIBILITY
            if i < table.getn(buttonOrder) then
                local downBtn = CreateFrame("Button", nil, rowFrame)
                downBtn:SetWidth(28)
                downBtn:SetHeight(22)
                downBtn:SetPoint("RIGHT", rowFrame, "RIGHT", 0, 0)
                downBtn:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 16,
                    insets = {left = 4, right = 4, top = 4, bottom = 4}
                })
                downBtn:SetBackdropColor(1, 0.5, 0, 1)  -- Bright orange for high visibility
                downBtn:SetBackdropBorderColor(0.8, 0.3, 0, 1)
                local downText = downBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                downText:SetPoint("CENTER", downBtn, "CENTER", 0, 0)
                downText:SetText("↓")
                downText:SetTextColor(0, 0, 0, 1)  -- Black text on orange background

                -- Hover effects for better UX
                downBtn:SetScript("OnEnter", function()
                    this:SetBackdropColor(1, 0.7, 0.3, 1)  -- Lighter orange on hover
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Move Down", 1, 1, 1)
                    GameTooltip:AddLine("Move this button later in order", 0.8, 0.8, 0.8)
                    GameTooltip:Show()
                end)
                downBtn:SetScript("OnLeave", function()
                    this:SetBackdropColor(1, 0.5, 0, 1)  -- Back to orange
                    GameTooltip:Hide()
                end)

                -- Capture index in closure
                local capturedIndex = i
                downBtn:SetScript("OnClick", function()
                    -- Swap with next button
                    local temp = buttonOrder[capturedIndex]
                    buttonOrder[capturedIndex] = buttonOrder[capturedIndex + 1]
                    buttonOrder[capturedIndex + 1] = temp
                    SaveButtonOrderAndRefresh()
                    -- Refresh config menu to show new order
                    local MainMenu = DPSLight_MainMenu
                    if MainMenu and MainMenu.Show then
                        MainMenu:Show()
                    end
                end)
            end

            yOffset = yOffset - 25
        end
    end
    yOffset = yOffset - 15

    -- ========== SECTION: FOOTER INFORMATION ==========
    local footerSection = CreateSection(scrollChild, yOffset, "Footer Information", {r=0.3, g=0.5, b=0.3})
    table.insert(allSections, footerSection)
    yOffset = yOffset - 40

    -- Show Footer Master Toggle
    local footerCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    table.insert(footerSection.content, footerCheck)
    footerCheck:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    footerCheck:SetChecked(Database and Database:GetSetting("showFooter") ~= false)
    local footerText = footerCheck:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    footerText:SetPoint("LEFT", footerCheck, "RIGHT", 5, 0)
    footerText:SetText("Show Footer")
    footerText:SetTextColor(1, 0.8, 0)
    footerCheck:SetScript("OnClick", function()
        if Database then
            Database:SetSetting("showFooter", this:GetChecked())
            local MainFrame = DPSLight_MainFrame
            if MainFrame and MainFrame.GetFrame then
                local frame = MainFrame:GetFrame()
                if frame and frame.footer then
                    if this:GetChecked() then
                        frame.footer:Show()
                    else
                        frame.footer:Hide()
                    end
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Footer " .. (this:GetChecked() and "shown" or "hidden"), 1, 1, 0)
        end
    end)
    yOffset = yOffset - 30

    -- Individual footer info checkboxes
    local footerInfo = Database and Database:GetSetting("footerInfo") or {}
    local footerOptions = {
        {key = "combatTimer", label = "Combat Timer"},
        {key = "fps", label = "FPS"},
        {key = "latency", label = "Latency"},
        {key = "memory", label = "Memory"},
    }

    for _, opt in ipairs(footerOptions) do
        local check = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        table.insert(footerSection.content, check)
        check:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 50, yOffset)
        check:SetChecked(footerInfo[opt.key] ~= false)
        local checkText = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        checkText:SetPoint("LEFT", check, "RIGHT", 5, 0)
        checkText:SetText(opt.label)

        -- Store value in closure to avoid loop variable issues
        local optKey = opt.key

        check:SetScript("OnClick", function()
            if Database then
                local info = Database:GetSetting("footerInfo") or {}
                info[optKey] = this:GetChecked()
                Database:SetSetting("footerInfo", info)

                -- Reload settings and update display
                local MainFrame = DPSLight_MainFrame
                if MainFrame then
                    if MainFrame.ReloadSettings then
                        MainFrame:ReloadSettings()
                    end
                    if MainFrame.GetFrame then
                        local frame = MainFrame:GetFrame()
                        if frame and frame.UpdateFooter then
                            frame:UpdateFooter()
                        end
                    end
                end
            end
        end)
        yOffset = yOffset - 25
    end
    yOffset = yOffset - 15

    -- ========== SECTION: DATA FILTERS ==========
    local filtersSection = CreateSection(scrollChild, yOffset, "Data Filters", {r=0.4, g=0.3, b=0.5})
    table.insert(allSections, filtersSection)
    yOffset = yOffset - 40

    -- Filter Mode (cycling button)
    local filterText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    table.insert(filtersSection.content, filterText)
    filterText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    filterText:SetText("Filter Mode:")
    yOffset = yOffset - 25

    local filterBtn = CreateFrame("Button", nil, scrollChild)
    table.insert(filtersSection.content, filterBtn)
    filterBtn:SetWidth(220)
    filterBtn:SetHeight(28)
    filterBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    filterBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    filterBtn:SetBackdropColor(0.2, 0.3, 0.5, 1)
    filterBtn:SetBackdropBorderColor(0.6, 0.7, 0.9, 1)

    local filterBtnText = filterBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    filterBtnText:SetPoint("CENTER", filterBtn, "CENTER", 0, 0)
    filterBtnText:SetJustifyH("CENTER")
    filterBtnText:SetWidth(200)

    local filterModes = {"all", "group", "raid"}
    local filterLabels = {all = "Show All Players", group = "Group Only", raid = "Raid Only"}
    local currentFilterMode = Database and Database:GetSetting("filterMode") or "all"
    local filterIndex = 1
    for i, mode in ipairs(filterModes) do
        if mode == currentFilterMode then
            filterIndex = i
            break
        end
    end
    filterBtnText:SetText(filterLabels[currentFilterMode])

    -- Show Self Only checkbox
    local selfOnlyCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    table.insert(filtersSection.content, selfOnlyCheck)

    -- Hover effects for Filter Mode button
    filterBtn:SetScript("OnEnter", function()
        this:SetBackdropColor(0.3, 0.4, 0.6, 1)  -- Lighter on hover
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Filter Mode", 1, 1, 1)
        GameTooltip:AddLine("Click to cycle: All → Group → Raid", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    filterBtn:SetScript("OnLeave", function()
        this:SetBackdropColor(0.2, 0.3, 0.5, 1)  -- Back to normal
        GameTooltip:Hide()
    end)

    filterBtn:SetScript("OnClick", function()
        filterIndex = filterIndex + 1
        if filterIndex > 3 then filterIndex = 1 end
        local newMode = filterModes[filterIndex]
        filterBtnText:SetText(filterLabels[newMode])

        if Database then
            Database:SetSetting("filterMode", newMode)

            -- When switching away from "Show All", uncheck "Show Self Only"
            if newMode ~= "all" and selfOnlyCheck and selfOnlyCheck:GetChecked() then
                selfOnlyCheck:SetChecked(false)
                Database:SetSetting("showSelfOnly", false)
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Show self only disabled (incompatible with " .. filterLabels[newMode] .. ")", 1, 1, 0)
            end

            -- Reload settings in MainFrame
            local MainFrame = DPSLight_MainFrame
            if MainFrame then
                if MainFrame.ReloadSettings then
                    MainFrame:ReloadSettings()
                end
                if MainFrame.UpdateDisplay then
                    MainFrame:UpdateDisplay()
                end
            end

            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Filter mode set to " .. filterLabels[newMode], 1, 1, 0)
        end
    end)
    yOffset = yOffset - 30

    -- Show Only Self
    selfOnlyCheck = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    table.insert(filtersSection.content, selfOnlyCheck)
    selfOnlyCheck:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    selfOnlyCheck:SetChecked(Database and Database:GetSetting("showSelfOnly") or false)
    local selfOnlyText = selfOnlyCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selfOnlyText:SetPoint("LEFT", selfOnlyCheck, "RIGHT", 5, 0)
    selfOnlyText:SetText("Show Self Only")
    selfOnlyCheck:SetScript("OnClick", function()
        if Database then
            local checked = this:GetChecked()
            -- Explicitly save false when unchecked
            if checked then
                Database:SetSetting("showSelfOnly", true)
            else
                Database:SetSetting("showSelfOnly", false)
            end

            -- When enabling Show Self Only, switch to "Show All Players" mode
            if checked and filterIndex ~= 1 then
                filterIndex = 1
                filterBtnText:SetText(filterLabels["all"])
                Database:SetSetting("filterMode", "all")
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Filter mode changed to Show All Players", 1, 1, 0)
            end

            -- Reload settings in MainFrame
            local MainFrame = DPSLight_MainFrame
            if MainFrame then
                if MainFrame.ReloadSettings then
                    MainFrame:ReloadSettings()
                end
                if MainFrame.UpdateDisplay then
                    MainFrame:UpdateDisplay()
                end
            end

            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Show self only " .. (checked and "enabled" or "disabled") .. " (value saved: " .. tostring(Database:GetSetting("showSelfOnly")) .. ")", 1, 1, 0)
        end
    end)
    yOffset = yOffset - 40

    -- Max Players
    local maxText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    table.insert(filtersSection.content, maxText)
    maxText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    maxText:SetText("Max Players to Show:")
    yOffset = yOffset - 25

    local maxSlider = CreateFrame("Slider", "DPSLight_MaxPlayersSlider", scrollChild, "OptionsSliderTemplate")
    table.insert(filtersSection.content, maxSlider)
    maxSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    maxSlider:SetMinMaxValues(5, 40)
    maxSlider:SetValueStep(1)
    maxSlider:SetWidth(200)
    maxSlider:SetValue(Database and Database:GetSetting("maxPlayers") or 20)
    getglobal("DPSLight_MaxPlayersSliderLow"):SetText("5")
    getglobal("DPSLight_MaxPlayersSliderHigh"):SetText("40")
    getglobal("DPSLight_MaxPlayersSliderText"):SetText("Max Players: " .. (Database and Database:GetSetting("maxPlayers") or 20))
    maxSlider:SetScript("OnValueChanged", function()
        if Database then
            local value = math.floor(this:GetValue())
            Database:SetSetting("maxPlayers", value)
            getglobal("DPSLight_MaxPlayersSliderText"):SetText("Max Players: " .. value)

            -- Reload settings in MainFrame
            local MainFrame = DPSLight_MainFrame
            if MainFrame then
                if MainFrame.ReloadSettings then
                    MainFrame:ReloadSettings()
                end
                if MainFrame.UpdateDisplay then
                    MainFrame:UpdateDisplay()
                end
            end
        end
    end)
    yOffset = yOffset - 50

    -- ========== SECTION: APPEARANCE ==========
    local appearanceSection = CreateSection(scrollChild, yOffset, "Appearance", {r=0.5, g=0.4, b=0.2})
    table.insert(allSections, appearanceSection)
    yOffset = yOffset - 40

    -- Border Style
    local borderText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    table.insert(appearanceSection.content, borderText)
    borderText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    borderText:SetText("Border Style:")
    yOffset = yOffset - 25

    local borderSlider = CreateFrame("Slider", "DPSLight_BorderStyleSlider", scrollChild, "OptionsSliderTemplate")
    table.insert(appearanceSection.content, borderSlider)
    borderSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    borderSlider:SetMinMaxValues(1, 6)
    borderSlider:SetValueStep(1)
    borderSlider:SetWidth(200)
    borderSlider:SetValue(Database and Database:GetSetting("borderStyle") or 1)
    getglobal("DPSLight_BorderStyleSliderLow"):SetText("1")
    getglobal("DPSLight_BorderStyleSliderHigh"):SetText("6")
    getglobal("DPSLight_BorderStyleSliderText"):SetText("Border Style: " .. (Database and Database:GetSetting("borderStyle") or 1))
    borderSlider:SetScript("OnValueChanged", function()
        if Database then
            local value = math.floor(this:GetValue())
            Database:SetSetting("borderStyle", value)
            getglobal("DPSLight_BorderStyleSliderText"):SetText("Border Style: " .. value)

            -- Apply border style immediately
            local MainFrame = DPSLight_MainFrame
            if MainFrame and MainFrame.GetFrame then
                local frame = MainFrame:GetFrame()
                if frame then
                    local borders = {
                        {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16},
                        {edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32},
                        {edgeFile = "Interface\\GLUES\\COMMON\\TextPanel-Border", edgeSize = 16},
                        {edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border", edgeSize = 12},
                        {edgeFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-WoodBorder", edgeSize = 32},
                        {edgeFile = "Interface\\COMMON\\Indicator-Gray", edgeSize = 8},
                    }
                    if borders[value] then
                        frame:SetBackdrop({
                            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                            edgeFile = borders[value].edgeFile,
                            tile = true,
                            tileSize = 16,
                            edgeSize = borders[value].edgeSize,
                            insets = {left = 4, right = 4, top = 4, bottom = 4}
                        })
                        -- Restore background color
                        local bgColor = Database:GetSetting("bgColor") or {r=0, g=0, b=0, a=0.8}
                        local opacity = Database:GetSetting("opacity") or 0.9
                        frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, opacity)
                        frame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
                    end
                end
            end
            -- Update secondary windows
            if MainFrame and MainFrame.UpdateSecondaryWindowsStyle then
                MainFrame:UpdateSecondaryWindowsStyle()
            end
        end
    end)
    yOffset = yOffset - 40

    -- Opacity Slider
    local opacityText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    table.insert(appearanceSection.content, opacityText)
    opacityText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    opacityText:SetText("Window Opacity:")
    yOffset = yOffset - 25

    local opacitySlider = CreateFrame("Slider", "DPSLight_OpacitySlider", scrollChild, "OptionsSliderTemplate")
    table.insert(appearanceSection.content, opacitySlider)
    opacitySlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 40, yOffset)
    opacitySlider:SetMinMaxValues(0.0, 1.0)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetWidth(200)
    opacitySlider:SetValue(Database and Database:GetSetting("opacity") or 0.9)
    getglobal("DPSLight_OpacitySliderLow"):SetText("0%")
    getglobal("DPSLight_OpacitySliderHigh"):SetText("100%")
    getglobal("DPSLight_OpacitySliderText"):SetText(string.format("Opacity: %.0f%%", (Database and Database:GetSetting("opacity") or 0.9) * 100))
    opacitySlider:SetScript("OnValueChanged", function()
        if Database then
            local value = this:GetValue()
            Database:SetSetting("opacity", value)
            getglobal("DPSLight_OpacitySliderText"):SetText(string.format("Opacity: %.0f%%", value * 100))
            local MainFrame = DPSLight_MainFrame
            if MainFrame and MainFrame.GetFrame then
                local frame = MainFrame:GetFrame()
                if frame then
                    local bgColor = Database:GetSetting("bgColor") or {r=0, g=0, b=0}
                    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, value)
                end
            end
            -- Update secondary windows
            if MainFrame and MainFrame.UpdateSecondaryWindowsStyle then
                MainFrame:UpdateSecondaryWindowsStyle()
            end
        end
    end)
    yOffset = yOffset - 45

    -- Scale Slider
    local scaleText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    table.insert(appearanceSection.content, scaleText)
    scaleText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    scaleText:SetText("Window Scale:")
    yOffset = yOffset - 25

    local scaleSlider = CreateFrame("Slider", "DPSLight_ScaleSlider", scrollChild, "OptionsSliderTemplate")
    table.insert(appearanceSection.content, scaleSlider)
    scaleSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 40, yOffset)
    scaleSlider:SetMinMaxValues(0.7, 1.3)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetWidth(200)
    scaleSlider:SetValue(Database and Database:GetSetting("scale") or 1.0)
    getglobal("DPSLight_ScaleSliderLow"):SetText("70%")
    getglobal("DPSLight_ScaleSliderHigh"):SetText("130%")
    getglobal("DPSLight_ScaleSliderText"):SetText(string.format("Scale: %.0f%%", (Database and Database:GetSetting("scale") or 1.0) * 100))
    scaleSlider:SetScript("OnValueChanged", function()
        if Database then
            local value = this:GetValue()
            Database:SetSetting("scale", value)
            getglobal("DPSLight_ScaleSliderText"):SetText(string.format("Scale: %.0f%%", value * 100))
            local MainFrame = DPSLight_MainFrame
            if MainFrame and MainFrame.GetFrame then
                local frame = MainFrame:GetFrame()
                if frame then
                    frame:SetScale(value)
                end
            end
        end
    end)
    yOffset = yOffset - 50

    -- ========== SECTION: ACTIONS ==========
    local actionsSection = CreateSection(scrollChild, yOffset, "Actions", {r=0.5, g=0.2, b=0.2})
    table.insert(allSections, actionsSection)
    yOffset = yOffset - 40

    -- Reset Position Button
    local resetPosBtn = CreateFrame("Button", nil, scrollChild)
    table.insert(actionsSection.content, resetPosBtn)
    resetPosBtn:SetWidth(180)
    resetPosBtn:SetHeight(28)
    resetPosBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    resetPosBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    resetPosBtn:SetBackdropColor(0.3, 0.4, 0.5, 1)
    local resetPosText = resetPosBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetPosText:SetPoint("CENTER", resetPosBtn, "CENTER", 0, 0)
    resetPosText:SetText("Reset Position")
    resetPosBtn:SetScript("OnClick", function()
        local MainFrame = DPSLight_MainFrame
        if MainFrame and MainFrame.GetFrame then
            local frame = MainFrame:GetFrame()
            if frame then
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                if Database then
                    Database:SetSetting("windowPos", {x = 0, y = 0})
                end
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Window position reset", 0, 1, 0)
            end
        end
    end)
    yOffset = yOffset - 38

    -- Assign reposition function to all sections
    for _, section in ipairs(allSections) do
        section.repositionFunc = RepositionSections
    end

    -- Reset All Settings Button
    local resetAllBtn = CreateFrame("Button", nil, scrollChild)
    table.insert(actionsSection.content, resetAllBtn)
    resetAllBtn:SetWidth(180)
    resetAllBtn:SetHeight(28)
    resetAllBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    resetAllBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    resetAllBtn:SetBackdropColor(0.6, 0.2, 0.2, 1)
    local resetAllText = resetAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetAllText:SetPoint("CENTER", resetAllBtn, "CENTER", 0, 0)
    resetAllText:SetText("Reset All Settings")
    resetAllBtn:SetScript("OnClick", function()
        if Database then
            Database:ResetAllSettings()
            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: All settings reset to defaults. /reload to apply.", 1, 1, 0)
        end
    end)
    yOffset = yOffset - 38

    -- Save Settings Button
    local saveBtn = CreateFrame("Button", nil, scrollChild)
    saveBtn:SetWidth(180)
    saveBtn:SetHeight(28)
    saveBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    saveBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
        edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    saveBtn:SetBackdropColor(0.2, 0.6, 0.2, 1)
    local saveText = saveBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    saveText:SetPoint("CENTER", saveBtn, "CENTER", 0, 0)
    saveText:SetText("Save Settings")
    saveBtn:SetScript("OnClick", function()
        if Database and Database.SaveToDisk then
            Database:SaveToDisk()
            DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Settings saved successfully!", 0, 1, 0)
        end
    end)

    menuFrame.configContent = content
end

-- Create Skins tab content
function MainMenu:CreateSkinsTab()
    -- Create ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, menuFrame.contentFrame)
    scrollFrame:SetPoint("TOPLEFT", menuFrame.contentFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", menuFrame.contentFrame, "BOTTOMRIGHT", -20, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(660)
    content:SetHeight(800)
    scrollFrame:SetScrollChild(content)

    -- Scrollbar
    local scrollBar = CreateFrame("Slider", nil, scrollFrame)
    scrollBar:SetPoint("TOPRIGHT", menuFrame.contentFrame, "TOPRIGHT", -5, -10)
    scrollBar:SetPoint("BOTTOMRIGHT", menuFrame.contentFrame, "BOTTOMRIGHT", -5, 10)
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
    thumb:SetWidth(14)
    thumb:SetHeight(25)
    thumb:SetVertexColor(0.6, 0.6, 0.6, 0.9)
    scrollBar:SetThumbTexture(thumb)

    scrollBar:SetScript("OnValueChanged", function()
        local maxScroll = content:GetHeight() - scrollFrame:GetHeight()
        if maxScroll > 0 then
            scrollFrame:SetVerticalScroll(arg1 * maxScroll)
        end
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollBar:GetValue()
        local maxScroll = content:GetHeight() - scrollFrame:GetHeight()
        if maxScroll > 0 then
            local step = (arg1 > 0) and -0.05 or 0.05
            local newValue = math.max(0, math.min(1, current + step))
            scrollBar:SetValue(newValue)
        end
    end)

    -- Title
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", content, "TOP", 0, -20)
    title:SetText("Themes & Skins")
    title:SetTextColor(1, 0.85, 0)

    -- Description
    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Choose a color theme for DPSLight windows")
    desc:SetTextColor(0.8, 0.8, 0.8)

    -- Predefined themes
    local themes = {
        {name = "Default Dark", bg = {0, 0, 0, 0.9}, border = {0.3, 0.3, 0.3}},
        {name = "Warrior Red", bg = {0.2, 0, 0, 0.85}, border = {0.8, 0.2, 0.2}},
        {name = "Mage Blue", bg = {0, 0.1, 0.3, 0.85}, border = {0.2, 0.5, 0.9}},
        {name = "Priest Holy", bg = {0.3, 0.3, 0.3, 0.85}, border = {0.9, 0.9, 0.9}},
        {name = "Rogue Black", bg = {0.1, 0.1, 0.05, 0.9}, border = {0.7, 0.7, 0.2}},
        {name = "Druid Nature", bg = {0.1, 0.2, 0, 0.85}, border = {0.5, 0.8, 0.3}},
        {name = "Hunter Green", bg = {0.05, 0.15, 0.05, 0.85}, border = {0.3, 0.7, 0.3}},
        {name = "Warlock Shadow", bg = {0.15, 0, 0.2, 0.85}, border = {0.6, 0.2, 0.8}},
        {name = "Paladin Gold", bg = {0.3, 0.2, 0.1, 0.85}, border = {0.9, 0.7, 0.3}},
        {name = "Shaman Elements", bg = {0.05, 0.1, 0.2, 0.85}, border = {0.3, 0.6, 0.9}},
    }

    local yOffset = -60
    local xOffset = 30
    local btnWidth = 200
    local btnHeight = 35
    local btnPerRow = 3
    local btnSpacing = 10

    local Database = DPSLight_Database

    for i, theme in ipairs(themes) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetWidth(btnWidth)
        btn:SetHeight(btnHeight)

        -- Calculate position (3 per row)
        local row = math.floor((i - 1) / btnPerRow)
        local col = (i - 1) - (row * btnPerRow)

        btn:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + (col * (btnWidth + btnSpacing)), yOffset - (row * (btnHeight + btnSpacing)))

        -- Background matching theme colors
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        btn:SetBackdropColor(theme.bg[1], theme.bg[2], theme.bg[3], theme.bg[4])
        btn:SetBackdropBorderColor(theme.border[1], theme.border[2], theme.border[3], 1)

        -- Theme name
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(theme.name)

        -- Store theme data
        btn.themeData = theme

        -- Apply theme on click
        btn:SetScript("OnClick", function()
            if Database then
                Database:SetSetting("bgColor", {r = theme.bg[1], g = theme.bg[2], b = theme.bg[3], a = theme.bg[4]})
                local MainFrame = DPSLight_MainFrame
                if MainFrame and MainFrame.GetFrame then
                    local frame = MainFrame:GetFrame()
                    if frame then
                        frame:SetBackdropColor(theme.bg[1], theme.bg[2], theme.bg[3], theme.bg[4])
                    end
                end
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Theme '" .. theme.name .. "' applied", 0, 1, 0)
            end
        end)

        -- Highlight on hover
        btn:SetScript("OnEnter", function()
            local b = this or btn
            b:SetBackdropBorderColor(1, 1, 0, 1)
        end)
        btn:SetScript("OnLeave", function()
            local b = this or btn
            local t = b.themeData
            if t then
                b:SetBackdropBorderColor(t.border[1], t.border[2], t.border[3], 1)
            end
        end)
    end

    menuFrame.skinsContent = content
end

-- Create Secondary Windows tab content
function MainMenu:CreateWindowsTab()
    local content = CreateFrame("Frame", nil, menuFrame.contentFrame)
    content:SetAllPoints(menuFrame.contentFrame)

    -- Title
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", content, "TOP", 0, -15)
    title:SetText("Secondary Windows")
    title:SetTextColor(1, 0.85, 0)

    -- Description
    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -8)
    desc:SetText("Create additional windows to display multiple stats simultaneously")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Window type buttons
    local windowTypes = {
        {mode = "damage", label = "Damage", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", color = {r=0.8, g=0.2, b=0.2}},
        {mode = "healing", label = "Healing", icon = "Interface\\Icons\\Spell_Holy_FlashHeal", color = {r=0.2, g=0.8, b=0.2}},
        {mode = "dispels", label = "Dispels", icon = "Interface\\Icons\\Spell_Holy_DispelMagic", color = {r=0.5, g=0.5, b=1}},
        {mode = "decurse", label = "Decurse", icon = "Interface\\Icons\\Spell_Nature_RemoveCurse", color = {r=0.5, g=1, b=0.5}},
        {mode = "deaths", label = "Deaths", icon = "Interface\\Icons\\Ability_Rogue_FeignDeath", color = {r=0.7, g=0.7, b=0.7}}
    }

    local yOffset = -70
    local xOffset = 50
    local btnWidth = 180
    local btnHeight = 50
    local btnSpacing = 15

    for i, winType in ipairs(windowTypes) do
        local btn = CreateFrame("Button", nil, content)
        btn:SetWidth(btnWidth)
        btn:SetHeight(btnHeight)

        local row = math.floor((i-1) / 3)
        local col = (i-1) - (row * 3)
        btn:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + col * (btnWidth + btnSpacing), yOffset - row * (btnHeight + btnSpacing))

        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = {left = 3, right = 3, top = 3, bottom = 3}
        })
        btn:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
        btn:SetBackdropBorderColor(winType.color.r, winType.color.g, winType.color.b, 0.6)

        -- Icon
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(32)
        icon:SetHeight(32)
        icon:SetPoint("LEFT", btn, "LEFT", 10, 0)
        icon:SetTexture(winType.icon)

        -- Label
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("LEFT", icon, "RIGHT", 10, 0)
        label:SetText("Create " .. winType.label)
        label:SetTextColor(winType.color.r, winType.color.g, winType.color.b)

        btn.mode = winType.mode
        btn.color = winType.color
        btn.winType = winType

        btn:SetScript("OnClick", function()
            local MainFrame = DPSLight_MainFrame
            if MainFrame and MainFrame.CreateSecondaryWindow then
                MainFrame:CreateSecondaryWindow(this.mode)
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Created " .. this.winType.label .. " window", this.color.r, this.color.g, this.color.b)
            end
        end)

        btn:SetScript("OnEnter", function()
            this:SetBackdropBorderColor(this.winType.color.r, this.winType.color.g, this.winType.color.b, 1)
            this:SetBackdropColor(0.15, 0.15, 0.2, 0.95)
        end)

        btn:SetScript("OnLeave", function()
            this:SetBackdropBorderColor(this.winType.color.r, this.winType.color.g, this.winType.color.b, 0.6)
            this:SetBackdropColor(0.1, 0.1, 0.15, 0.9)
        end)
    end

    content:Hide()
    menuFrame.windowsContent = content
end

-- Show menu
function MainMenu:Show(tab)
    if not menuFrame then
        self:Create()
    end

    if tab then
        self:SwitchTab(tab)
    end

    menuFrame:Show()
end

-- Hide menu
function MainMenu:Hide()
    if menuFrame then
        menuFrame:Hide()
    end
end

-- Toggle menu
function MainMenu:Toggle(tab)
    if not menuFrame then
        self:Show(tab)
        return
    end

    if menuFrame:IsVisible() then
        self:Hide()
    else
        self:Show(tab)
    end
end

-- Get frame reference
function MainMenu:GetFrame()
    return menuFrame
end

return MainMenu
