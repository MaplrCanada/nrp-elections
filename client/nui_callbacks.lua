-- File: client/nui_callbacks.lua

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('registerCandidate', function(data, cb)
    QBCore.Functions.TriggerCallback('elections:registerCandidate', function(success, message)
        cb({success = success, message = message})
        if success then
            QBCore.Functions.Notify(message, "success")
        else
            QBCore.Functions.Notify(message, "error")
        end
    end, data)
end)

RegisterNUICallback('voteForCandidate', function(data, cb)
    QBCore.Functions.TriggerCallback('elections:vote', function(success, message)
        cb({success = success, message = message})
        if success then
            QBCore.Functions.Notify(message, "success")
            SetNuiFocus(false, false)
        else
            QBCore.Functions.Notify(message, "error")
        end
    end, data.citizenid)
end)

-- Admin panel callbacks
RegisterNUICallback('toggleRegistration', function(data, cb)
    TriggerServerEvent('elections:server:toggleRegistration', data.state)
    cb('ok')
end)

RegisterNUICallback('toggleVoting', function(data, cb)
    TriggerServerEvent('elections:server:toggleVoting', data.state)
    cb('ok')
end)

RegisterNUICallback('resetElection', function(data, cb)
    TriggerServerEvent('elections:server:resetElection')
    cb('ok')
end)

RegisterNUICallback('announceResults', function(data, cb)
    TriggerServerEvent('elections:server:announceResults')
    cb('ok')
end)