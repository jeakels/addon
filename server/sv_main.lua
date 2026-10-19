ExecuteCommand("add_ace group.addon command allow")
ExecuteCommand("add_principal resource." .. CurrentResourceName .. " group.addon")
ExecuteCommand('add_unsafe_child_process_permission '..CurrentResourceName)
ExecuteCommand('add_filesystem_permission '..CurrentResourceName..' write vrp')
AddEventHandler('onResourceStop', function(res)
    if CurrentResourceName ~= res then return end
    ExecuteCommand('remove_principal resource.'..CurrentResourceName..' group.'..CurrentResourceName)
    ExecuteCommand('remove_ace group.'..CurrentResourceName..' command allow')
end)

local Config = GetConfig()
while not Fiveguard do Citizen.Wait(0) end

AddonDiscordBotState = { ready = false }
local botInitialization = promise.new()
local botInitialized = false
local function completeBotInitialization(result)
    if botInitialized then return end
    botInitialized = true
    botInitialization:resolve(result)
end
local function botSend(message)
    TriggerEvent('fg:addon:bot:send', json.encode(message))
end
AddEventHandler('fg:addon:bot:ready', function(payload)
    local data = json.decode(payload)
    AddonDiscordBotState.ready = true
    AddonDiscordBotState.guildId = data.guildId
    AddonDiscordBotState.memberEvents = data.memberEvents
    local details = {}
    local features = data.features or {}
    if features.commands then details[#details + 1] = 'commands' end
    if features.logsToPunish then details[#details + 1] = 'logs to punish' end
    if features.roles then details[#details + 1] = data.memberEvents and 'roles' or 'roles HTTP' end
    completeBotInitialization({
        status = data.problem and 'problem' or 'active',
        reason = data.problem,
        details = table.concat(details, ' | ')
    })
    TriggerEvent('fg:addon:bot:refreshPermissions')
end)
AddEventHandler('fg:addon:bot:unavailable', function()
    AddonDiscordBotState.ready = false
end)
AddEventHandler('fg:addon:bot:failed', function(reason)
    completeBotInitialization({ status = 'problem', reason = reason })
end)

local function positiveInteger(value)
    return type(value) == 'number' and value > 0 and value % 1 == 0 and value <= 2147483647
end
local function botReason(value)
    assert(type(value) == 'string' and #value > 0 and #value <= 2048 and not value:find('[%c;]'), 'Invalid reason')
    return value
end
local function botIdentifier(value)
    assert(type(value) == 'string' and #value <= 128 and value:match('^[%w]+:[%w]+$'), 'Invalid identifier')
    local kind = value:match('^(%w+):')
    assert(({ license = true, license2 = true, steam = true, discord = true, fivem = true, live = true, xbl = true })[kind], 'Unsupported identifier type')
    return value
end
AddEventHandler('fg:addon:bot:request', function(payload)
    if not Config.discordBot.commands and not Config.discordBot.logsToPunish.enable then return end
    Citizen.CreateThread(function()
        local request = json.decode(payload)
        local ok, value = xpcall(function()
            local action, args = request.action, request.args
            if action == 'logsToPunish' then assert(Config.discordBot.logsToPunish.enable, 'Logs To Punish is disabled')
            else assert(Config.discordBot.commands, 'Discord commands are disabled') end
            assert(type(args) == 'table', 'Invalid arguments')
            if action == 'commandPermission' then
                assert(type(args.discordId) == 'string' and #args.discordId <= 20
                    and args.discordId:match('^%d+$'), 'Invalid Discord user ID')
                local principal = 'identifier.discord:' .. args.discordId
                local fgCommands = IsPrincipalAceAllowed(principal, 'FGCommands')
                local misc = IsPrincipalAceAllowed(principal, 'Misc')
                return { allowed = fgCommands == true or fgCommands == 1 or misc == true or misc == 1 }
            end
            assert(GetResourceState(Fiveguard) == 'started', 'FiveGuard is unavailable')
            if action == 'check' or action == 'unban' then
                assert(positiveInteger(args.banId), 'Invalid ban ID')
                local result
                if action == 'check' then result = exports[Fiveguard]:GetBanInfoId(args.banId)
                else result = exports[Fiveguard]:UnbanId(args.banId) end
                if not result then return ('Ban ID %s not found.'):format(args.banId) end
                return result
            elseif action == 'clear' then
                local kinds = { ped = { 'clearped' }, vehicles = { 'clearveh' }, objects = { 'clearobj' }, all = { 'clearped', 'clearveh', 'clearobj' } }
                assert(kinds[args.kind], 'Invalid entity type')
                for _, command in ipairs(kinds[args.kind]) do ExecuteCommand('fg ' .. command) end
                return ('Cleanup commands sent to FiveGuard for %s.'):format(args.kind)
            elseif action == 'logsToPunish' then
                local identifier, reason = botIdentifier(args.identifier), botReason(args.reason)
                local rule = Config.discordBot.logsToPunish.options[args.option]
                assert(type(rule) == 'table' and (rule.punishment == 'ban' or rule.punishment == 'kick'), 'Missing or invalid logsToPunish punishment')
                local function clean(value)
                    return tostring(value):gsub('[%c]', ' '):gsub('%^%d', '')
                end
                for _, player in ipairs(GetPlayers()) do
                    for _, id in ipairs(GetPlayerIdentifiers(player)) do
                        if id == identifier then
                            local playerId = tonumber(player)
                            local playerName = GetPlayerName(playerId)
                            if playerName then
                                local actionText
                                if rule.punishment == 'kick' then
                                    DropPlayer(playerId, '[FIVEGUARD.NET] You have been kicked.')
                                    actionText = '^2kicked^0'
                                else
                                    local result = exports[Fiveguard]:fg_BanPlayer(playerId, reason, true)
                                    assert(result ~= false, 'FiveGuard rejected ban')
                                    actionText = '^2ban requested^0'
                                end
                                print(('[Discord bot] [Logs To Punish] [^5%s^0] ^5%s^0 %s with reason ^3%s^0.'):format(
                                    playerId, clean(playerName), actionText, clean(reason)))
                                return true
                            end
                        end
                    end
                end
                if rule.punishment == 'kick' then
                    print(('[Discord bot] [Logs To Punish] ^3Kick skipped^0 for ^5%s^0: player is not connected. Reason: ^3%s^0.'):format(clean(identifier), clean(reason)))
                    return true
                end
                ExecuteCommand(('fg offlineban %s %s'):format(identifier, reason))
                print(('[Discord bot] [Logs To Punish] Offline ban requested for ^5%s^0 with reason ^3%s^0.'):format(clean(identifier), clean(reason)))
                return true
            elseif action == 'offlineban' then
                local identifier, reason = botIdentifier(args.identifier), botReason(args.reason)
                ExecuteCommand(('fg offlineban %s %s'):format(identifier, reason))
                return ('Offline ban command sent to FiveGuard for %s.'):format(identifier)
            end
            assert(({ ban = true, kick = true, record = true, screenshot = true })[action], 'Unsupported action')
            local player = args.serverId
            if not positiveInteger(player) or not GetPlayerName(player) then
                return ('Player %s is not connected.'):format(tostring(player))
            end
            if action == 'ban' then
                local result = exports[Fiveguard]:fg_BanPlayer(player, botReason(args.reason), true)
                assert(result ~= false, 'FiveGuard rejected ban')
                return ('Ban request sent to FiveGuard for player %s.'):format(player)
            elseif action == 'kick' then
                DropPlayer(player, ('[FIVEGUARD.NET] You have been kicked for: %s'):format(botReason(args.reason)))
                return ('Player %s kicked successfully.'):format(player)
            end
            local expectedLicense = GetPlayerIdentifierByType(player, 'license')
            local seconds = args.seconds or Config.recordTime
            assert(type(seconds) == 'number' and seconds >= 1 and seconds <= 60 and seconds % 1 == 0, 'Duration must be 1-60 seconds')
            local pending, finished = promise.new(), false
            local function complete(url, err)
                if finished then return end
                finished = true
                pending:resolve({ url = url, error = err })
            end
            Citizen.SetTimeout((seconds + 45) * 1000, function() complete(nil, 'Media request timed out') end)
            local webhook = Config.customMediaWebhookUrl
            if type(webhook) ~= 'string' or #webhook < 80 then webhook = nil end
            if action == 'record' then exports[Fiveguard]:recordPlayerScreen(player, seconds * 1000, complete, webhook)
            else exports[Fiveguard]:screenshotPlayer(player, complete, webhook) end
            local result = Citizen.Await(pending)
            assert(not result.error and type(result.url) == 'string', tostring(result.error or 'No media URL returned'))
            assert(GetPlayerIdentifierByType(player, 'license') == expectedLicense, 'Player disconnected during capture')
            return ('%s for player %s:\n%s'):format(action == 'record' and 'Recording' or 'Screenshot', player, result.url)
        end, function(err) return tostring(err) end)
        if not ok then
            local args = type(request.args) == 'table' and request.args or {}
            print(('[Discord bot] %s %s: %s'):format(tostring(request.action), tostring(args.serverId or args.banId or args.identifier or args.kind or ''), tostring(value)))
        end
        botSend({ type = 'result', id = request.id, value = ok and value or nil, error = not ok and value or nil })
    end)
end)

Citizen.CreateThread(function()
    local sync = Config.discordBot.syncRoles and Config.easyPermissions.enable and Config.easyPermissions.discordPermissions.enable
    local run = Config.discordBot.commands or sync or Config.discordBot.logsToPunish.enable
    if run then
        Citizen.SetTimeout(300000, function()
            completeBotInitialization({ status = 'problem', reason = 'Discord initialization timed out (300 seconds)' })
        end)
    else
        completeBotInitialization({ status = 'disabled' })
    end
    TriggerEvent('fg:addon:bot:start', json.encode({
        config = Config.discordBot,
        permissions = { users = Config.easyPermissions.discordPermissions.users, roles = Config.easyPermissions.discordPermissions.roles },
        sync = sync,
        run = run
    }))
end)

local function checkVersion()
    local version = GetResourceMetadata(CurrentResourceName, 'version', 0)
    if version then version = version:match('(%d+%.%d+%.%d+)')
    else Error('Can\'t read version') return end

    Citizen.SetTimeout(1500, function()
        PerformHttpRequest('https://api.github.com/repos/jeakels/addon/releases/latest', function(code, body)
            if code ~= 200 or not body then return end

            local bData = json.decode(body)
            if not bData or bData.prerelease then return end

            local latest = bData.tag_name and bData.tag_name:match('(%d+%.%d+%.%d+)')
            if not latest or latest == version then return end

            local function splitVersion(v)
                local t = {}
                for num in v:gmatch('%d+') do
                    t[#t+1] = tonumber(num)
                end
                return t
            end

            local currentParts = splitVersion(version)
            local latestParts = splitVersion(latest)

            for i = 1, math.max(#currentParts, #latestParts) do
                local c = currentParts[i] or 0
                local l = latestParts[i] or 0

                if c < l then
                    Warn(('Update available (%s → %s) %s'):format(version, latest, bData.html_url))
                    return
                elseif c > l then
                    Warn(('Using unreleased version: %s Latest stable version: %s'):format(version, latest))
                    return
                end
            end
        end, 'GET')
    end)
end

local CORRECT_FXMANIFEST = [=[fx_version 'cerulean'
game 'gta5'

author 'Community of fiveguard.net'
description 'Addon pack for fiveguard'
version '1.6.2'
lua54 'yes'
addon 'yes'

data_file 'DLC_ITYP_REQUEST' 'stream/mads_no_exp_pumps.ytyp'

shared_script 'shared.lua'

server_scripts {
    'server/sv_resourceManager.js',
    'server/vrp_bridge.lua',
    'server/sv_main.lua'
}

client_script 'client/cl_main.lua'

files {
    'client/cl_antiFiveguardStopper.lua',
    'client/cl_easyBypass.lua',
    'client/cl_heartbeat.lua',
    'client/cl_vehicleProtection.lua',
    'client/cl_weaponProtection.lua'
}

file 'bypassNative.lua'
file 'xss.lua'
]=]

local function checkAndFixFxmanifest()
    local function simple_hash(s)
        if not s then return nil end
        s = s:gsub('^\239\187\191', '')
        s = s:gsub('\r\n', '\n')
        s = s:gsub('\r', '\n')
        s = s:gsub('\n*$', '\n')
        local h1, h2 = 0, 0
        for i = 1, #s do
            local b = s:byte(i)
            h1 = (h1 + b) % 0x100000000
            h2 = (h2 * 31 + b) % 0x100000000
        end
        return string.format('%08x%08x', h1, h2)
    end
    local currentContent = LoadResourceFile(CurrentResourceName, 'fxmanifest.lua')

    local correctHash = simple_hash(CORRECT_FXMANIFEST)
    local currentHash = simple_hash(currentContent)

    if currentHash ~= correctHash then
        Warn('You\'ve modified fxmanifest.lua, overwriting it with the correct version...')

        local resPath = GetResourcePath(CurrentResourceName)
        local fullPath = resPath .. '/' .. 'fxmanifest.lua'

        local file = io.open(fullPath, 'w')
        if file then
            file:write(CORRECT_FXMANIFEST)
            file:close()
            Info('fxmanifest.lua successfully restored, restart '..CurrentResourceName..' to start!')
            ExecuteCommand('refresh')
        else
            Error('Unable to open fxmanifest.lua! Check permissions.')
        end
        return true
    end
    return false
end

local banning = {}
local function getMedia(source, mediaType)
    local mediaUrl
    if Config.customMediaWebhookUrl and string.len(Config.customMediaWebhookUrl) < 80 then Config.customMediaWebhookUrl = nil end
    if tostring(mediaType) == 'video' then
        local p = promise.new()
        if not pcall(function() return exports[Fiveguard]:recordPlayerScreen(source, Config.recordTime*1000, function(success)
            if success then Debug(('Player [^5%s^0] ^5%s^0 recorded successfully'):format(source, GetPlayerName(source)))
            else Warn(('Unable to record the player [^5%s^0] ^5%s^0'):format(source, GetPlayerName(source))) end
            p:resolve(success)
        end, Config.customMediaWebhookUrl) end) then p:resolve(); Warn(('Unable to record the player [^5%s^0] ^5%s^0 \'^6recordPlayerScreen^0\' export not available'):format(source, GetPlayerName(source))) end
        mediaUrl =  Citizen.Await(p)
    elseif tostring(mediaType) == 'image' then
        local p = promise.new()
        if not pcall(function() return exports[Fiveguard]:screenshotPlayer(source, function(success)
            if success then Debug(('Player [^5%s^0] ^5%s^0 screenshotted successfully'):format(source, GetPlayerName(source)))
            else Warn(('Unable to screenshot the player [^5%s^0] ^5%s^0'):format(source, GetPlayerName(source))) end
            p:resolve(success)
        end, Config.customMediaWebhookUrl) end) then p:resolve(); Warn(('Unable to screenshot the player [^5%s^0] ^5%s^0, \'^6screenshotPlayer^0\' export not available'):format(source, GetPlayerName(source))) end
        mediaUrl =  Citizen.Await(p)
    end
    return mediaUrl
end

function PunishPlayer(source, ban, reason, mediaType)
    Citizen.CreateThread(function ()
        if not reason then reason= '' end
        ::cueuing::
        if banning[source] then
            Debug(('Ignoring punishment of player [^5%s^0] ^5%s^0 since it\'s getting punished'):format(source, GetPlayerName(source)))
            Citizen.Wait(100)
            goto cueuing
        end
        if not GetPlayerName(source) then return end
        banning[source] = true
        Debug('PunishPlayer', source, ban, reason, mediaType)
        local mediaUrl = getMedia(source, mediaType)
        if ban == 'ban' then
            if not pcall(function() return exports[Fiveguard]:fg_BanPlayer(source, reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or ''), true) end) then
                Error(('Unable to ban the Player [^5%s^1] ^5%s^1, \'^6fg_BanPlayer^1\' export not available. Kicking instead for ^3%s^0'):format(source, GetPlayerName(source), reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or '')))
                DropPlayer(source,'[FIVEGUARD.NET] You have been kicked.')
            end
        elseif ban == 'kick' then
            print(('[^1PUNISHMENT^0] Kicking [^5%s^0] ^5%s^0 for ^3%s^0'):format(source, GetPlayerName(source), reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or '')))
            DropPlayer(source,'[FIVEGUARD.NET] You have been kicked.')
        elseif ban == 'log' then
            print(('[^1PUNISHMENT^0] Logging [^5%s^0] ^5%s^0 for ^3%s^0'):format(source, GetPlayerName(source), reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or '')))
        end
        banning[source] = nil
    end)
end
AddEventHandler('playerDropped', function()
    banning[source] = nil
end)

local modules = {}
for name, config in pairs(Config) do
    if name ~= 'discordBot' and type(name) == 'string' and type(config) == 'table' and config.enable ~= nil then
        modules[#modules + 1] = name
    end
end
table.sort(modules)

local function loadModules(linked, linkError)
    local results, pendingModules = {}, {}
    for _, name in ipairs(modules) do
        local config = Config[name]
        if type(config) ~= 'table' then
            results[name] = { status = 'problem', reason = 'Missing configuration section' }
        elseif not config.enable then
            results[name] = { status = 'disabled' }
        elseif not linked then
            results[name] = { status = 'problem', reason = linkError }
        else
            local path = 'server/sv_' .. name .. '.lua'
            local pending = promise.new()
            local finished = false
            local function complete(initialized, reason, details)
                if finished then return end
                finished = true
                pending:resolve({
                    status = initialized == true and 'active' or 'problem',
                    reason = reason,
                    details = details
                })
            end
            Citizen.SetTimeout(60000, function()
                complete(false, 'Initialization timed out (60 seconds); module may be partially initialized')
            end)
            Citizen.CreateThread(function()
                local success, initialized, reason, details = xpcall(function()
                    local source = assert(LoadResourceFile(CurrentResourceName, path), 'Unable to read ' .. path)
                    local environment = setmetatable({ Config = config }, { __index = _ENV, __newindex = _ENV })
                    local chunk = assert(load(source, '@@' .. CurrentResourceName .. '/' .. path, 't', environment))
                    return chunk()
                end, debug.traceback)
                if success then
                    complete(initialized, reason or (initialized ~= true and 'Initialization did not complete' or nil), details)
                else
                    complete(false, initialized)
                end
            end)
            pendingModules[name] = pending
        end
    end
    for _, name in ipairs(modules) do
        if pendingModules[name] then results[name] = Citizen.Await(pendingModules[name]) end
    end
    local botResult = Citizen.Await(botInitialization)
    results.discordBot = {
        status = botResult.status, reason = botResult.reason, details = botResult.details
    }
    if botResult.status == 'active' and not AddonDiscordBotState.ready then
        results.discordBot.status = 'problem'
        results.discordBot.reason = 'Discord connection unavailable at recap time'
        results.discordBot.details = nil
    end
    if botResult.status ~= 'disabled' and not linked then
        results.discordBot.status = 'problem'
        results.discordBot.reason = linkError
    elseif botResult.status ~= 'disabled' and Config.discordBot.syncRoles
        and Config.easyPermissions.enable and Config.easyPermissions.discordPermissions.enable
        and results.easyPermissions and results.easyPermissions.status ~= 'active' then
        results.discordBot.status = 'problem'
        results.discordBot.details = (results.discordBot.details or ''):gsub('%s*|?%s*roles.*$', '')
    end
    return results
end

Citizen.CreateThread(function()
    if checkAndFixFxmanifest() then return end
    local logo = ([[
^3                A                          ddddddd             ddddddd ^0
^3               A:A                         d:::::d             d:::::d ^0
^3              A:::A                        d:::::d             d:::::d ^0
^3             A:::::A                       d:::::d             d:::::d ^0
^3            A:::::::A                      d:::::d             d:::::d ^0
^3           A:::::::::A             ddddddddd:::::d     ddddddddd:::::d ^0   ooooooooooo    nnn  nnnnnnnn
^3          A:::::A:::::A          dd::::::::::::::d   dd::::::::::::::d ^0 oo:::::::::::oo  n:::n:::::::nn
^3         A:::::A A:::::A        d::::::::::::::::d  d::::::::::::::::d ^0o:::::::::::::::o n::::::::::::nn
^3        A:::::A   A:::::A      d:::::::ddddd:::::d d:::::::ddddd:::::d ^0o:::::ooooo:::::o n::::::::::::::n
^3       A:::::A     A:::::A     d::::::d    d:::::d d::::::d    d:::::d ^0o::::o     o::::o n:::::nnnn:::::n
^3      A:::::AAAAAAAAA:::::A    d:::::d     d:::::d d:::::d     d:::::d ^0o::::o     o::::o n::::n    n::::n
^3     A:::::::::::::::::::::A   d:::::d     d:::::d d:::::d     d:::::d ^0o::::o     o::::o n::::n    n::::n
^3    A:::::AAAAAAAAAAAAA:::::A  d:::::d     d:::::d d:::::d     d:::::d ^0o::::o     o::::o n::::n    n::::n
^3   A:::::A             A:::::A d::::::ddddd::::::d d::::::ddddd::::::d ^0o:::::ooooo:::::o n::::n    n::::n
^3  A:::::A               A:::::A d::::::::::::::::d  d::::::::::::::::d ^0o:::::::::::::::o n::::n    n::::n
^3 A:::::A                 A:::::A d::::::::::d::::d   d::::::::::d::::d ^0 oo:::::::::::oo  n::::n    n::::n
^3AAAAAAA                   AAAAAAA ddddddddd   dddd    ddddddddd   dddd ^0   ooooooooooo    nnnnnn    nnnnnn
version %s                                        By Jeakels and contributors. Powered by ^3five^0guard%s]]):format(GetResourceMetadata(CurrentResourceName, 'version', 0),'\n')
    local function splitCamelCase(str) return (str:gsub('(%l)(%u)', '%1 %2')) end
    local function printRecap(results)
        local keys, maxw = {}, 0
        for name in pairs(results) do
            keys[#keys + 1] = name
            maxw = math.max(maxw, #splitCamelCase(name))
        end
        table.sort(keys, function(a, b) return a:lower() < b:lower() end)
        local function plain(value) return (value:gsub('%^%d', '')) end
        local rows, width = {}, 0
        for _, name in ipairs(keys) do
            local result = results[name]
            local details = result.details and result.details ~= '' and ' (' .. result.details .. ')' or ''
            local row = (' %-' .. maxw .. 's %s%s'):format(splitCamelCase(name), result.status, details)
            rows[name] = row
            width = math.max(width, #plain(row) + 1)
        end
        local title = ' Module status '
        width = math.max(width, #title)
        local padding = width - #title
        local out = '\n|' .. string.rep('=', math.floor(padding / 2)) .. title
            .. string.rep('=', padding - math.floor(padding / 2)) .. '|'
        local colors = { active = '^2', disabled = '^3', problem = '^1' }
        for _, name in ipairs(keys) do
            local result = results[name]
            local row = rows[name]
            local prefix = (' %-' .. maxw .. 's '):format(splitCamelCase(name))
            out = out .. '\n|' .. prefix .. colors[result.status] .. result.status .. '^7'
                .. row:sub(#prefix + #result.status + 1) .. '^0'
                .. string.rep(' ', width - #plain(row)) .. '|'
        end
        out = out .. '\n|' .. string.rep('=', width) .. '|\n'
        print(logo, out)
        for _, name in ipairs(keys) do
            if results[name].reason then Warn(name .. ': ' .. tostring(results[name].reason)) end
        end
    end
    local attempts = 1
    SetConvar('ac', Fiveguard)
    ::recheckFG::
    Citizen.Wait(1000*attempts)
    if GetResourceState(Fiveguard) == 'started' then
        local ok = pcall(function() return exports[Fiveguard].fg_BanPlayer end)
        if ok then
            printRecap(loadModules(true))
            Info('Fiveguard linked ^2successfully^0!')
            if Config.checkUpdates == true then
                Citizen.SetTimeout(2000, checkVersion)
            end
        else
            Warn('Seems like Fiveguard (^3'..Fiveguard..'^0) is started but not ready yet, checking again... (attempt: '..attempts..')^0')
            attempts += 1
            if attempts <= 5 then goto recheckFG end
            Error('Fiveguard is started but it\'s not working properly, make sure it\'s properly installed with an active subscription and no errors below!')
            ExecuteCommand('ensure '..Fiveguard)
            printRecap(loadModules(false, 'Fiveguard is not ready'))
        end
    else
        Warn('You didn\'t start Fiveguard (^3'..Fiveguard..'^0) before this resource\nMake sure to start it as first resource in your server.cfg for better compatibility with your scripts!')
        Info('Starting Fiveguard (^3'..Fiveguard..'^0)... (attempt: '..attempts..')^0')
        ExecuteCommand('ensure '..Fiveguard)
        attempts += 1
        if attempts <= 5 then goto recheckFG end
        Error(('Failed to start Fiveguard (^3%s^1) (attempts: %s)'):format(Fiveguard, attempts))
        printRecap(loadModules(false, 'Unable to start Fiveguard'))
    end
end)
