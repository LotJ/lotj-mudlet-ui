lotj.chat.routeMessage("ooc")
if lotj.settings.notif_ooc then
  lotj.layout.markTabUnread(lotj.layout.lowerRightTabData, "ooc")
end

if lotj.settings.gag_ooc then
  deleteLine()                            -- delete the current line
  moveCursor(0,getLineNumber()-1)         -- move the cursor back one line

  if getCurrentLine() == "" then
    deleteLine()                            -- delete the previous line now
  end
end
