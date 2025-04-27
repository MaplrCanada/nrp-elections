-- File: client/ui.lua

-- UI Functions for consistent styling

-- Display a dynamic blip on the map
function CreateBlip(coords, sprite, color, scale, text)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    return blip
end

-- Create 3D text in world
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Display progress bar
function ProgressBar(message, time)
    exports['progressbar']:Progress({
        name = "election_action",
        duration = time,
        label = message,
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }
    })
    
    Citizen.Wait(time)
end

-- Create animation when using voting booth
function PlayVotingAnimation()
    local playerPed = PlayerPedId()
    local animDict = "anim@heists@prison_heiststation@cop_reactions"
    local anim = "cop_b_idle"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    
    TaskPlayAnim(playerPed, animDict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(5000)
    ClearPedTasks(playerPed)
end

-- Visual notification with image
function SendAdvancedNotification(title, subtitle, message, icon, flash)
    if Config.UseHUD then
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        SetNotificationMessage(icon, icon, flash, 'CHAR_FRANKLIN', title, subtitle)
        DrawNotification(false, true)
    else
        QBCore.Functions.Notify(message, "primary", 5000)
    end
end

-- Certificate animation when registering
function ShowRegistrationCertificate(name)
    SendNUIMessage({
        action = "showCertificate",
        name = name
    })
    
    Citizen.Wait(5000)
    
    SendNUIMessage({
        action = "hideCertificate"
    })
end

-- Effects when announcing winner
function PlayWinnerEffect(coords)
    if coords then
        local particleDict = "scr_rcbarry2"
        local particleName = "scr_clown_appears"
        
        RequestNamedPtfxAsset(particleDict)
        while not HasNamedPtfxAssetLoaded(particleDict) do
            Citizen.Wait(10)
        end
        
        UseParticleFxAssetNextCall(particleDict)
        StartParticleFxLoopedAtCoord(particleName, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
        
        -- Play sound
        PlaySoundFrontend(-1, "MEDAL_UP", "HUD_MINI_GAME_SOUNDSET", 1)
    end
end