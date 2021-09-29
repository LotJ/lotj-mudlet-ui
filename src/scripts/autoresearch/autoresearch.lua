lotj = lotj or {}
lotj.autoResearch = lotj.autoResearch or {}

function lotj.autoResearch.log(text, precedingNewline)
  if precedingNewline then
    echo("\n")
  end
  cecho("[<cyan>LOTJ AutoResearch<reset>] "..text.."\n")
end

function lotj.autoResearch.command(args)
  argList = splitargs(args)

  if #argList == 1 and argList[1] == "start" then
    lotj.autoResearch.enabled = true
    lotj.autoResearch.researchList = {}
    lotj.autoResearch.log("Research list cleared.")

    enableTrigger("autoresearch.grabSkills")
    lotj.autoResearch.log("Retrieving research list...")
    send("practice", false)

  elseif #argList == 1 and argList[1] == "next" then
    if #(lotj.autoResearch.researchList or {}) == 0 then
      lotj.autoResearch.log("Research list empty.")
      lotj.autoResearch.enabled = false
      return
    end
    
    table.remove(lotj.autoResearch.researchList, 1)
    expandAlias("autoresearch continue", false)

  elseif #argList == 1 and argList[1] == "continue" then
    if #(lotj.autoResearch.researchList or {}) == 0 then
      lotj.autoResearch.log("Research list empty.")
      lotj.autoResearch.enabled = false
      return
    end
    
    local current = lotj.autoResearch.initialCount - #lotj.autoResearch.researchList + 1
    lotj.autoResearch.log(current.."/"..lotj.autoResearch.initialCount..": Researching "..lotj.autoResearch.researchList[1].."...")
    send("research "..lotj.autoResearch.researchList[1], false)

  elseif #argList == 1 and argList[1] == "stop" then
    lotj.autoResearch.enabled = false
    lotj.autoResearch.researchList = {}
    lotj.autoResearch.log("Research list cleared.")

  else
    lotj.autoResearch.log("AutoResearch Command List\n")
    cecho([[
<yellow>autoresearch start<reset>

Get the practice list and automatically begin researching anything eligible for it. Must be in a library.

<yellow>autoresearch continue<reset>

Resume researching the first skill in the current autoresearch list.

<yellow>autoresearch next<reset>

Skip to the next skill in the autoresearch list and begin researching it.

<yellow>autoresearch stop<reset>

Clear the autoresearch list and disable triggers for continuing automatically.
]])
  end
end