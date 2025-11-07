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
function lotj.galaxyMap.setup()
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

  -- Add button for manually adding systems
  local buttonSize = getFontSize() * 2.7
  lotj.galaxyMap.addButton = Geyser.Label:new({
    name = "galaxyMapAddSystem",
    x = -buttonSize - 5, y = 5,
    width = buttonSize, height = buttonSize,
  }, lotj.galaxyMap.container)
  lotj.galaxyMap.addButton:setStyleSheet([[
    QLabel {
      background-color: rgba(0, 170, 170, 180);
      border: 2px solid #00aaaa;
      border-radius: ]]..math.floor(buttonSize/2)..[[px;
      font-weight: bold;
    }
    QLabel:hover {
      background-color: rgba(0, 200, 200, 220);
      border: 2px solid #00dddd;
    }
  ]])
  lotj.galaxyMap.addButton:echo("+", "white", "c20")
  lotj.galaxyMap.addButton:setClickCallback("lotj.galaxyMap.showAddSystemDialog")

  disableTrigger("galaxy-map-refresh")
  if io.exists(dataFileName) then
    table.load(dataFileName, lotj.galaxyMap.data)
    lotj.galaxyMap.log("Loaded map data.")
    lotj.galaxyMap.drawSystems()
  end

  lotj.setup.registerEventHandler("gmcp.Ship.System", lotj.galaxyMap.setShipGalCoords)
  -- This seems necessary when recreating the UI after upgrading the package.
  lotj.galaxyMap.container:raiseAll()
end


function lotj.galaxyMap.log(text)
  cecho("[<cyan>LOTJ Galaxy Map<reset>] "..text.."\n")
end

function lotj.galaxyMap.setShipGalCoords()
  if not gmcp.Ship then return end
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
  -- Preserve manually added systems
  local manualSystems = {}
  for name, system in pairs(lotj.galaxyMap.data.systems or {}) do
    if system.manual then
      manualSystems[name] = system
    end
  end

  lotj.galaxyMap.data.planets = {}
  lotj.galaxyMap.data.systems = manualSystems
end

local govColorIdx = 1
local govColorList = {}
table.insert(govColorList, "#E69F00")
table.insert(govColorList, "#56B4E9")
table.insert(govColorList, "#009E73")
table.insert(govColorList, "#F0E442")
table.insert(govColorList, "#D55E00")
table.insert(govColorList, "#CC79A7")

function lotj.galaxyMap.recordSystem(name, x, y, manual)
  lotj.galaxyMap.data.systems = lotj.galaxyMap.data.systems or {}
  lotj.galaxyMap.data.systems[name] = {
    name = name,
    planets = {},
    gov = "Neutral Government",
    x = x,
    y = y,
    manual = manual or false,
  }
  table.save(dataFileName, lotj.galaxyMap.data)

  lotj.galaxyMap.drawSystems()
end

-- Add a manual system with user-friendly feedback
function lotj.galaxyMap.addManualSystem(name, x, y)
  if not name or name == "" then
    lotj.galaxyMap.log("<red>System name is required.")
    return false
  end

  if not x or not y then
    lotj.galaxyMap.log("<red>Coordinates (x, y) are required.")
    return false
  end

  x = tonumber(x)
  y = tonumber(y)

  if not x or not y then
    lotj.galaxyMap.log("<red>Coordinates must be numbers.")
    return false
  end

  if lotj.galaxyMap.data.systems[name] then
    lotj.galaxyMap.log("<yellow>System '"..name.."' already exists. Updating coordinates.")
  end

  lotj.galaxyMap.recordSystem(name, x, y, true)
  lotj.galaxyMap.log("<green>Added manual system '"..name.."' at ("..x..", "..y..")")

  return true
end

-- Show help text for gmap commands
function lotj.galaxyMap.showHelp()
  lotj.galaxyMap.log("<cyan>Galaxy Map Commands:")
  echo("\n")
  cecho("  <yellow>gmap refresh<reset>\n")
  cecho("    Refresh the galaxy map by gathering planet and system data from in-game.\n")
  cecho("    <red>Notice:<reset> This will refresh all systems except manually added ones.\n")
  echo("\n")
  cecho("  <yellow>gmap add <system name> <x> <y><reset>\n")
  cecho("    Manually add a system to the galaxy map.\n")
  cecho("    Example: <yellow>gmap add \"Unknown System\" -50 75<reset>\n")
  echo("\n")
  cecho("  <yellow>gmap list<reset>\n")
  cecho("    List all manually added systems.\n")
  echo("\n")
  cecho("  <yellow>gmap remove <system name><reset>\n")
  cecho("    Remove a manually added system from the map.\n")
  cecho("    Example: <yellow>gmap remove \"Unknown System\"<reset>\n")
  echo("\n")
end

-- Show dialog to add a system with UI inputs
function lotj.galaxyMap.showAddSystemDialog()
  -- Close any existing dialog
  if lotj.galaxyMap.addDialog then
    lotj.galaxyMap.closeAddSystemDialog()
  end

  -- Create semi-transparent overlay
  lotj.galaxyMap.addDialogOverlay = Geyser.Label:new({
    name = "galaxyMapAddDialogOverlay",
    x = 0, y = 0,
    width = "100%", height = "100%",
  })
  lotj.galaxyMap.addDialogOverlay:setStyleSheet([[
    background-color: rgba(0, 0, 0, 150);
  ]])
  lotj.galaxyMap.addDialogOverlay:raise()

  -- Create dialog box
  local dialogWidth = 400
  local dialogHeight = 240
  local mainWidth, mainHeight = getMainWindowSize()

  lotj.galaxyMap.addDialog = Geyser.Label:new({
    name = "galaxyMapAddDialog",
    x = (mainWidth - dialogWidth) / 2,
    y = (mainHeight - dialogHeight) / 2,
    width = dialogWidth, height = dialogHeight,
  }, lotj.galaxyMap.addDialogOverlay)
  lotj.galaxyMap.addDialog:setStyleSheet([[
    background-color: #1a1a1a;
    border: 2px solid #00aaaa;
    border-radius: 5px;
  ]])

  -- Title
  local titleLabel = Geyser.Label:new({
    x = "5%", y = 10,
    width = "90%", height = 30,
  }, lotj.galaxyMap.addDialog)
  titleLabel:echo("<center><b>Add System</b></center>", "white", "c18")

  -- Input row 1: System Name
  local inputHeight = 35
  local row1Y = 50
  local nameLabel = Geyser.Label:new({
    x = 20, y = row1Y,
    width = 120, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  nameLabel:echo("System Name:", "white", "c12")

  lotj.galaxyMap.addDialog.nameInput = Geyser.CommandLine:new({
    x = 145, y = row1Y,
    width = 235, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  lotj.galaxyMap.addDialog.nameInput:setStyleSheet([[
    background-color: #2a2a2a;
    border: 1px solid #555555;
    color: white;
    padding: 4px;
  ]])

  -- Input row 2: X Coordinate
  local row2Y = 95
  local xLabel = Geyser.Label:new({
    x = 20, y = row2Y,
    width = 120, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  xLabel:echo("X Coordinate:", "white", "c12")

  lotj.galaxyMap.addDialog.xInput = Geyser.CommandLine:new({
    x = 145, y = row2Y,
    width = 235, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  lotj.galaxyMap.addDialog.xInput:setStyleSheet([[
    background-color: #2a2a2a;
    border: 1px solid #555555;
    color: white;
    padding: 4px;
  ]])

  -- Input row 3: Y Coordinate
  local row3Y = 140
  local yLabel = Geyser.Label:new({
    x = 20, y = row3Y,
    width = 120, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  yLabel:echo("Y Coordinate:", "white", "c12")

  lotj.galaxyMap.addDialog.yInput = Geyser.CommandLine:new({
    x = 145, y = row3Y,
    width = 235, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  lotj.galaxyMap.addDialog.yInput:setStyleSheet([[
    background-color: #2a2a2a;
    border: 1px solid #555555;
    color: white;
    padding: 4px;
  ]])

  -- Buttons at bottom
  local buttonY = 180
  local buttonWidth = 120
  local buttonHeight = 35

  -- Cancel button
  local cancelButton = Geyser.Label:new({
    x = 40, y = buttonY,
    width = buttonWidth, height = buttonHeight,
  }, lotj.galaxyMap.addDialog)
  cancelButton:setStyleSheet([[
    background-color: #444444;
    border: 1px solid #666666;
    border-radius: 3px;
  ]])
  cancelButton:echo("<center><b>Cancel</b></center>", "white", "c14")
  cancelButton:setClickCallback("lotj.galaxyMap.closeAddSystemDialog")

  -- Add System button
  local addButton = Geyser.Label:new({
    x = 240, y = buttonY,
    width = buttonWidth, height = buttonHeight,
  }, lotj.galaxyMap.addDialog)
  addButton:setStyleSheet([[
    background-color: #006666;
    border: 1px solid #00aaaa;
    border-radius: 3px;
  ]])
  addButton:echo("<center><b>Add System</b></center>", "white", "c14")
  addButton:setClickCallback("lotj.galaxyMap.handleAddSystemSubmit")
  lotj.galaxyMap.addDialog:raiseAll()
end

-- Close the add system dialog
function lotj.galaxyMap.closeAddSystemDialog()
  if lotj.galaxyMap.addDialog then
    lotj.galaxyMap.addDialog:hide()
    lotj.galaxyMap.addDialog = nil
  end
  if lotj.galaxyMap.addDialogOverlay then
    lotj.galaxyMap.addDialogOverlay:hide()
    lotj.galaxyMap.addDialogOverlay = nil
  end
end

-- Handle submit from add system dialog
function lotj.galaxyMap.handleAddSystemSubmit()
  local name = lotj.galaxyMap.addDialog.nameInput:getText()
  local xStr = lotj.galaxyMap.addDialog.xInput:getText()
  local yStr = lotj.galaxyMap.addDialog.yInput:getText()

  -- Close dialog first
  lotj.galaxyMap.closeAddSystemDialog()

  -- Validate and add the system
  if not name or name == "" then
    lotj.galaxyMap.log("<red>System name is required.")
    return
  end

  if not xStr or xStr == "" or not yStr or yStr == "" then
    lotj.galaxyMap.log("<red>Both X and Y coordinates are required.")
    return
  end

  local x = tonumber(xStr)
  local y = tonumber(yStr)

  if not x or not y then
    lotj.galaxyMap.log("<red>Coordinates must be valid numbers.")
    return
  end

  -- Add the system
  lotj.galaxyMap.addManualSystem(name, x, y)
end

-- List all manually added systems
function lotj.galaxyMap.listManualSystems()
  local manualSystems = {}
  for name, system in pairs(lotj.galaxyMap.data.systems or {}) do
    if system.manual then
      table.insert(manualSystems, system)
    end
  end

  if #manualSystems == 0 then
    lotj.galaxyMap.log("No manually added systems found.")
    return
  end

  lotj.galaxyMap.log("Manually added systems:")
  for _, system in ipairs(manualSystems) do
    cecho("  <yellow>"..system.name.."<reset> at (<cyan>"..system.x..", "..system.y.."<reset>)\n")
  end
end

-- Remove a manually added system
function lotj.galaxyMap.removeManualSystem(name)
  if not lotj.galaxyMap.data.systems[name] then
    lotj.galaxyMap.log("<red>System '"..name.."' not found.")
    return false
  end

  if not lotj.galaxyMap.data.systems[name].manual then
    lotj.galaxyMap.log("<red>System '"..name.."' is not a manually added system. Only manual systems can be removed.")
    return false
  end

  lotj.galaxyMap.data.systems[name] = nil
  table.save(dataFileName, lotj.galaxyMap.data)
  lotj.galaxyMap.drawSystems()

  lotj.galaxyMap.log("<green>Removed manual system '"..name.."'")
  return true
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

local systemPointSize = math.ceil(getFontSize()*1.1)
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

    -- Add right-click menu for manually added systems
    if system.manual then
      point:createRightClickMenu({
        MenuItems = {"Delete System"}
      })
      point:setMenuAction("Delete System", function()
        point:hideMenuLabel("Delete System")
        lotj.galaxyMap.removeManualSystem(system.name)
      end)
    end

    local label = lotj.galaxyMap.systemLabels[system.name]
    if label == nil then
      label = Geyser.Label:new({
        height = math.ceil(getFontSize()*1.33), width = 100,
        fillBg = 0,
      }, container())
      
      lotj.galaxyMap.systemLabels[system.name] = label
    else
      label:show()
    end
    label:echo(systemDisplayName(system), "white", (getFontSize()-1).."c")
    
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
