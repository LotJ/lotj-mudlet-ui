if lotj.chat.commnetLastChannel == matches[2] and lotj.chat.commnetLastMessage == matches[3] then
  deleteLine()
  echo(" (Translated)")
else
  lotj.chat.routeMessage("commnet")
end
