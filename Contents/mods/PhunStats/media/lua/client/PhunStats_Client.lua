if isServer() then
    return
end
local PhunStats = PhunStats

local function setup()
    Events.EveryOneMinute.Remove(setup)
    for i = 1, getOnlinePlayers():size() do
        local p = getOnlinePlayers():get(i - 1)
        if p:isLocalPlayer() then
            sendClientCommand(p, PhunStats.name, PhunStats.commands.requestData, {})
            sendClientCommand(p, PhunStats.name, PhunStats.commands.lastOnline, {})
        end
    end
end

local function getDistance(start, finish)
    local x = math.abs(start.x - finish.x)
    local y = math.abs(start.y - finish.y)
    local z = math.abs(start.z - finish.z)
    return math.sqrt(x ^ 2 + y ^ 2 + z ^ 2)
end

PhunStats.pendingClientUpdates = {}
PhunStats.pendingClientUpdateModified = 0
PhunStats.pendingClientUpdatesSent = 0

function PhunStats:registerForClietnUpdate(playerObj, key, value)

    for _, v in ipairs(self.pendingClientUpdates) do
        if v.player == playerObj:getUsername() and v.key == key then
            v.value = v.value + value
            self.pendingClientUpdateModified = getTimestamp()
            return
        end
    end

    table.insert(self.pendingClientUpdates, {
        player = playerObj:getUsername(),
        key = key,
        value = value
    })

    self.pendingClientUpdateModified = getTimestamp()
end

function PhunStats:playerMoving(playerObj)

    local data = self:getLocalPlayerData(playerObj)

    local isMoving, isRunning, isSprinting = playerObj:isMoving(), playerObj:isRunning(), playerObj:isSprinting()
    local x, y, z = playerObj:getX(), playerObj:getY(), playerObj:getZ()

    if isRunning and not data.current.isRunning then
        -- started running
        data.current.isRunning = true
        data.current.runningLocation = {
            x = x,
            y = y,
            z = z
        }
        data.current.runningStartTime = os.time()
    elseif not isRunning and data.current.isRunning then
        -- stopped running
        data.current.isRunning = false
        self:registerRun(playerObj, data.current.runningDistance, os.time() - data.current.runningStartTime)
        data.current.runningLocation = nil
        data.current.runningStartTime = nil
        data.current.runningDistance = nil
        data.current.runningDuration = nil
    elseif isRunning and data.current.isRunning then
        -- still running
        data.current.runningDistance = (data.current.runningDistance or 0) + getDistance(data.current.runningLocation, {
            x = x,
            y = y,
            z = z
        })
        data.current.runningLocation = {
            x = x,
            y = y,
            z = z
        }
    end
    if isSprinting and not data.current.isSprinting then
        -- started sprinting
        data.current.isSprinting = true
        data.current.sprintingLocation = {
            x = x,
            y = y,
            z = z
        }
        data.current.sprintingStartTime = os.time()
    elseif not isSprinting and data.current.isSprinting then
        -- stopped sprinting
        data.current.isSprinting = false
        local distance = getDistance(data.current.sprintingLocation, {
            x = x,
            y = y,
            z = z
        })
        self:registerSprint(playerObj, data.current.sprintingDistance, os.time() - data.current.sprintingStartTime)
        data.current.sprintingLocation = nil
        data.current.sprintingStartTime = nil
        data.current.runningDistance = nil
    elseif isSprinting and data.current.isSprinting then
        -- still sprinting
        data.current.sprintingDistance = (data.current.sprintingDistance or 0) +
                                             getDistance(data.current.sprintingLocation, {
                x = x,
                y = y,
                z = z
            })
        data.current.sprintingLocation = {
            x = x,
            y = y,
            z = z
        }
    end
end

local Commands = {}

Commands[PhunStats.commands.newUser] = function(arguments)
    PhunStats:ini()
    print("New user " .. arguments.name)
end

Commands[PhunStats.commands.requestData] = function(arguments)
    PhunStats:ini()
    PhunStats.players[arguments.playerName] = arguments.playerData
    triggerEvent(PhunStats.events.OnPhunStatsClientReady, arguments)
end

Events.EveryOneMinute.Add(setup)

Commands[PhunStats.commands.lastOnline] = function(arguments)
    PhunStats.lastOnlinePlayers = arguments
    triggerEvent(PhunStats.events.OnPhunStatsPlayersUpdated, arguments)
end

Events.OnServerCommand.Add(function(module, command, arguments)
    if module == PhunStats.name and Commands[command] then
        Commands[command](arguments)
    end
end)

Events.EveryTenMinutes.Add(function()
    if PhunStats.pendingClientUpdateModified > PhunStats.pendingClientUpdatesSent then
        if PhunStats.pendingClientUpdates and #PhunStats.pendingClientUpdates > 0 then
            sendClientCommand(PhunStats.name, PhunStats.commands.clientUpdates, PhunStats.pendingClientUpdates)
            PhunStats.pendingClientUpdates = {}
            PhunStats.pendingClientUpdatesSent = getTimestamp()
        end
    end
end)

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)

    if tableName == PhunStats.name .. "_Leaderboard" and type(tableData) == "table" then
        PhunStats.leaderboard = tableData
        ModData.add(PhunStats.name .. "_Leaderboard", PhunStats.leaderboard)
        triggerEvent(PhunStats.events.OnPhunStatsLeaderboardUpdated, tableData)
    elseif tableName == PhunStats.name .. "_Players" and type(tableData) == "table" then
        PhunStats.players = tableData
        ModData.add(PhunStats.name .. "_Players", PhunStats.players)
        triggerEvent(PhunStats.events.OnPhunStatsPlayersReceived, tableData)
    elseif tableName == PhunStats.name .. "_LastOnline" and type(tableData) == "table" then
        PhunStats.lastOnlinePlayers = tableData
        ModData.add(PhunStats.name .. "_LastOnline", PhunStats.lastOnlinePlayers)
        triggerEvent(PhunStats.events.OnPhunStatsPlayersUpdated, tableData)
    end
end)

Events.OnPlayerMove.Add(function(playerObj)
    PhunStats:playerMoving(playerObj)
end)
