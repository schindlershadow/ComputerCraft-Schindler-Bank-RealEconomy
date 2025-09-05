local githubFilename = "dispenser.lua"
local githubFolder = "Dispenser"
local controllerURL = "https://raw.githubusercontent.com/schindlershadow/ComputerCraft-Schindler-Bank-RealEconomy/refs/heads/main/controller.lua"
local dropperRedstoneSide = "right"
local doorRedstoneSide = "left"
local speaker = peripheral.find("speaker")
local diskdrive = peripheral.find("drive")
local hopper = peripheral.find("minecraft:hopper")
local dropper = peripheral.find("minecraft:dropper")
local monitor = peripheral.find("monitor")
local width, height
local allowHopper = false

local function checkUpdates()
    print("Checking for updates")
    -- Set the GitHub repository information
    local owner = "schindlershadow"
    local repo = "ComputerCraft-Schindler-Bank-RealEconomy"

    -- Set the script file information
    local filepath = "startup.lua"
    -- Get the latest commit hash from the repository
    local commiturl = "https://api.github.com/repos/" ..
        owner .. "/" .. repo .. "/contents/" .. githubFolder .. "/" .. githubFilename
    local commitresponse = http.get(commiturl)
    if type(commitresponse) == "nil" then
        print("Failed to check for update")
        sleep(3)
        return
    end
    local responseCode = commitresponse.getResponseCode()
    if responseCode ~= 200 then
        print("Failed to check for update")
        sleep(3)
        return
    end
    local commitdata = commitresponse.readAll()
    commitresponse.close()
    local latestCommit = textutils.unserializeJSON(commitdata).sha

    local currentCommit = ""
    --Get the current commit sha
    if fs.exists("sha") then
        --Read the current file
        local file = fs.open("sha", "r")
        currentCommit = file.readAll()
        file.close()
    end

    print("Current SHA256: " .. tostring(currentCommit))

    -- Check if the latest commit is different from the current one
    if currentCommit ~= latestCommit then
        print("Update found with SHA256: " .. tostring(latestCommit))
        -- Download the latest script file
        local startupURL = "https://raw.githubusercontent.com/" ..
            owner .. "/" .. repo .. "/main/" .. githubFolder .. "/" .. githubFilename
        local response = http.get(startupURL)
        local data = response.readAll()
        response.close()

        --remove old version
        fs.delete(filepath)
        -- Save the downloaded file to disk
        local newfile = fs.open(filepath, "w")
        newfile.write(data)
        newfile.close()

        if fs.exists("sha") then
            fs.delete("sha")
        end
        --write new sha
        local shafile = fs.open("sha", "w")
        shafile.write(latestCommit)
        shafile.close()

        -- Print a message to the console
        print("Updated " .. githubFilename .. " to the latest version.")
        sleep(3)
        os.reboot()
    else
        print("No update found")
    end
end

--Dumps a table to string
local function dump(o)
    if type(o) == "table" then
        local s = ""
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s
    else
        return tostring(o)
    end
end

local function log(text)
    local logFile = fs.open("logs/server.log", "a")
    if type(text) == "string" then
        logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. text)
    else
        logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. textutils.serialise(text))
    end
    logFile.close()
end

local function debugLog(text)
    if settings.get("debug") then
        local logFile = fs.open("logs/serverDebug.log", "a")
        if type(text) == "string" then
            logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. text)
        else
            logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. textutils.serialise(text))
        end
        logFile.close()
    end
end

-- Returns true if any player is within maxDistance
local function playersNearby(maxDistance)
    local detector = peripheral.find("player_detector") -- or wrap("back") if you know the side
    if not detector then 
        print("No player detector found!")
        return false 
    end

    local players = detector.isPlayersInRange(maxDistance or 16) 
    return players
end

local function pullDisk(slot)
    if hopper ~= nil and diskdrive ~= nil then
        if hopper.getItemDetail(slot).name == "computercraft:pocket_computer_normal" or hopper.getItemDetail(slot).name == "computercraft:pocket_computer_advanced" then
            hopper.pushItems(peripheral.getName(diskdrive), slot, 1, 1)
        else
            print("Tried to pull nondisk item to disk drive")
            debugLog("Tried to pull nondisk item to disk drive")
        end
    else
        if hopper ~= nil then
            print("pullDisk: Hopper is nil")
        elseif diskdrive ~= nil then
            print("pullDisk: diskdrive is nil")
        end
    end
end

local function dumpDropper()
    if dropper == nil then
        print("dumpDropper: dropper is nil")
        dropper = peripheral.find("minecraft:dropper")
    end
    local itemList = dropper.list()
    local numOfItems = 0
    if itemList ~= nil then
        for slot, item in pairs(itemList) do
            numOfItems = numOfItems + item.count
        end
    end
    debugLog("numOfItems:" .. tostring(numOfItems))
    redstone.setOutput(dropperRedstoneSide, false)
    while numOfItems > 0 do
        redstone.setOutput(dropperRedstoneSide, true)
        sleep(0.1)
        redstone.setOutput(dropperRedstoneSide, false)
        numOfItems = numOfItems - 1
        sleep(0.1)
    end
end

local function dumpHopper()
    if dropper ~= nil and hopper ~= nil then
        local itemList = hopper.list()
        for k, v in pairs(itemList) do
            if v ~= nil and k ~= nil then
                dropper.pullItems(peripheral.getName(hopper), k)
                dumpDropper()
            end
        end
    end
    dumpDropper()
end

local function dumpDisk()
    if dropper ~= nil and diskdrive ~= nil then
        dropper.pullItems(peripheral.getName(diskdrive), 1)
    end
    dumpDropper()
end

local function centerText(text)
    if text == nil then
        text = ""
    end
    local x, y = monitor.getSize()
    local x1, y1 = monitor.getCursorPos()
    monitor.setCursorPos((math.floor(x / 2) - (math.floor(#text / 2))), y1)
    monitor.write(text)
end

local function drawTransition(color)
    local x,y = monitor.getSize()
    monitor.setBackgroundColor(color)
    for i = 1, y do
        --paintutils.drawLine(1, i, termX, i, color)
        monitor.setCursorPos(1,i)
        monitor.clearLine()
        sleep(0)
    end
end

local function loadingScreen(text)
    if playersNearby() then
    if type(text) == nil then
        text = ""
    end
    --monitor.setBackgroundColor(colors.red)
    --monitor.clear()
    drawTransition(colors.red)
    monitor.setCursorPos(1, 2)
    centerText(text)
    monitor.setCursorPos(1, 4)
    centerText("Loading...")
    monitor.setCursorPos(1, 6)
end
end

local function drawScreen(text)
    if type(text) == nil then
        text = ""
    end
    --monitor.setBackgroundColor(colors.red)
    --monitor.clear()
    drawTransition(colors.gray)
    monitor.setCursorPos(1, 2)
    centerText(text)
    monitor.setCursorPos(1, 4)
end

--Play audioFile on speaker
local function playAudio(audioFile)
    local dfpwm = require("cc.audio.dfpwm")
    local decoder = dfpwm.make_decoder()
    for chunk in io.lines(audioFile, 16 * 1024) do
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer, 3) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

--Play thank you audio
local function playAudioExit()
    playAudio("exit.dfpwm")
end

--Play new customer audio
local function playAudioNewCustomer()
    playAudio("new.dfpwm")
end

--Play returning customer audio
local function playAudioReturningCustomer()
    playAudio("returning.dfpwm")
end

--Play Deposit audio
local function playAudioDepositAccepted()
    playAudio("deposit.dfpwm")
end

local function writeControllerFile(slot)
    print("Starting writeControllerFile")
    print("Pulling pocket computer to diskdrive")
    pullDisk(slot)

    print("Getting newest controller software")
    local response = http.get(controllerURL)
    local contents = response.readAll()
    response.close()

    
    monitor.setBackgroundColor(colors.gray)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.black)
    monitor.clearLine()
    centerText("Schindler Controller Writer")
    monitor.setCursorPos(1, 3)
    monitor.setBackgroundColor(colors.gray)
    centerText("Pocket Computer Dectected!")
    monitor.setCursorPos(1, 5)
    centerText("Writing")
    monitor.setCursorPos(1, 6)
    centerText("Controller software...")
    monitor.setCursorPos(1, 9)
    centerText("Please wait")
    --monitor.setBackgroundColor(colors.blue)
    
    monitor.clearLine()
    centerText("Checking for free space")
    print("Checking for free space")
    if diskdrive == nil then
        print("diskdrive is nil, check settings")
        diskdrive = peripheral.find("drive")
        if diskdrive == nil then
            print("diskdrive is still nil, aborting writeControllerFile")
            dumpHopper()
            return
        end
    end
    local freespace = fs.getFreeSpace(diskdrive.getMountPath())

    if type(freespace) == "number" then
        if freespace < 10000 then
            local files = fs.list("/" .. diskdrive.getMountPath())
            for i = 1, #files do
                print("deleting " .. files[i])
                fs.delete("/" .. diskdrive.getMountPath() .. "/" .. files[i])
            end
        end
    end

    freespace = fs.getFreeSpace(diskdrive.getMountPath())
    if type(freespace) == "number" then
        if freespace < 10000 then
            print("No space on disk")
            dumpDisk()
            dumpHopper()
            return
        end
    end

    monitor.clearLine()
    centerText("Writing startup file")
    print("Writing startup file")
    local startupFile = fs.open(diskdrive.getMountPath() .. "/startup.lua", "w")
    startupFile.write(contents)
    startupFile.close()
    --[[
    monitor.setCursorPos(1, 7)
    centerText("Complete!")
    monitor.setCursorPos(1, 9)
    centerText("Make sure to restart")
    --]]
    monitor.clearLine()
    centerText("Done!")
    print("Returning Pocket Computer")
    monitor.setCursorPos(1, 11)
    centerText("\25\25\25 Pickup your Computer")
    dumpDisk()
    dumpHopper()

    --[[
    monitor.setCursorPos(1, 19)
    centerText("Dont forget your Pocket computer!")
    monitor.setCursorPos(1, 20)
    centerText("\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27")
    monitor.setCursorPos(1, 21)
    centerText("\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27\27")
    sleep(5)
    ]]
end

--Background thread that will always write controller software on pocket computers
local function controllerWriteHandler()
    print("Starting controllerWriteHandler")
    while true do
        if hopper ~= nil then
            local itemList = hopper.list()
            if itemList ~= nil and allowHopper == false then
                for slot, item in pairs(itemList) do
                    debugLog(item.name)
                    if item.name == "computercraft:pocket_computer_normal" or item.name == "computercraft:pocket_computer_advanced" then
                        writeControllerFile(slot)
                        --dumpHopper()
                        --drawMonitor()
                        playAudioNewCustomer()
                    else
                        dumpHopper()
                    end
                end
            end
        else
            print("Hopper is nil, check settings")
            hopper = peripheral.find("minecraft:hopper")
        end
        sleep(1)
    end
end

local function drawMonitor()
    monitor.setTextScale(1)
    monitor.setCursorPos(1, 1)
    drawTransition(colors.blue)
    while true do
        if playersNearby() then
        --code = math.random(1000, 9999)
        --print("code: " .. tostring(code))
        monitor.setBackgroundColor(colors.blue)
        monitor.clear()
        
        monitor.setCursorPos(1, 1)
        monitor.setBackgroundColor(colors.black)
        monitor.clearLine()
        centerText("Schindler Dispenser")
        monitor.setCursorPos(1, 3)
        monitor.setBackgroundColor(colors.blue)
        monitor.write("Welcome to Schindler's Arcade")
        monitor.setCursorPos(1, 5)
        monitor.write("You need a controller to play")
        monitor.setCursorPos(1, 9)
        centerText("Please Throw")
        monitor.setCursorPos(1, 10)
        centerText("Wireless Pocket Computer")
        monitor.setCursorPos(1, 11)
        centerText("into the hopper \25\25\25")

        monitor.setCursorPos(1, 12)
        monitor.setTextColor(colors.white)
        monitor.setBackgroundColor(colors.blue)

        --codeServer()
        --loginScreen()
        end
        sleep(5)
    end
end

local function onStart()
    os.setComputerLabel("Dispenser ID:" .. os.getComputerID())
    --clear out old log
    if fs.exists("logs/server.log") then
        fs.delete("logs/server.log")
    end
    if fs.exists("logs/serverDebug.log") then
        fs.delete("logs/serverDebug.log")
    end
    --Close any old connections and servers
    redstone.setOutput(doorRedstoneSide, false)
    redstone.setOutput(dropperRedstoneSide, false)

    
    width, height = monitor.getSize()
    monitor.setTextScale(0.5)
    loadingScreen("ATM is loading, please wait....")

    dumpDisk()
    dumpHopper()
    dumpDropper()
    drawMonitor()
end



if not settings.get("debug") then
    checkUpdates()
end

print("Client is loading, please wait....")


if not settings.get("debug") then
    --Staggered launch
    sleep(1 + math.random(5))
end



--Main loop
parallel.waitForAny(controllerWriteHandler, onStart)

--exit cleanup
redstone.setOutput(doorRedstoneSide, false)
redstone.setOutput(dropperRedstoneSide, false)
