-- FramePool.lua - Recycle UI frames to reduce memory allocation

local FramePool = {}
DPSLight_FramePool = FramePool

-- Frame pools by type
local pools = {
    Button = {},
    Frame = {},
    FontString = {},
    Texture = {},
    StatusBar = {},
}

local poolSizes = {
    Button = 0,
    Frame = 0,
    FontString = 0,
    Texture = 0,
    StatusBar = 0,
}

local MAX_POOL_SIZE = 100

-- Get a frame from pool or create new
function FramePool:Acquire(frameType, parent, template)
    frameType = frameType or "Frame"
    
    local pool = pools[frameType]
    if not pool then
        pool = {}
        pools[frameType] = pool
        poolSizes[frameType] = 0
    end
    
    local frame
    if poolSizes[frameType] > 0 then
        frame = pool[poolSizes[frameType]]
        pool[poolSizes[frameType]] = nil
        poolSizes[frameType] = poolSizes[frameType] - 1
        
        -- Reset frame
        frame:SetParent(parent or UIParent)
        frame:ClearAllPoints()
        frame:Show()
    else
        -- Create new frame
        frame = CreateFrame(frameType, nil, parent or UIParent, template)
    end
    
    return frame
end

-- Return frame to pool
function FramePool:Release(frame, frameType)
    if not frame then return end
    
    frameType = frameType or frame:GetObjectType()
    
    local pool = pools[frameType]
    if not pool or poolSizes[frameType] >= MAX_POOL_SIZE then
        -- Pool full or doesn't exist, let frame be garbage collected
        frame:Hide()
        frame:SetParent(nil)
        return
    end
    
    -- Reset frame state
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(UIParent)
    
    -- Clear scripts
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)
    frame:SetScript("OnClick", nil)
    frame:SetScript("OnMouseDown", nil)
    frame:SetScript("OnMouseUp", nil)
    
    -- Add to pool
    poolSizes[frameType] = poolSizes[frameType] + 1
    pool[poolSizes[frameType]] = frame
end

-- Release multiple frames
function FramePool:ReleaseMultiple(frames, frameType)
    for _, frame in ipairs(frames) do
        self:Release(frame, frameType)
    end
end

-- Clear all pools
function FramePool:Clear()
    for frameType, pool in pairs(pools) do
        for i = 1, poolSizes[frameType] do
            pool[i]:Hide()
            pool[i]:SetParent(nil)
            pool[i] = nil
        end
        poolSizes[frameType] = 0
    end
end

-- Get pool statistics
function FramePool:GetStats()
    local total = 0
    for _, size in pairs(poolSizes) do
        total = total + size
    end
    
    return {
        pools = poolSizes,
        total = total,
    }
end

return FramePool
