local coolDown = {}
local weaponHash = {}
do
    local w = {'WEAPON_SPECIALCARBINE_MK2','WEAPON_PUMPSHOTGUN','WEAPON_PISTOL_MK2','WEAPON_RAYMINIGUN','WEAPON_DAGGER','WEAPON_BOTTLE','WEAPON_EMPLAUNCHER','WEAPON_PISTOL','WEAPON_STONE_HATCHET','WEAPON_PISTOL50','WEAPON_KNIFE','WEAPON_PRECISIONRIFLE','WEAPON_SNSPISTOL','WEAPON_FLAREGUN','WEAPON_RAYPISTOL','WEAPON_GRENADE','WEAPON_NIGHTSTICK','WEAPON_FERTILIZERCAN','WEAPON_COMBATPISTOL','WEAPON_PISTOLXM3','WEAPON_PUMPSHOTGUN_MK2','WEAPON_SNIPERRIFLE','WEAPON_ACIDPACKAGE','WEAPON_HAZARDCAN','WEAPON_MACHETE','WEAPON_STUNGUN_MP','WEAPON_SPECIALCARBINE','WEAPON_FLASHLIGHT','WEAPON_CERAMICPISTOL','WEAPON_APPISTOL','WEAPON_REVOLVER','GADGET_PARACHUTE','WEAPON_PETROLCAN','WEAPON_BZGAS','WEAPON_CARBINERIFLE','WEAPON_COMBATMG_MK2','WEAPON_SWITCHBLADE','WEAPON_COMPACTLAUNCHER','WEAPON_BALL','WEAPON_SMG_MK2','WEAPON_PIPEBOMB','WEAPON_MOLOTOV','WEAPON_ASSAULTSHOTGUN','WEAPON_PROXMINE','WEAPON_HEAVYSNIPER','WEAPON_SAWNOFFSHOTGUN','WEAPON_MARKSMANPISTOL','WEAPON_ASSAULTSMG','WEAPON_RAILGUNXM3','WEAPON_SMOKEGRENADE','WEAPON_BULLPUPSHOTGUN','WEAPON_HAMMER','WEAPON_HOMINGLAUNCHER','WEAPON_RAILGUN','WEAPON_CARBINERIFLE_MK2','WEAPON_POOLCUE','WEAPON_GRENADELAUNCHER_SMOKE','WEAPON_COMBATSHOTGUN','WEAPON_MINIGUN','WEAPON_BATTLEAXE','WEAPON_GRENADELAUNCHER','WEAPON_ADVANCEDRIFLE','WEAPON_SMG','WEAPON_RPG','WEAPON_REVOLVER_MK2','WEAPON_HEAVYPISTOL','WEAPON_MARKSMANRIFLE_MK2','WEAPON_WRENCH','WEAPON_MARKSMANRIFLE','WEAPON_VINTAGEPISTOL','WEAPON_MACHINEPISTOL','WEAPON_DOUBLEACTION','WEAPON_HEAVYSNIPER_MK2','WEAPON_BULLPUPRIFLE','WEAPON_COMBATPDW','WEAPON_COMBATMG','WEAPON_MG','WEAPON_GUSENBERG','WEAPON_STUNGUN','WEAPON_MINISMG','WEAPON_HEAVYRIFLE','WEAPON_HEAVYSHOTGUN','WEAPON_COMPACTRIFLE','WEAPON_ASSAULTRIFLE','WEAPON_NAVYREVOLVER','WEAPON_FIREWORK','WEAPON_FLARE','WEAPON_ASSAULTRIFLE_MK2','WEAPON_SNSPISTOL_MK2','WEAPON_HATCHET','WEAPON_BULLPUPRIFLE_MK2','WEAPON_MICROSMG','WEAPON_CANDYCANE','WEAPON_AUTOSHOTGUN','WEAPON_TECPISTOL','WEAPON_BAT','WEAPON_DBSHOTGUN','WEAPON_MILITARYRIFLE','WEAPON_KNUCKLE','WEAPON_SNOWBALL','WEAPON_RAYCARBINE','WEAPON_TACTICALRIFLE','WEAPON_FIREEXTINGUISHER','WEAPON_GADGETPISTOL','WEAPON_STICKYBOMB','WEAPON_GOLFCLUB','WEAPON_CROWBAR','WEAPON_UNARMED','WEAPON_BATTLERIFLE','WEAPON_HACKINGDEVICE','WEAPON_METALDETECTOR','WEAPON_MUSKET','WEAPON_SNOWLAUNCHER','WEAPON_STUNROD','WEAPON_TEARGAS'}
    for i = 1, #w do weaponHash[GetHashKey(w[i]) & 0xFFFFFFFF] = w[i] end
end

---@param sender string
---@param ev table
---@param expectedHash number
---@param maxDist number
---@param reason string
local function CheckWeaponDistance(sender, ev, expectedHash, maxDist, reason)
    local w = tonumber(ev.weaponType)
    if not w or w ~= expectedHash then return end

    local attackerPed = GetPlayerPed(sender)
    if attackerPed == 0 then return end

    local attackerCoords = GetEntityCoords(attackerPed)
    local victims = ev.hitGlobalIds or { ev.hitGlobalId }

    for _, netId in ipairs(victims) do
        if netId and netId ~= 0 then
            local victimEnt = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(victimEnt) then
                local victimCoords = GetEntityCoords(victimEnt)
                if #(attackerCoords - victimCoords) > maxDist then
                    CancelEvent()
                    PunishPlayer(sender, Config.antiDistanceDamage.punishment, reason, Config.antiDistanceDamage.banMedia)
                end
            end
        end
    end
end


if Config.antiDistanceDamage.punch.enable then
    AddEventHandler('weaponDamageEvent', function(sender, ev)
        CheckWeaponDistance(sender, ev, 2725352035, Config.antiDistanceDamage.punch.maxDistance, 'Punch Distance Exceeded (1)')
    end)
end
if Config.antiDistanceDamage.stungun.enable then
    AddEventHandler('weaponDamageEvent', function(sender, ev)
        CheckWeaponDistance(sender, ev, 3452007600, Config.antiDistanceDamage.stungun.maxDistance, 'StunGun Distance Exceeded')
    end)
end
local initializationError
local details
local requiresInitialWeapons = false
if Config.antiGiveWeapon.enable then
    local frameworkDetected,HasWeapon

    local checkResource = function (res)
        local rs = GetResourceState(res)
        return rs == 'started' or rs == 'starting'
    end
    if not frameworkDetected and checkResource('es_extended') then
        frameworkDetected = 'ESX'
        local ESX = exports.es_extended:getSharedObject()
        local customInventory = ESX.GetConfig()?.CustomInventory
        HasWeapon = function(source, weaponName)
            local ok, result = pcall(function()
                local xPlayer = ESX.GetPlayerFromId(source)
                if not xPlayer then return nil end
                if not customInventory then return xPlayer.hasWeapon(weaponName) end
                local item = xPlayer.hasItem(weaponName)
                return item ~= nil and item ~= false and (tonumber(item.count) or 0) > 0
            end)
            if not ok then Error('Failed to check weapon through ESX!', result) return nil end
            return result
        end
    elseif not frameworkDetected and checkResource('qbx_core') then
        frameworkDetected = 'QBox'
        HasWeapon = function(source, weaponName)
            if not checkResource('ox_inventory') then Warn('Couldn\'t find ox_inventory to check weapon on QBox') return end
            local ok, err, hasItem = pcall(function () return '', exports.ox_inventory:GetItemCount(source, weaponName) >= 1 end)
            if not ok then Error('Failed to get item count from ox_inventory!') return end
            return hasItem
        end
    elseif not frameworkDetected and checkResource('qb-core') then
        frameworkDetected = 'QBCore'
        local QBCore = exports['qb-core']:GetCoreObject()
        HasWeapon = function(source, weaponName)
            local ok, err, hasItem = pcall(function()
                local player = QBCore.Functions.GetPlayer(source)
                if not player or not player.Functions or not player.Functions.GetItemByName then
                    return '', nil
                end
                local item = player.Functions.GetItemByName(weaponName)
                return '', item ~= nil and item ~= false
            end)
            if not ok then
                Warn('Couldn\'t get items from PlayerData, retrying with qb-inventory instead...')
                if not checkResource('qb-inventory') then Warn('Couldn\'t find qb-inventory to check weapon on QBCore') return end
                hasItem = exports['qb-inventory']:GetItemCount(source, weaponName) >= 1
            end
            return hasItem
        end
    elseif not frameworkDetected and checkResource('vrp') then
        local vrp, err = GetVRPBridge()
        frameworkDetected = vrp and vrp.version or 'vRP / unavailable'
        if not vrp then initializationError = err or 'vRP bridge unavailable; antiGiveWeapon is not operational' end
        if vrp and not vrp:EnableWeaponTracking() then
            initializationError = 'vRP equipped weapon tracking unavailable; inventory checks remain active'
        end
        HasWeapon = function(source, weaponName)
            if not vrp then return end
            local ok, authorized = pcall(vrp.HasWeapon, vrp, source, weaponName)
            if not ok then
                Error('Failed to check weapon through vRP: ' .. tostring(authorized))
                return
            end
            return authorized
        end
    else
        requiresInitialWeapons = true
        local PlayerWeapons = {}
        local isRegistered = {}
        AddEventHandler('playerJoining', function()
            PlayerWeapons[source] = {}
        end)
        AddEventHandler('playerDropped', function()
            PlayerWeapons[source] = nil
            isRegistered[source] = nil
        end)
        RegisterNetEvent('fg:addon:registerInitialWeapons', function(initialWeapons)
            if isRegistered[source] then
                PunishPlayer(source, Config.antiGiveWeapon.punishment, 'Tried to re-register his weapons', Config.antiGiveWeapon.banMedia)
                return
             end
            if not PlayerWeapons[source] then PlayerWeapons[source] = {} end
            for _, weaponName in ipairs(initialWeapons) do
                print(string.format('Registered starting weapon \'%s\' for player [^5%s^0] ^5%s^0', weaponName, source, GetPlayerName(source)))
                PlayerWeapons[source][weaponName] = true
            end
            isRegistered[source] = true
        end)
        exports('giveWeapon', function(targetId, weaponName)
            local targetId = tonumber(targetId)
            if not targetId then return end
            if not PlayerWeapons[targetId] then PlayerWeapons[targetId] = {} end
            PlayerWeapons[targetId][weaponName] = true
            local targetPedId = GetPlayerPed(targetId)
            GiveWeaponToPed(targetPedId, weaponName,0,false,false)
        end)
        exports('removeWeapon', function(targetId, weaponName)
            local targetId = tonumber(targetId)
            if not targetId then return end
            if PlayerWeapons[targetId] then
                PlayerWeapons[targetId][weaponName] = nil
            end
            local targetPedId = GetPlayerPed(targetId)
            RemoveWeaponFromPed(targetPedId,  weaponName)
        end)
        HasWeapon = function (source, weaponName)
            if PlayerWeapons[source] and PlayerWeapons[source][weaponName] then
                return true
            end
            return false
        end
    end
    details = frameworkDetected == 'QBox' and 'QBox | ox_inventory' or frameworkDetected or 'standalone'
    AddEventHandler('weaponDamageEvent', function(sender, ev)
        local sender = tonumber(sender)
        if not sender then return end
        local weaponName = weaponHash[ev.weaponType & 0xFFFFFFFF]
        if not weaponName or (weaponName and weaponName == 'WEAPON_UNARMED') or ev.damageType ~= 3 then return end
        if Config.antiGiveWeapon.relaxed then
            local now = GetGameTimer()
            if coolDown[sender] and now < coolDown[sender] then return end
            coolDown[sender] = now + 3000
        end
        local hasWeapon = HasWeapon(sender, weaponName)
        if hasWeapon == false then
            CancelEvent()
            if Config.antiGiveWeapon.punishment then
                PunishPlayer(sender, Config.antiGiveWeapon.punishment, ('Give Weapon Detected (Shot with: %s)'):format(weaponName), Config.antiGiveWeapon.banMedia)
            else
                local playerPedId = GetPlayerPed(sender)
                RemoveWeaponFromPed(playerPedId, ev.weaponType)
            end
        end
        Debug(('antiGiveWeapon: [^5%s^0] ^5%s^0 shot with %s that\'s %s'):format(sender or 0, GetPlayerName(sender) or 'unknown', weaponName, (hasWeapon == true and '^2present^0' or hasWeapon == false and '^1missing^0' or hasWeapon == nil and 'unavailable^0')..' in inventory'))
    end)
end

if Config.antiGiveWeapon.relaxed then
    AddEventHandler('playerDropped', function ()
        if coolDown[source] then
            coolDown[source] = nil
        end
    end)
end

local lastInitialWeaponsRequest = {}
RegisterNetEvent('fg:addon:askInitialWeapons', function()
    local src = source
    if src <= 0 or not GetPlayerName(src) then return end
    local now = GetGameTimer()
    if lastInitialWeaponsRequest[src] and now - lastInitialWeaponsRequest[src] < 1000 then return end
    lastInitialWeaponsRequest[src] = now
    TriggerClientEvent('fg:addon:initialWeaponsReady', src, requiresInitialWeapons)
end)
AddEventHandler('playerDropped', function()
    lastInitialWeaponsRequest[source] = nil
end)

if initializationError then return false, initializationError, details end
return true, nil, details
