local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local ConfigCrash = assert(load(data))()?.CrashProtection
if not ConfigCrash?.enable then return end
while not READY do Citizen.Wait(0) end

-- Crash: Lumia
if ConfigCrash.preventLumia then
    AddEventHandler('entityCreating', function(entity)
        local src = NetworkGetEntityOwner(entity)
        local modelprop = GetEntityModel(entity)
        if modelprop == 1885233650 or modelprop == 310817095 then
            CancelEvent()
            PunishPlayer(src, ConfigCrash.ban, "Tried to crash server (Lumia)", ConfigCrash.banMedia)
        end
    end)
end

-- Crash: New Crash Method (April 2026)
if ConfigCrash.preventNewCrashMethod then
    local _playerPos  = {}
    local _crasher    = {}
    local _lastPrint  = {}
    local WAIT_TIME = 250
    local CRASH_TIME = 15000

    CreateThread(function()
        while true do
            local now = GetGameTimer()
            local players = GetPlayers()
            for i = 1, #players do
                local srcId = tonumber(players[i])
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
            end
            Wait(WAIT_TIME)
        end
    end)

    AddEventHandler("playerDropped", function(reason)
        local srcId = source
        local victimCoords = _playerPos[srcId]
        local isCrash = reason and (
            reason:find("east%-november%-coffee", 1, false) or
            reason:find("1048F4A", 1, true) or
            reason:find("Exiting because of a fault", 1, true)
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
                PunishPlayer(bestId, ConfigCrash.ban, "Tried to crash server (April 2026 Method)", ConfigCrash.banMedia)
            end
        end
        _playerPos[srcId] = nil
        _crasher[srcId]   = nil
    end)
end

-- Crash: 119626B / 101C (FootIK Handle Jump / Ragdoll Spoof)
if ConfigCrash.preventFootIK then
    local VIOLATIONS     = {}
    local MAX_VIOLATIONS = 3
    local lastHandle     = {}

    local function flagPlayer(src, reason, detail, instant)
        if instant then
            PunishPlayer(src, ConfigCrash.ban, "Crash Exploit Detected: " .. reason, ConfigCrash.banMedia)
            VIOLATIONS[src] = nil
            lastHandle[src] = nil
            return
        end

        VIOLATIONS[src] = (VIOLATIONS[src] or 0) + 1
        if VIOLATIONS[src] >= MAX_VIOLATIONS then
            PunishPlayer(src, ConfigCrash.ban, "Crash Exploit Detected: " .. reason, ConfigCrash.banMedia)
            VIOLATIONS[src] = nil
            lastHandle[src] = nil
        end
    end

    AddEventHandler("playerDropped", function()
        VIOLATIONS[source] = nil
        lastHandle[source] = nil
    end)

    CreateThread(function()
        while true do
            Wait(500)
            for _, src in ipairs(GetPlayers()) do
                local ped = GetPlayerPed(src)
                if ped and ped > 0 then
                    if lastHandle[src] and math.abs(ped - lastHandle[src]) > 50000 then
                        flagPlayer(src, "FootIK_HandleJump", ("Handle: %d → %d"):format(lastHandle[src], ped), true)
                    end
                    lastHandle[src] = ped

                    if IsPedRagdoll(ped) or IsEntityDead(ped) then
                        if NetworkGetEntityOwner(ped) ~= tonumber(src) then
                            flagPlayer(src, "FootIK_RagdollSpoof", ("Owner: %d | Src: %s"):format(NetworkGetEntityOwner(ped), src), true)
                        end
                    end
                end
            end
        end
    end)
end