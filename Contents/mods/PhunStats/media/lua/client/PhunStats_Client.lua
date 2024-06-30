if isServer() then
    return
end
local PhunStats = PhunStats

local function setup()
    Events.EveryOneMinute.Remove(setup)
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        if p:isLocalPlayer() then
            sendClientCommand(p, PhunStats.name, PhunStats.commands.requestData, {})
            sendClientCommand(p, PhunStats.name, PhunStats.commands.lastOnline, {})
        end
    end
end

local Commands = {}

Commands[PhunStats.commands.requestData] = function(arguments)
    PhunStats:ini()
    PhunStats.players[arguments.playerName] = arguments.playerData
    triggerEvent(PhunStats.events.OnPhunStatsClientReady, arguments)
end

Events.EveryOneMinute.Add(setup)

Commands[PhunStats.commands.lastOnline] = function(arguments)
    PhunStats.lastOnlinePlayers = arguments
    triggerEvent(PhunStats.events.OnPhunStatsPlayersUpdated, arguments)
end

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunStats.name and Commands[command] then
        Commands[command](arguments)
    end
end)

Events.EveryTenMinutes.Add(function()
    -- PhunInfoUI.OnOpenPanel(getPlayer())
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)

    if tableName == PhunStats.name .. "_Leaderboard" and type(tableData) == "table" then
        PhunStats.leaderboard = tableData
        triggerEvent(PhunStats.events.OnPhunStatsLeaderboardUpdated, tableData)
    elseif tableName == PhunStats.name .. "_Players" and type(tableData) == "table" then
        PhunStats.players = tableData
        triggerEvent(PhunStats.events.OnPhunStatsPlayersReceived, tableData)
    elseif tableName == PhunStats.name .. "_LastOnline" and type(tableData) == "table" then
        PhunStats.lastOnlinePlayers = tableData
        triggerEvent(PhunStats.events.OnPhunStatsPlayersUpdated, tableData)
    end
end)
