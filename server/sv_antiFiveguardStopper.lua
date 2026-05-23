local data = LoadResourceFile(CurrentResourceName,'config.lua')
local Config = assert(load(data))()?.AntiFiveguardStopper
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end
local playerStates = {}

local function check()
    for playerId, state in pairs(playerStates) do
        if not state and not UPDATING then
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
