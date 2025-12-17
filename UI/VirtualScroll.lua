-- VirtualScroll.lua - Efficient scrolling list with only visible rows rendered
-- Only creates/updates frames for visible items, not entire list

local VirtualScroll = {}
DPSLight_VirtualScroll = VirtualScroll

local FramePool = DPSLight_FramePool
local Utils = DPSLight_Utils

-- Row height constant
local ROW_HEIGHT = 18
local ROW_SPACING = 2

-- Create new virtual scroll list
function VirtualScroll:New(parent, width, height, maxVisibleRows)
    local list = {
        parent = parent,
        width = width,
        height = height,
        maxVisibleRows = maxVisibleRows or 15,
        scrollOffset = 0,
        data = {},
        rows = {},
        totalRows = 0,
        showIcons = true,  -- Show icons by default
    }
    
    setmetatable(list, {__index = self})
    list:Initialize()
    
    return list
end

-- Initialize scroll list
function VirtualScroll:Initialize()
    -- Create container frame
    self.frame = CreateFrame("Frame", nil, self.parent)
    self.frame:SetWidth(self.width)
    self.frame:SetHeight(self.height)
    
    -- Create scrollbar
    self.scrollBar = CreateFrame("Slider", nil, self.frame)
    self.scrollBar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -16)
    self.scrollBar:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 16)
    self.scrollBar:SetWidth(16)
    self.scrollBar:SetOrientation("VERTICAL")
    self.scrollBar:SetMinMaxValues(0, 1)
    self.scrollBar:SetValue(0)
    self.scrollBar:SetValueStep(1)
    
    -- Scrollbar backdrop (invisible/discret)
    self.scrollBar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = false,
        tileSize = 16,
        edgeSize = 0,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    self.scrollBar:SetBackdropColor(0, 0, 0, 0.3)  -- Très transparent
    
    -- Scrollbar thumb (discret et petit)
    local thumb = self.scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    thumb:SetWidth(12)
    thumb:SetHeight(20)
    thumb:SetVertexColor(0.5, 0.5, 0.5, 0.8)
    self.scrollBar:SetThumbTexture(thumb)
    
    -- Scrollbar handlers
    local this = self
    self.scrollBar:SetScript("OnValueChanged", function()
        this:OnScroll(arg1)
    end)
    
    -- Mouse wheel
    self.frame:EnableMouseWheel(true)
    self.frame:SetScript("OnMouseWheel", function()
        local current = this.scrollBar:GetValue()
        local step = arg1 > 0 and -1 or 1
        this.scrollBar:SetValue(current + step)
    end)
    
    -- Create initial visible rows
    for i = 1, self.maxVisibleRows do
        local row = self:CreateRow(i)
        table.insert(self.rows, row)
    end
end

-- Create a row frame
function VirtualScroll:CreateRow(index)
    local row = CreateFrame("Button", nil, self.frame)
    local currentWidth = self.frame:GetWidth() or self.width
    row:SetWidth(currentWidth - 20)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -(index - 1) * (ROW_HEIGHT + ROW_SPACING))
    
    -- Background
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(0, 0, 0, 0.5)
    
    -- Highlight
    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(1, 1, 1, 0.2)
    
    -- Class icon
    row.classIcon = row:CreateTexture(nil, "ARTWORK")
    row.classIcon:SetWidth(16)
    row.classIcon:SetHeight(16)
    row.classIcon:SetPoint("LEFT", row, "LEFT", 4, 0)
    
    -- Rank text
    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rank:SetPoint("LEFT", row.classIcon, "RIGHT", 2, 0)
    row.rank:SetWidth(16)
    row.rank:SetJustifyH("LEFT")
    
    -- Name text
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.name:SetPoint("LEFT", row.rank, "RIGHT", 2, 0)
    row.name:SetWidth(90)
    row.name:SetJustifyH("LEFT")
    row.name:SetTextColor(1, 1, 1)
    
    -- Value text
    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.value:SetPoint("LEFT", row.name, "RIGHT", 2, 0)
    row.value:SetWidth(40)
    row.value:SetJustifyH("RIGHT")
    row.value:SetTextColor(1, 1, 1)
    
    -- Percent bar
    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetPoint("LEFT", row.value, "RIGHT", 2, 0)
    local currentWidth = self.frame:GetWidth() or self.width
    -- LEFT(4) + Icon(16+2) + Rank(16+2) + Name(90+2) + Value(40+2) + Margins = 174px
    local barWidth = math.max(30, currentWidth - 174 - 10)  -- -10 for right margin
    row.bar:SetWidth(barWidth)
    row.bar:SetHeight(12)
    row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.bar:SetMinMaxValues(0, 100)
    row.bar:SetValue(0)
    
    -- Tooltip
    row:EnableMouse(true)
    row:SetScript("OnEnter", function()
        if this.tooltipData then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(this.tooltipData.name, 1, 1, 1)
            
            if this.tooltipData.details then
                for _, line in ipairs(this.tooltipData.details) do
                    GameTooltip:AddLine(line, 0.8, 0.8, 0.8)
                end
            end
            
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Click to see ability details", 0.5, 1, 0.5)
            
            GameTooltip:Show()
        end
    end)
    
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Click to show details
    row:SetScript("OnMouseDown", function()
        if this.rowData and this.rowData.userID then
            local DetailFrame = DPSLight_DetailFrame
            if DetailFrame then
                DetailFrame:Show(this.rowData.userID, this.rowData.module)
            end
        end
    end)
    
    row:Hide()
    return row
end

-- Update visible rows
function VirtualScroll:Update()
    if not self.rows or not self.data then return end
    
    local firstVisible = math.floor(self.scrollOffset)
    local ClassIcons = DPSLight_ClassIcons
    local showIcons = self.showIcons
    local totalRows = self.totalRows
    
    for i = 1, self.maxVisibleRows do
        local dataIndex = firstVisible + i
        local row = self.rows[i]
        
        if dataIndex <= self.totalRows and self.data[dataIndex] then
            local entry = self.data[dataIndex]
            
            -- Update class icon
            if self.showIcons and ClassIcons and entry.class and row.classIcon then
                ClassIcons:SetIcon(row.classIcon, entry.class)
                row.classIcon:Show()
            else
                if row.classIcon then
                    row.classIcon:Hide()
                end
            end
            
            -- Update row content
            row.rank:SetText(dataIndex)
            
            -- Truncate name if too long
            local displayName = entry.name or "Unknown"
            local nameWidth = row.name:GetWidth() or 90
            local maxChars = math.floor(nameWidth / 6.5)  -- Approximate chars that fit
            if string.len(displayName) > maxChars then
                displayName = string.sub(displayName, 1, maxChars - 3) .. "..."
            end
            row.name:SetText(displayName)
            
            row.value:SetText(Utils:FormatNumber(entry.value or 0))
            
            local percent = entry.percent or 0
            row.bar:SetValue(percent)
            
            -- Set bar color
            local color = entry.color or {r = 0.2, g = 0.8, b = 0.2}
            row.bar:SetStatusBarColor(color.r, color.g, color.b)
            
            -- Set name color (class color)
            if entry.classColor then
                row.name:SetTextColor(entry.classColor.r, entry.classColor.g, entry.classColor.b)
            else
                row.name:SetTextColor(1, 1, 1)
            end
            
            -- Store tooltip data and row data for click
            row.tooltipData = entry.tooltip
            row.rowData = {
                userID = entry.userID,
                module = entry.module
            }
            
            row:Show()
        else
            if row then
                row:Hide()
            end
        end
    end
end

-- Set data for the list
function VirtualScroll:SetData(data)
    self.data = data
    self.totalRows = table.getn(data)
    
    -- Update scrollbar range
    local maxScroll = math.max(0, self.totalRows - self.maxVisibleRows)
    self.scrollBar:SetMinMaxValues(0, maxScroll)
    
    -- Show/hide scrollbar
    if maxScroll > 0 then
        self.scrollBar:Show()
    else
        self.scrollBar:Hide()
    end
    
    self:Update()
end

-- Scroll handler
function VirtualScroll:OnScroll(value)
    self.scrollOffset = value
    self:Update()
end

-- Get list frame
function VirtualScroll:GetFrame()
    return self.frame
end

-- Update all row sizes (for resize)
function VirtualScroll:UpdateAll()
    if not self.frame or not self.rows then return end
    
    local newWidth = self.frame:GetWidth()
    if not newWidth or newWidth < 100 then return end
    
    for i = 1, table.getn(self.rows) do
        local row = self.rows[i]
        if row then
            row:SetWidth(newWidth - 20)
            
            -- Adapt text sizes for small windows
            if newWidth < 250 then
                -- Very small - use tiny font and reduce widths
                if row.name then 
                    row.name:SetFont("Fonts\\FRIZQT__.TTF", 9)
                    row.name:SetWidth(60)
                end
                if row.value then 
                    row.value:SetFont("Fonts\\FRIZQT__.TTF", 9)
                    row.value:SetWidth(40)
                end
                if row.rank then row.rank:SetFont("Fonts\\FRIZQT__.TTF", 9) end
            elseif newWidth < 300 then
                -- Small - use small font
                if row.name then 
                    row.name:SetFont("Fonts\\FRIZQT__.TTF", 10)
                    row.name:SetWidth(70)
                end
                if row.value then 
                    row.value:SetFont("Fonts\\FRIZQT__.TTF", 10)
                    row.value:SetWidth(45)
                end
                if row.rank then row.rank:SetFont("Fonts\\FRIZQT__.TTF", 10) end
            else
                -- Normal size
                if row.name then 
                    row.name:SetFont("Fonts\\FRIZQT__.TTF", 11)
                    row.name:SetWidth(80)
                end
                if row.value then 
                    row.value:SetFont("Fonts\\FRIZQT__.TTF", 11)
                    row.value:SetWidth(50)
                end
                if row.rank then row.rank:SetFont("Fonts\\FRIZQT__.TTF", 11) end
            end
            
            -- Update bar width (recalculate based on actual widths)
            if row.bar then
                local nameWidth = row.name and row.name:GetWidth() or 80
                local valueWidth = row.value and row.value:GetWidth() or 50
                local usedWidth = 4 + 18 + 18 + nameWidth + valueWidth + 10
                local barWidth = math.max(20, newWidth - usedWidth - 20)
                row.bar:SetWidth(barWidth)
            end
        end
    end
    
    self:Update()
end

-- Clear list
function VirtualScroll:Clear()
    self:SetData({})
end

-- Set show icons
function VirtualScroll:SetShowIcons(show)
    self.showIcons = show
    for i = 1, table.getn(self.rows) do
        local row = self.rows[i]
        if row and row.classIcon then
            if show then
                row.classIcon:Show()
            else
                row.classIcon:Hide()
            end
        end
    end
end

return VirtualScroll
