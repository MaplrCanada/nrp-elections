-- File: client/main.lua

local QBCore = exports['qb-core']:GetCoreObject()
local candidates = {}
local settings = {}
local isNearBooth = false
local currentBooth = nil
local booths = {}

-- Initialize
Citizen.CreateThread(function()
    -- Create voting booth props and blips
    for i, booth in ipairs(Config.VotingBooths) do
        -- Create blip
        local blip = AddBlipForCoord(booth.coords)
        SetBlipSprite(blip, Config.ElectionBlip.sprite)
        SetBlipColour(blip, Config.ElectionBlip.color)
        SetBlipScale(blip, Config.ElectionBlip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.ElectionBlip.label)
        EndTextCommandSetBlipName(blip)
        
        -- Store booth data
        booth.blip = blip
        booths[i] = booth
    end
    
    -- Request initial data
    QBCore.Functions.TriggerCallback('elections:getCandidates', function(candidatesList)
        candidates = candidatesList
    end)
    
    QBCore.Functions.TriggerCallback('elections:getSettings', function(settingsData)
        settings = settingsData
    end)
end)

-- Update candidates list
RegisterNetEvent('elections:updateCandidates')
AddEventHandler('elections:updateCandidates', function(candidatesList)
    candidates = candidatesList
end)

-- Update settings
RegisterNetEvent('elections:updateSettings')
AddEventHandler('elections:updateSettings', function(settingsData)
    settings = settingsData
end)

-- Check for voting booths proximity
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000
        
        isNearBooth = false
        currentBooth = nil
        
        for i, booth in ipairs(booths) do
            local distance = #(playerCoords - booth.coords)
            
            if distance < 10.0 then
                sleep = 0
                DrawMarker(1, booth.coords.x, booth.coords.y, booth.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                
                if distance < 2.0 then
                    isNearBooth = true
                    currentBooth = booth
                    -- Display help text
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to access the voting system")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    
                    -- Handle interaction
                    if IsControlJustReleased(0, 38) then -- E key
                        OpenElectionMenu()
                    end
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- Create and spawn props (called during resource start)
Citizen.CreateThread(function()
    for _, booth in ipairs(Config.VotingBooths) do
        RequestModel(GetHashKey(booth.model))
        while not HasModelLoaded(GetHashKey(booth.model)) do
            Citizen.Wait(1)
        end
        
        local boothObj = CreateObject(GetHashKey(booth.model), booth.coords.x, booth.coords.y, booth.coords.z, false, true, true)
        SetEntityHeading(boothObj, booth.heading)
        FreezeEntityPosition(boothObj, true)
        SetModelAsNoLongerNeeded(GetHashKey(booth.model))
    end
end)

-- Display election results
RegisterNetEvent('elections:displayResults')
AddEventHandler('elections:displayResults', function(candidatesList, winner)
    SendNUIMessage({
        action = "showResults",
        candidates = candidatesList,
        winner = winner,
        settings = settings
    })
    SetNuiFocus(true, true)
end)

-- Open admin panel
RegisterNetEvent('elections:openAdminPanel')
AddEventHandler('elections:openAdminPanel', function()
    SendNUIMessage({
        action = "showAdminPanel",
        candidates = candidates,
        settings = settings
    })
    SetNuiFocus(true, true)
end)

-- Main election menu
function OpenElectionMenu()
    if not settings.election_active then
        QBCore.Functions.Notify("There is no active election at this time.", "error")
        return
    end
    
    QBCore.Functions.TriggerCallback('elections:hasVoted', function(hasVoted)
        SendNUIMessage({
            action = "showMainMenu",
            hasVoted = hasVoted,
            canRegister = settings.registration_open,
            canVote = settings.voting_open and not hasVoted,
            candidates = candidates,
            settings = settings
        })
        SetNuiFocus(true, true)
    end)
end

-- Register command as fallback
RegisterCommand('elections', function()
    if isNearBooth then
        OpenElectionMenu()
    else
        QBCore.Functions.Notify("You need to be at a voting booth to access elections.", "error")
    end
end)