echo("\n")
lotj.galaxyMap.log("Collected basic data for "..gatherPlanetState.name)
lotj.galaxyMap.recordPlanet(gatherPlanetState)

gatherPlanetsState.pendingBasic[gatherPlanetState.name] = nil
gatherPlanetsState.pendingCommands = gatherPlanetsState.pendingCommands - 1
if gatherPlanetsState.pendingCommands == 0 then
  lotj.galaxyMap.enqueuePendingRefreshCommands()
end

gatherPlanetState = nil
