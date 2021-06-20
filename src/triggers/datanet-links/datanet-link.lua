for i = 1, #matches, 4 do
  selectString(matches[i], 1)
  setUnderline(true)
  setLink([[send("datanet ]] .. matches[i] .. [[")]], "Datanet link: " .. matches[i])
end