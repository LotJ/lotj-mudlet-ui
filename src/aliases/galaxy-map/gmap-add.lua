-- Parse the arguments: gmap add <name> <x> <y>
local args = matches[2]
local parsedArgs = splitargs(args)

if #parsedArgs < 3 then
  lotj.galaxyMap.log("<red>Usage: gmap add <system name> <x> <y>")
  lotj.galaxyMap.log("Example: gmap add \"Unknown System\" -50 75")
  return
end

local name = parsedArgs[1]
local x = parsedArgs[2]
local y = parsedArgs[3]

lotj.galaxyMap.addManualSystem(name, x, y)
