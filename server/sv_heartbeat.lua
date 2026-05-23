local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.Heartbeat
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

local sessions = {}

math.randomseed(GetGameTimer())
local function newToken(src)
    return ('%d:%d:%d'):format(src, GetGameTimer(), math.random(100000, 999999))
end

local function start(src)
    if sessions[src] then return end

    Debug('Registering player '..src..' for heartbeat')
    sessions[src] = {
        spawnedAt = nil,
        seenPong = false,
        token = nil,
        pending = nil,
        misses = 0
    }

    Citizen.CreateThread(function()
        local st = sessions[src]

        while sessions[src] == st and DoesPlayerExist(src) do
            local ped = GetPlayerPed(src)
            if not ped or ped == 0 then
                Citizen.Wait(1000)
            else
                st.spawnedAt = st.spawnedAt or GetGameTimer()

                local token = newToken(src)
                local pending = promise.new()

                st.token = token
                st.pending = pending

                TriggerClientEvent('fg:addon:heartbeat:ping', src, token)
                Debug('Sent ping to '..src..' with token '..token)

                Citizen.SetTimeout(Config.tokenExpiry * 1000, function()
                    if sessions[src] == st and st.pending == pending then
                        st.pending = nil
                        st.token = nil
                        pending:resolve(false)
                    end
                end)

                local ok = Citizen.Await(pending)

                if sessions[src] ~= st then
                    break
                end

                st.pending = nil
                st.token = nil

                local graceExpired = st.seenPong or (GetGameTimer() - st.spawnedAt) >= (Config.joinGrace * 1000)

                if ok then
                    st.seenPong = true
                    st.misses = 0
                elseif graceExpired then
                    st.misses = st.misses + 1
                    Debug(('Heartbeat miss for %s (%d/%d)'):format(src, st.misses, Config.graceMisses))

                    if st.misses >= Config.graceMisses then
                        PunishPlayer(src, Config.punishment, ('Heartbeat failed (%d misses)'):format(st.misses), false)
                        break
                    end
                end
                Citizen.Wait((Config.threadTime * 1000) + math.random(0, 1500))
            end
        end
        sessions[src] = nil
    end)
end

AddEventHandler('playerDropped', function()
    local src = source
    local st = sessions[src]
    sessions[src] = nil
    if st and st.pending then
        local pending = st.pending
        st.pending = nil
        st.token = nil
        pending:resolve(false)
    end
end)

RegisterNetEvent('fg:addon:heartbeat:pong', function(token)
    local src = source
    local st = sessions[src]

    if not st or not st.pending then return end
    if st.token ~= token then
        Debug('Invalid heartbeat token from '..src)
        return
    end

    Debug('Received valid heartbeat pong from '..src)
    local pending = st.pending
    st.pending = nil
    st.token = nil
    pending:resolve(true)
end)

Citizen.CreateThread(function()
    while true do
        for _, id in ipairs(GetPlayers()) do
            start(tonumber(id))
        end
        Citizen.Wait(2000)
    end
end)
