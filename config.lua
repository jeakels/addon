return {
    Debug = false,
    CustomMediaWebhookURL = 'https://discord.com/api/webhooks/URL', -- Discord webhook URL to store video or images, if not configured will be used the default screenshot webhook url on your fiveguard config
    RecordTime = 5, -- (seconds)
    CheckUpdates = true, -- RECOMMENDED Enable this to be notified when an update is available!
    fiveguardUpdateEnsurer = {
        enable = true -- Automatically restarts fiveguard when an update is installed avoid exposing your server without anticheat, remember that this can crash server/players since restarting resources runtime is not reccomended (manually or by scripts or wathever).
    },
    heartbeat = {
        enable = true,      -- prevent cheaters to stop client side of this resource
        joinGrace = 45,     -- Seconds ignored after the player spawned
        threadTime = 5,     -- Interval between heartbeats (seconds)
        graceMisses = 3,    -- How many consecutive misses are tolerated before punishment
        tokenExpiry = 10,   -- Token expiry time (seconds)
        punishment = 'kick' -- ban/kick/log
    },
    crashProtection = {
        enable = true,      -- prevent cheaters to crash players
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image', -- 'image', 'video' or 'false'
        handleJumpExploit = true,
        vehicleOwnerExploit = true
    },
    checkNicknames = {
        enable = false,         -- block players that don't follow the allowed characters
        minNicknameLength = 3,  -- Minimum lenght of palyer nicknames, set false to disable
        maxNicknameLength = 25, -- Maximum lenght of palyer nicknames, set false to disable
        allowedPattern = '^[A-Za-z0-9_.%-%s]+$' -- Allowed characters, set false to disable
    },
    antiFiveguardStopper = {
        enable = true,      -- Detect if someone try to stop fiveguard
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image', -- image/video/false
        checkInterval = 5   -- interval in seconds
    },
    vehicleProtection = { -- Credit: @jona0081 for some detections included here
        enable = true,
        punishment = 'log', -- ban/kick/log
        banMedia = 'image', -- image/video/false
        detectNPC = false,  -- Can spawn client side event
        cleanNotOwnedVehicles = false,
        preventSafeSpawn = {
            enable = true,
            whitelistedCoords = {
                { coords = vec3(-47.500000, -1097.199951, 25.400000), radius = 2.0 },
                { coords = vec3(519.2477, -2618.788, -50.000), radius = 20.0 }
            },
        },
        preventAttachVehicles = false,    -- !!Can make false detections
        preventLaunchPlayer = false,      -- !!Can make false detections
        preventInvalidOwner = false,      -- !!Can make false detections
        preventNilResource = false,       -- !!Can make false detections
        preventUnNetworkedEntity = false, -- !!Can make false detections
        maxVehicleCheckDistance = 50,
        checkInterval = 5
    },
    weaponProtection = {
        enable = true,
        inventorySync = true, -- Disarm held weapons missing from the synced inventory.
        AntiGiveWeapon = { -- Credit: @locutor404 & @somis12
            enable = true,
            relaxed = true,    -- determinate if check every shot or no
            punishment = 'ban', -- ban/kick/log
            banMedia = 'image'  -- image/video/false
        },
        AntiDistanceDamage = {
            punishment = 'ban', -- ban/kick/log
            banMedia = 'image',
            punch = {
                enable = true,
                maxDistance = 16
            },
            stungun = {
                enable = true,
                maxDistance = 13
            }
        }
    },
    easyBypass = {
        enable = true,   -- Allows players to get a bypass directly by native execution on installed resources or when a event configured is triggered
        verbose = false, -- if true, prints are more detailed and don't warn if player already have permission
        onClientTrigger = {
            --[[
                Use this for client-client events ( TriggerEvent )

                1) Event to enable + event to disable:
                ['event:start'] = {
                    enable = true,
                    endEvent = 'event:end',
                    bypass = 'BypassName'
                },

                2) Same event sends true/false:
                ['event:switch'] = {
                    enable = true,
                    endEvent = 'event:switch',
                    bypass = 'BypassName'
                },

                3) No disable event, remove after X seconds:
                ['event:timed'] = {
                    enable = true,
                    endEvent = false,
                    bypass = 'BypassName'
                },

                Multiple bypasses:
                bypass = { 'Bypass1', 'Bypass2' }
            ]]
            ['jg-advancedgarages:client:open-garage'] = {
                enable = GetResourceState('jg-advancedgarages') ~= 'missing',
                endEvent = 'jg-advancedgarages:client:store-vehicle',
                bypass = 'BypassVehicleModifier'
            },
            ['jg-dealerships:client:open-showroom'] = {
                enable = GetResourceState('jg-dealerships') ~= 'missing',
                endEvent = '__ox_cb_jg-dealerships:server:exit-showroom',
                bypass = { 'BypassInvisible', 'BypassTeleport', 'BypassVehicleModifier' }
            },
            ['rcore_clothing:onClothingShopOpened'] = {
                enable = GetResourceState('rcore_clothing') ~= 'missing',
                endEvent = 'rcore_clothing:onClothingShopClosed',
                bypass = 'BypassStealOutfit'
            },
            ['ik-jobgarage:openUI'] = {
                enable = GetResourceState('ik-jobgarage') ~= 'missing',
                endEvent = 'ik-jobgarage:server:SaveCarData',
                bypass = 'BypassInvisible'
            },
            ['prison:client:Enter'] = {
                enable = GetResourceState('qb-prison') ~= 'missing',
                endEvent = false,
                bypass = 'BypassTeleport'
            },
            ['prison:client:Leave'] = {
                enable = GetResourceState('qb-prison') ~= 'missing',
                endEvent = false,
                bypass = 'BypassTeleport'
            },
            ['prison:client:UnjailPerson'] = {
                enable = GetResourceState('qb-prison') ~= 'missing',
                endEvent = false,
                bypass = 'BypassTeleport'
            },
            ['jg-mechanic:client:open-customisation-menu'] = {
                enable = GetResourceState('jg-mechanic') ~= 'missing',
                endEvent = false,
                duration = 10,
                bypass = { 'BypassVehicleModifier', 'BypassBulletproofTires' }
            },
        },
        onServerTrigger = {
            --[[
                Use isNet = false for server-server events ( TriggerEvent )
                Use isNet = true  for client-server events ( TriggerServerEvent )

                1) Event to enable + event to disable:
                ['event:start'] = {
                    enable = true,
                    isNet = false,
                    endEvent = 'event:end',
                    bypass = 'BypassName'
                },

                2) Same event sends true/false:
                ['event:switch'] = {
                    enable = true,
                    isNet = false,
                    endEvent = 'event:switch',
                    bypass = 'BypassName'
                },

                3) No disable event, remove after X seconds:
                ['event:timed'] = {
                    enable = true,
                    isNet = false,
                    endEvent = false,
                    bypass = 'BypassName'
                },

                Multiple bypasses:
                bypass = { 'Bypass1', 'Bypass2' }
            ]]
            ['rtx_themepark:Global:UsingAttractionPlayer'] = {
                enable = GetResourceState('rtx_themepark') ~= 'missing',
                isNet = true,
                endEvent = 'rtx_themepark:Global:UsingAttractionPlayer',
                bypass = { 'BypassNoclip', 'BypassSpoofedWeapons', 'BypassBulletproofTires' }
            },
            ['rtx_mazebankattractions:UsingAttractionHandler'] = {
                enable = GetResourceState('rtx_mazebank_themepark') ~= 'missing',
                isNet = true,
                endEvent = 'rtx_mazebankattractions:UsingAttractionHandler',
                bypass = 'BypassNoclip'
            },
            ['rtx_waterpark:UseWaterSlideClient'] = {
                enable = GetResourceState('rtx_waterpark') ~= 'missing',
                isNet = true,
                endEvent = 'rtx_waterpark:UseWaterSlideClient',
                bypass = 'BypassNoclip'
            },
            ['rtx_waterpark_roxwood:UseWaterSlideClient'] = {
                enable = GetResourceState('rtx_waterpark_roxwood') ~= 'missing',
                isNet = true,
                endEvent = 'rtx_waterpark_roxwood:UseWaterSlideClient',
                bypass = 'BypassNoclip'
            },
            ['rtx_spawnableattractions:Global:AttractionUsing'] = {
                enable = GetResourceState('rtx_spawnableattractions') ~= 'missing',
                isNet = true,
                endEvent = 'rtx_spawnableattractions:Global:AttractionUsing',
                bypass = 'BypassNoclip'
            },
            ['lsrp_lunapark:Freefall:attachPlayer'] = {
                enable = GetResourceState('lsrp_lunapark') ~= 'missing',
                endEvent = 'lsrp_lunapark:Freefall:detachPlayer',
                bypass = 'BypassNoclip',
            },
            ['lsrp_lunapark:RollerCoaster:attachPlayer'] = {
                enable = GetResourceState('lsrp_lunapark') ~= 'missing',
                endEvent = 'lsrp_lunapark:RollerCoaster:detachPlayer',
                bypass = 'BypassNoclip'
            },
            ['lsrp_lunapark:Wheel:attachPlayer'] = {
                enable = GetResourceState('lsrp_lunapark') ~= 'missing',
                endEvent = 'lsrp_lunapark:Wheel:detachPlayer',
                bypass = 'BypassNoclip',
            },
            ['rcore_prison:server:prologStarted'] = {
                enable = GetResourceState('rcore_prison') ~= 'missing',
                endEvent = 'rcore_prison:server:prologFinished',
                bypass = 'BypassStealOutfit'
            },
            ['wasabi_police:sendToJail'] = {
                enable = GetResourceState('wasabi_police') ~= 'missing',
                endEvent = false,
                duration = 10,
                bypass = 'BypassTeleport'
            },
            ['jg-mechanic:server:startHandlingEdit'] = {
                enable = GetResourceState('jg-mechanic') ~= 'missing',
                endEvent = 'jg-mechanic:server:finishHandlingEdit',
                bypass = {'BypassVehicleHandlingEdit','BypassVehicleModifier', 'BypassVehicleFixAndGodMode'}
            },
            ['jg-mechanic:server:sync-vehicle-repair'] = {
                enable = GetResourceState('jg-mechanic') ~= 'missing',
                endEvent = false,
                bypass = 'BypassVehicleFixAndGodMode'
            },
        },
        wrapNatives = { -- it will use the module bypassNative to detect autmatically if a script need to set a player invisible or teleport him
            -- It enable:
                -- exports['addon']:SafeSetEntityCoords(playerId, true --[[ or false ]], GetCurrentResourceName())
                --TriggerServerEvent('fg:addon:SetTempPermission:BypassTeleport', true --[[ or false ]], GetCurrentResourceName())
            SetEntityCoords = true,
            -- It enable:
                -- exports['addon']:SafeSetEntityVisible(playerId, true --[[ or false ]], GetCurrentResourceName())
                --TriggerServerEvent('fg:addon:SetTempPermission:BypassInvisible', true --[[ or false ]], GetCurrentResourceName())
            SetEntityVisible = true,
            -- It enable:
                -- exports['addon']:SafeSetEntityVisible(playerId, true --[[ or false ]], GetCurrentResourceName())
                -- TriggerServerEvent('fg:addon:SetTempPermission:BypassVehicleFixAndGodMode', true --[[ or false ]], GetCurrentResourceName())
            SetVehicleFixed = true,
            -- It enable:
                -- exports['addon']:SafeSetPedComponentVariation(playerId, true --[[ or false ]], GetCurrentResourceName())
                -- TriggerServerEvent('fg:addon:SetTempPermission:BypassStealOutfit', true --[[ or false ]], GetCurrentResourceName())
            SetPedComponentVariation = true,
        }
    },
    easyPermissions = {
        enable = true, --  Do not use multple permission system at same time! On conflicts txAdmin will be used.
        DiscordPermissions = { -- On joining discord permission system
            enable = false,
            --[[ To get a token and the bot to join your server, follow these two guides:
            Setting up a bot -> https://discordjs.guide/legacy/preparations/app-setup and
            Adding your bot to servers -> https://discordjs.guide/legacy/preparations/adding-your-app
            NOTE: The bot doesn't need any permission to work
            ]]
            botToken = '', -- Create your App -> https://discord.com/developers/applications
            guildId = 'auto', -- Auto requires exactly one guild; otherwise specify its ID as a string.
            users = { -- Users take precedence over roles.
                -- ['192000425828810752'] = { 'AdminMenuAccess', 'AnnouncementAccess', 'VisualsAccess', 'EntityCleanupAccess', 'PlayerModerationAccess', 'PlayerTeleportAccess', 'VehicleAccess', 'SelfAccess', 'QuickTeleportAccess', 'WorldAccess', 'WeaponAccess', 'PlayersAccess', 'PlayerManagementAccess', 'SpectateAccess', 'ScreenshotAccess', 'MonitorAccess', 'OfflinePlayersAccess', 'FreecamAccess', 'LogsAccess', 'PlayerSelectorAccess', 'BanListAccess', 'PedModelsAccess', 'BypassSpectate', 'BypassGodMode', 'BypassInvisible', 'BypassStealOutfit', 'BypassInfStamina', 'BypassNoclip', 'BypassSuperJump', 'BypassFreecam', 'BypassSpeedHack', 'BypassTeleport', 'BypassNightVision', 'BypassThermalVision', 'BypassExplosiveAmmo', 'BypassOCR', 'BypassNuiDevtools', 'BypassBlacklistedTextures', 'BlipsBypass', 'BypassCbScanner', 'BypassSpoofedBulletShot', 'BypassWeaponDmgModifier', 'BypassInfAmmo', 'BypassNoReload', 'BypassRapidFire', 'BypassVehicleFixAndGodMode', 'BypassVehicleHandlingEdit', 'BypassVehicleModifier', 'BypassBulletproofTires', 'BypassVehiclePlateChanger', 'BypassModelChanger', 'BypassWeaponBlacklist', 'FGCommands', 'BypassVPN', 'BypassExplosion', 'BypassClearTasks', 'BypassParticle', 'BypassSpoofedWeapons' },
                -- ['234567890123456789'] = { 'SpectateAccess' },
            },
            roles = { -- Highest priority FIRST. One ID per table; only the first matching role grants permissions.
                -- { ['345678901234567890'] = { 'AdminMenuAccess', 'AnnouncementAccess', 'VisualsAccess', 'EntityCleanupAccess', 'PlayerModerationAccess', 'PlayerTeleportAccess', 'VehicleAccess', 'SelfAccess', 'QuickTeleportAccess', 'WorldAccess', 'WeaponAccess', 'PlayersAccess', 'PlayerManagementAccess', 'SpectateAccess', 'ScreenshotAccess', 'MonitorAccess', 'OfflinePlayersAccess', 'FreecamAccess', 'LogsAccess', 'PlayerSelectorAccess', 'BanListAccess', 'PedModelsAccess', 'BypassSpectate', 'BypassGodMode', 'BypassInvisible', 'BypassStealOutfit', 'BypassInfStamina', 'BypassNoclip', 'BypassSuperJump', 'BypassFreecam', 'BypassSpeedHack', 'BypassTeleport', 'BypassNightVision', 'BypassThermalVision', 'BypassExplosiveAmmo', 'BypassOCR', 'BypassNuiDevtools', 'BypassBlacklistedTextures', 'BlipsBypass', 'BypassCbScanner', 'BypassSpoofedBulletShot', 'BypassWeaponDmgModifier', 'BypassInfAmmo', 'BypassNoReload', 'BypassRapidFire', 'BypassVehicleFixAndGodMode', 'BypassVehicleHandlingEdit', 'BypassVehicleModifier', 'BypassBulletproofTires', 'BypassVehiclePlateChanger', 'BypassModelChanger', 'BypassWeaponBlacklist', 'FGCommands', 'BypassVPN', 'BypassExplosion', 'BypassClearTasks', 'BypassParticle', 'BypassSpoofedWeapons' } },
                -- { ['456789012345678901'] = { 'SpectateAccess' } },
            }
        },
        txAdminPermissions = {
            enable = true,   -- Bypass txAdmin admins
            fgPermissions = { -- Permissions that'll be set if player has TxAdmin Access
            --[[ AdminMenu ]] --
                'AdminMenuAccess',
                'AnnouncementAccess',
                'VisualsAccess',
                'EntityCleanupAccess',
                'PlayerModerationAccess',
                'PlayerTeleportAccess',
                'VehicleAccess',
                'SelfAccess',
                'QuickTeleportAccess',
                'WorldAccess',
                'WeaponAccess',
                'PlayersAccess',
                'PlayerManagementAccess',
                'SpectateAccess',
                'ScreenshotAccess',
                'MonitorAccess',
                'OfflinePlayersAccess',
                'FreecamAccess',
                'LogsAccess',
                'PlayerSelectorAccess',
                'BanListAccess',
                'PedModelsAccess',
            --[[ Client ]] --
                'BypassSpectate',
                'BypassGodMode',
                'BypassInvisible',
                'BypassStealOutfit',
                'BypassInfStamina',
                'BypassNoclip',
                'BypassSuperJump',
                'BypassFreecam',
                'BypassSpeedHack',
                'BypassTeleport',
                'BypassNightVision',
                'BypassThermalVision',
                'BypassExplosiveAmmo',
                'BypassOCR',
                'BypassNuiDevtools',
                'BypassBlacklistedTextures',
                'BlipsBypass',
                'BypassCbScanner',
                'BypassSpoofedBulletShot',
            --[[ Weapon ]] --
                'BypassWeaponDmgModifier',
                'BypassInfAmmo',
                'BypassNoReload',
                'BypassRapidFire',
            --[[ Vehicle ]] --
                'BypassVehicleFixAndGodMode',
                'BypassVehicleHandlingEdit',
                'BypassVehicleModifier',
                'BypassBulletproofTires',
                'BypassVehiclePlateChanger',
            --[[ Blacklist ]] --
                'BypassModelChanger',
                'BypassWeaponBlacklist',
            --[[ Misc ]] --
                'FGCommands',
                'BypassVPN',
                'BypassExplosion',
                'BypassClearTasks',
                'BypassParticle',
                'BypassSpoofedWeapons',
            }
        },
        FrameworkPermissions = {
            enable = false, -- Use framework permission to determinate when add or remove fg perms
            customFramework = {
                enable = false, -- enable this only if u have a custom settings and u know what u are doing
                customEvent = '', -- name of the events that's triggered when a player get/lose a group
                invokerResource = '' -- name of the resource that's triggers the event (security check)
            },
            groups = {
                ['god'] = {
                --[[ AdminMenu ]] --
                    'AdminMenuAccess',
                    'AnnouncementAccess',
                    'VisualsAccess',
                    'EntityCleanupAccess',
                    'PlayerModerationAccess',
                    'PlayerTeleportAccess',
                    'VehicleAccess',
                    'SelfAccess',
                    'QuickTeleportAccess',
                    'WorldAccess',
                    'WeaponAccess',
                    'PlayersAccess',
                    'PlayerManagementAccess',
                    'SpectateAccess',
                    'ScreenshotAccess',
                    'MonitorAccess',
                    'OfflinePlayersAccess',
                    'FreecamAccess',
                    'LogsAccess',
                    'PlayerSelectorAccess',
                    'BanListAccess',
                    'PedModelsAccess',
                --[[ Client ]] --
                    'BypassSpectate',
                    'BypassGodMode',
                    'BypassInvisible',
                    'BypassStealOutfit',
                    'BypassInfStamina',
                    'BypassNoclip',
                    'BypassSuperJump',
                    'BypassFreecam',
                    'BypassSpeedHack',
                    'BypassTeleport',
                    'BypassNightVision',
                    'BypassThermalVision',
                    'BypassExplosiveAmmo',
                    'BypassOCR',
                    'BypassNuiDevtools',
                    'BypassBlacklistedTextures',
                    'BlipsBypass',
                    'BypassCbScanner',
                    'BypassSpoofedBulletShot',
                --[[ Weapon ]] --
                    'BypassWeaponDmgModifier',
                    'BypassInfAmmo',
                    'BypassNoReload',
                    'BypassRapidFire',
                --[[ Vehicle ]] --
                    'BypassVehicleFixAndGodMode',
                    'BypassVehicleHandlingEdit',
                    'BypassVehicleModifier',
                    'BypassBulletproofTires',
                    'BypassVehiclePlateChanger',
                --[[ Blacklist ]] --
                    'BypassModelChanger',
                    'BypassWeaponBlacklist',
                --[[ Misc ]] --
                    'FGCommands',
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle',
                    'BypassSpoofedWeapons',
                },
                ['admin'] = {
                --[[ AdminMenu ]] --
                    'AdminMenuAccess',
                    'AnnouncementAccess',
                    'VisualsAccess',
                    'EntityCleanupAccess',
                    'PlayerModerationAccess',
                    'PlayerTeleportAccess',
                    'VehicleAccess',
                    'SelfAccess',
                    'QuickTeleportAccess',
                    'WorldAccess',
                    'WeaponAccess',
                    'PlayersAccess',
                    'PlayerManagementAccess',
                    'SpectateAccess',
                    'ScreenshotAccess',
                    'MonitorAccess',
                    'OfflinePlayersAccess',
                    'FreecamAccess',
                    'LogsAccess',
                    'PlayerSelectorAccess',
                    'BanListAccess',
                    'PedModelsAccess',
                --[[ Client ]] --
                    'BypassSpectate',
                    'BypassGodMode',
                    'BypassInvisible',
                    'BypassStealOutfit',
                    'BypassInfStamina',
                    'BypassNoclip',
                    'BypassSuperJump',
                    'BypassFreecam',
                    'BypassSpeedHack',
                    'BypassTeleport',
                    'BypassNightVision',
                    'BypassThermalVision',
                    'BypassExplosiveAmmo',
                    'BypassOCR',
                    'BypassNuiDevtools',
                    'BypassBlacklistedTextures',
                    'BlipsBypass',
                    'BypassCbScanner',
                    'BypassSpoofedBulletShot',
                --[[ Weapon ]] --
                    'BypassWeaponDmgModifier',
                    'BypassInfAmmo',
                    'BypassNoReload',
                    'BypassRapidFire',
                --[[ Vehicle ]] --
                    'BypassVehicleFixAndGodMode',
                    'BypassVehicleHandlingEdit',
                    'BypassVehicleModifier',
                    'BypassBulletproofTires',
                    'BypassVehiclePlateChanger',
                --[[ Blacklist ]] --
                    'BypassModelChanger',
                    'BypassWeaponBlacklist',
                --[[ Misc ]] --
                    'FGCommands',
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle',
                    'BypassSpoofedWeapons',
                },
                ['mod'] = {
                --[[ Client ]] --
                    'BypassSpectate',
                    'BypassGodMode',
                    'BypassInvisible',
                    'BypassStealOutfit',
                    'BypassInfStamina',
                    'BypassNoclip',
                    'BypassSuperJump',
                    'BypassFreecam',
                    'BypassSpeedHack',
                    'BypassTeleport',
                    'BypassNightVision',
                    'BypassThermalVision',
                    'BypassOCR',
                    'BypassNuiDevtools',
                    'BypassBlacklistedTextures',
                    'BlipsBypass',
                    'BypassCbScanner',
                --[[ Weapon ]] --
                    'BypassWeaponDmgModifier',
                    'BypassInfAmmo',
                    'BypassNoReload',
                    'BypassRapidFire',
                --[[ Vehicle ]] --
                    'BypassVehicleFixAndGodMode',
                    'BypassVehicleHandlingEdit',
                    'BypassVehicleModifier',
                    'BypassBulletproofTires',
                --[[ Blacklist ]] --
                    'BypassModelChanger',
                    'BypassWeaponBlacklist',
                --[[ Misc ]] --
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
                },
                ['helper'] = {
                --[[ Client ]] --
                    'BypassSpectate',
                    'BypassGodMode',
                    'BypassInvisible',
                    'BypassStealOutfit',
                    'BypassInfStamina',
                    'BypassNoclip',
                    'BypassSuperJump',
                    'BypassFreecam',
                    'BypassSpeedHack',
                    'BypassTeleport',
                    'BypassNightVision',
                    'BypassThermalVision',
                    'BypassOCR',
                    'BypassNuiDevtools',
                    'BypassBlacklistedTextures',
                    'BlipsBypass',
                    'BypassCbScanner',
                --[[ Vehicle ]] --
                    'BypassVehicleFixAndGodMode',
                    'BypassVehicleHandlingEdit',
                    'BypassVehicleModifier',
                    'BypassBulletproofTires',
                --[[ Misc ]] --
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
                }
            }
        },
        AcePermissions = {  -- Use ACE Permissions from FiveM natives
            enable = false,
            groups = {      -- define wich perms you want to add for a specific group u granted to your admins
                ['admin'] = {
                --[[ AdminMenu ]] --
                    'AdminMenuAccess',
                    'AnnouncementAccess',
                    'VisualsAccess',
                    'EntityCleanupAccess',
                    'PlayerModerationAccess',
                    'PlayerTeleportAccess',
                    'VehicleAccess',
                    'SelfAccess',
                    'QuickTeleportAccess',
                    'WorldAccess',
                    'WeaponAccess',
                    'PlayersAccess',
                    'PlayerManagementAccess',
                    'SpectateAccess',
                    'ScreenshotAccess',
                    'MonitorAccess',
                    'OfflinePlayersAccess',
                    'FreecamAccess',
                    'LogsAccess',
                    'PlayerSelectorAccess',
                    'BanListAccess',
                    'PedModelsAccess',
                --[[ Client ]] --
                    'BypassSpectate',
                    'BypassGodMode',
                    'BypassInvisible',
                    'BypassStealOutfit',
                    'BypassInfStamina',
                    'BypassNoclip',
                    'BypassSuperJump',
                    'BypassFreecam',
                    'BypassSpeedHack',
                    'BypassTeleport',
                    'BypassNightVision',
                    'BypassThermalVision',
                    'BypassExplosiveAmmo',
                    'BypassOCR',
                    'BypassNuiDevtools',
                    'BypassBlacklistedTextures',
                    'BlipsBypass',
                    'BypassCbScanner',
                    'BypassSpoofedBulletShot',
                --[[ Weapon ]] --
                    'BypassWeaponDmgModifier',
                    'BypassInfAmmo',
                    'BypassNoReload',
                    'BypassRapidFire',
                --[[ Vehicle ]] --
                    'BypassVehicleFixAndGodMode',
                    'BypassVehicleHandlingEdit',
                    'BypassVehicleModifier',
                    'BypassBulletproofTires',
                    'BypassVehiclePlateChanger',
                --[[ Blacklist ]] --
                    'BypassModelChanger',
                    'BypassWeaponBlacklist',
                --[[ Misc ]] --
                    'FGCommands',
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle',
                    'BypassSpoofedWeapons',
                },
                ['mod'] = {
                --[[ Client ]] --
                    'BypassSpectate',
                    'BypassGodMode',
                    'BypassInvisible',
                    'BypassStealOutfit',
                    'BypassInfStamina',
                    'BypassNoclip',
                    'BypassSuperJump',
                    'BypassFreecam',
                    'BypassSpeedHack',
                    'BypassTeleport',
                    'BypassNightVision',
                    'BypassThermalVision',
                    'BypassOCR',
                    'BypassNuiDevtools',
                    'BypassBlacklistedTextures',
                    'BlipsBypass',
                    'BypassCbScanner',
                --[[ Weapon ]] --
                    'BypassWeaponDmgModifier',
                    'BypassInfAmmo',
                    'BypassNoReload',
                    'BypassRapidFire',
                --[[ Vehicle ]] --
                    'BypassVehicleFixAndGodMode',
                    'BypassVehicleHandlingEdit',
                    'BypassVehicleModifier',
                    'BypassBulletproofTires',
                --[[ Blacklist ]] --
                    'BypassModelChanger',
                    'BypassWeaponBlacklist',
                --[[ Misc ]] --
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
                },
                ['helper'] = {
                --[[ Client ]] --
                    'BypassSpectate',
                    'BypassGodMode',
                    'BypassInvisible',
                    'BypassStealOutfit',
                    'BypassInfStamina',
                    'BypassNoclip',
                    'BypassSuperJump',
                    'BypassFreecam',
                    'BypassSpeedHack',
                    'BypassTeleport',
                    'BypassNightVision',
                    'BypassThermalVision',
                    'BypassOCR',
                    'BypassNuiDevtools',
                    'BypassBlacklistedTextures',
                    'BlipsBypass',
                    'BypassCbScanner',
                --[[ Vehicle ]] --
                    'BypassVehicleFixAndGodMode',
                    'BypassVehicleHandlingEdit',
                    'BypassVehicleModifier',
                    'BypassBulletproofTires',
                --[[ Misc ]] --
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
                }
            }
        }
    }
}
