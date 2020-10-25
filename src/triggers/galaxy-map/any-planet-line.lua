-- Swallow lines and extend the triggers as long as we haven't found the end of the planet yet
if gatherPlanetState ~= nil then
  setTriggerStayOpen("gather-planet", 1)
end
deleteLine()
