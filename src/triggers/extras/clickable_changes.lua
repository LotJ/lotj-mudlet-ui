if lotj.settings.clickable_changes then
  local targetNumber = matches[2]
  selectString(matches[2], 1)
  setUnderline(true)
  setLink([[send("changes ]] .. targetNumber .. [[")]], "changes ".. targetNumber)
  resetFormat()
end
