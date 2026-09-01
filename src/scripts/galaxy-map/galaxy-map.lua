--Overriding a Geyser function to work around a stupid problem
function doNestLeave(label)
  if Geyser.Label.closeAllTimer then
    killTimer(Geyser.Label.closeAllTimer)
  end
  Geyser.Label.closeAllTimer = tempTimer(.5, function() closeAllLevels(label) end)
end

lotj = lotj or {}
lotj.galaxyMap = lotj.galaxyMap or {
  systems = {},
  recorded = {},
  governments = {},
  govToColor = {
    ["A Neutral Government"] = "#AAAAAA",
  },
  -- Map specific planets to specific images
  planetToImageMap = {
    ["Kashyyyk"] = "kashyyyk.png",
    ["Coruscant"] = "coruscant.png",
    ["Corellia"] = "corellia.png",
    ["Mon Cala"] = "moncalamari.png",
    ["Ithor"] = "ithor.png",
    ["Alderaan"] = "alderaan.png",
    ["Arkania"] = "arkania.png",
    ["Bespin"] = "bespin.png",
    ["Nal Hutta"] = "nalhutta.png",
    ["Ruusan"] = "ruusan.png",
    ["Korriban"] = "korriban.png",
    ["Wroona"] = "wroona.png",
    ["Ryloth"] = "ryloth.png",
    ["Lorrd"] = "lorrd.png",
    ["Tatooine"] = "tatooine.png",
    ["Dromund Kaas"] = "dromundkaas.png",
    ["Ord Mantell"] = "ordmantell.png",
    ["Nim Drovis"] = "nimdrovis.png",
    ["Mustafar"] = "mustafar.png",
    ["Dantooine"] = "dantooine.png",
    ["Felucia"] = "felucia.png",
    ["Hapes"] = "hapes.png",
    ["Kamino"] = "kamino.png",
    ["Manaan"] = "manaan.png",
    ["Naboo"] = "naboo.png",
    ["Mandalore"] = "mandalore.png"
    -- Add more planet-specific mappings here as needed
    -- ["Planet Name"] = "planetX.png",
  }
}

local manualDataFileName = getMudletHomeDir().."/galaxyMap_manual"
local gmcpDataFileName = getMudletHomeDir().."/galaxyMap_gmcp"

-- Load recorded data
if io.exists(manualDataFileName) then
  table.load(manualDataFileName, lotj.galaxyMap.recorded)
end

-- Right-click menu configuration
local rightClickMenuConfig = {
  Style = "Dark",
  MenuWidth = 30 * calcFontSize(getFontSize(), getFont()),
  MenuFormat = "c"..tostring(getFontSize()),
  MenuStyle = [[
    QLabel::hover {
      background-color: rgba(0,180,180,100%);
      color: white;
      font-family: ]]..getFont()..[[;
    }
    QLabel::!hover {
      color: cyan;
      background-color: rgba(20,40,50,100%);
      font-family: ]]..getFont()..[[;
    }
  ]]
}

function lotj.galaxyMap.setup()
  lotj.galaxyMap.container = Geyser.Label:new({
    name = "galaxy",
    x = 0, y = 0,
    width = "100%",
    height = "100%",
  }, lotj.layout.upperRightTabData.contents["galaxy"])
  --lotj.galaxyMap.container:setBackgroundImage(getMudletHomeDir().."/@PKGNAME@/space.jpg")
  local file = getMudletHomeDir().."/@PKGNAME@/space.jpg"
  lotj.galaxyMap.container:setStyleSheet([[
    border-image: url(]]..file..[[)
  ]])

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
  lotj.galaxyMap.addButton:setCursor("PointingHand")
  lotj.galaxyMap.addButton:echo("+", "white", "c20")
  lotj.galaxyMap.addButton:setClickCallback(lotj.galaxyMap.showAddSystemDialog)

  lotj.setup.registerEventHandler("gmcp.Ship.System", lotj.galaxyMap.setShipGalCoords)
  lotj.setup.registerEventHandler("gmcp.Room.Info", lotj.galaxyMap.setCurrentPlanet)
  lotj.setup.registerEventHandler("gmcp.Galaxy.Systems", lotj.galaxyMap.drawSystems)
  -- This seems necessary when recreating the UI after upgrading the package.
  lotj.galaxyMap.container:raiseAll()
end

function lotj.galaxyMap.log(text)
  cecho("[<cyan>LOTJ Galaxy Map<reset>] "..text.."\n")
end

function lotj.galaxyMap.setShipGalCoords()
  if not gmcp.Ship then return end
  if not gmcp.Ship.System then return end
  if gmcp.Ship.System.x ~= nil and gmcp.Ship.System.y ~= nil then
    lotj.galaxyMap.currentX = gmcp.Ship.System.x
    lotj.galaxyMap.currentY = gmcp.Ship.System.y
    lotj.galaxyMap.drawSystems()
  end
end

function lotj.galaxyMap.setCurrentPlanet()
  if not gmcp.Room and gmcp.Room.Info then return end
  if lotj.galaxyMap.currentPlanet ~= gmcp.Room.Info.planet then
    lotj.galaxyMap.currentPlanet = gmcp.Room.Info.planet
    lotj.galaxyMap.currentX = nil
    lotj.galaxyMap.currentY = nil
    lotj.galaxyMap.drawSystems()
  end
end

local function container()
  return lotj.galaxyMap.container
end

local govColorList = {}
table.insert(govColorList, "#56B4E9")
table.insert(govColorList, "#009E73")
table.insert(govColorList, "#D55E00")
table.insert(govColorList, "#E69F00")
table.insert(govColorList, "#F0E442")
table.insert(govColorList, "#CC79A7")

function lotj.galaxyMap.recordSystem(name, x, y)
  lotj.galaxyMap.recorded = lotj.galaxyMap.recorded or {}
  lotj.galaxyMap.recorded[name] = {
    planet = {
      government = "A Neutral Government",
      name = name
    },
    planets = {
      {
        government = "A Neutral Government",
        name = name
      },
    },
    name = name,
    x = x,
    y = y,
  }

  table.save(manualDataFileName, lotj.galaxyMap.recorded)
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

  if lotj.galaxyMap.recorded[name] or lotj.galaxyMap.systems[name] then
    lotj.galaxyMap.log("<yellow>System '"..name.."' already exists. Updating coordinates.")
  end

  lotj.galaxyMap.recordSystem(name, x, y)
  lotj.galaxyMap.drawSystems()
  lotj.galaxyMap.log("<reset>Added system '<green>"..name.."<reset>' at (<green>"..x..", "..y.."<reset>)")

  return true
end

-- Show help text for gmap commands
function lotj.galaxyMap.showHelp()
  lotj.galaxyMap.log("<cyan>Galaxy Map Commands:")
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
  cecho("  <yellow>gmap clear<reset>\n")
  cecho("    Remove all manually added systems from the map.\n")
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
  lotj.galaxyMap.addDialogOverlay:setClickCallback(lotj.galaxyMap.closeAddSystemDialog)

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
    name = "lotj_galaxyMap.titleLabel",
    x = "5%", y = 10,
    width = "90%", height = 30,
  }, lotj.galaxyMap.addDialog)
  titleLabel:setStyleSheet(f"background-color: transparent; font-family: {getFont()}")
  titleLabel:echo("<center><b>Add System</b></center>", "white", "c18")

  -- Input row 1: System Name
  local inputHeight = 35
  local row1Y = 50
  local nameLabel = Geyser.Label:new({
    name = "lotj_galaxyMap.nameLabel",
    x = 20, y = row1Y,
    width = 120, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  nameLabel:setStyleSheet(f"background-color: transparent; font-family: {getFont()}")
  nameLabel:echo("System Name:", "white", "c12")

  lotj.galaxyMap.addDialog.nameInput = Geyser.CommandLine:new({
    name = "lotj_galaxyMap.nameInput",
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
    name = "lotj_galaxyMap.xLabel",
    x = 20, y = row2Y,
    width = 120, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  xLabel:setStyleSheet(f"background-color: transparent; font-family: {getFont()}")
  xLabel:echo("X Coordinate:", "white", "c12")

  lotj.galaxyMap.addDialog.xInput = Geyser.CommandLine:new({
    name = "lotj_galaxyMap.xInput",
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
    name = "lotj_galaxyMap.yLabel",
    x = 20, y = row3Y,
    width = 120, height = inputHeight,
  }, lotj.galaxyMap.addDialog)
  yLabel:setStyleSheet(f"background-color: transparent; font-family: {getFont()}")
  yLabel:echo("Y Coordinate:", "white", "c12")

  lotj.galaxyMap.addDialog.yInput = Geyser.CommandLine:new({
    name = "lotj_galaxyMap.yInput",
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
    name = "lotj_galaxyMap.cancelButton",
    x = 40, y = buttonY,
    width = buttonWidth, height = buttonHeight,
  }, lotj.galaxyMap.addDialog)
  cancelButton:setStyleSheet([[
    background-color: #444444;
    border: 1px solid #666666;
    border-radius: 3px;
    font-family: ]]..getFont()..[[;
  ]])
  cancelButton:echo("<center><b>Cancel</b></center>", "white", "c14")
  cancelButton:setCursor("PointingHand")
  cancelButton:setClickCallback(lotj.galaxyMap.closeAddSystemDialog)

  -- Add System button
  local addButton = Geyser.Label:new({
    name = "lotj_galaxyMap.addButton",
    x = 240, y = buttonY,
    width = buttonWidth, height = buttonHeight,
  }, lotj.galaxyMap.addDialog)
  addButton:setStyleSheet([[
    QLabel {
      background-color: #006666;
      border: 1px solid #00aaaa;
      border-radius: 3px;
      font-family: ]]..getFont()..[[;
    }
    QLabel:hover {
      background-color: rgba(0, 200, 200, 220);
      border: 2px solid #00dddd;
    }
  ]])
  addButton:echo("<center><b>Add System</b></center>", "white", "c14")
  addButton:setCursor("PointingHand")
  addButton:setClickCallback(lotj.galaxyMap.handleAddSystemSubmit)
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
  local manualSystems = lotj.galaxyMap.recorded

  if next(manualSystems) == nil then
    lotj.galaxyMap.log("No manually added systems found.")
    return
  end

  lotj.galaxyMap.log("Manually added systems:")
  for systemName, system in pairs(manualSystems) do
    cecho("  <yellow>"..systemName.."<reset> at (<cyan>"..system.x..", "..system.y.."<reset>)\n")
  end
end

-- Remove all manually added systems
function lotj.galaxyMap.clearManualSystems()
  local count = #lotj.galaxyMap.recorded
  if count == 0 then
    lotj.galaxyMap.log("No manually added systems to remove.")
    return
  end
  for name, system in pairs(lotj.galaxyMap.recorded or {}) do
    lotj.galaxyMap.recorded[name] = nil
  end
  table.save(manualDataFileName, lotj.galaxyMap.recorded)
  lotj.galaxyMap.drawSystems()
  lotj.galaxyMap.log("<reset>Removed <red>" .. count .. " <reset>manually added system" .. (count == 1 and "" or "s") .. ".")
end

-- Remove a manually added system
function lotj.galaxyMap.removeManualSystem(name)
  if not lotj.galaxyMap.recorded[name] then
    lotj.galaxyMap.log("<red>System '"..name.."' not found.")
    return false
  end

  lotj.galaxyMap.recorded[name] = nil
  table.save(manualDataFileName, lotj.galaxyMap.recorded)
  lotj.galaxyMap.drawSystems()

  lotj.galaxyMap.log("<reset>Removed system '<red>"..name.."<reset>'")
  return true
end

local systemPointSize = 32  -- Size of planet images
local function stylePoint(point, gov, currentSystem, planetImage, pointSize, manual, label)
  -- If we have a planet image, use it with hover effects
  if planetImage then
    local borderStyle = ""
    if currentSystem then
      borderStyle = "border: 2px solid red; border-radius: 18px;"
    else
      borderStyle = "border: none;"
    end

    point:setStyleSheet([[
      background-repeat: no-repeat;
      background-position: center;
      background-color: transparent;
      ]]..borderStyle..[[
    ]])

    if currentSystem then
      point:adjustSize()
    end

    point:setBackgroundImage(planetImage)

    -- Add hover effects for custom planets
    if planetImage:match("%.png$") then
      local hoverImage = planetImage:gsub("%.png$", "_hover.gif")

      point:setOnEnter(function()
        point:setMovie(hoverImage)
        if manual then
          label:show()
          label:raiseAll()
        end
      end)

      point:setOnLeave(function()
        point:setBackgroundImage(planetImage)
        if manual then
          label:hide()
        end
      end)
    end
  else
    -- Fall back to old colored circular dot rendering
    local backgroundColor = lotj.galaxyMap.govToColor[gov] or "#AAAAAA"
    local borderStyle = ""
    if currentSystem then
      borderStyle = "border: 2px solid red;"
    else
      borderStyle = "border: 1px solid "..backgroundColor..";"
    end

    point:setStyleSheet([[
      border-radius: ]]..math.floor(pointSize/2)..[[px;
      background-color: ]]..backgroundColor..[[;
      ]]..borderStyle..[[
    ]])
  end
end

function lotj.galaxyMap.getSystemName(systemName, system)
  for planetName, planet in pairs(system) do
    if type(planet) == "table" and planet.government then
      system.name = planetName
      return planet
    end
  end
  system.name = systemName:match("[%w']+")
  return { government = "A Neutral Government"}
end

function lotj.galaxyMap.getSystemPlanets(system)
  local planets = {}
  for planetName, planet in pairs(system) do
    if type(planet) == "table" and planet.government then
      planet.name = planetName
      table.insert(planets, table.deepcopy(planet))
    end
  end
  return planets
end

-- TODO:
-- Even if there is no GMCP data, we should still draw the player's location
function lotj.galaxyMap.drawSystems()
  if lotj.layout and lotj.layout.upperRightTabData and lotj.layout.upperRightTabData.selectedTab ~= "galaxy" then
    lotj.galaxyMap.pendingDraw = true
    return
  end
  lotj.galaxyMap.pendingDraw = false

  local gmcp_data = gmcpVarByPath("Galaxy.Systems") or {}
  if next(gmcp_data) == nil then
    if not io.exists(gmcpDataFileName) then
      return
    end
    table.load(gmcpDataFileName, gmcp_data)
  else
    table.save(gmcpDataFileName, gmcp_data)
  end

  -- Create a System -> Planets hierarchy
  lotj.galaxyMap.systems = {}
  lotj.galaxyMap.governments = {}
  lotj.galaxyMap.govToColor = {}

  for systemName, system in pairs(gmcp_data) do
    system.planets = lotj.galaxyMap.getSystemPlanets(system)
    system.planet = lotj.galaxyMap.getSystemName(systemName, system)
    lotj.galaxyMap.systems[systemName] = system
    lotj.galaxyMap.governments[system.planet.government] = true
  end

  -- Establish government colors
  lotj.galaxyMap.govToColor["A Neutral Government"] = "#AAAAAA"
  local flag = 1
  for gov, _ in pairs(lotj.galaxyMap.governments) do
    if gov ~= "A Neutral Government" then
      lotj.galaxyMap.govToColor[gov] = govColorList[flag]
      flag = flag + 1
    end
  end

  local minX, _, _, maxY = lotj.galaxyMap.coordRange()
  local xOffset, yOffset, pxPerCoord, pxPerCoordX = lotj.galaxyMap.calculateSizing()

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

  -- Add systems from gmcp to systems to draw
  for _, system in pairs(lotj.galaxyMap.systems) do
    -- Ignore special systems placed at nonsensical locations
    if not lotj.galaxyMap.outOfBounds(system) then
      table.insert(systemsToDraw, table.deepcopy(system))
      if system.x == lotj.galaxyMap.currentX and system.y == lotj.galaxyMap.currentY then
        foundCurrentLocation = true
      end
    end
  end

  -- Add the recorded systems to systems to draw
  for _, system in pairs(lotj.galaxyMap.recorded) do
    system.manual = true
    table.insert(systemsToDraw, table.deepcopy(system))
    if system.x == lotj.galaxyMap.currentX and system.y == lotj.galaxyMap.currentY then
      foundCurrentLocation = true
    end
  end

  -- If our current location is not in any known system, add it as a custom point
  if not foundCurrentLocation and lotj.galaxyMap.currentX and lotj.galaxyMap.currentY then
    table.insert(systemsToDraw, {
      planet = {
        ["Current"] = {
          government = "A Neutral Government",
          name = "Current"
        },
      },
      planets = {},
      name = "Current",
      manual = true,
      x = lotj.galaxyMap.currentX,
      y = lotj.galaxyMap.currentY
    })
  end

  -- Initialize planet image assignments if needed
  lotj.galaxyMap.planetImages = lotj.galaxyMap.planetImages or {}

  for _, system in ipairs(systemsToDraw) do
    -- Check if this system should have a planet image
    if not lotj.galaxyMap.planetImages[system.name] then
      local mappedImage = nil

      -- First check if the system name itself matches a planet mapping
      if lotj.galaxyMap.planetToImageMap[system.name] then
        mappedImage = getMudletHomeDir().."/@PKGNAME@/"..lotj.galaxyMap.planetToImageMap[system.name]
      end

      -- Store mapped image if found
      if mappedImage then
        lotj.galaxyMap.planetImages[system.name] = mappedImage
      end
    end
    local planetImage = lotj.galaxyMap.planetImages[system.name]

    -- Use smaller size for systems without images, larger for planet images
    local pointSize = planetImage and systemPointSize or math.ceil(getFontSize()*1.1)

    local point = lotj.galaxyMap.systemPoints[system.name]
    if point == nil then
      point = Geyser.Label:new({name="galaxyMap_"..system.name, width=pointSize, height=pointSize}, container())
      stylePoint(point, system.planet.government, false, planetImage, pointSize)
      lotj.galaxyMap.systemPoints[system.name] = point
    else
      point:show()
    end
    point:raise()

    -- Build menu items based on system properties
    local menuItems = {"Calculate Route"}

    -- Add planet info options if system has planets
    if system.planets and #system.planets > 0  and system.manual ~= true then
      for _, planet in ipairs(system.planets) do
        table.insert(menuItems, "Show "..planet.name.." Info")
        table.insert(menuItems, "Show "..planet.name.." Resources")
        table.insert(menuItems, "Show "..planet.name.." AI")
      end
    end

    -- Add delete option for manual systems
    if system.manual then
      table.insert(menuItems, "Delete System")
    end

    -- Create right-click menu using config
    local menuConfig = {
      MenuItems = menuItems,
      Style = rightClickMenuConfig.Style,
      MenuWidth = rightClickMenuConfig.MenuWidth,
      MenuFormat = rightClickMenuConfig.MenuFormat,
      MenuStyle = rightClickMenuConfig.MenuStyle
    }
    point:createRightClickMenu(menuConfig)

    -- Set action for Calculate Route
    point:setMenuAction("Calculate Route", function()
      send("calculate '"..system.x.." "..system.y.."'")
      --closeAllLevels(point)
      closeAllLevels(point.rightClickMenu)
    end)

    -- Set actions for planet-specific options
    if system.planets and #system.planets > 0 and system.manual ~= true then
      for _, planet in ipairs(system.planets) do
        point:setMenuAction("Show "..planet.name.." Info", function()
          send("showplanet \""..planet.name.."\"")
          --closeAllLevels(point)
          closeAllLevels(point.rightClickMenu)
        end)

        point:setMenuAction("Show "..planet.name.." Resources", function()
          send("showplanet \""..planet.name.."\" resources")
          --closeAllLevels(point)
          closeAllLevels(point.rightClickMenu)
        end)

        point:setMenuAction("Show "..planet.name.." AI", function()
          send("showplanet \""..planet.name.."\" ai")
          --closeAllLevels(point)
          closeAllLevels(point.rightClickMenu)
        end)
      end
    end

    -- Set action for Delete System (manual systems only)
    if system.manual then
      point:setMenuAction("Delete System", function()
        closeAllLevels(point.rightClickMenu)
        lotj.galaxyMap.removeManualSystem(system.name)
      end)
    end

    local label = lotj.galaxyMap.systemLabels[system.name]
    labelText = system.name
    local fontSize = getFontSize() - 1

    -- Calculate approximate text width based on character count and font size
    -- Average character width is roughly 0.6 times the font size
    local labelWidth = math.ceil(#labelText * fontSize * 0.8)
    local labelHeight = math.ceil(getFontSize()*1.33)

    if label == nil then
      label = Geyser.Label:new({
        name = "lotj.galaxyMap.drawSystems.label_"..system.name,
        height = labelHeight,
        width = labelWidth,
        fillBg = 0,
      }, container())

      label:setStyleSheet([[
        background-color: rgba(0,0,0,0%);
      ]])

      lotj.galaxyMap.systemLabels[system.name] = label
    else
      label:resize(labelWidth, labelHeight)
      label:show()
    end

    -- Use government color for the label
    local labelColor = lotj.galaxyMap.govToColor[system.planet.government] or "#AAAAAA"
    label:echo(labelText, labelColor, fontSize.."c")
    label:raise()

    -- Add hover effect for manually added systems
    if system.manual then
      -- Initially hide the label for manual systems
      label:hide()

      -- Show and raise label on hover
      point:setOnEnter(function()
        label:show()
        label:raiseAll()
      end)

      -- Hide label when mouse leaves
      point:setOnLeave(function()
        label:hide()
      end)
    end

    local sysX = math.floor(xOffset + (system.x-minX)*pxPerCoordX - pointSize/2 + 0.5)
    local sysY = math.floor(yOffset + (maxY-system.y)*pxPerCoord - pointSize/2 + 0.5)
    point:move(sysX, sysY)
    local stylePointFlag = false
    -- system.planets = system.planets or {}
    for _, planet in ipairs(system.planets) do
      if gmcp.Room and gmcp.Room.Info and gmcp.Room.Info.planet and gmcp.Room.Info.planet == planet.name then
        stylePoint(point, system.planet.government, true, planetImage, pointSize, system.manual, label)
        stylePointFlag = true
      end
    end
    if system.x == lotj.galaxyMap.currentX and system.y == lotj.galaxyMap.currentY and not stylePointFlag then
      stylePoint(point, system.planet.government, true, planetImage, pointSize, system.manual, label)
    elseif not stylePointFlag then
      stylePoint(point, system.planet.government, false, planetImage, pointSize, system.manual, label)
    end

    -- Center the label under the planet
    local labelX = sysX + (pointSize/2) - (labelWidth/2)
    label:move(math.max(labelX, 0), sysY+pointSize)
  end
end

-- Returns X starting point, Y starting point, and pixels per coordinate
function lotj.galaxyMap.calculateSizing()
  local minX, maxX, minY, maxY = lotj.galaxyMap.coordRange()
  local xRange = maxX-minX
  local yRange = maxY-minY
  local contWidth = container():get_width()
  local contHeight = container():get_height()

  -- Use full available space on both axes independently
  local pxPerCoord = contHeight/yRange
  local pxPerCoordX = contWidth/xRange

  local mapWidth = contWidth
  local mapHeight = contHeight

  -- No centering needed since we're using full width/height
  local mapAnchorX = 0
  local mapAnchorY = 0

  return mapAnchorX, mapAnchorY, pxPerCoord, pxPerCoordX
end

function lotj.galaxyMap.coordRange()
  local minX = 0
  local maxX = 0
  local minY = 0
  local maxY = 0

  for _, system in pairs(lotj.galaxyMap.systems) do
    if not lotj.galaxyMap.outOfBounds(system) then
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
  end

  -- Pad all values by 10 to ensure points are displayed reasonably.
  return minX-10, maxX+10, minY-10, maxY+10
end

-- Determine whether we should ignore a system. This is mostly to catch weird imm planets way
-- off the map so they don't throw off the map layout.
function lotj.galaxyMap.outOfBounds(system)
  return system.x < -200 or system.x > 200 or system.y < -200 or system.y > 200
end
