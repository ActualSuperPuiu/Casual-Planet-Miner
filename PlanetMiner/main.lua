local screenWidth, screenHeight = 600, 600
local Version = 0.2

local DrawText = rl.DrawText
local DrawCircleV = rl.DrawCircleV
local new = rl.new
local DrawTexturePro = rl.DrawTexturePro
local DrawRectanglePro = rl.DrawRectanglePro

rl.InitWindow(screenWidth, screenHeight, "Planet Miner - "..Version)
rl.InitAudioDevice()

local Loaded = false
local Mine = new("Sound", rl.LoadSound("Mine.wav"))
local Upgrade = new("Sound", rl.LoadSound("Upgrade.wav"))
local Music = new("Music", rl.LoadMusicStream("Music.mp3"))

rl.SetTargetFPS(60)

local Background = rl.LoadTexture("Background.png")

local GroupLogo = rl.LoadTexture("NoBackgroundPuius.png")

local Particle = {}

local Planets = {
    [1] = {
        -- Earth
        ["Image"] = rl.LoadTexture("Earth.png"),
        ["Health"] = 2000,
        ["Bonus"] = 150,
        ["Name"] = "Earth",
        ["MaxHealth"] = 2000
    },

    [2] = {
        -- Mars
        ["Image"] = rl.LoadTexture("Mars.png"),
        ["Health"] = 4000,
        ["Bonus"] = 350,
        ["Name"] = "Mars",
        ["MaxHealth"] = 4000
    },

    [3] = {
        -- Venus
        ["Image"] = rl.LoadTexture("Venus.png"),
        ["Health"] = 6000,
        ["Bonus"] = 1000,
        ["Name"] = "Venus",
        ["MaxHealth"] = 6000
    }
}

local BonusPlanets = {
    ["Diamond"] = {
        ["Image"] = rl.LoadTexture("DiamondPlanet.png"),
        ["Health"] = 4500, -- 4500
        ["Bonus"] = 10000,
        ["Name"] = "Diamond",
        ["MaxHealth"] = 2000,
    },
    ["Bronze"] = {
        ["Image"] = rl.LoadTexture("Bronze.png"),
        ["Bonus"] = 2000,
        ["Health"] = 2000,
        ["Name"] = "Bronze",
        ["MaxHealth"] = 2000
    },
    
    ["Gold"] = {
        ["Image"] = rl.LoadTexture("Gold.png"),
        ["Bonus"] = 5000,
        ["Health"] = 3500,
        ["Name"] = "Gold",
        ["MaxHealth"] = 3500
    },
}

local CurrentPlanet = Planets[1]

local CurrentPlanetLevel = 1
local MaxPlanetLevel = 3
local UnlockedLevel = 1

local CurrentHealth = CurrentPlanet["Health"]

local PlanetCircle = new("Rectangle", 0, 0, CurrentPlanet["Image"].width, CurrentPlanet["Image"].height)

-- screenWidth/2 - texture.width/2, screenHeight/2 - texture.height/2, WHITE

local Points = 0
local PointsToUpgrade = 10
local miningPoints = 1
local autoMiningPoints = 0
local PointsToUpgrade2 = 60 -- Auto cliker upgrade

local Rotation = 0
local ScreenCenter = new("Vector2", screenWidth/2, screenHeight/2)

local isUpgradeOpen = false

local isLoaded = false

local lastClock = os.clock()
local UpgradeLastClock = os.clock()

local function iconDrawer()
    local iconRectangle = new("Rectangle", 0, 0, GroupLogo.width, GroupLogo.height)

    rl.BeginDrawing()

    rl.ClearBackground(rl.BLACK)

    DrawTexturePro(
        GroupLogo,
        iconRectangle,
        new("Rectangle", screenWidth/2, screenHeight/2, iconRectangle.width, iconRectangle.height),
        new("Vector2", GroupLogo.width / 2, GroupLogo.height / 2), -- center
        0,
        rl.WHITE
    )

    rl.DrawText("Made by the Puius Team.", 120, 450, 30, rl.RAYWHITE)
    rl.EndDrawing()
end

iconDrawer()
local tempClock = os.clock()

local function mineFunc(nr)
    Points = Points + nr
    CurrentHealth = CurrentHealth - nr

    rl.PlaySound(Mine)
end

local function changeCurrentPlanet(newPlanet, isBonus)
    if isBonus then
        CurrentPlanet = BonusPlanets[newPlanet]
        CurrentHealth = CurrentPlanet["MaxHealth"]
    else
        if CurrentHealth <= 0 then
        CurrentPlanet = Planets[newPlanet]
        CurrentHealth = CurrentPlanet["MaxHealth"]
        else
            CurrentPlanet = Planets[newPlanet]
            CurrentHealth = CurrentPlanet["Health"]    
        end
    end
end

repeat until (os.clock() - tempClock) >= 2

rl.PlayMusicStream(Music)

--                            <PROGRAM>                          --
while not rl.WindowShouldClose() do

--                   <CORE PARTS>               --
    Rotation = Rotation + 0.5
    local mousePos = rl.GetMousePosition()

    if rl.IsKeyPressed(rl.KEY_RIGHT) then 
        if CurrentPlanetLevel < UnlockedLevel then
            -- print("Changing current planet..")
           CurrentPlanetLevel = CurrentPlanetLevel + 1
           changeCurrentPlanet(CurrentPlanetLevel, false)
        end
    end

    if rl.IsKeyPressed(rl.KEY_LEFT) then
        if CurrentPlanetLevel ~= 1 then
            CurrentPlanetLevel = CurrentPlanetLevel - 1
            changeCurrentPlanet(CurrentPlanetLevel, false)
        end
    end

    local currentTime = os.clock() - lastClock
    rl.UpdateMusicStream(Music)

    if rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and isUpgradeOpen == false then
        local newParticTable = {
            ["Clock"] = os.clock(),
            ["pos"] = mousePos
        }

        Particle[#Particle + 1] = newParticTable
        mineFunc(miningPoints)
    end

    if rl.IsKeyPressed(rl.KEY_U) then
        if isUpgradeOpen then
            isUpgradeOpen = false
        else
            isUpgradeOpen = true
        end

        rl.PlaySound(Upgrade) 
    end

    if rl.IsKeyPressed(rl.KEY_O) and Points >= PointsToUpgrade2 then
        rl.PlaySound(Upgrade)

        Points = Points - PointsToUpgrade2

        PointsToUpgrade2 = PointsToUpgrade2 * 2
        autoMiningPoints = autoMiningPoints + 5
    end
    
    if currentTime >= 2 and autoMiningPoints > 0 then
        mineFunc(autoMiningPoints)
        lastClock = os.clock()
    end

    if CurrentHealth <= 0 then

        if MaxPlanetLevel ~= UnlockedLevel then
            UnlockedLevel = UnlockedLevel + 1
        end

        Points = Points + CurrentPlanet["Bonus"]

        local shouldBonus = math.random(1, 40)
        
        if shouldBonus > 36 then
            -- print("Bonus planet!")
            local rand = math.random(1, 100)

            if rand <= 75 then
                changeCurrentPlanet("Bronze", true)
            elseif rand > 75 and rand < 90 then
                changeCurrentPlanet("Gold", true)
            elseif rand > 90 then
                changeCurrentPlanet("Diamond", true)
            end
        else
            changeCurrentPlanet(CurrentPlanetLevel, false)
        end

        PlanetCircle = new("Rectangle", 0, 0, CurrentPlanet["Image"].width, CurrentPlanet["Image"].height)
end
--                   <CORE PARTS>               --
    -- Drawing
    rl.BeginDrawing()
    
    rl.ClearBackground(rl.BLACK)
    
    DrawTexturePro(Background, new("Rectangle", 0, 0, 600, 600), new("Rectangle", 0, 0, 600, 600), rl.Vector2Zero(), 0, rl.WHITE)
    
    DrawTexturePro(CurrentPlanet["Image"],
    PlanetCircle,
    new("Rectangle", screenWidth/2, screenHeight/2, PlanetCircle.width, PlanetCircle.height),
    new("Vector2", CurrentPlanet["Image"].width / 2, CurrentPlanet["Image"].height / 2), -- center
    Rotation,
    rl.WHITE
)

for i = 1, #Particle do
    if (os.clock() - Particle[i]["Clock"]) < 2 then
        Particle[i]["pos"] = Particle[i]["pos"] - new("Vector2", 0, 6)
        DrawText(""..miningPoints, Particle[i]["pos"].x, Particle[i]["pos"].y, 20, rl.RAYWHITE)
    else
       
    end
end

    if not isUpgradeOpen then
     
        -- Main text
     DrawText("Points: "..Points, 10, 10, 20, rl.RAYWHITE)
     DrawText("Press U to open the upgrade menu. ", 10, 30, 20, rl.RAYWHITE)
     DrawText("Press O to get an auto click. ("..PointsToUpgrade2.." Points)", 10, 50, 20, rl.RAYWHITE)
     DrawText("Health: "..CurrentHealth, 10, 580, 20, rl.RAYWHITE)
     DrawText("Planet Name: "..CurrentPlanet["Name"], 350, 580, 20 ,rl.RAYWHITE)
    
    end

    if isUpgradeOpen then
        local MiningPowerRec = new("Rectangle", screenWidth/2, screenHeight/2, 80, 40)
        local MiningPowerBounds = new("Rectangle", screenWidth/2 + -90, screenHeight/2 - 100, 70, 20)

        local frameRec = new("Rectangle", screenWidth/2 + 80 / 2, screenHeight/2 - 40 / 2, 300, 200)

        DrawRectanglePro(
        frameRec,
        new("Vector2", 160, 100),
        0,
        rl.RAYWHITE)

        DrawRectanglePro(
            MiningPowerRec,
            new("Vector2", 100, 100),
            0,
            rl.GRAY
        )

        DrawText("Mining power:", 208, 210 , 10, rl.RAYWHITE)
        DrawText(""..miningPoints, 209, 225, 10, rl.RAYWHITE)
        DrawText("Cost: "..PointsToUpgrade, 209, 245, 10, rl.GRAY)

        if (rl.CheckCollisionPointRec(mousePos, MiningPowerBounds)) == true and Points >= PointsToUpgrade then
            if rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT) and (os.clock() - UpgradeLastClock) >= 0.5 then
            
            Points = Points - PointsToUpgrade
            
            PointsToUpgrade = PointsToUpgrade * 3
            miningPoints = miningPoints * 2

            rl.PlaySound(Upgrade)
            UpgradeLastClock = os.clock()
        end
    end
end

    rl.EndDrawing()

    -- Value updating
    CurrentPlanet["Health"] = CurrentHealth
end

rl.CloseWindow()
rl.CloseAudioDevice()
rl.UnloadMusicStream(Music)