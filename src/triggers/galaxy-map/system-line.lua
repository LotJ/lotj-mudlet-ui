local systemName = matches[2]:match "^%s*(.-)%s*$"
local xCoord = tonumber(matches[3])
local yCoord = tonumber(matches[4])

if xCoord >= -100 and xCoord <= 100 and yCoord >= -100 and yCoord <= 100 then
  lotj.galaxyMap.recordSystem(systemName, xCoord, yCoord)
end

setTriggerStayOpen("gather-starsystems", 1)
deleteLine()
