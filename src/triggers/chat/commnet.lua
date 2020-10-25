lotj.chat.routeMessage("commnet")

-- Track commnet messages to potentially squash a redundant translation
-- message on the next line
lotj.chat.commnetLastChannel = matches[2]
lotj.chat.commnetLastMessage = matches[3]
