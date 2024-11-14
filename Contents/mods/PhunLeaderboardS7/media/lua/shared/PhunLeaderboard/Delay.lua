local os_time = os.time
local Delay = {}
Delay.instances = {}

---@param delay number
---@param func function
---@param name string?
function Delay:set(delay, func, name)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.eTime = os_time() + delay
    o.func = func
    if not name then
        name = ""
    end
    o.name = name
    -- o.args = args
    table.insert(Delay.instances, o)
end

function Delay.Initialize()
    Events.OnTickEvenPaused.Remove(Delay.Handle)
    Events.OnTickEvenPaused.Add(Delay.Handle)
end

function Delay.Handle()
    local cTime = os_time()

    for i = 1, #Delay.instances do
        local inst = Delay.instances[i]
        if inst then
            if cTime > inst.eTime then
                inst.func()
                table.remove(Delay.instances, i)
            end
        end
    end
end

if isServer() then
    Events.OnServerStarted.Add(Delay.Initialize)
elseif isClient() then
    Events.OnConnected.Add(Delay.Initialize)
end

return Delay
