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

Commands[PS.commands.notifyServer] = function(player, args)
    print("Notify of ", args.key, " by ", player:getUsername())
    local data = PS:getData(player)
    if data and args and args.key then

        local stat = PS.stats[args.key]
        if stat and stat.register then
            stat:register(player, args.value or 1)
        else
            print("Stat not found or not registered")
        end
    end

end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == PS.name and Commands[command] then
        Commands[command](player, args)
    end
end)
