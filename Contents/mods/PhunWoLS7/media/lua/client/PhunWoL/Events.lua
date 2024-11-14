if not isClient() then
    return
end
local PW = PhunWoL

local function setup()
    Events.OnTick.Remove(setup)
    PW:ini()
    ModData.request(PW.name)
end

Events.OnTick.Add(setup)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PW.name then
        ModData.add(PW.name, tableData)
        PW.data = ModData.get(PW.name)
        PW:debug("Received online players")
        triggerEvent(PW.events.OnDataReceived)
    end
end)
