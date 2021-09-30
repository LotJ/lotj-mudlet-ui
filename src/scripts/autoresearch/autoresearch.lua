-- Based on AutoResearch script by @ZakattackLOTJ

lotj = lotj or {}
lotj.autoResearch = lotj.autoResearch or {}

function lotj.autoResearch.log(text, precedingNewline)
  if precedingNewline then
    echo("\n")
  end
  cecho("[<cyan>LOTJ AutoResearch<reset>] "..text.."\n")
end

local subcommands = {{
  args = {"start"},
  action = function()
    lotj.autoResearch.enabled = true
    lotj.autoResearch.researchList = {}
    lotj.autoResearch.log("Research list cleared.")

    enableTrigger("autoresearch.grabSkills")
    lotj.autoResearch.log("Retrieving research list...")
    send("practice", false)
  end,
  helpText = "Get the practice list and automatically begin researching anything eligible for it. Must be in a library."
},{
  args = {"next"},
  action = function()
    if #(lotj.autoResearch.researchList or {}) == 0 then
      lotj.autoResearch.log("Research list empty.")
      lotj.autoResearch.enabled = false
      return
    end
    
    table.remove(lotj.autoResearch.researchList, 1)
    expandAlias("autoresearch continue", false)
  end,
  helpText = "Resume researching the first skill in the current autoresearch list."
},{
  args = {"continue"},
  action = function()
    if #(lotj.autoResearch.researchList or {}) == 0 then
      lotj.autoResearch.log("Research list empty.")
      lotj.autoResearch.enabled = false
      return
    end
    
    local current = lotj.autoResearch.initialCount - #lotj.autoResearch.researchList + 1
    lotj.autoResearch.log(current.."/"..lotj.autoResearch.initialCount..": Researching "..lotj.autoResearch.researchList[1].."...")
    send("research "..lotj.autoResearch.researchList[1], false)
  end,
  helpText = "Skip to the next skill in the autoresearch list and begin researching it."
},{
  args = {"stop"},
  action = function()
    lotj.autoResearch.enabled = false
    lotj.autoResearch.researchList = {}
    lotj.autoResearch.log("Research list cleared.")
  end,
  helpText = "Clear the autoresearch list and disable triggers for continuing automatically."
}}

function lotj.autoResearch.command(args)
  processCommand("autoresearch", subcommands, args)
end