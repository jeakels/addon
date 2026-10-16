local playerStates = {}

local function check()
    for playerId, state in pairs(playerStates) do
        if not state and not UPDATING then
            if GetResourceState(Fiveguard) ~= 'started' then return end
            PunishPlayer(playerId, Config.punishment, 'Stopping Fiveguard', Config.banMedia)
            playerStates[playerId] = nil
        end
    end
    Citizen.SetTimeout(Config.checkInterval * 1000, check)
end
check()

RegisterNetEvent('fg:addon:resourceState', function(isResourceActive)
    playerStates[source] = isResourceActive
end)

return true
