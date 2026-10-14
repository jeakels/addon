local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.VehicleProtection
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

local function isVehicleValid(vehicle)
    if Config.preventUnNetworkedEntity then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        if not netId or netId == 0 then
            return false, 'Vehicle with Invalid net id'
        end
    end
    if Config.preventInvalidOwner then
        local owner = NetworkGetEntityOwner(vehicle)
        if not owner or owner == -1 then
            return false, 'Vehicle with Invalid Owner'
        end
    end
    if Config.preventNilResource or Config.preventUnauthorizedResource.enable then
        local scriptName = GetEntityScript(vehicle)
        if Config.preventNilResource and scriptName == nil then
            return false, 'Vehicle with an invalid resource (2)'
        end
        if Config.preventUnauthorizedResource.enable and scriptName and not Config.preventUnauthorizedResource.resourceWhitelisted[scriptName] then
            return false, 'Vehicle from non-whitelisted script: ' .. tostring(scriptName) .. ' (2)'
        end
    end
    return true
end

local function check()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(vehicle)
            and #(playerCoords - GetEntityCoords(vehicle)) <= Config.maxVehicleCheckDistance then
            local isValid, reason = isVehicleValid(vehicle)

            if not isValid then
                DeleteEntity(vehicle)
                Debug(('[VehicleProtection] Deleted vehicle %s for reason: %s'):format(vehicle, reason))
                TriggerServerEvent('fg:addon:VehicleProtection:punish', reason)
            end
        end
    end
    Citizen.SetTimeout(Config.checkInterval * 1000,check)
end
check()

if Config.preventSafeSpawn.enable then
    local function check_safespawn()
        local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if DoesEntityExist(veh) and not NetworkGetEntityIsNetworked(veh) then
                    local pos = GetEntityCoords(ped)
                    local inWhitelistZone = false
                    for i=1, #Config.preventSafeSpawn.whitelistedCoords do
                        if #(pos-Config.preventSafeSpawn.whitelistedCoords[i].coords) <= Config.preventSafeSpawn.whitelistedCoords[i].radius then
                            inWhitelistZone = true
                            break
                        end
                    end
                    Debug('[AntiSafeSpawn] inWhitelistZone',inWhitelistZone)
                    if not inWhitelistZone then
                        DeleteEntity(veh)
                        Debug('[AntiSafeSpawn] Deleted vehicle', veh)
                        TriggerServerEvent('fg:addon:VehicleProtection:punish','Safe spawned a vehicle')
                    end
                end
            end
        Citizen.SetTimeout(10000,check_safespawn)
    end
    check_safespawn()
end
