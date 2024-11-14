if not isClient() then
    return
end
local PL = PhunLeaderboard
local Commands = require "PhunLeaderboard/Commands"

local function setup()
    Events.OnTick.Remove(setup)
    PL:ini()
    ModData.request(PL.name)
end

Events.OnTick.Add(setup)

Events.OnServerCommand.Add(function(module, command, args)
    if module == PL.name and Commands[command] then
        Commands[command](args)
    end
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PL.name then
        ModData.add(PL.name, tableData)
        PL.data = ModData.get(PL.name)
        triggerEvent(PL.events.OnDataReceived)
    end
end)
