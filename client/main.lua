-- Client-side script (client/main.lua)

local QBCore = exports['qb-core']:GetCoreObject()
local candidates = {}
local isMenuOpen = false

-- Update candidates list
RegisterNetEvent('elections:updateCandidates')
AddEventHandler('elections:updateCandidates', function(candidatesList)
    candidates = candidatesList
end)

-- Command to open registration menu
RegisterCommand('register', function()
    QBCore.Functions.TriggerCallback('elections:getCandidates', function(candidatesList)
        candidates = candidatesList
        OpenRegistrationMenu()
    end)
end)

-- Command to open voting menu
RegisterCommand('vote', function()
    QBCore.Functions.TriggerCallback('elections:hasVoted', function(hasVoted)
        if hasVoted then
            QBCore.Functions.Notify('You have already voted', 'error')
            return
        end
        
        QBCore.Functions.TriggerCallback('elections:getCandidates', function(candidatesList)
            candidates = candidatesList
            OpenVotingMenu()
        end)
    end)
end)

-- Registration menu
function OpenRegistrationMenu()
    if isMenuOpen then return end
    
    isMenuOpen = true
    
    local registrationMenu = {
        {
            header = "Candidate Registration",
            isMenuHeader = true
        },
        {
            header = "Register as Candidate",
            txt = "Submit your candidacy for the election",
            params = {
                event = "elections:registerCandidateForm"
            }
        },
        {
            header = "Close Menu",
            txt = "",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        }
    }
    
    exports['qb-menu']:openMenu(registrationMenu)
    isMenuOpen = false
end

-- Registration form
RegisterNetEvent('elections:registerCandidateForm')
AddEventHandler('elections:registerCandidateForm', function()
    local dialog = exports['qb-input']:ShowInput({
        header = "Candidate Registration",
        submitText = "Register",
        inputs = {
            {
                text = "Campaign Slogan",
                name = "slogan",
                type = "text",
                isRequired = true
            },
            {
                text = "Campaign Promises",
                name = "promises",
                type = "text",
                isRequired = true
            }
        }
    })
    
    if dialog then
        QBCore.Functions.TriggerCallback('elections:registerCandidate', function(success, message)
            QBCore.Functions.Notify(message, success and 'success' or 'error')
        end, dialog)
    end
end)

-- Voting menu
function OpenVotingMenu()
    if isMenuOpen then return end
    
    isMenuOpen = true
    
    local votingMenu = {
        {
            header = "Election Voting",
            isMenuHeader = true
        }
    }
    
    if #candidates == 0 then
        table.insert(votingMenu, {
            header = "No candidates available",
            txt = "Check back later",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        })
    else
        for _, candidate in pairs(candidates) do
            table.insert(votingMenu, {
                header = candidate.name,
                txt = "Slogan: " .. candidate.slogan,
                params = {
                    event = "elections:viewCandidate",
                    args = {
                        citizenid = candidate.citizenid,
                        name = candidate.name,
                        slogan = candidate.slogan,
                        promises = candidate.promises
                    }
                }
            })
        end
    end
    
    table.insert(votingMenu, {
        header = "Close Menu",
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }
    })
    
    exports['qb-menu']:openMenu(votingMenu)
    isMenuOpen = false
end

-- View candidate details
RegisterNetEvent('elections:viewCandidate')
AddEventHandler('elections:viewCandidate', function(data)
    local candidateMenu = {
        {
            header = "Candidate: " .. data.name,
            isMenuHeader = true
        },
        {
            header = "Slogan",
            txt = data.slogan,
            params = {
                event = "elections:returnToVoting"
            }
        },
        {
            header = "Promises",
            txt = data.promises,
            params = {
                event = "elections:returnToVoting"
            }
        },
        {
            header = "Vote for this candidate",
            txt = "Your vote is final",
            params = {
                event = "elections:confirmVote",
                args = {
                    citizenid = data.citizenid,
                    name = data.name
                }
            }
        },
        {
            header = "Back to Candidates",
            txt = "",
            params = {
                event = "elections:returnToVoting"
            }
        }
    }
    
    exports['qb-menu']:openMenu(candidateMenu)
end)

-- Return to voting menu
RegisterNetEvent('elections:returnToVoting')
AddEventHandler('elections:returnToVoting', function()
    OpenVotingMenu()
end)

-- Confirm vote
RegisterNetEvent('elections:confirmVote')
AddEventHandler('elections:confirmVote', function(data)
    local confirmMenu = {
        {
            header = "Confirm Your Vote",
            isMenuHeader = true
        },
        {
            header = "Vote for " .. data.name,
            txt = "This action cannot be undone",
            params = {
                event = "elections:submitVote",
                args = {
                    citizenid = data.citizenid
                }
            }
        },
        {
            header = "Cancel",
            txt = "Return to candidates",
            params = {
                event = "elections:returnToVoting"
            }
        }
    }
    
    exports['qb-menu']:openMenu(confirmMenu)
end)

-- Submit vote
RegisterNetEvent('elections:submitVote')
AddEventHandler('elections:submitVote', function(data)
    QBCore.Functions.TriggerCallback('elections:vote', function(success, message)
        QBCore.Functions.Notify(message, success and 'success' or 'error')
    end, data.citizenid)
end)