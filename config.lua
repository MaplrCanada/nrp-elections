-- File: config.lua

Config = {}

-- General settings
Config.AdminRank = 3  -- Minimum admin rank required for election commands
Config.UseHUD = true  -- Whether to use the HUD notification system
Config.ElectionBlip = {
    sprite = 407,     -- Voting booth blip sprite
    color = 0,        -- Blip color
    scale = 0.7,      -- Blip scale
    label = "Voting Booth"  -- Blip label
}

-- Voting booth locations
Config.VotingBooths = {
    {
        coords = vector3(-545.0208, -203.8816, 38.2151),
        heading = 28.54,
        model = 'prop_food_van_1'  -- Can be changed to a more appropriate prop
    },
    {
        coords = vector3(237.5159, -413.3118, 48.1119),
        heading = 158.62,
        model = 'prop_food_van_1'
    },
    -- Add more voting booths as needed
}

-- Database settings
Config.DatabaseTable = {
    candidates = "election_candidates",
    votes = "election_votes",
    settings = "election_settings"
}

-- Default settings
Config.DefaultSettings = {
    registration_open = false,
    voting_open = false,
    election_active = false,
    election_name = "City Mayor Election"
}

-- UI settings
Config.UI = {
    title = "Los Santos Elections",
    primary_color = "#3498db",
    secondary_color = "#2c3e50",
    accent_color = "#e74c3c",
    logo = "img/logo.png"
}