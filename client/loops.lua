CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            Wait(10)
            TriggerServerEvent('QBCore:PlayerJoined')
            return
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if LocalPlayer.state['isLoggedIn'] then
            Wait((1000 * 60) * QBCore.Config.UpdateInterval)
            TriggerEvent('QBCore:Player:UpdatePlayerData')
        end
    end
end)

CreateThread(function()
    while true do
        Wait(QBCore.Config.StatusInterval)
        if LocalPlayer.state['isLoggedIn'] then
            if QBCore.Functions.GetPlayerData().metadata['hunger'] <= 0 or
                QBCore.Functions.GetPlayerData().metadata['thirst'] <= 0 then
                local ped = PlayerPedId()
                local currentHealth = GetEntityHealth(ped)
                SetEntityHealth(ped, currentHealth - math.random(5, 10))
            end
        end
    end
end)