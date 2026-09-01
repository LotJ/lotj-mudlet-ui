---@diagnostic disable: redundant-parameter

debugc("lotj-ui -> setup.lua")

lotj = lotj or {}
lotj.settings = lotj.settings or {}
lotj.configTable = lotj.configTable or {}
lotj.setup = lotj.setup or {}
lotj.setup.eventHandlerKillIds = lotj.setup.eventHandlerKillIds or {}
lotj.setup.gmcpEventHandlerFuncs = lotj.setup.gmcpEventHandlerFuncs or {}

gmcp = gmcp or {}

gmcp.Char = gmcp.Char or {
  Enemy = {},
  Chat = {}
}
gmcp.Room = gmcp.Room or {
  Info = {}
}

---@param eventName string
---@param func function
function lotj.setup.registerEventHandler(eventName, func)
  local killId = registerAnonymousEventHandler(eventName, func)
  table.insert(lotj.setup.eventHandlerKillIds, killId)

  -- A little bit hacky, but we want to run all GMCP event handlers when we finish
  -- doing initial setup to populate the UI.
  if eventName:find("gmcp.") then
    table.insert(lotj.setup.gmcpEventHandlerFuncs, func)
  end
end

local function debugChar()
  lotj.chat.debugLog("Char")
end
local function debugRoom()
  lotj.chat.debugLog("Room")
end
local function debugShip()
  lotj.chat.debugLog("Ship")
end
local function debugExternal()
  lotj.chat.debugLog("External")
end
local function debugClient()
  lotj.chat.debugLog("Client")
end
local function debugGalaxy()
  lotj.chat.debugLog("Galaxy")
end

local function saveData()
  if lotj and lotj.mapper and lotj.configTable then
    lotj.configTable.mappingArea = false
    if lotj.mapper.mappingArea then
      lotj.configTable.mappingArea = true
    end
  end

  lotj.configTable = copyTableWithoutFunctions(lotj.configTable)
  lotj.chat.debugLog("Saving lotj.configTable dynamic settings...")
  -- Example: save to JSON file
  -- local json = require("dkjson")
  local json = require("@PKGNAME@.dkjson")
  local file = io.open(getMudletHomeDir().."/.dynamic_settings.lua", "w")
  if file then
    file:write(json.encode(lotj.configTable))
    file:close()
    lotj.chat.debugLog(".dynamic_settings.lua successfully saved.")
  end
end

local function loadData()
  lotj.chat.debugLog("Loading .dynamic_settings.lua...")
  -- Example: load from JSON file
  -- local json = require("dkjson")
  local json = require("@PKGNAME@.dkjson")
  local file = io.open(getMudletHomeDir().."/.dynamic_settings.lua", "r")
  if file == nil then
    saveData()
    file = io.open(getMudletHomeDir().."/.dynamic_settings.lua", "r")
  end
  if file then
    local content = file:read("*all")
    file:close()
    local loaded = json.decode(content)
    lotj.chat.debugLog(".dynamic_settings.lua successfully loaded.")
    lotj.configTable = loaded
  end
end

local function doSetup()
  -- No setup can be done without default settings being loaded
  lotj.settings.setup()

  -- Layout has to be created first
  lotj.layout.setup()

  -- Then everything else in no particular order
  lotj.chat.setup()
  lotj.galaxyMap.setup()
  lotj.infoPanel.setup()
  lotj.systemMap.setup()
  lotj.mapper.setup()
  lotj.comlinkInfo.setup()
  lotj.tutorial.setup()
  loadData()

  -- Settings tab setup after chat setup
  lotj.settings.setupTab()

  lotj.setup.registerEventHandler("gmcp.Char", debugChar)
  lotj.setup.registerEventHandler("gmcp.Room", debugRoom)
  lotj.setup.registerEventHandler("gmcp.Ship", debugShip)
  lotj.setup.registerEventHandler("gmcp.External", debugExternal)
  lotj.setup.registerEventHandler("gmcp.Client", debugClient)
  lotj.setup.registerEventHandler("gmcp.Galaxy", debugGalaxy)

  -- Event handler for saving data on profile close
  -- lotj.setup.registerEventHandler("sysDisconnectionEvent", saveData) -- We do not save data on disconnect so dynamic settings are not shared between quick character swaps
  lotj.setup.registerEventHandler("sysExitEvent", saveData)

  -- Manually kick off all GMCP event handlers, since GMCP data would not have changed
  -- since loading the UI.
  for _, func in ipairs(lotj.setup.gmcpEventHandlerFuncs) do
    func()
  end

  geyserMapper:show()
  geyserMapper:raise()

  -- Then set our UI default view and check for tutorial
  tempTimer(0, [[
    lotj.layout.selectTab(lotj.layout.upperRightTabData, lotj.settings.startup_map)
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, lotj.settings.startup_chat)
    debugc("lotj-ui finished")
    raiseEvent("lotjUiLoaded")
  ]])
end

function lotj.setup.teardown()
  debugc("lotj-ui -> teardown")
  for _, killId in ipairs(lotj.setup.eventHandlerKillIds) do
    killAnonymousEventHandler(killId)
  end

  lotj.mapper.teardown()
  lotj.layout.teardown()
  lotj = nil
  debugc("lotj-ui -> exited")
end

lotj.setup.registerEventHandler("sysLoadEvent", function()
  doSetup()
end)

lotj.setup.registerEventHandler("sysInstallPackage", function(_, pkgName)
  --Check if the generic_mapper package is installed and if so uninstall it
  if table.contains(getPackages(),"generic_mapper") then
    uninstallPackage("generic_mapper")
    tempTimer(1, [[uninstallPackage("generic_mapper")]])
  end

  if pkgName ~= "@PKGNAME@" then return end
  sendGMCP("Core.Supports.Set", "[\"Ship 1\"]")
  sendGMCP("Core.Supports.Set", "[\"Galaxy 1\"]")
  doSetup()
end)

lotj.setup.registerEventHandler("sysUninstallPackage", function(_, pkgName)
  if pkgName ~= "@PKGNAME@" then return end
  lotj.setup.teardown()
end)

lotj.setup.registerEventHandler("sysProtocolEnabled", function(_, protocol)
  if protocol == "GMCP" then
    sendGMCP("Core.Supports.Set", "[\"Ship 1\"]")
    sendGMCP("Core.Supports.Set", "[\"Galaxy 1\"]")
  end
end)
