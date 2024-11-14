if not isServer() then
    return
end
local PS = PhunStats

local Commands = {}

Commands[PS.commands.requestStats] = function(player)

    local data = PS:getData(player)
    if data then
        sendServerCommand(player, PS.name, PS.commands.requestStats, {
            playername = player:getUsername(),
            data = data
        })
    end

end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == PS.name and Commands[command] then
        Commands[command](player, args)
    end
end)
