-- Server-side script (server/main.lua)

local QBCore = exports['qb-core']:GetCoreObject()
local candidates = {}
local votes = {}
local registrationOpen = true
local votingOpen = false

-- Register candidate
QBCore.Functions.CreateCallback('elections:registerCandidate', function(source, cb, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not registrationOpen then
        cb(false, "Registration is closed")
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if player is already registered
    for _, candidate in pairs(candidates) do
        if candidate.citizenid == citizenid then
            cb(false, "You are already registered as a candidate")
            return
        end
    end
    
    -- Register new candidate
    local candidateInfo = {
        citizenid = citizenid,
        name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        slogan = data.slogan or "",
        promises = data.promises or "",
        votes = 0,
        photo = data.photo or "https://via.placeholder.com/150"
    }
    
    table.insert(candidates, candidateInfo)
    TriggerClientEvent('elections:updateCandidates', -1, candidates)
    cb(true, "You have successfully registered as a candidate")
end)

-- Vote for candidate
QBCore.Functions.CreateCallback('elections:vote', function(source, cb, candidateId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    
    if not votingOpen then
        cb(false, "Voting is not currently open")
        return
    end
    
    -- Check if player has already voted
    if votes[citizenid] then
        cb(false, "You have already voted")
        return
    end
    
    -- Check if candidate exists
    local candidateFound = false
    for i, candidate in pairs(candidates) do
        if candidate.citizenid == candidateId then
            candidates[i].votes = candidates[i].votes + 1
            candidateFound = true
            break
        end
    end
    
    if not candidateFound then
        cb(false, "Candidate not found")
        return
    end
    
    -- Register vote
    votes[citizenid] = candidateId
    
    -- Update all clients
    TriggerClientEvent('elections:updateCandidates', -1, candidates)
    cb(true, "Your vote has been registered")
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
    
    cb(votes[citizenid] ~= nil)
end)

-- Admin commands
QBCore.Commands.Add('openregistration', 'Open candidate registration', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= 3 then -- Admin check
        registrationOpen = true
        TriggerClientEvent('QBCore:Notify', -1, 'Election registration is now open!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission', 'error')
    end
end)

QBCore.Commands.Add('closeregistration', 'Close candidate registration', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= 3 then -- Admin check
        registrationOpen = false
        TriggerClientEvent('QBCore:Notify', -1, 'Election registration is now closed!', 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission', 'error')
    end
end)

QBCore.Commands.Add('openvoting', 'Open voting period', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= 3 then -- Admin check
        votingOpen = true
        TriggerClientEvent('QBCore:Notify', -1, 'Voting is now open!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission', 'error')
    end
end)

QBCore.Commands.Add('closevoting', 'Close voting period', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= 3 then -- Admin check
        votingOpen = false
        TriggerClientEvent('QBCore:Notify', -1, 'Voting is now closed!', 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission', 'error')
    end
end)

QBCore.Commands.Add('electionresults', 'Show election results', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= 3 then -- Admin check
        -- Sort candidates by votes
        table.sort(candidates, function(a, b) return a.votes > b.votes end)
        
        -- Announce winner and results
        if #candidates > 0 then
            local winner = candidates[1]
            local resultMessage = winner.name .. " has won the election with " .. winner.votes .. " votes!"
            TriggerClientEvent('QBCore:Notify', -1, resultMessage, 'success')
            
            -- Also display detailed results to the admin
            for i, candidate in ipairs(candidates) do
                TriggerClientEvent('QBCore:Notify', src, i .. ". " .. candidate.name .. ": " .. candidate.votes .. " votes", 'primary')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'No candidates registered', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission', 'error')
    end
end)

QBCore.Commands.Add('resetelection', 'Reset the election', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.job.grade.level >= 3 then -- Admin check
        candidates = {}
        votes = {}
        registrationOpen = true
        votingOpen = false
        TriggerClientEvent('elections:updateCandidates', -1, candidates)
        TriggerClientEvent('QBCore:Notify', -1, 'The election has been reset', 'primary')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission', 'error')
    end
end)

