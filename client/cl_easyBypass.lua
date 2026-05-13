local data = LoadResourceFile(CurrentResourceName,'config.lua')
local Config = assert(load(data))()?.EasyBypass
if not Config.enable then return end
while not READY do Citizen.Wait(0) end
local R_EVENTS = {}

do
    for startEvent, v in pairs(Config.onClientTrigger) do
        if type(v) ~= 'table' then Error('Can\'t load bypasses config'); goto continue end
        if not v.enable then goto continue end
        if not startEvent or not v.bypass then goto continue end
        if v.endEvent == nil then Error('Missing endEvent for client bypass event: ' .. startEvent); goto continue end
        if R_EVENTS[startEvent] then Warn(('Event %s is already registered'):format(startEvent)); goto skipStartEvent end
        R_EVENTS[startEvent] = AddEventHandler(startEvent, function(...)
            local invokingResource = GetInvokingResource()
            if not invokingResource then return end
            local args = { ... }
            local value = v.booleanArgIndex and args[v.booleanArgIndex] or args[1]
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
