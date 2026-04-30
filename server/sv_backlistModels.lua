local data = LoadResourceFile(CurrentResourceName,'config.lua')
local Config = assert(load(data))()?.BlacklistedModels
if not Config?.enable then return end
while not READY do Citizen.Wait(0) end

local function checkModel()
    local players = GetPlayers()
    for i = 1, #players do
        local source = tonumber(players[i])
        ---@diagnostic disable-next-line: param-type-mismatch
        local model = GetEntityModel(GetPlayerPed(source))
        if model and Config.blacklist[model] == true then
            PunishPlayer(source, Config.ban, ("Blacklisted model detected: %s"):format(model), Config.banMedia)
            break
        end
    end
    Citizen.SetTimeout(Config.checkInterval*1000, checkModel)
end
checkModel()
