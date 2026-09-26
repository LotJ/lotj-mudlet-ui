if lotj.settings.ponder then
  if lotj.afk then
    lotj.debugLog("Tried to send ponder but lotj.afk set.")
    return
  end
  send("Ponder")
end
