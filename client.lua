Keys = {
    ["ESC"] = 322,
    ["F1"] = 288,
    ["F2"] = 289,
    ["F3"] = 170,
    ["F5"] = 166,
    ["F6"] = 167,
    ["F7"] = 168,
    ["F8"] = 169,
    ["F9"] = 56,
    ["F10"] = 57,
    ["~"] = 243,
    ["1"] = 157,
    ["2"] = 158,
    ["3"] = 160,
    ["4"] = 164,
    ["5"] = 165,
    ["6"] = 159,
    ["7"] = 161,
    ["8"] = 162,
    ["9"] = 163,
    ["-"] = 84,
    ["="] = 83,
    ["BACKSPACE"] = 177,
    ["TAB"] = 37,
    ["Q"] = 44,
    ["W"] = 32,
    ["E"] = 38,
    ["R"] = 45,
    ["T"] = 245,
    ["Y"] = 246,
    ["U"] = 303,
    ["P"] = 199,
    ["["] = 39,
    ["]"] = 40,
    ["ENTER"] = 18,
    ["CAPS"] = 137,
    ["A"] = 34,
    ["S"] = 8,
    ["D"] = 9,
    ["F"] = 23,
    ["G"] = 47,
    ["H"] = 74,
    ["K"] = 311,
    ["L"] = 182,
    ["LEFTSHIFT"] = 21,
    ["Z"] = 20,
    ["X"] = 73,
    ["C"] = 26,
    ["V"] = 0,
    ["B"] = 29,
    ["N"] = 249,
    ["M"] = 244,
    [","] = 82,
    ["."] = 81,
    ["LEFTCTRL"] = 36,
    ["LEFTALT"] = 19,
    ["SPACE"] = 22,
    ["RIGHTCTRL"] = 70,
    ["HOME"] = 213,
    ["PAGEUP"] = 10,
    ["PAGEDOWN"] = 11,
    ["DELETE"] = 178,
    ["LEFT"] = 174,
    ["RIGHT"] = 175,
    ["TOP"] = 27,
    ["DOWN"] = 173,
    ["NENTER"] = 201,
    ["N4"] = 108,
    ["N5"] = 60,
    ["N6"] = 107,
    ["N+"] = 96,
    ["N-"] = 97,
    ["N7"] = 117,
    ["N8"] = 61,
    ["N9"] = 118
}

PNotify = {}
ESX = nil
Player = nil
InsideHouse = false
Locations = {
    House = {
        Entry = { ["x"] = -14.2, ["y"] = -1442.36, ["z"] = 31.11, ["heading"] = 180.0 },
        Inside = { ["x"] = -14.1, ["y"] = -1440.36, ["z"] = 31.11, ["heading"] = 0.0 },
        Backdoor = { ["x"] = -14.39, ["y"] = -1425.6, ["z"] = 30.67, ["heading"] = 358.44 },
        BackdoorInside = { ["x"] = -14.51, ["y"] = -1427.98, ["z"] = 31.1, ["heading"] = 355.68 },
        LootPlaces = {
            { ["x"] = -9.84, ["y"] = -1438.47, ["z"] = 31.11, ["type"] = "fotölj" },
            { ["x"] = -12.54, ["y"] = -1436.94, ["z"] = 31.11, ["type"] = "hylla" },
            { ["x"] = -12.41, ["y"] = -1434.89, ["z"] = 31.11, ["type"] = "hylla" },
            { ["x"] = -9.48, ["y"] = -1441.4, ["z"] = 31.11, ["type"] = "tv bänk" },
            { ["x"] = -12.93, ["y"] = -1429.25, ["z"] = 31.11, ["type"] = "skafferi" },
            { ["x"] = -11.95, ["y"] = -1428.05, ["z"] = 31.11, ["type"] = "köksskåp" },
            { ["x"] = -17.11, ["y"] = -1430.41, ["z"] = 31.11, ["type"] = "förråd" },
            { ["x"] = -16.48, ["y"] = -1434.91, ["z"] = 31.11, ["type"] = "nattygsbord" },
            { ["x"] = -17.72, ["y"] = -1432.15, ["z"] = 31.11, ["type"] = "byrå" },
            { ["x"] = -16.95, ["y"] = -1440.76, ["z"] = 31.11, ["type"] = "byrå" },
            { ["x"] = -18.37, ["y"] = -1440.59, ["z"] = 31.11, ["type"] = "nattygsbord" },
        }
    }
}
Config = {
    LootingTime = 5000
}

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(100)

        TriggerEvent("esx:getSharedObject", function(library)
            ESX = library
        end)
    end

    if ESX.IsPlayerLoaded() then
        OnLoad()
    end
end)

AddEventHandler('skinchanger:modelLoaded', function(model)
    OnLoad()
end)

function OnLoad()
    Player = ESX.GetPlayerData()

    local blip = AddBlipForCoord(Locations.House.Entry["x"], Locations.House.Entry["y"], Locations.House.Entry["z"])

    SetBlipSprite(blip, 206)
    SetBlipDisplay(blip, 4)
    SetBlipColour(blip, 10)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Inbrott')
    EndTextCommandSetBlipName(blip)

    Markers.Add("House.Robberies.Entry", Locations.House.Entry, "Tryck ~INPUT_CONTEXT~ för att göra inbrott här.", function()
        ESX.TriggerServerCallback("House.Robberies.Rob", function(response, code)
            if code == 0 then
                if string.len(response) > 0 then
                    PNotify:Queue(response, "success", 3000)
                end

                TriggerServerEvent("esx_phone:send", "police", "Inbrottslarm avlöst på denna position.", true, Locations.House.Entry)

                Citizen.CreateThread(function()
                    TeleportIntoHouse()
                end)
            elseif code == 1 then
                if string.len(response) > 0 then
                    PNotify:Queue(response, "success", 3000)
                end

                Citizen.CreateThread(function()
                    TeleportIntoHouse()
                end)
            elseif code == 2 then
                PNotify:Queue(response, "success", 3000)
            elseif code == 3 then
                PNotify:Queue(response, "error", 3000)
            end
        end)
    end)

    Markers.Add("House.Robberies.Leave", Locations.House.Inside, "Tryck ~INPUT_CONTEXT~ för att lämna huset.", function()
        LeaveHouse()
    end)

    Markers.Add("House.Robberies.BackdoorLeave", Locations.House.BackdoorInside, "Tryck ~INPUT_CONTEXT~ för att lämna huset.", function()
        LeaveHouseFromBackdoor()
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000)

            local door = GetClosestObjectOfType(Locations.House.Entry["x"], Locations.House.Entry["y"], Locations.House.Entry["z"], 5.0, GetHashKey("v_ilev_fa_frontdoor"), false, false, false)

            if door ~= nil and DoesEntityExist(door) then
                FreezeEntityPosition(door, true, true)
            end
        end
    end)
end

function TeleportIntoHouse()
    DoScreenFadeOut(1000)

    Citizen.Wait(1000)

    local ped = PlayerPedId()

    InsideHouse = true
    SetEntityCoords(ped, Locations.House.Inside["x"], Locations.House.Inside["y"], Locations.House.Inside["z"])
    SetEntityHeading(ped, Locations.House.Inside["heading"])

    while not HasCollisionLoadedAroundEntity(ped) do
        Citizen.Wait(10)
    end

    DoScreenFadeIn(1000)

    LootLogic()
end

function LeaveHouse()
    DoScreenFadeOut(1000)

    Citizen.Wait(1000)

    local ped = PlayerPedId()

    InsideHouse = false
    SetEntityCoords(ped, Locations.House.Entry["x"], Locations.House.Entry["y"], Locations.House.Entry["z"])
    SetEntityHeading(ped, Locations.House.Entry["heading"])

    while not HasCollisionLoadedAroundEntity(ped) do
        Citizen.Wait(10)
    end

    DoScreenFadeIn(1000)
end

function LeaveHouseFromBackdoor()
    DoScreenFadeOut(1000)

    Citizen.Wait(1000)

    local ped = PlayerPedId()

    InsideHouse = false
    SetEntityCoords(ped, Locations.House.Backdoor["x"], Locations.House.Backdoor["y"], Locations.House.Backdoor["z"])
    SetEntityHeading(ped, Locations.House.Backdoor["heading"])

    while not HasCollisionLoadedAroundEntity(ped) do
        Citizen.Wait(10)
    end

    DoScreenFadeIn(1000)
end

function LootLogic()
    for i = 1, #Locations.House.LootPlaces do
        Locations.House.LootPlaces[i]["id"] = i
    end

    while InsideHouse do
        Citizen.Wait(0)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        for i = 1, #Locations.House.LootPlaces do
            local place = Locations.House.LootPlaces[i]

            if GetDistanceBetweenCoords(coords, place["x"], place["y"], place["z"], false) <= 1.0 then
                SetTextComponentFormat('STRING')
                AddTextComponentString("Tryck ~INPUT_CONTEXT~ för att söka " .. place["type"])
                DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                if IsControlJustPressed(0, Keys["E"]) then
                    LootPlace(ped, coords, heading, place)
                end
            end
        end
    end
end

function LootPlace(ped, coords, heading, place)
    TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_BUM_BIN', coords["x"], coords["y"], coords["z"], heading, 1000, false, false)

    local timestamp = GetGameTimer()
    local done = false

    while not done do
        Citizen.Wait(0)

        local percentage = (GetGameTimer() - timestamp) / Config.LootingTime * 100

        if percentage >= 100 then
            ESX.TriggerServerCallback("House.Robberies.Loot", function(response)
                PNotify:Queue(response, "success", 3000)
            end, place["id"])

            ClearPedTasksImmediately(ped)

            done = true
        else
            DrawTextWithFont("Söker igenom " .. place["type"] .. " (" .. math.floor(percentage) .. "%)")
        end
    end
end

function DrawTextWithFont(text)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(0.75, 0.75)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    SetTextCentre(true)
    DrawText(0.45, 0.20)
end

function PNotify:Queue(message, type, timeout)
    TriggerEvent("pNotify:SendNotification", {
        text = message,
        type = type,
        queue = "lucasss",
        timeout = timeout,
        layout = "bottomCenter"
    })
end