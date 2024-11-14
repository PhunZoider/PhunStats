require "PhunStats/Core"
local Delay = require "PhunLeaderboard/Delay"
local PS = PhunStats

PhunWoL = {
    name = "PhunWoL",
    inied = false,
    commands = {
        update = "updatePhunWoL"
    },
    settings = {
        debug = true
    },
    data = {},
    online = {},
    events = {
        OnReady = "OnPhunWoLInied",
        updated = "OnPhunWoLUpdated",
        OnDataReceived = "OnPhunWoLDataReceived"
    }
}

local Core = PhunWoL

for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:debug(...)
    if self.settings.debug then
        local args = {...}
        PhunTools:debug(args)
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
        self.data = ModData.getOrCreate(self.name, {})
        triggerEvent(self.events.OnReady)
        self:calculateOnline()
    end
end

local gt = nil
function Core:calculateOnline()

    if getOnlinePlayers then
        local onlinePlayers = getOnlinePlayers() -- Call the function to get the players
        local nowOnline = {}
        local changeKey = ""
        if onlinePlayers and onlinePlayers.size and onlinePlayers:size() > 0 then

            if gt == nil then
                gt = GameTime:getInstance()
            end

            local gameDay = gt:getDay() + 1
            local gameMonth = gt:getMonth() + 1
            local gameYear = gt:getYear()
            local worldHours = gt:getWorldAgeHours()
            local now = getTimestamp()

            -- Check if onlinePlayers is a table or an object with a size method
            if onlinePlayers.size then -- Assuming size is a method in case it's an object

                for i = 1, onlinePlayers:size() do
                    local p = onlinePlayers:get(i - 1)
                    local name = p:getUsername()
                    changeKey = changeKey .. name
                    nowOnline[name] = true
                    if not self.data[name] then
                        self.data[name] = {
                            playername = p:getUsername(),
                            created = now,
                            lastOnline = now,
                            lastGameDay = gameDay,
                            lastGameMonth = gameMonth,
                            lastGameYear = gameYear,
                            lastWorldHours = worldHours
                        }
                    else
                        self.data[name].lastOnline = now
                        self.data[name].lastGameDay = gameDay
                        self.data[name].lastGameMonth = gameMonth
                        self.data[name].lastGameYear = gameYear
                        self.data[name].lastWorldHours = worldHours
                    end
                    if PS.stats.hours.register then
                        PS.stats.hours:register(p)
                    end
                end
            end
        end
        self.online = nowOnline
        table.sort(self.data, function(a, b)
            return a.lastOnline > b.lastOnline
        end)
        if self.lastChangeKey ~= changeKey then
            self.lastChangeKey = changeKey
            triggerEvent(self.events.updated, self.data, self.online)
        end

    end

    Delay:set(15, function()
        Core:calculateOnline()
    end, "calculateOnline")

end

if isServer() then
    Events.OnServerStarted.Add(function()
        Core:ini()
    end)
end
