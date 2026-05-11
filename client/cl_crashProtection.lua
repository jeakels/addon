local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.CrashProtection
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

-- Crash: Pneumatic Hammer
if Config.preventPneumaticHammer then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            local objects = GetGamePool('CObject')
            for _, obj in ipairs(objects) do
                if DoesEntityExist(obj) then
                    local modelHash = GetEntityModel(obj)
                    if modelHash == 1360563376 then
                        SetEntityAsMissionEntity(obj, true, true)
                        DeleteObject(obj)
                    end
                end
            end
        end
    end)
end

-- Crash: Table-golf-summer
if Config.preventTableGolfSummer then
    Citizen.CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()
            local status = GetScriptTaskStatus(ped, 0x491A782D)
            if status ~= 7 then
                ClearPedTasksImmediately(ped)
            end
            if GetIsTaskActive(ped, 57) and GetIsTaskActive(ped, 313) then
                ClearPedTasksImmediately(ped)
            end
        end
    end)
end