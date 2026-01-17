lotj.chat.routeMessage("commnet")
if lotj.settings.notif_commnet then
    lotj.layout.markTabUnread(lotj.layout.lowerRightTabData, "commnet")
end

-- Track commnet messages to potentially squash a redundant translation
-- message on the next line
lotj.chat.commnetLastChannel = matches[2]
lotj.chat.commnetLastMessage = matches[3]
