local data = LoadResourceFile(CurrentResourceName,'config.lua')
local Config = assert(load(data))()
READY = false
while not Fiveguard do Citizen.Wait(0) end

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

local CORRECT_FXMANIFEST = 'fx_version \'cerulean\'\ngame \'gta5\'\n\nauthor \'Community of fiveguard.net\'\ndescription \'Addon pack for fiveguard\'\nversion \'1.6.1\'\nlua54 \'yes\'\naddon \'yes\'\n\ndata_file \'DLC_ITYP_REQUEST\' \'stream/mads_no_exp_pumps.ytyp\'\n\nshared_script \'shared.lua\'\n\nserver_scripts {\n    \'server/sv_resourceManager.js\',\n    \'server/sv_main.lua\',\n    \'server/sv_antiExplosion.lua\',\n    \'server/sv_antiThrow.lua\',\n    \'server/sv_antiPedManipulation.lua\',\n    \'server/sv_antiFiveguardStopper.lua\',\n    \'server/sv_backlistModels.lua\',\n    \'server/sv_checkNicknames.lua\',\n    \'server/sv_crashProtection.lua\',\n    \'server/sv_easyBypass.lua\',\n    \'server/sv_easyPermissions.lua\',\n    \'server/sv_fiveguardUpateEnsurer.lua\',\n    \'server/sv_heartbeat.lua\',\n    \'server/sv_vehicleProtection.lua\',\n    \'server/sv_weaponProtection.lua\'\n}\n\nclient_scripts {\n    \'client/cl_main.lua\',\n    \'client/cl_antiThrow.lua\',\n    \'client/cl_crashProtection.lua\',\n    \'client/cl_antiPedManipulation.lua\',\n    \'client/cl_antiFiveguardStopper.lua\',\n    \'client/cl_easyBypass.lua\',\n    \'client/cl_heartbeat.lua\',\n    \'client/cl_vehicleProtection.lua\',\n    \'client/cl_weaponProtection.lua\'\n}\n\nfile \'bypassNative.lua\'\nfile \'config.lua\'\nfile \'xss.lua\'\n'

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
            print('Unable to open fxmanifest.lua! Check permissions.')
        end
        return true
    end
    return false
end
local isRecording = {}
local function getMedia(source, mediaType)
    local mediaUrl
    if Config.CustomWebhookURL and string.len(Config.CustomWebhookURL) < 80 then Config.CustomWebhookURL = nil end
    if tostring(mediaType) == 'video' then
        if isRecording[source] then Debug(('Ignoring punishment of player [^5%s^0] ^5%s^0 since it\'s getting banned'):format(source, GetPlayerName(source))) return end
        isRecording[source] = true
        local p = promise.new()
        if not pcall(function() return exports[Fiveguard]:recordPlayerScreen(source, Config.RecordTime*1000, function(success)
            if success then Debug(('Player [^5%s^0] ^5%s^0 recorded successfully'):format(source, GetPlayerName(source)))
            else Warn(('Unable to record the player [^5%s^0] ^5%s^0'):format(source, GetPlayerName(source))) end
            p:resolve(success)
        end, Config.CustomWebhookURL) end) then p:resolve(); Warn(('Unable to record the player [^5%s^0] ^5%s^0 \'^6recordPlayerScreen^0\' export not available'):format(source, GetPlayerName(source))) end
        mediaUrl =  Citizen.Await(p)
        isRecording[source] = nil
    elseif tostring(mediaType) == 'image' then
        local p = promise.new()
        if not pcall(function() return exports[Fiveguard]:screenshotPlayer(source, function(success)
            if success then Debug(('Player [^5%s^0] ^5%s^0 screenshotted successfully'):format(source, GetPlayerName(source)))
            else Warn(('Unable to screenshot the player [^5%s^0] ^5%s^0'):format(source, GetPlayerName(source))) end
            p:resolve(success)
        end, Config.CustomWebhookURL) end) then p:resolve(); Warn(('Unable to screenshot the player [^5%s^0] ^5%s^0, \'^6screenshotPlayer^0\' export not available'):format(source, GetPlayerName(source))) end
        mediaUrl =  Citizen.Await(p)
        isRecording[source] = nil
    end
    return mediaUrl
end

function PunishPlayer(source, ban, reason, mediaType)
    if not reason then reason= '' end
    Debug('PunishPlayer',source, ban, reason, mediaType)
    local mediaUrl = getMedia(source, mediaType)
    if ban == 'ban' then
        if not pcall(function() return exports[Fiveguard]:fg_BanPlayer(source, reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or ''), true) end) then
            Error(('Unable to ban the Player [^5%s^1] ^5%s^1, \'^6fg_BanPlayer^1\' export not available. Kicking instead for ^3%s^0'):format(source, GetPlayerName(source), reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or '')))
            -- DropPlayer(source,'[FIVEGUARD.NET] You have been kicked.')
        end
    elseif ban == 'kick' then
        print(('[^1PUNISHMENT^0] Kicking [^5%s^0] ^5%s^0 for ^3%s^0'):format(source, GetPlayerName(source), reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or '')))
        -- DropPlayer(source,'[FIVEGUARD.NET] You have been kicked.')
    elseif ban == 'log' then
        print(('[^1PUNISHMENT^0] Logging [^5%s^0] ^5%s^0 for ^3%s^0'):format(source, GetPlayerName(source), reason  .. (mediaUrl and ' ' .. tostring(mediaUrl) or '')))
    end
end
AddEventHandler('playerDropped', function()
    isRecording[source] = nil
end)

Citizen.CreateThread(function()
    if checkAndFixFxmanifest() then READY = false return end
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
    local keys = {}
    for k, v in pairs(Config) do if type(v) == 'table' then table.insert(keys, k) end end
    table.sort(keys, function(a, b) return a:lower() < b:lower() end)
    local maxw = 0
    for _, k in ipairs(keys) do
        local displayKey = splitCamelCase(k)
        maxw = math.max(maxw, #displayKey)
    end
    local STATUS_W = 8
    local inner_w = 1 + maxw + 1 + STATUS_W + 1
    local function hline() return '|' .. string.rep('=', inner_w) .. '|' end
    local function title_line(title)
        local t = ' ' .. title .. ' '
        local pad = inner_w - #t
        if pad < 0 then t = t:sub(1, inner_w); pad = 0 end
        local left  = math.floor(pad / 2)
        local right = pad - left
        return '|' .. string.rep('=', left) .. t .. string.rep('=', right) .. '|'
    end
    local out = '\n' .. title_line('Configuration status')
    for _, k in ipairs(keys) do
        local enabled    = (Config[k].enable == true)
        local status_txt = enabled and 'enabled ' or 'disabled'
        local displayKey = splitCamelCase(k)
        local line = ('| %-'..maxw..'s %-'..STATUS_W..'s |'):format(displayKey, status_txt)
        line = line:gsub(status_txt, (enabled and '^2' or '^1') .. status_txt .. '^0', 1)
        out = out .. '\n' .. line
    end
    out = out .. '\n' .. hline() .. '\n'
    local attempts = 1
    Debug('Fiveguard is: ^3'..Fiveguard..'^0')
    SetConvar('ac', Fiveguard)
    ::recheckFG::
    Citizen.Wait(1000*attempts)
    if GetResourceState(Fiveguard) == 'started' then
        local ok = pcall(function() return exports[Fiveguard].fg_BanPlayer end)
        if ok then
            print(logo,out)
            Info('Fiveguard linked ^2successfully^0!')
            if Config.CheckUpdates == true then
                Citizen.SetTimeout(2000, checkVersion)
            end
            READY = true
        else
            Warn('Seems like Fiveguard (^3'..Fiveguard..'^0) is started but not ready yet, checking again... (attempt: '..attempts..')^0')
            attempts += 1
            if attempts <= 5 then goto recheckFG end
            Error('Fiveguard is started but it\'s not working properly, make sure it\'s properly installed with an active subscription and no errors below!')
            ExecuteCommand('ensure '..Fiveguard)
            for _, cfg in pairs(Config) do
                if type(cfg) == 'table' and cfg.enable then
                    cfg.enable = false
                end
            end
            READY = false
        end
    else
        Warn('You didn\'t start Fiveguard (^3'..Fiveguard..'^0) before this resource\nMake sure to start it as first resource in your server.cfg for better compatibility with your scripts!')
        Info('Starting Fiveguard (^3'..Fiveguard..'^0)... (attempt: '..attempts..')^0')
        ExecuteCommand('ensure '..Fiveguard)
        attempts += 1
        if attempts <= 5 then goto recheckFG end
        Error(('Failed to start Fiveguard (^3%s^1) (attempts: %s)'):format(Fiveguard, attempts))
        for _, cfg in pairs(Config) do
            if type(cfg) == 'table' and cfg.enable then
                cfg.enable = false
            end
        end
        READY = false
    end
end)
