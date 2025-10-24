--[[
--Date: 2019-11-21 19:48:49
--LastEditors: jiancheng.huang
--LastEditTime: 2020-08-29 19:52:39
--Description: format data
]]

local hexTbl = {
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
}

function numberToHex( num, len )
    -- --print("numberToHex:", num, len)
    -- local ret = ""
    -- if num == 0 then
    --     ret = "0"
    --     if len and string.len( ret ) < len then
    --         local add = len - string.len( ret )
    --         ret = string.rep( "0", add ) .. ret
    --     end
    --     --print("numberToHex ret:", ret)
    --     return ret
    -- end
    -- local value = num
    -- local mod = 0
    -- while value > 0 do 
    --     mod = value%16
    --     ret = hexTbl[mod+1] .. ret
    --     value = math.modf( value/16 )
    -- end
    -- if len and string.len( ret ) < len then
    --     local add = len - string.len( ret )
    --     ret = string.rep( "0", add ) .. ret
    -- end
    -- --print("numberToHex ret:", ret)
    -- return ret
    local str = "%X"
    if len and len > 0 then
        str = string.format( "%%0%dX", len )
    end
    return string.format( str, num )
end

function hexToString( data )
    if not data or data == "" then
        return ""
    end
    local ret = ""
    local len = string.len( data )
    local pos = 1
    while pos < len do
        ret = ret .. string.char( tonumber(string.sub( data, pos, pos+1 ), 16) )
        pos = pos + 2
    end

    return ret
end

function hexStringToByteArray( data )
    if not data or string.len( data ) == 0 then
        return {}
    end
    local dataLen = string.len( data )
    local _, num2 = math.modf( dataLen/2 )
    if num2 ~= 0 then
        data = "0" .. data
        dataLen = dataLen + 1
    end
    local tbl = {}
    local pos = 1 
    while pos < string.len( data ) do 
        local hByte = string.sub( data, pos, pos+1 )
        table.insert( tbl, hByte )
        pos = pos + 2
    end
    return tbl
end

function stringToHex( str )
    if not str or string.len( str ) == 0 then
        return ""
    end
    local ret = ""
    for i = 1, #str do 
        local byte = string.byte( str, i )
        ret = ret .. string.format( "%02X", byte )
    end
    return ret
end