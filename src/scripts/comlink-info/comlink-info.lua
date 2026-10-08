-- Comlink info script by Johnson
-- Translated to Mudlet by Kbug

lotj = lotj or {}
lotj.comlinkInfo = lotj.comlinkInfo or {}

function lotj.comlinkInfo.setup()
  lotj.comlinkInfo.loadForChar()
  lotj.setup.registerEventHandler("gmcp.Char.Info", lotj.comlinkInfo.loadForChar)
end

function lotj.comlinkInfo.log(text, precedingNewline)
  if precedingNewline then
    echo("\n")
  end
  cecho("[<cyan>LOTJ Comlinks<reset>] "..text.."\n")
end

-- Keep dynamic player text out of cecho's color markup.
local function logComlinkAction(action, name, note, color)
  cecho("<reset>[<cyan>LOTJ Comlinks<reset>] <"..(color or "green")..">"..action.."<white>")
  echo(" '"..name.."'")
  if note then
    echo(": "..note)
  end
  cecho("<reset>\n")
end

function lotj.comlinkInfo.loadForChar()
  local charName = gmcpVarByPath("Char.Info.name")
  if charName == lotj.comlinkInfo.currentChar and lotj.comlinkInfo.comlinks then
    return
  end

  lotj.comlinkInfo.comlinks = {}
  lotj.comlinkInfo.currentChar = charName
  if charName and io.exists(getMudletHomeDir() .. "/comlinkdata_" .. charName .. ".lua") then
    table.load(getMudletHomeDir() .. "/comlinkdata_" .. charName .. ".lua", lotj.comlinkInfo.comlinks)
    if lotj.comlinkInfo.comlinks then
      local comlinkCount = 0
      for _, _ in pairs(lotj.comlinkInfo.comlinks) do
        comlinkCount = comlinkCount+1
      end

      lotj.comlinkInfo.log("Loaded data for "..comlinkCount.." comlinks.")
    end
  end
end

function lotj.comlinkInfo.saveForChar()
  lotj.comlinkInfo.loadForChar()
  local charName = gmcpVarByPath("Char.Info.name")
  if charName then
    table.save(getMudletHomeDir() .. "/comlinkdata_" .. charName .. ".lua", lotj.comlinkInfo.comlinks)
  else
    lotj.comlinkInfo.log("No character name detected for saving comlink data.")
  end
end

function lotj.comlinkInfo.cleanupComlinkName(line)
  line = line:gsub("%(Humming%)", '')
  line = string.trim(line:gsub("%(%d+%)", ''))
  line = line:gsub('"', '')
  line = line:gsub("'", '')
  return line
end

function lotj.comlinkInfo.registerComlink(comlinkName, channel, encryption)
  lotj.comlinkInfo.loadForChar()
  local name = lotj.comlinkInfo.cleanupComlinkName(comlinkName)
  local comlink = { channel = 0, encryption = 0 }
  comlink = lotj.comlinkInfo.comlinks[name] or comlink -- load an existing comlink or make a new one
  if channel ~= nil then -- got a channel
    if comlink.channel ~= channel then -- new channel is different than existing channel
      comlink.channel = tonumber(channel) or 0
    end
  end
  if encryption ~= nil then -- got an encryption
    if comlink.encryption ~= encryption then -- new encryption is different than existing
      comlink.encryption = tonumber(encryption) or 0
    end
  end
  lotj.comlinkInfo.comlinks[name] = comlink -- rip out quotation marks

  lotj.comlinkInfo.saveForChar()
end

local subcommands = {{
  args = {"reset"},
  action = function()
    lotj.comlinkInfo.comlinks = {}
    lotj.comlinkInfo.log("Stored comlink data erased.")
    lotj.comlinkInfo.saveForChar()
  end,
  helpText = "Deletes the stored comlink list."
},{
  args = {"delete", "comlink:string"},
  action = function(name)
    for i, v in pairs(lotj.comlinkInfo.comlinks) do
      -- search by comlink keyword or note keyword
      if string.find(i:lower(), name:lower(), 0, true) or (v.note and (string.find(v.note:lower(), name:lower(), 0, true))) then
        lotj.comlinkInfo.log("Comlink '" .. i .. "' removed from stored comlinks.")
        lotj.comlinkInfo.comlinks[i] = nil
        lotj.comlinkInfo.saveForChar()
        return
      end
    end
    lotj.comlinkInfo.log("Comlink '" .. name .. "' not found in comlinks.")
  end,
  helpText = "Deletes the first comlink matching the specified keyword from the comlink list.\n"..
    "Notice: Will match either the comlink description or the note attached to that comlink."
},{
  args = {"notes"},
  action = function()
    lotj.comlinkInfo.log("Listing all stored comlinks with notes:")
    for i, v in pairs(lotj.comlinkInfo.comlinks) do
      if v.note then
        cecho("    <dim_gray>" .. i .. " <yellow>-> <dim_gray>(Note:<red>" .. v.note .. "<dim_gray>)\n")
      end
    end
  end,
  helpText = "Prints a list of every comlink that has a note."
},{
  args = {"note", "comlink:string", "note:string?"},
  action = function(com, note)
    for i, v in pairs(lotj.comlinkInfo.comlinks) do
      if string.find(i:lower(), com:lower(), 0, true) or (v.note and (string.find(v.note:lower(), com:lower(), 0, true))) then -- search by comlink keyword or note keyword
        if note == "" or note == nil then
          if v.note == nil then
            logComlinkAction("No note saved for", i, nil, "gray")
            return
          end
          logComlinkAction("Removed note from", i, v.note)
          v.note = nil
        else
          v.note = note
          logComlinkAction("Added note to", i, v.note)
        end
        lotj.comlinkInfo.saveForChar()
        return
      end
    end
    logComlinkAction("Comlink not found", com, nil, "red")
  end,
  helpText = "Add or remove a note: comlinks note \"Example radio\" [\"Example note\"] (omit the note to remove it)."
}}

function lotj.comlinkInfo.command(args)
  lotj.comlinkInfo.loadForChar()
  processCommand("comlinks", subcommands, args)
end
