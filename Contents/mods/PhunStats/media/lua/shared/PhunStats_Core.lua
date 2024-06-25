PhunStats = {
    inied = false,
    name = "PhunStats",
    commands = {
        requestData = "requestData",
        lastOnline = "lastOnline",
        newUser = "newUser",
        returnUser = "returnUser"
    },
    settings = {
        debug = true
    },
    leaderboard = {},
    lastOnlinePlayers = {},
    players = {},
    events = {
        OnPhunStatsInied = "OnPhunStatsInied",
        OnPhunStatsClientReady = "OnPhunStatsClientReady",
        OnPhunStatsLeaderboardUpdated = "OnPhunStatsLeaderboardUpdated",
        OnPhunStatsPlayersUpdated = "OnPhunStatsPlayersUpdated"
    }
}

for _, event in pairs(PhunStats.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunStats:registerMyDeath(playerObj, fromPvP)
    local pData = self:getPlayerData(playerObj)
    if pData then
        local deathAdd = 1
        local pvpAdd = 0
        if fromPvP == true then
            deathAdd = 0
            pvpAdd = 1
        end
        pData.total.deaths = (pData.total.deaths or 0) + deathAdd
        pData.total.pvp_deaths = (pData.total.pvp_deaths or 0) + pvpAdd
        pData.current.hours = 0
        pData.current.kills = 0
        pData.current.pvp_kills = 0
        pData.current.damage = 0
        pData.current.damage_taken = 0
        pData.current.ampules = 0
        pData.current.sprinters = 0
        pData.current.smokes = 0
        pData.current.car_kills = 0
    end
end

function PhunStats:registerAmpule(playerObj)
    local pData = self:getPlayerData(playerObj)
    if pData then
        pData.current.ampules = (pData.current.ampules or 0) + 1
        pData.total.ampules = (pData.total.ampules or 0) + 1
    end
end

function PhunStats:registerSmoke(playerObj)
    local pData = self:getPlayerData(playerObj)
    if pData then
        pData.current.smokes = (pData.current.smokes or 0) + 1
        pData.total.smokes = (pData.total.smokes or 0) + 1
    end
end

function PhunStats:registerSprinterKill(playerObj)
    local pData = self:getPlayerData(playerObj)
    if pData then
        pData.current.sprinters = (pData.current.sprinters or 0) + 1
        pData.total.sprinters = (pData.total.sprinters or 0) + 1
    end
end

function PhunStats:registerZedKill(playerObj, byCar)
    local pData = self:getPlayerData(playerObj)
    if pData then
        if byCar == true then
            pData.current.car_kills = (pData.current.car_kills or 0) + 1
            pData.total.car_kills = (pData.total.car_kills or 0) + 1
        else
            pData.current.kills = (pData.current.kills or 0) + 1
            pData.total.kills = (pData.total.kills or 0) + 1
        end

    end
end

function PhunStats:registerPvPKill(playerObj, byCar)
    local pData = self:getPlayerData(playerObj)
    if pData then
        if byCar == true then
            pData.current.pvp_car_kills = (pData.current.pvp_car_kills or 0) + 1
            pData.total.pvp_car_kills = (pData.total.pvp_car_kills or 0) + 1
        else
            pData.current.pvp_kills = (pData.current.pvp_kills or 0) + 1
            pData.total.pvp_kills = (pData.total.pvp_kills or 0) + 1
        end
    end
end

function PhunStats:registerPvPDeath(playerObj, byCar)
    local pData = self:getPlayerData(playerObj)
    if pData then
        if byCar then
            pData.total.pvp_car_deaths = (pData.total.pvp_car_deaths or 0) + 1
        else
            pData.total.pvp_deaths = (pData.total.pvp_deaths or 0) + 1
        end
        pData.current.hours = 0
        pData.current.kills = 0
        pData.current.pvp_kills = 0
        pData.current.damage = 0
        pData.current.damage_taken = 0
        pData.current.ampules = 0
        pData.current.sprinters = 0
        pData.current.smokes = 0
        pData.current.car_kills = 0
    end
end

function PhunStats:getPlayerData(playerObj)
    local key = nil
    if type(playerObj) == "string" then
        key = playerObj
    else
        key = playerObj:getUsername()
    end
    if key and string.len(key) > 0 then
        if not self.players then
            self.players = {}
        end
        if not self.players[key] then
            self.players[key] = {}
        end
        if not self.players[key].current then
            self.players[key].current = {}
        end
        if not self.players[key].total then
            self.players[key].total = {}
        end
        return self.players[key]
    end
end

function PhunStats:getLeaderboardEntry(key)
    if not self.leaderboard[key] then
        self.leaderboard[key] = {
            who = nil,
            value = 0
        }
    end
    return self.leaderboard[key]
end

function PhunStats:leaderboardCheck(playerName, key, value)
    local leader = self:getLeaderboardEntry(key)
    if value > (leader.value or 0) then
        leader.who = playerName
        leader.value = value
        return true
    end
    return false
end

function PhunStats:updateStat(playerName, category, key, value)
    local pData = self:getPlayerData(playerName)
    if pData then
        pData.current[category] = value
        return self:leaderboardCheck(playerName, key, value)
    end
end

function PhunStats:ini()
    if not self.inied then
        self.inied = true
        self.leaderboard = ModData.getOrCreate(PhunStats.name .. "_Leaderboard")
        self.players = ModData.getOrCreate(PhunStats.name .. "_Players")
        self.lastOnlinePlayers = ModData.getOrCreate(PhunStats.name .. "_LastOnline")

        if isServer() then
            PhunTools:printTable(self.lastOnlinePlayers)
        end

        triggerEvent(self.events.OnPhunStatsInied)

        local oldfnSmokes = OnEat_Cigarettes

        OnEat_Cigarettes = function(food, character, percent)
            PhunStats:registerSmoke(character)
            return oldfnSmokes(food, character, percent)
        end

        if OnEat_Zomboxivir then
            local oldFnAmpules = OnEat_Zomboxivir
            OnEat_Zomboxivir = function(food, player, percent)
                if not food:isRotten() then
                    PhunStats:registerAmpule(player)
                end
                local bodyDamage = player:getBodyDamage();
                print("before")
                -- print("infected=" .. tostring(bodyDamage:getInfected()));
                print("infLevel=" .. tostring(bodyDamage:getInfectionLevel()));
                local result = oldFnAmpules(food, player, percent)
                print("after")
                bodyDamage = player:getBodyDamage();
                -- print("infected=" .. tostring(bodyDamage:getInfected()));
                print("infLevel=" .. tostring(bodyDamage:getInfectionLevel()));
                return result
            end
        end

    end

end

function PhunStats:debug(...)
    if self.settings.debug then
        local args = {...}
        PhunTools:debug(args)
    end
end

Events.OnCharacterDeath.Add(function(playerObj)
    if instanceof(playerObj, "IsoPlayer") then
        -- a player died
        local killer = playerObj:getAttackedBy()

        if instanceof(killer, "IsoPlayer") then
            -- another player did it
            local fromCar = false
            local vehicle = killer:getVehicle()
            if vehicle then
                if vehicle:getDriver() == killer then
                    fromCar = true
                end
            end
            PhunStats:registerPvPDeath(playerObj, fromCar)
            PhunStats:registerPvPKill(killer, fromCar)
        else
            -- player killed by player, but no idea how
            PhunStats:registerMyDeath(playerObj)
        end
    elseif instanceof(playerObj, "IsoZombie") then
        -- zed died
        local player = playerObj:getAttackedBy()
        local vehicle = player:getVehicle()
        if vehicle then
            if vehicle:getDriver() == player then
                PhunStats:registerZedKill(player, true)
            end
        else
            local zdata = playerObj:getModData()
            local data = zdata.PhunRunners or {}
            -- PhunTools:debug("-- z --", zdata)
            if data.sprinting then
                PhunStats:registerSprinterKill(player)
            else
                PhunStats:registerZedKill(player)
            end
        end
    end
end)

