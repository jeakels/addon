local Config = GetConfig()

local modules = {}
for name, config in pairs(Config) do
    if type(name) == 'string' and type(config) == 'table' and config.enable ~= nil then
        modules[#modules + 1] = name
    end
end
table.sort(modules)

local function loadModules()
    local results, pendingModules = {}, {}
    for _, name in ipairs(modules) do
        local config = Config[name]
        if type(config) ~= 'table' then
            results[name] = { status = 'problem', reason = 'Missing configuration section' }
        elseif not config.enable then
            results[name] = { status = 'disabled' }
        else
            local path = 'client/cl_' .. name .. '.lua'
            local pending = promise.new()
            local finished = false
            local function complete(initialized, reason)
                if finished then return end
                finished = true
                pending:resolve({ status = initialized == true and 'active' or 'problem', reason = reason })
            end
            Citizen.SetTimeout(60000, function()
                complete(false, 'Initialization timed out (60 seconds); module may be partially initialized')
            end)
            Citizen.CreateThread(function()
                local success, initialized, reason = xpcall(function()
                    local source = assert(LoadResourceFile(CurrentResourceName, path), 'Unable to read ' .. path)
                    local environment = setmetatable({ Config = config }, { __index = _ENV, __newindex = _ENV })
                    local chunk = assert(load(source, '@@' .. CurrentResourceName .. '/' .. path, 't', environment))
                    return chunk()
                end, debug.traceback)
                if success then
                    complete(initialized, reason or (initialized ~= true and 'Initialization did not complete' or nil))
                else
                    complete(false, initialized)
                end
            end)
            pendingModules[name] = pending
        end
    end
    for _, name in ipairs(modules) do
        if pendingModules[name] then results[name] = Citizen.Await(pendingModules[name]) end
    end
    return results
end

Citizen.CreateThread(function()
    repeat Citizen.Wait(0)
    until Fiveguard and NetworkIsSessionStarted() and PlayerPedId() > 0

    local results = loadModules()
    local colors = { active = '^2', disabled = '^3', problem = '^1' }
    local recap = '\nClient module status'
    for _, name in ipairs(modules) do
        local result = results[name]
        recap = recap .. ('\n%-22s %s%s^0'):format(name, colors[result.status], result.status)
    end
    Debug(recap)
    for _, name in ipairs(modules) do
        if results[name].reason then Warn(name .. ': ' .. tostring(results[name].reason)) end
    end

    Citizen.Wait(3000)
    TriggerEvent('fg:addon:playerReady')
    TriggerServerEvent('fg:addon:playerReady')
    Debug('Player is ready')
end)
