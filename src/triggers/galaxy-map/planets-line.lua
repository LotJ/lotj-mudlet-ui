deleteLine()

local line = matches[2]

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

-- After all the planets there's a blank line
if line == "" then
  lotj.galaxyMap.enqueuePendingRefreshCommands()
  return
end

line = line:gsub("  +", ";")
local startIdx, _, planet, system, gov, notices = line:find("([^;]+);([^;]+);([^;]+);([^;]+)")
if not startIdx then
  gov = "None"
  startIdx, _, planet, system, notices = line:find("([^;]+);([^;]+);([^;]+)")
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
