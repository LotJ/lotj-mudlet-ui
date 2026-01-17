lotj = lotj or {}
lotj.settings = lotj.settings or {}

local settingsFile = getMudletHomeDir().."/lotj_ui_settings.lua"

local primaryConfigDefinition = {
  title = "Legends of the Jedi | Settings",
  name = "lotj", -- unique identifier
  configTable = lotj.settings, -- reference to your settings table

  categories = {
    -- {
    --   name = "General Settings",
    --   items = {
    --     {
    --       name = "Enable Feature",
    --       key = "enableFeature",
    --       type = "toggle",
    --       default = true,
    --       description = "Enable the main feature of the application",
    --       icon = "✨",
    --       onChange = function(value, key)
    --         lotj.chat.debugLog("Feature toggled to: " .. tostring(value))
    --       end
    --     },
    --     -- {
    --     --   name = "Pingmap Settings",
    --     --   key = "pingmap_settings",
    --     --   type = "popup",
    --     --   window = lotj.pingmap.configWindow,
    --     --   description = "Open a popup with the pingmap plugin settings",
    --     --   icon = "🗺️"
    --     -- }
    --   }
    -- },
    {
      name = "Gag Options",
      items = {
        -- {
        --   name = "Study",
        --   key = "gag_study",
        --   type = "toggle",
        --   default = false,
        --   description = "Enable gagging for other players scripting study",
        --   icon = "❌"
        -- },
        {
          name = "OOC",
          key = "gag_ooc",
          type = "toggle",
          default = false,
          description = "Gag the OOC channel",
          icon = "❌"
        },
        {
          name = "BlankLines",
          key = "gag_blanklines",
          type = "toggle",
          default = false,
          description = "Gag blank lines coming from the MUD",
          icon = "❌"
        },
      }
    },
    {
      name = "Notification Settings",
      items = {
        {
          name = "Local",
          key = "notif_local",
          type = "toggle",
          default = true,
          description = "Enable Local tab notifications",
          icon = "👥"
        },
        {
          name = "CommNet",
          key = "notif_commnet",
          type = "toggle",
          default = true,
          description = "Enable CommNet tab notifications",
          icon = "🎧"
        },
        {
          name = "Clan",
          key = "notif_clan",
          type = "toggle",
          default = true,
          description = "Enable Clan tab notifications",
          icon = "🏰"
        },
        {
          name = "Broadcast",
          key = "notif_broadcast",
          type = "toggle",
          default = true,
          description = "Enable Broadcast tab notifications",
          icon = "🔊"
        },
        {
          name = "OOC",
          key = "notif_ooc",
          type = "toggle",
          default = true,
          description = "Enable OOC tab notifications",
          icon = "📻"
        },
        {
          name = "Tell",
          key = "notif_tell",
          type = "toggle",
          default = true,
          description = "Enable Tell tab notifications",
          icon = "🤫"
        },
        {
          name = "Imm",
          key = "notif_imm",
          type = "toggle",
          default = true,
          description = "Enable Immchat notifications",
          icon = "🌩"
        }
      }
    },
    {
      name = "Extras",
      items = {
        {
          name = "Clickable Changes Entries",
          key = "clickable_changes",
          type = "toggle",
          default = true,
          description = "Enable a clickable link for standard format changes entries",
          icon = "📗"
        },
        {
          name = "Study",
          key = "study",
          type = "toggle",
          default = false,
          description = "Enable triggered studying - handles copyovers",
          icon = "📖"
        },
      }
    },
    {
      name = "Advanced Options",
      items = {
        {
          name = "Debug Mode",
          key = "debugMode",
          type = "toggle",
          default = false,
          description = "Enable debug logging and verbose output - Reload the profile for all features to take effect",
          icon = "🐛"
        },
        -- {
        --   name = "Test Input String",
        --   key = "testInputString",
        --   type = "input",
        --   default = "default",
        --   descripiton = "",
        --   icon = "🐞",
        --   inputType = "text"
        -- },
        -- {
        --   name = "Test Input Number",
        --   key = "testInputNumber",
        --   type = "input",
        --   default = 60,
        --   descripiton = "",
        --   icon = "🐞",
        --   inputType = "number"
        -- }
      }
    }
  },

  -- Global callbacks
  onChange = function(key, value, configTable)
    lotj.chat.debugLog("Setting '" .. key .. "' changed to: " .. tostring(value))
    -- You could save to file here, update other systems, etc.
  end,

  onSave = function(configTable)
    configTable = copyTableWithoutFunctions(configTable)
    lotj.chat.debugLog("Saving configuration...")
    -- Example: save to JSON file
    local json = require("dkjson")
    local file = io.open(getMudletHomeDir() .. "/lotj-ui/settings.json", "w")
    if file then
---@diagnostic disable-next-line: param-type-mismatch
      file:write(json.encode(configTable))
      file:close()
      lotj.chat.debugLog("Configuration saved!")
    end
  end,

  onLoad = function(configTable)
    lotj.chat.debugLog("Loading configuration...")
    -- Example: load from JSON file
    local json = require("dkjson")
    local file = io.open(getMudletHomeDir() .. "/lotj-ui/settings.json", "r")
    if file then
      local content = file:read("*all")
      file:close()
      local loaded = json.decode(content)
      if loaded then
---@diagnostic disable-next-line: param-type-mismatch
        for k, v in pairs(loaded) do
          configTable[k] = v
        end
        lotj.chat.debugLog("Configuration loaded!")
      end
    end
  end
}

function lotj.settings.setup()
  primaryConfigDefinition.onLoad(lotj.settings)
end

local mainStyle = {
  window = {
    width = "100%",
    height = "100%",
    x = "0%",
    y = "0%"
  },
  colors = {
    background = "rgba(15, 15, 25, 240)",
    header = "rgba(40, 40, 50, 200)",
    selected = "rgba(100, 150, 200, 150)",
    hover = "rgba(255, 255, 255, 60)",
    toggleOn = "#336666",
    toggleOff = "#333333",
    text = "#ffffff"
  }
}

local secondaryStyle = {
  window = {
    width = "40%",
    height = "50%", 
    x = "60%",
    y = "0%"
  },
  colors = {
    background = "rgba(15, 15, 25, 240)",
    header = "rgba(40, 40, 50, 200)",
    selected = "rgba(100, 150, 200, 150)",
    hover = "rgba(255, 255, 255, 60)",
    toggleOn = "#336666",
    toggleOff = "#333333",
    text = "#ffffff"
  }
}

function lotj.settings.setupTab()
  -- lotj.chat["settings"]:setStyleSheet("background-color: rgba(0,0,0,100%)")

  lotj.configWindow = {}
  lotj.configWindow = ModernConfigManager:new(primaryConfigDefinition, { style = mainStyle })

  lotj.configWindow:create(lotj.chat["settings"])
  lotj.configWindow.container:lockContainer("full")
end
