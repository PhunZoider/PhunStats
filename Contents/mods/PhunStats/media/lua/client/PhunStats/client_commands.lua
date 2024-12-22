if isServer() then
    return
end
local PS = PhunStats

local Commands = {}

Commands[PS.commands.requestStats] = function(args)
    PS.data[args.playername] = args.data
    triggerEvent(PS.events.OnDataReceived)

end

return Commands
