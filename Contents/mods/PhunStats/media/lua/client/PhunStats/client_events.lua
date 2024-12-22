if isServer() then
    return
end
local PS = PhunStats
local Commands = require "PhunStats/client_commands"
local function registerSmokes()
    local oldfnSmokes = OnEat_Cigarettes

    OnEat_Cigarettes = function(food, character, percent)
        if character:isLocalPlayer() then
            PS.stats.smokes:register(character)
        end
        return oldfnSmokes(food, character, percent)
    end

end

local function registerAmpules()
    if OnEat_Zomboxivir then
        local oldFnAmpules = OnEat_Zomboxivir
        OnEat_Zomboxivir = function(food, player, percent)
            if not food:isRotten() then
                if player:isLocalPlayer() then
                    PS.stats.ampules:register(player)
                end
            end
            local bodyDamage = player:getBodyDamage();
            local result = oldFnAmpules(food, player, percent)
            return result
        end
    end
end

local function registerRunners()
    if PhunRunners then
        Events[PhunRunners.events.OnSprinterDeath].Add(function(zedObj, playerObj, carKill)
            -- a sprinter died
            if playerObj and playerObj.getUsername then
                if playerObj:isLocalPlayer() then
                    PS.stats.sprinterKills:register(playerObj)
                end
            end
        end)
    end
end

local function registerIntegrations()
    registerSmokes()
    registerAmpules()
    registerRunners()
end

Events.OnReceiveGlobalModData.Add(function(tableName, tableData)
    if tableName == PS.name then
        ModData.add(PS.name, tableData)
        PS.data = ModData.get(PS.name)
        triggerEvent(PS.events.OnDataReceived)
    end
end)

local function setup()
    Events.OnTick.Remove(setup)
    PS:ini()
    registerIntegrations()
    sendClientCommand(PS.name, PS.commands.requestStats, {})
end

Events.OnTick.Add(setup)

Events.OnServerCommand.Add(function(module, command, args)
    if module == PS.name and Commands[command] then
        Commands[command](args)
    end
end)
