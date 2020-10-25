gatherPlanetState.section = "resources"

local resource = matches[2]:match "^%s*(.-)%s*$"
local price = tonumber(matches[3])

gatherPlanetState.resources = gatherPlanetState.resources or {}
gatherPlanetState.resources[resource] = price
