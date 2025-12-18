lotj = lotj or {}
lotj.infoPanel = lotj.infoPanel or {}


function lotj.infoPanel.setup()
  local basicStatsContainer = Geyser.Label:new({
    h_stretch_factor = 1.75
  }, lotj.layout.lowerInfoPanel)
  local combatContainer = Geyser.Label:new({
    h_stretch_factor = 1.15
  }, lotj.layout.lowerInfoPanel)
  local chatContainer = Geyser.Label:new({
    h_stretch_factor = 0.6
  }, lotj.layout.lowerInfoPanel)

  lotj.infoPanel.createBasicStats(basicStatsContainer)
  lotj.infoPanel.createOpponentStats(combatContainer)
  lotj.infoPanel.createChatInfo(chatContainer)
  lotj.infoPanel.createShipOverlay()

  -- Wire up ship overlay visibility
  lotj.setup.registerEventHandler("gmcp.Ship.Info", lotj.infoPanel.updateShipOverlayVisibility)
end

function lotj.infoPanel.updateShipOverlayVisibility()
  if gmcp.Ship and gmcp.Ship.Info and not table.is_empty(gmcp.Ship.Info) then
    -- We're in a ship, show the overlay above the bottom panel
    lotj.layout.shipOverlay:show()
    setBorderBottom(lotj.layout.lowerInfoPanelHeight + lotj.layout.shipOverlayHeight)
  else
    -- Not in a ship, hide the overlay
    lotj.layout.shipOverlay:hide()
    setBorderBottom(lotj.layout.lowerInfoPanelHeight)
  end
end


-- Utility functions
local function gaugeFrontStyle(step1, step2, step3, step4, step5)
  return [[
    background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 ]]..step1..[[, stop: 0.05 ]]..step2..[[, stop: 0.1 ]]..step3..[[, stop: 0.45 ]]..step3..[[, stop: 0.5 ]]..step5..[[, stop: 0.55 ]]..step3..[[, stop: 1 ]]..step3..[[);
    border: 1px solid ]]..step1..[[;
    border-radius: 4px;
    padding: 3px;
    box-shadow: 0 0 8px ]]..step3..[[, 0 0 4px ]]..step2..[[;
  ]]
end

local function gaugeBackStyle(step1, step2, step3, step4, step5)
  return [[
    background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 ]]..step1..[[, stop: 0.05 ]]..step2..[[, stop: 0.1 ]]..step3..[[, stop: 0.45 ]]..step3..[[, stop: 0.5 ]]..step5..[[, stop: 0.55 ]]..step3..[[, stop: 1 ]]..step3..[[);
    border: 1px solid ]]..step1..[[;
    border-radius: 4px;
    padding: 3px;
    box-shadow: 0 0 4px ]]..step3..[[, 0 0 2px ]]..step4..[[;
  ]]
end

local function styleGaugeText(gauge, fontSize)
  gauge.text:setStyleSheet([[
    padding-left: ]]..(getFontSize()-2)..[[px;
  ]])
  gauge:setAlignment("l")
  gauge:setFontSize(fontSize)
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
  local totalSpace = lotj.layout.lowerInfoPanelHeight
  local gaugeHeight = math.ceil(totalSpace * 0.7)
  local gaugesStart = math.floor((totalSpace - gaugeHeight)/2)

  -- Health gauge
  local healthGauge = Geyser.Gauge:new({
    x="2%", y=gaugesStart,
    width="31%", height=gaugeHeight,
  }, container)
  healthGauge.front:setStyleSheet(gaugeFrontStyle("#f04141", "#ef2929", "#cc0000", "#a40000", "#cc0000"))
  healthGauge.back:setStyleSheet(gaugeBackStyle("#3f1111", "#3f0707", "#330000", "#220000", "#330000"))
  styleGaugeText(healthGauge, getFontSize())
  wireGaugeUpdate(healthGauge, "Char.Vitals.hp", "Char.Vitals.maxHp", "", "gmcp.Char.Vitals")

  -- Health icon overlay - 75% of gauge height, positioned on right side
  local healthIconSize = math.ceil(gaugeHeight * 0.75)
  local healthIconStart = math.floor((gaugeHeight - healthIconSize) / 2)
  local healthIcon = Geyser.Label:new({
    x="-20%", y=healthIconStart,
    width=healthIconSize, height=healthIconSize,
  }, healthGauge)
  local healthFile = getMudletHomeDir().."/@PKGNAME@/health_icon.png"
  healthIcon:setStyleSheet([[
    border-image: url(]]..healthFile..[[)
  ]])

  local wimpyBar = Geyser.Label:new({
    x=0, y=0,
    width=2, height="100%",
  }, healthGauge.back)
  wimpyBar:setStyleSheet([[
    background-color: rgba(255, 255, 0, 200);
    border-radius: 2px;
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
    x="35%", y=gaugesStart,
    width="31%", height=gaugeHeight,
  }, container)
  movementGauge.front:setStyleSheet(gaugeFrontStyle("#41f041", "#29ef29", "#00cc00", "#00a400", "#00cc00"))
  movementGauge.back:setStyleSheet(gaugeBackStyle("#113f11", "#073f07", "#003300", "#002200", "#003300"))
  styleGaugeText(movementGauge, getFontSize())
  wireGaugeUpdate(movementGauge, "Char.Vitals.move", "Char.Vitals.maxMove", "", "gmcp.Char.Vitals")

  -- Stamina icon overlay - 75% of gauge height, positioned on right side
  local staminaIconSize = math.ceil(gaugeHeight * 0.75)
  local staminaIconStart = math.floor((gaugeHeight - staminaIconSize) / 2)
  local staminaIcon = Geyser.Label:new({
    x="-20%", y=staminaIconStart,
    width=staminaIconSize, height=staminaIconSize,
  }, movementGauge)
  local staminaFile = getMudletHomeDir().."/@PKGNAME@/stamina_icon.png"
  staminaIcon:setStyleSheet([[
    border-image: url(]]..staminaFile..[[)
  ]])

  -- Mana/Force gauge (conditionally shown)
  local manaGauge = Geyser.Gauge:new({
    x="68%", y=gaugesStart,
    width="30%", height=gaugeHeight,
  }, container)
  manaGauge.front:setStyleSheet(gaugeFrontStyle("#4141f0", "#2929ef", "#0000cc", "#0000a4", "#0000cc"))
  manaGauge.back:setStyleSheet(gaugeBackStyle("#11113f", "#07073f", "#000033", "#000022", "#000011"))
  styleGaugeText(manaGauge, getFontSize())
  wireGaugeUpdate(manaGauge, "Char.Vitals.mana", "Char.Vitals.maxMana", "mn", "gmcp.Char.Vitals")

  -- Show/hide mana gauge based on whether character has mana
  lotj.setup.registerEventHandler("gmcp.Char.Vitals", function()
    if not gmcp.Char or not gmcp.Char.Vitals then return end
    local manaMax = gmcp.Char.Vitals.maxMana or 0
    if manaMax > 0 then
      manaGauge:show()
      -- With mana: all three gauges visible, narrower
      healthGauge:move("2%", nil)
      healthGauge:resize("31%", nil)
      movementGauge:move("35%", nil)
      movementGauge:resize("31%", nil)
    else
      manaGauge:hide()
      -- Without mana: two gauges, wider
      healthGauge:move("2%", nil)
      healthGauge:resize("47%", nil)
      movementGauge:move("51%", nil)
      movementGauge:resize("47%", nil)
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
  opponentGauge.text:setStyleSheet("padding: 3px;")
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
    opponentGauge:setValue(opponentHealth, opponentHealthMax, opponentName.." - "..opponentHealth.."%")
  end
  lotj.setup.registerEventHandler("gmcp.Char.Enemy", update)
end


function lotj.infoPanel.createChatInfo(container)
  -- Commlink icon - square aspect ratio based on container height
  local totalSpace = lotj.layout.lowerInfoPanelHeight
  local iconSize = math.ceil(totalSpace * 1.0)
  local iconStart = math.floor((totalSpace - iconSize) / 2)

  local commIcon = Geyser.Label:new({
    x=0, y=iconStart,
    width=iconSize, height=iconSize,
  }, container)
  local file = getMudletHomeDir().."/@PKGNAME@/commlink_icon.png"
  commIcon:setStyleSheet([[
    border-image: url(]]..file..[[)
  ]])

  -- Commnet channel/code - position after the icon
  local commnetInfo = Geyser.Label:new({
    x=iconSize + 5, y="10%",
    width="100%-"..(iconSize + 10), height="80%",
  }, container)

  local function updateCommnet()
    local commChannel = gmcp.Char.Chat.commChannel
    local commEncrypt = gmcp.Char.Chat.commEncrypt
    if not commChannel then
      commnetInfo:echo("None", nil, "l"..getFontSize())
    elseif commEncrypt then
      commnetInfo:echo(commChannel.." : "..commEncrypt, nil, "l"..getFontSize())
    else
      commnetInfo:echo(commChannel, nil, "l"..getFontSize())
    end
  end
  lotj.setup.registerEventHandler("gmcp.Char.Chat", updateCommnet)
end


function lotj.infoPanel.createSpaceStats(container)
  local totalSpace = lotj.layout.lowerInfoPanelHeight
  local gaugeSpacing = math.floor(totalSpace/15)
  local gaugeHeight = math.ceil(lotj.layout.lowerInfoPanelHeight/5 * 1.33)
  local allGaugesHeight = gaugeHeight*3+gaugeSpacing
  local gaugesStart = math.floor((totalSpace - allGaugesHeight)/2)
  local spaceStatFontSize = getFontSize()-1

  local energyGauge = Geyser.Gauge:new({
    x="3%", y=gaugesStart,
    width="30%", height=gaugeHeight,
  }, container)
  energyGauge.front:setStyleSheet(gaugeFrontStyle("#7a7a7a", "#777777", "#656565", "#505050", "#656565"))
  energyGauge.back:setStyleSheet(gaugeBackStyle("#383838", "#303030", "#222222", "#151515", "#222222"))
  styleGaugeText(energyGauge, spaceStatFontSize)
  wireGaugeUpdate(energyGauge, "Ship.Info.energy", "Ship.Info.maxEnergy", "en", "gmcp.Ship.Info")

  local hullGauge = Geyser.Gauge:new({
    x="3%", y=gaugesStart+gaugeHeight+gaugeSpacing,
    width="30%", height=gaugeHeight,
  }, container)
  hullGauge.front:setStyleSheet(gaugeFrontStyle("#bd7833", "#bd6e20", "#994c00", "#703800", "#994c00"))
  hullGauge.back:setStyleSheet(gaugeBackStyle("#442511", "#441d08", "#331100", "#200900", "#331100"))
  styleGaugeText(hullGauge, spaceStatFontSize)
  wireGaugeUpdate(hullGauge, "Ship.Info.hull", "Ship.Info.maxHull", "hl", "gmcp.Ship.Info")

  local shieldGauge = Geyser.Gauge:new({
    x="3%", y=gaugesStart+gaugeHeight*2+gaugeSpacing*2,
    width="30%", height=gaugeHeight,
  }, container)
  shieldGauge.front:setStyleSheet(gaugeFrontStyle("#31d0d0", "#22cfcf", "#00b2b2", "#009494", "#00b2b2"))
  shieldGauge.back:setStyleSheet(gaugeBackStyle("#113f3f", "#073f3f", "#003333", "#002222", "#001111"))
  styleGaugeText(shieldGauge, spaceStatFontSize)
  wireGaugeUpdate(shieldGauge, "Ship.Info.shield", "Ship.Info.maxShield", "sh", "gmcp.Ship.Info")

  
  -- Piloting indicator
  local pilotLabel = Geyser.Label:new({
    x="35%", y="10%",
    width="13%", height="40%"
  }, container)
  pilotLabel:echo("Pilot:  ", nil, "rb"..spaceStatFontSize)

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
      pilotBox:setStyleSheet("background-color: #29efef; border: 2px solid #eeeeee; border-radius: 3px;")
    else
      pilotBox:setStyleSheet("background-color: #073f3f; border: 2px solid #eeeeee; border-radius: 3px;")
    end
  end)


  local speedGauge = Geyser.Label:new({
    x="56%", y="10%",
    width="19%", height="40%",
  }, container)
  
  local function updateSpeed()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.maxSpeed then
      speedGauge:echo("<b>Sp:</b> N/A", nil, "l"..spaceStatFontSize)
    else
      local speed = gmcp.Ship.Info.speed or 0
      local maxSpeed = gmcp.Ship.Info.maxSpeed or 0
      speedGauge:echo("<b>Sp:</b> "..speed.."<b>/</b>"..maxSpeed, nil, "l"..spaceStatFontSize)
    end
  end
  lotj.setup.registerEventHandler("gmcp.Ship.Info", updateSpeed)


  local coordsInfo = Geyser.Label:new({
    x="35%", y="53%",
    width="60%", height="40%",
  }, container)

  local function updateCoords()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.posX then
      coordsInfo:echo("<b>Coords:</b> N/A", nil, "l"..spaceStatFontSize)
    else
      local shipX = gmcp.Ship.Info.posX or 0
      local shipY = gmcp.Ship.Info.posY or 0
      local shipZ = gmcp.Ship.Info.posZ or 0
      coordsInfo:echo("<b>Coords:</b> "..shipX.." "..shipY.." "..shipZ, nil, "l"..spaceStatFontSize)
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
  lotj.infoPanel.chaffIndicator:echo("[Chaff]", "yellow", "c"..spaceStatFontSize.."b")
  lotj.infoPanel.chaffIndicator:hide()
end

function lotj.infoPanel.createShipOverlay()
  local totalSpace = lotj.layout.shipOverlayHeight
  local gaugeHeight = math.ceil(totalSpace * 0.7)
  local gaugesStart = math.floor((totalSpace - gaugeHeight)/2)
  local shipStatFontSize = getFontSize()

  -- Ship gauges container (aligns with character vitals)
  local shipGaugesContainer = Geyser.Label:new({
    h_stretch_factor = 1.75
  }, lotj.layout.shipOverlay)

  -- Ship HUD container (aligns with combat + chat area)
  local shipHudContainer = Geyser.Label:new({
    h_stretch_factor = 1.75
  }, lotj.layout.shipOverlay)

  -- Shield gauge
  lotj.infoPanel.shipShieldGauge = Geyser.Gauge:new({
    x="2%", y=gaugesStart,
    width="31%", height=gaugeHeight,
  }, shipGaugesContainer)
  lotj.infoPanel.shipShieldGauge.front:setStyleSheet(gaugeFrontStyle("#31d0d0", "#22cfcf", "#00b2b2", "#009494", "#00b2b2"))
  lotj.infoPanel.shipShieldGauge.back:setStyleSheet(gaugeBackStyle("#113f3f", "#073f3f", "#003333", "#002222", "#001111"))
  styleGaugeText(lotj.infoPanel.shipShieldGauge, shipStatFontSize)
  wireGaugeUpdate(lotj.infoPanel.shipShieldGauge, "Ship.Info.shield", "Ship.Info.maxShield", "", "gmcp.Ship.Info")

  -- Shield icon overlay - 75% of gauge height, positioned on right side
  local shieldIconSize = math.ceil(gaugeHeight * 0.75)
  local shieldIconStart = math.floor((gaugeHeight - shieldIconSize) / 2)
  local shieldIcon = Geyser.Label:new({
    x="-20%", y=shieldIconStart,
    width=shieldIconSize, height=shieldIconSize,
  }, lotj.infoPanel.shipShieldGauge)
  local shieldFile = getMudletHomeDir().."/@PKGNAME@/shield_icon.png"
  shieldIcon:setStyleSheet([[
    border-image: url(]]..shieldFile..[[)
  ]])

  -- Hull gauge
  lotj.infoPanel.shipHullGauge = Geyser.Gauge:new({
    x="35%", y=gaugesStart,
    width="31%", height=gaugeHeight,
  }, shipGaugesContainer)
  lotj.infoPanel.shipHullGauge.front:setStyleSheet(gaugeFrontStyle("#7a7a7a", "#777777", "#656565", "#505050", "#656565"))
  lotj.infoPanel.shipHullGauge.back:setStyleSheet(gaugeBackStyle("#383838", "#303030", "#222222", "#151515", "#222222"))
  styleGaugeText(lotj.infoPanel.shipHullGauge, shipStatFontSize)
  wireGaugeUpdate(lotj.infoPanel.shipHullGauge, "Ship.Info.hull", "Ship.Info.maxHull", "", "gmcp.Ship.Info")

  -- Hull icon overlay - 75% of gauge height, positioned on right side
  local hullIconSize = math.ceil(gaugeHeight * 0.75)
  local hullIconStart = math.floor((gaugeHeight - hullIconSize) / 2)
  local hullIcon = Geyser.Label:new({
    x="-20%", y=hullIconStart,
    width=hullIconSize, height=hullIconSize,
  }, lotj.infoPanel.shipHullGauge)
  local hullFile = getMudletHomeDir().."/@PKGNAME@/hull_icon.png"
  hullIcon:setStyleSheet([[
    border-image: url(]]..hullFile..[[)
  ]])

  -- Energy gauge
  lotj.infoPanel.shipEnergyGauge = Geyser.Gauge:new({
    x="68%", y=gaugesStart,
    width="30%", height=gaugeHeight,
  }, shipGaugesContainer)
  lotj.infoPanel.shipEnergyGauge.front:setStyleSheet(gaugeFrontStyle("#d4d433", "#cfcf22", "#b2b200", "#949400", "#b2b200"))
  lotj.infoPanel.shipEnergyGauge.back:setStyleSheet(gaugeBackStyle("#3f3f11", "#3f3f07", "#333300", "#222200", "#111100"))
  styleGaugeText(lotj.infoPanel.shipEnergyGauge, shipStatFontSize)
  wireGaugeUpdate(lotj.infoPanel.shipEnergyGauge, "Ship.Info.energy", "Ship.Info.maxEnergy", "", "gmcp.Ship.Info")

  -- Energy icon overlay - 75% of gauge height, positioned on right side
  local energyIconSize = math.ceil(gaugeHeight * 0.75)
  local energyIconStart = math.floor((gaugeHeight - energyIconSize) / 2)
  local energyIcon = Geyser.Label:new({
    x="-20%", y=energyIconStart,
    width=energyIconSize, height=energyIconSize,
  }, lotj.infoPanel.shipEnergyGauge)
  local energyFile = getMudletHomeDir().."/@PKGNAME@/energy_icon.png"
  energyIcon:setStyleSheet([[
    border-image: url(]]..energyFile..[[)
  ]])

  -- Piloting indicator
  local pilotLabel = Geyser.Label:new({
    x="2%", y=gaugesStart,
    width="10%", height=gaugeHeight
  }, shipHudContainer)
  pilotLabel:echo("Pilot:", nil, "r"..shipStatFontSize)

  -- Pilot box - half size, centered vertically
  local boxSize = math.ceil(gaugeHeight * 0.5)
  local boxOffset = gaugesStart + math.floor((gaugeHeight - boxSize) / 2)
  local pilotBox = Geyser.Label:new({
    x="13%", y=boxOffset,
    width=boxSize, height=boxSize
  }, shipHudContainer)

  lotj.setup.registerEventHandler("gmcp.Ship.Info", function()
    if gmcp.Ship and gmcp.Ship.Info.piloting then
      pilotBox:setStyleSheet("background-color: #29efef; border: 2px solid #eeeeee; border-radius: 3px;")
    else
      pilotBox:setStyleSheet("background-color: #073f3f; border: 2px solid #eeeeee; border-radius: 3px;")
    end
  end)

  -- Speed display
  local speedLabel = Geyser.Label:new({
    x="18%", y=gaugesStart,
    width="20%", height=gaugeHeight,
  }, shipHudContainer)

  local function updateSpeed()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.maxSpeed then
      speedLabel:echo("<b>Sp:</b> N/A", nil, "l"..shipStatFontSize)
    else
      local speed = gmcp.Ship.Info.speed or 0
      local maxSpeed = gmcp.Ship.Info.maxSpeed or 0
      speedLabel:echo("<b>Sp:</b> "..speed.."<b>/</b>"..maxSpeed, nil, "l"..shipStatFontSize)
    end
  end
  lotj.setup.registerEventHandler("gmcp.Ship.Info", updateSpeed)

  -- Coordinates
  local coordsInfo = Geyser.Label:new({
    x="40%", y=gaugesStart,
    width="58%", height=gaugeHeight,
  }, shipHudContainer)

  local function updateCoords()
    if not gmcp.Ship or not gmcp.Ship.Info or not gmcp.Ship.Info.posX then
      coordsInfo:echo("<b>Coords:</b> N/A", nil, "l"..shipStatFontSize)
    else
      local shipX = gmcp.Ship.Info.posX or 0
      local shipY = gmcp.Ship.Info.posY or 0
      local shipZ = gmcp.Ship.Info.posZ or 0
      coordsInfo:echo("<b>Coords:</b> "..shipX.." "..shipY.." "..shipZ, nil, "l"..shipStatFontSize)
    end
  end
  lotj.setup.registerEventHandler("gmcp.Ship.Info", updateCoords)

  -- Chaff indicator (overlays on coordinates when active)
  lotj.infoPanel.shipChaffIndicator = Geyser.Label:new({
    x="40%", y=gaugesStart,
    width="58%", height=gaugeHeight,
  }, shipHudContainer)
  lotj.infoPanel.shipChaffIndicator:echo("[Chaff]", "yellow", "c"..shipStatFontSize.."b")
  lotj.infoPanel.shipChaffIndicator:hide()
  lotj.layout.shipOverlay:hide()
end

-- Sets up timers to refresh the space tick counter
function lotj.infoPanel.markSpaceTick()
  local spaceStatFontSize = getFontSize()-1
  for _, timerId in ipairs(lotj.infoPanel.spaceTickTimers or {}) do
    killTimer(timerId)
  end

  -- Update both old and new tick counters for backwards compatibility
  if lotj.infoPanel.spaceTickCounter then
    lotj.infoPanel.spaceTickCounter:show()
  end
  if lotj.infoPanel.shipSpaceTickCounter then
    lotj.infoPanel.shipSpaceTickCounter:show()
  end

  lotj.infoPanel.spaceTickTimers = {}
  for i = 0,20,1 do
    local timerId = tempTimer(i, function()
      if lotj.infoPanel.spaceTickCounter then
        lotj.infoPanel.spaceTickCounter:echo("<b>Tick:</b> "..20-i, nil, "c"..spaceStatFontSize)
      end
      if lotj.infoPanel.shipSpaceTickCounter then
        lotj.infoPanel.shipSpaceTickCounter:echo("<b>Tick:</b> "..20-i, nil, "c"..spaceStatFontSize)
      end
    end)
    table.insert(lotj.infoPanel.spaceTickTimers, timerId)
  end

  -- A few seconds after the next tick should happen, hide the counter.
  -- This will be canceled if we see another tick before then.
  local timerId = tempTimer(23, function()
    if lotj.infoPanel.spaceTickCounter then
      lotj.infoPanel.spaceTickCounter:hide()
    end
    if lotj.infoPanel.shipSpaceTickCounter then
      lotj.infoPanel.shipSpaceTickCounter:hide()
    end
  end)
  table.insert(lotj.infoPanel.spaceTickTimers, timerId)
end

function lotj.infoPanel.markChaff()
  lotj.infoPanel.clearChaff()
  if lotj.infoPanel.chaffIndicator then
    lotj.infoPanel.chaffIndicator:show()
  end
  if lotj.infoPanel.shipChaffIndicator then
    lotj.infoPanel.shipChaffIndicator:show()
  end

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

  if lotj.infoPanel.chaffIndicator then
    lotj.infoPanel.chaffIndicator:hide()
  end
  if lotj.infoPanel.shipChaffIndicator then
    lotj.infoPanel.shipChaffIndicator:hide()
  end
end
