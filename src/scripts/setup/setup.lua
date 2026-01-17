---@diagnostic disable: redundant-parameter
lotj = lotj or {}
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

local DKJSON_PATH = getMudletHomeDir() .. "/dkjson.lua"
local DKJSON_URL  = "https://raw.githubusercontent.com/LuaDist/dkjson/refs/heads/master/dkjson.lua"

function doSetup()
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

  -- Settings tab setup after chat setup
  lotj.settings.setupTab()

  -- Then set our UI default view
  lotj.layout.selectTab(lotj.layout.upperRightTabData, "map")
  lotj.layout.selectTab(lotj.layout.lowerRightTabData, "all")

  lotj.setup.registerEventHandler("gmcp.Char", debugChar)
  lotj.setup.registerEventHandler("gmcp.Room", debugRoom)
  lotj.setup.registerEventHandler("gmcp.Ship", debugShip)
  lotj.setup.registerEventHandler("gmcp.External", debugExternal)
  lotj.setup.registerEventHandler("gmcp.Client", debugClient)


  -- Manually kick off all GMCP event handlers, since GMCP data would not have changed
  -- since loading the UI.
  for _, func in ipairs(lotj.setup.gmcpEventHandlerFuncs) do
    func()
  end

  raiseEvent("lotjUiLoaded")
end

local function ensureDepsAndSetup()
  if io.exists(DKJSON_PATH) then
    doSetup()
    return
  end

  -- One-shot handler for dkjson finishing download
  local killId
  killId = registerAnonymousEventHandler("sysDownloadDone", function(_, filename)
    if filename ~= DKJSON_PATH then return end
    killAnonymousEventHandler(killId)
    doSetup()
  end)

  downloadFile(DKJSON_PATH, DKJSON_URL)
end

local function teardown()
  for _, killId in ipairs(lotj.setup.eventHandlerKillIds) do
    killAnonymousEventHandler(killId)
  end

  lotj.mapper.teardown()
  lotj.layout.teardown()
  lotj = nil
end

lotj.setup.registerEventHandler("sysLoadEvent", function()
  ensureDepsAndSetup()
end)

lotj.setup.registerEventHandler("sysInstallPackage", function(_, pkgName)
  --Check if the generic_mapper package is installed and if so uninstall it
  if table.contains(getPackages(),"generic_mapper") then
    uninstallPackage("generic_mapper")
  end
  
  if pkgName ~= "lotj-ui" then return end
  sendGMCP("Core.Supports.Set", "[\"Ship 1\"]")
  ensureDepsAndSetup()
end)

lotj.setup.registerEventHandler("sysUninstallPackage", function(_, pkgName)
  if pkgName ~= "lotj-ui" then return end
  teardown()
end)

lotj.setup.registerEventHandler("sysProtocolEnabled", function(_, protocol)
  if protocol == "GMCP" then
    sendGMCP("Core.Supports.Set", "[\"Ship 1\"]")
  end
end)
