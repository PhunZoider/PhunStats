local Delay = require "PhunStats/Delay"
local onlinePlayers = getOnlinePlayers

PhunStats = {
    inied = false,
    name = "PhunStats",
    commands = {
        notifyServer = "notifyServer",
        requestStats = "requestStats"
    },
    settings = {
        debug = true
    },
    data = {},
    events = {
        OnReady = "OnPhunStatsInied",
        OnRecord = "OnPhunStatsRecord",
        OnUpdate = "OnPhunStatsUpdate",
        OnDataReceived = "OnPhunStatsReceived"
    },
    stats = {
        pvpDeaths = {
            enabled = false,
            leaderboard = true,
            total = true,
            current = false,
            ordinal = 140,
            type = "DEATH",
            category = "DEATHS"
        },
        banditDeaths = {
            enabled = false,
            leaderboard = true,
            total = true,
            ordinal = 120,
            current = false,
            type = "DEATH",
            category = "DEATHS"
        },
        zombieDeaths = {
            ordinal = 100,
            leaderboard = true,
            current = false,
            total = true,
            type = "DEATH",
            category = "DEATHS"
        },
        otherDeaths = {
            ordinal = 110,
            current = false,
            leaderboard = false,
            total = true,
            type = "DEATH",
            category = "DEATHS"
        },
        carDeaths = {
            enabled = false,
            current = false,
            leaderboard = true,
            total = true,
            ordinal = 130,
            type = "DEATH",
            category = "DEATHS"
        },
        ampules = {
            ordinal = 200,
            leaderboard = true,
            current = true,
            total = true,
            category = "CONSUMED",
            notifyServer = true
        },
        smokes = {
            ordinal = 510,
            leaderboard = true,
            current = true,
            total = true,
            category = "CONSUMED",
            notifyServer = true
        },
        zombieKills = {
            ordinal = 300,
            leaderboard = true,
            current = true,
            total = true,
            category = "KILLS"
        },
        sprinterKills = {
            ordinal = 310,
            leaderboard = true,
            current = true,
            total = true,
            category = "KILLS",
            notifyServer = true
        },
        banditKills = {
            enabled = false,
            leaderboard = true,
            ordinal = 320,
            current = true,
            total = true,
            category = "KILLS"
        },
        pvpKills = {
            enabled = false,
            leaderboard = true,
            ordinal = 330,
            current = true,
            total = true,
            category = "KILLS"
        },
        carKills = {
            ordinal = 340,
            leaderboard = true,
            current = true,
            total = true,
            category = "KILLS"
        },
        hours = {
            ordinal = 200,
            leaderboard = true,
            current = true,
            total = true,
            type = "HOURS",
            category = "HOURS"
        }

    }
}

for _, event in pairs(PhunStats.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunStats:debug(...)
    if self.settings.debug then
        local args = {...}
        PhunTools:debug(args)
    end
end

local doTotalAndCurrent = function(stat, player, value)
    value = value or 1
    if isClient() then
        if not player:isLocalPlayer() then
            return
        end
        if stat.notifyServer then
            -- notify server
            sendClientCommand(PhunStats.name, PhunStats.commands.notifyServer, {
                key = stat.key,
                value = value
            })
        end
    end
    local data = PhunStats:getData(player)
    if data then

        if stat.type == "INCREMENT" then
            if stat.current then
                data["current"][stat.key] = (data.current[stat.key] or 0) + value
                triggerEvent(PhunStats.events.OnUpdate, player, "current", stat.key, data.current[stat.key])
            end
            if stat.total then
                data["total"][stat.key] = (data.total[stat.key] or 0) + value
                triggerEvent(PhunStats.events.OnUpdate, player, "total", stat.key, data.total[stat.key])
            end
        elseif stat.type == "DEATH" then

            local updates = {
                total = {},
                current = {}
            }
            -- PhunTools:printTable(data)
            data.total[stat.key] = (data.total[stat.key] or 0) + 1
            table.insert(updates.total, stat.key)
            data.total.hours = (data.total.hours or 0) + data.current.hours
            table.insert(updates.total, "hours")
            data.current.hours = 0
            table.insert(updates.current, "hours")

            triggerEvent(PhunStats.events.OnUpdate, player, updates)
        elseif stat.type == "HOURS" then

            if isServer() then

                data.current.hours = (data.current.hours or 0) + value or 0
                data.total.hours = (data.total.hours or 0) + value or 0
                print("hours=", data.current.hours, " total=", data.total.hours)
                triggerEvent(PhunStats.events.OnUpdate, player, "current", "hours", data.current.hours)
                triggerEvent(PhunStats.events.OnUpdate, player, "total", "hours", data.total.hours)
            else
                data.current.hours = player:getHoursSurvived()
                print("Hours survived: " .. player:getHoursSurvived())
                PhunTools:printTable(data)
                print("-----")
                triggerEvent(PhunStats.events.OnUpdate, player, "current", stat.key, data.current.hours)
                triggerEvent(PhunStats.events.OnUpdate, player, "total", stat.key,
                    (data.total.hours or 0) + data.current.hours)
            end

        end
    end

end

local gt = nil
local lastOnline = {}

function PhunStats:ini()

    if not self.inied then

        self.inied = true
        self.data = ModData.getOrCreate(self.name, {})

        for k, v in pairs(self.stats) do
            v.key = k
            if v.type == nil then
                v.type = "INCREMENT"
            end
            v.register = doTotalAndCurrent
        end

        triggerEvent(self.events.OnReady)
    end
end

function PhunStats:getData(player)
    if not player then
        return nil
    end
    local name = nil
    if type(player) == "string" then
        name = player
    elseif player and player.getUsername then
        name = player:getUsername()
    end
    if name then
        if not self.data then
            self.data = {}
        end
        if not self.data[name] then
            self.data[name] = {}
        end
        if not self.data[name].current then
            self.data[name].current = {}
        end
        if not self.data[name].total then
            self.data[name].total = {}
        end
        return self.data[name]
    end
    return nil
end

local banditsIntegration = nil

Events.OnCharacterDeath.Add(function(player)

    if banditsIntegration == nil then
        banditsIntegration = getActivatedMods():contains("Bandits")
    end
    if instanceof(player, "IsoPlayer") then
        -- a player died
        local killer = player:getAttackedBy()

        if instanceof(killer, "IsoPlayer") then
            -- a player killed another player
            local fromCar = false
            local vehicle = killer:getVehicle()
            if vehicle then
                if vehicle:getDriver() == killer then
                    fromCar = true
                end
            end

            -- register the players death and kill
            PhunStats.stats.pvpDeaths:register(player)
            PhunStats.stats.pvpKills:register(killer)

            if fromCar then
                -- register the car kill and death
                PhunStats.stats.carDeaths:register(player)
                PhunStats.stats.carKills:register(killer)
            end
        else
            if banditsIntegration == true then
                local data = killer:getModData()
                if data and data.brain then
                    -- A bandit killed the player
                    PhunStats.stats.banditDeaths:register(player)
                    return
                end
            end

            -- a zed killed the player
            PhunStats.stats.zombieDeaths:register(player)

        end
    elseif instanceof(player, "IsoZombie") then
        -- zed died
        if banditsIntegration == true then
            local data = player:getModData()
            if data and data.brain then
                -- A bandit was killed
                local killer = player:getAttackedBy()
                if instanceof(killer, "IsoPlayer") then
                    local vehicle = killer:getVehicle()

                    PhunStats.stats.banditKills:register(killer)
                    if vehicle and vehicle:getDriver() == killer then
                        PhunStats.stats.carKills:register(killer)
                    end
                end
                return
            end
        end

        local killer = player:getAttackedBy()
        if killer and instanceof(killer, "IsoPlayer") then
            local vehicle = killer and killer.getVehicle and killer:getVehicle()
            if vehicle then
                if vehicle:getDriver() == killer then
                    PhunStats.stats.zombieKills:register(killer)
                    PhunStats.stats.carKills:register(killer)
                end
            else
                PhunStats.stats.zombieKills:register(killer)
            end
        end

    end
end)

