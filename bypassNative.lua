local resourceName = GetCurrentResourceName()
if resourceName == CurrentResourceName then return end
local Fiveguard = nil
local Addon = nil
do
    local resources = GetNumResources()
    for i = 0, resources - 1 do
        local resource = GetResourceByFindIndex(i)
        local files = GetNumResourceMetadata(resource, 'ac')
        for j = 0, files - 1 do
            local x = GetResourceMetadata(resource, 'ac', j)
            if x and x:find('fg') then
                Fiveguard = resource
                break
            end
        end
        if Fiveguard then break end
    end
    for i = 0, resources - 1 do
        local resource = GetResourceByFindIndex(i)
        local files = GetNumResourceMetadata(resource, 'addon')
        for j = 0, files - 1 do
            local x = GetResourceMetadata(resource, 'addon', j)
            if x and x:find('yes') then
                Addon = resource
                break
            end
        end
        if Addon then break end
    end
end

if IsDuplicityVersion() then
    print(('[^2INFO^0] the module ^5bypassNative^0 by addon is loaded into ^5%s^0 successfully!'):format(tostring(resourceName)))
    local setEntityCoords = SetEntityCoords
    local setEntityVisible = SetEntityVisible
    local setPedComponentVariation = SetPedComponentVariation
    SetEntityCoords = function (...)
        local source = NetworkGetEntityOwner(...)
        if not pcall(function ()
            return exports[Addon]:SafeSetEntityCoords(source, true, resourceName)
        end) then print('[^3WARN^0] EasyBypass is disabled^0') end
        Citizen.SetTimeout(1000,function ()
            if not pcall(function ()
                return exports[Addon]:SafeSetEntityCoords(source, false, resourceName)
            end) then print('[^3WARN^0] EasyBypass is disabled^0') end
        end)
        return setEntityCoords(...)
    end
    SetEntityVisible = function (...)
        local entity, toggle = ...
        local source = NetworkGetEntityOwner(entity)
        if not pcall(function ()
            return exports[Addon]:SafeSetEntityVisible(source, not toggle, resourceName)
        end) then print('[^3WARN^0] EasyBypass is disabled^0') end
        return setEntityVisible(...)
    end
    local variations = {}
    local resetTimers = {}
    local snooze = {}
    SetPedComponentVariation = function(...)
        local source = NetworkGetEntityOwner(...)
        variations[source] = (variations[source] or 0) + 1
        if not resetTimers[source] then
            resetTimers[source] = true
            Citizen.SetTimeout(50, function()
                variations[source] = nil
                resetTimers[source] = nil
            end)
        end
        if variations[source] > 2 then
            snooze[source] = (snooze[source] or 0) + 1
            local a_snooze = snooze[source]
            local ok = pcall(function()
                return exports[Addon]:SafeSetSetPedComponentVariation(source, true, resourceName)
            end)
            if not ok then print('[^3WARN^0] EasyBypass is disabled^0') end
            Citizen.SetTimeout(2000, function()
                if snooze[source] == a_snooze then
                    local ok = pcall(function()
                        return exports[Addon]:SafeSetSetPedComponentVariation(source, false, resourceName)
                    end)
                    if not ok then print('[^3WARN^0] EasyBypass is disabled^0') end
                    snooze[source] = nil
                end
            end)
            variations[source] = nil
            resetTimers[source] = nil
        end
        return setPedComponentVariation(...)
    end
else
    local setEntityCoords = SetEntityCoords
    local setVehicleFixed = SetVehicleFixed
    local setEntityVisible = SetEntityVisible
    local setPedComponentVariation = SetPedComponentVariation
    SetEntityCoords = function (...)
        TriggerServerEvent('fg:addon:SetTempPermission:BypassTeleport', true, resourceName)
        Citizen.SetTimeout(2000, function ()
            TriggerServerEvent('fg:addon:SetTempPermission:BypassTeleport', false, resourceName)
        end)
        return setEntityCoords(...)
    end
    SetVehicleFixed = function (...)
        TriggerServerEvent('fg:addon:SetTempPermission:BypassVehicleFixAndGodMode', true, resourceName)
        Citizen.SetTimeout(2000, function ()
            TriggerServerEvent('fg:addon:SetTempPermission:BypassVehicleFixAndGodMode', false, resourceName)
        end)
        return setVehicleFixed(...)
    end
    SetEntityVisible = function (...)
        local _, toggle = ...
        TriggerServerEvent('fg:addon:SetTempPermission:BypassInvisible', not toggle, resourceName)
        return setEntityVisible(...)
    end
    local variations = 0
    local resetTimer = false
    local snooze = 0
    SetPedComponentVariation = function(...)
        variations = variations + 1
        if not resetTimer then
            resetTimer = true
            Citizen.SetTimeout(50, function()
                variations = 0
                resetTimer = false
            end)
        end
        if variations > 2 then
            snooze = snooze + 1
            local a_snooze = snooze
            TriggerServerEvent('fg:addon:SetTempPermission:BypassStealOutfit', true, resourceName)
            Citizen.SetTimeout(2000, function()
                if a_snooze == snooze then
                    TriggerServerEvent('fg:addon:SetTempPermission:BypassStealOutfit', false, resourceName)
                    snooze = 0
                end
            end)
            variations = 0
            resetTimer = false
        end
        return setPedComponentVariation(...)
    end
end
