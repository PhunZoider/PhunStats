if isClient() then
    return
end
local PW = PhunWoL
local PZ = PhunZones
local PS = PhunStats
local emptyServerTickCount = 0
local emptyServerCalculate = false

Events.OnTickEvenPaused.Add(function()

    if emptyServerCalculate == true and emptyServerTickCount > 100 then
        if PS:onlinePlayers():size() == 0 then
            emptyServerCalculate = false
            PW.lastChangeKey = ""
            PW.online = {}
            for k, v in pairs(PW.data) do
                PW.data[k].o = false
                PW.data[k].ph = PW.data[k].h
            end
        end
    elseif emptyServerTickCount > 100 then
        emptyServerTickCount = 0
    else
        emptyServerTickCount = emptyServerTickCount + 1
    end
end)

Events.EveryTenMinutes.Add(function()
    emptyServerCalculate = PS:onlinePlayers():size() > 0
end)

Events.OnServerStarted.Add(function()
    PW:ini()
end)

if PZ then
    Events[PZ.events.OnPhunZoneReady].Add(function(playerObj, zone)
        PW:calculateOnline()
    end)
end

