local data = LoadResourceFile(CurrentResourceName, 'config.lua')
local Config = assert(load(data))()?.WeaponProtection
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end
local coolDown = {}

local weaponHash = {}
do
    local w = {'WEAPON_SPECIALCARBINE_MK2','WEAPON_PUMPSHOTGUN','WEAPON_PISTOL_MK2','WEAPON_RAYMINIGUN','WEAPON_DAGGER','WEAPON_BOTTLE','WEAPON_EMPLAUNCHER','WEAPON_PISTOL','WEAPON_STONE_HATCHET','WEAPON_PISTOL50','WEAPON_KNIFE','WEAPON_PRECISIONRIFLE','WEAPON_SNSPISTOL','WEAPON_FLAREGUN','WEAPON_RAYPISTOL','WEAPON_GRENADE','WEAPON_NIGHTSTICK','WEAPON_FERTILIZERCAN','WEAPON_COMBATPISTOL','WEAPON_PISTOLXM3','WEAPON_PUMPSHOTGUN_MK2','WEAPON_SNIPERRIFLE','WEAPON_ACIDPACKAGE','WEAPON_HAZARDCAN','WEAPON_MACHETE','WEAPON_STUNGUN_MP','WEAPON_SPECIALCARBINE','WEAPON_FLASHLIGHT','WEAPON_CERAMICPISTOL','WEAPON_APPISTOL','WEAPON_REVOLVER','GADGET_PARACHUTE','WEAPON_PETROLCAN','WEAPON_BZGAS','WEAPON_CARBINERIFLE','WEAPON_COMBATMG_MK2','WEAPON_SWITCHBLADE','WEAPON_COMPACTLAUNCHER','WEAPON_BALL','WEAPON_SMG_MK2','WEAPON_PIPEBOMB','WEAPON_MOLOTOV','WEAPON_ASSAULTSHOTGUN','WEAPON_PROXMINE','WEAPON_HEAVYSNIPER','WEAPON_SAWNOFFSHOTGUN','WEAPON_MARKSMANPISTOL','WEAPON_ASSAULTSMG','WEAPON_RAILGUNXM3','WEAPON_SMOKEGRENADE','WEAPON_BULLPUPSHOTGUN','WEAPON_HAMMER','WEAPON_HOMINGLAUNCHER','WEAPON_RAILGUN','WEAPON_CARBINERIFLE_MK2','WEAPON_POOLCUE','WEAPON_GRENADELAUNCHER_SMOKE','WEAPON_COMBATSHOTGUN','WEAPON_MINIGUN','WEAPON_BATTLEAXE','WEAPON_GRENADELAUNCHER','WEAPON_ADVANCEDRIFLE','WEAPON_SMG','WEAPON_RPG','WEAPON_REVOLVER_MK2','WEAPON_HEAVYPISTOL','WEAPON_MARKSMANRIFLE_MK2','WEAPON_WRENCH','WEAPON_MARKSMANRIFLE','WEAPON_VINTAGEPISTOL','WEAPON_MACHINEPISTOL','WEAPON_DOUBLEACTION','WEAPON_HEAVYSNIPER_MK2','WEAPON_BULLPUPRIFLE','WEAPON_COMBATPDW','WEAPON_COMBATMG','WEAPON_MG','WEAPON_GUSENBERG','WEAPON_STUNGUN','WEAPON_MINISMG','WEAPON_HEAVYRIFLE','WEAPON_HEAVYSHOTGUN','WEAPON_COMPACTRIFLE','WEAPON_ASSAULTRIFLE','WEAPON_NAVYREVOLVER','WEAPON_FIREWORK','WEAPON_FLARE','WEAPON_ASSAULTRIFLE_MK2','WEAPON_SNSPISTOL_MK2','WEAPON_HATCHET','WEAPON_BULLPUPRIFLE_MK2','WEAPON_MICROSMG','WEAPON_CANDYCANE','WEAPON_AUTOSHOTGUN','WEAPON_TECPISTOL','WEAPON_BAT','WEAPON_DBSHOTGUN','WEAPON_MILITARYRIFLE','WEAPON_KNUCKLE','WEAPON_SNOWBALL','WEAPON_RAYCARBINE','WEAPON_TACTICALRIFLE','WEAPON_FIREEXTINGUISHER','WEAPON_GADGETPISTOL','WEAPON_STICKYBOMB','WEAPON_GOLFCLUB','WEAPON_CROWBAR','WEAPON_UNARMED','WEAPON_BATTLERIFLE','WEAPON_HACKINGDEVICE','WEAPON_METALDETECTOR','WEAPON_MUSKET','WEAPON_SNOWLAUNCHER','WEAPON_STUNROD','WEAPON_TEARGAS'}
    for i = 1, #w do weaponHash[GetHashKey(w[i])] = w[i] end
end

---@param sender string
---@param ev table
---@param expectedHash number
---@param maxDist number
---@param reason string
---@param extraCond? fun(ev: table): boolean
local function CheckWeaponDistance(sender, ev, expectedHash, maxDist, reason, extraCond)
    local w = tonumber(ev.weaponType)
    if not w or w ~= expectedHash then return end
    if extraCond and not extraCond(ev) then return end

    local attackerPed = GetPlayerPed(sender)
    if attackerPed == 0 then return end

    local attackerCoords = GetEntityCoords(attackerPed)
    local victims = ev.hitGlobalIds or { ev.hitGlobalId }

    for _, netId in ipairs(victims) do
        if netId and netId ~= 0 then
            local victimEnt = NetworkGetEntityFromNetworkId(netId)
            local victimCoords = GetEntityCoords(victimEnt)
            if DoesEntityExist(victimEnt) then
                if #(attackerCoords - victimCoords) > maxDist then
                    CancelEvent()
                    PunishPlayer(sender, Config.AntiDistanceDamage.punishment, reason, Config.AntiDistanceDamage.banMedia)
                end
            end
        end
    end
end


if Config.AntiDistanceDamage.punch.enable then
    AddEventHandler('weaponDamageEvent', function(sender, ev)
        CheckWeaponDistance(sender, ev, 2725352035, Config.AntiDistanceDamage.punch.maxDistance, 'Punch Distance Exceeded (1)')
        CheckWeaponDistance(sender, ev, 2725352035, Config.AntiDistanceDamage.punch.maxDistance, 'Punch Distance Exceeded (2)', function(r)
            return r.weaponDamage == 0
        end)
    end)
end
if Config.AntiDistanceDamage.stungun.enable then
    AddEventHandler('weaponDamageEvent', function(sender, ev)
        CheckWeaponDistance(sender, ev, 3452007600, Config.AntiDistanceDamage.stungun.maxDistance, 'StunGun Distance Exceeded')
    end)
end
if Config.AntiGiveWeapon.enable then
    local frameworkDetected,HasWeapon

    local checkResource = function (res)
        local rs = GetResourceState(res)
        return rs == 'started' or rs == 'starting'
    end
    if not frameworkDetected and checkResource('es_extended') then
        frameworkDetected = 'ESX'
        local ESX = exports.es_extended:getSharedObject()
        HasWeapon = function(source, weaponName)
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then
                Warn(('Player [^5%s^0] ^5%s^0 is not loaded'):format(source, GetPlayerName(source)))
                return
            end
            return xPlayer.hasItem(weaponName).count >= 1
        end
    elseif not frameworkDetected and checkResource('qbx_core') then
        frameworkDetected = 'QBox'
        HasWeapon = function(source, weaponName)
            local Player = exports.qbx_core:GetPlayer(source)
            if not Player then Warn(('Player [^5%s^0] ^5%s^0 is not loaded'):format(source, GetPlayerName(source))) return end
            local ok, hasItem = pcall(function () return Player.PlayerData?.items?[weaponName]?.amount >= 1 end)
            if not ok then
                Warn('Couldn\'t get items from GetPlayer, retrying with ox_inventory instead...')
                if not checkResource('ox_inventory') then Warn('Couldn\'t find ox_inventory to check weapon on QBox') return end
                hasItem = exports.ox_inventory:GetItemCount(source, weaponName) >= 1
            end
            return hasItem
        end
    elseif not frameworkDetected and checkResource('qb-core') then
        frameworkDetected = 'QBCore'
        local QBCore = exports['qb-core']:GetCoreObject()
        HasWeapon = function(source, weaponName)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then
                Warn(('Player [^5%s^0] ^5%s^0 is not loaded'):format(source, GetPlayerName(source)))
                return
            end
            return Player.Functions.GetItemByName(weaponName) and true or false
        end
    elseif not frameworkDetected and checkResource('vrp') then
        frameworkDetected = 'vRP'
        local fileCode = LoadResourceFile('vrp','lib/utils.lua')
        assert(load(fileCode,'@@vrp/lib/utils.lua','t'))()
        ---@diagnostic disable-next-line: deprecated
        local Proxy = module('vrp', 'lib/Proxy')
        ---@diagnostic disable-next-line: undefined-field, need-check-nil, lowercase-global
        local vRP = Proxy.getInterface('vRP')
        HasWeapon = function(source, weaponName) --todo: check if work on most vrp versions
            local user_id = vRP.getUserId(source)
            if user_id then return vRP.getInventoryItemAmount(user_id, weaponName) > 0 end
            Error(('Incompatible vRP version, disable AntiGiveWeapon in addon\'s config'):format(source))
        end
    else
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
                PunishPlayer(source, Config.AntiGiveWeapon.punishment, 'Tried to re-register his weapons', Config.AntiGiveWeapon.banMedia)
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
            if not PlayerWeapons[targetId] then PlayerWeapons[targetId] = {} end
            PlayerWeapons[targetId][weaponName] = true
            local targetPedId = GetPlayerPed(targetId)
            GiveWeaponToPed(targetPedId, weaponName,0,false,false)
        end)
        exports('removeWeapon', function(targetId, weaponName)
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
    if frameworkDetected then Debug(('Framework For Weapon Detection: ^3%s^0'):format(frameworkDetected)) end
    AddEventHandler('weaponDamageEvent', function(sender, ev)
        local weaponName = weaponHash[ev.weaponType]
        if not weaponName or (weaponName and weaponName == 'WEAPON_UNARMED') or ev.damageType ~= 3 then return end
        if Config.AntiGiveWeapon.relaxed then
            local now = GetGameTimer()
            if coolDown[sender] and now < coolDown[sender] then return end
            coolDown[sender] = now + 3000
        end
        local hasWeapon = HasWeapon(sender, weaponName)
        Debug(('AntiGiveWeapon: [^5%s^0] ^5%s^0 shot with %s that\'s %s'):format(sender or 0, GetPlayerName(sender) or 'unknown', weaponName, (hasWeapon == true and '^2present^0 ' or '^1missing^0 ')..'in inventory'))
        if hasWeapon == false then
            CancelEvent()
            if Config.AntiGiveWeapon.punishment then
                PunishPlayer(sender, Config.AntiGiveWeapon.punishment, ('Give Weapon Detected (Shot with: %s)'):format(weaponName), Config.AntiGiveWeapon.banMedia)
            else
                local playerPedId = GetPlayerPed(sender)
                RemoveWeaponFromPed(playerPedId, ev.weaponType)
            end
        end
    end)
end

if Config.AntiGiveWeaponToPed.enable then
    AddEventHandler('giveWeaponEvent',function (sender,ddata)
        Debug(json.encode(ddata,{indent=true}))
        if not IsPedAPlayer(NetworkGetEntityFromNetworkId(ddata.pedId)) or not weaponHash[ddata.weaponType] then return end
        PunishPlayer(sender,Config.AntiGiveWeaponToPed.punishment,('Tried to Add %s to player %s'):format(weaponHash[ddata.weaponType],NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(ddata.pedId))),false)
        CancelEvent()
    end)
end

if Config.AntiRemoveWeaponFromPed.enable then
    AddEventHandler('removeWeaponEvent',function (sender,ddata)
        Debug(json.encode(ddata,{indent=true}))
        if not IsPedAPlayer(NetworkGetEntityFromNetworkId(ddata.pedId)) or not weaponHash[ddata.weaponType] then return end
        PunishPlayer(sender,Config.AntiRemoveWeaponFromPed.punishment,('Tried to remove %s from player %s'):format(weaponHash[ddata.weaponType],NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(ddata.pedId))),false)
        CancelEvent()
    end)
    AddEventHandler('removeAllWeaponsEvent',function (sender,ddata)
        Debug(json.encode(ddata,{indent=true}))
        if not IsPedAPlayer(NetworkGetEntityFromNetworkId(ddata.pedId)) or not weaponHash[ddata.weaponType] then return end
        PunishPlayer(sender,Config.AntiRemoveWeaponFromPed.punishment,('Tried to remove all weapons from player %s'):format(weaponHash[ddata.weaponType],NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(ddata.pedId))),false)
        CancelEvent()
    end)
end

if Config.AntiGiveWeapon.relaxed then
    AddEventHandler('playerDropped', function ()
        if coolDown[source] then
            coolDown[source] = nil
        end
    end)
end
