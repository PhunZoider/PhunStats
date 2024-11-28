if not isServer() then
    return
end
local PL = PhunLeaderboard
local PS = PhunStats
local Delay = require "PhunLeaderboard/Delay"
local sendServerCommand = sendServerCommand

local lastDelayTime = 0
local lastModified = 0
local lastSentTime = 0
local deferred = {}

-- store updated changes into deferred table to push out periodically
local function deferLeadboardUpdates(category, key)

    if key == nil and type(category) == "table" then
        for k, v in pairs(category) do
            if type(v) == "table" then
                for kk, vv in pairs(v) do
                    deferLeadboardUpdates(kk)
                end
            else
                deferLeadboardUpdates(k, v)
            end

        end
        return
    end

    if deferred[category] == nil then
        deferred[category] = {}
    end

    deferred[category][key] = PL.data[category][key]

    PL.deferrmentLastModified = getTimestamp()

end

function PhunLeaderboard:setDeferment()
    local seconds = PL.settings.deferSeconds
    Delay:set(seconds, function()
        if (PL.deferrmentLastModified or 0) > (PL.deferrmentLastSent or 0) then
            sendServerCommand(PL.name, PL.commands.update, deferred)
            PL.deferrmentLastSent = getTimestamp()
            -- reset delay
            PL.deferred = {}
        end
        PhunLeaderboard:setDeferment()
    end, "transmitLeaderboards")
end

local function setup()
    Events.OnTick.Remove(setup)
    PL:ini()
    PL:setDeferment()
end

Events.OnTick.Add(setup)

Events[PL.events.OnUpdate].Add(deferLeadboardUpdates)

Events[PS.events.OnUpdate].Add(function(player, category, key, value)
    PL:leaderboardCheck(player, category, key, value)
end)
