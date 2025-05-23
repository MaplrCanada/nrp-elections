-- File: server/database.lua

function InitializeDatabase()
    -- Create candidates table if it doesn't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ]] .. Config.DatabaseTable.candidates .. [[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            name VARCHAR(100) NOT NULL,
            slogan TEXT,
            promises TEXT,
            party VARCHAR(50) DEFAULT 'Independent',
            photo VARCHAR(255) DEFAULT 'default.jpg',
            votes INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {})
    
    -- Create votes table if it doesn't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ]] .. Config.DatabaseTable.votes .. [[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            voter_citizenid VARCHAR(50) NOT NULL,
            candidate_citizenid VARCHAR(50) NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(voter_citizenid)
        )
    ]], {})
    
    -- Create settings table if it doesn't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ]] .. Config.DatabaseTable.settings .. [[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            setting_key VARCHAR(50) NOT NULL,
            setting_value VARCHAR(255) NOT NULL,
            UNIQUE(setting_key)
        )
    ]], {})
    
    -- Insert default settings if they don't exist
    for key, value in pairs(Config.DefaultSettings) do
        local strValue = tostring(value)
        if type(value) == "boolean" then
            strValue = value and "1" or "0"
        end
        
        MySQL.Async.execute([[
            INSERT INTO ]] .. Config.DatabaseTable.settings .. [[ (setting_key, setting_value)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
        ]], {key, strValue})
    end
end

function LoadElectionSettings()
    -- Initialize the settings table if it's not already initialized
    settings = settings or {}

    MySQL.Async.fetchAll('SELECT setting_key, setting_value FROM ' .. Config.DatabaseTable.settings, {}, function(result)
        if result and #result > 0 then
            for _, setting in ipairs(result) do
                print("Loading setting: " .. setting.setting_key .. " with DB value: " .. setting.setting_value)
                
                -- Update settings as boolean if the key matches and if it's one of the toggled settings
                if setting.setting_key == "registration_open" or setting.setting_key == "voting_open" or setting.setting_key == "election_active" then
                    settings[setting.setting_key] = setting.setting_value == "1"  -- Convert "1" to true and "0" to false
                    print("Converted " .. setting.setting_key .. " to boolean: " .. tostring(settings[setting.setting_key]))
                else
                    settings[setting.setting_key] = setting.setting_value
                end
            end
        else
            print("No settings found in database or query failed")
        end
    end)
end

function UpdateElectionSettings()
    for key, value in pairs(settings) do
        local strValue = tostring(value)
        
        -- Convert boolean to 1 or 0
        if type(value) == "boolean" then
            strValue = value and "1" or "0"
        end
        
        print("Updating setting: " .. key .. " to value: " .. strValue .. " (original: " .. tostring(value) .. ")") -- Enhanced debugging
        
        MySQL.Async.execute([[
            UPDATE ]] .. Config.DatabaseTable.settings .. [[ 
            SET setting_value = ? 
            WHERE setting_key = ?
        ]], {strValue, key}, function(affectedRows)
            if affectedRows == 0 then
                print("Failed to update setting: " .. key .. " - No rows affected") -- Better error logging
            end
        end)
    end
end

function ToggleElectionSetting(settingKey)
    -- Ensure the setting exists before toggling
    if settings[settingKey] ~= nil then
        -- Toggle the value between true and false
        settings[settingKey] = not settings[settingKey]
        
        -- Add debug output to verify the toggle happened in memory
        print("TOGGLED " .. settingKey .. " to: " .. tostring(settings[settingKey]))
        
        -- Call UpdateElectionSettings to reflect the change in the database
        UpdateElectionSettings()
    else
        print("Setting " .. settingKey .. " not found!")
    end
end


function LoadCandidates()
    MySQL.Async.fetchAll('SELECT * FROM ' .. Config.DatabaseTable.candidates, {}, function(result)
        if result and #result > 0 then
            candidates = result
        end
    end)
end

function InsertCandidate(candidateInfo, cb)
    MySQL.Async.insert([[
        INSERT INTO ]] .. Config.DatabaseTable.candidates .. [[ 
        (citizenid, name, slogan, promises, party, photo) 
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        candidateInfo.citizenid,
        candidateInfo.name,
        candidateInfo.slogan,
        candidateInfo.promises,
        candidateInfo.party,
        candidateInfo.photo
    }, function(id)
        cb(id ~= nil and id > 0)
    end)
end

function CheckCandidateExists(citizenid, cb)
    MySQL.Async.fetchScalar([[
        SELECT COUNT(*) FROM ]] .. Config.DatabaseTable.candidates .. [[ 
        WHERE citizenid = ?
    ]], {citizenid}, function(count)
        cb(count > 0)
    end)
end

function UpdateCandidateVotes(citizenid, votes)
    MySQL.Async.execute([[
        UPDATE ]] .. Config.DatabaseTable.candidates .. [[ 
        SET votes = ? 
        WHERE citizenid = ?
    ]], {votes, citizenid})
end

function RecordVote(voterCitizenid, candidateCitizenid)
    MySQL.Async.insert([[
        INSERT INTO ]] .. Config.DatabaseTable.votes .. [[ 
        (voter_citizenid, candidate_citizenid) 
        VALUES (?, ?)
    ]], {voterCitizenid, candidateCitizenid})
end

function CheckVoteExists(citizenid, cb)
    MySQL.Async.fetchScalar([[
        SELECT COUNT(*) FROM ]] .. Config.DatabaseTable.votes .. [[ 
        WHERE voter_citizenid = ?
    ]], {citizenid}, function(count)
        cb(count > 0)
    end)
end

function ResetElection(cb)
    MySQL.Async.execute('TRUNCATE TABLE ' .. Config.DatabaseTable.candidates, {}, function()
        MySQL.Async.execute('TRUNCATE TABLE ' .. Config.DatabaseTable.votes, {}, function()
            -- Reset settings to default
            for key, value in pairs(Config.DefaultSettings) do
                local strValue = tostring(value)
                if type(value) == "boolean" then
                    strValue = value and "1" or "0"
                end
                
                MySQL.Async.execute([[
                    UPDATE ]] .. Config.DatabaseTable.settings .. [[ 
                    SET setting_value = ? 
                    WHERE setting_key = ?
                ]], {strValue, key})
            end
            
            cb(true)
        end)
    end)
end