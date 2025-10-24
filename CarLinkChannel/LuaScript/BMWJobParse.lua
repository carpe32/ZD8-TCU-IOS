local processClassTbl = {}
processClassTbl["01"] = "HWEL"
processClassTbl["02"] = "HWAP"
processClassTbl["03"] = "HWFR"
processClassTbl["04"] = "GWTB"
processClassTbl["05"] = "CAFD"
processClassTbl["06"] = "BTLD"
processClassTbl["07"] = "FLSL"
processClassTbl["08"] = "SWFL"
processClassTbl["09"] = "SWFF"
processClassTbl["0B"] = "ONPS"
processClassTbl["0C"] = "IBAD"
processClassTbl["0D"] = "SWFK"
processClassTbl["0F"] = "FAFP"
processClassTbl["10"] = "FCFA"
processClassTbl["1A"] = "TLRT"
processClassTbl["1B"] = "TPRG"
processClassTbl["1C"] = "BLUP"
processClassTbl["1D"] = "FLUP"
processClassTbl["A0"] = "ENTD"
processClassTbl["A1"] = "NAVD"
processClassTbl["A2"] = "FCFN"
processClassTbl["C0"] = "SWUP"
processClassTbl["C1"] = "SWIP"
processClassTbl["00"] = "UNKW"

local function getVersion( ver )
    local verValue = tonumber(ver, 16)
    if verValue < 10 then
        return "00"..verValue
    elseif verValue < 100 then
        return "0" .. verValue
    end
    return ""..verValue
end

function parseECU( data, addr )
    --print("parseECU", data, addr)
    local byteArr = hexStringToByteArray(data)
    local ecu = {}
    ecu.address = addr
    ecu.version = tonumber(byteArr[1])
    ecu.progdep = byteArr[2]
    local sgbmCount = tonumber(byteArr[3]..byteArr[4], 16)
    local fInfoSize = #byteArr - 4 - sgbmCount*8
    if fInfoSize == 13 then
        local fingerInfo = {}
        fingerInfo.progDate = byteArr[5] .. byteArr[6] .. byteArr[7]
        fingerInfo.TEK = byteArr[8]
        fingerInfo.systemSupplierId = byteArr[9]..byteArr[10]
        fingerInfo.progSystemType = byteArr[11]
        fingerInfo.progSystemSerialNumber = byteArr[12]..byteArr[13]..byteArr[14]..byteArr[15]
        fingerInfo.KMStand = byteArr[16]..byteArr[17]
        ecu.fingerInfo = fingerInfo
    end
    ecu.sgbms = {}
    local pos = 18
    for i = 1, sgbmCount do
        local pClass = processClassTbl[byteArr[pos]]
        local id = byteArr[pos+1]..byteArr[pos+2]..byteArr[pos+3]..byteArr[pos+4]
        local ver1 = getVersion(byteArr[pos+5])
        local ver2 = getVersion(byteArr[pos+6])
        local ver3 = getVersion(byteArr[pos+7])
        local sgbm = string.format( "%s_%s_%s_%s_%s", pClass, id, ver1, ver2, ver3 )
        table.insert( ecu.sgbms, sgbm )
        pos = pos + 8
    end
    return jsonEncodeObject(ecu)
end

