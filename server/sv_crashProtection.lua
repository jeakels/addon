local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.CrashProtection
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

if Config.preventLumia then
    local ENGINE_START_LIMIT = 6000
    local vehicleStates = {}

    local function flag(src, reason, veh)
        PunishPlayer(src, Config.punishment, reason, 'log')
        vehicleStates[veh] = nil
        if DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
    end

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(50)
            local now = GetGameTimer()
            for _, veh in ipairs(GetAllVehicles()) do
                if not DoesEntityExist(veh) then
                    goto continue
                end

                local driverPed = GetPedInVehicleSeat(veh, -1)
                if driverPed == 0 or not IsPedAPlayer(driverPed) then
                    vehicleStates[veh] = nil
                    goto continue
                end

                local owner = NetworkGetEntityOwner(veh)
                local engineOn = GetIsVehicleEngineRunning(veh)

                local state = vehicleStates[veh]
                if not state then
                    vehicleStates[veh] = {
                        driverPed   = driverPed,
                        owner       = owner,
                        engineOffAt = engineOn and nil or now
                    }
                    goto continue
                end

                if state.driverPed ~= driverPed then
                    state.driverPed = driverPed
                    state.owner = owner
                    state.engineOffAt = engineOn and nil or now
                    goto continue
                end

                if engineOn and state.owner ~= owner then
                    flag(owner, ('Gained vehicle ownership without a driver change from: [^5%s^0] ^5%s^0'):format(state.owner, GetPlayerName(state.owner)), veh)
                    goto continue
                end

                if not engineOn then
                    if not state.engineOffAt then
                        state.engineOffAt = now
                    elseif now - state.engineOffAt >= ENGINE_START_LIMIT then
                        flag(owner, ("engine stuck off >%dms while player driving"):format(ENGINE_START_LIMIT), veh)
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
                if not DoesEntityExist(veh) then
                    vehicleStates[veh] = nil
                end
            end
        end
    end)

    AddEventHandler('entityCreating', function(entity)
        local src = NetworkGetEntityOwner(entity)
        local modelprop = GetEntityModel(entity)
        if modelprop == 1885233650 or modelprop == 310817095 then
            CancelEvent()
            PunishPlayer(src, Config.punishment, 'Tried to crash server (Lumia)', Config.banMedia)
        end
    end)
end

do
    local _playerPos  = {}
    local _crasher    = {}
    local _lastPrint  = {}
    local lastHandle  = {}

    Citizen.CreateThread(function()
        while true do
            local now = GetGameTimer()
            local players = GetPlayers()
            for i = 1, #players do
                local srcId = tonumber(players[i])
                if not srcId then goto continue end
                local ped = GetPlayerPed(srcId)
                if ped ~= 0 and DoesEntityExist(ped) then
                    if Config.heliPassengerRappelExploit then
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        if vehicle ~= 0 and DoesEntityExist(vehicle) then
                            if GetVehicleType(vehicle) ~= 'heli' then
                                for taskIndex = 0, 7 do
                                    local taskType = GetPedSpecificTaskType(ped, taskIndex)
                                    if taskType == 67 then
                                        ClearPedTasksImmediately(ped)
                                        PunishPlayer(srcId, Config.punishment, ('Executing suspicious task %s (%s)'):format(taskType, taskIndex), 'image')
                                        goto continue
                                    end
                                end
                            end
                        end
                    end
                    if Config.handleJumpExploit then
                        if lastHandle[srcId] and math.abs(ped - lastHandle[srcId]) > 50000 then
                            PunishPlayer(srcId, Config.punishment, 'Crash Exploit Detected: HandleJump' .. ('Handle: %d → %d'):format(lastHandle[srcId], ped), Config.banMedia)
                            lastHandle[srcId] = nil
                            goto continue
                        end
                        lastHandle[srcId] = ped
                    end
                    if Config.ragdollSpoofExploit then
                        if IsPedRagdoll(ped) or GetEntityHealth(ped) == 0 then
                            if NetworkGetEntityOwner(ped) ~= srcId then
                                PunishPlayer(srcId, Config.punishment, 'Crash Exploit Detected: RagdollSpoof ' .. ('Owner: %d | Src: %s'):format(NetworkGetEntityOwner(ped), srcId), Config.banMedia)
                                lastHandle[srcId] = nil
                                goto continue
                            end
                        end
                    end
                    if Config.swapWeaponExploit then
                        local coords = GetEntityCoords(ped)
                        _playerPos[srcId] = coords
                        local taskType = GetPedSpecificTaskType(ped, 0)
                        if taskType == 56 then
                            local _, weaponHash = GetCurrentPedWeapon(ped, true)
                            if weaponHash == -1569615261 then
                                _crasher[srcId] = { t = now, coord = coords }
                            end
                        end
                    end
                else
                    _playerPos[srcId] = nil
                end
                ::continue::
            end
            Citizen.Wait(250)
        end
    end)
    if Config.swapWeaponExploit then
        AddEventHandler('playerDropped', function(reason)
            local srcId = source
            local victimCoords = _playerPos[srcId]
            local isCrash = reason and (
                reason:find('east%-november%-coffee', 1, false) or
                reason:find('1048F4A', 1, true) or
                reason:find('Exiting because of a fault', 1, true)
            )

            if not isCrash or not victimCoords then
                _playerPos[srcId] = nil
                _crasher[srcId]   = nil
                return
            end

            local now = GetGameTimer()
            local bestId, bestDist = nil, math.huge

            for hackId, info in pairs(_crasher) do
                if hackId ~= srcId then
                    local playerCoord = _playerPos[hackId]
                    if playerCoord and (now - info.t) < 15000 then
                        local dist = #(victimCoords - playerCoord)
                        if dist < bestDist and dist <= 30 then
                            bestDist = dist
                            bestId = hackId
                        end
                    else
                        _crasher[hackId] = nil
                    end
                end
            end

            if bestId then
                if not _lastPrint[bestId] or (now - _lastPrint[bestId]) > 3000 then
                    _lastPrint[bestId] = now
                    PunishPlayer(bestId, Config.punishment, 'Tried to crash server (April 2026 Method)', Config.banMedia)
                end
            end
            _playerPos[srcId] = nil
            _crasher[srcId]   = nil
        end)
    end
end

-- Crash from South Menu May 2026
if Config.vehicleOwnerExploit then
    AddEventHandler('entityCreating', function(entity)
        if GetEntityType(entity) ~= 2 then return end

        local owner = NetworkGetEntityOwner(entity)
        if not owner or owner <= 0 then return end

        local coords = GetEntityCoords(entity)
        if coords and (coords.x ~= coords.x or math.abs(coords.x) > 15000) then
            CancelEvent()
            PunishPlayer(owner,Config.punishment,'Blocked corrupted coords')
            return
        end

        Wait(100)
        if DoesEntityExist(entity) then
            local driver = GetPedInVehicleSeat(entity, -1)
            if driver ~= 0 and DoesEntityExist(driver) then
                local driverOwner = NetworkGetEntityOwner(driver)
                if driverOwner and driverOwner ~= owner then
                    local driverPlayerPed = GetPlayerPed(driverOwner)
                    local vehicleOwnerPed = GetPlayerPed(owner)
                    if driver ~= driverPlayerPed and driver ~= vehicleOwnerPed then
                        CancelEvent()
                        PunishPlayer(owner,Config.punishment,'Blocked corrupted driver')
                        return
                    end
                end
            end
        end
    end)
end
