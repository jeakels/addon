local resourceName = GetCurrentResourceName()
if GetResourceState('vrp') == 'missing' then return end
if resourceName == CurrentResourceName then
    local Adapter = {}
    Adapter.__index = Adapter
    local instance
    local initializing = false

    function Adapter:Call(method, ...)
        if self.legacy then
            return self.api[method]({ ... })
        end
        return self.api[method](...)
    end

    function Adapter:GetUserId(src)
        if self.remote then return self.remote.getUserId(src) end
        return self:Call('getUserId', src)
    end

    function Adapter:GetUserSource(userId)
        if self.remote then return self.remote.getUserSource(userId) end
        return self:Call('getUserSource', userId)
    end

    function Adapter:GetGroups(src)
        if self.remote then return self.remote.getGroups(src) end
        local userId = self:GetUserId(src)
        if userId == nil then return end
        local groups = self:Call('getUserGroups', userId)
        if type(groups) == 'table' then return groups end
    end
    function Adapter:GetInventoryItemAmount(src, itemId)
        if self.remote then return self.remote.getInventoryItemAmount(src, itemId) end
        local userId = self:GetUserId(src)
        if userId == nil then return end
        if self:Call('getItemDefinition', itemId) == nil then return end
        local amount = self:Call('getInventoryItemAmount', userId, itemId)
        if type(amount) == 'number' then return amount end
    end
    function Adapter:EnableWeaponTracking()
        if self.weaponTrackingAttempted then return self.weaponTracking end
        self.weaponTrackingAttempted = true
        local installed = false
        TriggerEvent('fg:addon:vrp:weapons', nil, nil, function(available)
            installed = available == true
        end)
        if not installed and self.remote then
            local ok, result = pcall(self.remote.enableWeaponTracking, resourceName)
            if not ok or result ~= true then
                Warn('vRP equipped weapon tracking unavailable: ' .. tostring(result))
            else
                installed = true
            end
        elseif not installed then
            local path = 'fxmanifest.lua'
            local manifest = LoadResourceFile('vrp', path)
            if not manifest then
                path = '__resource.lua'
                manifest = LoadResourceFile('vrp', path)
            end
            local hook = '@' .. resourceName .. '/server/vrp_bridge.lua'
            if manifest and not manifest:find(hook, 1, true) then
                local ok, saved = pcall(function()
                    local backup = path .. '.bak'
                    if not LoadResourceFile('vrp', backup) then
                        assert(SaveResourceFile('vrp', backup, manifest, -1), 'Cannot back up vRP manifest')
                    end
                    return SaveResourceFile('vrp', path, manifest .. '\n-- addon vRP weapon tracking\nserver_script '
                        .. string.format('%q', hook) .. '\n', -1)
                end)
                if not ok or not saved then
                    Warn('Cannot install vRP weapon hook: ' .. tostring(saved))
                    return false
                end
            elseif not manifest then
                Warn('Cannot install vRP weapon hook: vRP manifest not found')
                return false
            end
            Warn('vRP weapon hook prepared for the next full server start; equipped weapons are currently unverifiable')
        end
        self.weaponTracking = installed
        return installed
    end

    function Adapter:HasWeapon(src, weaponName)
        local amount = self:GetInventoryItemAmount(src, weaponName)
        if amount ~= nil and amount > 0 then return true end
        if not self.weaponTracking then
            if amount ~= nil then return false end
            return
        end
        local result, retiring
        TriggerEvent('fg:addon:vrp:weapons', src, weaponName, function(available, authorized, grace)
            if available and type(authorized) == 'boolean' then
                result, retiring = authorized, grace == true
            end
        end)
        if amount ~= nil and not retiring then return false end
        return result
    end

    function Adapter:SubscribePermissions()
        if self.subscribed then return end
        if self.remote then
            assert(self.remote.subscribe(resourceName), 'Unable to subscribe addon to vRP 2')
        else
            for _, eventName in ipairs({
                'vRP:playerSpawn', 'vRP:playerJoinGroup', 'vRP:playerLeaveGroup'
            }) do
                AddEventHandler(eventName, function(userId)
                    if GetInvokingResource() ~= 'vrp' then return end
                    local src = tonumber(self:GetUserSource(userId))
                    if not src then return end
                    Citizen.SetTimeout(0, function()
                        TriggerEvent(self.syncEvent, src)
                    end)
                end)
            end
        end
        self.subscribed = true
    end

    function GetVRPBridge()
        while initializing do Citizen.Wait(0) end
        if instance then return instance end
        initializing = true
        local ok, result = pcall(function()
            while GetResourceState('vrp') == 'starting' do Citizen.Wait(0) end
            assert(GetResourceState('vrp') == 'started', 'vRP is not started')
            if type(module) ~= 'function' then
                local utils = assert(LoadResourceFile('vrp', 'lib/utils.lua'), 'Missing vRP utilities')
                assert(load(utils, '@@vrp/lib/utils.lua', 't'))()
            end
            local Proxy = module('vrp', 'lib/Proxy')
            local adapter = setmetatable({
                api = Proxy.getInterface('vRP', resourceName .. ':vrpBridge:core'),
                syncEvent = resourceName .. ':vrp:syncPermissions',
                resource = 'vrp'
            }, Adapter)
            if LoadResourceFile('vrp', 'vRPShared.lua') ~= nil
                and LoadResourceFile('vrp', 'vRP.lua') ~= nil then
                adapter.api.loadScript(resourceName, 'server/vrp_bridge')
                adapter.remote = Proxy.getInterface(
                    'vRP.EXT.AddonBridge', resourceName .. ':vrpBridge:extension'
                )
                assert(adapter.remote.getVersion() == 2, 'Unable to load the vRP 2 bridge')
                adapter.version = 'vRP2'
            else
                local signature = debug.getinfo(adapter.api.getUserId, 'u')
                if signature.isvararg then
                    adapter.version = 'vRP1'
                elseif signature.nparams == 2 then
                    adapter.legacy = true
                    adapter.version = 'vRP0.5'
                else
                    error('Unsupported vRP')
                end
            end
            return adapter
        end)
        initializing = false
        if not ok then return nil, tostring(result) end
        instance = result
        return instance
    end
    local weaponConfig = GetConfig('weaponProtection')
    if weaponConfig.enable and weaponConfig.inventorySync then
        local requests = {}
        RegisterNetEvent('fg:addon:vrp:askWeaponState', function()
            local src = tonumber(source)
            if not src or src <= 0 or not GetPlayerName(src) or requests[src] then return end
            local request = {}
            requests[src] = request
            local adapter, err = GetVRPBridge()
            if requests[src] ~= request or not GetPlayerName(src) then return end
            if adapter and adapter:EnableWeaponTracking() then
                TriggerEvent('fg:addon:vrp:subscribeWeapons', src)
            else
                TriggerClientEvent('fg:addon:vrp:weaponState', src, false, {})
                if err then Warn('inventorySync vRP unavailable: ' .. tostring(err)) end
            end
        end)
        AddEventHandler('playerDropped', function()
            local src = tonumber(source)
            if src then requests[src] = nil end
        end)
    end
    return
end

local function enableWeaponTracking()
    if AddonVRPWeaponTracking then return true end

    local modern = type(vRP.EXT) == 'table' and vRP.Extension ~= nil
    local remote
    if modern then remote = vRP.EXT.PlayerState and vRP.EXT.PlayerState.remote
    else remote = vRPclient end
    if type(remote) ~= 'table' then return false end
    if type(remote.giveWeapons) ~= 'function' then return false end
    local signature = debug.getinfo(remote.giveWeapons, 'u')
    local legacy = not signature.isvararg and signature.nparams == 3
    if not legacy and not signature.isvararg then return false end

    local ok, Tunnel = pcall(module, 'vrp', 'lib/Tunnel')
    if not ok or type(Tunnel) ~= 'table' then Tunnel = {} end
    local function transitionDeadline(src)
        local delay = Tunnel.delays and Tunnel.delays[src]
        local queued = delay and ((delay[1] or 0) + (delay[2] or 0)) or 0
        local networkGrace = math.max(1000, GetPlayerPing(src) * 2)
        return GetGameTimer() + math.max(0, queued) + networkGrace
    end

    local states, subscribers, pendingSync = {}, {}, {}
    local function identity(src)
        if modern then
            local user = vRP.users_by_source[src]
            if user then return user, user.cid, user:isReady() end
        else
            local id = vRP.getUserId(src)
            if id ~= nil then return id, nil, true end
        end
    end

    local function publish(src)
        local subscriber = subscribers[src]
        if not subscriber then return end
        local state = states[src]
        local owner, character, ready = identity(src)
        local known = state ~= nil and owner ~= nil and state.owner == owner
            and state.character == character and state.ready == true
        local weapons = {}
        if known and ready then
            for name in pairs(state.items) do weapons[name] = true end
            local now = GetGameTimer()
            for name, deadline in pairs(state.retired) do
                if not weapons[name] and deadline > now then weapons[name] = deadline - now end
            end
        end
        TriggerClientEvent('fg:addon:vrp:weaponState', src, known and ready == true, weapons)
        pendingSync[src] = nil
        -- A full loadout may arrive before vRP marks the character as ready.
        -- Wait locally for that transition; the client makes no further requests.
        if known and not ready then
            local pending = {}
            pendingSync[src] = pending
            local function whenReady()
                if pendingSync[src] ~= pending or states[src] ~= state then return end
                local currentOwner, currentCharacter, currentReady = identity(src)
                if currentOwner ~= owner or currentCharacter ~= character then return end
                if currentReady then publish(src)
                else Citizen.SetTimeout(250, whenReady) end
            end
            Citizen.SetTimeout(250, whenReady)
        end
    end

    AddEventHandler('fg:addon:vrp:subscribeWeapons', function(src)
        local subscriber = GetInvokingResource()
        src = tonumber(src)
        if not subscriber or subscriber == 'vrp' or not src or not GetPlayerName(src) then return end
        subscribers[src] = subscriber
        publish(src)
    end)

    local function reset(src, ready)
        src = tonumber(src)
        if not src then return end
        local owner, character = identity(src)
        if owner == nil then states[src] = nil publish(src) return end
        states[src] = { owner = owner, character = character, ready = ready, items = {}, retired = {} }
        publish(src)
    end

    local function record(src, weapons, replace)
        src = tonumber(src)
        if not src or type(weapons) ~= 'table' then return end
        if src == -1 then
            for _, player in ipairs(GetPlayers()) do record(player, weapons, replace) end
            return
        end
        local owner, character = identity(src)
        if owner == nil then return end
        local state = states[src]
        if not state or state.owner ~= owner or state.character ~= character then
            reset(src, false)
            state = states[src]
        end
        if replace then
            local now = GetGameTimer()
            for weaponName, deadline in pairs(state.retired) do
                if deadline <= now then state.retired[weaponName] = nil end
            end
            local deadline = transitionDeadline(src)
            for weaponName in pairs(state.items) do
                state.retired[weaponName] = deadline
            end
            state.items = {}
            state.ready = true
        end
        for weaponName, weapon in pairs(weapons) do
            if type(weaponName) == 'string' and type(weapon) == 'table' then
                state.items[weaponName:upper()] = true
                state.retired[weaponName:upper()] = nil
            end
        end
        publish(src)
    end

    local function wrap(method, replace)
        local original = remote[method]
        if type(original) ~= 'function' then return end
        remote[method] = function(src, ...)
            local arguments = table.pack(...)
            local weapons, clear
            if legacy then
                local payload = arguments[1]
                if type(payload) == 'table' then weapons, clear = payload[1], payload[2] end
            else
                weapons, clear = arguments[1], arguments[2]
            end
            record(src, weapons, replace or clear)
            local pending = states[tonumber(src)]
            local result = table.pack(pcall(original, src, table.unpack(arguments, 1, arguments.n)))
            if not result[1] then
                if tonumber(src) == -1 then
                    for _, player in ipairs(GetPlayers()) do
                        local target = tonumber(player)
                        states[target] = nil
                        publish(target)
                    end
                elseif pending and states[tonumber(src)] == pending then
                    states[tonumber(src)] = nil
                    publish(tonumber(src))
                end
                error(result[2], 0)
            end
            return table.unpack(result, 2, result.n)
        end
    end
    wrap('giveWeapons', false)
    wrap('replaceWeapons', true)
    if not legacy then
        wrap('_giveWeapons', false)
        wrap('_replaceWeapons', true)
    end

    AddEventHandler('fg:addon:vrp:weapons', function(src, weaponName, reply)
        local callable = type(reply) == 'function'
            or (type(reply) == 'table' and rawget(reply, '__cfx_functionReference') ~= nil)
        if not callable or not GetInvokingResource() then return end
        if src == nil then reply(true) return end
        if type(weaponName) ~= 'string' then reply(true, nil) return end
        weaponName = weaponName:upper()
        src = tonumber(src)
        local state = states[src]
        local owner, character, ready = identity(src)
        if not state or owner == nil or state.owner ~= owner or state.character ~= character or not ready then
            reply(true, nil)
        elseif state.items[weaponName] then
            reply(true, true)
        elseif state.retired[weaponName] and GetGameTimer() < state.retired[weaponName] then
            reply(true, true, true)
        elseif state.ready then
            state.retired[weaponName] = nil
            reply(true, false)
        else
            reply(true, nil)
        end
    end)

    if modern then
        local Lifecycle = class('AddonWeaponLifecycle', vRP.Extension)
        Lifecycle.event = {}
        function Lifecycle.event:characterLoad(user) reset(user.source, false) end
        function Lifecycle.event:characterUnload(user)
            states[user.source] = nil
            publish(user.source)
        end
        function Lifecycle.event:playerLeave(user)
            states[user.source] = nil
            publish(user.source)
            subscribers[user.source], pendingSync[user.source] = nil, nil
        end
        function Lifecycle.event:playerDeath(user) record(user.source, {}, true) end
        vRP:registerExtension(Lifecycle)
    else
        AddEventHandler('vRP:playerSpawn', function(_, src)
            if GetInvokingResource() ~= 'vrp' then return end
            local owner, character = identity(tonumber(src))
            local state = states[tonumber(src)]
            if not state or state.owner ~= owner or state.character ~= character then
                reset(src, true)
            end
        end)
        AddEventHandler('vRP:playerDied', function() record(source, {}, true) end)
        AddEventHandler('vRP:playerLeave', function(_, src)
            if GetInvokingResource() == 'vrp' then
                src = tonumber(src)
                states[src] = nil
                publish(src)
                subscribers[src], pendingSync[src] = nil, nil
            end
        end)
    end
    AddEventHandler('playerDropped', function()
        local src = tonumber(source)
        if not src then return end
        states[src], subscribers[src], pendingSync[src] = nil, nil, nil
    end)
    AddonVRPWeaponTracking = true
    return true
end

if type(vRP.EXT) ~= 'table' or not vRP.Extension then
    return enableWeaponTracking()
end

if vRP.EXT.AddonBridge then return AddonVRPWeaponTracking == true end
local Bridge = class('AddonBridge', vRP.Extension)

function Bridge:__construct()
    vRP.Extension.__construct(self)
    self.subscribers = {}
    self.pending = {}
end

Bridge.proxy = {}

function Bridge.proxy:getVersion()
    return 2
end

function Bridge.proxy:enableWeaponTracking(addonResource)
    if type(addonResource) ~= 'string' or GetInvokingResource() ~= addonResource then return false end
    local ok, result = pcall(enableWeaponTracking)
    return ok and result == true
end

function Bridge.proxy:subscribe(addonResource)
    if type(addonResource) ~= 'string' or GetInvokingResource() ~= addonResource then
        return false
    end
    self.subscribers[addonResource] = true
    return true
end

function Bridge.proxy:getUserId(src)
    local user = vRP.users_by_source[tonumber(src)]
    if user then return user.id end
end

function Bridge.proxy:getUserSource(userId)
    local user = vRP.users[tonumber(userId)]
    if user then return user.source end
end

function Bridge.proxy:getGroups(src)
    local user = vRP.users_by_source[tonumber(src)]
    if user and user:isReady() and user.cdata and user.cdata.groups
        and type(user.getGroups) == 'function' then
        return user:getGroups()
    end
end

function Bridge.proxy:getInventoryItemAmount(src, itemId)
    local user = vRP.users_by_source[tonumber(src)]
    local inventory = vRP.EXT.Inventory
    if not user or not user:isReady() or not user.cdata or not user.cdata.inventory
        or not inventory or type(user.getItemAmount) ~= 'function' then return end
    if not inventory:computeItem(itemId) then return end
    local amount = user:getItemAmount(itemId)
    if type(amount) == 'number' then return amount end
end

function Bridge:Notify(src, clear)
    for addonResource in pairs(self.subscribers) do
        local state = GetResourceState(addonResource)
        if state == 'started' or state == 'starting' then
            TriggerEvent(addonResource .. ':vrp:syncPermissions', src, clear)
        elseif state == 'missing' then
            self.subscribers[addonResource] = nil
        end
    end
end

Bridge.event = {}

function Bridge.event:playerSpawn(user)
    local src = user.source
    if not src then return end
    local pending = { user = user, character = user.cid }
    self.pending[src] = pending
    local attempts = 0
    local function notifyWhenReady()
        if self.pending[src] ~= pending then return end
        if vRP.users_by_source[src] ~= user or user.cid ~= pending.character then
            self.pending[src] = nil
            return
        end
        if user:isReady() then
            self.pending[src] = nil
            self:Notify(src, false)
        else
            attempts = attempts + 1
            Citizen.SetTimeout(attempts < 100 and 100 or 1000, notifyWhenReady)
        end
    end
    Citizen.SetTimeout(0, notifyWhenReady)
end

Bridge.event.characterLoad = Bridge.event.playerSpawn
Bridge.event.playerJoinGroup = Bridge.event.playerSpawn
Bridge.event.playerLeaveGroup = Bridge.event.playerSpawn

function Bridge.event:characterUnload(user)
    self.pending[user.source] = nil
    self:Notify(user.source, true)
end

Bridge.event.playerLeave = Bridge.event.characterUnload
vRP:registerExtension(Bridge)
