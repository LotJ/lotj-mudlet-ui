deleteLine()

local line = matches[2]

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

if starts_with(line, "Use SHOWPLANET for more information.") then
  lotj.galaxyMap.enqueuePendingRefreshCommands()
  return
end

line = line:gsub("%(UFG%)", "")
line = line:gsub("  +", ";")
local _, _, planet, system, gov, support = line:find("([^;]+);([^;]+);([^;]+);([^;]+)")

if planet ~= "Planet" then
  lotj.galaxyMap.recordPlanet({
    name = planet,
    system = system,
    gov = gov,
  })

  gatherPlanetsState.pendingBasic[planet] = true
  gatherPlanetsState.pendingResources[planet] = true
end

setTriggerStayOpen("gather-planets", 1)
