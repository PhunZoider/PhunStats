PhunLeaderboard = {
    name = "PhunLeaderboard",
    inied = false,
    commands = {
        update = "updatePhunLeaderboard"
    },
    settings = {
        debug = true,
        deferSeconds = 30
    },
    data = {},
    dataTransmitted = 0,
    dataModified = 0,
    dataQueue = {},
    deferred = {},
    deferrmentLastModified = 0,
    deferrmentLastSent = 0,
    events = {
        OnReady = "OnPhunLeaderboardInied",
        OnUpdate = "OnPhunLeaderboardUpdate",
        OnDataReceived = "OnPhunLeaderboardDataReceived"
    },
    keys = {
        current = {},
        total = {}
    }
}

for _, event in pairs(PhunLeaderboard.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunLeaderboard:debug(...)
    if self.settings.debug then
        local args = {...}
        PhunTools:debug(args)
    end
end

function PhunLeaderboard:ini()
    if not self.inied then
        self.inied = true
        self.data = ModData.getOrCreate(self.name, {})
        triggerEvent(self.events.OnReady)
    end
end

function PhunLeaderboard:getLeaderboardEntry(category, key)
    if not self.data[category] then
        self.data[category] = {}
    end
    if not self.data[category][key] then
        self.data[category][key] = {
            who = nil,
            value = 0
        }
    end
    return self.data[category][key]
end

function PhunLeaderboard:leaderboardCheck(player, category, key, value)

    if key == nil and type(category) == "table" then
        for k, v in pairs(category) do
            if type(v) == "table" then
                for kk, vv in pairs(v) do
                    self:leaderboardCheck(player, k, kk, vv)
                end
            else
                self:leaderboardCheck(player, k, v, value)
            end

        end
        return
    end

    if value == nil then
        value = 1
    end

    -- print("leaderboardCheck ",
    --     tostring(player:getUsername()) .. " " .. tostring(category) .. "." .. tostring(key) .. "=" .. tostring(value))
    local leader = self:getLeaderboardEntry(category, key)

    if value > (leader.value or 0) then

        if type(player) == "string" then
            leader.who = player
        elseif player and player.getUsername then
            leader.who = player:getUsername()
        end

        leader.value = value
        self.data[category][key] = leader
        triggerEvent(self.events.OnUpdate, category, key)
        return true

    end
    return false
end

