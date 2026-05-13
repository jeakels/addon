local data = LoadResourceFile(CurrentResourceName,'config.lua')
local Config = assert(load(data))()?.Heartbeat
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

RegisterNetEvent('fg:addon:heartbeat:ping', function(token)
    TriggerServerEvent('fg:addon:heartbeat:pong', token)
end)
