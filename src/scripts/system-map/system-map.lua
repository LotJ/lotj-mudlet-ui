lotj = lotj or {}
lotj.systemMap = lotj.systemMap or {
  mapRange = 2000,
  radarItems = {},
  genPoints = {},
  genLabels = {}
}
local pointSize = 12
local labelWidth = 200
local labelHeight = 16

local controlButtonStyle = [[
  background-color: grey;
  border: 2px solid white;
]]

registerAnonymousEventHandler("lotjUICreated", function()
  disableTrigger("system-map-radar")

  local tabContents = lotj.layout.upperRightTabData.contents["system"]
  lotj.systemMap.container = Geyser.Label:new({}, tabContents)
  lotj.systemMap.container:setStyleSheet([[
    background-color: black;
  ]])
  lotj.systemMap.resizeToSquare()
  registerAnonymousEventHandler("sysWindowResizeEvent", lotj.systemMap.resizeToSquare)

  local zoomInButton = Geyser.Label:new({
    x = "2%", y = 10,
    width = 28, height = 28,
  }, tabContents)
  zoomInButton:setStyleSheet(controlButtonStyle)
  zoomInButton:echo("+", "white", "c16b")
  zoomInButton:setClickCallback(function()
    if lotj.systemMap.mapRange > 1000 then
      lotj.systemMap.mapRange = lotj.systemMap.mapRange - 1000
    elseif lotj.systemMap.mapRange == 1000 then
      lotj.systemMap.mapRange = 500
    else
      return
    end
    lotj.systemMap.drawMap()
  end)

  local zoomOutButton = Geyser.Label:new({
    x = "2%", y = 44,
    width = 28, height = 28,
  }, tabContents)
  zoomOutButton:setStyleSheet(controlButtonStyle)
  zoomOutButton:echo("-", "white", "c16b")
  zoomOutButton:setClickCallback(function()
    if lotj.systemMap.mapRange >= 1000 then
      lotj.systemMap.mapRange = lotj.systemMap.mapRange + 1000
    elseif lotj.systemMap.mapRange == 500 then
      lotj.systemMap.mapRange = 1000
    else
      return
    end
    lotj.systemMap.drawMap()
  end)

  local refreshButton = Geyser.Label:new({
    x = "2%", y = 78,
    width = 28, height = 28,
  }, tabContents)
  refreshButton:setStyleSheet(controlButtonStyle)
  refreshButton:echo("R", "white", "c16b")
  refreshButton:setClickCallback(function()
    lotj.systemMap.maskNextRadarOutput = true
    expandAlias("radar", false)
  end)


  local rangeCircle = rangeCircle or Geyser.Label:new({fillBg = 0}, lotj.systemMap.container)
  rangeCircle:move(0, 0)

  lotj.systemMap.rangeLabel = lotj.systemMap.rangeLabel or Geyser.Label:new({fillBg = 0}, lotj.systemMap.container)
  lotj.systemMap.rangeLabel:resize(50, 20)
  lotj.systemMap.rangeLabel:echo(lotj.systemMap.mapRange, "green", "10c")

  local function positionRangeCircle()
    local containerSize = lotj.systemMap.container:get_height()
    lotj.systemMap.rangeLabel:move(containerSize-math.ceil(containerSize/10)-25, math.ceil(containerSize/10))
    rangeCircle:resize(containerSize, containerSize)
    rangeCircle:setStyleSheet([[
      border: 1px dashed green;
      border-radius: ]]..math.floor(containerSize/2)..[[px;
    ]])
  end
  positionRangeCircle()
  registerAnonymousEventHandler("sysWindowResizeEvent", positionRangeCircle)

  registerAnonymousEventHandler("gmcp.Ship.Base", "lotj.systemMap.drawMap")
end)

function lotj.systemMap.resetItems()
  lotj.systemMap.radarItems = {}
end

function lotj.systemMap.addItem(item)
  table.insert(lotj.systemMap.radarItems, item)
end

function lotj.systemMap.drawMap()
  lotj.systemMap.rangeLabel:echo(lotj.systemMap.mapRange, "green", "10c")

  -- Hide any previously generated elements which we may be displaying
  for _, elem in ipairs(lotj.systemMap.genPoints) do
    elem:hide()
  end
  for _, elem in ipairs(lotj.systemMap.genLabels) do
    elem:hide()
  end

  -- We use ship max speed as a proxy for "do we have ship data at all"
  if gmcp.Ship.Base.maxSpeed == nil then
    return
  end

  local shipX = gmcp.Ship.Base.posX
  local shipY = gmcp.Ship.Base.posY
  local shipZ = gmcp.Ship.Base.posZ
  local selfData = {name="You", x=shipX, y=shipY, z=shipZ}

  local itemsToDraw = {}
  table.insert(itemsToDraw, selfData)
  for _, item in ipairs(lotj.systemMap.radarItems) do
    if lotj.systemMap.dist(selfData, item) <= lotj.systemMap.mapRange then
      table.insert(itemsToDraw, item)
    end
  end

  local drawnItems = {}
  for i, item in ipairs(itemsToDraw) do
    local point, label = lotj.systemMap.pointAndLabel(i)

    local color = "yellow"
    if item.class and string.match(item.class, "Pirated") then
      color = "red"
    elseif item == selfData then
      color = "white"
    end

    point:resize(pointSize, pointSize)
    point:setStyleSheet([[
      border-radius: ]]..math.floor(pointSize/2)..[[px;
      background-color: ]]..color..[[;
    ]])

    local x, y = lotj.systemMap.computeXY(selfData, item)
    point:show()
    point:move(x, y)

    local labelXOffset, labelYOffset = lotj.systemMap.computeLabelPos(drawnItems, x, y)
    local labelX = x+labelXOffset
    local labelY = y+labelYOffset
    label:show()
    label:move(labelX, labelY)
    lotj.systemMap.printLabels(point, label, color, labelXOffset, item, selfData)

    table.insert(drawnItems, {x = x, y = y, labelX = labelX, labelY = labelY, labelXOffset = labelXOffset, labelYOffset = labelYOffset})
  end
end

-- Add appropriate text to the point and label
function lotj.systemMap.printLabels(point, label, color, labelXOffset, item, selfData)
  local labelStr = item.name

  -- Prepend an up/down arrow to show Z diff
  local zDiff = item.z - selfData.z
  if zDiff ~= 0 then
    local arrowFontSize = 3 + math.floor(11 * math.abs(zDiff) / lotj.systemMap.mapRange + 0.5)
    local arrowChar = "&#x25B2;" -- Up arrow
    if zDiff < 0 then
      arrowChar = "&#x25BC;" -- Down arrow
    end
    point:echo(arrowChar, "black", arrowFontSize.."c")
  else
    point:echo("")
  end

  -- Append proximity and class
  if item ~= selfData then
    labelStr = labelStr.." ("..math.floor(lotj.systemMap.dist(item, selfData) + 0.5)
    if item.class ~= nil then
      labelStr = labelStr..", "..item.class
    end
    labelStr = labelStr..")"
  end

  -- Set alignment based on whether the label is to the right or left of the point
  if labelXOffset > 0 then
    label:echo(labelStr, color, "11l")
  else
    label:echo(labelStr, color, "11r")
  end
end

-- Based on the position, size of map, and zoom level, determine the X and Y placement for the given item
function lotj.systemMap.computeXY(selfData, item)
  local mapMinX = selfData.x-lotj.systemMap.mapRange
  local mapMinY = selfData.y-lotj.systemMap.mapRange
  local containerSize = lotj.systemMap.container:get_height()

  local x = math.floor(containerSize * ((item.x - mapMinX) / (lotj.systemMap.mapRange*2)) + 0.5)
  local y = math.floor(containerSize * (1 - (item.y - mapMinY) / (lotj.systemMap.mapRange*2)) + 0.5)

  return x-pointSize/2, y-pointSize/2
end

-- Return true if the first rectancle overlaps with any part of the second rectangle
local function overlaps(x1, y1, w1, h1, x2, y2, w2, h2)
  local xOverlap = (x1 >= x2 and x1 <= x2+w2) or (x1+w1 >= x2 and x1+w1 <= x2+w2)
  local yOverlap = (y1 >= y2 and y1 <= y2+h2) or (y1+h1 >= y2 and y1+h1 <= y2+h2)
  return xOverlap and yOverlap
end

-- Determine whether a given rectangle overlaps with the points or labels in the given array of items
local function anyOverlaps(x, y, w, h, items)
  for _, item in ipairs(items) do
    -- Overlap with this item's point?
    if overlaps(x, y, w, h, item.x, item.y, pointSize, pointSize) then
      return true
    end
    -- Overlap with this item's label?
    if overlaps(x, y, w, h, item.labelX, item.labelY, labelWidth, labelHeight) then
      return true
    end
  end
  return false
end

-- Find a suitable label X and Y offset for a new label, attempting to avoid overlap with anything previously drawn
function lotj.systemMap.computeLabelPos(drawnItems, itemX, itemY)
  local labelXOffset = pointSize
  local labelYOffset = pointSize

  -- If we find an item at the same coords, simply put the label below the last one for those coords
  local foundSameCoords = false
  for _, item in ipairs(drawnItems) do
    if item.x == itemX and item.y == itemY then
      foundSameCoords = true
      if item.labelY > item.y then
        labelYOffset = item.labelYOffset + labelHeight
      else
        labelYOffset = item.labelYOffset - labelHeight
      end
    end
  end
  if foundSameCoords then
    return labelXOffset, labelYOffset
  end

  -- Try four different label positions to find one without any overlap
  local offsetsToTry = {}
  table.insert(offsetsToTry, {x = pointSize, y = pointSize})
  table.insert(offsetsToTry, {x = pointSize, y = labelHeight * -1})
  table.insert(offsetsToTry, {x = labelWidth * -1, y = labelHeight * -1})
  table.insert(offsetsToTry, {x = labelWidth * -1, y = pointSize})
  for _, offsets in ipairs(offsetsToTry) do
    if not anyOverlaps(itemX+offsets.x, itemY+offsets.y, labelWidth, labelHeight, drawnItems) then
      return offsets.x, offsets.y
    end
  end

  -- We couldn't find a non-overlapping position, so just put it to the lower right
  return labelXOffset, labelYOffset
end

-- Return existing (or create new) Geyser labels for a given point and label
-- We store and reuse these so that we don't accumulate infinite label objects, since Geyser doesn't give us a way to delete elements, only hide them
function lotj.systemMap.pointAndLabel(idx)
  lotj.systemMap.genPoints[idx] = lotj.systemMap.genPoints[idx] or Geyser.Label:new({}, lotj.systemMap.container)
  lotj.systemMap.genLabels[idx] = lotj.systemMap.genLabels[idx] or Geyser.Label:new({fillBg = 0, width = labelWidth, height = labelHeight}, lotj.systemMap.container)
  return lotj.systemMap.genPoints[idx], lotj.systemMap.genLabels[idx]
end

-- Compute distance between one X/Y/Z coord and another
function lotj.systemMap.dist(coordsA, coordsB)
  local xDiff = math.abs(coordsA.x-coordsB.x)
  local yDiff = math.abs(coordsA.y-coordsB.y)
  local zDiff = math.abs(coordsA.z-coordsB.z)

  local xyDiff = math.sqrt(xDiff*xDiff + yDiff*yDiff)
  local totalDiff = math.sqrt(xyDiff*xyDiff + zDiff*zDiff)
  return totalDiff
end

-- Resize the map to the largest possible square when the window dimensions change
function lotj.systemMap.resizeToSquare()
  local tabContents = lotj.layout.upperRightTabData.contents["system"]
  local contH = tabContents:get_height()
  local contW = tabContents:get_width()

  local x = 0
  local y = 0
  local width = "100%"
  local height = "100%"
  if contW >= contH then
    width = contH
    x = (contW-contH)/2
  else
    height = contW
    y = (contH-contW)/2
  end

  lotj.systemMap.container:move(x, y)
  lotj.systemMap.container:resize(width, height)
end

function lotj.systemMap.findTarget(targetName)
  targetName = targetName:lower()
  local target = nil
  for _, item in ipairs(lotj.systemMap.radarItems) do
    if item.name:lower():sub(1, #targetName) == targetName then
      target = item
    end
  end
  return target
end

function lotj.systemMap.log(text)
  cecho("[<cyan>System Map<reset>] "..text.."\n")
end
