local screenWidth, screenHeight = 600, 600
local Version = 0.3

setmetatable(_G, {__index = rl})


 InitWindow(screenWidth, screenHeight, "Planet Miner - "..Version)
 InitAudioDevice()

repeat until  IsAudioDeviceReady()
local Loaded = false
local Mine = new("Sound",  LoadSound("Mine.wav"))
local Upgrade = new("Sound",  LoadSound("Upgrade.wav"))

local Music = new("Music",  LoadMusicStream("music.xm"))
 PlayMusicStream(Music)
 SetTargetFPS(60)

local Background =  LoadTexture("Background.png")

local GroupLogo =  LoadTexture("NoBackgroundPuius.png")

local Particle = {}

local Planets = {
    [1] = {
        -- Earth
        ["Image"] =  LoadTexture("Earth.png"),
        ["Health"] = 2000,
        ["Bonus"] = 150,
        ["Name"] = "Earth",
        ["MaxHealth"] = 2000
    },

    [2] = {
        -- Mars
        ["Image"] = LoadTexture("Mars.png"),
        ["Health"] = 4000,
        ["Bonus"] = 350,
        ["Name"] = "Mars",
        ["MaxHealth"] = 4000
    },

    [3] = {
        -- Venus
        ["Image"] =  LoadTexture("Venus.png"),
        ["Health"] = 6000,
        ["Bonus"] = 1000,
        ["Name"] = "Venus",
        ["MaxHealth"] = 6000
    },

    [4] = {
        -- Saturn
        ["Image"] = LoadTexture("Saturn.png"),
        ["Health"] = 10000,
        ["Bonus"] = 4000,
        ["Name"] = "Saturn",
        ["MaxHealth"] = 10000
    }
}

local BonusPlanets = {
    ["Diamond"] = {
        ["Image"] =  LoadTexture("DiamondPlanet.png"),
        ["Health"] = 4500, -- 4500
        ["Bonus"] = 10000,
        ["Name"] = "Diamond",
        ["MaxHealth"] = 2000,
    },
    ["Bronze"] = {
        ["Image"] =  LoadTexture("Bronze.png"),
        ["Bonus"] = 2000,
        ["Health"] = 2000,
        ["Name"] = "Bronze",
        ["MaxHealth"] = 2000
    },
    
    ["Gold"] = {
        ["Image"] =  LoadTexture("Gold.png"),
        ["Bonus"] = 5000,
        ["Health"] = 3500,
        ["Name"] = "Gold",
        ["MaxHealth"] = 3500
    },
}

local function loadData(dataName)
    local file = io.open("DataSaver\\"..dataName..".txt")

    if file then
     local data = file:read()
     file:close()
     return tonumber(data)
    end
    return nil
end

local function saveData(dataName, data)
    pcall(function()
        os.execute("mkdir ".."DataSaver")
        local file = io.open("DataSaver\\"..dataName..".txt", "w")

        file:write(data)
        file:close()
    end)
end

local CurrentPlanet = Planets[1]

local CurrentPlanetLevel = 1
local MaxPlanetLevel = 4
local UnlockedLevel = loadData("UnlockedLevel") or 1

local CurrentHealth = CurrentPlanet["Health"]

-- screenWidth/2 - texture.width/2, screenHeight/2 - texture.height/2, WHITE

local Points = loadData("Points") or 0
local PointsToUpgrade = loadData("PointsToUpgrade") or 10
local miningPoints = loadData("miningPoints") or 1
local autoMiningPoints = loadData("autoMiningPoints") or 1
local PointsToUpgrade2 = loadData("PointsToUpgrade2") or 60 -- Auto cliker upgrade

local Rotation = 0
local ScreenCenter = new("Vector2", screenWidth/2, screenHeight/2)

local isUpgradeOpen = false

local isLoaded = false

local lastClock = os.clock()
local UpgradeLastClock = os.clock()
local programClock = os.clock()

local function clean()
     UnloadSound(Mine)
     UnloadSound(Upgrade)
     UnloadMusicStream(Music)
     StopSoundMulti()
     CloseWindow()
     CloseAudioDevice()

     saveData("Points", Points)
     saveData("UnlockedLevel", UnlockedLevel)
     saveData("autoMiningPoints", autoMiningPoints)
     saveData("miningPoints", miningPoints)
     saveData("PointsToUpgrade", PointsToUpgrade)
     saveData("PointsToUpgrade2", PointsToUpgrade2)
end

local function iconDrawer()
    local iconRectangle = new("Rectangle", 0, 0, GroupLogo.width, GroupLogo.height)

     BeginDrawing()

     ClearBackground( BLACK)

    DrawTexturePro(
        GroupLogo,
        iconRectangle,
        new("Rectangle", screenWidth/2, screenHeight/2, iconRectangle.width, iconRectangle.height),
        new("Vector2", GroupLogo.width / 2, GroupLogo.height / 2), -- center
        0,
         WHITE
    )

     DrawText("Made by the Puius Team.", 120, 450, 30,  RAYWHITE)
     EndDrawing()
end

iconDrawer()
local tempClock = os.clock()

local function mineFunc(nr)
    Points = Points + nr
    CurrentHealth = CurrentHealth - nr

    PlaySoundMulti(Mine)
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

--                            <PROGRAM>                          --
while not  WindowShouldClose() do

--                   <CORE PARTS>               --

pcall(function()
     UpdateMusicStream(Music)
end)

     local PlanetCircle = new("Rectangle", 0, 0, CurrentPlanet["Image"].width, CurrentPlanet["Image"].height)

    Rotation = Rotation + 0.5
    local mousePos =  GetMousePosition()

    if  IsKeyPressed( KEY_RIGHT) then 
        if CurrentPlanetLevel < UnlockedLevel then
            -- print("Changing current planet..")
           CurrentPlanetLevel = CurrentPlanetLevel + 1
           changeCurrentPlanet(CurrentPlanetLevel, false)
        end
    end

    if  IsKeyPressed( KEY_LEFT) then
        if CurrentPlanetLevel ~= 1 then
            CurrentPlanetLevel = CurrentPlanetLevel - 1
            changeCurrentPlanet(CurrentPlanetLevel, false)
        end
    end

    local currentTime = os.clock() - lastClock

    if  IsMouseButtonPressed( MOUSE_BUTTON_LEFT) and isUpgradeOpen == false then
        local newParticTable = {
            ["Clock"] = os.clock(),
            ["pos"] = mousePos
        }

        Particle[#Particle + 1] = newParticTable
        mineFunc(miningPoints)
    end

    if  IsKeyPressed( KEY_U) then
        if isUpgradeOpen then
            isUpgradeOpen = false
        else
            isUpgradeOpen = true
        end

        PlaySoundMulti(Upgrade) 
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
     BeginDrawing()
    
     ClearBackground( BLACK)
    
    DrawTexturePro(Background, new("Rectangle", 0, 0, 600, 600), new("Rectangle", 0, 0, 600, 600),  Vector2Zero(), 0,  WHITE)
    
    DrawTexturePro(CurrentPlanet["Image"],
    PlanetCircle,
    new("Rectangle", screenWidth/2, screenHeight/2, PlanetCircle.width, PlanetCircle.height),
    new("Vector2", CurrentPlanet["Image"].width / 2, CurrentPlanet["Image"].height / 2), -- center
    Rotation,
     WHITE
)

for i = 1, #Particle do
    if (os.clock() - Particle[i]["Clock"]) < 2 then
        Particle[i]["pos"] = Particle[i]["pos"] - new("Vector2", 0, 6)
        DrawText(""..miningPoints, Particle[i]["pos"].x, Particle[i]["pos"].y, 20,  RAYWHITE)
    else
       
    end
end

    if not isUpgradeOpen then
     
        -- Main text
     DrawText("Points: "..Points, 10, 10, 20,  RAYWHITE)
     DrawText("Press U to open the upgrade menu. ", 10, 30, 20,  RAYWHITE)
     DrawText("Health: "..CurrentHealth, 10, 580, 20,  RAYWHITE)
     DrawText("Planet Name: "..CurrentPlanet["Name"], 350, 580, 20 , RAYWHITE)
    
    end

    if isUpgradeOpen then
        local MiningPowerRec = new("Rectangle", screenWidth/2, screenHeight/2, 80, 40)
        local MiningPowerBounds = new("Rectangle", screenWidth/2 + -90, screenHeight/2 - 100, 70, 20)
        local AutoMiningRec = new("Rectangle", screenWidth/2 + 20, screenHeight/2 + -1, 80, 40)
        local AutoMiningBounds = new("Rectangle", screenWidth/2 + 20, screenHeight/2 + -100, 80, 40)

        local frameRec = new("Rectangle", screenWidth/2 + 80 / 2, screenHeight/2 - 40 / 2, 300, 200)

        DrawRectanglePro(
        frameRec,
        new("Vector2", 160, 100),
        0,
         RAYWHITE)

        DrawRectanglePro(
            MiningPowerRec,
            new("Vector2", 100, 100),
            0,
             GRAY
        )

        DrawRectanglePro(
            AutoMiningRec,
            new("Vector2", 10, 100),
            0,
             GRAY
        )


        DrawText("Mining power:", 208, 210 , 10,  RAYWHITE)
        DrawText(""..miningPoints, 209, 225, 10,  RAYWHITE)
        DrawText("Cost: "..PointsToUpgrade, 209, 245, 10,  GRAY)
        DrawText("Cost: "..PointsToUpgrade2, 320, 245, 10,  GRAY)
        DrawText("Miners: ", 320, 208, 10,  RAYWHITE)
        DrawText(""..autoMiningPoints, 320, 225, 10,  RAYWHITE)

        if ( CheckCollisionPointRec(mousePos, MiningPowerBounds)) == true and Points >= PointsToUpgrade then
            if  IsMouseButtonDown( MOUSE_BUTTON_LEFT) and (os.clock() - UpgradeLastClock) >= 0.5 then
            
            Points = Points - PointsToUpgrade
            
            PointsToUpgrade = PointsToUpgrade * 3
            miningPoints = miningPoints * 2

            PlaySoundMulti(Upgrade)
            UpgradeLastClock = os.clock()
        end
    elseif  CheckCollisionPointRec(mousePos, AutoMiningBounds) == true and Points >= PointsToUpgrade2 then
        -- print("Buying miners..")
        if  IsMouseButtonDown( MOUSE_BUTTON_LEFT) and (os.clock() - UpgradeLastClock) >= 0.5 then
            
            Points = Points - PointsToUpgrade2
            
            PointsToUpgrade2 = PointsToUpgrade2 * 3
            autoMiningPoints = autoMiningPoints * 2

            PlaySoundMulti(Upgrade)
            UpgradeLastClock = os.clock()
        end
    end
end

     EndDrawing()

    -- Value updating
    CurrentPlanet["Health"] = CurrentHealth

    -- print(os.clock() - programClock.." since last tick!")
    -- programClock = os.clock()
end

clean()