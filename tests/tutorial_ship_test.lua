-- Run from the repository root with Lua 5.1.
-- args: source-root, bundled mudlet-lua/lua directory.
-- UI methods are mocked; panel and tutorial callbacks execute unchanged.
local root=arg[1] or '.'
local library=assert(arg[2], 'provide the bundled Mudlet Lua library directory')
dofile(library..'/TableUtils.lua')
local events, widgets, timers = {}, {}, {}
local count, nextButton, prevButton, endButton = 0
local function widget(options)
  local w=options or {}
  count=count+1
  w.name=w.name or 'test_widget_'..count
  w.hidden=false
  w.setStyleSheet=function(self,s) self.stylesheet=s end
  w.setFontSize=function(self,size) self.fontSize=size end
  w.setAlignment=function(self,a) self.alignment=a end
  w.show=function(self) self.hidden=false end
  w.hide=function(self) self.hidden=true end
  w.raise=function() end
  w.raiseAll=function() end
  w.move=function(self,x,y) self.x=x or self.x; self.y=y or self.y end
  w.resize=function(self,width,height) self.width=width or self.width; self.height=height or self.height end
  w.get_width=function() return 500 end
  w.get_height=function() return 40 end
  w.echo=function(self,message) self.message=tostring(message) end
  w.clear=function(self) self.message='' end
  w.setCursor=function(self,cursor) self.cursor=cursor end
  w.flash=function() end
  w.setClickCallback=function(self,fn)
    self.click=fn
    if self.name:match('_next$') then nextButton=self end
    if self.name:match('_prev$') then prevButton=self end
    if self.name:match('_end$') then endButton=self end
  end
  widgets[w.name]=w
  return w
end
Geyser={Label={new=function(_,options) return widget(options) end}}
Geyser.Gauge={new=function(_,options)
  local w=widget(options)
  w.front,w.back,w.text=widget(),widget(),widget()
  w.setValue=function(self,current,max,message) self.current=current; self.max=max; self.message=message end
  return w
end}
function getMudletHomeDir() return '/fictional-profile' end
function getFont() return 'TestFont' end
function getFontSize() return 12 end
function calcFontSize() return 7,14 end
function setBorderBottom(value) borderBottom=value end
function cecho() end
function cechoLink() end
function table.save() end
function deleteLabel(name) widgets[name]=nil end
function tempTimer(delay,callback) timers[#timers+1]=callback; return #timers end
function killTimer(id) timers[id]=false; return true end
function raiseEvent(event)
  for _,fn in ipairs(events[event] or {}) do fn() end
end
function gmcpVarByPath(path)
  local value=gmcp
  for key in path:gmatch('[^.]+') do if not value then return nil end; value=value[key] end
  return value
end
lotj={layout={lowerInfoPanelHeight=40,shipOverlayHeight=40,lowerInfoPanel=widget(),shipOverlay=widget(),upperContainer=widget(),lowerContainer=widget(),selectTab=function() end},setup={}}
function lotj.setup.registerEventHandler(event,callback)
  events[event]=events[event] or {}; table.insert(events[event],callback)
end
gmcp={Char={Vitals={hp=50,maxHp=100,wimpy=0,move=80,maxMove=100,mana=50,maxMana=100},Enemy={},Chat={}}}
dofile(root..'/src/scripts/info-panel/info-panel.lua')
lotj.infoPanel.setup()
dofile(root..'/src/scripts/setup/tutorial.lua')
local observedShipEvents=0
lotj.setup.registerEventHandler('gmcp.Ship.Info',function() observedShipEvents=observedShipEvents+1 end)
local function expect(value,message) assert(value,message) end
local function ship(energy,x)
  return {shield=45,maxShield=100,hull=70,maxHull=100,energy=energy,maxEnergy=100,piloting=true,speed=20,maxSpeed=100,posX=x,posY=800,posZ=700}
end
local function goToShipTutorial()
  lotj.tutorial.run()
  for step=2,8 do nextButton.click() end
end
-- On foot: demonstration values show only in the panel, without creating GMCP.Ship.
goToShipTutorial()
expect(gmcp.Ship==nil,'preview must not create live ship state')
expect(lotj.infoPanel.shipEnergyGauge.current==60,'preview must render demonstration gauges')
expect(not lotj.layout.shipOverlay.hidden,'preview must show the overlay while on foot')
expect(observedShipEvents==0,'preview must not emit fake GMCP events to other consumers')
local labelled=false
for _,w in pairs(widgets) do if not w.hidden and (w.message or ''):find('Tutorial preview: example ship values.',1,true) then labelled=true end end
expect(labelled,'preview must be labelled as example values')
endButton.click()
expect(gmcp.Ship==nil and lotj.infoPanel.shipPreview==nil,'ending on foot must leave live ship state absent')
expect(lotj.layout.shipOverlay.hidden,'ending on foot must hide the demonstration overlay')
-- Aboard: keep the real table identity and render the latest server update after ending.
gmcp.Ship={Info=ship(12,900)}
local realInfo=gmcp.Ship.Info
raiseEvent('gmcp.Ship.Info')
goToShipTutorial()
expect(gmcp.Ship.Info==realInfo and realInfo.energy==12,'tutorial must leave live values and table identity intact')
expect(lotj.infoPanel.shipEnergyGauge.current==60,'panel must still render the tutorial preview')
gmcp.Ship.Info.energy=11; gmcp.Ship.Info.posX=901
raiseEvent('gmcp.Ship.Info')
expect(realInfo.energy==11 and lotj.infoPanel.shipEnergyGauge.current==60,'live updates must survive without replacing demonstration values')
endButton.click()
expect(gmcp.Ship.Info==realInfo and realInfo.posX==901,'cleanup must retain the latest live ship data')
expect(lotj.infoPanel.shipEnergyGauge.current==11 and not lotj.layout.shipOverlay.hidden,'cleanup must immediately render the latest live state')
-- Backward navigation and rerunning while previewing must release old preview state.
goToShipTutorial()
prevButton.click()
expect(lotj.infoPanel.shipPreview==nil and lotj.infoPanel.shipEnergyGauge.current==11,'going back out of ship intro must end the preview')
nextButton.click()
lotj.tutorial.run()
expect(lotj.infoPanel.shipPreview==nil and gmcp.Ship.Info==realInfo,'rerunning must clean up old preview without touching GMCP')
for step=2,12 do nextButton.click() end
expect(lotj.infoPanel.shipPreview.piloting==false and realInfo.piloting==true,'pilot demo must not change real piloting status')
nextButton.click()
expect(lotj.infoPanel.shipPreview.piloting==true,'active pilot demo must still render')
nextButton.click()
nextButton.click() -- leaving speed/coordinate preview for map tab
expect(lotj.infoPanel.shipPreview==nil and gmcp.Ship.Info==realInfo,'forward navigation must release the preview')
-- Landing during a tutorial must be reflected on completion rather than restored from a stale snapshot.
goToShipTutorial()
gmcp.Ship.Info={}
raiseEvent('gmcp.Ship.Info')
endButton.click()
expect(next(gmcp.Ship.Info)==nil and lotj.layout.shipOverlay.hidden,'ending after landing must retain the current empty ship state')
goToShipTutorial()
lotj.tutorial.teardown()
expect(lotj.infoPanel.shipPreview==nil and lotj.tutorial.activeElements==nil,'teardown must release the preview and tutorial widgets')
print('PASS tutorial preview isolation, status rendering, literal state preservation, live updates, navigation, rerun, and teardown')
