mudlet = mudlet or {}; mudlet.mapper_script = true
lotj = lotj or {}
lotj.mapper = lotj.mapper or {}


local dirs = {}
-- The order of these is important. The indices of the directions must match
-- https://github.com/Mudlet/Mudlet/blob/9c13f8f946f5b82c0c2e817dab5f42588cee17e0/src/TRoom.h#L38
table.insert(dirs, {short="n",  long="north",     rev="s",  xyzDiff = { 0, 1, 0}})
table.insert(dirs, {short="ne", long="northeast", rev="sw", xyzDiff = { 1, 1, 0}})
table.insert(dirs, {short="nw", long="northwest", rev="se", xyzDiff = {-1, 1, 0}})
table.insert(dirs, {short="e",  long="east",      rev="w",  xyzDiff = { 1, 0, 0}})
table.insert(dirs, {short="w",  long="west",      rev="e",  xyzDiff = {-1, 0, 0}})
table.insert(dirs, {short="s",  long="south",     rev="n",  xyzDiff = { 0,-1, 0}})
table.insert(dirs, {short="se", long="southeast", rev="nw", xyzDiff = { 1,-1, 0}})
table.insert(dirs, {short="sw", long="southwest", rev="ne", xyzDiff = {-1,-1, 0}})
table.insert(dirs, {short="u",  long="up",        rev="d",  xyzDiff = { 0, 0, 1}})
table.insert(dirs, {short="d",  long="down",      rev="u",  xyzDiff = { 0, 0,-1}})

-- Given a direction short or long name, or a direction number, return an object representing it.
local function dirObj(arg)
  if dirs[arg] ~= nil then
    return dirs[arg]
  end

  for _, dir in ipairs(dirs) do
    if arg == dir.short or arg == dir.long then
      return dir
    end
  end
  return nil
end

-- Given a direction short or long name, or a direction number, return an object representing its opposite
local function revDirObj(arg)
  local dir = dirObj(arg)
  if dir ~= nil then
    return dirObj(dir.rev)
  end
  return nil
end

-- Configuration of an amenity name to the environment code to use on rooms with it
local amenityEnvCodes = {
  bacta = {
    envCode = 269,
    symbol = "B"
  },
  bank = {
    envCode = 267,
    symbol = "B"
  },
  broadcast = {
    envCode = 270,
    symbol = "B"
  },
  hotel = {
    envCode = 265,
    symbol = "H"
  },
  library = {
    envCode = 261,
    symbol = "L"
  },
  locker = {
    envCode = 263,
    symbol = "L"
  },
  package = {
    envCode = 262,
    symbol = "P"
  },
  workshop = {
    envCode = 266,
    symbol = "W"
  },
  ["turbolift landing"] = {
    envCode = 259,
    symbol = "L"
  },
  ["turbolift"] = {
    envCode = 263,
    symbol = "T"
  },
}

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


------------------------------------------------------------------------------
-- Command Handlers
------------------------------------------------------------------------------

-- Main "map" command handler
function lotj.mapper.mapCommand(input)
  input = trim(input)
  if #input == 0 then
    lotj.mapper.printMainMenu()
    return
  end

  _, _, cmd, args = string.find(input, "([^%s]+)%s*(.*)")
  cmd = string.lower(cmd)

  if cmd == "help" then
    lotj.mapper.printHelp()
  elseif cmd == "start" then
    lotj.mapper.startMapping(args)
  elseif cmd == "stop" then
    lotj.mapper.stopMapping()
  elseif cmd == "deletearea" then
    lotj.mapper.deleteArea(args)
  elseif cmd == "shift" then
    lotj.mapper.shiftCurrentRoom(args)
  elseif cmd == "save" then
    lotj.mapper.saveMap()
  elseif cmd == "setroomcoords" then
    lotj.mapper.setRoomCoords(args)
  else
    lotj.mapper.logError("Unknown map command. Try <yellow>map help<reset>.")
  end
end


function lotj.mapper.printMainMenu()
  lotj.mapper.log("Mapper Introduction and Status")
  cecho([[

The LOTJ Mapper plugin tracks movement using GMCP variables. To begin, try <yellow>map start <current area><reset>.
Once mapping is started, move <red>slowly<reset> between rooms to map them. Moving too quickly will cause the
mapper to skip rooms. You should wait for the map to reflect your movements before moving again
whenever you are in mapping mode.

When you are finished mapping, use <yellow>map stop<reset> to stop recording your movements, and be sure to
<yellow>map save<reset>! Map data will not be saved automatically.

Other commands are available to adjust mapping as you go. <yellow>map shift <direction><reset>, for example,
will move your current room. See <yellow>map help<reset> for a full list of available commands.

The map GUI also offers editing functionality and is ideal for moving groups of rooms, deleting
or coloring rooms, etc.

]])

  if lotj.mapper.mappingArea ~= nil then
    cecho("Mapper status: <green>Mapping<reset> in area <yellow>"..lotj.mapper.mappingArea.."<reset>\n")
  else
    cecho("Mapper status: <red>Off<reset>\n")
  end
end


function lotj.mapper.printHelp()
  lotj.mapper.log("Mapper Command List")
  cecho([[

<yellow>map start [<area name>]<reset>

Begin mapping. Any new rooms you enter while mapping will be added to this area name, so you
should be sure to stop mapping before entering a ship or moving to a different planet. No area
name argument is required if you're on a planet, as we'll default to the planet name.

Some tips to remember:
 - Use a light while mapping. Entering a dark room where you can't see will not update the map.
 - Use <yellow>map shift<reset> to adjust room positioning, especially after going through turbolifts or
   voice-activated doors. It's faster to click-and-drag with the GUI to move large blocks of
   rooms, though.
 - Rooms in ships are all unique, even if they are the same model. In practice, mapping ships
   really isn't supported yet, although platforms or ships you use frequently may be worth it.

<yellow>map stop<reset>

Stop editing the map based on your movements.

<yellow>map save<reset>

Save the map to the map.dat file in your Mudlet profile's directory.

<yellow>map deletearea <area name><reset>

Deletes all data for an area. There's no confirmation and no undo!

<yellow>map shift <direction><reset>

Moves the current room in whichever direction you enter. Useful for adjusting placement of
rooms when you need to space them out.
]])


  if gmcp.Char.Info.immLevel and gmcp.Char.Info.immLevel >= 102 then
    cecho([[

<yellow>map setroomcoords <area name><reset>

<orange>(Staff Command)<reset> Assuming you are happy with your local copy of a map, sends commands to the
game to set the x/y/z coordinates of all rooms. (Requires the 'at' command.)
]])
  end

end


function lotj.mapper.startMapping(areaName)
  areaName = trim(areaName)
  if #areaName == 0 then
    if lotj.mapper.current and lotj.mapper.current.planet then
      areaName = lotj.mapper.current.planet
    else
      lotj.mapper.log("Syntax: map start <yellow><area name><reset>")
      return
    end
  end

  if lotj.mapper.mappingArea ~= nil then
    lotj.mapper.logError("Mapper already running in <yellow>"..lotj.mapper.mappingArea.."<reset>.")
    return
  end

  local areaTable = getAreaTable()
  if areaTable[areaName] == nil then
    addAreaName(areaName)
    lotj.mapper.log("Mapping in new area <yellow>"..areaName.."<reset>.")
  else
    lotj.mapper.log("Mapping in existing area <yellow>"..areaName.."<reset>.")
  end
  
  lotj.mapper.mappingArea = areaName
  lotj.mapper.processCurrentRoom()
end


function lotj.mapper.stopMapping()
  if lotj.mapper.mappingArea == nil then
    lotj.mapper.logError("Mapper not running.")
    return
  end
  lotj.mapper.mappingArea = nil
  lotj.mapper.log("Mapping <red>stopped<reset>. Don't forget to <yellow>map save<reset>!")
end


function lotj.mapper.deleteArea(areaName)
  areaName = trim(areaName)
  if #areaName == 0 then
    lotj.mapper.log("Syntax: map deletearea <yellow><area name><reset>")
    return
  end

  local areaTable = getAreaTable()
  if areaTable[areaName] == nil then
    lotj.mapper.logError("Area <yellow>"..areaName.."<reset> does not exist.")
    return
  end
  
  if areaName == lotj.mapper.mappingArea then
    lotj.mapper.stopMapping()
  end

  deleteArea(areaName)
  lotj.mapper.log("Area <yellow>"..areaName.."<reset> deleted.")
end


function lotj.mapper.shiftCurrentRoom(direction)
  direction = trim(direction)
  if #direction == 0 then
    lotj.mapper.log("Syntax: map shift <yellow><direction><reset>")
    return
  end

  local dir = dirObj(direction)
  if dir == nil then
    lotj.mapper.logError("Direction unknown: <yellow>"..direction.."<reset>")
    return
  end

  local vnum = lotj.mapper.current.vnum
  local room = lotj.mapper.getRoomByVnum(vnum)
  if room ~= nil then
    currentX, currentY, currentZ = getRoomCoordinates(vnum)
    dx, dy, dz = unpack(dir.xyzDiff)
    setRoomCoordinates(vnum, currentX+dx, currentY+dy, currentZ+dz)
    updateMap()
    centerview(vnum)
  end
end


function lotj.mapper.saveMap()
  saveMap(getMudletHomeDir() .. "/map.dat")
  lotj.mapper.log("Map saved.")
end


function lotj.mapper.setRoomCoords(areaName)
  if not gmcp.Char.Info.immLevel or gmcp.Char.Info.immLevel < 102 then
    lotj.mapper.logError("This command only works for imm characters.")
    return
  end
  
  local areaId = getAreaTable()[areaName]
  if not areaId then
    lotj.mapper.logError("Area not found by name "..areaName)
    return
  end
  
  for _, roomId in ipairs(getAreaRooms(areaId)) do
    local x, y, z = getRoomCoordinates(roomId)
    send("at "..roomId.." redit xyz "..x.." "..y.." "..z)
  end
end  


------------------------------------------------------------------------------
-- Event Handlers
------------------------------------------------------------------------------


function lotj.mapper.setup()
  if not geyserMapper then
    -- Preserve this as a global. We can only create one mapper in a profile, so if we
    -- unload and reload this UI, we need to reuse what was created before.
    geyserMapper = Geyser.Mapper:new({
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    }, lotj.layout.upperRightTabData.contents["map"])
  else
    lotj.layout.upperRightTabData.contents["map"]:add(geyserMapper)
    geyserMapper:raiseAll()
  end
  setMapZoom(15)

  local hasAnyAreas = false
  for name, id in pairs(getAreaTable()) do
    if name ~= "Default Area" then
      hasAnyAreas = true
    end
  end
  if not hasAnyAreas then
    loadMap(getMudletHomeDir().."/@PKGNAME@/starter-map.dat")
  end

  lotj.setup.registerEventHandler("sysDataSendRequest", lotj.mapper.handleSentCommand)
  lotj.setup.registerEventHandler("gmcp.Room.Info", lotj.mapper.onEnterRoom)
end

function lotj.mapper.teardown()
  lotj.layout.upperRightTabData.contents["map"]:remove(geyserMapper)
  geyserMapper:hide()
end


-- Track the most recent movement command so we know which direction we moved when automapping
function lotj.mapper.handleSentCommand(event, cmd)
  -- If we're not mapping, don't bother
  if lotj.mapper.mappingArea == nil then
    return
  end

  local dir = dirObj(trim(cmd))
  if dir ~= nil then
    lotj.mapper.lastMoveDirs = lotj.mapper.lastMoveDirs or {}
    table.insert(lotj.mapper.lastMoveDirs, dir)
    lotj.mapper.logDebug("Pushed movement dir: "..dir.long)
  end
end


function lotj.mapper.popMoveDir()
  if not lotj.mapper.lastMoveDirs or #lotj.mapper.lastMoveDirs == 0 then
    lotj.mapper.logDebug("Popped movement dir: nil")
    return nil
  end
  local result = table.remove(lotj.mapper.lastMoveDirs, 1)
  lotj.mapper.logDebug("Popped movement dir: "..result.long)
  return result
end


-- Function used to handle a room that we've moved into. This will use the data on
-- lotj.mapper.current, compared with lotj.mapper.last, to potentially create a new room and
-- link it with an exit on the previous room.
function lotj.mapper.processCurrentRoom()
  local vnum = lotj.mapper.current.vnum
  local moveDir = lotj.mapper.popMoveDir()
  local room = lotj.mapper.getRoomByVnum(vnum)

  if lotj.mapper.mappingArea == nil and room == nil then
    lotj.mapper.logDebug("Room not found, but mapper not running.")
    return
  end

  local lastRoom = nil
  if lotj.mapper.last ~= nil then
    lastRoom = lotj.mapper.getRoomByVnum(lotj.mapper.last.vnum)
  end

  -- Create the room if we don't have it yet
  if room == nil then
    lotj.mapper.log("Added new room: <yellow>"..lotj.mapper.current.name.."<reset>")
    addRoom(vnum)
    setRoomArea(vnum, lotj.mapper.mappingArea)
    setRoomCoordinates(vnum, 0, 0, 0)
    setRoomName(vnum, lotj.mapper.current.name)
    room = lotj.mapper.getRoomByVnum(vnum)

    -- Create stub exits in any known direction we see
    for dir, state in pairs(lotj.mapper.current.exits) do
      local exitDir = dirObj(dir)
      if exitDir ~= nil then
        setExitStub(vnum, exitDir.short, true)
        if state == "C" then
          setDoor(vnum, exitDir.short, 2)
        end
      end
    end

    local lastRoomAtPresetCoords = false
    if lastRoom ~= nil then
      -- Figure out if our last room was positioned by ingame room settings.
      local lastX, lastY, lastZ = getRoomCoordinates(lotj.mapper.last.vnum)
      if lotj.mapper.last.x == lastX and
         lotj.mapper.last.y == lastY and
         lotj.mapper.last.z == lastZ then
        lastRoomAtPresetCoords = true
      end
    end

    if lotj.mapper.current.x ~= nil and (not lastRoom or lastRoomAtPresetCoords) then
      -- This room has x/y/z set ingame and we're not coming from a lastRoom with
      -- a custom direction, so we should honor what the game said to use.
      setRoomCoordinates(vnum, lotj.mapper.current.x, lotj.mapper.current.y, lotj.mapper.current.z)
    elseif lastRoom ~= nil then
      -- Position the room relative to the room we came from
      local lastX, lastY, lastZ = getRoomCoordinates(lotj.mapper.last.vnum)
      
      -- If we recorded a valid movement command, use that direction to position this room
      if moveDir ~= nil then
        local dx, dy, dz = unpack(moveDir.xyzDiff)
        lotj.mapper.log("Positioning new room "..moveDir.long.." of the previous room based on movement command.")
        setRoomCoordinates(vnum, lastX+dx, lastY+dy, lastZ+dz)
      else
        -- We didn't have a valid movement command but we still changed rooms, so try to guess
        -- where this room should be relative to the last.
        
        -- Find a stub with a door on the last room which matches a stub with a door on this room
        -- This aims to handle cases where you've used a voice-activated locked door
        local lastDoors = getDoors(lotj.mapper.last.vnum)
        local currentDoors = getDoors(vnum)
        local matchingStubDir = nil
        for _, lastRoomStubDirNum in ipairs(getExitStubs1(lotj.mapper.last.vnum) or {}) do
          local lastRoomStubDir = dirObj(lastRoomStubDirNum)

          for _, currentRoomStubDirNum in ipairs(getExitStubs1(vnum) or {}) do
            local currentRoomStubDir = dirObj(currentRoomStubDirNum)
            if lastRoomStubDir.short == currentRoomStubDir.rev
              and lastDoors[lastRoomStubDir.short] == 2
              and currentDoors[currentRoomStubDir.short] == 2 then

              matchingStubDir = lastRoomStubDir
            end
          end
        end
        
        if matchingStubDir ~= nil then
          local dx, dy, dz = unpack(matchingStubDir.xyzDiff)
          setRoomCoordinates(vnum, lastX+dx, lastY+dy, lastZ+dz)
          lotj.mapper.log("Positioning new room "..matchingStubDir.long.." of the previous room based on matching closed doors.")
        else
          -- If no matching stubs were found, just find a nearby location which isn't taken by either a stub or a real room.
          for dir in pairs({"n", "e", "w", "s", "ne", "nw", "se", "sw", "u", "d"}) do
            local dx, dy, dz = unpack(dirObj(dir).xyzDiff)
            local overlappingRoomId = lotj.mapper.getRoomByCoords(lotj.mapper.mappingArea, lastX+dx, lastY+dy, lastZ+dz)
            
            local hasOverlappingStub = false
            for _, stubDirNum in ipairs(getExitStubs1(lotj.mapper.last.vnum) or {}) do
              if dirObj(stubDirNum) == dirObj(dir) then
                hasOverlappingStub = true
              end
            end

            if overlappingRoomId == nil and not hasOverlappingStub then
              lotj.mapper.log("Exit unknown. Positioning new room "..dirObj(dir).long.." of the previous room.")
              setRoomCoordinates(vnum, lastX+dx, lastY+dy, lastZ+dz)
              break
            end
          end
        end
      end
    end
  end
  
  -- Link this room with the previous one if they have a matching set of exit stubs
  if lastRoom ~= nil and moveDir ~= nil then
    -- Always set the exit we took even if it wasn't a stub. The direction we just moved is our best
    -- evidence of how rooms are connected, overriding any reverse-created exits made earlier if they
    -- are different.
    setExit(lotj.mapper.last.vnum, vnum, moveDir.short)

    -- Only set the reverse exit (from current room back to where we came from) if it's a stub.
    -- In the case of mazes or asymmetrical exits, this may be wrong but will be fixed on moving back
    -- out through this exit.
    for _, currentRoomStubDirNum in ipairs(getExitStubs1(vnum) or {}) do
      local currentRoomStubDir = dirObj(currentRoomStubDirNum)
      if moveDir.rev == currentRoomStubDir.short then
        setExit(vnum, lotj.mapper.last.vnum, moveDir.rev)
      end
    end
  end

  centerview(vnum)
end


function lotj.mapper.checkAmenityLine(roomName, amenityName)
  if lotj.mapper.mappingArea == nil then
    return
  end

  amenityData = amenityEnvCodes[string.lower(amenityName)]
  if amenityData == nil then
    return
  end
  
  -- Sanity check that the current room matches the name we just saw
  local addAmenityRoom = nil
  if lotj.mapper.current.name == roomName then
    addAmenityRoom = lotj.mapper.current
  else
    return
  end
  
  -- This is being invoked on seeing a room name and we don't want it mushed into that line.
  echo("\n")

  lotj.mapper.log("Set amenity <yellow>"..amenityName.."<reset> on room <yellow>"..addAmenityRoom.name.."<reset>")
  setRoomEnv(addAmenityRoom.vnum, amenityData.envCode)
  setRoomChar(addAmenityRoom.vnum, amenityData.symbol)
  updateMap()
end


-- The vnum is always sent after the name and exits, so we can use it as a trigger for
-- handling movement to a new room
function lotj.mapper.onEnterRoom()
  if lotj.mapper.current ~= nil then
    lotj.mapper.last = lotj.mapper.current
  end
  lotj.mapper.current = {
    vnum = gmcp.Room.Info.vnum,
    name = gmcp.Room.Info.name:gsub("&.", ""),
    exits = gmcp.Room.Info.exits or {},
    planet = gmcp.Room.Info.planet,
  }

  -- This room has coordinates set in the game which we should use.
  if gmcp.Room.Info.x ~= nil then
    lotj.mapper.current.x = gmcp.Room.Info.x
    lotj.mapper.current.y = gmcp.Room.Info.y
    lotj.mapper.current.z = gmcp.Room.Info.z
  end

  -- If the new room has has a planet different than the last one and we don't have
  -- an area for that planet yet, give a prompt about how to start mapping it.
  if lotj.mapper.current.planet then
    if lotj.mapper.last and lotj.mapper.last.planet ~= lotj.mapper.current.planet then
      if getAreaTable()[lotj.mapper.current.planet] == nil then
        lotj.mapper.log("Welcome to <yellow>"..lotj.mapper.current.planet.."<reset>. "..
          "To begin mapping this area as you explore, type <yellow>map start<reset>.")
        echo("\n")
      end
    end
  end
  
  lotj.mapper.processCurrentRoom()
end


------------------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------------------


function lotj.mapper.log(text)
  cecho("[<cyan>LOTJ Mapper<reset>] "..text.."\n")
end

function lotj.mapper.logDebug(text)
  if lotj.mapper.debug then
    lotj.mapper.log("<green>Debug:<reset> "..text)
  end
end

function lotj.mapper.logError(text)
  lotj.mapper.log("<red>Error:<reset> "..text)
end

function lotj.mapper.getRoomByVnum(vnum)
  return getRooms()[vnum]
end

function lotj.mapper.getRoomByCoords(areaName, x, y, z)
  local areaRooms = getAreaRooms(getAreaTable()[areaName]) or {}
  for _, roomId in pairs(areaRooms) do
    local roomX, roomY, roomZ = getRoomCoordinates(roomId)
    if roomX == x and roomY == y and roomZ == z then
      return roomId
    end
  end
  return nil
end

function doSpeedWalk()
  lotj.mapper.log("Speedwalking using these directions: " .. table.concat(speedWalkDir, ", ") .. "\n")
  for _, dir in ipairs(speedWalkDir) do
    send(dir, false)
  end
end
