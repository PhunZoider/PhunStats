if not isServer() then
    return
end
local PhunStats = PhunStats
local gameTime = getGameTime()
local TEN_MINS = 0.16666667

local lastOnlinePlayers = {}

local currentAndTotalKeys = {"hours", "kills", "pvp_kills", "pvp_car_kills", "damage", "damage_taken", "ampules",
                             "sprinters", "smokes", "car_kills"}

local totalKeys = {"pvp_deaths", "pvp_car_deaths", "deaths"}

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

    -- local kills = playerObj:getZombieKills()

    -- self:updateStat(pName, "current", "kills", playerObj:getZombieKills())
    -- -- Don't add to total as that is total "previous"
    -- -- self:updateStat(pName, "total", "kills", kills)

    -- self:updateStat(pName, "current", "hours", (pData.current.hours or 0) + TEN_MINS)
    -- self:updateStat(pName, "current", "pvp_kills", (pData.current.pvp_kills or 0) + 1)
    -- self:updateStat(pName, "current", "pvp_car_kills", (pData.current.pvp_car_kills or 0) + TEN_MINS)

    -- local killDifferential = ((current.kills or 0) - kills)

    -- current.hours = (current.hours or 0) + TEN_MINS
    -- total.hours = (total.hours or 0) + TEN_MINS

    -- local hasNewHigh = false
    -- for _, key in ipairs(currentAndTotalKeys) do
    --     local totalInc = (current[key] or 0) - (total[key] or 0)
    --     if self:updateStat(pName, "current", key, pData.current[key] or 0) then
    --         hasNewHigh = true
    --     end
    --     if self:updateStat(pName, "total", key, totalInc) then
    --         hasNewHigh = true
    --     end
    -- end

    -- current.online = true
    -- current.lastonline = getTimestamp()
    -- current.lastgameday = gameTime:getDay() + 1
    -- current.lastgamemonth = gameTime:getMonth() + 1
    -- current.lastWorldHours = gameTime:getWorldAgeHours()
    -- current.lastgameyear = gameTime:getYear()

    -- current.lastupdate = getTimestamp()
    -- current.current = nil
    -- current.total = nil
    -- return hasNewHigh
end

function PhunStats:updatePlayersTenMin()
    local tempPlayersOnlineNow = {}
    local tempWasOnline = {}
    local hasNewHigh = false
    local hasDifferentPlayers = false

    -- get a copy of everyone "online"
    for k, v in pairs(self.lastOnlinePlayers) do
        if v.online == true then
            tempPlayersOnlineNow[k] = v
        end
    end

    -- iterate through all currentl online players
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        local pName = p:getUsername()

        local pData = self:getPlayerData(pName)

        if tempPlayersOnlineNow[pName] then
            -- was online and clearly still here!
            -- remove from tempPlayersOnlineNow

            local timePassed = getTimestamp() - (tempPlayersOnlineNow[pName].lastupdate or getTimestamp())
            if timePassed > 0 then
                self:incrementStat(p, "real_hours", timePassed)
            end
            local gameTimePassed = gameTime:getWorldAgeHours() - (tempPlayersOnlineNow[pName].lastWorldHours or 0)
            if gameTimePassed > 0 then
                self:incrementStat(p, "hours", gameTimePassed)
            end

            tempPlayersOnlineNow[pName] = nil
            self.lastOnlinePlayers[pName].online = true
            self.lastOnlinePlayers[pName].lastonline = getTimestamp()
            self.lastOnlinePlayers[pName].lastgameday = gameTime:getDay() + 1
            self.lastOnlinePlayers[pName].lastgamemonth = gameTime:getMonth() + 1
            self.lastOnlinePlayers[pName].lastgameyear = gameTime:getYear() + 1
            self.lastOnlinePlayers[pName].lastWorldHours = gameTime:getWorldAgeHours()
        elseif not tempPlayersOnlineNow[pName] then
            -- not currently "online" so this is a newly logged in player
            if not self.lastOnlinePlayers[pName] then
                -- we've never registered this player!
                sendServerCommand(PhunStats.name, PhunStats.commands.newUser, {
                    name = pName
                })
                hasDifferentPlayers = true
            else
                -- player was offline, but has now returned!
                hasDifferentPlayers = true
                sendServerCommand(PhunStats.name, PhunStats.commands.returningUser, {
                    name = pName,
                    lastInfo = self.lastOnlinePlayers[pName]
                })
            end
            -- register/update player
            self.lastOnlinePlayers[pName] = {
                lastonline = getTimestamp(),
                lastgameday = gameTime:getDay() + 1,
                lastgamemonth = gameTime:getMonth() + 1,
                lastgameyear = gameTime:getYear(),
                lastWorldHours = gameTime:getWorldAgeHours(),
                online = true,
                username = pName
            }
            -- don't need to removef from tempPlayersOnlineNow as they were never in there
        end
    end
    if hasNewHigh then
        self.leaderboardModified = getTimestamp()
    end

    -- remaining tempPlayersOnlineNow are players that are no longer online
    for k, v in pairs(tempPlayersOnlineNow) do
        self.lastOnlinePlayers[k].online = false
        hasDifferentPlayers = true
    end

    if hasDifferentPlayers then
        self:transmitOnline()
    end

    lastOnlinePlayers = tempPlayersOnlineNow
end

function PhunStats:transmitOnline()
    self.lastOnlinePlayers = table.sort(self.lastOnlinePlayers, function(a, b)
        return (a.lastonline or 0) > (b.value.lastonline or 0)
    end)
    ModData.transmit(PhunStats.name .. "_LastOnline")
end

function PhunStats:transmitLeaderboard()
    self.leaderboardTransmitted = getTimestamp()
    ModData.transmit(PhunStats.name .. "_Leaderboard")
end

function PhunStats:sendLastOnline(playerObj)
    if playerObj then
        sendServerCommand(playerObj, PhunStats.name, PhunStats.commands.lastOnline, self.lastOnlinePlayers)
    else
        sendServerCommand(PhunStats.name, PhunStats.commands.lastOnline, self.lastOnlinePlayers)
    end
end

local Commands = {}

Commands[PhunStats.commands.sprinterKill] = function(playerObj, arguments)
    PhunStats:registerSprinterKill(playerObj)
end

Commands[PhunStats.commands.requestData] = function(playerObj, arguments)
    local data = PhunStats:getPlayerData(playerObj)
    sendServerCommand(playerObj, PhunStats.name, PhunStats.commands.requestData, {
        playerIndex = playerObj:getPlayerNum(),
        playerName = playerObj:getUsername(),
        playerData = data
    })
end

Commands[PhunStats.commands.lastOnline] = function(playerObj, arguments)
    sendServerCommand(playerObj, PhunStats.name, PhunStats.commands.lastOnline, PhunStats.lastOnlinePlayers)
end

Events.OnClientCommand.Add(function(module, command, playerObj, arguments)
    if module == PhunStats.name and Commands[command] then
        Commands[command](playerObj, arguments)
    end
end)
Events.OnGameStart.Add(function()
    PhunStats:ini()
end)

Events.OnInitGlobalModData.Add(function()
    PhunStats:ini()
end)

Events.EveryTenMinutes.Add(function()
    PhunStats:updatePlayersTenMin()
    if PhunStats.leaderboardModified > (PhunStats.leaderboardTransmitted + 10) then
        PhunStats:transmitLeaderboard()
    end
end)

Events.EveryHours.Add(function()

end)

Events[PhunStats.events.OnPhunStatsInied].Add(function()
    PhunStats.players = ModData.getOrCreate(PhunStats.name .. "_Players")
    PhunStats.lastOnlinePlayers = ModData.getOrCreate(PhunStats.name .. "_LastOnline")
end)

-- Add a hook to save player data when the server goes empty
PhunTools:RunOnceWhenServerEmpties(PhunStats.name, function()
    PhunStats:updatePlayersTenMin()
end)
