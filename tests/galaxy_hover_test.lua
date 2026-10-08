-- Run with Lua 5.1 from the repository root. No profile, network, or native UI is used.
-- Native movie state follows Mudlet Host::setMovie and Qt QLabel::setPixmap:
-- replacing the display retains the QMovie and does not pause its playback.
local function expect(value, message) assert(value, message) end
local function widget()
  return {
    visible=false,
    setStyleSheet=function() end,
    setFontSize=function() end,
    show=function(self) self.visible=true end,
    hide=function(self) self.visible=false end,
    raise=function(self) self.raised=true end,
    raiseAll=function(self) self.raised=true end,
    adjustSize=function() end,
    get_x=function() return 100 end,
    get_y=function() return 100 end,
    get_width=function() return 32 end,
    get_height=function() return 32 end,
    setBackgroundImage=function(self, path) self.background=path; self.movie=nil end,
    setMovie=function(self, path)
      self.nativeMovie=self.nativeMovie or {}
      self.nativeMovie.path=path
      self.nativeMovie.running=true
      self.movie=path
      return true
    end,
    pauseMovie=function(self)
      if not self.movie then return nil, 'no movie found at label' end
      self.nativeMovie.running=false
      return true
    end,
    setOnEnter=function(self, fn) self.enter=fn end,
    setOnLeave=function(self, fn) self.leave=fn end,
  }
end
local coords
Geyser={Label={new=function() coords=widget(); return coords end}}
function getMudletHomeDir() return '/fake-profile' end
function getFont() return 'TestFont' end
function getFontSize() return 12 end
function calcFontSize() return 7,14 end
io.exists=function() return false end
lotj={settings={galmap_coords=true}}
dofile(arg[1] or 'src/scripts/galaxy-map/galaxy-map.lua')
local stylePoint
for i=1,100 do
  local name,value=debug.getupvalue(lotj.galaxyMap.drawSystems,i)
  if not name then break end
  if name=='stylePoint' then stylePoint=value; break end
end
assert(stylePoint, 'stylePoint helper not found')
local cases={
 {name='custom dot with coordinates enabled', manual=true, enabled=true},
 {name='custom dot with coordinates disabled', manual=true, enabled=false},
 {name='custom PNG with coordinates enabled', manual=true, enabled=true, image='example.png'},
 {name='custom PNG with coordinates disabled', manual=true, enabled=false, image='example.png'},
 {name='public PNG keeps its visible name', manual=false, enabled=true, image='example.png'},
 {name='custom non-PNG image keeps its hover name', manual=true, enabled=true, image='example.gif'},
 {name='initial styling without a name label', manual=false, enabled=true, image='example.png', noLabel=true},
}
local failures=0
for _,case in ipairs(cases) do
 local ok,err=pcall(function()
  lotj.settings.galmap_coords=case.enabled
  local point,label=widget(),widget()
  label.visible=not case.manual
  local nameLabel=label
  if case.noLabel then nameLabel=nil end
  stylePoint(point,'TestGovernment',false,case.image,32,case.manual,nameLabel,10,20)
  expect(not coords.visible,'coordinates should start hidden')
  point.enter()
  if case.manual then expect(label.visible and label.raised,'custom name must appear and be raised') end
  expect(coords.visible==case.enabled,'coordinates must respect the setting')
  if case.image=='example.png' then expect(point.movie=='example_hover.gif' and point.nativeMovie.running,'PNG animation must start') end
  point.leave()
  expect(not coords.visible,'coordinates must hide on leave')
  if case.manual then expect(not label.visible,'custom name must hide on leave')
  elseif not case.noLabel then expect(label.visible,'public name must stay visible') end
  if case.image=='example.png' then
    expect(point.background=='example.png' and point.movie==nil,'static image must be restored')
    expect(not point.nativeMovie.running,'retained animation must be paused on leave')
    local retainedMovie=point.nativeMovie
    -- Repeated visits must resume playback and pause the same cached movie again.
    for visit=1,3 do
      point.enter()
      expect(point.movie=='example_hover.gif' and point.nativeMovie.running,'animation must resume on another visit')
      expect(point.nativeMovie==retainedMovie,'another visit must reuse the retained movie')
      point.leave()
      expect(point.movie==nil and not point.nativeMovie.running,'animation must pause after every visit')
    end
  end
 end)
 print((ok and 'PASS ' or 'FAIL ')..case.name)
 if not ok then failures=failures+1; print('  '..err) end
end
print((#cases-failures)..'/'..#cases..' hover scenarios passed')
os.exit(failures==0 and 0 or 1)
