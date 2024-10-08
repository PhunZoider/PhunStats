PhunStats = {
    inied = false,
    name = "PhunStats",
    commands = {
        requestData = "requestData",
        lastOnline = "lastOnline",
        newUser = "newUser",
        returnUser = "returnUser",
        sprinterKill = "sprinterKill",
        deathBySprinter = "deathBySprinter",
        adminUpdatePlayerOnline = "adminUpdatePlayerOnline",
        clientUpdates = "clientUpdates"
    },
    settings = {
        debug = true
    },
    leaderboard = {},
    lastOnlinePlayers = {},
    leaderboardTransmitted = 0,
    leaderboardModified = 0,
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
        if not fromPvP then
            self:incrementTotalStat(playerObj, "deaths")
        else
            self:incrementTotalStat(playerObj, "deaths")
        end
        pData.current = {}
    end
end

function PhunStats:registerAmpule(playerObj)
    self:incrementStat(playerObj, "ampules")
end

function PhunStats:registerSmoke(playerObj)
    self:incrementStat(playerObj, "smokes")
end

function PhunStats:registerSprinterKill(playerObj)
    if isClient() then
        -- be sure to tell server about it or it will be missed
        sendClientCommand(self.name, self.commands.sprinterKill, {})
    end
    if playerObj and playerObj.getUsername then
        self:incrementStat(playerObj, "sprinters")
    end
end

function PhunStats:registerRun(playerObj, distance, duration)
    if isClient() then
        self:registerForClietnUpdate(playerObj, "runDistance", distance)
        self:registerForClietnUpdate(playerObj, "runDuration", duration)
    end
    if playerObj and playerObj.getUsername then
        self:incrementStat(playerObj, "runDistance", distance)
        self:incrementStat(playerObj, "runDuration", duration)
    end
end

function PhunStats:registerSprint(playerObj, distance, duration)
    if isClient() then
        -- -- be sure to tell server about it or it will be missed
        -- sendClientCommand(self.name, self.commands.clientUpdates, {
        --     sprintDistance = distance,
        --     sprintDuration = duration
        -- })
        self:registerForClietnUpdate(playerObj, "sprintDistance", distance)
        self:registerForClietnUpdate(playerObj, "sprintDuration", duration)
    end
    if playerObj and playerObj.getUsername then
        self:incrementStat(playerObj, "sprintDistance", distance)
        self:incrementStat(playerObj, "sprintDuration", duration)
    end
end

function PhunStats:registerBanditKill(playerObj)

    self:incrementStat(playerObj, "bandit_kills")

end

function PhunStats:registerZedKill(playerObj, byCar)
    if byCar then
        self:incrementStat(playerObj, "car_kills")
    else
        self:incrementStat(playerObj, "kills")
    end
end

function PhunStats:registerPvPKill(playerObj, byCar)
    if byCar then
        self:incrementStat(playerObj, "pvp_car_kills")
    else
        self:incrementStat(playerObj, "pvp_kills")
    end
end

function PhunStats:registerPvPDeath(playerObj, byCar)

    if byCar then
        self:incrementStat(playerObj, "pvp_car_deaths")
    else
        self:incrementStat(playerObj, "pvp_deaths")
    end

    local pData = self:getPlayerData(playerObj)
    if pData then
        pData.current = {}
    end
end

function PhunStats:getLocalPlayerData(playerObj)
    local key = nil
    if type(playerObj) == "string" then
        key = playerObj
    elseif playerObj and playerObj.getUsername then
        key = playerObj:getUsername()
    else
        print("PhunStats:getLocalPlayerData() - invalid playerObj " .. tostring(playerObj))
    end
    if key and string.len(key) > 0 then
        if not self.lplayers then
            self.lplayers = {}
        end
        if not self.lplayers[key] then
            self.lplayers[key] = {}
        end
        if not self.lplayers[key].current then
            self.lplayers[key].current = {}
        end
        if not self.lplayers[key].total then
            self.lplayers[key].total = {}
        end
        return self.lplayers[key]
    end

end

-- Updates online player every 10 game mins
function PhunStats:updatePlayerTenMin(playerObj)

    local now = getTimestamp()
    local pData = self:getPlayerData(playerObj)
    local pName = playerObj:getUsername()
    local current = pData.current or {}
    local total = pData.total or {}

    local timePassed = now - (current.lastupdate or now)
    if timePassed > 0 then
        self:incrementStat(playerObj, "real_hours", timePassed / 60)
    end
    local gameTimePassed = getGameTime():getWorldAgeHours() - (current.lastHours or getGameTime():getWorldAgeHours())
    if gameTimePassed > 0 then
        self:incrementStat(playerObj, "hours", gameTimePassed)
    end
    current.lastHours = getGameTime():getWorldAgeHours()
end

function PhunStats:getPlayerData(playerObj)
    local key = nil
    if type(playerObj) == "string" then
        key = playerObj
    elseif playerObj and playerObj.getUsername then
        key = playerObj:getUsername()
    else
        print("PhunStats:getPlayerData() - invalid playerObj " .. tostring(playerObj))
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

function PhunStats:getLeaderboardEntry(category, key)
    if not self.leaderboard[category] then
        self.leaderboard[category] = {}
    end
    if not self.leaderboard[category][key] then
        self.leaderboard[category][key] = {
            who = nil,
            value = 0
        }
    end
    return self.leaderboard[category][key]
end

function PhunStats:leaderboardCheck(playerName, category, key, value)
    local leader = self:getLeaderboardEntry(category, key)
    if value > (leader.value or 0) then

        if type(playerName) == "string" then
            leader.who = playerName
        elseif playerName and playerName.getUsername then
            leader.who = playerName:getUsername()
        end

        leader.value = value
        self.leaderboard[category][key] = leader

        -- print("PhunStats:leaderboardCheck() - " .. tostring(playerName) .. " is now the leader in " ..
        --           tostring(category) .. " " .. tostring(key) .. " with " .. tostring(value))
        self.leaderboardModified = getTimestamp()
        triggerEvent(self.events.OnPhunStatsLeaderboardUpdated)
        return true

    end
    return false
end

function PhunStats:incrementStat(playerName, key, value)
    local pData = self:getPlayerData(playerName)
    if pData then
        self:updateStat(playerName, "current", key, (pData.current[key] or 0) + (value or 1))
        self:updateStat(playerName, "total", key, (pData.total[key] or 0) + (value or 1))
    end
end

function PhunStats:incrementTotalStat(playerName, key, value)
    local pData = self:getPlayerData(playerName)
    if pData then
        self:updateStat(playerName, "total", key, (pData.total[key] or 0) + (value or 1))
    end
end

function PhunStats:incrementCurrentStat(playerName, key, value)
    local pData = self:getPlayerData(playerName)
    if pData then
        self:updateStat(playerName, "current", key, (pData.total[key] or 0) + (value or 1))
    end
end

function PhunStats:setStat(playerName, key, value)
    self:updateStat(playerName, "current", key, value)
    self:updateStat(playerName, "total", key, value)
end

function PhunStats:updateStat(playerName, category, key, value)
    -- if key ~= "hours" then
    --     print(
    --         "PhunStats:updateStat() - " .. tostring(playerName) .. " " .. tostring(category) .. " " .. tostring(key) ..
    --             " " .. tostring(value))
    -- end
    local pData = self:getPlayerData(playerName)
    if pData then
        if not pData[category] then
            pData[category] = {}
        end
        pData[category][key] = value
        if isServer() then
            return self:leaderboardCheck(playerName, category, key, value)
        end
    end
end

function PhunStats:ini()
    if not self.inied then
        self.inied = true
        self.leaderboard = ModData.getOrCreate(self.name .. "_Leaderboard")
        self.players = ModData.getOrCreate(self.name .. "_Players")
        self.lastOnlinePlayers = ModData.getOrCreate(self.name .. "_LastOnline")

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
                local result = oldFnAmpules(food, player, percent)
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

if PhunRunners then
    Events[PhunRunners.events.OnSprinterDeath].Add(function(zedObj, playerObj, carKill)
        -- a sprinter died
        print("SPRINTER DIED")
        if playerObj and playerObj.getUsername then
            if playerObj:isLocalPlayer() then
                -- notify server of the kill. This only happend on client
                PhunStats:registerSprinterKill(playerObj)
            end

        end
    end)
end

local banditsIntegration = nil

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
        if banditsIntegration == nil then
            banditsIntegration = getActivatedMods():contains("Bandits")
        end

        if banditsIntegration == true then
            local data = playerObj:getModData()
            if data and data.brain then
                -- this is a bandit
                print("bandit killed")
                local player = playerObj:getAttackedBy()
                PhunStats:registerBanditKill(player)
                return
            end
        end
        local player = playerObj:getAttackedBy()
        local vehicle = player and player.getVehicle and player:getVehicle()
        if vehicle then
            if vehicle:getDriver() == player then
                PhunStats:registerZedKill(player, true)
            end
        else
            local zdata = playerObj:getModData()
            local data = zdata.PhunRunners or {}
            if data.sprinting then
                -- notify server of the kill. This only happend on client
                PhunStats:registerSprinterKill(player)
            end
            PhunStats:registerZedKill(player)
        end
    end
end)

