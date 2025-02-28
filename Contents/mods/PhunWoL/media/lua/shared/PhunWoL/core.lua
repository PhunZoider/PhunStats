local Delay = require "PhunWoL/delay"
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

    local args = {...}
    for i, v in ipairs(args) do
        if type(v) == "table" then
            self:printTable(v)
        else
            print(tostring(v))
        end
    end

end

function Core:printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t or {}) do
        if type(value) == "table" then
            print(indent .. key .. ":")
            Core:printTable(value, indent .. "  ")
        elseif type(value) ~= "function" then
            print(indent .. key .. ": " .. tostring(value))
        end
    end
end

function Core:ini()
    if not self.inied then
        self.inied = true
        self.data = ModData.getOrCreate(self.name, {})

        -- convert old data to New format
        for k, v in pairs(self.data) do
            if v.o == nil or v.lastWorldHours ~= nil then
                v.o = false
                v.c = v.c or v.created or v.m or v.lastOnline
                v.m = v.m or v.lastOnline
                v.pm = v.pm or v.lastOnline
                v.n = v.n or 1
                v.s = v.s or v.seen
                v.h = v.h or v.lastWorldHours
                v.ph = v.ph or v.h

                v.playername = nil
                v.online = nil
                v.created = nil
                v.seen = nil
                v.sessions = nil
                v.wHours = nil
                v.pHours = nil
                v.lastOnline = nil
                v.lastOnline = nil
                v.lastWorldHours = nil
                v.lastGameDay = nil
                v.lastGameMonth = nil
                v.lastGameYear = nil

            end
            if v.o then
                v.o = false
                v.ph = v.h
            end
            if v.c == nil then
                v.c = getTimestamp() - 1000
            end
            if not v.pm then
                v.pm = v.m
            end
        end

        triggerEvent(self.events.OnReady)
    end
end

local pz = nil
local gt = nil
function Core:calculateOnline()

    local onlinePlayers = PS:onlinePlayers() -- Call the function to get the players
    local nowOnline = {}
    local changeKey = ""
    local recalcOnline = false

    if onlinePlayers and onlinePlayers.size and onlinePlayers:size() > 0 then

        if gt == nil then
            -- cache the GameTime instance
            gt = GameTime:getInstance()
        end
        local worldHours = math.floor(gt:getWorldAgeHours() * 100 + 0.5) / 100
        local now = getTimestamp()

        -- Check if onlinePlayers is a table or an object with a size method
        if onlinePlayers.size then -- Assuming size is a method in case it's an object

            if pz == nil then
                -- cache PhunZones
                pz = false
                if PhunZones then
                    pz = PhunZones
                end
            end

            for i = 1, onlinePlayers:size() do
                local p = onlinePlayers:get(i - 1)
                local name = p:getUsername()
                changeKey = changeKey .. name
                nowOnline[name] = true
                if not self.data[name] then
                    print(name .. " is a new player")
                    recalcOnline = true
                    -- New player
                    self.data[name] = {
                        -- u = p:getUsername(), -- username
                        c = now, -- created
                        o = true, -- online
                        n = 1, -- session count
                        m = now, -- modified/seen
                        pm = now, -- previous modified/seen
                        s = now, -- session start
                        ph = worldHours, -- previous world hours
                        h = worldHours, -- world hours
                        z = pz and pz:getPlayerData(p) or nil
                    }
                else

                    if self.data[name].o ~= true then
                        recalcOnline = true
                        -- renewing session
                        self.data[name].n = (self.data[name].n or 0) + 1 -- session count
                        self.data[name].s = now -- session start
                        self.data[name].ph = self.data[name].h -- previous world hours
                        self.data[name].pm = self.data[name].m -- previous modified/seen
                    else
                        if PS.stats.hours.register then
                            -- add difference between h and worldHours to the hours stat
                            PS.stats.hours:register(p, worldHours - (self.data[name].h or worldHours))
                        end
                    end
                    -- Existing player
                    self.data[name].o = true -- online
                    self.data[name].m = now -- modified/seen
                    self.data[name].h = worldHours
                    self.data[name].z = pz and pz:getPlayerData(p) or nil
                end

            end
        end
    end

    if self.lastChangeKey ~= changeKey or recalcOnline then
        self.lastChangeKey = changeKey

        for k, v in pairs(self.online or {}) do
            if not nowOnline[k] and self.data[k].o then
                self.data[k].o = false
                self.data[k].ph = self.data[k].h
            end
        end
        self.online = nowOnline
        triggerEvent(self.events.updated, self.data, self.online)
    end

end

local next = 0
local frequency = 15
Events.OnTick.Add(function()
    if getTimestamp() > next then
        next = getTimestamp() + frequency
        Core:calculateOnline()
    end
end)
