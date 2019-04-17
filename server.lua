ESX = nil

TriggerEvent("esx:getSharedObject", function(library)
    ESX = library
end)

Cache = {
    CooldownTimestamp = 0,
    TableSize = 0,
    Robbery = {
        LootedPlaces = {}
    }
}
Config = {
    RequiredPolice = 1,
    Cooldown = 1800,
    LootPercentage = 30,
    LootAvailable = {
        ["WEAPON_PISTOL"] = 25,
        ["WEAPON_REVOLVER"] = 8,
        --["iphone"] = 1,
        ["gps"] = 1,
        ["fishing_rod"] = 1,
        ["fishing_lure"] = 5,
        --["pink_dildo"] = 1,
        ["drill"] = 1,
       -- ["bennys_off"] = 1,
       -- ["bennys_off1"] = 1,
        --["bilfirma_off"] = 1,
        --["bilfirma_off1"] = 1,
        ["weed"] = 5,
        ["Salmon"] = 3,
        ["Bass"] = 1,
        ["Pike"] = 2,
        ["vodka"] = 1
    },
    GracePeriod = 30
}

function RegisterEvent(event, func)
    RegisterServerEvent(event)
    AddEventHandler(event, func)
end

MySQL.ready(function()
    MySQL.Async.fetchAll("SELECT * FROM houserobbery", {}, function(cooldown)
        local row = true

        if cooldown[1] == nil then cooldown[1] = { ["cooldown"] = 0 } row = false end
        if cooldown[1]["cooldown"] == nil then cooldown[1]["cooldown"] = 0 row = false end

        Cache.CooldownTimestamp = cooldown[1]["cooldown"]
        Cache.FoundRow = row
    end)
end)

ESX.RegisterServerCallback("House.Robberies.Rob", function(source, callback)
    local player = ESX.GetPlayerFromId(source)

    if player == nil then return end

    if Cache.CooldownTimestamp + Config.Cooldown > os.time() and Cache.CooldownTimestamp + Config.GracePeriod < os.time() and player.job.name ~= "police" then
        callback("Det har redan varit ett inbrott här, vänta i  " .. ((Cache.CooldownTimestamp + Config.Cooldown) - os.time()) .. " sekund(er).", 3)

        return
    end

    local police = CalculatePolice()

    if police < Config.RequiredPolice then
        callback("Det måste vara " .. Config.RequiredPolice .. " polis(er) inne i tjänst för att göra inbrott. Just nu är det: " .. police, 2)

        return
    end

    local timestamp = os.time()

    if player.job.name == "police" then
        if Cache.CooldownTimestamp + Config.Cooldown < os.time() then
            Cache.CooldownTimestamp = timestamp
            Cache.Robbery = {
                LootedPlaces = {}
            }

            if not Cache.FoundRow then
                MySQL.Async.execute("INSERT INTO houserobbery (cooldown) VALUES (@timestamp)", {
                    ["@timestamp"] = timestamp
                })
            else
                MySQL.Async.execute("UPDATE houserobbery SET cooldown = @timestamp", {
                    ["@timestamp"] = timestamp
                })
            end

            print("[aurp-houserobberies] Ett inbrott har startats av ID " .. source .. " som har polisroll.")

            callback("", 0)

            return
        else
            print("[aurp-houserobberies] ID " .. source .. " gick in i huset och har polisroll.")

            callback("", 1)

            return
        end
    end

    if Cache.CooldownTimestamp + Config.Cooldown < os.time() then
        Cache.CooldownTimestamp = timestamp
        Cache.Robbery = {
            LootedPlaces = {}
        }

        if not Cache.FoundRow then
            MySQL.Async.execute("INSERT INTO houserobbery (cooldown) VALUES (@timestamp)", {
                ["@timestamp"] = timestamp
            })
        else
            MySQL.Async.execute("UPDATE houserobbery SET cooldown = @timestamp", {
                ["@timestamp"] = timestamp
            })
        end

        print("[aurp-houserobberies] Ett inbrott har startats av ID " .. source)

        callback("Polisen har fått larm om ett inbrott, skynda dig!", 0)
    else
        print("[aurp-houserobberies] ID " .. source .. " gick in i huset.")

        callback("Polisen är påväg, skynda dig!", 1)
    end
end)


ESX.RegisterServerCallback("House.Robberies.Loot", function(source, callback, id)
    local player = ESX.GetPlayerFromId(source)

    if player == nil then return end

    if Cache.Robbery.LootedPlaces[id] then
        callback("Detta ställe har redan blivit genomsökt av en person.", false)

        return
    end

    print("[aurp-houserobberies] ID " .. source .. " söker igenom ställe nummer " .. id .. ".")

    if math.random(0, 100) <= Config.LootPercentage then
        local itemfound = ""
        local index = 1
        local lootspots = 0

        for k, v in pairs(Config.LootAvailable) do
            lootspots = lootspots + 1
        end

        local randomized = math.random(lootspots)

        for k, v in pairs(Config.LootAvailable) do
            if index == randomized then
                if string.sub(k, 1, 6) == "WEAPON" then
                    itemfound = ESX.GetWeaponLabel(k) .. " [" .. v .. "]"

                    player.addWeapon(k, v)
                else
                    itemfound = ESX.GetItemLabel(k) .. " x" .. v

                    player.addInventoryItem(k, v)
                end

                break
            end

            index = index + 1
        end

        callback("Du hittade " .. itemfound .. "!", true)
    else
        callback("Inget speciellt hittades.", true)
    end

    Cache.Robbery.LootedPlaces[id] = true
end)

function CalculatePolice()
    local police = 0

    for k, v in pairs(ESX.Players) do
        if v.job.name == "police" then
            police = police + 1
        end
    end

    return police
end