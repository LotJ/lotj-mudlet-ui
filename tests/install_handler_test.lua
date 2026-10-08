-- Run from the repository root with Lua 5.1. No native package installation occurs.
local root=arg[1] or '.'
local handlers, removals, timers = {}, {}, {}
function debugc() end
function registerAnonymousEventHandler(event, callback) handlers[event]=callback; return event end
function table.contains(t,value) for _,v in pairs(t) do if v==value then return true end end; return false end
function getPackages() return {'lotj-ui','generic_mapper','mudlet-base-ui','example-addon'} end
function uninstallPackage(name) table.insert(removals,name) end
function tempTimer(delay,code) table.insert(timers,code); return #timers end
function sendGMCP() end
local file=assert(io.open(root..'/src/scripts/setup/setup.lua','r'))
local source=file:read('*all'); file:close()
assert(loadstring(source:gsub('@PKGNAME@','lotj-ui')))()
handlers.sysInstallPackage('sysInstallPackage','example-addon')
assert(#removals==0 and #timers==0, 'unrelated installs must not remove or schedule removal of any package')
-- Stub the local setup callback, retaining the actual package ownership guard and conflict cleanup.
local install=handlers.sysInstallPackage
local replaced=false
for i=1,20 do
  local name=debug.getupvalue(install,i)
  if not name then break end
  if name=='doSetup' then debug.setupvalue(install,i,function() end); replaced=true; break end
end
assert(replaced,'setup callback not found')
install('sysInstallPackage','lotj-ui')
assert(#removals==2 and removals[1]=='generic_mapper' and removals[2]=='mudlet-base-ui', 'lotj-ui installs must still clean up conflicting packages')
assert(#timers==2,'delayed conflict cleanup must remain available for lotj-ui installs')
local teardownOrder={}
function killAnonymousEventHandler() end
lotj.tutorial={teardown=function() table.insert(teardownOrder,'tutorial') end}
lotj.mapper={teardown=function() table.insert(teardownOrder,'mapper') end}
lotj.layout={teardown=function() table.insert(teardownOrder,'layout') end}
handlers.sysUninstallPackage('sysUninstallPackage','example-addon')
assert(#teardownOrder==0, 'unrelated uninstalls must leave this UI intact')
handlers.sysUninstallPackage('sysUninstallPackage','lotj-ui')
assert(table.concat(teardownOrder,',')=='tutorial,mapper,layout' and lotj==nil, 'package teardown must clean up tutorial previews before disposing the UI')
print('PASS unrelated package protection, existing conflict cleanup, and tutorial teardown wiring')
