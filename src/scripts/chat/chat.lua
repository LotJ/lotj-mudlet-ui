lotj = lotj or {}
lotj.chat = lotj.chat or {}

function lotj.chat.setup()
  for keyword, contentsContainer in pairs(lotj.layout.lowerRightTabData.contents) do
    if keyword == "settings" then
      lotj.chat[keyword] = Geyser.Container:new({
        x = "1%", y = "1%",
        width = "98%", height = "98%",
      }, contentsContainer)
    else
      lotj.chat[keyword] = Geyser.MiniConsole:new({
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
function lotj.chat.debugLog(type)
  if not (lotj.settings.debugMode and lotj.chat["debug"]) then return end
  lotj.chat["debug"]:cecho("<reset><green>"..getTime(true, "hh:mm:ss").."<reset> "..type.."\n")
  if gmcp[type] then
    lotj.chat["debug"]:display(gmcp[type])
  end
  lotj.chat["debug"]:cecho("<reset>\n")
end
