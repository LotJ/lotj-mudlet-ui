if lotj.settings.bot_resume and lotj.settings.bot_resumeAction then
  if lotj.afk then
    send("afk")
  end
  sendAll("bot start", lotj.settings.bot_resumeAction)
  lotj.settings.bot_resumeAction = nil
end
