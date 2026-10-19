UPDATING = false
AddEventHandler('fg:NewUpdate', function(ov, nv)
    if GetInvokingResource() ~= Fiveguard then return end
    local i, ready = 1, nil
    Info('Updating fiveguard from ^5'..ov..'^0 to ^5'..nv..'^0')
    Info(('Restarting %s to apply the update...'):format(Config.restart))
    if Config.restart == 'script' then
        UPDATING = true
        repeat
            if i > 1 then Warn('Seems like Fiveguard (^3'..Fiveguard..'^0) is started but not ready yet, checking again... (attempt: '..i..')^0') end
                ExecuteCommand('refresh')
                Citizen.Wait(250)
                ExecuteCommand('ensure '..Fiveguard)
                Citizen.Wait(2000*i)
                i += 1
                ready = pcall(function() return exports[Fiveguard].fg_BanPlayer end)
        until ready or i > 3
        if not ready then
            Error('Fiveguard is started but it\'s not working properly, redownload it from ^0https://my.fiveguard.net/user/dashboard^1 and replace the files except bans.json!')
            ExecuteCommand('ensure '..Fiveguard)
        else
            Info('Fiveguard updated successfully from ^5'..ov..'^0 to ^5'..nv..'^0 !\nChangelogs: https://discord.com/channels/901177948248367135/1018417491766149241')
        end
        Citizen.Wait(5000)
        UPDATING = false
    elseif Config.restart == 'server' then
        TriggerEvent('txAdmin:events:serverShuttingDown')
        Citizen.Wait(2000)
        ExecuteCommand('quit Updating...')
    end
end)

return true
