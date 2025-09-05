--os.loadAPI("cryptoNet")
-- Init
local bankServerSocketBlackJack, controllerSocket
local quit = false
local id = 0
local cash = 0
local total = 0
local tArgs = { ... }
local username = tArgs[1]
local termX, termY = term.getSize()
local speaker = peripheral.find("speaker")
local chatbox = peripheral.find("chat_box");
local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
term.setBackgroundColor(colors.gray)
term.setTextColor(colors.white)
--term.clear()

--Play audioFile on speaker
local function playAudio(path)
   if not speaker then
        print("No speaker found")
        return
    end
    if not fs.exists(path) then
        print("Missing audio file: " .. path)
        return
    end

    local file = assert(io.open(path, "rb")) -- open binary
    for chunk in function() return file:read(16 * 1024) end do
        local buffer = decoder(chunk)
        while not speaker.playAudio(buffer, 3) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    file:close()
end

--Play tune on speakers
local function playSounds(instrument, reversed)
  local rand = math.random(24)
  speaker.playNote(instrument, 1, rand)
end

local function sysLog(msg)
    -- Encode message for URL
    local urlMsg = textutils.urlEncode("label:" .. os.getComputerLabel().." ID:" .. os.getComputerID() .. " blackjack:" .. msg)
    local url = "https://schindlershadow.duckdns.org/log.php?msg=" .. urlMsg

    local response = http.get(url)
    if response then
        --print("Logged:", response.readAll())
        response.close()
    else
        --print("Failed to log message")
    end
end

local function log(text)
	local logFile = fs.open("logs/blackjack.log", "a");
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
-- Toast helper
local function sendToast(username, title, msg)
    if chatbox and chatbox.sendToastToPlayer then
        chatbox.sendToastToPlayer(msg, title, username, "&4&lBank", "()", "&c&l")
    end
end
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
	term.getBackgroundColor(colors.green);
  --term.clear()
	term.setCursorPos(1, y);
	centerText(text);
	term.setCursorPos(1, 4);
	--centerText("Loading...");
	term.setCursorPos(1, 6);
end;
local function truncate(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult) / mult
end
local function hasMoreThanTwoDecimals(value)
    local s = tostring(value)
    local dot = s:find("%.")
    if not dot then
        return false -- no decimal point at all
    end
    local decimals = #s - dot
    return decimals > 2
end
local function setCredits(username, value)
	if type(value) ~= "number" then
		return false;
	end;
	commands.reco("set " .. username .. " Dollar " .. tostring(value));
	return true;
end;
local function getCredits()
	if type(username) ~= "string" then
		return 0;
	end;
	local _, out = commands.bal(username);
	for _, line in ipairs(out) do
		local amt = line:match("([%d%.]+)");
		if amt then
      if hasMoreThanTwoDecimals((amt)) then
				amt = truncate(tonumber(amt), 2)
				setCredits(username, tonumber(amt));
				sendToast(username, "Balance Truncated - BlackJack: " .. tostring(os.getComputerLabel()), "Balance set to $" .. tostring(amt));
			end
            cash = tonumber(amt)
			return amt;
		end;
	end;
    cash = 0
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
    --log("reco add " .. username .. " Dollar " .. tostring(value));
    --debugLog("ok ".. tostring(ok) .. " msg " .. tostring(msg) .. " num " .. tostring(num))
    sysLog(username ..": +" .. tostring(value) .. " $" .. tostring(getCredits(username)))
    sendToast(username, "Payment Processed - BlackJack: " .. tostring(os.getComputerLabel()), "+$" .. tostring(value) .. " for " .. settings.get("gameName"));
	--writeDatabase();
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
    --log("reco remove " .. username .. " Dollar " .. tostring(value));
    --debugLog("ok ".. tostring(ok) .. " msg " .. tostring(msg) .. " num " .. tostring(num))
    sysLog(username ..": -" .. tostring(value) .. " $" .. tostring(getCredits(username)))
    sendToast(username, "Payment Processed - BlackJack: " .. tostring(os.getComputerLabel()), "-$" .. tostring(value) .. " for " .. settings.get("gameName"));
	--writeDatabase();
	return true;
end;
local function pay(amount)
  if settings.get("debug") then
		return true;
	end
	if type(username) == "string" and type(amount) == "number" then
		local credits = getCredits(username);
		if credits - amount >= 0 then
			--log("Credits change: user:" .. username .. " amount:" .. tostring((-1) * amount));
			--print("Credits change: user:" .. username .. " amount:" .. tostring((-1) * amount));
      if amount == 0 then
				return true
            end
            if amount > 0 then
                removeCredits(amount);
            elseif amount ~= 0 then
                addCredits((-1)*amount);
            end
			total = total + ((-1) * amount);
			--playAudioDepositAccepted();
			return true;
		else
			return false;
		end;
	end;
end;

function center(str)
  curX, curY = term.getCursorPos()
  maxX, maxY = term.getSize()
  maxX = maxX / 2
  maxX = maxX - (#str / 2)
  term.setCursorPos(maxX, curY)
  print(str)
end

deckCount = false
cardCount = false
analysis = {}


function shuffle()
  playAudio("shuffle.dfpwm")
  faceCount = 0
  term.setBackgroundColor(colors.green)
  term.clear()
  term.setCursorPos(1, 9)
  term.setTextColor(colors.white)
  center("Shuffling deck...")
  cards = {
    "A", "A", "A", "A", "A", "A", "A", "A",
    "J", "J", "J", "J", "J", "J", "J", "J",
    "K", "K", "K", "K", "K", "K", "K", "K",
    "Q", "Q", "Q", "Q", "Q", "Q", "Q", "Q",
    "2", "2", "2", "2", "2", "2", "2", "2",
    "3", "3", "3", "3", "3", "3", "3", "3",
    "4", "4", "4", "4", "4", "4", "4", "4",
    "5", "5", "5", "5", "5", "5", "5", "5",
    "6", "6", "6", "6", "6", "6", "6", "6",
    "7", "7", "7", "7", "7", "7", "7", "7",
    "8", "8", "8", "8", "8", "8", "8", "8",
    "9", "9", "9", "9", "9", "9", "9", "9",
    "10", "10", "10", "10", "10", "10", "10", "10",
  }
  local symbols = { "\4", "\5", "\6" }
  term.setCursorPos(1, 10)
  deck = {}
  for i, v in pairs(cards) do
    repeat
      pos = math.random(1, #cards)
      write(symbols[math.random(1, 3)])
    until deck[pos] == nil
    deck[pos] = v
    sleep(0)
  end
  speaker.stop()
end

playerHand = {}
dealerHand = {}
--cash = 1000
function countCard(sCard)
  if sCard == "A" or sCard == "J" or sCard == "K" or sCard == "Q" or sCard == "10" then
    faceCount = faceCount - 1
  elseif sCard == "2" or sCard == "3" or sCard == "4" or sCard == "5" or sCard == "6" then
    faceCount = faceCount + 1
  end
end

function dealSelf(hide, toPlayAudio)
  log("dealSelf hide " .. tostring(hide) .. " toPlayAudio " .. tostring(toPlayAudio))
    if #deck == 0 then
        log("Deck empty! Cannot deal dealer card.")
        return
    end
    if toPlayAudio == nil then
        toPlayAudio = true
    end
    if toPlayAudio then
        log("playaudio card.dfpwm")
        playAudio("card.dfpwm")
    end

    local card = deck[#deck]
    dealerHand[#dealerHand + 1] = card
    if not hide then
        countCard(card)
    end
    deck[#deck] = nil
    sleep(0.5)
end


function dealPlayer()
  playAudio("card.dfpwm")
  playerHand[#playerHand + 1] = deck[#deck]
  countCard(deck[#deck])
  deck[#deck] = nil
  sleep(0.5)
end

function drawCard(card, x, y)
  do
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    if card == "flipped" then
      term.setBackgroundColor(colors.red)
      term.setTextColor(colors.white)
      term.setCursorPos(x, y)
      --write("+-+")
      write("\127\127\127")
      term.setCursorPos(x, y + 1)
      --write("|*|")
      write("\127\127\127")
      term.setCursorPos(x, y + 2)
      write("\127\127\127")
      --write("+-+")
    elseif card == "10" then
      term.setCursorPos(x, y)
      write("10 ")
      term.setCursorPos(x, y + 1)
      write("   ")
      term.setCursorPos(x, y + 2)
      write(" 10")
    else
      term.setCursorPos(x, y)
      write(card .. "  ")
      term.setCursorPos(x, y + 1)
      write("   ")
      term.setCursorPos(x, y + 2)
      write("  " .. card)
    end
  end
end

function getHandValue(hand)
    local value = 0
    local aces = 0

    for i, card in ipairs(hand) do
        if card == "A" then
            value = value + 11
            aces = aces + 1
        elseif card == "K" or card == "Q" or card == "J" then
            value = value + 10
        else
            value = value + tonumber(card)
        end
    end

    local soft = false
    while value > 21 and aces > 0 do
        value = value - 10
        aces = aces - 1
    end

    if aces > 0 then soft = true end  -- still have Ace counted as 11
    return value, soft
end


dealerShowing = false
buttons = false
function redraw()
  term.setBackgroundColor(colors.green)
  term.clear()
  term.setTextColor(colors.white)
  --spacing = 25 - (#dealerHand * 2)
  spacing = 29 - (#dealerHand * 2)
  for i, v in pairs(dealerHand) do
    if dealerShowing or i == 1 then
      drawCard(v, spacing, 3)
    else
      drawCard("flipped", spacing, 3)
    end
    spacing = spacing + 4
  end
  --spacing = 25 - (#playerHand * 2)
  spacing = 29 - (#playerHand * 2)
  for i, v in pairs(playerHand) do
    if i == #playerHand and doubled and not dealerShowing then
      drawCard("flipped", spacing, 13)
    else
      drawCard(v, spacing, 13)
    end
    spacing = spacing + 4
  end
  if buttons then
    term.setCursorPos(10, 21)
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.gray)
    write(" Stand ")
    term.setCursorPos(18, 21)
    if doubled then
      term.setBackgroundColor(colors.gray)
      term.setTextColor(colors.lightGray)
    else
      term.setBackgroundColor(colors.lightGray)
      term.setTextColor(colors.gray)
    end
    write(" Hit ")
    term.setCursorPos(24, 21)
    if cash >= (bet * 2) and not doubled then
      term.setBackgroundColor(colors.lightGray)
      term.setTextColor(colors.gray)
    else
      term.setBackgroundColor(colors.gray)
      term.setTextColor(colors.lightGray)
    end
    write(" Double ")
    term.setCursorPos(33, 21)
    if #playerHand == 2 and playerHand[1] == playerHand[2] then
      term.setBackgroundColor(colors.lightGray)
      term.setTextColor(colors.gray)
    else
      term.setBackgroundColor(colors.gray)
      term.setTextColor(colors.lightGray)
    end
    write(" Split ")
  end
  term.setCursorPos(2, 20)
  term.setBackgroundColor(colors.green)
  term.setTextColor(colors.white)
  write("Dollars: ")
  --term.setCursorPos(2, 17)
  term.setTextColor(colors.lime)
  write("\167" .. tostring(cash))
  if bet ~= nil then
    term.setCursorPos(2, 22)
    term.setTextColor(colors.white)
    write("Bet: ")
    term.setTextColor(colors.red)
    write("\167" .. tostring(bet))
  end
  term.setTextColor(colors.white)
  term.setCursorPos(2, 19)
  write("ID: " .. tostring(id))
  term.setCursorPos(2, 2)
  write("Max Bet: \167" .. tostring(settings.get("maxBet")))
  term.setCursorPos(45, 16)
  term.setTextColor(colors.white)
  if deckCount then
    write("Deck:")
    term.setCursorPos(46, 21)
    term.setTextColor(colors.lightGray)
    write(tostring(#deck))
  end
  if cardCount then
    write("Count:")
    term.setCursorPos(46, 21)
    term.setTextColor(colors.white)
    write(tostring(faceCount))
  end
  if #playerHand > 0 then
    term.setCursorPos(1, 11)
    term.setBackgroundColor(colors.green)
    term.setTextColor(colors.gray)
    if dealerShowing or not doubled then
      center(tostring(getHandValue(playerHand)))
    else
      center("?")
    end
    term.setCursorPos(1, 7)
    if dealerShowing then
      center(tostring(getHandValue(dealerHand)))
    else
      center("?")
    end
  end
end

function msg(str)
  paintutils.drawFilledBox(1, 8, termX, 10, colors.gray)
  term.setCursorPos(1, 9)
  term.setTextColor(colors.white)
  center(str)
end

function winAnim()
  dollars = {}
  for i = 1, termX do
    dollars[i] = math.random(-5, 0)
  end
  term.setTextColor(colors.yellow)
  term.setBackgroundColor(colors.black)
  playAudio("win.dfpwm")
  for i = 1, 40 do
    for x, v in pairs(dollars) do
      if v >= 1 and v <= termX then
        term.setCursorPos(x, v)
        write("\127")
      end
      dollars[x] = dollars[x] + 1
      if (v + 1) >= 1 and (v + 1) <= termX then
        term.setCursorPos(x, v + 1)
        write("$")
      end
    end
    sleep(0.1)
  end
  for i = 1, termY do
    paintutils.drawLine(1, i, termX, i, colors.green)
    sleep(0)
  end
  speaker.stop()
end

local function readkb()
  local string = ""
  local event, key
  local x, y = term.getCursorPos()
  while true do
    term.setCursorPos(x, y)
    term.write(string)
    repeat
      event, key = os.pullEvent()
    until event == "key" or event == "char"
    if event == "char" then
      string = string .. key
    elseif event == "key" then
      if key == keys.backspace then
        --remove from text entry
        string = string:sub(1, -2)
        term.setCursorPos(x, y)
        term.write("                                                  ")
      elseif key == keys.enter or key == keys.numPadEnter then
        --set creds
        return string
      end
    end
  end
end

local function drawAnalysis()
  --term.setBackgroundColor(colors.gray)
  drawTransition(colors.gray)
  --term.clear()
  term.setTextColor(colors.white)
  cBlackjack = 0
  cDealerbust = 0
  cBust = 0
  cLose = 0
  cPush = 0
  cWin = 0
  for i, v in pairs(analysis) do
    if v == "blackjack" then
      cBlackjack = cBlackjack + 1
    elseif v == "dealerbust" then
      cDealerbust = cDealerbust + 1
    elseif v == "bust" then
      cBust = cBust + 1
    elseif v == "lose" then
      cLose = cLose + 1
    elseif v == "push" then
      cPush = cPush + 1
    elseif v == "win" then
      cWin = cWin + 1
    end
  end
  gameCount = cBlackjack + cDealerbust + cBust + cLose + cPush + cWin
  startPoint = 2
  colorz = {
    [6] = colors.purple,
    [4] = colors.lime,
    [1] = colors.red,
    [2] = colors.orange,
    [5] = colors.green,
    [3] = colors.yellow,
  }
  output = {
    [1] = cBust,
    [2] = cLose,
    [3] = cPush,
    [4] = cWin,
    [5] = cDealerbust,
    [6] = cBlackjack,
  }
  if gameCount > 0 then
  for i, v in pairs(output) do
    paintutils.drawLine(startPoint, 4, (startPoint + ((v / gameCount) * 49) - 1), 4, colorz[i])
    startPoint = startPoint + ((v / gameCount) * 49)
  end
end

  paintutils.drawPixel(1, 4, colors.gray)
  paintutils.drawPixel(51, 4, colors.gray)
  analysis = {}
  term.setBackgroundColor(colors.gray)
  term.setTextColor(colors.white)
  term.setCursorPos(1, 2)
  center("Game Analysis")
  term.setCursorPos(4, 6)
  term.setBackgroundColor(colors.gray)
  term.setTextColor(colors.red)
  write("Bust  ")
  term.setTextColor(colors.orange)
  write("Lose  ")
  term.setTextColor(colors.yellow)
  write("Push  ")
  term.setTextColor(colors.lime)
  write("Win  ")
  term.setTextColor(colors.green)
  write("Dealer Bust  ")
  term.setTextColor(colors.purple)
  write("Blackjack")


  term.setCursorPos(1, 8)
  term.setTextColor(colors.red)
  print("Bust: " .. tostring(cBust))
  term.setTextColor(colors.orange)
  print("Lose: " .. tostring(cLose))
  term.setTextColor(colors.yellow)
  print("Push: " .. tostring(cPush))
  term.setTextColor(colors.lime)
  print("Win: " .. tostring(cWin))
  term.setTextColor(colors.green)
  print("Dealer Bust: " .. tostring(cDealerbust))
  term.setTextColor(colors.purple)
  print("Blackjack: " .. tostring(cBlackjack))
  term.setTextColor(colors.white)
  print("")
  print("Total Winnings: \167" .. tostring(total))
  term.setCursorPos(1, 18)
  term.setBackgroundColor(colors.lightGray)
  term.setTextColor(colors.gray)
  centerText(" Press any key to exit ")
  --sleep(5)
  repeat
    e = os.pullEvent()
  until e == "key"
  quit = true
end

-- Round to n decimal places (default = 0)
local function round(num, n)
    n = n or 0
    local mult = 10 ^ n
    return math.floor(num * mult + 0.5) / mult
end

function playHand()
  if cash == 0 then
    optA = true
    optB = true
    optC = true
    term.setBackgroundColor(colors.black)
    term.clear()
    paintutils.drawImage(paintutils.loadImage("/dollar"), 1, 1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 11)
    center("You're ruined!")
    term.setCursorPos(1, 13)
    term.setTextColor(colors.red)
    center("\1670 Dollars")
    sleep(5)
    quit = true
    return
  end
  bet = nil
  buttons = false
  blackJack = false
  playerBust = false
  dealerBust = false
  dealerShowing = false
  playerHand = {}
  dealerHand = {}
  if #deck < 12 then
    shuffle()
  end
  doubled = false
  redraw()
  if not splitCard then
    repeat
      paintutils.drawFilledBox(10, 21, 39, 21, colors.green)
      term.setCursorPos(18, 22)
      term.setTextColor(colors.white)
      center("Bet 0 to exit")
      term.setCursorPos(18, 21)
      term.setTextColor(colors.white)
      write("Bet: ")
      bet = 0
      bet = tonumber(string.format("%.2f", tonumber(readkb())))
      if bet == 0 then
        drawAnalysis()
        quit = true
        return
      end
      if not bet or type(bet) ~= "number" then
        bet = 0
      end
      if bet > tonumber(settings.get("maxBet")) then
        bet = tonumber(settings.get("maxBet"))
      end
      bet = round(bet, 0)
    until bet <= cash and bet >= 1
    pay(round(bet,2))
    playAudio("chips.dfpwm")
    sleep(0.5)
  end
  if not splitCard then
    dealPlayer()
    redraw()
    sleep(0.5)
    dealSelf()
    redraw()
    sleep(0.5)
    dealPlayer()
    redraw()
    sleep(0.5)
    dealSelf(true)
    redraw()
  else
    playerHand[#playerHand + 1] = splitCard
    bet = splitBet
    splitCard = nil
    splitBet = nil
    dealSelf()
    redraw()
    sleep(0.5)
    dealPlayer()
    redraw()
    sleep(0.5)
    dealSelf(true)
    redraw()
    sleep(0.5)
    msg("Playing Split Hand")
    sleep(3)
  end
  continue = true
  if getHandValue(playerHand) == 21 then
    continue = false
    blackJack = true
  end
  while continue do
    buttons = true
    redraw()
    local playerValue = getHandValue(playerHand)
    
    if playerValue > 21 then
        playerBust = true
        continue = false
        break
    elseif playerValue == 21 then
        -- Auto-stand on 21
        continue = false
        break
    end

    e, key, x, y = os.pullEvent("key")
    if key == keys.s or key == keys.one or key == keys.numPad1 then
      -- Stand
      log("Player stands: " .. table.concat(playerHand, ", ") .. " Value: " .. playerValue)
      continue = false
      break
    elseif key == keys.h or key == keys.two or key == keys.numPad2 then
      -- Hit
      if not doubled then
        dealPlayer()
      end
    elseif key == keys.d or key == keys.three or key == keys.numPad3 then
      -- Double
      if cash >= (bet * 2) and not doubled then
        doubled = true
        pay(round(bet,2))
        dealPlayer()
        bet = bet * 2
      end
    elseif key == keys.l or key == keys.four or key == keys.numPad4 then
      -- Split
      if playerHand[1] == playerHand[2] then
        if #playerHand == 2 then
          splitBet = bet
          splitCard = playerHand[2]
          playerHand[2] = nil
          dealPlayer()
        end
      end
    end

    sleep(0.2)
  end
  log("Player final: " .. table.concat(playerHand, ", ") .. " Value: " .. getHandValue(playerHand))
  buttons = false
  --playAudio("card.dfpwm")
  dealerShowing = true
countCard(dealerHand[2])
log("Dealer reveals: " .. table.concat(dealerHand, ", ") .. " Value: " .. getHandValue(dealerHand))

local dealerValue, dealerSoft = getHandValue(dealerHand)
log("Dealer initial: " .. table.concat(dealerHand, ", ") .. " Value: " .. dealerValue .. " Soft: " .. tostring(dealerSoft))
local dealerLoopCount = 0
--playAudio("card.dfpwm")
while dealerValue < 17 or (dealerValue == 17 and dealerSoft) do
    if #deck == 0 then
        log("Deck empty! Dealer cannot draw more cards.")
        break
    end
    log("Dealer hits...")
    dealSelf(false, false)
    log("Dealer hand: " .. table.concat(dealerHand, ", "))
    dealerValue, dealerSoft = getHandValue(dealerHand)
    log("Dealer hits: " .. table.concat(dealerHand, ", ") .. " Value: " .. dealerValue .. " Soft: " .. tostring(dealerSoft))
    redraw()
    dealerLoopCount = dealerLoopCount + 1
    sleep(0.5)

    if dealerLoopCount > 20 then
        log("Dealer loop safety break triggered!")
        break
    end
end

log("Dealer stands: " .. table.concat(dealerHand, ", ") .. " Value: " .. dealerValue)



  playAudio("card.dfpwm")
  redraw()
  sleep(0.5)
  if blackJack then
    --cash = cash + (bet * 1.5)
    pay(round(-1 * (bet + (bet * 1.5)),2))
    msg("Blackjack!")
    analysis[#analysis + 1] = "blackjack"
    sleep(2)
    winAnim()
    return
  end
  if playerBust then
    --cash = cash - bet
    --pay(bet)
    msg("You Bust!")
    analysis[#analysis + 1] = "bust"
    playAudio("lose.dfpwm")
    sleep(3)
    return
  end
  if getHandValue(dealerHand) > 21 then
    --cash = cash + bet
    pay(round(-1 * (bet * 2),2))
    msg("Dealer Busts!")
    analysis[#analysis + 1] = "dealerbust"
    sleep(2)
    winAnim()
    return
  end
  if getHandValue(dealerHand) > getHandValue(playerHand) then
    --cash = cash - bet
    --pay(bet)
    msg("You Lose!")
    analysis[#analysis + 1] = "lose"
    playAudio("lose.dfpwm")
    sleep(3)
    return
  end
  if getHandValue(dealerHand) == getHandValue(playerHand) then
    pay(round(-1 * bet,2))
    msg("You Push!")
    analysis[#analysis + 1] = "push"
    sleep(3)
    return
  end
  if getHandValue(playerHand) > getHandValue(dealerHand) then
    --cash = cash + bet
    pay(round(-1 * (bet * 2),2))
    msg("You Win!")
    analysis[#analysis + 1] = "win"
    sleep(2)
    winAnim()
    return
  end
end

local function onStart()
  -- Start Game
  drawTransition(colors.gray)
  paintutils.drawFilledBox(1, 7, termX, 11, colors.lightGray)
  term.setCursorPos(1, 8)
  term.setTextColor(colors.black)
  center("Blackjack")
  term.setCursorPos(1, 10)
  term.setTextColor(colors.yellow)
  center("Deluxe")
  term.setTextColor(colors.white)

  --bankServerSocketBlackJack = cryptoNet.connect(settings.get("BankServer"), 5, 2, settings.get("BankServer") .. ".crt", "bottom")
  --print("Connected!")
  --timeout no longer needed
  getCredits()


  sleep(3)
  faceCount = 0
  for i = 1, termY do
    paintutils.drawFilledBox(1, i, termX, i, colors.green)
    sleep(0)
  end

  --sleep(0.5)
  shuffle()

  while not quit do
    playHand()
    if #deck < 12 then
      drawAnalysis()
      quit = true
    end
  end
  getCredits()
end

--Main loop
onStart()
