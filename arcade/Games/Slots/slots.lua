local speaker = peripheral.find("speaker");
local chatbox = peripheral.find("chat_box");
local dfpwm = require("cc.audio.dfpwm");
local decoder = dfpwm.make_decoder();
local limit = tonumber(settings.get("maxBet"));
local quit = false;
local jackpot = 0;
local tArgs = {
	...
};
local username = tArgs[1];
local credits = 0;
local diamondW = 2;
local dollarW = 13;
local sevenW = 15;
local bellW = 25;
local orangeW = 12;
local orangech = 30;
local diamondch = 5;
local bellch = 20;
local sevench = 15;
local dollarch = 10;
local a = 0;
local b = diamondch;
local c = b + bellch;
local d = c + sevench;
local e = d + dollarch;
local f = e + orangech;
local g = 100;
local aW = 0;
local bW = diamondW;
local cW = bW + dollarW;
local dW = cW + sevenW;
local eW = dW + bellW;
local fW = eW + orangeW;
local gW = 100;
local creds = 0;
local nr1 = 0;
multeplier = 0;
local amount = limit;
local diamond = paintutils.loadImage("images/diamond.nfp");
local bell = paintutils.loadImage("images/bell.nfp");
local seven = paintutils.loadImage("images/7.nfp");
local dollar = paintutils.loadImage("images/dollar.nfp");
local orange = paintutils.loadImage("images/orange.nfp");
local none = paintutils.loadImage("images/none.nfp");
local offset = 2;
local termX, termY = term.getSize();
local function sysLog(msg)
	local urlMsg = textutils.urlEncode("label:" .. os.getComputerLabel() .. " ID:" .. os.getComputerID() .. " slots:" .. msg);
	local url = "https://schindlershadow.duckdns.org/log.php?msg=" .. urlMsg;
	local response = http.get(url);
	if response then
		response.close();
	end;
end;
local function log(text)
	local logFile = fs.open("logs/slots.log", "a");
	if type(text) == "string" then
		logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. text);
	else
		logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. textutils.serialise(text));
	end;
	logFile.close();
end;
if fs.exists("logs/slots.log") then
	fs.delete("logs/slots.log");
end;
local function centerText(text)
	if term ~= nil then
		if text == nil then
			text = "";
		end;
		local x, y = term.getSize();
		local x1, y1 = term.getCursorPos();
		term.setCursorPos(math.floor(x / 2) - math.floor((#text) / 2), y1);
		term.write(text);
	end;
end;
local function drawTransition(color)
	local x, y = term.getSize();
	term.setBackgroundColor(color);
	for i = 1, y do
		term.setCursorPos(1, i);
		term.clearLine();
		sleep(0);
	end;
end;
local function loadingScreen(text)
	if type(text) == nil then
		text = "";
	end;
	local x, y = term.getSize();
	term.setBackgroundColor(colors.red);
	term.setCursorPos(1, y);
	centerText(text);
	term.setCursorPos(1, 4);
	term.setCursorPos(1, 6);
end;
local function drawBox(startX, startY, endX, endY, color)
	paintutils.drawFilledBox(startX + offset, startY + offset, endX + offset, endY + offset, color);
end;
local function drawLine(startX, startY, endX, endY, color)
	paintutils.drawLine(startX + offset, startY + offset, endX + offset, endY + offset, color);
end;
local function drawImage(image, x, y)
	paintutils.drawImage(image, x + offset, y + offset);
end;
local function drawTransition()
	for i = 1, termY do
		if i == 1 then
			paintutils.drawLine(1, i, termX, i, colors.black);
		elseif i < 5 then
			paintutils.drawLine(1, i, termX, i, colors.blue);
		else
			paintutils.drawLine(1, i, termX, i, colors.green);
		end;
		sleep(0);
	end;
end;
local function centerText(text)
	if text == nil then
		text = "";
	end;
	local x, y = term.getSize();
	local x1, y1 = term.getCursorPos();
	term.setCursorPos(math.floor(x / 2) - math.floor((#text) / 2), y1);
	term.write(text);
end;
local function debugLog(text)
	if settings.get("debug") then
		local logFile = fs.open("logs/slotsDebug.log", "a");
		if type(text) == "string" then
			logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. text);
		else
			logFile.writeLine(os.date("%A/%d/%B/%Y %I:%M%p") .. ", " .. textutils.serialise(text));
		end;
		logFile.close();
	end;
end;
if fs.exists("logs/slotsDebug.log") then
	fs.delete("logs/slotsDebug.log");
end;
-- Toast helper
local function sendToast(username, title, msg)
    if chatbox and chatbox.sendToastToPlayer then
        chatbox.sendToastToPlayer(msg, title, username, "&4&lBank", "()", "&c&l")
    end
end
debugLog("bW: " .. tostring(bW));
debugLog("cW: " .. tostring(cW));
debugLog("dW: " .. tostring(dW));
debugLog("eW: " .. tostring(eW));
debugLog("fW: " .. tostring(fW));
local function playAudio(path)
	if not speaker then
		print("No speaker found");
		return;
	end;
	if not fs.exists(path) then
		print("Missing audio file: " .. path);
		return;
	end;
	local file = assert(io.open(path, "rb"));
	for chunk in function()
		return file:read(16 * 1024);
	end do
		local buffer = decoder(chunk);
		while not speaker.playAudio(buffer, 3) do
			os.pullEvent("speaker_audio_empty");
		end;
	end;
	file:close();
end;
local function getJackpot()
	if fs.exists("jackpot") then
		local file = fs.open("jackpot", "r");
		local contents = file.readAll();
		if tonumber(contents) == nil then
			jackpot = 0;
		else
			jackpot = tonumber(contents);
		end;
		file.close();
	else
		jackpot = 0;
	end;
end;
local function setJackpot(number)
	number = math.floor(number);
	if fs.exists("jackpot") then
		fs.delete("jackpot");
	end;
	local file = fs.open("jackpot", "w");
	file.write(number);
	file.close();
	jackpot = number;
end;
local function drawJackpot()
	term.setTextColor(colors.white);
	playAudio("jackpot.dfpwm");
	for i = 1, 10 do
		if i % 2 == 0 then
			term.setBackgroundColor(colors.blue);
		else
			term.setBackgroundColor(colors.red);
		end;
		term.clear();
		term.setCursorPos(1, 11);
		centerText("JACKPOT WINNER");
		term.setCursorPos(1, 13);
		centerText("\167" .. tostring(jackpot) .. " CREDITS");
		paintutils.drawImage(diamond, 2, 2);
		paintutils.drawImage(diamond, 10, 2);
		paintutils.drawImage(diamond, 20, 2);
		paintutils.drawImage(diamond, 30, 2);
		paintutils.drawImage(diamond, 40, 2);
		paintutils.drawImage(diamond, termX - 8, 2);
		paintutils.drawImage(diamond, 2, 7);
		paintutils.drawImage(diamond, 2, 13);
		paintutils.drawImage(diamond, termX - 8, 7);
		paintutils.drawImage(diamond, termX - 8, 13);
		paintutils.drawImage(diamond, 2, 19);
		paintutils.drawImage(diamond, 10, 19);
		paintutils.drawImage(diamond, 20, 19);
		paintutils.drawImage(diamond, 30, 19);
		paintutils.drawImage(diamond, 40, 19);
		paintutils.drawImage(diamond, termX - 8, 19);
		sleep(0.5);
	end;
	sleep(1);
end;
local function drawRandomImage(x, y)
	local randomNum = math.random(5);
	if randomNum == 1 then
		paintutils.drawImage(seven, x, y);
	elseif randomNum == 2 then
		paintutils.drawImage(orange, x, y);
	elseif randomNum == 3 then
		paintutils.drawImage(dollar, x, y);
	elseif randomNum == 4 then
		paintutils.drawImage(bell, x, y);
	else
		paintutils.drawImage(diamond, x, y);
	end;
end;
local function drawNoCredits()
	term.setBackgroundColor(colors.black);
	term.clear();
	paintutils.drawImage(paintutils.loadImage("/dollar"), 1, 1);
	term.setBackgroundColor(colors.black);
	term.setTextColor(colors.white);
	term.setCursorPos(1, 11);
	centerText("You're ruined!");
	term.setCursorPos(1, 13);
	term.setTextColor(colors.red);
	centerText("\1670 Credits");
	term.setTextColor(colors.white);
	sleep(5);
end;
local function getCredits()
	if type(username) ~= "string" then
		return 0;
	end;
	local _, out = commands.bal(username);
	for _, line in ipairs(out) do
		local amt = line:match("([%d%.]+)");
		if amt then
			credits = tonumber(amt);
			return amt;
		end;
	end;
	credits = 0;
	return 0;
end;
local function addCredits(value)
	if type(username) ~= "string" then
		return false;
	end;
	if type(value) ~= "number" then
		return false;
	end;
	loadingScreen("Processing payment...");
	local ok, msg, num = commands.reco("add " .. username .. " Dollar " .. tostring(value));
	log("reco add " .. username .. " Dollar " .. tostring(value));
	debugLog("ok " .. tostring(ok) .. " msg " .. tostring(msg) .. " num " .. tostring(num));
	sysLog(username .. ": +" .. tostring(value) .. " $" .. tostring(getCredits(username)));
    sendToast(username, "Payment Processed - Arcade: " .. tostring(os.getComputerLabel()), "+$" .. tostring(value) .. " for " .. settings.get("gameName"));
	return true;
end;
local function removeCredits(value)
	if type(username) ~= "string" then
		return false;
	end;
	if type(value) ~= "number" then
		return false;
	end;
	loadingScreen("Processing payment...");
	local ok, msg, num = commands.reco("remove " .. username .. " Dollar " .. tostring(value));
	log("reco remove " .. username .. " Dollar " .. tostring(value));
	debugLog("ok " .. tostring(ok) .. " msg " .. tostring(msg) .. " num " .. tostring(num));
	sysLog(username .. ": -" .. tostring(value) .. " $" .. tostring(getCredits(username)));
    sendToast(username, "Payment Processed - Arcade: " .. tostring(os.getComputerLabel()), "-$" .. tostring(value) .. " for " .. settings.get("gameName"));
	return true;
end;
local function pay(amount)
    if settings.get("debug") then
		return true;
	end
	if type(username) == "string" and type(amount) == "number" then
		local credits = getCredits(username);
		if credits - amount >= 0 then
			log("Credits change: user:" .. username .. " amount:" .. tostring((-1) * amount));
			if amount == 0 then
				return true;
			end;
			if amount > 0 then
				removeCredits(amount);
			elseif amount ~= 0 then
				addCredits((-1) * amount);
			end;
			return true;
		else
			return false;
		end;
	end;
end;
local function readkb()
	local string = "";
	local event, key;
	local x, y = term.getCursorPos();
	while true do
		term.setCursorPos(x, y);
		term.write(string);
		repeat
			event, key = os.pullEvent();
		until event == "key" or event == "char";
		if event == "char" then
			string = string .. key;
		elseif event == "key" then
			if key == keys.backspace then
				string = string:sub(1, -2);
				term.setCursorPos(x, y);
				term.write("         ");
			elseif key == keys.enter or key == keys.numPadEnter then
				return string;
			end;
		end;
	end;
end;
function insert_amount()
	amount = 1;
	term.setBackgroundColor(colors.green);
	term.clear();
	while true do
		if credits == 0 then
			debugLog("drawNoCredits");
			drawNoCredits();
			quit = true;
			return;
		end;
		term.clear();
		term.setCursorPos(1, 1);
		term.setBackgroundColor(colors.black);
		term.setTextColor(colors.white);
		term.clearLine();
		centerText("Schindler Slots");
		term.setBackgroundColor(colors.blue);
		term.setCursorPos(1, 2);
		term.clearLine();
		term.setCursorPos(1, 3);
		term.clearLine();
		term.setTextColor(colors.red);
		centerText("JACKPOT \167" .. tostring(jackpot));
		term.setCursorPos(1, 4);
		term.clearLine();
		term.setBackgroundColor(colors.green);
		term.setTextColor(colors.white);
		term.setCursorPos(22, 7);
		term.write("Dollars: ");
		term.setTextColor(colors.lime);
		term.write("\167" .. tostring(credits));
		term.setTextColor(colors.white);
		term.setCursorPos(22, 9);
		term.write("Max Bet: ");
		term.setTextColor(colors.blue);
		term.write("\167" .. tostring(limit));
		term.setTextColor(colors.white);
		term.setCursorPos(18, 10);
		term.write("Min JackPot Bet: ");
		term.setTextColor(colors.red);
		term.write("\167" .. tostring(limit / 2));
		term.setTextColor(colors.white);
		term.setCursorPos(18, 12);
		centerText("Enter 0 to quit");
		drawRandomImage(2, 7);
		drawRandomImage(2, 13);
		drawRandomImage(termX - 8, 7);
		drawRandomImage(termX - 8, 13);
		drawRandomImage(2, 19);
		drawRandomImage(10, 19);
		drawRandomImage(20, 19);
		drawRandomImage(30, 19);
		drawRandomImage(40, 19);
		drawRandomImage(termX - 8, 19);
		term.setBackgroundColor(colors.green);
		term.setCursorPos(18, 14);
		term.setTextColor(colors.black);
		centerText("Bet Amount: \167");
		amount = tonumber(string.format("%.2f", tonumber(readkb())));
		term.setTextColor(colors.white);
		if amount ~= nil then
			if amount == 0 then
				quit = true;
				return;
			end;
			if amount >= 0.05 and amount <= credits and amount <= limit then
				break;
			end;
		end;
	end;
	local status = false;
	status = pay(amount);
	playAudio("coins-handling.dfpwm");
	if not status then
		quit = true;
	end;
end;
function slotmachiene()
	term.clear();
	term.setCursorPos(1, 1);
	term.setBackgroundColor(colors.black);
	term.setTextColor(colors.white);
	term.clearLine();
	centerText("Schindler Slots");
	term.setBackgroundColor(colors.blue);
	term.setCursorPos(1, 2);
	term.clearLine();
	term.setTextColor(colors.red);
	centerText("JACKPOT \167" .. tostring(jackpot));
	term.setBackgroundColor(colors.green);
	term.setTextColor(colors.white);
	drawBox(5, 1, 46, 19, colors.lightGray);
	drawLine(5, 1, 5, 19, colors.white);
	drawLine(19, 1, 19, 19, colors.white);
	drawLine(33, 1, 33, 19, colors.white);
	drawLine(47, 1, 47, 19, colors.white);
	drawLine(2, 10, 5, 10, colors.gray);
	drawLine(47, 10, 50, 10, colors.gray);
	term.setCursorPos(1, 22);
	term.setTextColor(colors.red);
	centerText(" Bet: " .. tostring(amount) .. " ");
	term.setTextColor(colors.white);
end;
function result()
	nr4 = math.random(100);
	if nr4 < bW then
		multeplier = 2;
		price = 1;
	elseif nr4 < cW then
		multeplier = 1.75;
		price = 2;
	elseif nr4 < dW then
		multeplier = 1.5;
		price = 3;
	elseif nr4 < eW then
		multeplier = 1.25;
		price = 4;
	elseif nr4 < fW then
		multeplier = 1;
		price = 5;
	else
		price = 6;
		multeplier = 0;
	end;
end;
function random_1()
	drawBox(6, 1, 18, 19, colors.lightGray);
	local result;
	for i = 1, 3 do
		h = i * 6 - 4;
		nr1 = math.random(100);
		if nr1 < b then
			drawImage(diamond, 8, h);
			result = diamond;
		elseif nr1 < c then
			drawImage(bell, 8, h);
			result = bell;
		elseif nr1 < d then
			drawImage(seven, 8, h);
			result = seven;
		elseif nr1 < e then
			drawImage(dollar, 8, h);
			result = dollar;
		elseif nr1 < f then
			drawImage(orange, 8, h);
			result = orange;
		elseif nr1 <= 100 then
			drawImage(none, 8, h);
			result = none;
		end;
	end;
	return result;
end;
function random_2(last)
	drawBox(20, 1, 32, 19, colors.lightGray);
	for i = 4, 6 do
		h = (i - 3) * 6 - 4;
		nr2 = math.random(100);
		if nr2 < b and last ~= diamond then
			drawImage(diamond, 22, h);
		elseif nr2 < c and last ~= bell then
			drawImage(bell, 22, h);
		elseif nr2 < d and last ~= seven then
			drawImage(seven, 22, h);
		elseif nr2 < e and last ~= dollar then
			drawImage(dollar, 22, h);
		elseif nr2 < f and last ~= orange then
			drawImage(orange, 22, h);
		elseif nr2 <= 100 then
			drawImage(none, 22, h);
		else
			drawImage(none, 22, h);
		end;
	end;
end;
function random_3(last)
	drawBox(34, 1, 46, 19, colors.lightGray);
	for i = 7, 9 do
		h = (i - 6) * 6 - 4;
		nr3 = math.random(100);
		if nr3 < b and last ~= diamond then
			drawImage(diamond, 36, h);
		elseif nr3 < c and last ~= diamond then
			drawImage(bell, 36, h);
		elseif nr3 < d and last ~= diamond then
			drawImage(seven, 36, h);
		elseif nr3 < e and last ~= diamond then
			drawImage(dollar, 36, h);
		elseif nr3 < f and last ~= diamond then
			drawImage(orange, 36, h);
		elseif nr3 <= 100 and last ~= diamond then
			drawImage(none, 36, h);
		else
			drawImage(none, 22, h);
		end;
	end;
end;
function roll()
	for x = 1, 25 do
		random_1();
		random_2();
		random_3();
		sleep(0, 5);
	end;
	if price == 1 then
		drawBox(6, 7, 18, 13, colors.lightGray);
		drawImage(diamond, 8, 8);
	elseif price == 2 then
		drawBox(6, 7, 18, 13, colors.lightGray);
		drawImage(dollar, 8, 8);
	elseif price == 3 then
		drawBox(6, 7, 18, 13, colors.lightGray);
		drawImage(seven, 8, 8);
	elseif price == 4 then
		drawBox(6, 7, 18, 13, colors.lightGray);
		drawImage(bell, 8, 8);
	elseif price == 5 then
		drawBox(6, 7, 18, 13, colors.lightGray);
		drawImage(orange, 8, 8);
	end;
	playAudio("row.dfpwm");
	for x = 1, 25 do
		random_2();
		random_3();
		sleep(0, 5);
	end;
	if price == 1 then
		drawBox(20, 7, 32, 13, colors.lightGray);
		drawImage(diamond, 22, 8);
	elseif price == 2 then
		drawBox(20, 7, 32, 13, colors.lightGray);
		drawImage(dollar, 22, 8);
	elseif price == 3 then
		drawBox(20, 7, 32, 13, colors.lightGray);
		drawImage(seven, 22, 8);
	elseif price == 4 then
		drawBox(20, 7, 32, 13, colors.lightGray);
		drawImage(bell, 22, 8);
	elseif price == 5 then
		drawBox(20, 7, 32, 13, colors.lightGray);
		drawImage(orange, 22, 8);
	end;
	playAudio("row.dfpwm");
	for x = 1, 25 do
		random_3();
		sleep(0, 5);
	end;
	if price == 1 then
		drawBox(34, 7, 46, 13, colors.lightGray);
		drawImage(diamond, 36, 8);
	elseif price == 2 then
		drawBox(34, 7, 46, 13, colors.lightGray);
		drawImage(dollar, 36, 8);
	elseif price == 3 then
		drawBox(34, 7, 46, 13, colors.lightGray);
		drawImage(seven, 36, 8);
	elseif price == 4 then
		drawBox(34, 7, 46, 13, colors.lightGray);
		drawImage(bell, 36, 8);
	elseif price == 5 then
		drawBox(34, 7, 46, 13, colors.lightGray);
		drawImage(orange, 36, 8);
	else
		drawBox(34, 7, 46, 13, colors.lightGray);
		drawImage(none, 36, 8);
	end;
	playAudio("row.dfpwm");
	sleep(0.5);
end;
local function round(num, n)
	n = n or 0;
	local mult = 10 ^ n;
	return math.floor((num * mult + 0.5)) / mult;
end;
function pricewon()
	if multeplier == 2 and amount >= limit / 2 then
		drawJackpot();
		priceamount = amount + jackpot;
		if jackpot < amount * multeplier then
			priceamount = priceamount + amount * multeplier;
		end;
		setJackpot(0);
	else
		priceamount = round(amount * multeplier, 2);
	end;
	won = priceamount - amount;
	pay((-1) * priceamount);
	term.setBackgroundColor(colors.green);
	term.clear();
	if multeplier >= 1 then
		term.setBackgroundColor(colors.blue);
		term.clear();
		term.setCursorPos(1, 11);
		centerText("Winner!");
		term.setCursorPos(22, 13);
		centerText("Dollars Won");
		term.setCursorPos(22, 14);
		term.setTextColor(colors.lime);
		centerText("\167" .. priceamount);
		term.setTextColor(colors.white);
		paintutils.drawImage(dollar, 10, 2);
		paintutils.drawImage(dollar, 20, 2);
		paintutils.drawImage(dollar, 30, 2);
		paintutils.drawImage(dollar, 40, 2);
		paintutils.drawImage(dollar, 2, 7);
		paintutils.drawImage(dollar, 2, 13);
		paintutils.drawImage(dollar, termX - 8, 7);
		paintutils.drawImage(dollar, termX - 8, 13);
		paintutils.drawImage(dollar, 10, 19);
		paintutils.drawImage(dollar, 20, 19);
		paintutils.drawImage(dollar, 30, 19);
		paintutils.drawImage(dollar, 40, 19);
		term.setBackgroundColor(colors.blue);
		if multeplier == 2 and amount < limit / 2 then
			term.setCursorPos(1, 15);
			term.setTextColor(colors.red);
			centerText("You could have won the JackPot!");
			term.setTextColor(colors.white);
		end;
		playAudio("win.dfpwm");
	elseif multeplier < 1 then
		setJackpot(jackpot + amount / 4);
		term.setBackgroundColor(colors.red);
		term.clear();
		term.setCursorPos(1, 11);
		centerText("You lost");
		term.setCursorPos(1, 15);
		centerText("Better luck next time");
		playAudio("lose.dfpwm");
	end;
	term.setCursorPos(16, 17);
	centerText("Press any key to continue");
	os.pullEvent("key");
	drawTransition();
end;
function lever()
	slotmachiene();
	random_1();
	random_2();
	random_3();
	term.setCursorPos(1, 11);
	term.setBackgroundColor(colors.black);
	centerText("Press any key to pull lever");
	term.setBackgroundColor(colors.green);
	os.pullEvent("key");
	playAudio("lever-pull.dfpwm");
	sleep(1);
end;
local function testRun(runs, jackpotNumber, cost)
	print();
	jackpot = jackpotNumber;
	local jp = 0;
	local onep75 = 0;
	local onep5 = 0;
	local onep25 = 0;
	local one = 0;
	local two = 0;
	local zero = 0;
	local total = 0;
	local maxJackpot = 0;
	if cost == nil then
		cost = limit / 2;
	end;
	local results = {};
	for i = 1, runs do
		total = total - cost;
		result();
		if multeplier == 0 then
			zero = zero + 1;
			jackpot = jackpot + cost / 4;
			if jackpot > maxJackpot then
				maxJackpot = jackpot;
			end;
			total = total + cost * multeplier;
		elseif multeplier == 1 then
			one = one + 1;
			total = total + cost * multeplier;
		elseif multeplier == 2 then
			total = total - cost * multeplier;
			if cost >= limit / 2 then
				total = total + jackpot;
				if jackpot < cost * multeplier then
					total = total + cost * multeplier;
					two = two + 1;
				else
					total = total + cost;
				end;
				jackpot = 0;
				jp = jp + 1;
			else
				total = total + cost * multeplier;
				two = two + 1;
			end;
		elseif multeplier == 1.25 then
			onep25 = onep25 + 1;
			total = total + cost * multeplier;
		elseif multeplier == 1.5 then
			onep5 = onep5 + 1;
			total = total + cost * multeplier;
		elseif multeplier == 1.75 then
			onep75 = onep75 + 1;
			total = total + cost * multeplier;
		end;
	end;
	local net = total + runs * cost;
	debugLog("Totals");
	debugLog("runs: " .. tostring(runs) .. " jackpotNumber: " .. tostring(jackpotNumber));
	print("runs: " .. tostring(runs) .. " jackpotNumber: " .. tostring(jackpotNumber));
	debugLog("0: " .. tostring(zero) .. " | " .. tostring(zero / runs * 100) .. "%");
	debugLog("1: " .. tostring(one) .. " | " .. tostring(one / runs * 100) .. "%");
	debugLog("1.25: " .. tostring(onep25) .. " | " .. tostring(onep25 / runs * 100) .. "%");
	debugLog("1.5: " .. tostring(onep5) .. " | " .. tostring(onep5 / runs * 100) .. "%");
	debugLog("1.75: " .. tostring(onep75) .. " | " .. tostring(onep75 / runs * 100) .. "%");
	debugLog("2: " .. tostring(two) .. " | " .. tostring(two / runs * 100) .. "%");
	debugLog("jackpot: " .. tostring(jp) .. " | " .. tostring(jp / runs * 100) .. "% Left: " .. tostring(jackpot));
	debugLog("Total: " .. tostring(total) .. " Cost: " .. tostring(runs * cost) .. " Net: " .. tostring(net));
	debugLog("Winning %: " .. tostring(100 + total / (runs * cost) * 100));
	print("Bet: " .. tostring(cost));
	print("Jackpot Left: " .. tostring(jackpot));
	print("maxJackpot: " .. tostring(maxJackpot));
	print("Winning %: " .. tostring(100 + total / (runs * cost) * 100));
	jackpot = 0;
	sleep(2);
end;
term.setBackgroundColor(colors.gray);
term.clear();
paintutils.drawFilledBox(1, 7, termX, 11, colors.lightGray);
term.setCursorPos(1, 8);
term.setTextColor(colors.black);
centerText("Schindler");
term.setCursorPos(1, 10);
term.setTextColor(colors.yellow);
centerText("Slots");
term.setTextColor(colors.white);
sleep(3);
drawTransition();
term.setBackgroundColor(colors.green);
if settings.get("debug") then
	term.setCursorPos(1, 1);
end;
debugLog("Main Loop");
while not quit do
	debugLog("getJackpot");
	getJackpot();
	debugLog("getCredits");
	getCredits();
	debugLog("insert_amount");
	insert_amount();
	if not quit then
		debugLog("lever");
		lever();
		if quit then
			break;
		end;
		debugLog("slotmachiene");
		slotmachiene();
		debugLog("result");
		result();
		debugLog("roll");
		roll();
		sleep(1);
		debugLog("pricewon");
		pricewon();
	end;
end;
