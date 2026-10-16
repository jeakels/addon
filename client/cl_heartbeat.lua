RegisterNetEvent('fg:addon:heartbeat:ping', function(token)
    TriggerServerEvent('fg:addon:heartbeat:pong', token)
end)

return true
