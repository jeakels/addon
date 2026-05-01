-- local data = LoadResourceFile(CurrentResourceName,'config.lua')
-- local Config = assert(load(data))()
while not Fiveguard do Citizen.Wait(0) end

Citizen.CreateThread(function()
    repeat Citizen.Wait(0) until NetworkIsSessionStarted() and PlayerPedId() > 0
    Citizen.Wait(3000)
    TriggerEvent('fg:addon:playerReady')
    TriggerServerEvent('fg:addon:playerReady')
    Debug("Player is ready")
end)
READY = true
