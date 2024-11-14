if not isClient() then
    return
end
local PL = PhunLeaderboard

local Commands = {}

Commands[PL.commands.update] = function(args)

    for key, value in pairs(args) do
        for k, v in pairs(value) do
            if not PL.data[key] then
                PL.data[key] = {}
            end
            PL.data[key][k] = v
        end
    end

end

return Commands
