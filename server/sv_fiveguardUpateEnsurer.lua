local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.FiveguardUpdateEnsurer
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end
UPDATING = false
AddEventHandler('fg:NewUpdate', function(ov, nv)
    if GetInvokingResource() ~= Fiveguard then return end
    UPDATING = true
    local i = 1
    Info('Updating fiveguard from ^5'..ov..'^0 to ^5'..nv..'^0')
    Info('Restarting fiveguard to apply the update...')
    repeat
        if i > 1 then Warn('Seems like Fiveguard (^3'..Fiveguard..'^0) is started but not ready yet, checking again... (attempt: '..i..')^0') end
        ExecuteCommand('refresh')
        ExecuteCommand('ensure '..Fiveguard)
        Citizen.Wait(2000*i)
        i += 1
    until pcall(function() return exports[Fiveguard].fg_BanPlayer end) or i > 3
    if i > 3 then
        Error('Fiveguard is started but it\'s not working properly, redownload it from ^0https://my.fiveguard.net/user/dashboard^1 and repalce the files exept bans.json!')
        ExecuteCommand('ensure '..Fiveguard)
    else
        Info('Fiveguard updated successfully from ^5'..ov..'^0 to ^5'..nv..'^0 !\nChangelogs: https://discord.com/channels/901177948248367135/1018417491766149241')
    end
    Citizen.Wait(5000)
    UPDATING = false
end)
