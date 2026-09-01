lotj = lotj or {}
lotj.settings = lotj.settings or {}

local os = getOS()

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
        -- { -- To be integrated
        --   name = "Study",
        --   key = "gag_study",
        --   type = "toggle",
        --   default = false,
        --   description = "Enable gagging for other players scripting study",
        --   icon = "❌"
        -- },
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
      name = "Keybinds",
      items = {
        {
          name = "Numpad movement",
          key = "numpad_movement",
          type = "toggle",
          default = false,
          description = "Enable/disable numpad cardinal movement keybinds",
          icon = "🔢",
          onChange = function(value, key)
            if value then enableKey("lotj-ui_move") else disableKey("lotj-ui_move") end
          end
        },
        {
          name = "Numpad Map Shift",
          key = "numpad_map_shift",
          type = "toggle",
          default = false,
          description = "Enable/disable map shift numpad keybinds (alt+numpad)",
          icon = "🗺️",
          onChange = function(value, key)
            if value then enableKey("lotj-ui_map-shift") else disableKey("lotj-ui_map-shift") end
          end
        },
        {
          name = "Numpad Scanning",
          key = "numpad_scanning",
          type = "toggle",
          default = false,
          description = "Enable/disable scanning with ctrl+numpad",
          icon = "🔭",
          onChange = function(value, key)
            if value then enableKey("lotj-ui_scan") else disableKey("lotj-ui_scan") end
          end
        },
        {
          name = "Chat Tab Selecting",
          key = "chat-tab_selecting",
          type = "toggle",
          default = false,
          description = "Enable/disable tabbing between chat tabs with alt+# (# being tab number)",
          icon = "👆",
          onChange = function(value, key)
            if value then enableKey("lotj-ui_chat-tab") else disableKey("lotj-ui_chat-tab") end
          end
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
          default = false,
          description = "Enable Local tab notifications",
          icon = "👥"
        },
        {
          name = "CommNet",
          key = "notif_commnet",
          type = "toggle",
          default = false,
          description = "Enable CommNet tab notifications",
          icon = "🎧"
        },
        {
          name = "Clan",
          key = "notif_clan",
          type = "toggle",
          default = false,
          description = "Enable Clan tab notifications",
          icon = "🏰"
        },
        {
          name = "Broadcast",
          key = "notif_broadcast",
          type = "toggle",
          default = false,
          description = "Enable Broadcast tab notifications",
          icon = "🔊"
        },
        {
          name = "OOC",
          key = "notif_ooc",
          type = "toggle",
          default = false,
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
      name = "GUI Preferences",
      items = {
        {
          name = "Startup Map",
          key = "startup_map",
          type = "dropdown",
          options = {"map", "system", "galaxy"},
          update = function() return lotj.layout.getTabNames(lotj.layout.upperRightTabData) end,
          default = "map",
          description = "Select which upper right window tab to display on startup",
          icon = "⏻",
          onChange = function(value)
            lotj.layout.selectTab(lotj.layout.upperRightTabData, value)
          end
        },
        {
          name = "Startup Chat",
          key = "startup_chat",
          type = "dropdown",
          options = {"all", "local", "commnet", "clan", "broadcast", "ooc", "tell", "imm", "settings"},
          update = function() return lotj.layout.getTabNames(lotj.layout.lowerRightTabData) end,
          default = "all",
          description = "Select which lower right chat tab to display on startup",
          icon = "⏻"
        }
      }
    },
    {
      name = "Logging",
      items = {
        {
          name = "Enable Logging",
          key = "logging",
          type = "toggle",
          default = false,
          description = "Automatically start and stop logging when connecting and disconnecting",
          icon = "📁",
          onChange = function(value)
            lotj.applyLoggingHandlers()
            if value then
              eventStartLogging(nil, true)
            else
              eventEndLogging(nil, true)
            end
          end
        },
        {
          name = "Log Style",
          key = "logStyle",
          type = "dropdown",
          default = "TXT",
          options = {"TXT", "HTML"},
          description = "Select which extension to log in",
          icon = "📁",
          onChange = function(value)
            if value == "TXT" then
              setConfig("logInHTML", false)
            else
              setConfig("logInHTML", true)
            end
          end
        },
        {
          name = "Daily Log Rotation Timer",
          key = "logTimer",
          type = "toggle",
          default = false,
          description = "Create a new log every day at midnight",
          icon = "⏱️"
        }
        -- { -- Maybe one day if Mudlet adds a setCommandSeparator function 
        --   name = "Command Line Separator",
        --   key = "command_line_separator",
        --   type = "input",
        --   default = getCommandSeparator(),
        --   descripiton = "Change your default command line separator - put this string inside one command to send it as two",
        --   icon = ">_",
        --   inputType = "text",
        --   onChange = function(value, key)
        --     setCommandSeparator(value)
        --   end
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
    },
    {
      name = "Debug Options",
      items = {
        {
          name = "Debug Mode",
          key = "debugMode",
          type = "toggle",
          default = false,
          description = "Enable debug logging and verbose output - Reload the profile for all features to take effect",
          icon = "🐛"
        },
        {
          name = "GMCP Output",
          key = "debugGMCP_out",
          type = "toggle",
          default = true,
          description = "Route all GMCP traffic to the debug window",
          icon = "🚂"
        },
        {
          name = "Debug Console",
          key = "debugconsole",
          type = "toggle",
          default = true,
          description = "Enable input to the debug window - requires profile reset to take effect",
          icon = "⌨️"
        }
      }
    }
  },

  -- Global callbacks
  onChange = function(key, value, configTable)
    lotj.chat.debugLog("Setting '" .. key .. "' changed to: " .. tostring(value))
    -- You could save to file here, update other systems, etc.
  end,

  onSave = function(self, configTable)
    configTable = copyTableWithoutFunctions(configTable)
    lotj.chat.debugLog("Saving configuration...")
    -- Example: save to JSON file
    -- local json = require("dkjson")
    local json = require("@PKGNAME@.dkjson")
    local file = io.open(settingsFile, "w")
    if file then
      file:write(json.encode(configTable))
      file:close()
      lotj.chat.debugLog("Configuration saved!")
    end
  end,

  onLoad = function(self, configTable)
    lotj.chat.debugLog("Loading configuration...")
    -- Example: load from JSON file
    -- local json = require("dkjson")
    local json = require("@PKGNAME@.dkjson")
    local file = io.open(settingsFile, "r")
    if file == nil then
      self:onSave(configTable)
      file = io.open(settingsFile, "r")
    end
    if file then
      local content = file:read("*all")
      file:close()
      local loaded = json.decode(content)
      if loaded then
        for k, v in pairs(loaded) do
          configTable[k] = v
        end
        lotj.chat.debugLog("Configuration loaded!")
        for _, c in ipairs(lotj.configWindow.configDef.categories) do
          for _, j in ipairs(c.items) do
            if j.type == "toggle" then
              lotj.configWindow:setItemValue(j, configTable[j.key])
            end
          end
        end
      end
    end
  end,

  overrideClose = true
}

-- Version dependent settings
if not mudletOlderThan(5) then
  table.insert(primaryConfigDefinition.categories[1].items,
    {
      name = "OOC",
      key = "gag_ooc",
      type = "toggle",
      default = false,
      description = "Gag the OOC channel",
      icon = "❌"
    }
  )
end

-- OS dependent settings
if os == "linux" then
  table.insert(primaryConfigDefinition.categories[2].items,
    {
      name = "Retreat",
      key = "numpad_retreat_linux",
      type = "toggle",
      default = false,
      description = "Enable/disable retreat with shift+numpad",
      icon = "💨",
      onChange = function(value, key)
        if value then enableKey("lotj-ui_retreat-linux") else disableKey("lotj-ui_retreat-linux") end
      end
    }
  )
elseif os == "windows" then
  table.insert(primaryConfigDefinition.categories[2].items,
    {
      name = "Retreat",
      key = "numpad_retreat_windows",
      type = "toggle",
      default = false,
      description = "Enable/disable retreat with shift+numpad",
      icon = "💨",
      onChange = function(value, key)
        if value then enableKey("lotj-ui_retreat-windows") else disableKey("lotj-ui_retreat-windows") end
      end
    }
  )
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

function lotj.settings.setup()
  -- Apply OS dependent settings
  local function applyOSSettings()
    local OS = getOS()
    if OS == "linux" then
      disableKey("lotj-ui_retreat-windows")
    elseif OS == "windows" then
      disableKey("lotj-ui_retreat-linux")
    else
      disableKey("lotj-ui_retreat-linux")
      disableKey("lotj-ui_retreat-windows")
    end
  end
  lotj.setup.registerEventHandler("lotjUiLoaded", applyOSSettings)

  local function outOfDateMudletNotice()
    if not mudletOlderThan(5) then return end
    local outdatedMudlet = {}
    local style = [[
      QLabel {
        background-color: #0a1a2e;
        border: 1px solid #00aaff;
        border-top-right-radius: 4px;
        border-top-left-radius: 4px;
        margin: 3px 3px 3px 3px;
        font-family: ]] .. getFont() .. [[;
      }
    ]]

    function outdatedMudlet.closeUpdateMudletNotice()
      outdatedMudlet.updateMudletNotice:delete()
      outdatedMudlet.backgroundLabel:delete()
    end

    function outdatedMudlet.createUpdateMudletNotice()
      outdatedMudlet.backgroundLabel = Geyser.Label:new({
        name = "outdatedMudlet.backgroundLabel",
        x = 0, y = 0, width = "100%", height = "100%",
      })
      outdatedMudlet.backgroundLabel:setStyleSheet([[
        background-color: rgba(0, 0, 0, 150);
      ]])
      outdatedMudlet.backgroundLabel:raise()
      outdatedMudlet.backgroundLabel:show()
      outdatedMudlet.backgroundLabel:setClickCallback(outdatedMudlet.closeUpdateMudletNotice)

      outdatedMudlet.updateMudletNotice = Geyser.Label:new({
        name = "outdatedMudlet.updateMudletNotice",
        x = "25%", y = "25%", width = "50%", height = "50%",
        fontSize = 18,
        message = [[<center>
        <p>NOTICE: You are using Mudlet version ]]..getMudletVersion("string")..[[ and some features are disabled.</p>
        <p><br>The LOTJ Mudlet UI officially supports version 5.0.0+, <br>
        head to the <a href="https://mudlet.org/download" style="color: #00aaff; text-decoration: underline;">Mudlet website</a> to update.</p>
        <p><br>Click outside the label to dismiss this notice.</p>
        </center>]]
      })
      outdatedMudlet.updateMudletNotice:setStyleSheet(style)
      outdatedMudlet.updateMudletNotice:raise()
      outdatedMudlet.updateMudletNotice:show()
    end

    tempTimer(.2, function()
      outdatedMudlet.createUpdateMudletNotice()
    end)
  end
  lotj.setup.registerEventHandler("lotjUiLoaded", outOfDateMudletNotice)

  lotj.configWindow = {}
  lotj.configWindow = ModernConfigManager:new(primaryConfigDefinition, { style = mainStyle })

  primaryConfigDefinition:onLoad(lotj.settings)
end

function lotj.settings.setupTab()
  lotj.configWindow:create(lotj.chat["settings"])
  -- lotj.configWindow:show()
  lotj.configWindow.container:lockContainer("full")
end
