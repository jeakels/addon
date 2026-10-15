if Config.preventLumia then
    local ENGINE_START_LIMIT = 6000
    local vehicleStates = {}

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            local now = GetGameTimer()
            for _, veh in ipairs(GetAllVehicles()) do
                if not DoesEntityExist(veh) then goto continue end
                local driverPed = GetPedInVehicleSeat(veh, -1)
                if driverPed == 0 or not IsPedAPlayer(driverPed) then
                    vehicleStates[veh] = nil
                    goto continue
                end

                local owner = NetworkGetEntityOwner(veh)
                local engineOn = GetIsVehicleEngineRunning(veh)
                local state = vehicleStates[veh]
                if not state then
                    state = {
                        driverPed   = driverPed,
                        owner       = owner
                    }
                    if not engineOn then
                        state.engineOffAt = now
                    end
                    vehicleStates[veh] = state
                    goto continue
                end

                if state.driverPed ~= driverPed then
                    state.driverPed = driverPed
                    state.owner = owner
                    if engineOn then
                        state.engineOffAt = nil
                    else
                        state.engineOffAt = now
                    end
                    goto continue
                end

                if engineOn and state.owner ~= owner then
                    PunishPlayer(owner, Config.punishment, ('Gained vehicle ownership without a driver change from player ID: %s'):format(state.owner), Config.banMedia)
                    vehicleStates[veh] = nil
                    if DoesEntityExist(veh) then DeleteEntity(veh) end
                    goto continue
                end

                if not engineOn then
                    if not state.engineOffAt then
                        state.engineOffAt = now
                    elseif now - state.engineOffAt >= ENGINE_START_LIMIT then
                        PunishPlayer(owner, Config.punishment, ("engine stuck off >%dms while player driving"):format(ENGINE_START_LIMIT), Config.banMedia)
                        vehicleStates[veh] = nil
                        if DoesEntityExist(veh) then DeleteEntity(veh) end
                        goto continue
                    end
                else
                    state.engineOffAt = nil
                end

                state.driverPed = driverPed
                state.owner = owner
                ::continue::
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(15000)
            for veh in pairs(vehicleStates) do
                if not DoesEntityExist(veh) then vehicleStates[veh] = nil end
            end
        end
    end)

    AddEventHandler('entityCreating', function(entity)
        local src = NetworkGetEntityOwner(entity)
        local modelprop = GetEntityModel(entity)
        if not IsPedAPlayer(entity) and (modelprop == 1885233650 or modelprop == 310817095) then
            CancelEvent()
            PunishPlayer(src, Config.punishment, 'Tried to crash server (Lumia)', Config.banMedia)
        end
    end)
end

if Config.handleJumpExploit then
    local lastHandle = {}
    Citizen.CreateThread(function()
        while true do
            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                if src then
                    local ped = GetPlayerPed(src)
                    if ped ~= 0 and DoesEntityExist(ped) then
                        local previous = lastHandle[src]
                        if previous and math.abs(ped - previous) > 50000 then
                            PunishPlayer(src, Config.punishment, ('Crash Exploit Detected: HandleJump Handle: %d → %d'):format(previous, ped), Config.banMedia)
                            lastHandle[src] = nil
                        else
                            lastHandle[src] = ped
                        end
                    end
                end
            end
            Citizen.Wait(250)
        end
    end)
    AddEventHandler('playerDropped', function()
        lastHandle[source] = nil
    end)
end

if Config.vehicleOwnerExploit then -- Crash from South Menu May 2026
    AddEventHandler('entityCreating', function(entity)
        if GetEntityType(entity) ~= 2 then return end

        local owner = NetworkGetEntityOwner(entity)
        if not owner or owner <= 0 then return end

        local coords = GetEntityCoords(entity)
        if coords and (coords.x ~= coords.x or math.abs(coords.x) > 15000) then
            CancelEvent()
            PunishPlayer(owner,Config.punishment,'Blocked corrupted coords', Config.banMedia)
            return
        end
        if DoesEntityExist(entity) then
            local driver = GetPedInVehicleSeat(entity, -1)
            if driver ~= 0 and DoesEntityExist(driver) then
                local driverOwner = NetworkGetEntityOwner(driver)
                if driverOwner and driverOwner ~= owner then
                    local driverPlayerPed = GetPlayerPed(driverOwner)
                    local vehicleOwnerPed = GetPlayerPed(owner)
                    if driver ~= driverPlayerPed and driver ~= vehicleOwnerPed then
                        CancelEvent()
                        PunishPlayer(owner, Config.punishment,'Blocked corrupted driver', Config.banMedia)
                        return
                    end
                end
            end
        end
    end)
end

return true
