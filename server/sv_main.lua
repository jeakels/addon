local data = LoadResourceFile(CurrentResourceName,'config.lua')
local Config = assert(load(data))()
READY = false
while not Fiveguard do Citizen.Wait(0) end

local function checkResourceNames()
    local forbiddenPatterns = {
    "fg",
    "ac",
    "anticheat",
    "fiveguard",
    "security",
    "guard",
    }
    local resourceName = string.lower(CurrentResourceName)
    for i = 1, #forbiddenPatterns do
        local pattern = string.lower(forbiddenPatterns[i])
        if string.find(resourceName, pattern) then
            Warn("The resource '" .. resourceName .. "' contains a forbidden pattern: '" .. pattern .. "'. Please change its name.")
        end
    end
end

local function checkVersion()
    local resName = GetInvokingResource() or GetCurrentResourceName()
    local version = GetResourceMetadata(resName, 'version', 0)

    if version then
        version = version:match("(%d+%.%d+%.%d+)")
    else
        Error("Can't read version")
        return
    end

    SetTimeout(1500, function()
        PerformHttpRequest("https://api.github.com/repos/jeakels/addon/releases/latest", function(code, body)
            if code ~= 200 or not body then return end

            local data = json.decode(body)
            if not data or data.prerelease then return end

            local latest = data.tag_name and data.tag_name:match("(%d+%.%d+%.%d+)")
            if not latest or latest == version then return end

            local function splitVersion(v)
                local t = {}
                for num in v:gmatch("%d+") do
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
                    Warn(("Update available (%s → %s) %s"):format(version, latest, data.html_url))
                    return
                elseif c > l then
                    return
                end
            end
        end, "GET")
    end)
end

local CORRECT_FXMANIFEST = [[fx_version 'cerulean'
game 'gta5'

author 'Community of fiveguard.net'
description 'Addon pack for fiveguard'
version "1.5.7"
lua54 'yes'
addon 'yes'

data_file "DLC_ITYP_REQUEST" "stream/mads_no_exp_pumps.ytyp"

shared_script 'shared.lua'

server_scripts {
    'server/sv_resourceManager.js',
    'server/sv_main.lua',
    'server/sv_antiExplosion.lua',
    'server/sv_antiThrow.lua',
    'server/sv_antiPedManipulation.lua',
    'server/sv_antiStopper.lua',
    'server/sv_backlistModels.lua',
    'server/sv_checkNicknames.lua',
    'server/sv_easyBypass.lua',
    'server/sv_easyPermissions.lua',
    'server/sv_heartbeat.lua',
    'server/sv_vehicleProtection.lua',
    'server/sv_weaponProtection.lua'
}

client_scripts {
    'client/cl_main.lua',
    'client/cl_antiThrow.lua',
    'client/cl_antiPedManipulation.lua',
    'client/cl_antiStopper.lua',
    'client/cl_easyBypass.lua',
    'client/cl_heartbeat.lua',
    'client/cl_vehicleProtection.lua',
    'client/cl_weaponProtection.lua'
}

file 'bypassNative.lua'
file 'config.lua'
file 'xss.lua'
]]

local function checkAndFixFxmanifest()
    local function simple_hash(s)
        if not s then return nil end
        local h1, h2 = 0, 0
        for i = 1, #s do
            local b = s:byte(i)
            h1 = (h1 + b) % 0x100000000
            h2 = (h2 * 31 + b) % 0x100000000
        end
        return string.format("%08x%08x", h1, h2)
    end
    local fxPath = "fxmanifest.lua"
    local currentContent = LoadResourceFile(CurrentResourceName, fxPath)

    local correctHash = simple_hash(CORRECT_FXMANIFEST)
    local currentHash = simple_hash(currentContent)

    if currentHash ~= correctHash then
        Warn("You've modified fxmanifest.lua, overwriting it with the correct version...")

        local resPath = GetResourcePath(CurrentResourceName)
        local fullPath = resPath .. "/" .. fxPath

        local file = io.open(fullPath, "w")
        if file then
            file:write(CORRECT_FXMANIFEST)
            file:close()
            Info("fxmanifest.lua successfully restored, restart "..CurrentResourceName.." to start!")
            ExecuteCommand("refresh")
        else
            print("Unable to open fxmanifest.lua! Check permissions.")
        end
        return true
    end
    return false
end
local isRecording = {}

function PunishPlayer(source, ban, reason, mediaType)
    if not reason then reason= "" end
    Debug("PunishPlayer",source, ban, reason, mediaType)
    if not ban then
        print(("Player kicked [^4%s^0] ^4%s^0 for %s"):format(source,GetPlayerName(source),reason))
        DropPlayer(source,"[FIVEGUARD.NET] You have been kicked")
        return
    end
    if tostring(mediaType) == "video" then
        if isRecording[source] then Debug(("Ignoring player ban since it's getting banned"):format())return end
        isRecording[source] = true
        if Config.CustomWebhookURL and string.len(Config.CustomWebhookURL) < 80 then
            Config.CustomWebhookURL = nil
        end
        exports[Fiveguard]:recordPlayerScreen(source, Config.RecordTime*1000, function(success)
            if success then
                reason = reason .. " "..tostring(success)
                Debug(("Player [^4%s^0] ^4%s^0 recorded successfully"):format(source,GetPlayerName(source)))
            else
                Warn(("Unable to record the player [^4%s^1] ^4%s^1"):format(source,GetPlayerName(source)))
            end
            exports[Fiveguard]:fg_BanPlayer(source, reason, true)
        end, Config.CustomWebhookURL)
    elseif tostring(mediaType) == "image" then
        exports[Fiveguard]:screenshotPlayer(source, function(success)
            if success then
                reason = reason .. " "..tostring(success)
                Debug(("Player [^4%s^0] ^4%s^0 screenshotted successfully"):format(source,GetPlayerName(source)))
            else
                Warn(("Unable to screenshot the player [^4%s^1] ^4%s^1"):format(source,GetPlayerName(source)))
            end
            exports[Fiveguard]:fg_BanPlayer(source, reason, true)
        end, Config.CustomWebhookURL)
    else
        exports[Fiveguard]:fg_BanPlayer(source, reason, true)
    end
end
AddEventHandler('playerDropped', function()
    isRecording[source] = nil
end)

Citizen.CreateThread(function()
    if checkAndFixFxmanifest() then
        READY = false
        return
    end
    print(([[
^3                                          dddddddd            dddddddd^0                                   
^3               AAA                        d::::::d            d::::::d^0                                   
^3              A:::A                       d::::::d            d::::::d^0                                   
^3             A:::::A                      d::::::d            d::::::d^0                                   
^3            A:::::::A                     d:::::d             d:::::d ^0                                   
^3           A:::::::::A            ddddddddd:::::d     ddddddddd:::::d ^0   ooooooooooo   nnnn  nnnnnnnn    
^3          A:::::A:::::A         dd::::::::::::::d   dd::::::::::::::d ^0 oo:::::::::::oo n:::nn::::::::nn  
^3         A:::::A A:::::A       d::::::::::::::::d  d::::::::::::::::d ^0o:::::::::::::::on::::::::::::::nn 
^3        A:::::A   A:::::A     d:::::::ddddd:::::d d:::::::ddddd:::::d ^0o:::::ooooo:::::onn:::::::::::::::n
^3       A:::::A     A:::::A    d::::::d    d:::::d d::::::d    d:::::d ^0o::::o     o::::o  n:::::nnnn:::::n
^3      A:::::AAAAAAAAA:::::A   d:::::d     d:::::d d:::::d     d:::::d ^0o::::o     o::::o  n::::n    n::::n
^3     A:::::::::::::::::::::A  d:::::d     d:::::d d:::::d     d:::::d ^0o::::o     o::::o  n::::n    n::::n
^3    A:::::AAAAAAAAAAAAA:::::A d:::::d     d:::::d d:::::d     d:::::d ^0o::::o     o::::o  n::::n    n::::n
^3   A:::::A             A:::::Ad::::::ddddd::::::ddd::::::ddddd::::::dd^0o:::::ooooo:::::o  n::::n    n::::n
^3  A:::::A               A:::::Ad:::::::::::::::::d d:::::::::::::::::d^0o:::::::::::::::o  n::::n    n::::n
^3 A:::::A                 A:::::Ad:::::::::ddd::::d  d:::::::::ddd::::d^0 oo:::::::::::oo   n::::n    n::::n
^3AAAAAAA                   AAAAAAAddddddddd   ddddd   ddddddddd   ddddd^0   ooooooooooo     nnnnnn    nnnnnn
version %s                                   By OffSey, Jeakels and contributors. Powered by ^3five^0guard]]):format(GetResourceMetadata(CurrentResourceName, "version", 0)))
    local function splitCamelCase(str)
        return (str:gsub("(%l)(%u)", "%1 %2"))
    end
    local keys = {}
    for k, v in pairs(Config) do
        if type(v) == "table" then table.insert(keys, k) end
    end
    table.sort(keys, function(a, b) return a:lower() < b:lower() end)
    local maxw = 0
    for _, k in ipairs(keys) do
        local displayKey = splitCamelCase(k)
        maxw = math.max(maxw, #displayKey)
    end
    local STATUS_W = 8
    local inner_w = 1 + maxw + 1 + STATUS_W + 1
    local function hline()
        return "|" .. string.rep("=", inner_w) .. "|"
    end
    local function title_line(title)
        local t = " " .. title .. " "
        local pad = inner_w - #t
        if pad < 0 then t = t:sub(1, inner_w); pad = 0 end
        local left  = math.floor(pad / 2)
        local right = pad - left
        return "|" .. string.rep("=", left) .. t .. string.rep("=", right) .. "|"
    end
    local out = "\n" .. title_line("Fiveguard Addon")
    for _, k in ipairs(keys) do
        local enabled    = (Config[k].enable == true)
        local status_txt = enabled and "enabled " or "disabled"
        local displayKey = splitCamelCase(k)
        local line = ("| %-"..maxw.."s %-"..STATUS_W.."s |"):format(displayKey, status_txt)
        line = line:gsub(status_txt, (enabled and "^2" or "^1") .. status_txt .. "^0", 1)
        out = out .. "\n" .. line
    end
    out = out .. "\n" .. hline() .. "\n"
    checkResourceNames()
    if Config.CheckUpdates == true then
        Citizen.SetTimeout(2000, checkVersion)
    end
    local attempts = 1
    Debug('Fiveguard is: ^3'..Fiveguard..'^0')
    SetConvar('ac', Fiveguard)
    ::recheckFG::
    if GetResourceState(Fiveguard) == 'started' then
        Citizen.Wait(2000)
        READY = true
        Info('Fiveguard linked ^2successfully^0!')
        print(out)
    else
        StartResource(Fiveguard)
        Error('Seems like you didn\'t start ^3'..Fiveguard..'^1 before this resource\nMake sure to start ^3'..Fiveguard..'^1 as first resource in your server.cfg for better compatibility with your scripts!')
        Info('Trying to start ^3'..Fiveguard..'^0 (attempt: '..attempts..')^0')
        attempts += 1
        if attempts < 3 then goto recheckFG end
        Error(('Failed to start ^3%s^1 (attempts: %s)'):format(Fiveguard, attempts))
        for _, cfg in pairs(Config) do
            if type(cfg) == "table" and cfg.enable then
                cfg.enable = false
                READY = false
            end
        end
    end
end)

