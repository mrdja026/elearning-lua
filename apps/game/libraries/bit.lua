-- bit.lua - Pure Lua implementation of LuaJIT's bit module
-- For Love.js compatibility (Lua 5.1 without LuaJIT)

local bit = {}

local function normalize(x)
    return x % 0x100000000
end

function bit.tobit(x)
    x = normalize(x)
    if x >= 0x80000000 then
        return x - 0x100000000
    end
    return x
end

function bit.tohex(x, n)
    n = n or 8
    x = normalize(x)
    return string.format("%0" .. n .. "x", x)
end

function bit.bnot(x)
    return bit.tobit(normalize(0xFFFFFFFF - normalize(x)))
end

function bit.band(a, b, ...)
    local result = normalize(a) % 0x100000000
    local args = {b, ...}
    for i = 1, #args do
        local x = normalize(args[i])
        local res = 0
        local shift = 1
        for j = 0, 31 do
            local a_bit = result % 2
            local b_bit = x % 2
            if a_bit == 1 and b_bit == 1 then
                res = res + shift
            end
            result = math.floor(result / 2)
            x = math.floor(x / 2)
            shift = shift * 2
        end
        result = res
    end
    return bit.tobit(result)
end

function bit.bor(a, b, ...)
    local result = normalize(a)
    local args = {b, ...}
    for i = 1, #args do
        local x = normalize(args[i])
        local res = 0
        local shift = 1
        for j = 0, 31 do
            local a_bit = result % 2
            local b_bit = x % 2
            if a_bit == 1 or b_bit == 1 then
                res = res + shift
            end
            result = math.floor(result / 2)
            x = math.floor(x / 2)
            shift = shift * 2
        end
        result = res
    end
    return bit.tobit(result)
end

function bit.bxor(a, b, ...)
    local result = normalize(a)
    local args = {b, ...}
    for i = 1, #args do
        local x = normalize(args[i])
        local res = 0
        local shift = 1
        for j = 0, 31 do
            local a_bit = result % 2
            local b_bit = x % 2
            if a_bit ~= b_bit then
                res = res + shift
            end
            result = math.floor(result / 2)
            x = math.floor(x / 2)
            shift = shift * 2
        end
        result = res
    end
    return bit.tobit(result)
end

function bit.lshift(x, n)
    return bit.tobit(normalize(x) * (2 ^ n))
end

function bit.rshift(x, n)
    return bit.tobit(math.floor(normalize(x) / (2 ^ n)))
end

function bit.arshift(x, n)
    local z = bit.rshift(x, n)
    if x >= 0x80000000 then
        z = z + bit.lshift(0xFFFFFFFF, 32 - n)
    end
    return bit.tobit(z)
end

function bit.rol(x, n)
    n = n % 32
    x = normalize(x)
    return bit.tobit(bit.bor(bit.lshift(x, n), bit.rshift(x, 32 - n)))
end

function bit.ror(x, n)
    n = n % 32
    x = normalize(x)
    return bit.tobit(bit.bor(bit.rshift(x, n), bit.lshift(x, 32 - n)))
end

function bit.bswap(x)
    x = normalize(x)
    local a = bit.band(x, 0xFF)
    local b = bit.band(bit.rshift(x, 8), 0xFF)
    local c = bit.band(bit.rshift(x, 16), 0xFF)
    local d = bit.band(bit.rshift(x, 24), 0xFF)
    return bit.tobit(bit.lshift(a, 24) + bit.lshift(b, 16) + bit.lshift(c, 8) + d)
end

return bit
