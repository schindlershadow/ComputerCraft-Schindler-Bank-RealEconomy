
local width, height = term.getSize()

local totalDownloaded = 0

local function update(text)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.setCursorPos(1, 9)
	term.clearLine()
	term.setCursorPos(math.floor(width/2 - string.len(text)/2 + 0.5), 9)
	write(text)
end

local function bar(ratio)
	term.setBackgroundColor(colors.gray)
	term.setTextColor(colors.lime)
	term.setCursorPos(1, 11)

	for i = 1, width do
		if (i/width < ratio) then
			write("]")
		else
			write(" ")
		end
	end
end

local function download(path, attempt)
	local rawData = http.get("https://raw.githubusercontent.com/Xella37/CCDoom/master/"..path)
	update("Downloaded " .. path .. "!")
	if not rawData then
		if attempt == 3 then
			error("Failed to download " .. path .. " after 3 attempts!")
		end
		update("Failed to download " .. path .. ". Trying again (attempt " .. (attempt+1) .. "/3)")
		return download(path, attempt+1)
	end
	local data = rawData.readAll()
	local file = fs.open(path, "w")
	file.write(data)
	file.close()
end

local function downloadAll(downloads, total)
	local nextFile = table.remove(downloads, 1)
	if nextFile then
		sleep(0.1)
		parallel.waitForAll(function()
			downloadAll(downloads, total)
		end, function()
			download(nextFile, 1)
			totalDownloaded = totalDownloaded + 1
			bar(totalDownloaded / total)
		end)
	end
end

function install()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.yellow)
	term.clear()

	local str = "CCDoom Installer"
	term.setCursorPos(math.floor(width/2 - #str / 2 + 0.5), 2)
	write(str)

	update("Installing...")
	bar(0)

	local total = 36

	local folders = {
		"models",
		"images",
		"levels",
	}

	local downloads = {
		"Doom.lua",
		"Pine3D-minified.lua",
		"betterblittle.lua",
		"blittle",
		"README.md",
		"LICENSE",
		"models/corpse",
		"models/doorx",
		"models/doorz",
		"models/emerald",
		"models/enemy1",
		"models/enemy2",
		"models/wallx",
		"models/wallxz",
		"models/wallz",
		"levels/level1",
		"levels/level2",
		"levels/level3",
		"levels/level4",
		"levels/level5",
		"levels/level6",
		"levels/level7",
		"levels/level8",
		"levels/level9",
		"images/bfire",
		"images/bgun",
		"images/bgunf",
		"images/bheart",
		"images/fire",
		"images/gun",
		"images/gunf",
		"images/heart",
		"images/logo",
	}

	local total = #folders + #downloads

	for i = 1, #folders do
		local folder = folders[i]
		update("Creating " .. folder .. " folder...")
		fs.makeDir(folder)
		bar(i/total)
	end

	totalDownloaded = #folders
	downloadAll(downloads, total)

	update("Installation finished!")

	sleep(1)

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()

	term.setCursorPos(1, 1)
	write("Finished installation!\nPress any key to close...")

	os.pullEventRaw()

	term.clear()
	term.setCursorPos(1, 1)
end

install()