local R_EVENTS = {}
local initializationError

do
    for startEvent, v in pairs(Config.onClientTrigger) do
        if type(v) ~= 'table' then initializationError = 'Invalid bypass configuration for event: ' .. tostring(startEvent); Error(initializationError); goto continue end
        if not v.enable then goto continue end
        if not startEvent or not v.bypass then goto continue end
        if v.endEvent == nil then initializationError = 'Missing endEvent for client bypass event: ' .. tostring(startEvent); Error(initializationError); goto continue end
        if R_EVENTS[startEvent] then Warn(('Event %s is already registered'):format(startEvent)); goto skipStartEvent end
        R_EVENTS[startEvent] = AddEventHandler(startEvent, function(...)
            local invokingResource = GetInvokingResource()
            if not invokingResource then return end
            local args = { ... }
            local index = v.booleanArgIndex or 1
            local value = args[index]
            TriggerServerEvent('fg:addon:onClientTrigger', startEvent, invokingResource, value)
        end)
        ::skipStartEvent::
        if v.endEvent and v.endEvent ~= startEvent then
            if R_EVENTS[v.endEvent] then Warn(('Event %s is already registered'):format(v.endEvent)); goto continue end
            R_EVENTS[v.endEvent] = AddEventHandler(v.endEvent, function()
                local invokingResource = GetInvokingResource()
                if not invokingResource then return end
                TriggerServerEvent('fg:addon:onClientTrigger', v.endEvent, invokingResource, false)
            end)
        end
        ::continue::
    end
end

AddEventHandler('onResourceStop', function(res)
    if CurrentResourceName ~= res then return end
    for _, value in pairs(R_EVENTS) do
        if value then
            RemoveEventHandler(value)
        end
    end
end)

if initializationError then return false, initializationError .. '; other bypasses may be active' end
return true
