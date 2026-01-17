lotj.chat.routeMessage("broadcast", true)
if lotj.settings.notif_broadcast then
    lotj.layout.markTabUnread(lotj.layout.lowerRightTabData, "broadcast")
end
