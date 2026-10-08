-- Run from the repository root with Lua 5.1.
-- args: source-root (or .), bundled mudlet-lua/lua directory, empty temporary fixture directory.
local root = arg[1] or '.'
local library = assert(arg[2], 'provide the bundled Mudlet Lua library directory')
local fixtures = assert(arg[3], 'provide an empty temporary fixture directory')
local function read(path)
  local file = assert(io.open(path, 'r'))
  local text = file:read('*all'); file:close(); return text
end
-- Use Mudlet's actual serializer instead of a mock that might hide table merging.
dofile(library..'/TableUtils.lua')
local other = read(library..'/Other.lua')
local start = assert(other:find('\nfunction table.save', 1, true))
local serialization = other:sub(start)
local stop = assert(serialization:find('local functions used for pausing', 1, true))
serialization = serialization:sub(1, assert(serialization:sub(1, stop):match('.*()\n'))-1)
assert(loadstring(serialization))()
local strings = read(library..'/StringUtils.lua')
assert(loadstring(assert(strings:match('(function string:enclose.-\nend)'))))()
local function expect(value, message) assert(value, message) end
local markup, literal = {}, {}
function cecho(text) table.insert(markup, text) end
function echo(text) table.insert(literal, text) end
function getMudletHomeDir() return fixtures end
function gmcpVarByPath() return gmcp.Char.Info.name end
function string.trim(s) return s:match('^%s*(.-)%s*$') end
io.exists = function(path) local f=io.open(path,'r'); if f then f:close(); return true end; return false end
-- Invoke the package's real parser for quoted and optional command arguments.
local util = read(root..'/src/scripts/setup/util.lua')
assert(loadstring(util:sub(1, assert(util:find('local function parseColor',1,true))-1)))()
dofile(root..'/src/scripts/comlink-info/comlink-info.lua')
local pathOne, pathTwo = fixtures..'/comlinkdata_ExampleOne.lua', fixtures..'/comlinkdata_ExampleTwo.lua'
assert(not io.exists(pathOne) and not io.exists(pathTwo) and not io.exists(fixtures..'/comlinkdata_ExampleThree.lua'), 'fixture files already exist; choose an empty temporary directory')
table.save(pathOne, {['Example radio one']={channel=123,encryption=456}})
table.save(pathTwo, {['Example radio two']={channel=789,encryption=101}})
gmcp = {Char={Info={name='ExampleOne'}}}
lotj.comlinkInfo.loadForChar()
expect(lotj.comlinkInfo.comlinks['Example radio one'], 'first load must populate its own table')
expect(_G['Example radio one']==nil, 'saved data must not load into globals')
gmcp.Char.Info.name='ExampleTwo'
lotj.comlinkInfo.loadForChar()
expect(not lotj.comlinkInfo.comlinks['Example radio one'], 'old character records must not carry over')
expect(lotj.comlinkInfo.comlinks['Example radio two'], 'new character records must load')
local current=lotj.comlinkInfo.comlinks
lotj.comlinkInfo.loadForChar()
expect(lotj.comlinkInfo.comlinks==current, 'repeated character events must preserve the current list')
gmcp.Char.Info.name='ExampleThree'
lotj.comlinkInfo.loadForChar()
expect(next(lotj.comlinkInfo.comlinks)==nil, 'a character without a file must start empty')
lotj.comlinkInfo.registerComlink('Example radio three','222','333')
local saved={}; table.load(fixtures..'/comlinkdata_ExampleThree.lua',saved)
expect(saved['Example radio three'] and not saved['Example radio two'], 'saving must use only the active character records')
-- Mutators must protect isolation even when they precede a character-change event.
gmcp.Char.Info.name='ExampleTwo'
lotj.comlinkInfo.command('note "Example radio two" "Example note"')
expect(lotj.comlinkInfo.comlinks['Example radio two'].note=='Example note', 'note command must load its character first')
lotj.comlinkInfo.command('note "Example radio two"')
expect(lotj.comlinkInfo.comlinks['Example radio two'].note==nil, 'omitting a note must remove it')
lotj.comlinkInfo.command('note "Example radio two"') -- removing an absent note must be safe
expect(table.concat(markup):find('No note saved for',1,true), 'absent note must have readable feedback')
local writes=0
local actualSave=table.save
table.save=function(...) writes=writes+1; return actualSave(...) end
lotj.comlinkInfo.command('note "Example radio two"')
expect(writes==0, 'no-op note removal must not rewrite the file')
-- Player text must reach echo literally, never become cecho color markup.
lotj.comlinkInfo.comlinks['<red>Example radio']={channel=0,encryption=0}
lotj.comlinkInfo.command('note "<red>Example radio" "<blue>Example note"')
expect(not table.concat(markup):find('<blue>Example note',1,true), 'note text must not become color markup')
expect(table.concat(literal):find('<blue>Example note',1,true), 'note text must print literally')
lotj.comlinkInfo.command('note "<red>Example radio"')
expect(not table.concat(markup):find('<red>Example radio',1,true), 'comlink names must print literally')
gmcp.Char.Info.name=nil
lotj.comlinkInfo.loadForChar()
expect(next(lotj.comlinkInfo.comlinks)==nil, 'unknown character must not retain prior records')
lotj.comlinkInfo.saveForChar()
expect(writes==2, 'unknown character must not save a file')
for _,name in ipairs({'ExampleOne','ExampleTwo','ExampleThree'}) do os.remove(fixtures..'/comlinkdata_'..name..'.lua') end
print('PASS comlink isolation, actual serialization, optional notes, literal output, and no-op saves')
