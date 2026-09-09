-- Settings
DELETE_UI_UPDATER = true
AUTO_REJOIN = true
REJOIN_INTERVAL = 1800

-- Monedas a minar
mineCoins = {"Christmas3 Small Cane", "Christmas3 Cane"}

-- Optimización (ajustar según necesidad)
COOLDOWN = 0.1      -- Tiempo entre ataques (menor = más rápido)
LOOP_WAIT = 0.05    -- Velocidad del loop (menor = más rápido)

-- // Don't change anything below

if DELETE_UI_UPDATER then
    game.Players.LocalPlayer.PlayerGui.Events:ClearAllChildren()
end

function getPetLevel(petData, hatsData)
    local lvl = petData.l
    if petData.h then
        for _, hat in pairs(hatsData) do
            if hat.id == petData.h then
                lvl = lvl + hat.l
                break
            end
        end
    end
    return lvl
end

function getEquippedPets()
    local Stats = workspace.__REMOTES.Core["Get Stats"]:InvokeServer()
    local equippedPets = {}
    for i, pet in pairs(Stats.Save.Pets) do
        if pet.e then
            local lvl = getPetLevel(pet, Stats.Save.Hats)
            table.insert(equippedPets, {
                id = pet.id,
                lvl = lvl
            })
        end
    end
    return equippedPets
end

local equippedPets = getEquippedPets()
local lastMineCooldown = os.clock()
local currentCoin = nil

_G.FARMING = true

task.spawn(function()
    while _G.FARMING do
        if not currentCoin or not currentCoin.Parent or currentCoin.Parent ~= workspace.__THINGS.Coins then
            currentCoin = nil
            for i, v in pairs(workspace.__THINGS.Coins:GetChildren()) do
                local cn = v:FindFirstChild('CoinName')
                if cn and table.find(mineCoins, cn.Value) then
                    currentCoin = v
                    break
                end
            end
            if not currentCoin then
                task.wait(0.5)
            end
        end

        if currentCoin and currentCoin.Parent == workspace.__THINGS.Coins then
            local cn = currentCoin:FindFirstChild('CoinName')
            if cn and table.find(mineCoins, cn.Value) and os.clock() > lastMineCooldown + COOLDOWN then
                for _, pet in pairs(equippedPets) do
                    workspace.__REMOTES.Game.Coins:FireServer("Mine", currentCoin.Name, pet.lvl * 2 - 1, pet.id)
                end
                lastMineCooldown = os.clock()
            end
        end

        task.wait(LOOP_WAIT)
    end
end)

if AUTO_REJOIN then
    local ts = game:GetService("TeleportService")
    local plr = game:GetService("Players").LocalPlayer

    task.spawn(function()
        while _G.FARMING and plr and plr.Parent do
            task.wait(REJOIN_INTERVAL)
            if #game.Players:GetPlayers() <= 1 then
                plr:Kick("\nRejoining...")
                task.wait(1)
                ts:Teleport(game.PlaceId, plr)
            else
                local success, err = pcall(function()
                    ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
                end)
                if not success then
                    ts:Teleport(game.PlaceId, plr)
                end
            end
        end
    end)
end