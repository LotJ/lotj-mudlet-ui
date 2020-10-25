local trimName = matches[2]:gsub("^%s*(.-)%s*$", "%1")

if trimName == "Your Coordinates:" then
  setTriggerStayOpen("system-map-radar", 0)
  disableTrigger("system-map-radar")

  echo("\n")
  lotj.systemMap.log("Radar data collected.")
  lotj.systemMap.maskNextRadarOutput = false
  lotj.systemMap.inRadarOutput = false
  lotj.systemMap.drawMap()

  return
end

_, _, class, name = trimName:find("(.*) '(.*)'")
if name == nil then
  name = trimName
end

lotj.systemMap.addItem({
  class = class,
  name = name,
  x = tonumber(matches[3]),
  y = tonumber(matches[4]),
  z = tonumber(matches[5]),
})

if lotj.systemMap.maskNextRadarOutput then
  deleteLine()
end
setTriggerStayOpen("system-map-radar", 1)
