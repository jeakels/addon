local enabledModes = (Config.DiscordPermissions.enable and 1 or 0)
    + (Config.AcePermissions.enable and 1 or 0)
    + (Config.FrameworkPermissions.enable and 1 or 0)
    + (Config.txAdminPermissions.enable and 1 or 0)
if enabledModes > 0 then
    local PermsTable = {}
    if enabledModes > 1 then
        Config.DiscordPermissions.enable = false
        Config.AcePermissions.enable = false
        Config.FrameworkPermissions.enable = true
        Config.txAdminPermissions.enable = false
        Warn('Do not use multple permission system at same time!^0\nPermissions configored to use txAdmin')
    end
    ---@param source number|string
    ---@param group string
    ---@param enable boolean
    function SetPermission(source, group, enable)
        Debug('[SetPermission]', source, group, enable, PermsTable[source]?.group)
        if not group or type(group) ~= 'string' then return Error('Group not valid or not exist') end
        if group == 'user' then return Debug(('Ignored player: [^5%s^0] ^5%s^0 since he\'s: ^5%s^0'):format(source, GetPlayerName(source), group)) end
        if source ~= 0 then
            if enable then
                if PermsTable[source] and PermsTable[source]?.group ~= group then
                    local oldGroup = PermsTable[source]?.group
                    ExecuteCommand(('remove_principal player.%s fg.%s'):format(source, oldGroup))
                    PermsTable[source] = nil
                    ExecuteCommand(('add_principal player.%s fg.%s'):format(source, group))
                    PermsTable[source] = { group = group }
                    exports[Fiveguard]:RefreshPlayerPermissions(source)
                    return Info(('Permissions for player: [^5%s^0] ^5%s^0 was registered with the group ^5%s^0, overriding permissions to ^5%s^0'):format(source, GetPlayerName(source), oldGroup, group))
                elseif PermsTable[source] and PermsTable[source]?.group == group then
                    return Warn(('Player: [^5%s^0] ^5%s^0 already have ^5%s^0 group permissions, ignored'):format(source, GetPlayerName(source), group))
                else
                    ExecuteCommand(('add_principal player.%s fg.%s'):format(source, group))
                    PermsTable[source] = { group = group }
                    exports[Fiveguard]:RefreshPlayerPermissions(source)
                    return Info(('Permissions ^2granted^0 to player: [^5%s^0] ^5%s^0 Group: ^5%s^0'):format(source, GetPlayerName(source), group))
                end
            else
                ExecuteCommand(('remove_principal player.%s fg.%s'):format(source, group))
                if PermsTable[source] and PermsTable[source].group == group then
                    PermsTable[source] = nil
                end
                exports[Fiveguard]:RefreshPlayerPermissions(source)
                return Debug(('Permissions ^1removed^0 from player: [^5%s^0] ^5%s^0 Group: ^5%s^0'):format(source, GetPlayerName(source), group))
            end
        else
            return Error(('Invalid player: [^5%s^0] ^5%s^0'):format(source, GetPlayerName(source)))
        end
    end
    AddEventHandler('onResourceStop', function(res)
        if CurrentResourceName ~= res then return end
        for source, v in pairs(PermsTable) do
            if PermsTable[source]?.group then
                ExecuteCommand(('remove_principal player.%s fg.%s'):format(source, v.group))
                PermsTable[source] = nil
            end
        end
    end)
else
    return false, 'No permission system selected'
end

if Config.DiscordPermissions.enable then
    local function snowflake(value)
        return type(value) == 'string' and #value <= 20 and value:match('^%d+$') ~= nil
    end
    local function array(value)
        if type(value) ~= 'table' then return false end
        local count = 0
        for index in pairs(value) do
            if type(index) ~= 'number' or index % 1 ~= 0 or index < 1 or index > #value then return false end
            count = count + 1
        end
        return count == #value
    end
    local automatic = Config.DiscordPermissions.guildId == nil or Config.DiscordPermissions.guildId == '' or Config.DiscordPermissions.guildId == 'auto'
    local roleSettings = Config.DiscordPermissions.roles == nil and {} or Config.DiscordPermissions.roles
    local userSettings = Config.DiscordPermissions.users == nil and {} or Config.DiscordPermissions.users
    if type(roleSettings) ~= 'table' or type(userSettings) ~= 'table' then
        return false, 'Discord permissions: roles and users must be tables'
    end
    local function validPermissions(permissions)
        if not array(permissions) then return false end
        for _, permission in ipairs(permissions) do
            if type(permission) ~= 'string' or not permission:match('^[%w_.*:%-]+$') then
                return false
            end
        end
        return true
    end
    local roles, users, grants = {}, {}, {}
    if not array(roleSettings) then return false, 'Discord permissions: roles must be a dense ordered array of single-ID tables' end
    local seenRoles = {}
    for _, entry in ipairs(roleSettings) do
        if type(entry) ~= 'table' then return false, 'Discord permissions: each role entry must contain exactly one ID' end
        local id, permissions = next(entry)
        if not snowflake(id) or next(entry, id) ~= nil or seenRoles[id] or not validPermissions(permissions) then
            return false, 'Discord permissions: each role entry requires one unique ID mapped to a valid permissions array'
        end
        seenRoles[id] = true
        local role = { id = id, group = 'discord_role_' .. id, permissions = permissions }
        roles[#roles + 1] = role
        grants[#grants + 1] = role
    end
    for id, permissions in pairs(userSettings) do
        if not snowflake(id) or not validPermissions(permissions) then
            return false, 'Discord permissions: each user ID must map to a valid permissions array'
        end
        local user = { group = 'discord_user_' .. id, permissions = permissions }
        users[id] = user
        grants[#grants + 1] = user
    end
    if #grants == 0 then return false, 'Discord permissions: configure at least one role or user' end
    local initializationError
    local token
    if #roles > 0 then
        if type(Config.DiscordPermissions.botToken) == 'string' then
            token = Config.DiscordPermissions.botToken:match('^%s*(.-)%s*$'):gsub('^Bot%s+', '')
        end
        if (not automatic and not snowflake(Config.DiscordPermissions.guildId)) or not token
            or token == '' or token:find('[%s%c]') then
            initializationError = 'Discord permissions: configure a valid botToken and guildId; role permissions disabled'
            roles, grants = {}, {}
            for _, user in pairs(users) do grants[#grants + 1] = user end
            if #grants == 0 then return false, initializationError end
        end
    end

    local running, busy, waiting = true, false, false
    local guildId, blockedUntil = nil, 0
    local sessions, queue, createdAces = {}, {}, {}
    local guildInitialization = #roles > 0 and promise.new() or nil
    local guildCompleted = false
    if guildInitialization then
        Citizen.SetTimeout(45000, function()
            if guildCompleted then return end
            guildCompleted = true
            guildInitialization:resolve({ ok = false, reason = 'Guild lookup timed out; users remain available' })
        end)
    end

    for _, grant in ipairs(grants) do
        for _, permission in ipairs(grant.permissions) do
            if not IsPrincipalAceAllowed('fg.' .. grant.group, permission) then
                ExecuteCommand(('add_ace fg.%s %s allow'):format(grant.group, permission))
                createdAces[#createdAces + 1] = { grant.group, permission }
            end
        end
    end

    local processQueue
    processQueue = function()
        if not running or busy or waiting or #queue == 0 then return end
        local delay = blockedUntil - GetGameTimer()
        if delay > 0 then
            waiting = true
            Citizen.SetTimeout(delay, function()
                waiting = false
                processQueue()
            end)
            return
        end
        local job = table.remove(queue, 1)
        local state = job.state
        if (not state and guildCompleted) or (state and (not guildId or sessions[state.src] ~= state or not GetPlayerName(state.src)
            or GetPlayerIdentifierByType(state.src, 'discord') ~= 'discord:' .. state.id)) then
            return processQueue()
        end
        busy = true
        local done = false
        local function finish(status, body, headers)
            if done or not running then return end
            done, busy = true, false
            local ok, response = pcall(json.decode, body or '')
            if not ok or type(response) ~= 'table' then response = nil end
            local normalized = {}
            for name, value in pairs(type(headers) == 'table' and headers or {}) do
                normalized[tostring(name):lower()] = value
            end
            local retryAfter = status == 429 and (normalized['retry-after'] or (response and response.retry_after))
                or (tonumber(normalized['x-ratelimit-remaining']) == 0 and normalized['x-ratelimit-reset-after'])
            retryAfter = tonumber(retryAfter)
            if not retryAfter or retryAfter ~= retryAfter or retryAfter <= 0 or retryAfter == math.huge then
                retryAfter = status == 429 and 1 or 0.25
            end
            if status == 401 or status == 403 then retryAfter = math.max(retryAfter, 60) end
            blockedUntil = GetGameTimer() + math.ceil(retryAfter * 1000)
            if status == 429 and (job.retries or 0) < 2 then
                job.retries = (job.retries or 0) + 1
                table.insert(queue, 1, job)
                Warn('Discord permissions: rate limit reached; retrying after the requested delay')
            elseif not state or (sessions[state.src] == state and GetPlayerName(state.src)
                and GetPlayerIdentifierByType(state.src, 'discord') == 'discord:' .. state.id) then
                if not pcall(job.callback, status, response) then
                    Warn('Discord permissions: could not apply response; check permission integration')
                end
            end
            processQueue()
        end
        Citizen.SetTimeout(15000, function() finish(0) end)
        local path = state and ('/guilds/' .. guildId .. '/members/' .. state.id) or job.path
        local ok = pcall(PerformHttpRequest, 'https://discord.com/api/v10' .. path, finish, 'GET', '', {
            Authorization = 'Bot ' .. token,
            ['User-Agent'] = 'FiveguardAddon (https://github.com/jeakels/addon, 1.6.2)'
        }, { followLocation = false })
        if not ok then finish(0) end
    end

    if #roles > 0 then
        queue[1] = {
            path = automatic and '/users/@me/guilds?limit=2' or '/guilds/' .. Config.DiscordPermissions.guildId,
            callback = function(status, response)
                if guildCompleted then return end
                guildCompleted = true
                if status ~= 200 or not response then
                    return guildInitialization:resolve({ ok = false, reason = 'Guild lookup failed (HTTP ' .. tostring(status) .. '); users remain available' })
                end
                if automatic then
                    if not array(response) or #response ~= 1 or type(response[1]) ~= 'table' or not snowflake(response[1].id) then
                        return guildInitialization:resolve({ ok = false, reason = 'Auto requires exactly one guild; configure guildId. Users remain available' })
                    end
                    guildId = response[1].id
                elseif response.id == Config.DiscordPermissions.guildId then
                    guildId = response.id
                else
                    return guildInitialization:resolve({ ok = false, reason = 'Invalid response for configured guildId; users remain available' })
                end
                guildInitialization:resolve({ ok = true })
            end
        }
    end

    local function onJoin(src)
        src = tonumber(src)
        if not src or not GetPlayerName(src) or sessions[src] then return end
        local identifier = GetPlayerIdentifierByType(src, 'discord')
        local id = identifier and identifier:match('^discord:(%d+)$')
        local state = { src = src, id = id }
        sessions[src] = state
        if not snowflake(id) then return end
        if users[id] then
            state.group = users[id].group
            return SetPermission(src, state.group, true)
        end
        if #roles == 0 then return end
        queue[#queue + 1] = {
            state = state,
            callback = function(status, response)
                if status == 404 then return end
                if status ~= 200 then
                    return Warn('Discord permissions: member lookup failed (HTTP ' .. tostring(status) .. ') for player ' .. src)
                end
                if not response or not array(response.roles)
                    or (response.user and (type(response.user) ~= 'table' or response.user.id ~= id)) then
                    return Warn('Discord permissions: invalid member response for player ' .. src)
                end
                local memberRoles = { [guildId] = true }
                for _, roleId in ipairs(response.roles) do
                    if not snowflake(roleId) then return Warn('Discord permissions: invalid member roles for player ' .. src) end
                    memberRoles[roleId] = true
                end
                for _, role in ipairs(roles) do
                    if memberRoles[role.id] then
                        state.group = role.group
                        return SetPermission(src, role.group, true)
                    end
                end
            end
        }
        processQueue()
    end
    AddEventHandler('playerJoining', function() onJoin(source) end)
    AddEventHandler('playerDropped', function()
        local src = tonumber(source)
        local state = sessions[src]
        sessions[src] = nil
        for index = #queue, 1, -1 do
            if state and queue[index].state == state then table.remove(queue, index) end
        end
        if state and state.group then
            local ok = pcall(SetPermission, src, state.group, false)
            if not ok then Warn('Discord permissions: could not refresh disconnected player permissions') end
        end
    end)
    AddEventHandler('onResourceStop', function(resource)
        if resource ~= CurrentResourceName then return end
        running = false
        queue = {}
        for _, ace in ipairs(createdAces) do
            ExecuteCommand(('remove_ace fg.%s %s allow'):format(ace[1], ace[2]))
        end
    end)
    for _, src in ipairs(GetPlayers()) do onJoin(src) end
    processQueue()
    if guildInitialization then
        local result = Citizen.Await(guildInitialization)
        if not result.ok then return false, result.reason end
    end
    if initializationError then return false, initializationError .. '; users remain available' end
    Info('[Easy Permissions] Connected successfully with: ^3Discord^0')
elseif Config.AcePermissions.enable then
    for group, groupConfig in pairs(Config.AcePermissions.groups) do
        local principal = ('group.%s'):format(group)
        local object    = ('has.'..group)
        for i = 1 , #groupConfig do
            if IsPrincipalAceAllowed(('fg.%s'):format(group),groupConfig[i]) then
                Warn(('[ACE Permission] Ignored permission %s for group %s because is already registered'):format(groupConfig[i],group))
            else
                ExecuteCommand(('add_ace fg.%s %s allow'):format(group, groupConfig[i]))
            end
        end
        if not IsPrincipalAceAllowed(principal, object) then
            ExecuteCommand(('add_ace %s %s allow'):format(principal, object))
        end
    end

    AddEventHandler('playerJoining', function()
        if tonumber(source) > 65000 then return end
        for group,_ in pairs(Config.AcePermissions.groups) do
            if IsPlayerAceAllowed(source, 'has.'..group) then
                SetPermission(source, group, true)
                break
            end
        end
    end)

    RegisterNetEvent('fg:addon:playerReady', function()
        for group, _ in pairs(Config.AcePermissions.groups) do
            if IsPlayerAceAllowed(source, 'has.'..group) then
                SetPermission(source, group, true)
                break
            end
        end
    end)

    AddEventHandler('playerDropped', function()
        for group,_ in pairs(Config.AcePermissions.groups) do
            if IsPlayerAceAllowed(source, 'has.'..group) then
                SetPermission(source, group, false)
                break
            end
        end
    end)

    AddEventHandler('onResourceStop', function(res)
        if CurrentResourceName ~= res then return end
        for group, groupConfig in pairs(Config.AcePermissions.groups) do
            for i = 1 , #groupConfig do
                ExecuteCommand(('remove_ace fg.%s %s allow'):format(group, groupConfig[i]))
            end
        end
    end)
elseif Config.FrameworkPermissions.enable then
    local out = ''
    for group, groupConfig in pairs(Config.FrameworkPermissions.groups) do
        for i = 1 , #groupConfig do
            if IsPrincipalAceAllowed(('fg.%s'):format(group),groupConfig[i]) then
                out = out..'\n\tIgnored permission \''..groupConfig[i]..'\' for group \''..group..'\'. Already Registered!'
            else
                ExecuteCommand(('add_ace fg.%s %s allow'):format(group, groupConfig[i]))
            end
        end
    end
    if string.len(out) > 10 then Warn(out) end
    local checkResource = function (res)
        local rs = GetResourceState(res)
        return rs == 'started' or rs == 'starting'
    end
    local frameworkDetected = ''
    local frameworkResource
    if not Config.FrameworkPermissions.customFramework.enable then
        if checkResource('es_extended') then
            frameworkDetected = 'ESX'
            local ESX = exports.es_extended:getSharedObject()
            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                local xPlayer = ESX.GetPlayerFromId(src)
                if xPlayer then
                    SetPermission(src, xPlayer.getGroup(), true)
                end
            end
            AddEventHandler('esx:playerLoaded', function(source, xPlayer)
                Debug('[esx:playerLoaded]',GetInvokingResource(),source, xPlayer)
                if GetInvokingResource() ~= 'es_extended' then return Warn(source,'tried to exploit esx:playerLoaded') end
                local fgGroup = xPlayer.getGroup()
                SetPermission(source, fgGroup, true)
            end)
            AddEventHandler('esx:playerDropped', function(playerId, reason)
                Debug('[esx:playerDropped]',GetInvokingResource(),playerId, reason)
                if GetInvokingResource() ~= 'es_extended' then return Warn(source,'tried to exploit esx:playerDropped') end
                local xPlayer = ESX.GetPlayerFromId(playerId)
                local fgGroup = xPlayer.getGroup()
                SetPermission(playerId, fgGroup, false)
            end)
            AddEventHandler('esx:setGroup',function(playerId, group, lastGroup)
                Debug('[esx:setGroup]',GetInvokingResource(),playerId, group, lastGroup)
                if GetInvokingResource() ~= 'es_extended' then return Warn(source,'tried to exploit esx:setGroup') end
                SetPermission(playerId, lastGroup, false)
                SetPermission(playerId, group, true)
            end)
        elseif checkResource('qbx_core') then
            frameworkDetected = 'QBox'
            for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)

            if exports.qbx_core:GetPlayer(src) then
                for group in pairs(Config.FrameworkPermissions.groups) do
                    if IsPlayerAceAllowed(src, group) then
                        SetPermission(src, group, true)
                        break
                    end
                end
            end
        end
            AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
                Debug('[QBCore:Server:PlayerLoaded]',GetInvokingResource(),Player.PlayerData.source)
                if GetInvokingResource() ~= 'qbx_core' then return Warn(source,'tried to exploit QBCore:Server:PlayerLoaded') end
                for group,_ in pairs(Config.FrameworkPermissions.groups) do
                    if IsPlayerAceAllowed(Player.PlayerData.source, group) then
                        SetPermission(Player.PlayerData.source, group, true)
                        break
                    end
                end
            end)
            RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(source)
                Debug('[QBCore:Server:OnPlayerUnload]',GetInvokingResource(),source)
                if GetInvokingResource() ~= 'qbx_core' then return Warn(source,'tried to exploit QBCore:Server:OnPlayerUnload') end
                for group,_ in pairs(Config.FrameworkPermissions.groups) do
                    if IsPlayerAceAllowed(source, group) then
                        SetPermission(source, group, false)
                        break
                    end
                end
            end)
            AddEventHandler('QBCore:Server:OnPermissionUpdate', function(source)
                Debug('[QBCore:Server:OnPermissionUpdate]',GetInvokingResource(),source)
                if GetInvokingResource() ~= 'qbx_core' then return Warn(source,'tried to exploit QBCore:Server:OnPermissionUpdate') end
                for group,_ in pairs(Config.FrameworkPermissions.groups) do
                    if IsPlayerAceAllowed(source, group) then
                        SetPermission(source, group, true)
                    else
                        SetPermission(source, group, false)
                    end
                end
            end)
            AddEventHandler('qbx_core:server:onGroupUpdate', function(source, groupName, groupGrade)
                Debug('[qbx_core:server:onGroupUpdate]',GetInvokingResource(),source, groupName, groupGrade)
                if GetInvokingResource() ~= 'qbx_core' then return Warn(source,'tried to exploit qbx_core:server:onGroupUpdate') end
                for group,_ in pairs(Config.FrameworkPermissions.groups) do
                    if IsPlayerAceAllowed(source, group) then
                        SetPermission(source, group, true)
                    elseif not IsPlayerAceAllowed(source, group) then
                        SetPermission(source, group, false)
                    end
                end
            end)
        elseif checkResource('qb-core') then
            frameworkDetected = 'QBCore'
            local QBCore = exports['qb-core']:GetCoreObject()
            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                if QBCore.Functions.GetPlayer(src) then
                    for group in pairs(Config.FrameworkPermissions.groups) do
                        if IsPlayerAceAllowed(src, group) then
                            SetPermission(src, group, true)
                            break
                        end
                    end
                end
            end
            if not IsPrincipalAceAllowed('qbcore.god','group.admin') then
                ExecuteCommand('add_principal qbcore.god group.admin')
            end
            AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
                Debug('[QBCore:Server:PlayerLoaded]',GetInvokingResource(),Player.PlayerData.source)
                if GetInvokingResource() ~= 'qb-core' then return Warn(source,'tried to exploit QBCore:Server:PlayerLoaded') end
                for group,_ in pairs(Config.FrameworkPermissions.groups) do
                    if IsPlayerAceAllowed(Player.PlayerData.source, group) then
                        SetPermission(Player.PlayerData.source, group, true)
                        break
                    end
                end
            end)
            AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
                Debug('[QBCore:Server:OnPlayerUnload]',GetInvokingResource(),source)
                if GetInvokingResource() ~= 'qb-core' then return Warn(source,'tried to exploit QBCore:Server:OnPlayerUnload') end
                for group,_ in pairs(Config.FrameworkPermissions.groups) do
                    if IsPlayerAceAllowed(source, group) then
                        SetPermission(source, group, false)
                        break
                    end
                end
            end)
        elseif checkResource('vrp') then
            local vrp, err = GetVRPBridge()
            if not vrp then return false, err end
            frameworkDetected = vrp.version
            frameworkResource = vrp.resource
            local assignedGroups = {}

            AddEventHandler(vrp.syncEvent, function(playerId, clear)
                local invoker = GetInvokingResource()
                if invoker ~= vrp.resource and invoker ~= CurrentResourceName then return end
                local src = tonumber(playerId)
                if not src or not GetPlayerName(src) then return end
                local selectedGroup
                if not clear then
                    local ok, groups = pcall(vrp.GetGroups, vrp, src)
                    if not ok then Error('vRP permission sync: ' .. tostring(groups)) return end
                    if type(groups) ~= 'table' then return end
                    for group in pairs(Config.FrameworkPermissions.groups) do
                        if group ~= 'user' and groups[group] ~= nil then
                            selectedGroup = group
                            break
                        end
                    end
                end
                local previousGroup = assignedGroups[src]
                if previousGroup == selectedGroup then return end
                if previousGroup then
                    SetPermission(src, previousGroup, false)
                    assignedGroups[src] = nil
                end
                if selectedGroup then
                    SetPermission(src, selectedGroup, true)
                    assignedGroups[src] = selectedGroup
                end
            end)

            vrp:SubscribePermissions()
            AddEventHandler('playerDropped', function()
                local src = tonumber(source)
                local group = assignedGroups[src]
                assignedGroups[src] = nil
                if group then
                    local ok, cleanupError = pcall(SetPermission, src, group, false)
                    if not ok then Warn('vRP permission cleanup: ' .. tostring(cleanupError)) end
                end
            end)
            for _, playerId in ipairs(GetPlayers()) do
                TriggerEvent(vrp.syncEvent, tonumber(playerId))
            end
        else return false, 'Framework not detected; configure customFramework if needed'
        end
    else
        if type(Config.FrameworkPermissions.customFramework.customEvent) ~= 'string' or not Config.FrameworkPermissions.customFramework.customEvent:find('%S') then
            return false, 'Custom framework event missing or invalid'
        end
        AddEventHandler(tostring(Config.FrameworkPermissions.customFramework.customEvent),function(playerId,group,allow)
            frameworkDetected = GetInvokingResource()
            Debug('[customEvent]', GetInvokingResource())
            if Config.FrameworkPermissions.customFramework.invokerResource and Config.FrameworkPermissions.customFramework.invokerResource:len() > 4 then
                if GetInvokingResource() ~= Config.FrameworkPermissions.customFramework.invokerResource then return Warn(source,'tried to exploit '..Config.FrameworkPermissions.customFramework.customEvent) end
            else
                Warn('Make sure to config \'Config.FrameworkPermissions.customFramework.invokerResource\' for you custom framework, without it the event can be exploitable by cheaters!')
            end
            if not (playerId and group and allow~=nil) then
                return Warn('[Framework Permission] Bad config for custom framework')
            end
            SetPermission(playerId, group, allow)
        end)
    end
    Info('[Easy Permissions] Connected successfully with: ^3'..frameworkDetected..'^0')

    AddEventHandler('onResourceStop', function(res)
        if (CurrentResourceName ~= res) then return end
        for group, groupConfig in pairs(Config.FrameworkPermissions.groups) do
            for i = 1 , #groupConfig do
                ExecuteCommand(('remove_ace fg.%s %s allow'):format(group, groupConfig[i]))
            end
        end
        if frameworkDetected == 'QBCore' then
            ExecuteCommand('remove_principal qbcore.god group.admin')
        end
    end)
    AddEventHandler('onResourceStop', function(res)
        if res ~= (frameworkResource or frameworkDetected) then return end
        for group, groupConfig in pairs(Config.FrameworkPermissions.groups) do
            for i = 1 , #groupConfig do
                ExecuteCommand(('remove_ace fg.%s %s allow'):format(group, groupConfig[i]))
            end
        end
        if frameworkDetected == 'QBCore' then
            ExecuteCommand('remove_principal qbcore.god group.admin')
        end
    end)
elseif Config.txAdminPermissions.enable then
    if GetResourceState('monitor') ~= 'started' then return false, 'txAdmin is not started' end
    Info('Easy Permissions: using txAdmin Permissions')
    for i = 1, #Config.txAdminPermissions.fgPermissions do
        if IsPrincipalAceAllowed('fg.txadmin', Config.txAdminPermissions.fgPermissions[i]) then
            Warn(('[txAdmin Permissions] Ignored permission %s for group fg.txadmin because is already registered'):format(Config.txAdminPermissions.fgPermissions[i]))
        else
            ExecuteCommand(('add_ace fg.txadmin %s allow'):format(Config.txAdminPermissions.fgPermissions[i]))
        end
    end
    AddEventHandler('txAdmin:events:adminAuth', function(data)
        Debug('[txAdmin:events:adminAuth]', json.encode(data, {indent=true}))
        if not data then return end
        if data.netid >= 1 then
            SetPermission(data.netid, 'txadmin', data?.isAdmin)
        else
            Info('txAdmin sent a broadcast reauth')
            local targets = GetPlayers()
            for i = 1, #targets do
                SetPermission(targets[i], 'txadmin', data?.isAdmin)
            end
        end
    end)
    AddEventHandler('onResourceStop', function(res)
        if res ~= CurrentResourceName then return end
        for i = 1, #Config.txAdminPermissions.fgPermissions do
            ExecuteCommand(('remove_ace fg.txadmin %s allow'):format(Config.txAdminPermissions.fgPermissions[i]))
        end
    end)
    AddEventHandler('onResourceStop', function(res)
        if res ~= 'monitor' then return end
        for i = 1, #Config.txAdminPermissions.fgPermissions do
            ExecuteCommand(('remove_ace fg.txadmin %s allow'):format(Config.txAdminPermissions.fgPermissions[i]))
        end
    end)
    Info('[Easy Permissions] Connected successfully with: ^3txAdmin^0')
end

return true
