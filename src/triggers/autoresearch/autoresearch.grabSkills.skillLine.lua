for str in matches[1]:gmatch("[^%%]+%s*") do
  str = str:gsub('^%s*(.-)%s*$', '%1') -- Trim whitespace
  local skill, pct = str:match("(.*)%s+([0-9]+)")
  if skill then
    skill = skill:gsub('^%s*(.-)%s*$', '%1') -- Trim whitespace
    pct = tonumber(pct)
    
    if pct < 90 then
      if skill == "research" then
        -- Always do research first if it's in the list
        table.insert(lotj.autoResearch.researchList, 1, skill)
      else
        table.insert(lotj.autoResearch.researchList, skill)
      end
    end
  end
end

setTriggerStayOpen("autoresearch.grabSkills", 1)