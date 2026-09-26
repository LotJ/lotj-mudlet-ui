if not lotj.settings.clickable_mail then return end

lotj.settings.clickable_mail_sender = matches.sender

lotj.settings.clickable_mailRegexTrigger = tempRegexTrigger(
  [[^(?<id>\d+)\s*\|\s*(?<sender>.+?)\s*\|\s*(?<recipient>.+?)\s*\|\s(?<subject>.+?)$|^(?<empty>)$]],
  function()
    if matches.empty then
      return false
    end
    local targetNumber = matches.id
    selectString(matches.subject:trim(), 1)
    setUnderline(true)
    if lotj.settings.clickable_mail_sender == "SENDER" then
      setLink([[send("mail read ]] .. targetNumber .. [[")]], "mail read ".. targetNumber)
    else
      setLink([[send("note read ]] .. targetNumber .. [[")]], "note read ".. targetNumber)
    end
    resetFormat()
    return true
  end,
  1
)
