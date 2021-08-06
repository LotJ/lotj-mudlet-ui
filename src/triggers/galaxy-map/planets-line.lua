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
local startIdx, _, planet, system, gov, support, military = line:find("([^;]+);([^;]+);([^;]+);([^;]+);([^;]+)")
if not startIdx then
  gov = "None"
  startIdx, _, planet, system, support, military = line:find("([^;]+);([^;]+);([^;]+);([^;]+)")
end
if not startIdx then
  echo("\n")
  lotj.galaxyMap.log("Bad planet line: "..matches[2])
  return
end

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
