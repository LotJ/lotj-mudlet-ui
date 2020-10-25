-- If we've gotten into the list of resources, an empty line means we're done
if gatherPlanetState and gatherPlanetState.section == "resources" then
  echo("\n")
  lotj.galaxyMap.log("Collected resource data for "..gatherPlanetState.name)
  lotj.galaxyMap.recordPlanet(gatherPlanetState)
  
  gatherPlanetsState.pendingResources[gatherPlanetState.name] = nil
  gatherPlanetsState.pendingCommands = gatherPlanetsState.pendingCommands - 1
  if gatherPlanetsState.pendingCommands == 0 then
    lotj.galaxyMap.enqueuePendingRefreshCommands()
  end

  gatherPlanetState = nil
end
