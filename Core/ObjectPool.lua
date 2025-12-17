-- ObjectPool.lua - High-performance object recycling system
-- Reduces garbage collection by reusing tables instead of creating new ones

local ObjectPool = {}
DPSLight_ObjectPool = ObjectPool

-- Pool configuration
local MAX_POOL_SIZE = 1000
local CLEANUP_THRESHOLD = 500

-- Pools for different object types
local tablePools = {
    small = {},    -- < 10 entries
    medium = {},   -- 10-100 entries
    large = {},    -- > 100 entries
}

local poolSizes = {
    small = 0,
    medium = 0,
    large = 0,
}

-- Determine pool type based on table size
local function GetPoolType(size)
    if size < 10 then
        return "small"
    elseif size < 100 then
        return "medium"
    else
        return "large"
    end
end

-- Get a recycled table or create new one
function ObjectPool:GetTable(estimatedSize)
    estimatedSize = estimatedSize or 0
    local poolType = GetPoolType(estimatedSize)
    local pool = tablePools[poolType]
    
    if poolSizes[poolType] > 0 then
        local t = pool[poolSizes[poolType]]
        pool[poolSizes[poolType]] = nil
        poolSizes[poolType] = poolSizes[poolType] - 1
        return t
    end
    
    return {}
end

-- Return table to pool for reuse
function ObjectPool:ReleaseTable(t, poolType)
    if not t then return end
    
    -- Determine pool type if not specified
    if not poolType then
        local size = 0
        for _ in pairs(t) do
            size = size + 1
            if size > 100 then break end
        end
        poolType = GetPoolType(size)
    end
    
    -- Clear the table
    for k in pairs(t) do
        t[k] = nil
    end
    
    -- Add to pool if under limit
    local pool = tablePools[poolType]
    if poolSizes[poolType] < MAX_POOL_SIZE then
        poolSizes[poolType] = poolSizes[poolType] + 1
        pool[poolSizes[poolType]] = t
    end
end

-- Release multiple tables at once
function ObjectPool:ReleaseTables()
    for i = 1, table.getn(arg) do
        local t = arg[i]
        if type(t) == "table" then
            self:ReleaseTable(t)
        end
    end
end

-- Clean up excess pooled objects
function ObjectPool:Cleanup()
    for poolType, pool in pairs(tablePools) do
        local size = poolSizes[poolType]
        if size > CLEANUP_THRESHOLD then
            local removeCount = size - CLEANUP_THRESHOLD
            for i = size, size - removeCount + 1, -1 do
                pool[i] = nil
            end
            poolSizes[poolType] = CLEANUP_THRESHOLD
        end
    end
end

-- Get pool statistics
function ObjectPool:GetStats()
    return {
        small = poolSizes.small,
        medium = poolSizes.medium,
        large = poolSizes.large,
        total = poolSizes.small + poolSizes.medium + poolSizes.large,
    }
end

-- Clear all pools (use sparingly)
function ObjectPool:Reset()
    for poolType, pool in pairs(tablePools) do
        for i = 1, poolSizes[poolType] do
            pool[i] = nil
        end
        poolSizes[poolType] = 0
    end
end

-- String pool for frequently used strings
local stringCache = {}
local stringCacheSize = 0
local MAX_STRING_CACHE = 500

function ObjectPool:GetCachedString(str)
    if not str then return nil end
    
    local cached = stringCache[str]
    if cached then
        return cached
    end
    
    if stringCacheSize < MAX_STRING_CACHE then
        stringCache[str] = str
        stringCacheSize = stringCacheSize + 1
    end
    
    return str
end

function ObjectPool:ClearStringCache()
    for k in pairs(stringCache) do
        stringCache[k] = nil
    end
    stringCacheSize = 0
end

-- Periodic cleanup
local cleanupTimer = 0
local CLEANUP_INTERVAL = 60 -- seconds

local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function()
    cleanupTimer = cleanupTimer + arg1
    if cleanupTimer >= CLEANUP_INTERVAL then
        ObjectPool:Cleanup()
        cleanupTimer = 0
    end
end)

return ObjectPool
