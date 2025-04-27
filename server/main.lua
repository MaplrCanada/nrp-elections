-- File: server/main.lua

local QBCore = exports['qb-core']:GetCoreObject()
local candidates = {}
local settings = Config.DefaultSettings

-- Initialize and load data from database
Citizen.CreateThread(function()
    InitializeDatabase()
    Wait(1000) -- Wait for DB to initialize
    LoadElectionSettings()
    LoadCandidates()
end)

-- Register candidate
QBCore.Functions.CreateCallback('elections:registerCandidate', function(source, cb, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not settings.registration_open then
        cb(false, "Registration is closed")
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if player is already registered
    CheckCandidateExists(citizenid, function(exists)
        if exists then
            cb(false, "You are already registered as a candidate")
            return
        end
        
        -- Register new candidate
        local candidateInfo = {
            citizenid = citizenid,
            name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            slogan = data.slogan or "",
            promises = data.promises or "",
            party = data.party or "Independent",
            photo = data.photo or "default.jpg",
            votes = 0
        }
        
        InsertCandidate(candidateInfo, function(success)
            if success then
                -- Add to local cache
                table.insert(candidates, candidateInfo)
                TriggerClientEvent('elections:updateCandidates', -1, candidates)
                cb(true, "You have successfully registered as a candidate")
            else
                cb(false, "Failed to register. Please try again.")
            end
        end)
    end)
end)

-- Vote for candidate
QBCore.Functions.CreateCallback('elections:vote', function(source, cb, candidateId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    
    if not settings.voting_open then
        cb(false, "Voting is not currently open")
        return
    end
    
    -- Check if player has already voted
    CheckVoteExists(citizenid, function(hasVoted)
        if hasVoted then
            cb(false, "You have already voted")
            return
        end
        
        -- Check if candidate exists
        local candidateFound = false
        for i, candidate in pairs(candidates) do
            if candidate.citizenid == candidateId then
                candidates[i].votes = candidates[i].votes + 1
                candidateFound = true
                
                -- Update votes in database
                UpdateCandidateVotes(candidateId, candidates[i].votes)
                
                -- Record vote
                RecordVote(citizenid, candidateId)
                
                break
            end
        end
        
        if not candidateFound then
            cb(false, "Candidate not found")
            return
        end
        
        -- Update all clients
        TriggerClientEvent('elections:updateCandidates', -1, candidates)
        cb(true, "Your vote has been registered")
    end)
end)

-- Get candidates
QBCore.Functions.CreateCallback('elections:getCandidates', function(source, cb)
    cb(candidates)
end)

-- Check if player has voted
QBCore.Functions.CreateCallback('elections:hasVoted', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    
    CheckVoteExists(citizenid, function(hasVoted)
        cb(hasVoted)
    end)
end)

-- Get election settings
QBCore.Functions.CreateCallback('elections:getSettings', function(source, cb)
    cb(settings)
end)

-- Admin commands
QBCore.Commands.Add('electionadmin', 'Open election admin panel', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= Config.AdminRank then
        TriggerClientEvent('elections:openAdminPanel', src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission', 'error')
    end
end)

-- Admin command handlers
RegisterNetEvent('elections:server:toggleRegistration')
AddEventHandler('elections:server:toggleRegistration', function(state)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= Config.AdminRank then
        settings.registration_open = state  -- Set the state directly from UI
        print("Setting registration_open to: " .. tostring(state))  -- Debug log
        UpdateElectionSettings()  -- Save to database
        TriggerClientEvent('QBCore:Notify', -1, 'Election registration is now ' .. (state and 'open' or 'closed'), state and 'success' or 'error')
    end
end)

RegisterNetEvent('elections:server:toggleVoting')
AddEventHandler('elections:server:toggleVoting', function(state)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= Config.AdminRank then
        settings.voting_open = state  -- Set the state directly from UI
        print("Setting voting_open to: " .. tostring(state))  -- Debug log
        UpdateElectionSettings()  -- Save to database
        TriggerClientEvent('QBCore:Notify', -1, 'Voting is now ' .. (state and 'open' or 'closed'), state and 'success' or 'error')
    end
end)

RegisterNetEvent('elections:server:resetElection')
AddEventHandler('elections:server:resetElection', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= Config.AdminRank then
        ResetElection(function(success)
            if success then
                candidates = {}
                settings = Config.DefaultSettings
                TriggerClientEvent('elections:updateCandidates', -1, candidates)
                TriggerClientEvent('QBCore:Notify', -1, 'The election has been reset', 'primary')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Failed to reset election', 'error')
            end
        end)
    end
end)

RegisterNetEvent('elections:server:announceResults')
AddEventHandler('elections:server:announceResults', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= Config.AdminRank then
        -- Sort candidates by votes
        table.sort(candidates, function(a, b) return a.votes > b.votes end)
        
        if #candidates > 0 then
            local winner = candidates[1]
            if winner.votes > 0 then
                local resultMessage = winner.name .. " has won the election with " .. winner.votes .. " votes!"
                TriggerClientEvent('elections:displayResults', -1, candidates, winner)
            else
                TriggerClientEvent('QBCore:Notify', src, 'No votes have been cast yet', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'No candidates registered', 'error')
        end
    end
end)

-- Player connection
RegisterNetEvent('QBCore:Server:PlayerLoaded')
AddEventHandler('QBCore:Server:PlayerLoaded', function()
    local src = source
    TriggerClientEvent('elections:updateCandidates', src, candidates)
    TriggerClientEvent('elections:updateSettings', src, settings)
end)