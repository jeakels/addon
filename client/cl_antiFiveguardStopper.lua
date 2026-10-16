local function check()
    TriggerServerEvent('fg:addon:resourceState', GetResourceState(Fiveguard) == 'started')
    Citizen.SetTimeout(Config.checkInterval * 1000, check)
end
check()

return true
