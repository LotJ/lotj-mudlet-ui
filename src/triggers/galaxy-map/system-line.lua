local systemName = matches[2]:match "^%s*(.-)%s*$"
local xCoord = tonumber(matches[3])
local yCoord = tonumber(matches[4])

lotj.galaxyMap.recordSystem(systemName, xCoord, yCoord)

setTriggerStayOpen("gather-starsystems", 1)
deleteLine()
