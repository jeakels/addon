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
