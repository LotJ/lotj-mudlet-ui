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
    padding-right: ]]..(getFontSize()-2)..[[px;
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
  styleGaugeText(healthGauge, getFontSize()-1)
  wireGaugeUpdate(healthGauge, "Char.Vitals.hp", "Char.Vitals.maxHp", "hp", "gmcp.Char.Vitals")
  
  local wimpyBar = Geyser.Label:new({
    x=0, y=0,
    width=2, height="100%",
  }, healthGauge.back)
  wimpyBar:setStyleSheet([[
    background-color: yellow;
  ]])

  lotj.setup.registerEventHandler("gmcp.Char.Vitals", function()
    if not gmcp.Char or not gmcp.Char.Vitals then return end

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
  styleGaugeText(movementGauge, getFontSize()-1)
  wireGaugeUpdate(movementGauge, "Char.Vitals.move", "Char.Vitals.maxMove", "mv", "gmcp.Char.Vitals")

  -- Mana gauge (will be hidden later if we do not have mana)
  local manaGauge = Geyser.Gauge:new({
    x="5%", y=42,
    width="90%", height=16,
  }, container)
  manaGauge.front:setStyleSheet(gaugeFrontStyle("#4141f0", "#2929ef", "#0000cc", "#0000a4", "#0000cc"))
  manaGauge.back:setStyleSheet(gaugeBackStyle("#11113f", "#07073f", "#000033", "#000022", "#000011"))
  styleGaugeText(manaGauge, getFontSize()-1)
  wireGaugeUpdate(manaGauge, "Char.Vitals.mana", "Char.Vitals.maxMana", "mn", "gmcp.Char.Vitals")
  
  lotj.setup.registerEventHandler("gmcp.Char.Vitals", function()
    local totalSpace = lotj.layout.lowerInfoPanelHeight
    local manaMax = gmcp.Char.Vitals.maxMana or 0
    if manaMax > 0 then
      local gaugeSpacing = math.floor(totalSpace/20)
      local gaugeHeight = math.ceil(lotj.layout.lowerInfoPanelHeight/5 * 1.33)
      local allGaugesHeight = gaugeHeight*3+gaugeSpacing*2
      local gaugesStart = math.floor((totalSpace - allGaugesHeight)/2)

      healthGauge:move(nil, gaugesStart)
      healthGauge:resize(nil, gaugeHeight)
      healthGauge:setFontSize(getFontSize()-1)
  
      movementGauge:move(nil, gaugesStart+gaugeHeight+gaugeSpacing)
      movementGauge:resize(nil, gaugeHeight)
      movementGauge:setFontSize(getFontSize()-1)
  
      manaGauge:show()
      manaGauge:move(nil, gaugesStart+gaugeHeight*2+gaugeSpacing*2)
      manaGauge:resize(nil, gaugeHeight)
      manaGauge:setFontSize(getFontSize()-1)
    else
      local gaugeSpacing = math.floor(totalSpace/15)
      local gaugeHeight = math.ceil(lotj.layout.lowerInfoPanelHeight/5 * 1.66)
      local allGaugesHeight = gaugeHeight*2+gaugeSpacing
      local gaugesStart = math.floor((totalSpace - allGaugesHeight)/2)

      healthGauge:move(nil, gaugesStart)
      healthGauge:resize(nil, gaugeHeight)
      healthGauge:setFontSize(getFontSize())
  
      movementGauge:move(nil, gaugesStart+gaugeHeight+gaugeSpacing)
      movementGauge:resize(nil, gaugeHeight)
      movementGauge:setFontSize(getFontSize())
  
      manaGauge:hide()
    end
  end)
end


function lotj.infoPanel.createOpponentStats(container)
  -- Opponent health gauge
  local opponentGauge = Geyser.Gauge:new({
    x="5%", y="10%",
    width="90%", height="80%",
  }, container)
  opponentGauge.front:setStyleSheet(gaugeFrontStyle("#bd7833", "#bd6e20", "#994c00", "#703800", "#994c00"))
  opponentGauge.back:setStyleSheet(gaugeBackStyle("#442511", "#441d08", "#331100", "#200900", "#331100"))
  opponentGauge.text:setStyleSheet("padding: 10px;")
  opponentGauge:setAlignment("c")
  opponentGauge:setFontSize(getFontSize()-1)

  local function update()
    if not gmcp.Char.Enemy.name then
      opponentGauge:setValue(0, 1, "Not fighting")
      return
    end

    local opponentName = string.gsub(gmcp.Char.Enemy.name, "&.", "")
    if opponentName == "" then
      opponentName = "Current target"
    end
    local opponentHealth = gmcp.Char.Enemy.percent
    local opponentHealthMax = 100
    opponentGauge:setValue(opponentHealth, opponentHealthMax, opponentName.."<br>"..opponentHealth.."%")
  end
  lotj.setup.registerEventHandler("gmcp.Char.Enemy", update)
end


function lotj.infoPanel.createChatInfo(container)
  -- Commnet channel/code
  local commnetInfo = Geyser.Label:new({
    x="3%", y="10%",
    width="94%", height="40%",
  }, container)

  local function updateCommnet()
    local commChannel = gmcp.Char.Chat.commChannel
    local commEncrypt = gmcp.Char.Chat.commEncrypt
    if not commChannel then
      commnetInfo:echo("<b>Comm:</b> None", nil, "l"..getFontSize())
    elseif commEncrypt then
      commnetInfo:echo("<b>Comm:</b> "..commChannel.." (E "..commEncrypt..")", nil, "l"..getFontSize())
    else
      commnetInfo:echo("<b>Comm:</b> "..commChannel, nil, "l"..getFontSize())
    end
  end
  lotj.setup.registerEventHandler("gmcp.Char.Chat", updateCommnet)

  -- OOC meter
  local oocLabel = Geyser.Label:new({
    x="3%", y="53%",
    width="27%", height="40%",
  }, container)
  oocLabel:echo("OOC:", nil, "rb"..getFontSize())
  local oocGauge = Geyser.Gauge:new({
    x="33%", y="53%",
    width="40%", height="33%",
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
  local totalSpace = lotj.layout.lowerInfoPanelHeight
  local gaugeSpacing = math.floor(totalSpace/15)
  local gaugeHeight = math.ceil(lotj.layout.lowerInfoPanelHeight/5 * 1.33)
  local allGaugesHeight = gaugeHeight*3+gaugeSpacing
  local gaugesStart = math.floor((totalSpace - allGaugesHeight)/2)

  local energyGauge = Geyser.Gauge:new({
    x="3%", y=gaugesStart,
    width="30%", height=gaugeHeight,
  }, container)
  energyGauge.front:setStyleSheet(gaugeFrontStyle("#7a7a7a", "#777777", "#656565", "#505050", "#656565"))
  energyGauge.back:setStyleSheet(gaugeBackStyle("#383838", "#303030", "#222222", "#151515", "#222222"))
  styleGaugeText(energyGauge, getFontSize()-1)
  wireGaugeUpdate(energyGauge, "Ship.Info.energy", "Ship.Info.maxEnergy", "en", "gmcp.Ship.Info")

  local hullGauge = Geyser.Gauge:new({
    x="3%", y=gaugesStart+gaugeHeight+gaugeSpacing,
    width="30%", height=gaugeHeight,
  }, container)
  hullGauge.front:setStyleSheet(gaugeFrontStyle("#bd7833", "#bd6e20", "#994c00", "#703800", "#994c00"))
  hullGauge.back:setStyleSheet(gaugeBackStyle("#442511", "#441d08", "#331100", "#200900", "#331100"))
  styleGaugeText(hullGauge, getFontSize()-1)
  wireGaugeUpdate(hullGauge, "Ship.Info.hull", "Ship.Info.maxHull", "hl", "gmcp.Ship.Info")

  local shieldGauge = Geyser.Gauge:new({
    x="3%", y=gaugesStart+gaugeHeight*2+gaugeSpacing*2,
    width="30%", height=gaugeHeight,
  }, container)
  shieldGauge.front:setStyleSheet(gaugeFrontStyle("#31d0d0", "#22cfcf", "#00b2b2", "#009494", "#00b2b2"))
  shieldGauge.back:setStyleSheet(gaugeBackStyle("#113f3f", "#073f3f", "#003333", "#002222", "#001111"))
  styleGaugeText(shieldGauge, getFontSize()-1)
  wireGaugeUpdate(shieldGauge, "Ship.Info.shield", "Ship.Info.maxShield", "sh", "gmcp.Ship.Info")

  
  -- Piloting indicator
  local pilotLabel = Geyser.Label:new({
    x="35%", y="10%",
    width="13%", height="40%"
  }, container)
  pilotLabel:echo("Pilot:  ", nil, "rb"..getFontSize())

  local pilotBoxCont = Geyser.Label:new({
    x="48%", y="16%",
    width="8%", height=gaugeHeight
  }, container)
  local pilotBox = Geyser.Label:new({
    x=2, y=0,
    width=gaugeHeight, height=gaugeHeight
  }, pilotBoxCont)

  lotj.setup.registerEventHandler("gmcp.Ship.Info", function()
    if gmcp.Ship and gmcp.Ship.Info.piloting then
      pilotBox:setStyleSheet("background-color: #29efef; border: 2px solid #eeeeee;")
    else
      pilotBox:setStyleSheet("background-color: #073f3f; border: 2px solid #eeeeee;")
    end
  end)


  local speedGauge = Geyser.Label:new({
    x="56%", y="10%",
    width="19%", height="40%",
  }, container)
  
  local function updateSpeed()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.maxSpeed then
      speedGauge:echo("<b>Sp:</b> N/A", nil, "l"..getFontSize())
    else
      local speed = gmcp.Ship.Info.speed or 0
      local maxSpeed = gmcp.Ship.Info.maxSpeed or 0
      speedGauge:echo("<b>Sp:</b> "..speed.."<b>/</b>"..maxSpeed, nil, "l"..getFontSize())
    end
  end
  lotj.setup.registerEventHandler("gmcp.Ship.Info", updateSpeed)


  local coordsInfo = Geyser.Label:new({
    x="35%", y="53%",
    width="60%", height="40%",
  }, container)

  local function updateCoords()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.posX then
      coordsInfo:echo("<b>Coords:</b> N/A", nil, "l"..getFontSize())
    else
      local shipX = gmcp.Ship.Info.posX or 0
      local shipY = gmcp.Ship.Info.posY or 0
      local shipZ = gmcp.Ship.Info.posZ or 0
      coordsInfo:echo("<b>Coords:</b> "..shipX.." "..shipY.." "..shipZ, nil, "l"..getFontSize())
    end
  end
  lotj.setup.registerEventHandler("gmcp.Ship.Info", updateCoords)

  lotj.infoPanel.spaceTickCounter = Geyser.Label:new({
    x="77%", y="10%",
    width="15%", height="40%",
  }, container)

  lotj.infoPanel.chaffIndicator = Geyser.Label:new({
    x="77%", y="53%",
    width="15%", height="40%",
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
