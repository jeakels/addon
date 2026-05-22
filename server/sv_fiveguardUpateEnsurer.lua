local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.FiveguardUpdateEnsurer
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

AddEventHandler('fg:NewUpdate', function(ov, nv)
    local i = 1
    Info('Installing new fiveguard version: '..nv)
    repeat
        ExecuteCommand('refresh')
        ExecuteCommand('ensure '..Fiveguard)
        i = i + 1
        Citizen.Wait(5000)
    until pcall(function() return exports[Fiveguard].fg_BanPlayer end) and i <= 3
end)
