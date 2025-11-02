-- Parse the arguments: gmap remove <name>
local args = matches[2]
local parsedArgs = splitargs(args)

if #parsedArgs < 1 then
  lotj.galaxyMap.log("<red>Usage: gmap remove <system name>")
  lotj.galaxyMap.log("Example: gmap remove \"Unknown System\"")
  return
end

local name = parsedArgs[1]
lotj.galaxyMap.removeManualSystem(name)
