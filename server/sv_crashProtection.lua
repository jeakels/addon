local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.CrashProtection
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

-- Crash: Lumia
if Config.preventLumia then
    AddEventHandler('entityCreating', function(entity)
        local src = NetworkGetEntityOwner(entity)
        local modelprop = GetEntityModel(entity)
        if modelprop == 1885233650 or modelprop == 310817095 then
            CancelEvent()
            PunishPlayer(src, Config.punishment, 'Tried to crash server (Lumia)', Config.banMedia)
        end
    end)
end

-- Crash: New Crash Method (April 2026)
if Config.preventNewCrashMethod then
    local _playerPos  = {}
    local _crasher    = {}
    local _lastPrint  = {}
    local WAIT_TIME = 250
    local CRASH_TIME = 15000

    Citizen.CreateThread(function()
        while true do
            local now = GetGameTimer()
            local players = GetPlayers()
            for i = 1, #players do
                local srcId = tonumber(players[i])
                if not srcId then goto continue end
                local ped = GetPlayerPed(srcId)
                if ped ~= 0 and DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    _playerPos[srcId] = coords
                    local taskType = GetPedSpecificTaskType(ped, 0)
                    if taskType == 56 then
                        local _, weaponHash = GetCurrentPedWeapon(ped, true)
                        if weaponHash == -1569615261 then
                            _crasher[srcId] = { t = now, coord = coords }
                        end
                    end
                else
                    _playerPos[srcId] = nil
                end
                ::continue::
            end
            Citizen.Wait(WAIT_TIME)
        end
    end)

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
        local bestId, bestDist, bestCoord = nil, math.huge, nil

        for hackId, info in pairs(_crasher) do
            if hackId ~= srcId then
                local playerCoord = _playerPos[hackId]
                if playerCoord and (now - info.t) < CRASH_TIME then
                    local dist = #(victimCoords - playerCoord)
                    if dist < bestDist then
                        bestDist = dist
                        bestId = hackId
                        bestCoord = playerCoord
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
-- Crash: 119626B / 101C (FootIK Handle Jump / Ragdoll Spoof)
if Config.preventFootIK then
    local lastHandle = {}
    AddEventHandler('playerDropped', function()
        lastHandle[source] = nil
    end)

    Citizen.CreateThread(function()
        while true do
            Wait(500)
            for _, src in ipairs(GetPlayers()) do
                local ped = GetPlayerPed(src)
                if ped and ped > 0 then
                    if lastHandle[src] and math.abs(ped - lastHandle[src]) > 50000 then
                        PunishPlayer(src, Config.punishment, 'Crash Exploit Detected: FootIK_HandleJump ' .. ('Handle: %d → %d'):format(lastHandle[src], ped), Config.banMedia)
                        lastHandle[source] = nil
                    end
                    lastHandle[src] = ped
                    if IsPedRagdoll(ped) or GetEntityHealth(ped) == 0 then
                        if NetworkGetEntityOwner(ped) ~= tonumber(src) then
                            PunishPlayer(src, Config.punishment, 'Crash Exploit Detected: FootIK_RagdollSpoof ' .. ('Owner: %d | Src: %s'):format(NetworkGetEntityOwner(ped), src), Config.banMedia)
                            lastHandle[source] = nil
                        end
                    end
                end
            end
        end
    end)
end

-- Crash from South Menu May 2026
if Config.preventSouthMenu then
    AddEventHandler('entityCreating', function(entity)
        if GetEntityType(entity) ~= 2 then return end

        local owner = NetworkGetEntityOwner(entity)
        if not owner or owner <= 0 then return end

        local coords = GetEntityCoords(entity)
        if coords and (coords.x ~= coords.x or math.abs(coords.x) > 15000) then
            CancelEvent()
            print('[FIVEGUARD] Blocked corrupted coords from src:' .. owner)
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
                        print('[FIVEGUARD] Blocked corrupted driver from src:' .. owner)
                        return
                    end
                end
            end
        end
    end)
end