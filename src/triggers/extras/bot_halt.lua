if lotj.settings.bot_resume then
  registerNamedEventHandler("@PKGNAME@", "@PKGNAME@_bot_halt_trigger", "sysDataSendRequest", function(eventName, command)
    if command:trim():lower() == "afk" then 
      lotj.settings.bot_resumeAction = nil
      lotj.debugLog("AFK command not used to populate lotj.settings.bot_resumeAction,")
      return false
    end
    lotj.settings.bot_resumeAction = command
    lotj.debugLog("lotj.settings.bot_resumeAction: "..command)
  end, true)

  tempTimer(180, function()
    if deleteNamedEventHandler("@PKGNAME", "@PKGNAME@_bot_halt_trigger") then
      lotj.debugLog("@PKGNAME@_bot_halt_trigger expired.")
    end
  end)
end
