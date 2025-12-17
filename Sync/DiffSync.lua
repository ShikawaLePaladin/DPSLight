-- DiffSync.lua - Differential synchronization system
-- Only syncs changes since last sync, not full data

local DiffSync = {}
DPSLight_DiffSync = DiffSync

local DataStore = DPSLight_DataStore
local Compression = DPSLight_Compression
local EventEngine = DPSLight_EventEngine
local Config = DPSLight_Config

-- Last sync state
local lastSyncTime = 0
local pendingChanges = {}
local syncTimer = 0

-- Track changes for sync
function DiffSync:TrackChange(changeType, data)
    if not Config:Get("syncEnabled") then return end
    
    table.insert(pendingChanges, {
        timestamp = GetTime(),
        type = changeType,
        data = data,
    })
end

-- Get changes since last sync
function DiffSync:GetPendingChanges()
    return pendingChanges
end

-- Clear pending changes
function DiffSync:ClearPendingChanges()
    for i = table.getn(pendingChanges), 1, -1 do
        pendingChanges[i] = nil
    end
end

-- Send sync update to raid
function DiffSync:SendUpdate()
    if not Config:Get("syncEnabled") then return end
    
    local numRaid = GetNumRaidMembers()
    if numRaid == 0 then return end -- Not in raid
    
    local changes = self:GetPendingChanges()
    if table.getn(changes) == 0 then return end -- Nothing to sync
    
    -- Compress changes
    local compressed = Compression:CompressMultiple(changes)
    
    -- Split into chunks if too large (max 255 chars per addon message)
    local maxChunkSize = 250
    local chunks = {}
    
    for i = 1, string.len(compressed), maxChunkSize do
        local chunk = string.sub(compressed, i, i + maxChunkSize - 1)
        table.insert(chunks, chunk)
    end
    
    -- Send chunks
    for i, chunk in ipairs(chunks) do
        local header = string.format("SYNC:%d/%d:", i, table.getn(chunks))
        SendAddonMessage("DPSLight", header .. chunk, "RAID")
    end
    
    -- Clear sent changes
    self:ClearPendingChanges()
    lastSyncTime = GetTime()
end

-- Receive sync data
local receivedChunks = {}

function DiffSync:ReceiveUpdate(sender, message)
    if not Config:Get("syncEnabled") then return end
    
    -- Parse header
    local chunkNum, totalChunks, data = string.match(message, "SYNC:(%d+)/(%d+):(.*)")
    if not chunkNum then return end
    
    chunkNum = tonumber(chunkNum)
    totalChunks = tonumber(totalChunks)
    
    -- Store chunk
    if not receivedChunks[sender] then
        receivedChunks[sender] = {}
    end
    receivedChunks[sender][chunkNum] = data
    
    -- Check if we have all chunks
    local complete = true
    for i = 1, totalChunks do
        if not receivedChunks[sender][i] then
            complete = false
            break
        end
    end
    
    if complete then
        -- Reassemble message
        local compressed = table.concat(receivedChunks[sender], "")
        receivedChunks[sender] = nil
        
        -- Decompress and apply
        local changes = Compression:DecompressMultiple(compressed)
        self:ApplyChanges(changes)
    end
end

-- Apply received changes
function DiffSync:ApplyChanges(changes)
    for _, change in ipairs(changes) do
        if change.type == "damage" then
            -- Apply damage change to DataStore
            -- (Implementation depends on DataStore API)
        elseif change.type == "healing" then
            -- Apply healing change
        end
    end
end

-- Initialize sync system
function DiffSync:Initialize()
    -- Register addon message handler
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" and arg1 == "DPSLight" then
            self:ReceiveUpdate(arg2, arg3)
        end
    end)
    
    -- Periodic sync timer
    local syncFrame = CreateFrame("Frame")
    syncFrame:SetScript("OnUpdate", function()
        syncTimer = syncTimer + arg1
        local syncInterval = Config:Get("syncInterval") or 30
        
        if syncTimer >= syncInterval then
            self:SendUpdate()
            syncTimer = 0
        end
    end)
    
    -- Note: RegisterAddonMessagePrefix not needed in WoW 1.12
end

-- Enable/disable sync
function DiffSync:SetEnabled(enabled)
    Config:Set("syncEnabled", enabled)
end

function DiffSync:IsEnabled()
    return Config:Get("syncEnabled")
end

-- Get sync statistics
function DiffSync:GetStats()
    return {
        lastSyncTime = lastSyncTime,
        pendingChanges = table.getn(pendingChanges),
        syncEnabled = Config:Get("syncEnabled"),
    }
end

return DiffSync
