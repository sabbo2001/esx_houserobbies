Data = {
    Markers = {}
}

Markers = {}
Markers.Add = function(id, position, hint, callback, settings)
    local threadId = GetGameTimer()

    if settings == nil then
        settings = {}
    end

    Data.Markers[id] = {
        ["position"] = position,
        ["hint"] = hint,
        ["callback"] = callback,
        ["type"] = settings["markerType"],
        ["color"] = settings["markerColor"],
        ["size"] = settings["markerSize"],
        ["key"] = settings["key"],
        ["hidden"] = false,
        ["id"] = threadId,
        ["job"] = settings["requiredJob"]
    }

    local defaultValues = {
        ["position"] = {["x"] = 0.0, ["y"] = 0.0, ["z"] = 0.0},
        ["hint"] = 'Press ~INPUT_CONTEXT~ ...',
        ["type"] = 27,
        ["color"] = {0, 0, 255, 100},
        ["size"] = {1.5, 0.5},
        ["key"] = "E",
        ["job"] = "none"
    }

    for k, _ in pairs(defaultValues) do
        if Data.Markers[id][k] == nil then
            Data.Markers[id][k] = defaultValues[k]
        end
    end

    Citizen.CreateThread(function()
        local ped = GetPlayerPed(-1)
        local hintDisplayed = false

        Data.Markers[id]["position"]["z"] = Data.Markers[id]["position"]["z"] - 0.975

        while Data.Markers[id] ~= nil do
            local marker = Data.Markers[id]

            if marker["id"] == threadId then
                if Player.job.jobName == marker["job"] or marker["job"] == "none" then
                    local coords = GetEntityCoords(ped)
                    local distance = GetDistanceBetweenCoords(coords["x"], coords["y"], coords["z"], marker["position"]["x"], marker["position"]["y"], marker["position"]["z"], true)
                    local sleep = 0

                    if distance < marker["size"][1] * 7.5 then
                        DrawMarker(marker["type"], marker["position"]["x"], marker["position"]["y"], marker["position"]["z"], 0.0, 0.0, 0.0, 0, 0.0, 0.0, marker["size"][1], marker["size"][1], marker["size"][2], marker["color"][1], marker["color"][2], marker["color"][3], marker["color"][4], false, false, 2, false, false, false, false)
                    end

                    if distance < marker["size"][1] then
                        SetTextComponentFormat('STRING')
                        AddTextComponentString(marker["hint"])
                        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                        hintDisplayed = true

                        if IsControlJustPressed(0, Keys[marker["key"]]) then
                            if marker["callback"] ~= nil then
                                marker["callback"]()
                            end
                        end
                    else
                        if hintDisplayed then
                            SetTextComponentFormat('STRING')
                            AddTextComponentString("")
                            DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                            hintDisplayed = false
                        end

                        if distance > marker["size"][1] * 7.5 then
                            sleep = math.floor(distance * 5)
                        end
                    end

                    Citizen.Wait(sleep)
                else
                    Citizen.Wait(3000)
                end
            else
                break
            end
        end
    end)
end

Markers.Remove = function(id)
    Data.Markers[id] = nil
end

Markers.Hide = function(id)
    if Data.Markers[id] ~= nil then
        Data.Markers[id]["hidden"] = true
    end
end

Markers.Show = function(id)
    if Data.Markers[id] ~= nil then
        Data.Markers[id]["hidden"] = false
    end
end