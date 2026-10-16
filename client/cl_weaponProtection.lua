local hasInitialWeaponsBeenChecked = false
local waitingForServer = false
local initialWeapons

RegisterNetEvent('fg:addon:initialWeaponsReady', function(required)
    if source ~= 65535 or not waitingForServer or type(required) ~= 'boolean' then return end
    waitingForServer = false
    if required then
        TriggerServerEvent('fg:addon:registerInitialWeapons', initialWeapons)
    end
end)

local WeaponsToCheck = {
    'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL', 'WEAPON_PISTOL50', 'WEAPON_SNSPISTOL',
    'WEAPON_CARBINERIFLE', 'WEAPON_SPECIALCARBINE', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_SMG',
    'WEAPON_ASSAULTSMG', 'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
    'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER'
}

AddEventHandler('fg:addon:playerReady', function()
    if hasInitialWeaponsBeenChecked then return end
    hasInitialWeaponsBeenChecked = true
    Citizen.Wait(1000)
    initialWeapons = {}
    local playerPed = PlayerPedId()
    for _, weaponName in ipairs(WeaponsToCheck) do
        local weaponHash = GetHashKey(weaponName) & 0xFFFFFFFF
        if HasPedGotWeapon(playerPed, weaponHash, false) then
            table.insert(initialWeapons, weaponName)
        end
    end
    if #initialWeapons > 0 then
        waitingForServer = true
        local deadline = GetGameTimer() + 60000
        while waitingForServer and GetGameTimer() < deadline do
            TriggerServerEvent('fg:addon:askInitialWeapons')
            Citizen.Wait(2000)
        end
        if waitingForServer then
            waitingForServer = false
            Warn('WeaponProtection: server did not confirm readiness; initial weapons were not registered')
        end
    end
end)

if Config.inventorySync then
    local getInventory, isLoaded, inventoryResource, frameworkResource
    local loadout = false
    local ESX, QBCore
    local vrpWeapons
    local syncGeneration = 0
    if GetResourceState('es_extended') == 'started' then
        frameworkResource = 'es_extended'
        ESX = exports.es_extended:getSharedObject()
        isLoaded = function() return ESX.IsPlayerLoaded() == true end
    elseif GetResourceState('qbx_core') == 'started' then
        frameworkResource = 'qbx_core'
        isLoaded = function() return LocalPlayer.state.isLoggedIn == true end
    elseif GetResourceState('qb-core') == 'started' then
        frameworkResource = 'qb-core'
        QBCore = exports['qb-core']:GetCoreObject()
        isLoaded = function() return LocalPlayer.state.isLoggedIn == true end
    elseif GetResourceState('vrp') == 'started' then
        frameworkResource = 'vrp'
        isLoaded = function() return vrpWeapons ~= nil end
    end

    local itemDefinitions
    if frameworkResource == 'vrp' then
        inventoryResource = 'vrp'
        loadout = true
        RegisterNetEvent('fg:addon:vrp:weaponState', function(ready, weapons)
            if source ~= 65535 or type(ready) ~= 'boolean' or type(weapons) ~= 'table' then return end
            if not ready or not vrpWeapons then syncGeneration = syncGeneration + 1 end
            vrpWeapons = nil
            if not ready then return end
            vrpWeapons = {}
            local now = GetGameTimer()
            for name, value in pairs(weapons) do
                if type(name) == 'string' then
                    if value == true then vrpWeapons[name] = true
                    elseif type(value) == 'number' and value > 0 then vrpWeapons[name] = now + value end
                end
            end
        end)
        getInventory = function()
            if not vrpWeapons then return end
            local items, now = {}, GetGameTimer()
            for name, deadline in pairs(vrpWeapons) do
                if deadline == true or now < deadline then
                    items[#items + 1] = { name = name }
                end
            end
            return items
        end
        TriggerServerEvent('fg:addon:vrp:askWeaponState')
    elseif isLoaded and GetResourceState('ox_inventory') == 'started' then
        inventoryResource = 'ox_inventory'
        itemDefinitions = exports.ox_inventory:Items()
        getInventory = function() return exports.ox_inventory:GetPlayerItems() end
    elseif QBCore and GetResourceState('qb-inventory') == 'started' then
        inventoryResource = 'qb-inventory'
        getInventory = function()
            local data = QBCore.Functions.GetPlayerData()
            return data and data.items
        end
    elseif ESX and ESX.GetConfig and ESX.GetConfig().CustomInventory == false then
        inventoryResource = 'es_extended'
        loadout = true
        getInventory = function()
            local data = ESX.GetPlayerData()
            return data and data.loadout
        end
    end

    if not getInventory then
        return false, 'inventorySync unavailable: no supported synced client inventory; existing weapon checks remain active'
    end

    local ignoredWeapons = {}
    for _, name in ipairs({ 'WEAPON_UNARMED', 'WEAPON_HANDCUFFS', 'WEAPON_GARBAGEBAG', 'OBJECT', 'WEAPON_HOSE', 'GADGET_PARACHUTE' }) do
        ignoredWeapons[GetHashKey(name) & 0xFFFFFFFF] = true
    end
    local itemHashes = {}
    Citizen.CreateThread(function()
        local readyAt, pendingPed, pendingWeapon, lastGeneration
        local reportedError = false
        while true do
            Citizen.Wait(200)
            if lastGeneration ~= syncGeneration then
                readyAt, pendingPed, pendingWeapon = nil, nil, nil
                lastGeneration = syncGeneration
            end
            local ok, inventory = pcall(function()
                if GetResourceState(frameworkResource) ~= 'started'
                    or GetResourceState(inventoryResource) ~= 'started' or not isLoaded() then return end
                return getInventory()
            end)
            if not ok or type(inventory) ~= 'table' then
                readyAt, pendingPed, pendingWeapon = nil, nil, nil
                if not ok and not reportedError then
                    Warn('inventorySync paused: ' .. tostring(inventory))
                    reportedError = true
                end
            else
                reportedError = false
                readyAt = readyAt or GetGameTimer() + 1000
                local ped = PlayerPedId()
                if ped == 0 or IsEntityDead(ped) or GetGameTimer() < readyAt then
                    pendingPed, pendingWeapon = nil, nil
                else
                    local weapon = GetSelectedPedWeapon(ped) & 0xFFFFFFFF
                    local present = ignoredWeapons[weapon] or GetWeapontypeGroup(weapon) == 0
                    if not present then
                        for _, item in pairs(inventory) do
                            if type(item) == 'table' and type(item.name) == 'string'
                                and (loadout or (tonumber(item.count or item.amount) or 0) > 0) then
                                local hash = itemHashes[item.name]
                                if not hash then
                                    local definition = itemDefinitions and itemDefinitions[item.name]
                                    hash = ((definition and definition.hash) or GetHashKey(item.name)) & 0xFFFFFFFF
                                    itemHashes[item.name] = hash
                                end
                                if hash == weapon then present = true break end
                            end
                        end
                    end
                    if present then
                        pendingPed, pendingWeapon = nil, nil
                    elseif pendingPed == ped and pendingWeapon == weapon then
                        RemoveWeaponFromPed(ped, weapon)
                        pendingPed, pendingWeapon = nil, nil
                    else
                        pendingPed, pendingWeapon = ped, weapon
                    end
                end
            end
        end
    end)
end

return true
