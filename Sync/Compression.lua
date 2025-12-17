-- Compression.lua - Simple data compression for sync

local Compression = {}
DPSLight_Compression = Compression

-- Encode number to base64-like string (smaller than decimal)
local function EncodeNumber(num)
    if not num or num == 0 then return "0" end
    
    local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local base = string.len(chars)
    local result = ""
    
    while num > 0 do
        local remainder = math.mod(num, base)
        result = string.sub(chars, remainder + 1, remainder + 1) .. result
        num = math.floor(num / base)
    end
    
    return result
end

-- Decode base64-like string to number
local function DecodeNumber(str)
    if not str or str == "0" then return 0 end
    
    local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local base = string.len(chars)
    local num = 0
    
    for i = 1, string.len(str) do
        local char = string.sub(str, i, i)
        local value = string.find(chars, char, 1, true) - 1
        num = num * base + value
    end
    
    return num
end

-- Compress damage data entry
function Compression:CompressDamageEntry(userID, abilityID, targetID, amount, isCrit)
    -- Format: userID:abilityID:targetID:amount:crit
    -- Using encoded numbers for smaller size
    local parts = {
        EncodeNumber(userID),
        EncodeNumber(abilityID),
        EncodeNumber(targetID),
        EncodeNumber(amount),
        isCrit and "1" or "0"
    }
    
    return table.concat(parts, ":")
end

-- Decompress damage data entry
function Compression:DecompressDamageEntry(compressed)
    local parts = {}
    for part in string.gmatch(compressed, "([^:]+)") do
        table.insert(parts, part)
    end
    
    if table.getn(parts) < 5 then return nil end
    
    return {
        userID = DecodeNumber(parts[1]),
        abilityID = DecodeNumber(parts[2]),
        targetID = DecodeNumber(parts[3]),
        amount = DecodeNumber(parts[4]),
        isCrit = parts[5] == "1",
    }
end

-- Compress multiple entries into a single string
function Compression:CompressMultiple(entries)
    local compressed = {}
    
    for _, entry in ipairs(entries) do
        if entry.type == "damage" then
            table.insert(compressed, "D" .. self:CompressDamageEntry(
                entry.userID,
                entry.abilityID,
                entry.targetID,
                entry.amount,
                entry.isCrit
            ))
        elseif entry.type == "healing" then
            table.insert(compressed, "H" .. self:CompressDamageEntry(
                entry.userID,
                entry.abilityID,
                entry.targetID,
                entry.amount,
                entry.isCrit
            ))
        end
    end
    
    return table.concat(compressed, "|")
end

-- Decompress multiple entries
function Compression:DecompressMultiple(compressed)
    local entries = {}
    
    for entryStr in string.gmatch(compressed, "([^|]+)") do
        local entryType = string.sub(entryStr, 1, 1)
        local data = string.sub(entryStr, 2)
        
        local entry = self:DecompressDamageEntry(data)
        if entry then
            if entryType == "D" then
                entry.type = "damage"
            elseif entryType == "H" then
                entry.type = "healing"
            end
            table.insert(entries, entry)
        end
    end
    
    return entries
end

-- Calculate compression ratio
function Compression:GetCompressionRatio(original, compressed)
    local originalSize = string.len(original)
    local compressedSize = string.len(compressed)
    
    if originalSize == 0 then return 1 end
    
    return compressedSize / originalSize
end

return Compression
