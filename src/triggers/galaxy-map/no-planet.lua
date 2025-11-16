local planetName = gatherPlanetsState.currentPlanet
echo("\n")
lotj.galaxyMap.log("Skipping unlisted planet: "..planetName)

-- Remove from appropriate pending list
if gatherPlanetsState.currentIsBasic then
  gatherPlanetsState.pendingBasic[planetName] = nil
else
  gatherPlanetsState.pendingResources[planetName] = nil
end

-- Decrement command counter and continue
gatherPlanetsState.pendingCommands = gatherPlanetsState.pendingCommands - 1
gatherPlanetsState.currentPlanet = nil
lotj.galaxyMap.enqueuePendingRefreshCommands()