lotj.chat.routeMessage("ooc")
lotj.layout.markTabUnread(lotj.layout.lowerRightTabData, "ooc")

deleteLine()                            -- delete the current line
moveCursor(0,getLineNumber()-1)         -- move the cursor back one line

if getCurrentLine() == "" then
  deleteLine()                            -- delete the previous line now
end
