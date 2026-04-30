local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.Heartbeat
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

local state = {}

math.randomseed(GetGameTimer())
local function newToken(src)
    return ("%d:%d:%d"):format(src, GetGameTimer(), math.random(100000, 999999))
end

local function ensurePlayer(src)
    if not state[src] then
        Debug("Registering player "..src.." for heartbeat")
        state[src] = {
            expected = nil,
            ready = false,
            issuedAt = 0,
            lastSeen = 0,
            misses = 0
        }
    end
    return state[src]
end

AddEventHandler("playerJoining", function()
    ensurePlayer(source)
end)

AddEventHandler("playerDropped", function()
    state[source] = nil
end)

RegisterNetEvent("fg:addon:heartbeat:pong", function(token)
    Debug("Received pong from "..source.." with token "..token)
    local src = source
    local st = ensurePlayer(src)

    if not st.expected or st.expected ~= token then
        st.expected = nil
        st.issuedAt = 0
        return
    end

    local minExpiry = Config.threadTime + 1
    local maxAge = math.max(Config.tokenExpiry, minExpiry) * 1000
    if (GetGameTimer() - st.issuedAt) > maxAge then
        st.expected = nil
        st.issuedAt = 0
        return
    end

    st.expected = nil
    st.issuedAt = 0
    st.lastSeen = GetGameTimer()
    st.misses = 0
end)

CreateThread(function()
    while true do
        local cycleStart = GetGameTimer()
        local players = GetPlayers()

        for _, id in ipairs(players) do
            local src = tonumber(id)
            local st = ensurePlayer(src)

            local token = newToken(src)
            st.expected = token
            st.issuedAt = GetGameTimer()
            st.ready = GetPlayerPed(src) ~= 0
            Debug(("%s heartbeat to %s with token %s"):format(st.ready and "Issuing" or "Skipping", src, token))
            if st.ready then
                ---@diagnostic disable-next-line: param-type-mismatch
                TriggerClientEvent("fg:addon:heartbeat:ping", src, token)
                Debug("Sent ping to "..src.." with token "..token)
            end
        end

        Citizen.Wait(Config.threadTime * 1000)

        local now = GetGameTimer()
        for _, id in ipairs(players) do
            local src = tonumber(id)
            local st = state[src]

            if st then
                if st.ready then
                    Debug(("Checking heartbeat for %s: expected=%s, lastSeen=%s, misses=%s"):format(src, st.expected, st.lastSeen, st.misses))

                    if (now - st.lastSeen) > Config.timeOut*1000 then
                        st.misses = st.misses + 1
                    end

                    if st.misses >= Config.graceMisses then
                        PunishPlayer(
                            src,
                            Config.ban,
                            ("Heartbeat failed (%d misses)"):format(st.misses),
                            false
                        )
                    end
                end
            end
        end

        local elapsed = GetGameTimer() - cycleStart
        local cycleTime = Config.threadTime * 1000
        local sleep = cycleTime - elapsed

        Citizen.Wait(sleep > 0 and sleep or 0)
    end
end)
