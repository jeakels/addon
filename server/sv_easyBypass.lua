local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.EasyBypass
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end
local R_EVENTS = {}
local ClientEvents = {}
local B_CATEGORY = {
    -- AdminMenu
    ['AdminMenuAccess'] = 'AdminMenu',
    ['AnnouncementAccess'] = 'AdminMenu',
    ['ESPAccess'] = 'AdminMenu',
    ['ClearEntitiesAccess'] = 'AdminMenu',
    ['BanAndKickAccess'] = 'AdminMenu',
    ['GotoAndBringAccess'] = 'AdminMenu',
    ['VehicleAccess'] = 'AdminMenu',
    ['MiscAccess'] = 'AdminMenu',
    ['LogsAccess'] = 'AdminMenu',
    ['PlayerSelectorAccess'] = 'AdminMenu',
    ['BanListAndUnbanAccess'] = 'AdminMenu',
    ['ModelChangerAccess'] = 'AdminMenu',
    -- Client
    ['BypassSpectate'] = 'Client',
    ['BypassGodMode'] = 'Client',
    ['BypassInvisible'] = 'Client',
    ['BypassStealOutfit'] = 'Client',
    ['BypassInfStamina'] = 'Client',
    ['BypassNoclip'] = 'Client',
    ['BypassSuperJump'] = 'Client',
    ['BypassFreecam'] = 'Client',
    ['BypassSpeedHack'] = 'Client',
    ['BypassTeleport'] = 'Client',
    ['BypassNightVision'] = 'Client',
    ['BypassThermalVision'] = 'Client',
    ['BypassExplosiveAmmo'] = 'Client',
    ['BypassOCR'] = 'Client',
    ['BypassNuiDevtools'] = 'Client',
    ['BypassBlacklistedTextures'] = 'Client',
    ['BlipsBypass'] = 'Client',
    ['BypassCbScanner'] = 'Client',
    ['BypassSpoofedBulletShot'] = 'Client',
    -- Weapon
    ['BypassWeaponDmgModifier'] = 'Weapon',
    ['BypassInfAmmo'] = 'Weapon',
    ['BypassNoReload'] = 'Weapon',
    ['BypassRapidFire'] = 'Weapon',
    -- Vehicle
    ['BypassVehicleFixAndGodMode'] = 'Vehicle',
    ['BypassVehicleHandlingEdit'] = 'Vehicle',
    ['BypassVehicleModifier'] = 'Vehicle',
    ['BypassBulletproofTires'] = 'Vehicle',
    ['BypassVehiclePlateChanger'] = 'Vehicle',
    -- Blacklist
    ['BypassModelChanger'] = 'Blacklist',
    ['BypassWeaponBlacklist'] = 'Blacklist',
    -- Misc
    ['FGCommands'] = 'Misc',
    ['BypassVPN'] = 'Misc',
    ['BypassExplosion'] = 'Misc',
    ['BypassClearTasks'] = 'Misc',
    ['BypassParticle'] = 'Misc',
    ['BypassSpoofedWeapons'] = 'Misc'
}

local setTempPermission = function(src, bypasses, state, eventName)
    local result, errorText
    if not src or not bypasses then return end
    if type(bypasses) == 'string' then bypasses = { bypasses } end

    for i = 1, #bypasses do
        local bypass = bypasses[i]
        local category = B_CATEGORY[bypass]
        if not category then
            Warn(('[SetTempPermission] Unknown bypass ^5\'%s\'^0 for event ^5\'%s\'^0'):format(tostring(bypass), tostring(eventName)))
            goto continue
        end

        result, errorText = exports[Fiveguard]:SetTempPermission(src, category, bypass, state)
        if not result then
            if Config.verbose then
                Warn(('[SetTempPermission] Can\'t %s temporany permission!\nPermission: ^5\'%s.%s\'^0\nPlayer: ^5[%s] %s^0\nReason: ^5%s^0'):format(state and 'give' or 'remove', category, bypass, src, GetPlayerName(src), errorText))
            end
        else
            Debug(('[SetTempPermission] temporany Permission ^5\'%s.%s\'^0 was %s succesfully!\nPlayer changed: ^5[%s] %s^0'):format(category, bypass, state == true and '^2granted^0' or '^1removed^0', src, GetPlayerName(src)))
        end
        ::continue::
    end
end

---@param source any
---@param bol boolean
---@param resName string
---@return nil
local SafeSetEntityCoords = function(source, bol, resName)
    if resName == CurrentResourceName then return end
    if not Resources[resName] then return Warn(('[^5%s^0] ^5%s^0 tried to get a BypassTeleport using the resource: %s'):format(source,GetPlayerName(source),resName)) end
    if Config.wrapNatives.SetEntityCoords then
        local result, errorText = exports[Fiveguard]:SetTempPermission(source, B_CATEGORY['BypassTeleport'], 'BypassTeleport', bol, false)
        if not result then
            if Config.verbose then
                Warn(('The resource ^5%s^0 can\'t give temporany permission!\nPermission: ^5\'%s.%s\'^0\nPlayer: ^5[%s] %s^0\nReason: ^5%s^0'):format(resName,'Client','BypassTeleport',source,GetPlayerName(tostring(source)),errorText))
            end
        else
            Debug(('Temporany Permission ^5\'%s.%s\'^0 was %s succesfully by ^5\'%s\'^0!\nPlayer changed: ^5[%s] %s^0'):format(B_CATEGORY['BypassTeleport'],'BypassTeleport',bol == true and'^2granted^0' or '^1removed^0',resName,source,GetPlayerName(tostring(source))))
        end
    else
        Warn('Can\'t give/remove BypassTeleport since the option is disabled ')
    end
end

---@param source any
---@param bol boolean
---@param resName string
---@return nil
local SafeSetEntityVisible = function(source, bol, resName)
    if resName == CurrentResourceName then return end
    if not Resources[resName] then return Warn(('[^5%s^0] ^5%s^0 tried to get a BypassInvisible using the resource: %s'):format(source,GetPlayerName(source),resName)) end
    if Config.wrapNatives.SetEntityVisible then
        local result, errorText = exports[Fiveguard]:SetTempPermission(source, B_CATEGORY['BypassInvisible'], 'BypassInvisible', bol, false)
        if not result then
            if Config.verbose then
                Warn(('The resource ^5%s^0  can\'t give temporany permission!\nPermission: ^5\'%s.%s\'^0\nPlayer: ^5[%s] %s^0\nReason: ^5%s^0'):format(resName,'Client','BypassInvisible',source,GetPlayerName(tostring(source)),errorText))
            end
        else
            Debug(('Temporany Permission ^5\'%s.%s\'^0 was %s succesfully by ^5\'%s\'^0!\nPlayer changed: ^5[%s] %s^0'):format('Client','BypassInvisible',bol == true and'^2granted^0' or '^1removed^0',resName,source,GetPlayerName(tostring(source))))
        end
    else
        Warn('can\'t give/remove BypassInvisible since the option is disabled ')
    end
end

---@param source any
---@param bol boolean
---@param resName string
---@return nil
local SafeSetSetPedComponentVariation = function(source, bol, resName)
    if resName == CurrentResourceName then return end
    if not Resources[resName] then return Warn(('[^5%s^0] ^5%s^0 tried to get a BypassStealOutfit using the resource: %s'):format(source,GetPlayerName(source),resName)) end
    if Config.wrapNatives.SetPedComponentVariation then
        local result, errorText = exports[Fiveguard]:SetTempPermission(source, B_CATEGORY['BypassStealOutfit'], 'BypassStealOutfit', bol, false)
        if not result then
            if Config.verbose then
                Warn(('The resource ^5%s^0 can\'t give temporany permission!\nPermission: ^5\'%s.%s\'^0\nPlayer: ^5[%s] %s^0\nReason: ^5%s^0'):format(resName,'Client','BypassStealOutfit',source,GetPlayerName(tostring(source)),errorText))
            end
        else
            Debug(('Temporany Permission ^5\'%s.%s\'^0 was %s succesfully by ^5\'%s\'^0!\nPlayer changed: ^5[%s] %s^0'):format(B_CATEGORY['BypassStealOutfit'],'BypassStealOutfit',bol == true and'^2granted^0' or '^1removed^0',resName,source,GetPlayerName(tostring(source))))
        end
    else
        Warn('Can\'t give/remove BypassStealOutfit since the option is disabled ')
    end
end

RegisterNetEvent('fg:addon:SetTempPermission:BypassVehicleFixAndGodMode', function (bol,resName)
    if resName == CurrentResourceName then return end
    if not Resources[resName] then return Warn(('[^5%s^0] ^5%s^0 tried to get a BypassVehicleFixAndGodMode using the resource: %s'):format(source,GetPlayerName(source),resName)) end
    if Config.wrapNatives.SetVehicleFixed then
        local result, errorText = exports[Fiveguard]:SetTempPermission(source, B_CATEGORY['BypassVehicleFixAndGodMode'], 'BypassVehicleFixAndGodMode', bol, false)
        if not result then
            if Config.verbose then
                Warn(('The resource ^5%s^0 can\'t give temporany permission!\nPermission: ^5\'%s.%s\'^0\nPlayer: ^5[%s] %s^0\nReason: ^5%s^0'):format(resName,B_CATEGORY['BypassVehicleFixAndGodMode'],'BypassVehicleFixAndGodMode',source,GetPlayerName(tostring(source)),errorText))
            end
        else
            Debug(('Temporany Permission ^5\'%s.%s\'^0 was %s succesfully by ^5\'%s\'^0!\nPlayer changed: ^5[%s] %s^0'):format(B_CATEGORY['BypassVehicleFixAndGodMode'],'BypassVehicleFixAndGodMode',bol == true and'^2granted^0' or '^1removed^0',resName,source,GetPlayerName(tostring(source))))
        end
    else
        Warn('can\'t give/remove BypassVehicleFixAndGodMode since the option is disabled ')
    end
end)

RegisterNetEvent('fg:addon:SetTempPermission:BypassTeleport', function (bol, resName)
    return SafeSetEntityCoords(source, bol, resName)
end)
RegisterNetEvent('fg:addon:SetTempPermission:BypassInvisible', function (bol, resName)
    return SafeSetEntityVisible(source, bol, resName)
end)
RegisterNetEvent('fg:addon:SetTempPermission:BypassStealOutfit', function (bol, resName)
    return SafeSetSetPedComponentVariation(source, bol, resName)
end)

exports('SafeSetEntityCoords', function (source, bol, resName)
    return SafeSetEntityCoords(source, bol, resName)
end)
exports('SafeSetEntityVisible', function (source, bol, resName)
    return SafeSetEntityVisible(source, bol, resName)
end)
exports('SafeSetSetPedComponentVariation', function (source, bol, resName)
    return SafeSetSetPedComponentVariation(source, bol, resName)
end)

do
    for startEvent, v in pairs(Config.onServerTrigger) do
        if type(v) ~= 'table' then Error('can\'t load bypasses config for event: ' .. startEvent); goto continue end
        if not v.enable then goto continue end
        if not v.bypass or v.endEvent == nil then Error('Missing bypass/endEvent for server bypass event: ' .. startEvent); goto continue end

        do
            local endEvent = v.endEvent
            local bypasses = v.bypass
            local sourceArgIndex = not v.isNet and (v.sourceArgIndex or 1) or 0
            local booleanArgIndex = v.booleanArgIndex or sourceArgIndex + 1
            local timeout = v.duration and v.duration * 1000 or 5000

            if R_EVENTS[startEvent] then Warn(('Event %s is already registered to bypass %s'):format(startEvent,bypasses)); goto continue end
            if endEvent and endEvent ~= startEvent and R_EVENTS[endEvent] then Warn(('Event %s is already registered'):format(endEvent)); goto continue end
            if type(bypasses) == 'string' then bypasses = { bypasses } end

            if v.isNet then
                RegisterNetEvent(startEvent)
                if endEvent and endEvent ~= startEvent then
                    RegisterNetEvent(endEvent)
                end
            end

            if endEvent == false then
                R_EVENTS[startEvent] = AddEventHandler(startEvent, function(...)
                    local args = { ... }
                    local src = v.isNet and source or args[sourceArgIndex]
                    if not src or src == 0 then return Error(startEvent.. ' can\'t resolve player source! Make sure it\'s configured correctly') end

                    setTempPermission(src, bypasses, true, startEvent)
                    Citizen.SetTimeout(timeout, function()
                        setTempPermission(src, bypasses, false, startEvent)
                    end)
                end)
                Debug(('Event ^5\'%s\'^0 registered to ^2enable^0 bypass ^5%s^0'):format(startEvent,json.encode(bypasses)))
            elseif startEvent == endEvent then
                R_EVENTS[startEvent] = AddEventHandler(startEvent, function(...)
                    local args = { ... }
                    local src = v.isNet and source or args[sourceArgIndex]
                    if not src or src == 0 then return Error(startEvent.. ' can\'t resolve player source! Make sure it\'s configured correctly') end

                    if args[booleanArgIndex] == nil then
                        Warn(startEvent.. ' don\'t have a boolean argument at index '..tostring(booleanArgIndex)..'! Bypassing for '..tostring(timeout / 1000)..' seconds just in case')
                        setTempPermission(src, bypasses, true, startEvent)
                        Citizen.SetTimeout(timeout, function()
                            setTempPermission(src, bypasses, false, startEvent)
                        end)
                        return
                    end

                    local state = type(args[booleanArgIndex]) == 'boolean' and args[booleanArgIndex] or tostring(args[booleanArgIndex]) == 'true'
                    setTempPermission(src, bypasses, state, startEvent)
                end)
                Debug(('Event ^5\'%s\'^0 registered to ^3switch^0 bypass ^5%s^0'):format(startEvent,json.encode(bypasses)))
            else
                R_EVENTS[startEvent] = AddEventHandler(startEvent, function(...)
                    local args = { ... }
                    local src = v.isNet and source or args[sourceArgIndex]
                    if not src or src == 0 then return Error(startEvent.. ' can\'t resolve player source! Make sure it\'s configured correctly') end

                    setTempPermission(src, bypasses, true, startEvent)
                end)
                Debug(('Event ^5\'%s\'^0 registered to ^2enable^0 bypass ^5%s^0'):format(startEvent,json.encode(bypasses)))

                R_EVENTS[endEvent] = AddEventHandler(endEvent, function(...)
                    local args = { ... }
                    local src = v.isNet and source or args[sourceArgIndex]
                    if not src or src == 0 then return Error(endEvent.. ' can\'t resolve player source! Make sure it\'s configured correctly') end

                    setTempPermission(src, bypasses, false, endEvent)
                end)
                Debug(('Event ^5\'%s\'^0 registered to ^1disable^0 bypass ^5%s^0'):format(endEvent,json.encode(bypasses)))
            end
        end
        ::continue::
    end
    RegisterNetEvent('fg:addon:onClientTrigger')
    for startEvent, v in pairs(Config.onClientTrigger) do
        if type(v) ~= 'table' then Error('can\'t load bypasses config for event: ' .. startEvent); goto continue end
        if not v.enable then goto continue end
        if not v.bypass or v.endEvent == nil then Error('Missing bypass/endEvent for client bypass event: ' .. startEvent); goto continue end

        do
            local bypasses = v.bypass
            if type(bypasses) == 'string' then bypasses = { bypasses } end
            if ClientEvents[startEvent] or ClientEvents[v.endEvent] then Warn(startEvent..' already registered'); goto continue end
            local eventData = {
                bypass = bypasses,
                startEvent = startEvent,
                duration = v.duration and v.duration * 1000 or 5000,
                endEvent = v.endEvent
            }
            ClientEvents[startEvent] = eventData
            if v.endEvent and v.endEvent ~= startEvent then
                ClientEvents[v.endEvent] = {
                    bypass = bypasses,
                    startEvent = startEvent,
                    endEvent = v.endEvent
                }
            end
        end
        ::continue::
    end
end

R_EVENTS['onClientTrigger'] = AddEventHandler('fg:addon:onClientTrigger', function(...)
    local src = source
    local args = { ... }
    local eventName = args[1]
    local invokingResource = args[2]
    local value = args[3]
    local v = ClientEvents[eventName]

    if not v then return end
    if not src then
        Error(tostring(eventName).. ' can\'t resolve player source')
        return
    end

    local isEndEvent = v.endEvent and eventName == v.endEvent and eventName ~= v.startEvent
    local isSwitchEvent = v.endEvent == v.startEvent
    local isDurationEvent = v.endEvent == false
    Debug(('Client event ^5\'%s\'^0 forwarded by ^5\'%s\'^0'):format(tostring(eventName), tostring(invokingResource)))
    if isEndEvent then
        setTempPermission(src, v.bypass, false, eventName)
        return
    end

    if isSwitchEvent then
        if value == nil then
            Warn(tostring(eventName).. ' don\'t have a boolean argument! Bypassing for '..tostring(v.duration / 1000)..' seconds just in case')
            setTempPermission(src, v.bypass, true, eventName)
            Citizen.SetTimeout(v.duration, function()
                setTempPermission(src, v.bypass, false, eventName)
            end)
            return
        end
        local state = type(value) == 'boolean' and value or tostring(value) == 'true'
        setTempPermission(src, v.bypass, state, eventName)
        return
    end

    setTempPermission(src, v.bypass, true, eventName)
    if isDurationEvent then
        Citizen.SetTimeout(v.duration, function()
            setTempPermission(src, v.bypass, false, eventName)
        end)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if CurrentResourceName ~= res then return end
    for _, value in pairs(R_EVENTS) do
        if value then
            RemoveEventHandler(value)
        end
    end
end)
