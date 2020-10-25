-- Trigger groups seem to fire the parent trigger on child matches
if not matches or #matches == 0 then
  return
end

-- Occasionally we catch the space prompt here. We want to ignore that.
if string.match(matches[2], "Fuel Level:") then
  return
end

if lotj.systemMap.maskNextRadarOutput then
  deleteLine()
end

-- If we're already in the block of radar output, don't do any top-level setup
if lotj.systemMap.inRadarOutput then
  return
end

setTriggerStayOpen("system-map-radar", 1)
lotj.systemMap.resetItems()
lotj.systemMap.inRadarOutput = true
