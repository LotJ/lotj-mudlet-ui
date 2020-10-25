registerAnonymousEventHandler("sysLoadEvent", function()
  registerAnonymousEventHandler("msdp.COMMANDS", function()
    local msdpVars = {}

    table.insert(msdpVars, "HEALTH")
    table.insert(msdpVars, "HEALTHMAX")
    table.insert(msdpVars, "WIMPY")
    table.insert(msdpVars, "MOVEMENT")
    table.insert(msdpVars, "MOVEMENTMAX")
    table.insert(msdpVars, "MANA")
    table.insert(msdpVars, "MANAMAX")
    
    table.insert(msdpVars, "OPPONENTNAME")
    table.insert(msdpVars, "OPPONENTHEALTH")
    table.insert(msdpVars, "OPPONENTHEALTHMAX")
    
    table.insert(msdpVars, "COMMCHANNEL")
    table.insert(msdpVars, "COMMENCRYPT")
    table.insert(msdpVars, "OOCLIMIT")
    
    table.insert(msdpVars, "ROOMNAME")
    table.insert(msdpVars, "ROOMEXITS")
    table.insert(msdpVars, "ROOMVNUM")
    
    table.insert(msdpVars, "PILOTING")
    table.insert(msdpVars, "SHIPSPEED")
    table.insert(msdpVars, "SHIPMAXSPEED")
    table.insert(msdpVars, "SHIPHULL")
    table.insert(msdpVars, "SHIPMAXHULL")
    table.insert(msdpVars, "SHIPSHIELD")
    table.insert(msdpVars, "SHIPMAXSHIELD")
    table.insert(msdpVars, "SHIPENERGY")
    table.insert(msdpVars, "SHIPMAXENERGY")
    table.insert(msdpVars, "SHIPSYSX")
    table.insert(msdpVars, "SHIPSYSY")
    table.insert(msdpVars, "SHIPSYSZ")
    table.insert(msdpVars, "SHIPGALX")
    table.insert(msdpVars, "SHIPGALY")
    table.insert(msdpVars, "SHIPSYSNAME")
    
    for _, varName in ipairs(msdpVars) do
      sendMSDP("REPORT", varName)
    end
  end)
end)
