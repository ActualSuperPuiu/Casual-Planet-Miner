-- this function converts a string to base64
function to_base64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
 
-- this function converts base64 to string
function from_base64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local screenWidth, screenHeight = 600, 600
local Version = 0.4

setmetatable(_G, {__index = rl})


 InitWindow(screenWidth, screenHeight, "Planet Miner - "..Version)
 InitAudioDevice()

repeat until  IsAudioDeviceReady()
local Loaded = false
local Mine = new("Sound",  LoadSound("Mine.wav"))
local Upgrade = new("Sound",  LoadSound("Upgrade.wav"))

local Music = new("Music", LoadMusicStream("music.xm"))

PlayMusicStream(Music)
SetTargetFPS(60)

local Background =  LoadTexture("Background.png")
local GroupLogo =  LoadTexture("NoBackgroundPuius.png")
local UFO = LoadTexture("UFO.png")

local AsteroidData = {
    ["AsteroidPosition"] = new("Vector2", 0, 0),
    ["AsteroidSpawned"] = false,
    ["IsAsteroidMined"] = false,
    ["AsteroidClock"] = 0,
    ["Health"] = 0,
    ["MaxHealth"] = 0,
    ["Bonus"] = 0,
    ["Name"] = "Asteroid",
    ["Image"] = LoadTexture("Asteroid.png")
}

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
        local newData
     local data = file:read()
     file:close()

     if data then
        newData = from_base64(tostring(data))
     end

     return tonumber(newData)
    end
    return nil
end

local function saveData(dataName, data)
    pcall(function()
        os.execute("mkdir ".."DataSaver")
        local file = io.open("DataSaver\\"..dataName..".txt", "w")

        local newData = to_base64(tostring(data))

        file:write(newData)
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

    if  IsKeyPressed(KEY_LEFT) then
        if CurrentPlanetLevel ~= 1 then
            CurrentPlanetLevel = CurrentPlanetLevel - 1
            changeCurrentPlanet(CurrentPlanetLevel, false)
        end
    end

    if IsKeyPressed(KEY_SPACE) then
        if AsteroidData["AsteroidSpawned"] == true then
            CurrentPlanet = AsteroidData
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
    
     ClearBackground(BLACK)
    
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
     DrawText("Cash: "..Points, 10, 10, 20,  RAYWHITE)
     DrawText("Press U to open the upgrade menu. ", 10, 30, 20,  RAYWHITE)
     DrawText("Health: "..CurrentHealth, 10, 580, 20,  RAYWHITE)
     DrawText("Planet Name: "..CurrentPlanet["Name"], 350, 580, 20 , RAYWHITE)
    
    end

    if isUpgradeOpen then
        local MiningPowerRec = new("Rectangle", screenWidth/2, screenHeight/2, 80, 40)
        local MiningPowerBounds = new("Rectangle", screenWidth/2 + -90, screenHeight/2 - 100, 70, 20)
        local AutoMiningRec = new("Rectangle", screenWidth/2 + 20, screenHeight/2 + -1, 80, 40)
        local AutoMiningBounds = new("Rectangle", screenWidth/2 + 20, screenHeight/2 + -100, 80, 40)

        local frameRec = new("Rectangle", screenWidth/2 + 60 / 2, screenHeight/2 - 40 / 2, 300, 200)

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
    if AsteroidData["AsteroidSpawned"] and AsteroidData["AsteroidClock"] ~= 0 and (os.clock() - AsteroidData["AsteroidClock"]) <= 2 then
       AsteroidData["AsteroidPosition"] = AsteroidData["AsteroidPosition"] + new("Vector2", 5, 5)
       DrawRectangleV(AsteroidData["AsteroidPosition"], new("Vector2",20, 20), GRAY)
    elseif AsteroidData["AsteroidSpawned"] == false then
        local rand = math.random(0, 1000)

        if rand == 800 then
            local Health = math.random(100, 1000) * (miningPoints / 2)

            AsteroidData["AsteroidSpawned"] = true
            AsteroidData["AsteroidClock"] = os.clock()
            AsteroidData["MaxHealth"] = Health
            AsteroidData["Health"] = Health
            AsteroidData["Bonus"] = miningPoints * autoMiningPoints

        else
            AsteroidData["AsteroidSpawned"] = false
            AsteroidData["AsteroidClock"] = 0
        end

    end
    -- Value updating
    CurrentPlanet["Health"] = CurrentHealth

    -- print(os.clock() - programClock.." since last tick!")
    -- programClock = os.clock()

    EndDrawing()
end

clean()