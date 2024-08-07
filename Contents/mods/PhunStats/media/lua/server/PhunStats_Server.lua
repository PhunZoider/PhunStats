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

end

function PhunStats:updatePlayersTenMin()
    local tempPlayersOnlineNow = {}
    local tempWasOnline = {}
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
            self.lastOnlinePlayers[pName].lastgameyear = gameTime:getYear()
            self.lastOnlinePlayers[pName].lastWorldHours = gameTime:getWorldAgeHours()
        elseif not tempPlayersOnlineNow[pName] then
            -- not currently "online" so this is a newly logged in player
            if not self.lastOnlinePlayers[pName] then
                -- we've never registered this player!
                print("New player: " .. pName)
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
        return (a.lastonline or 0) > (b.lastonline or 0)
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

Commands[PhunStats.commands.clientUpdates] = function(playerObj, arguments)

    for _, v in ipairs(arguments) do
        PhunStats:incrementStat(v.player, tostring(v.key), v.value)
    end
end

Commands[PhunStats.commands.requestData] = function(playerObj, arguments)
    local data = PhunStats:getPlayerData(playerObj)
    sendServerCommand(playerObj, PhunStats.name, PhunStats.commands.requestData, {
        playerIndex = playerObj:getPlayerNum(),
        playerName = playerObj:getUsername(),
        playerData = data,
        leaderboard = PhunStats.leaderboard
    })
end

Commands[PhunStats.commands.lastOnline] = function(playerObj, arguments)
    sendServerCommand(playerObj, PhunStats.name, PhunStats.commands.lastOnline, PhunStats.lastOnlinePlayers)
end

Commands[PhunStats.commands.adminUpdatePlayerOnline] = function(playerObj, arguments)

    local playerName = arguments.playerName

    if playerName and string.len(playerName) > 0 then

        local existing = PhunStats.lastOnlinePlayers[playerName] or {}

        PhunStats.lastOnlinePlayers[playerName] = {
            lastonline = tonumber(arguments.lastonline or 0),
            lastgameday = tonumber(arguments.lastgameday or 0),
            lastgamemonth = tonumber(arguments.lastgamemonth or 0),
            lastgameyear = tonumber(arguments.lastgameyear or 0),
            lastWorldHours = tonumber(arguments.lastWorldHours or 0),
            online = existing.online == true,
            username = playerName
        }
        PhunStats:transmitOnline()
    end

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
end)

Events.EveryHours.Add(function()
    -- reducing the frequency of leaderboard updates
    if PhunStats.leaderboardModified > (PhunStats.leaderboardTransmitted + 10) then
        PhunStats:transmitLeaderboard()
    end
end)

Events[PhunStats.events.OnPhunStatsInied].Add(function()
    PhunStats.players = ModData.getOrCreate(PhunStats.name .. "_Players")
    PhunStats.lastOnlinePlayers = ModData.getOrCreate(PhunStats.name .. "_LastOnline")
end)

-- Add a hook to save player data when the server goes empty
PhunTools:RunOnceWhenServerEmpties(PhunStats.name, function()
    PhunStats:updatePlayersTenMin()
end)

Events.OnPlayerMove.Add(function(playerObj)
    local data = PhunStats:getPlayerData(playerObj)

    local isMoving, isRunning, isSprinting = playerObj:isMoving(), playerObj:isRunning(), playerObj:isSprinting()
    local x, y, z = playerObj:getX(), playerObj:getY(), playerObj:getZ()

end)
