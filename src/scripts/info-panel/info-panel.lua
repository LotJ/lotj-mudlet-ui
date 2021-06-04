lotj = lotj or {}
lotj.infoPanel = lotj.infoPanel or {}


function lotj.infoPanel.setup()
  local basicStatsContainer = Geyser.Label:new({
    h_stretch_factor = 0.9
  }, lotj.layout.lowerInfoPanel)
  local combatContainer = Geyser.Label:new({
    h_stretch_factor = 0.9
  }, lotj.layout.lowerInfoPanel)
  local chatContainer = Geyser.Label:new({
    h_stretch_factor = 1
  }, lotj.layout.lowerInfoPanel)
  local spaceContainer = Geyser.Label:new({
    h_stretch_factor = 2.2
  }, lotj.layout.lowerInfoPanel)

  lotj.infoPanel.createBasicStats(basicStatsContainer)
  lotj.infoPanel.createOpponentStats(combatContainer)
  lotj.infoPanel.createChatInfo(chatContainer)
  lotj.infoPanel.createSpaceStats(spaceContainer)
end


-- Utility functions
local function gaugeFrontStyle(step1, step2, step3, step4, step5)
  return [[
    background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 ]]..step1..[[, stop: 0.1 ]]..step2..[[, stop: 0.49 ]]..step3..[[, stop: 0.5 ]]..step4..[[, stop: 1 ]]..step5..[[);
    border-top: 1px black solid;
    border-left: 1px black solid;
    border-bottom: 1px black solid;
    padding: 3px;
  ]]
end

local function gaugeBackStyle(step1, step2, step3, step4, step5)
  return [[
    background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 ]]..step1..[[, stop: 0.1 ]]..step2..[[, stop: 0.49 ]]..step3..[[, stop: 0.5 ]]..step4..[[, stop: 1 ]]..step5..[[);
    border-width: 1px;
    border-color: black;
    border-style: solid;
    padding: 3px;
  ]]
end

local function styleGaugeText(gauge, fontSize)
  gauge.text:setStyleSheet([[
    padding-right: 10px;
  ]])
  gauge:setAlignment("r")
  gauge:setFontSize(fontSize)
end

local function gmcpVarByPath(varPath)
  local temp = gmcp
  for varStep in varPath:gmatch("([^\\.]+)") do
    if temp and temp[varStep] then
      temp = temp[varStep]
    else
      return nil
    end
  end
  return temp
end

-- Wires up GMCP subscriptions for a gauge.
-- statName is the short version of the stat name to show after the value (mv, hp, etc)
local function wireGaugeUpdate(gauge, valueVarName, maxVarName, statName, eventName)
  local function doUpdate()
    local current = gmcpVarByPath(valueVarName) or 0
    local max = gmcpVarByPath(maxVarName) or 0
    if max > 0 then
      gauge:setValue(current, max, current.."/"..max.." "..statName)
    else
      gauge:setValue(0, 1, "")
    end
  end
  lotj.setup.registerEventHandler(eventName, doUpdate)
end


function lotj.infoPanel.createBasicStats(container)
  -- Health gauge
  local healthGauge = Geyser.Gauge:new({
    x="5%", y=4,
    width="90%", height=16,
  }, container)
  healthGauge.front:setStyleSheet(gaugeFrontStyle("#f04141", "#ef2929", "#cc0000", "#a40000", "#cc0000"))
  healthGauge.back:setStyleSheet(gaugeBackStyle("#3f1111", "#3f0707", "#330000", "#220000", "#330000"))
  styleGaugeText(healthGauge, 12)
  wireGaugeUpdate(healthGauge, "Char.Vitals.hp", "Char.Vitals.maxHp", "hp", "gmcp.Char.Vitals")
  
  local wimpyBar = Geyser.Label:new({
    x=0, y=0,
    width=2, height="100%",
  }, healthGauge.back)
  wimpyBar:setStyleSheet([[
    background-color: yellow;
  ]])

  lotj.setup.registerEventHandler("gmcp.Char.Vitals", function()
    local health = gmcp.Char.Vitals.hp
    local healthMax = gmcp.Char.Vitals.maxHp
    local wimpy = gmcp.Char.Vitals.wimpy
    if healthMax > 0 then
      if wimpy > 0 and health > 0 and wimpy < health then
        wimpyBar:show()
        wimpyBar:move(math.floor(wimpy*100/health).."%", nil)
      else
        wimpyBar:hide()
      end
    end
  end)

  -- Movement gauge
  local movementGauge = Geyser.Gauge:new({
    x="5%", y=23,
    width="90%", height=16,
  }, container)
  movementGauge.front:setStyleSheet(gaugeFrontStyle("#41f041", "#29ef29", "#00cc00", "#00a400", "#00cc00"))
  movementGauge.back:setStyleSheet(gaugeBackStyle("#113f11", "#073f07", "#003300", "#002200", "#003300"))
  styleGaugeText(movementGauge, 12)
  wireGaugeUpdate(movementGauge, "Char.Vitals.move", "Char.Vitals.maxMove", "mv", "gmcp.Char.Vitals")

  -- Mana gauge (will be hidden later if we do not have mana)
  local manaGauge = Geyser.Gauge:new({
    x="5%", y=42,
    width="90%", height=16,
  }, container)
  manaGauge.front:setStyleSheet(gaugeFrontStyle("#4141f0", "#2929ef", "#0000cc", "#0000a4", "#0000cc"))
  manaGauge.back:setStyleSheet(gaugeBackStyle("#11113f", "#07073f", "#000033", "#000022", "#000011"))
  styleGaugeText(manaGauge, 12)
  wireGaugeUpdate(manaGauge, "Char.Vitals.mana", "Char.Vitals.maxMana", "mn", "gmcp.Char.Vitals")
  
  lotj.setup.registerEventHandler("gmcp.Char.Vitals", function()
    local manaMax = gmcp.Char.Vitals.maxMana or 0
    if manaMax > 0 then
      healthGauge:move(nil, 4)
      healthGauge:resize(nil, 16)
      healthGauge:setFontSize("12")
  
      movementGauge:move(nil, 23)
      movementGauge:resize(nil, 16)
      movementGauge:setFontSize("12")
  
      manaGauge:show()
      manaGauge:move(nil, 42)
      manaGauge:resize(nil, 16)
      manaGauge:setFontSize("12")
    else
      healthGauge:move(nil, 6)
      healthGauge:resize(nil, 22)
      healthGauge:setFontSize("13")
  
      movementGauge:move(nil, 32)
      movementGauge:resize(nil, 22)
      movementGauge:setFontSize("13")
  
      manaGauge:hide()
    end
  end)
end


function lotj.infoPanel.createOpponentStats(container)
  -- Opponent health gauge
  local opponentGauge = Geyser.Gauge:new({
    x="5%", y=6,
    width="90%", height=48,
  }, container)
  opponentGauge.front:setStyleSheet(gaugeFrontStyle("#bd7833", "#bd6e20", "#994c00", "#703800", "#994c00"))
  opponentGauge.back:setStyleSheet(gaugeBackStyle("#442511", "#441d08", "#331100", "#200900", "#331100"))
  opponentGauge.text:setStyleSheet("padding: 10px;")
  opponentGauge:setAlignment("c")
  opponentGauge:setFontSize("12")

  local function update()
    local opponentName = string.gsub(gmcp.Char.Enemy.name or "", "&.", "")
    -- Opponent name seems to always be empty string even when fighting, so fall back to something reasonable
    if opponentName == "" then
      opponentName = "Current target"
    end
    local opponentHealth = gmcp.Char.Enemy.Percent
    local opponentHealthMax = 100
    if opponentHealth ~= nil then
      opponentGauge:setValue(opponentHealth, opponentHealthMax, opponentName.."<br>"..opponentHealth.."%")
    else
      opponentGauge:setValue(0, 1, "Not fighting")
    end
  end
  lotj.setup.registerEventHandler("gmcp.Char.Enemy", update)
end


function lotj.infoPanel.createChatInfo(container)
  -- Commnet channel/code
  local commnetLabel = Geyser.Label:new({
    x="3%", y=6,
    width="20%", height=24,
  }, container)
  commnetLabel:echo("Comm:", nil, "rb13")
  local commnetInfo = Geyser.Label:new({
    x = "25%", y = 6,
    width = "75%", height = 24
  }, container)

  local function updateCommnet()
    local commChannel = gmcp.Char.Chat.commChannel
    local commEncrypt = gmcp.Char.Chat.commEncrypt
    if not commChannel then
      commnetInfo:echo("None", nil, "l13")
    elseif commEncrypt then
      commnetInfo:echo(commChannel.." (E "..commEncrypt..")", nil, "l13")
    else
      commnetInfo:echo(commChannel, nil, "l13")
    end
  end
  lotj.setup.registerEventHandler("gmcp.Char.Chat", updateCommnet)

  -- OOC meter
  local oocLabel = Geyser.Label:new({
    x="3%", y=32,
    width="20%", height=24,
  }, container)
  oocLabel:echo("OOC:", nil, "rb13")
  local oocGauge = Geyser.Gauge:new({
    x="25%", y=32,
    width="40%", height=20,
  }, container)
  oocGauge.front:setStyleSheet(gaugeFrontStyle("#31d0d0", "#22cfcf", "#00b2b2", "#009494", "#00b2b2"))
  oocGauge.back:setStyleSheet(gaugeBackStyle("#113f3f", "#073f3f", "#003333", "#002222", "#001111"))

  lotj.setup.registerEventHandler("gmcp.Char.Chat", function()
    local oocLeft = gmcp.Char.Chat.oocLimit or 0
    local oocMax = 6
    oocGauge:setValue(oocLeft, oocMax)
  end)
end


function lotj.infoPanel.createSpaceStats(container)
  local energyGauge = Geyser.Gauge:new({
    x="3%", y=4,
    width="30%", height=16,
  }, container)
  energyGauge.front:setStyleSheet(gaugeFrontStyle("#7a7a7a", "#777777", "#656565", "#505050", "#656565"))
  energyGauge.back:setStyleSheet(gaugeBackStyle("#383838", "#303030", "#222222", "#151515", "#222222"))
  styleGaugeText(energyGauge, 12)
  wireGaugeUpdate(energyGauge, "Ship.Info.energy", "Ship.Info.maxEnergy", "en", "gmcp.Ship.Info")

  local hullGauge = Geyser.Gauge:new({
    x="3%", y=23,
    width="30%", height=16,
  }, container)
  hullGauge.front:setStyleSheet(gaugeFrontStyle("#bd7833", "#bd6e20", "#994c00", "#703800", "#994c00"))
  hullGauge.back:setStyleSheet(gaugeBackStyle("#442511", "#441d08", "#331100", "#200900", "#331100"))
  styleGaugeText(hullGauge, 12)
  wireGaugeUpdate(hullGauge, "Ship.Info.hull", "Ship.Info.maxHull", "hl", "gmcp.Ship.Info")

  local shieldGauge = Geyser.Gauge:new({
    x="3%", y=42,
    width="30%", height=16,
  }, container)
  shieldGauge.front:setStyleSheet(gaugeFrontStyle("#31d0d0", "#22cfcf", "#00b2b2", "#009494", "#00b2b2"))
  shieldGauge.back:setStyleSheet(gaugeBackStyle("#113f3f", "#073f3f", "#003333", "#002222", "#001111"))
  styleGaugeText(shieldGauge, 12)
  wireGaugeUpdate(shieldGauge, "Ship.Info.shield", "Ship.Info.maxShield", "sh", "gmcp.Ship.Info")

  
  -- Piloting indicator
  local pilotLabel = Geyser.Label:new({
    x="35%", y=6,
    width="13%", height=24
  }, container)
  pilotLabel:echo("Pilot:", nil, "lb12")

  local pilotBoxCont = Geyser.Label:new({
    x="48%", y=10,
    width="8%", height=16
  }, container)
  local pilotBox = Geyser.Label:new({
    x=2, y=0,
    width=16, height=16
  }, pilotBoxCont)

  lotj.setup.registerEventHandler("gmcp.Ship.Info", function()
    if gmcp.Ship and gmcp.Ship.Info.piloting then
      pilotBox:setStyleSheet("background-color: #29efef; border: 2px solid #eeeeee;")
    else
      pilotBox:setStyleSheet("background-color: #073f3f; border: 2px solid #eeeeee;")
    end
  end)


  local speedGauge = Geyser.Label:new({
    x="56%", y=6,
    width="19%", height=24,
  }, container)
  
  local function updateSpeed()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.maxSpeed then
      speedGauge:echo("<b>Sp:</b> N/A", nil, "l12")
    else
      local speed = gmcp.Ship.Info.speed or 0
      local maxSpeed = gmcp.Ship.Info.maxSpeed or 0
      speedGauge:echo("<b>Sp:</b> "..speed.."<b>/</b>"..maxSpeed, nil, "l12")
    end
  end
  lotj.setup.registerEventHandler("gmcp.Ship.Info", updateSpeed)


  local coordsInfo = Geyser.Label:new({
    x="35%", y=32,
    width="40%", height=24,
  }, container)

  local function updateCoords()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.posX then
      coordsInfo:echo("<b>Coords:</b> N/A", nil, "l12")
    else
      local shipX = gmcp.Ship.Info.posX or 0
      local shipY = gmcp.Ship.Info.posY or 0
      local shipZ = gmcp.Ship.Info.posZ or 0
      coordsInfo:echo("<b>Coords:</b> "..shipX.." "..shipY.." "..shipZ, nil, "l12")
    end
  end
  lotj.setup.registerEventHandler("gmcp.Ship.Info", updateCoords)

  lotj.infoPanel.spaceTickCounter = Geyser.Label:new({
    x="77%", y=6,
    width="20%", height=24,
  }, container)

  lotj.infoPanel.chaffIndicator = Geyser.Label:new({
    x="77%", y=32,
    width="20%", height=24,
  }, container)
  lotj.infoPanel.chaffIndicator:echo("[Chaff]", "yellow", "c13b")
  lotj.infoPanel.chaffIndicator:hide()
end

-- Sets up timers to refresh the space tick counter
function lotj.infoPanel.markSpaceTick()
  for _, timerId in ipairs(lotj.infoPanel.spaceTickTimers or {}) do
    killTimer(timerId)
  end

  lotj.infoPanel.spaceTickCounter:show()
  lotj.infoPanel.spaceTickTimers = {}
  for i = 0,20,1 do
    local timerId = tempTimer(i, function()
      lotj.infoPanel.spaceTickCounter:echo("<b>Tick:</b> "..20-i, nil, "c13")
    end)
    table.insert(lotj.infoPanel.spaceTickTimers, timerId)
  end

  -- A few seconds after the next tick should happen, hide the counter.
  -- This will be canceled if we see another tick before then.
  local timerId = tempTimer(23, function()
    lotj.infoPanel.spaceTickCounter:hide()
  end)
  table.insert(lotj.infoPanel.spaceTickTimers, timerId)
end

function lotj.infoPanel.markChaff()
  lotj.infoPanel.clearChaff()
  lotj.infoPanel.chaffIndicator:show()

  -- In case we miss the "chaff cleared" message somehow, set a 20 second timer to get rid of this
  lotj.infoPanel.chaffTimer = tempTimer(20, function()
    lotj.infoPanel.clearChaff()
  end)
end

function lotj.infoPanel.clearChaff()
  if lotj.infoPanel.chaffTimer ~= nil then
    killTimer(lotj.infoPanel.chaffTimer)
    lotj.infoPanel.chaffTimer = nil
  end

  lotj.infoPanel.chaffIndicator:hide()
end
