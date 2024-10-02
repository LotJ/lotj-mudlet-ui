if lotj.autoResearch.enabled then
  echo("\n")
  lotj.autoResearch.initialCount = #(lotj.autoResearch.researchList or {})
  if lotj.autoResearch.initialCount == 0 then
    lotj.autoResearch.enabled = false
    lotj.autoResearch.log("Nothing to research.")
    return
  end
  lotj.autoResearch.log("Don't forget to 'bot start' if you won't be monitoring your screen as this runs.")
  expandAlias("autoresearch continue", false)
else
  lotj.autoResearch.log("Type 'autoresearch start' to start researching all skills below 90%.", true)
end