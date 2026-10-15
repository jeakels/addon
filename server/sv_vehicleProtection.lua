local modelsToDelete = {
    [-1809822327] = true, -- Cargoplane
    [-1177863319] = true, -- Tug
    [1728666326] = true,  -- Large vehicle exploit
}

AddEventHandler('entityCreated', function(entity)
    if not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 2 then return end
    if not Config.detectNPC and GetEntityPopulationType(entity) == 5 then
        return
    end
    local firstOwner
    if Config.cleanNotOwnedVehicles or Config.preventAttachVehicles then
        firstOwner = NetworkGetFirstEntityOwner(entity)
    end
    if Config.cleanNotOwnedVehicles then
        if not firstOwner or firstOwner == -1 then
            DeleteEntity(entity)
            Debug(('Vehicle without owner deleted (entity: %s)'):format(entity))
            return
        end
    end
    if Config.preventAttachVehicles then
        local attached = GetEntityAttachedTo(entity)
        if attached ~= 0 and IsPedAPlayer(attached) then
            PunishPlayer(firstOwner,Config.punishment, 'Tried to attach a vehicle to a player', Config.banMedia)
            DeleteEntity(entity)
            Debug(('Deleted attached vehicle (entity: %s)'):format(entity))
            return
        end
    end
    if Config.preventUnNetworkedEntity then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        if not netId or netId == 0 then
            Debug(NetworkGetEntityOwner(entity), 'Spawned Unnetworked Entity')
            DeleteEntity(entity)
            Debug(('Deleted unnetworked vehicle (entity: %s)'):format(entity))
            return
        end
    end
    if Config.preventLaunchPlayer then
        local model = GetEntityModel(entity)
        if modelsToDelete[model] then
            local owner = NetworkGetEntityOwner(entity)
            DeleteEntity(entity)
            Debug(('Deleted launch vehicle (entity: %s)'):format(entity))
            PunishPlayer(owner, Config.punishment, 'Tried to launch a player with '..tostring(model), Config.banMedia)
            return
        end
    end
    if Config.preventNilResource and GetEntityScript(entity) == nil then
        local owner = NetworkGetEntityOwner(entity)
        DeleteEntity(entity)
        Debug(('Deleted vehicle with nil resource (entity: %s)'):format(entity))
        PunishPlayer(owner, Config.punishment, 'Spawned vehicle with an invalid resource (1)', Config.banMedia)
        return
    end
end)

RegisterNetEvent('fg:addon:vehicleProtection:punish', function(reason)
    PunishPlayer(source, Config.punishment, reason, Config.banMedia)
end)

return true
