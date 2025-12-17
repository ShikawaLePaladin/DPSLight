-- MinimapButton.lua - Minimap button for quick access
local MinimapButton = {}
DPSLight_MinimapButton = MinimapButton

local button = nil

-- Lazy load
local function GetDatabase() return DPSLight_Database end
local function GetMainFrame() return DPSLight_MainFrame end

-- Create minimap button
function MinimapButton:Create()
    if button then return button end

    button = CreateFrame("Button", "DPSLightMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)

    -- Icon
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_02")
    button.icon = icon

    -- Border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", 0, 0)

    -- Tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("DPSLight", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Main Menu", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: Toggle all windows", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift-click: Reset data", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click handlers
    button:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            -- Reset data
            local DataStore = DPSLight_GetCore():GetDataStore()
            if DataStore then
                DataStore:NewSegment()
                DEFAULT_CHAT_FRAME:AddMessage("DPSLight: Data reset", 0, 1, 0)
            end
        elseif arg1 == "RightButton" then
            -- Toggle main stats window AND all secondary windows
            local MainFrame = GetMainFrame()
            if MainFrame then
                -- Check if main frame is currently visible
                local mainFrame = getglobal("DPSLight_MainWindow")
                local mainVisible = mainFrame and mainFrame:IsVisible()

                -- Toggle main window
                MainFrame:Toggle()

                -- Toggle all secondary windows to match main window state
                if DPSLight_AllWindows then
                    for _, secFrame in ipairs(DPSLight_AllWindows) do
                        -- Skip the main frame itself
                        if secFrame and secFrame ~= mainFrame then
                            if mainVisible then
                                secFrame:Hide()
                            else
                                secFrame:Show()
                            end
                        end
                    end
                end
            end
        else
            -- Open main menu (Left click)
            local MainMenu = DPSLight_MainMenu
            if MainMenu then
                MainMenu:Toggle()
            end
        end
    end)

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Dragging
    button:SetScript("OnDragStart", function()
        this:LockHighlight()
        this.isDragging = true
    end)

    button:SetScript("OnDragStop", function()
        this:UnlockHighlight()
        this.isDragging = false

        local Database = GetDatabase()
        if Database then
            local angle = MinimapButton:GetAngle()
            Database:SetSetting("minimap.angle", angle)
        end
    end)

    button:SetScript("OnUpdate", function()
        if this.isDragging then
            MinimapButton:UpdatePosition()
        end
    end)

    -- Initial position
    self:UpdatePosition()

    return button
end

-- Update position
function MinimapButton:UpdatePosition()
    if not button then return end

    local Database = GetDatabase()
    local angle = Database and Database:GetSetting("minimap.angle") or 180

    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Get current angle
function MinimapButton:GetAngle()
    if not button then return 180 end

    local centerX, centerY = Minimap:GetCenter()
    local buttonX, buttonY = button:GetCenter()

    if not centerX or not buttonX then return 180 end

    local dx = buttonX - centerX
    local dy = buttonY - centerY

    return math.atan2(dy, dx)
end

-- Show button
function MinimapButton:Show()
    if not button then
        self:Create()
    end
    button:Show()
end

-- Hide button
function MinimapButton:Hide()
    if button then
        button:Hide()
    end
end

-- Show context menu
function MinimapButton:ShowContextMenu()
    if not button then return end

    local MainFrame = GetMainFrame()
    if not MainFrame then return end

    -- Create menu if doesn't exist
    if not button.contextMenu then
        local menu = CreateFrame("Frame", "DPSLight_MinimapMenu", UIParent)
        menu:SetWidth(200)
        menu:SetHeight(75)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        menu:SetBackdropColor(0, 0, 0, 0.95)
        menu:SetBackdropBorderColor(1, 0.82, 0, 1)  -- Bordure dorée
        menu:Hide()

        local yOffset = -8

        -- Configuration button
        local configBtn = CreateFrame("Button", nil, menu)
        configBtn:SetWidth(190)
        configBtn:SetHeight(30)
        configBtn:SetPoint("TOP", menu, "TOP", 0, yOffset - 2)
        configBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        configBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        configBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
            tile = false
        })

        local configText = configBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        configText:SetPoint("CENTER", configBtn, "CENTER", 0, 0)
        configText:SetText("Configuration")
        configText:SetTextColor(1, 0.82, 0)
        configText:SetJustifyH("CENTER")

        configBtn:SetScript("OnClick", function()
            MainFrame:ShowConfigMenu()
            menu:Hide()
        end)

        yOffset = yOffset - 30

        -- Add Secondary Window button
        local addBtn = CreateFrame("Button", nil, menu)
        addBtn:SetWidth(190)
        addBtn:SetHeight(30)
        addBtn:SetPoint("TOP", menu, "TOP", 0, yOffset - 2)
        addBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        addBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        addBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\UI-Panel-Button-Up",
            tile = false
        })

        local addText = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        addText:SetPoint("CENTER", addBtn, "CENTER", 0, 0)
        addText:SetText("Add Secondary Window")
        addText:SetTextColor(0.5, 1, 0.5)
        addText:SetJustifyH("CENTER")

        addBtn:SetScript("OnClick", function()
            MainFrame:ShowWindowSelector()
            menu:Hide()
        end)

        -- Auto-hide timer
        menu.hideTimer = 0
        menu:SetScript("OnUpdate", function()
            this.hideTimer = this.hideTimer + arg1
            if this.hideTimer >= 4 then
                this:Hide()
                this.hideTimer = 0
            end
        end)

        -- Hide on outside click
        menu:SetScript("OnShow", function()
            this.hideTimer = 0
        end)

        menu:EnableMouse(true)
        menu:SetScript("OnMouseDown", function()
            -- Click inside menu resets timer
            this.hideTimer = 0
        end)

        button.contextMenu = menu
    end

    -- Position menu to the LEFT of minimap button for better visibility
    local buttonX, buttonY = button:GetCenter()
    if buttonX and buttonY then
        button.contextMenu:ClearAllPoints()
        button.contextMenu:SetPoint("TOPRIGHT", button, "BOTTOMLEFT", -5, 0)
    else
        -- Fallback to cursor position (left side)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        button.contextMenu:ClearAllPoints()
        button.contextMenu:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end

    button.contextMenu:Show()
end

-- Toggle button
function MinimapButton:Toggle()
    local Database = GetDatabase()
    if not Database then return end

    local hide = Database:GetSetting("minimap.hide")
    Database:SetSetting("minimap.hide", not hide)

    if hide then
        self:Show()
    else
        self:Hide()
    end
end

return MinimapButton
