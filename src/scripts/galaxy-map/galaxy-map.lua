lotj = lotj or {}
lotj.galaxyMap = lotj.galaxyMap or {
  data = {
    labelAsPlanets = true,
    systems = {},
    planets = {},
    govToColor = {
      ["Neutral Government"] = "#AAAAAA",
    },
  }
}

local dataFileName = getMudletHomeDir().."/galaxyMap"
registerAnonymousEventHandler("lotjUICreated", function()
  lotj.galaxyMap.container = Geyser.Label:new({
    name = "galaxy",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  }, lotj.layout.upperRightTabData.contents["galaxy"])
  lotj.galaxyMap.container:setBackgroundImage(getMudletHomeDir().."/@PKGNAME@/space.jpg")
  
  lotj.galaxyMap.refreshButton = Geyser.Label:new({
    name = "galaxyMapRefresh",
    x = "20%", y = "35%",
    width = "60%", height = 40,
  }, lotj.galaxyMap.container)
  lotj.galaxyMap.refreshButton:setStyleSheet([[
    background-color: grey;
    border: 1px solid white;
  ]])
  lotj.galaxyMap.refreshButton:echo("Click here to populate this map.", "white", "c14")
  lotj.galaxyMap.refreshButton:setClickCallback(function()
    expandAlias("gmap refresh", false)
  end)
  
  disableTrigger("galaxy-map-refresh")
  if io.exists(dataFileName) then
    table.load(dataFileName, lotj.galaxyMap.data)
    lotj.galaxyMap.log("Loaded map data.")
    lotj.galaxyMap.drawSystems()
  end

  registerAnonymousEventHandler("gmcp.Ship.System.y", lotj.galaxyMap.setShipGalCoords)
end)


function lotj.galaxyMap.log(text)
  cecho("[<cyan>LOTJ Galaxy Map<reset>] "..text.."\n")
end

function lotj.galaxyMap.setShipGalCoords()
  if gmcp.Ship.System.x ~= nil and gmcp.Ship.System.y ~= nil then
    lotj.galaxyMap.currentX = gmcp.Ship.System.x
    lotj.galaxyMap.currentY = gmcp.Ship.System.y
    lotj.galaxyMap.drawSystems()
  end
end

local function container()
  return lotj.galaxyMap.container
end

-- Fire off any showplanet commands we still need to run to load data for all known planets
function lotj.galaxyMap.enqueuePendingRefreshCommands()
  for planet in pairs(gatherPlanetsState.pendingBasic) do
    send("showplanet \""..planet.."\"", false)
    gatherPlanetsState.pendingCommands = gatherPlanetsState.pendingCommands + 1
  end
  for planet in pairs(gatherPlanetsState.pendingResources) do
    send("showplanet \""..planet.."\" resources", false)
    gatherPlanetsState.pendingCommands = gatherPlanetsState.pendingCommands + 1
  end

  -- We didn't have to retry any, so we're done getting info.
  if gatherPlanetsState.pendingCommands == 0 then
    disableTrigger("galaxy-map-refresh")
    return
  end

  echo("\n")
  lotj.galaxyMap.log("Enqueueing "..gatherPlanetsState.pendingCommands.." showplanet commands.")
end

function lotj.galaxyMap.resetData()
  lotj.galaxyMap.data.planets = {}
  lotj.galaxyMap.data.systems = {}
end

local govColorIdx = 1
local govColorList = {}
table.insert(govColorList, "#E69F00")
table.insert(govColorList, "#56B4E9")
table.insert(govColorList, "#009E73")
table.insert(govColorList, "#F0E442")
table.insert(govColorList, "#D55E00")
table.insert(govColorList, "#CC79A7")

function lotj.galaxyMap.recordSystem(name, x, y)
  lotj.galaxyMap.data.systems = lotj.galaxyMap.data.systems or {}
  lotj.galaxyMap.data.systems[name] = {
    name = name,
    planets = {},
    gov = "Neutral Government",
    x = x,
    y = y,
  }
  table.save(dataFileName, lotj.galaxyMap.data)
  
  lotj.galaxyMap.drawSystems()
end

function lotj.galaxyMap.recordPlanet(planetData)
  if not lotj.galaxyMap.data.planets[planetData.name] then
    lotj.galaxyMap.data.planets[planetData.name] = {
      name = planetData.name,
      gov = planetData.gov,
      system = planetData.system,
    }

    local system = lotj.galaxyMap.data.systems[planetData.system]
    if system ~= nil then
      system.gov = planetData.gov
      table.insert(system.planets, planetData.name)
    else
      lotj.galaxyMap.log("Unable to find system "..planetData.system.." for planet "..planetData.name)
    end

    if lotj.galaxyMap.data.govToColor[planetData.gov] == nil then
      govColorIdx = govColorIdx+1
      lotj.galaxyMap.data.govToColor[planetData.gov] = govColorList[govColorIdx]
    end
  end

  if planetData.coords ~= nil then
    lotj.galaxyMap.data.planets[planetData.name].coords = planetData.coords
  end
  if planetData.freeport ~= nil then
    lotj.galaxyMap.data.planets[planetData.name].freeport = planetData.freeport
  end
  if planetData.taxRate ~= nil then
    lotj.galaxyMap.data.planets[planetData.name].taxRate = planetData.taxRate
  end
  if planetData.resources ~= nil then
    lotj.galaxyMap.data.planets[planetData.name].resources = planetData.resources
  end

  table.save(dataFileName, lotj.galaxyMap.data)

  lotj.galaxyMap.drawSystems()
end

local systemPointSize = 14
local function stylePoint(point, gov, currentSystem)
  local backgroundColor = lotj.galaxyMap.data.govToColor[gov] or "#AAAAAA"
  local borderStyle = ""
  if currentSystem then
    borderStyle = "border: 2px solid red;"
  end
  point:setStyleSheet([[
    border-radius: ]]..math.floor(systemPointSize/2)..[[px;
    background-color: ]]..backgroundColor..[[;
    ]]..borderStyle..[[
  ]])
end

local function systemDisplayName(system)
  if lotj.galaxyMap.data.labelAsPlanets and #(system.planets or {}) > 0 then
    local labelString = ""
    for _, planet in ipairs(system.planets) do
      if #labelString > 0 then
        labelString = labelString..", "
      end
      labelString = labelString..planet
    end
    return labelString
  else
    -- Cut off common extra words from the system name to keep labels short
    local labelString = system.name
    labelString = string.gsub(labelString, " System$", "")
    labelString = string.gsub(labelString, " Sector$", "")
    return labelString
  end
end

function lotj.galaxyMap.drawSystems()
  local minX, _, _, maxY = lotj.galaxyMap.coordRange()
  local xOffset, yOffset, pxPerCoord = lotj.galaxyMap.calculateSizing()
  
  lotj.galaxyMap.systemPoints = lotj.galaxyMap.systemPoints or {}
  for _, point in pairs(lotj.galaxyMap.systemPoints) do
    point:hide()
  end

  lotj.galaxyMap.systemLabels = lotj.galaxyMap.systemLabels or {}
  for _, label in pairs(lotj.galaxyMap.systemLabels) do
    label:hide()
  end

  
  local foundCurrentLocation = false
  local systemsToDraw = {}
  for _, system in pairs(lotj.galaxyMap.data.systems) do
    table.insert(systemsToDraw, system)
    if system.x == lotj.galaxyMap.currentX and system.y == lotj.galaxyMap.currentY then
      foundCurrentLocation = true
    end
  end
  if not foundCurrentLocation and lotj.galaxyMap.currentX and lotj.galaxyMap.currentY then
    table.insert(systemsToDraw, {
      name = "Current",
      x = lotj.galaxyMap.currentX,
      y = lotj.galaxyMap.currentY
    })
  end

  -- Hide or show the refresh button accordingly, based on whether we have any data.
  if #systemsToDraw > 0 then
    lotj.galaxyMap.refreshButton:hide()
  else
    lotj.galaxyMap.refreshButton:show()
  end
  
  for _, system in ipairs(systemsToDraw) do
    local point = lotj.galaxyMap.systemPoints[system.name]
    if point == nil then
      point = Geyser.Label:new({width=systemPointSize, height=systemPointSize}, container())
      stylePoint(point, system.gov, false)
      lotj.galaxyMap.systemPoints[system.name] = point
    else
      point:show()
    end

    local label = lotj.galaxyMap.systemLabels[system.name]
    if label == nil then
      label = Geyser.Label:new({
        height = 16, width = 100,
        fillBg = 0,
      }, container())
      
      lotj.galaxyMap.systemLabels[system.name] = label
    else
      label:show()
    end
    label:echo(systemDisplayName(system), "white", "12c")
    
    local sysX = math.floor(xOffset + (system.x-minX)*pxPerCoord - systemPointSize/2 + 0.5)
    local sysY = math.floor(yOffset + (maxY-system.y)*pxPerCoord - systemPointSize/2 + 0.5)
    point:move(sysX, sysY)
    if system.x == lotj.galaxyMap.currentX and system.y == lotj.galaxyMap.currentY then
      stylePoint(point, system.gov, true)
    else
      stylePoint(point, system.gov, false)
    end
    
    label:move(math.max(sysX-45, 0), sysY+systemPointSize)
  end
end

-- Returns X starting point, Y starting point, and pixels per coordinate
function lotj.galaxyMap.calculateSizing()
  local minX, maxX, minY, maxY = lotj.galaxyMap.coordRange()
  local xRange = maxX-minX
  local yRange = maxY-minY
  local contWidth = container():get_width()
  local contHeight = container():get_height()
  
  -- Determine whether the map would be limited by height or width first.
  local mapWidth = nil
  local mapHeight = nil
  local pxPerCoord = nil
  local pxHeightIfLimitedByWidth = (contWidth/xRange)*yRange
  local pxWidthIfLimitedByHeight = (contHeight/yRange)*xRange
  if pxHeightIfLimitedByWidth <= contHeight then
    -- Width was the limiting factor, so use it to determine sizing
    mapWidth = contWidth
    mapHeight = pxHeightIfLimitedByWidth
    pxPerCoord = contWidth/xRange
  elseif pxWidthIfLimitedByHeight <= contWidth then
    -- Width was the limiting factor, so use it to determine sizing
    mapWidth = pxWidthIfLimitedByHeight
    mapHeight = contHeight
    pxPerCoord = contHeight/yRange
  else
    echo("Unable to determine appropriate galaxy map dimensions. This is a script bug.\n")
  end
  
  local mapAnchorX = (contWidth-mapWidth)/2
  local mapAnchorY = (contHeight-mapHeight)/2
  
  return mapAnchorX, mapAnchorY, pxPerCoord
end

function lotj.galaxyMap.coordRange()
  local minX = 0
  local maxX = 0
  local minY = 0
  local maxY = 0
  
  for _, system in pairs(lotj.galaxyMap.data.systems) do
    if minX > system.x then
      minX = system.x
    end
    if maxX < system.x then
      maxX = system.x
    end
    if minY > system.y then
      minY = system.y
    end
    if maxY < system.y then
      maxY = system.y
    end
  end
  
  -- Pad all values by 10 to ensure points are displayed reasonably.
  return minX-10, maxX+10, minY-10, maxY+10
end
