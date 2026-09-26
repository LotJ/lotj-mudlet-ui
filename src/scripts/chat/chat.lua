lotj = lotj or {}
lotj.chat = lotj.chat or {}

local backgroundTabStyle = [[
  background-color: #000000;
  border: 1px solid #00aaaa;
  margin: 2px 0px 0px 0px;
  font-family: ]] .. getFont() .. [[;
]]

function lotj.chat.setup()
  for keyword, contentsContainer in pairs(lotj.layout.lowerRightTabData.contents) do
    if keyword == "settings" then
      lotj.chat[keyword] = Geyser.Container:new({
        name = "lotj.chat.container_"..keyword,
        x = "1%", y = "1%",
        width = "98%", height = "98%",
      }, contentsContainer)
    else
      lotj.chat[keyword] = Geyser.MiniConsole:new({
        name = "lotj.chat.miniConsole_"..keyword,
        x = "1%", y = "1%",
        width = "98%",
        height = "98%",
        autoWrap = false,
        color = "black",
        scrollBar = true,
        font = getFont(),
        fontSize = getFontSize(),
      }, contentsContainer)

    -- Set the wrap at a few characters short of the full width to avoid the scroll bar showing over text
    local charsPerLine = lotj.chat[keyword]:getColumnCount()-3
    lotj.chat[keyword]:setWrap(charsPerLine)
      lotj.setup.registerEventHandler("sysWindowResizeEvent", function()
        charsPerLine = lotj.chat[keyword]:getColumnCount()-3
        lotj.chat[keyword]:setWrap(charsPerLine)
      end)
    end
  end
  if lotj.settings.debugMode and lotj.settings.debugconsole then
    lotj.chat["debug"]:enableCommandLine()
    lotj.chat["debug"]:setCmdLineStyleSheet(backgroundTabStyle)

    local function run_lua_code(text)
      lotj.chat["debug"]:cecho("<reset><ansi_yellow>"..text..'<reset>\n')
      local f, e = loadstring("return "..text)
      if not f then
        f, e = assert(loadstring(text))
      end

      local r =
        function(...)
          if not table.is_empty({...}) then
            lotj.chat["debug"]:display(...)
          end
        end
      r(f())
    end

    lotj.chat["debug"]:setCmdAction(run_lua_code)
  end
end

function lotj.chat.routeMessage(type, skipAllTab)
  selectCurrentLine()
  copy()
  lotj.chat[type]:cecho("<reset>"..getTime(true, "hh:mm:ss").." ")
  lotj.chat[type]:appendBuffer()

  if not skipAllTab then
    lotj.chat.all:cecho("<reset>"..getTime(true, "hh:mm:ss").." ")
    lotj.chat.all:appendBuffer()
  end
end

-- Echo GMCP[`type`] to the "Debug" tab  
-- Reserved words are Char, Room, Ship, External, Client
function lotj.chat.debugLog(type_)
  if not (lotj.settings.debugMode and lotj.chat["debug"]) then return end
  if table.contains({"Char", "Room", "External", "Client", "Ship", "Galaxy"}, type_) and not lotj.settings.debugGMCP_out then return end
  lotj.chat["debug"]:cecho("<reset><green>"..getTime(true, "hh:mm:ss").."<reset> "..type_.."\n")
  if gmcp[type_] and lotj.settings.debugGMCP_out then
    lotj.chat["debug"]:display(gmcp[type_])
  end
  lotj.chat["debug"]:cecho("<reset>")
end

lotj.logDebug = lotj.chat.debugLog
lotj.debugLog = lotj.chat.debugLog
