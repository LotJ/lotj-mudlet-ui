lotj = lotj or {}
lotj.setup = lotj.setup or {}
lotj.setup.eventHandlerKillIds = lotj.setup.eventHandlerKillIds or {}
lotj.setup.gmcpEventHandlerFuncs = lotj.setup.gmcpEventHandlerFuncs or {}

function lotj.setup.registerEventHandler(eventName, func)
  local killId = registerAnonymousEventHandler(eventName, func)
  table.insert(lotj.setup.eventHandlerKillIds, killId)

  -- A little bit hacky, but we want to run all GMCP event handlers when we finish
  -- doing initial setup to populate the UI.
  if eventName:find("gmcp\.") then
    table.insert(lotj.setup.gmcpEventHandlerFuncs, func)
  end
end

local function setup()
  -- Layout has to be created first
  lotj.layout.setup()

  -- Then everything else in no particular order
  lotj.chat.setup()
  lotj.galaxyMap.setup()
  lotj.infoPanel.setup()
  lotj.mapper.setup()
  lotj.systemMap.setup()
  lotj.comlinkInfo.setup()

  -- Then set our UI default view
  lotj.layout.selectTab(lotj.layout.upperRightTabData, "map")
  lotj.layout.selectTab(lotj.layout.lowerRightTabData, "all")

  -- Manually kick off all GMCP event handlers, since GMCP data would not have changed
  -- since loading the UI.
  for _, func in ipairs(lotj.setup.gmcpEventHandlerFuncs) do
    func()
  end

  raiseEvent("lotjUiLoaded")
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
  setup()
end)

lotj.setup.registerEventHandler("sysInstallPackage", function(_, pkgName)
  --Check if the generic_mapper package is installed and if so uninstall it
  if table.contains(getPackages(),"generic_mapper") then
    uninstallPackage("generic_mapper")
  end
  
  if pkgName ~= "lotj-ui" then return end
  sendGMCP("Core.Supports.Set", "[\"Ship 1\"]")
  setup()
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
