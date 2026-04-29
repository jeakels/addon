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
        local now = GetGameTimer()
        state[src] = {
            expected = nil,
            joinedAt = now,
            issuedAt = 0,
            lastSeen = now,
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

CreateThread(function()
    Citizen.Wait(1000)
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        ensurePlayer(src)
    end
end)

RegisterNetEvent("fg:addon:heartbeat:pong", function(token)
    local src = source
    local st = ensurePlayer(src)

    if not st.expected or st.expected ~= token then
        return
    end

    local minExpiry = (Config.threadTime or 5) + 1
    local maxAge = math.max(Config.tokenExpiry or minExpiry, minExpiry) * 1000
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

        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local st = ensurePlayer(src)

            local token = newToken(src)
            st.expected = token
            st.issuedAt = GetGameTimer()

            ---@diagnostic disable-next-line: param-type-mismatch
            TriggerClientEvent("fg:addon:heartbeat:ping", src, token)
        end

        Citizen.Wait((Config.threadTime or 5) * 1000)

        local now = GetGameTimer()

        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local st = state[src]

            if st then
                local jgrace = (Config.joinGrace or 10) * 1000
                if (now - st.joinedAt) >= jgrace then

                    local timeout = (Config.timeOut or 10) * 1000
                    if (now - st.lastSeen) > timeout then
                        st.misses = st.misses + 1
                    end

                    if st.misses >= (Config.graceMisses or 3) then
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
        local cycleTime = (Config.threadTime or 5) * 1000
        local sleep = cycleTime - elapsed

        Citizen.Wait(sleep > 0 and sleep or 0)
    end
end)
