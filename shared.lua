CurrentResourceName = GetCurrentResourceName()
Resources = {}
local isServer = IsDuplicityVersion()
local Config

function GetConfig(section)
    while not Config do Citizen.Wait(0) end
    if section then return Config[section] end
    return Config
end

if isServer then
    local data = LoadResourceFile(CurrentResourceName, 'config.lua')
    Config = assert(load(data))()

    local clientConfig = {
        debug = Config.debug,
        heartbeat = { enable = Config.heartbeat.enable },
        antiFiveguardStopper = {
            enable = Config.antiFiveguardStopper.enable,
            checkInterval = Config.antiFiveguardStopper.checkInterval
        },
        easyBypass = {
            enable = Config.easyBypass.enable,
            onClientTrigger = Config.easyBypass.onClientTrigger
        },
        weaponProtection = {
            enable = Config.weaponProtection.enable,
            inventorySync = Config.weaponProtection.inventorySync
        },
        vehicleProtection = {
            enable = Config.vehicleProtection.enable,
            preventUnNetworkedEntity = Config.vehicleProtection.preventUnNetworkedEntity,
            preventInvalidOwner = Config.vehicleProtection.preventInvalidOwner,
            preventNilResource = Config.vehicleProtection.preventNilResource,
            maxVehicleCheckDistance = Config.vehicleProtection.maxVehicleCheckDistance,
            checkInterval = Config.vehicleProtection.checkInterval,
            preventSafeSpawn = {
                enable = Config.vehicleProtection.preventSafeSpawn.enable,
                whitelistedCoords = Config.vehicleProtection.preventSafeSpawn.whitelistedCoords
            }
        }
    }
    local lastRequest = {}
    RegisterNetEvent('fg:addon:askConfig', function()
        local player = source
        if player <= 0 then return end
        local now = GetGameTimer()
        if lastRequest[player] and now - lastRequest[player] < 1000 then return end
        lastRequest[player] = now
        TriggerClientEvent('fg:addon:getConfig', player, clientConfig)
    end)
    AddEventHandler('playerDropped', function()
        lastRequest[source] = nil
    end)
    if Config.debug then
        RegisterNetEvent('fg:addon:debug', function(...)
            print('[^5DEBUG-CLIENT-'..source..'^0]', ...)
        end)
    end
else
    local p=promise.new()
    RegisterNetEvent('fg:addon:getConfig', function(data)
        if source ~= 65535 then return end
        if Config or type(data) ~= 'table' then return end
        p:resolve(data)
    end)
    TriggerServerEvent('fg:addon:askConfig')
    Config = Citizen.Await(p)
end

---@param ... any
function Debug(...)
    if not GetConfig().debug then return end
    if isServer then
        print('[^5DEBUG-SERVER^0]', ...)
    else
        print('[^5DEBUG-CLIENT^0]', ...)
        TriggerServerEvent('fg:addon:debug', ...)
    end
end
---@param ... any
function Error(...)
    print('[^1ERROR^0]^1', ..., '^0')
end
---@param ... any
function Warn(...)
    print('[^3WARN^0]', ..., '^0')
end
---@param ... any
function Info(...)
    print('[^2INFO^0]', ..., '^0')
end

local pros = promise.new()
Citizen.CreateThread(function()
    local attempts = 0
    local found = nil
    while attempts < 5 and not found do
        local resources = GetNumResources()
        for i = 0, resources - 1 do
            local resource = GetResourceByFindIndex(i)
            Resources[resource] = true
            local files = GetNumResourceMetadata(resource, 'ac')
            for j = 0, files - 1 do
                local x = GetResourceMetadata(resource, 'ac', j)
                if x:find('fg') then
                    found = resource
                end
            end
        end
        if not found then
            attempts = attempts + 1
            Citizen.Wait(0)
        end
    end
    if found then
        pros:resolve(found)
    else
        pros:reject('Fiveguard not found! Get it on https://discord.gg/gpXNsFe2PE (Fiveguard Italy)')
    end
end)

do
    local success, result = pcall(function()
        return Citizen.Await(pros)
    end)
    if success then
        Fiveguard = result
    else
        Error(result)
    end
end
