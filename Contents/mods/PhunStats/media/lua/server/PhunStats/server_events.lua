if isClient() then
    return
end
local PS = PhunStats

local function setup()
    PS:ini()
end

Events.OnServerStarted.Add(setup)
