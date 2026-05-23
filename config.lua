return {
    Debug = false,
    CustomWebhookURL = 'https://discord.com/api/webhooks/URL', -- Discord webhook URL to store video or images, if not configured will be used the default screenshot webhook url on your fiveguard config
    RecordTime = 5, -- (seconds)
    CheckUpdates = true, -- RECOMMENDED Enable this to be notified when an update is available!
    FiveguardUpdateEnsurer = {
        enable = true -- Automatically restarts fiveguard when an update is installed avoiding downtimes, remember that this can crash players since restarting resources runtime is not reccomended (manual or by scripts or wathever).
    },
    Heartbeat = {
        enable = true,      -- prevent cheaters to stop client side of this resource
        joinGrace = 30,     -- Seconds ignored after the player spawned
        threadTime = 5,     -- Interval between heartbeats (seconds)
        graceMisses = 3,    -- How many consecutive misses are tolerated before punishment
        tokenExpiry = 10,   -- Token expiry time (seconds)
        punishment = 'kick' -- ban/kick/log
    },
    CrashProtection = {
        enable = true,      -- prevent cheaters to crash players
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image', -- 'image', 'video' or 'false'
        preventLumia = true,
        preventPneumaticHammer = true,
        preventTableGolfSummer = true,
        preventNewCrashMethod = true,
        preventFootIK = true,
        preventSouthMenu = true
    },
    AntiThrow = {
        enable = true,      -- prevent cheaters to take and launch vehicles
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image', -- image/video/false
        whitelistedZones = {
            -- { -- EXAMPLE
            --     coords = vector3(0, 0, 0),
            --     radius = 100.0
            -- },
            GetResourceState('rtx_themepark') ~= 'missing' and { --JUST A WHITELIST FOR A SPECIFIC SCRIPT
                coords = vector3(-1659.5439, -1102.4888, 13.1184),  -- RTX ThemePark (Beach ThemePark)
                radius = 150.0
            } or nil
        }
    },
    CheckNicknames = {
        enable = false,         -- block players that don't follow the allowed characters
        minNicknameLength = 3,  -- Minimum lenght of palyer nicknames, set false to disable
        maxNicknameLength = 25, -- Maximum lenght of palyer nicknames, set false to disable
        allowedPattern = '^[A-Za-z0-9_.%-%s]+$' -- Allowed characters, set false to disable
    },
    AntiFiveguardStopper = {
        enable = true,      -- Detect if someone try to stop fiveguard
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image', -- image/video/false
        checkInterval = 5   -- interval in seconds
    },
    AntiPedManipulation = { -- Credit: @somis12
        -- If it gives you false bans, change the "true" below to "false" (enable = true / enable = false).
        -- NOTE: The system will still activate ONLY if onesync_population is disabled.
        enable = true and not GetConvarBool("onesync_population", true),
        maxBucketUsed = 15000,
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image' -- image/video/false
    },
    VehicleProtection = { -- Credit: @jona0081 for some detections included here
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
        checkInterval = 5,
        preventUnauthorizedResource = {
            enable = false,               -- If enabled, whitelist your resources below
            resourceWhitelisted = {
                ['monitor']             = GetResourceState('monitor') ~= 'missing',
                ['es_extended']         = GetResourceState('es_extended') ~= 'missing',
                ['esx_vehicleshop']     = GetResourceState('esx_vehicleshop') ~= 'missing',
                ['esx_garages']         = GetResourceState('esx_garages') ~= 'missing',
                ['qb-core']             = GetResourceState('qb-core') ~= 'missing',
                ['qb-vehicleshop']      = GetResourceState('qb-vehicleshop') ~= 'missing',
                ['qb-garages']          = GetResourceState('qb-garages') ~= 'missing',
                ['qbx_core']            = GetResourceState('qbx_core') ~= 'missing',
                ['ox_lib']              = GetResourceState('ox_lib') ~= 'missing',
                ['jg-advancedgarages']  = GetResourceState('jg-advancedgarages') ~= 'missing',
                ['okokGarage']          = GetResourceState('okokGarage') ~= 'missing',
                ['okokVehicleShop']     = GetResourceState('okokVehicleShop') ~= 'missing',
                ['cd_garage']           = GetResourceState('cd_garage') ~= 'missing',
                ['loaf_garage']         = GetResourceState('loaf_garage') ~= 'missing',
                ['rcore_garage']        = GetResourceState('rcore_garage') ~= 'missing',
                ['codem-garage']        = GetResourceState('codem-garage') ~= 'missing',
                ['qs-smartphone-pro']   = GetResourceState('qs-smartphone-pro') ~= 'missing',
                ['qs-smartphone']       = GetResourceState('qs-smartphone') ~= 'missing',
                ['lb-phone']            = GetResourceState('lb-phone') ~= 'missing',
                ['okokPhone']           = GetResourceState('okokPhone') ~= 'missing',
            }
        },
    },
    WeaponProtection = {
        enable = true,
        AntiGiveWeapon = { -- Credit: @locutor404 & @somis12
            enable = true,
            relaxed = false,    -- determinate if check every shot or no
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
        },
        AntiGiveWeaponToPed = {
            enable = true,
            punishment = 'ban' -- ban/kick/log
        },
        AntiRemoveWeaponFromPed = {
            enable = true,
            punishment = 'ban' -- ban/kick/log
        }
    },
    AntiExplosions = {
        enable = true,
        preventExplosions = true, -- Crédit: @jona0081
        preventSafeExplosions = false,
        preventUnnetworkedExplosions = true,
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image' -- image/video/false
    },
    BlacklistedModels = {
        enable = true,
        punishment = 'ban', -- ban/kick/log
        banMedia = 'image', -- image/video/false
        checkInterval = 10, -- in seconds
        blacklist = { -- a list of ped/animal models that player can't use
            [GetHashKey('a_c_fish')] = true,
            [GetHashKey('a_c_boar')] = true,
            [GetHashKey('a_c_boar_02')] = true,
            [GetHashKey('a_c_cat_01')] = true,
            [GetHashKey('a_c_chickenhawk')] = true,
            [GetHashKey('a_c_chimp')] = true,
            [GetHashKey('a_c_chimp_02')] = true,
            [GetHashKey('a_c_chop')] = true,
            [GetHashKey('a_c_cormorant')] = true,
            [GetHashKey('a_c_cow')] = true,
            [GetHashKey('a_c_coyote')] = true,
            [GetHashKey('a_c_crow')] = true,
            [GetHashKey('a_c_deer')] = true,
            [GetHashKey('a_c_dolphin')] = true,
            [GetHashKey('a_c_hen')] = true,
            [GetHashKey('a_c_humpback')] = true,
            [GetHashKey('a_c_husky')] = true,
            [GetHashKey('a_c_killerwhale')] = true,
            [GetHashKey('a_c_mtlion')] = true,
            [GetHashKey('a_c_pig')] = true,
            [GetHashKey('a_c_pigeon')] = true,
            [GetHashKey('a_c_poodle')] = true,
            [GetHashKey('a_c_pug')] = true,
            [GetHashKey('a_c_rabbit_01')] = true,
            [GetHashKey('a_c_rat')] = true,
            [GetHashKey('a_c_retriever')] = true,
            [GetHashKey('a_c_rhesus')] = true,
            [GetHashKey('a_c_rottweiler')] = true,
            [GetHashKey('a_c_rottweiler_02')] = true,
            [GetHashKey('a_c_sharkhammer')] = true,
            [GetHashKey('a_c_sharktiger')] = true,
            [GetHashKey('a_c_shepherd')] = true,
            [GetHashKey('a_c_stingray')] = true,
            [GetHashKey('a_c_westy')] = true
        },
    },
    EasyBypass = {
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
    EasyPermissions = {
        enable = false,
        -- !! DO NOT ENABLE MORE THAN 1 PERMISSION SYSTEM BELOW AT SAME TIME! Default is ACE
        txAdminPermissions = {
            enable = false,   -- Bypass txAdmin admins
            fgPermissions = { -- Permissions that'll be set if player has TxAdmin Access
                --[[ AdminMenu ]]  --
                    'AdminMenuAccess',
                    'AnnouncementAccess',
                    'ESPAccess',
                    'ClearEntitiesAccess',
                    'BanAndKickAccess',
                    'GotoAndBringAccess',
                    'VehicleAccess',
                    'MiscAccess',
                    'LogsAccess',
                    'PlayerSelectorAccess',
                    'BanListAndUnbanAccess',
                    'ModelChangerAccess',
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
                    'FGCommands',
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
            }
        },
        FrameworkPermissions = {
            enable = true, -- Use framework permission to determinate when add or remove fg perms
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
                    'ESPAccess',
                    'ClearEntitiesAccess',
                    'BanAndKickAccess',
                    'GotoAndBringAccess',
                    'VehicleAccess',
                    'MiscAccess',
                    'LogsAccess',
                    'PlayerSelectorAccess',
                    'BanListAndUnbanAccess',
                    'ModelChangerAccess',
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
                    'FGCommands',
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
                },
                ['admin'] = {
                    --[[ AdminMenu ]] --
                    'AdminMenuAccess',
                    'AnnouncementAccess',
                    'ESPAccess',
                    'ClearEntitiesAccess',
                    'BanAndKickAccess',
                    'GotoAndBringAccess',
                    'VehicleAccess',
                    'MiscAccess',
                    'LogsAccess',
                    'PlayerSelectorAccess',
                    'BanListAndUnbanAccess',
                    'ModelChangerAccess',
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
                    'FGCommands',
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
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
            enable = false, -- Group Ace Permissions // ONLY ESX FOR THE MOMENT (Soon QbCore & vRP)
            groups = {      -- define wich perms you want to add for a specific group
                ['admin'] = {
                    --[[ AdminMenu ]] --
                    'AdminMenuAccess',
                    'AnnouncementAccess',
                    'ESPAccess',
                    'ClearEntitiesAccess',
                    'BanAndKickAccess',
                    'GotoAndBringAccess',
                    'VehicleAccess',
                    'MiscAccess',
                    'LogsAccess',
                    'PlayerSelectorAccess',
                    'BanListAndUnbanAccess',
                    'ModelChangerAccess',
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
                    'FGCommands',
                    'BypassVPN',
                    'BypassExplosion',
                    'BypassClearTasks',
                    'BypassParticle'
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
