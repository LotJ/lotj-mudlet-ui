local class = matches.class
local shipName = matches.shipName
local starName = matches.starName
local planetName = matches.planetName
local x = tonumber(matches.x)
local y = tonumber(matches.y)
local z = tonumber(matches.z)

if matches.fin then
  if lotj.systemMap.pendingRadarRefresh then
    lotj.systemMap.radarDataReceived()
  end
  return
end

if not class and starName then
  lotj.systemMap.addItem(
    {
      class = "star",
      name = starName,
      x = x,
      y = y,
      z = z
    }
  )
  return
end

if not class and planetName then
  lotj.systemMap.addItem(
    {
      class = "planet",
      name = planetName,
      x = x,
      y = y,
      z = z
    }
  )
  return
end

if class and shipName then
  lotj.systemMap.addItem(
    {
      class = class,
      name = shipName,
      x = x,
      y = y,
      z = z
    }
  )
  return
end
