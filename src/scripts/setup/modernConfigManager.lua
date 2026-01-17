-- ============================================================================
-- ModernConfigManager - Generic Configuration Window for Mudlet
-- ============================================================================
-- A flexible, modern configuration system that can be easily integrated
-- into any Mudlet package or script by copying this code directly.
--
-- Usage:
--   1. Copy this entire script into your Mudlet package
--   2. Define your configuration structure (see example at bottom)
--   3. Call ModernConfigManager:new(configDefinition):show()
--
-- Features:
--   • Toggle switches, sliders, dropdowns, and text inputs
--   • Scrollable categories with modern styling
--   • Automatic default value initialization
--   • Customizable callbacks and styling
--   • Fully self-contained - no external dependencies
--
-- Author: Mudlet Community
-- Version: 1.1
-- License: MIT
-- ============================================================================

-- Create global table if it doesn't exist
ModernConfigManager = ModernConfigManager or {}
ModernConfigManager.__index = ModernConfigManager

-- Default styling configuration
local DEFAULT_STYLE = {
  window = {
    width = "40%",
    height = "75%", 
    x = "30%",
    y = "12.5%"
  },
  colors = {
    background = "rgba(40, 40, 40, 240)",
    header = "rgba(60, 60, 60, 200)", 
    selected = "rgba(80, 120, 160, 150)",
    hover = "rgba(70, 70, 70, 150)",
    border = "#888888",
    text = "#ffffff",
    categoryText = "#00ffff",
    itemText = "#ffff00",
    toggleOn = "#44ff44",
    toggleOff = "#ff4444"
  }
}

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

--[[
Creates a new configuration manager instance.

Parameters:
  configDef (table): Configuration definition structure
  options (table): Optional styling and behavior options
  
Example configDef structure:
{
  title = "My Application Config",
  name = "myapp", -- unique identifier for UI elements
  configTable = myApp.settings, -- The table that stores actual values
  categories = {
    {
      name = "General",
      items = {
        {
          name = "Enable Feature",
          key = "enableFeature", 
          type = "toggle",
          default = true,
          description = "Enables the main feature",
          icon = "✨"
        },
        {
          name = "Update Interval", 
          key = "updateInterval",
          type = "slider",
          min = 1, max = 60, step = 1,
          default = 5,
          suffix = "s",
          description = "How often to update",
          icon = "⏱️"
        },
        {
          name = "Theme",
          key = "theme",
          type = "dropdown",
          options = {"dark", "light", "blue"},
          default = "dark",
          description = "Select UI theme",
          icon = "🎨"
        },
        {
          name = "Player Name",
          key = "playerName", 
          type = "input",
          default = "Anonymous",
          description = "Your character name",
          icon = "👤"
        }
      }
    }
  },
  
  -- Optional callbacks
  onChange = function(key, value, configTable)
    -- Called whenever any setting changes
  end,
  onSave = function(configTable)
    -- Called when save button is clicked
  end,
  onLoad = function(configTable)
    -- Called when load button is clicked
  end
}
--]]
function ModernConfigManager:new(configDef, options)
  local instance = {}
  setmetatable(instance, self)
  
  -- Validate required parameters
  if not configDef then
    error("ModernConfigManager: configDef parameter is required")
  end
  if not configDef.configTable then
    error("ModernConfigManager: configDef.configTable is required - this should be the table that stores your settings")
  end
  
  -- Store configuration definition
  instance.configDef = configDef
  instance.configTable = configDef.configTable
  
  -- Set default name if not provided
  if not instance.configDef.name then
    instance.configDef.name = "config_" .. math.random(1000, 9999)
  end
  
  -- Merge styling options with defaults
  instance.style = DEFAULT_STYLE
  if options and options.style then
    instance.style = instance:deepMerge(DEFAULT_STYLE, options.style)
  end
  
  -- Initialize default values in config table
  instance:initializeDefaults()
  
  -- UI elements
  instance.container = nil
  instance.scrollArea = nil
  instance.contentContainer = nil
  
  return instance
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function ModernConfigManager:deepMerge(default, override)
  local result = {}
  
  -- Copy default values
  for k, v in pairs(default) do
    if type(v) == "table" then
      result[k] = self:deepMerge(v, {})
    else
      result[k] = v
    end
  end
  
  -- Override with new values
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = self:deepMerge(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

function ModernConfigManager:initializeDefaults()
  if not self.configDef.categories then return end
  
  for _, category in ipairs(self.configDef.categories) do
    if category.items then
      for _, item in ipairs(category.items) do
        if item.key and item.default ~= nil then
          if self.configTable[item.key] == nil then
            self.configTable[item.key] = item.default
          end
        end
      end
    end
  end
end

-- ============================================================================
-- MAIN UI CREATION
-- ============================================================================

function ModernConfigManager:create(parent)
  if self.container then
    self.container:show()
    self.container:raise()
    return
  end

  self.parent = parent

  local title = self.configDef.title or "Configuration"
  local uniqueName = self.configDef.name

  if io.exists(getMudletHomeDir() .. "/AdjustableContainer/modernConfigContainer_" .. uniqueName .. ".lua") then
    os.remove(getMudletHomeDir() .. "/AdjustableContainer/modernConfigContainer_" .. uniqueName .. ".lua")
  end

  -- Main container using Adjustable.Container
  self.container = Adjustable.Container:new({
    name = "modernConfigContainer_" .. uniqueName,
    titleText = title,
    x = self.style.window.x,
    y = self.style.window.y,
    -- x = "0%", y = "0%",
    width = self.style.window.width,
    height = self.style.window.height,
    -- width = "60%", height = "75%",
    adjLabelstyle = [[
      background-color: ]] .. self.style.colors.background .. [[;
      border: 2px solid ]] .. self.style.colors.border .. [[;
      border-radius: 10px;
    ]],
    buttonstyle = [[
      QLabel {
        background-color: ]] .. self.style.colors.header .. [[;
        color: ]] .. self.style.colors.text .. [[;
        border: 1px solid ]] .. self.style.colors.border .. [[;
        border-radius: 5px;
        padding: 5px;
      }
      QLabel:hover {
        background-color: ]] .. self.style.colors.hover .. [[;
      }
    ]]
  }, self.parent)

  -- Create scrollable content area
  self.scrollArea = Geyser.ScrollBox:new({
    name = "configScrollArea_" .. uniqueName,
    x = 0, y = 0,
    width = "100%",
    height = "85%"
  }, self.container)

  -- Create content container inside scroll area
  self.contentContainer = Geyser.Label:new({
    name = "configContent_" .. uniqueName,
    x = 0, y = 0,
    width = "100%",
    height = "100%"
  }, self.scrollArea)
  
  self.contentContainer:setStyleSheet([[
    background-color: transparent;
    color: ]] .. self.style.colors.text .. [[;
  ]])

  -- Build the UI
  self:buildCategories()
  self:createBottomButtons()

  -- Show container
  self.container:show()
  self.container:raise()
end

function ModernConfigManager:buildCategories()
  if not self.configDef.categories then return end
  
  local yPos = 10
  local _, categoryHeight = calcFontSize(14, getFont())
  local _, itemHeight = calcFontSize(11, getFont())
  
  for _, category in ipairs(self.configDef.categories) do
    -- Category header
    local categoryLabel = Geyser.Label:new({
      name = "category_" .. category.name:gsub("%s+", "_") .. "_" .. self.configDef.name,
      x = 10, y = yPos,
      width = "95%", height = categoryHeight + 5
    }, self.contentContainer)
    
    categoryLabel:setStyleSheet([[
      QLabel {
        color: ]] .. self.style.colors.categoryText .. [[;
        font-weight: bold;
        font-size: ]] .. categoryHeight .. [[px;
        background: qlineargradient(x1: 0, y1: 0, x2: 1, y2: 0,
                                   stop: 0 ]] .. self.style.colors.header .. [[,
                                   stop: 0.5 rgba(60, 60, 60, 100),
                                   stop: 1 transparent);
        border-bottom: 2px solid ]] .. self.style.colors.categoryText .. [[;
        padding: 5px;
        border-radius: 5px;
      }
    ]])
    categoryLabel:setFont(getFont())
    categoryLabel:echo(category.name)
    
    yPos = yPos + categoryHeight + 15
    
    -- Category items
    if category.items then
      for _, item in ipairs(category.items) do
        yPos = yPos + self:createConfigItem(item, yPos, itemHeight)
      end
    end
    
    yPos = yPos + 20 -- spacing between categories
  end
  
  -- Adjust content container height
  self.contentContainer:resize(self.contentContainer:get_width(), yPos)
end

function ModernConfigManager:createConfigItem(item, yPos, itemHeight)
  local uniqueName = self.configDef.name
  local itemContainer = Geyser.Label:new({
    name = "item_" .. item.key .. "_" .. uniqueName,
    x = 20, y = yPos,
    width = "90%", height = itemHeight + 10
  }, self.contentContainer)

  itemContainer:setStyleSheet([[
    QLabel {
      background: ]] .. self.style.colors.header .. [[;
      border: 1px solid ]] .. self.style.colors.border .. [[;
      border-radius: 8px;
      padding: 5px;
    }
    QLabel:hover {
      background: ]] .. self.style.colors.hover .. [[;
      border: 1px solid ]] .. self.style.colors.selected .. [[;
    }
  ]])
  itemContainer:setFont(getFont())

  -- Add tooltip if description exists
  if item.description then
    itemContainer:setToolTip(item.description)
  end

  -- Icon and label
  local iconLabel = Geyser.Label:new({
    name = "icon_" .. item.key .. "_" .. uniqueName,
    x = 5, y = 2,
    width = itemHeight + 5, height = itemHeight + 5
  }, itemContainer)
  iconLabel:echo(item.icon or "⚙️")
  iconLabel:setStyleSheet([[
    background: transparent; 
    color: ]] .. self.style.colors.itemText .. [[;
    font-size: ]] .. (itemHeight-2) .. [[px;
  ]])
  iconLabel:setFont(getFont())
  
---@diagnostic disable-next-line: unbalanced-assignments
  local width, height = calcFontSize(8, getFont()) * #item.name
  
  local nameLabel = Geyser.Label:new({
    name = "name_" .. item.key .. "_" .. uniqueName,
    x = itemHeight + 15, y = 2,
    width = width,
    -- width = "50%", 
    height = itemHeight + 5
  }, itemContainer)
  nameLabel:echo(item.name)
  nameLabel:setStyleSheet([[
    background: transparent; 
    color: ]] .. self.style.colors.text .. [[;
    qproperty-alignment: 'AlignLeft | AlignVCenter';
  ]])
  nameLabel:setFont(getFont())
  
  -- Control based on type
  if item.type == "toggle" then
    self:createToggle(item, itemContainer, itemHeight)
  elseif item.type == "slider" then
    self:createSlider(item, itemContainer, itemHeight)
  elseif item.type == "dropdown" then
    self:createDropdown(item, itemContainer, itemHeight)
  elseif item.type == "input" then
    self:createInput(item, itemContainer, itemHeight)
  elseif item.type == "popup" then
    self:createPopup(item, itemContainer, itemHeight)
  else
    -- Unknown type - show warning
    local warningLabel = Geyser.Label:new({
      name = "warning_" .. item.key .. "_" .. uniqueName,
      x = "60%", y = 2,
      width = "35%", height = itemHeight + 5
    }, itemContainer)
    warningLabel:echo("Unknown type: " .. (item.type or "nil"))
    warningLabel:setStyleSheet([[
      background: ]] .. self.style.colors.toggleOff .. [[;
      color: ]] .. self.style.colors.text .. [[;
      border-radius: 4px;
      qproperty-alignment: 'AlignCenter';
    ]])
  end
  
  return itemHeight + 20
end

-- ============================================================================
-- CONTROL CREATORS
-- ============================================================================

function ModernConfigManager:createToggle(item, parent, height)
  local uniqueName = self.configDef.name
  local toggle = Geyser.Label:new({
    name = "toggle_" .. item.key .. "_" .. uniqueName,
    x = "70%", y = 2,
    width = "25%", height = height + 5
  }, parent)
  
  local isEnabled = self:getItemValue(item)
  
  local bgColor = isEnabled and self.style.colors.toggleOn or self.style.colors.toggleOff
  local text = isEnabled and "ON" or "OFF"
  
  toggle:setStyleSheet([[
    QLabel {
      background: ]] .. bgColor .. [[;
      border: 2px solid ]] .. self.style.colors.border .. [[;
      border-radius: ]] .. (height/2) .. [[px;
      color: ]] .. self.style.colors.text .. [[;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background: ]] .. (isEnabled and self.style.colors.selected or self.style.colors.hover) .. [[;
    }
  ]])
  toggle:setFont(getFont())
  
  toggle:echo(text)
  toggle:setClickCallback(function() self:toggleItem(item, toggle, height) end)
end

function ModernConfigManager:createSlider(item, parent, height)
  local uniqueName = self.configDef.name
  
  -- Validate slider parameters
  item.min = item.min or 0
  item.max = item.max or 100
  item.step = item.step or 1
  
  local valueLabel = Geyser.Label:new({
    name = "value_" .. item.key .. "_" .. uniqueName,
    x = "50%", y = 2,
    width = "20%", height = height + 5
  }, parent)
  
  -- Initial display
  local currentVal = self:getItemValue(item)
  valueLabel:echo(string.format("%.1f%s", currentVal, item.suffix or ""))
  valueLabel:setStyleSheet([[
    background: ]] .. self.style.colors.header .. [[;
    border: 1px solid ]] .. self.style.colors.border .. [[;
    border-radius: 4px;
    color: ]] .. self.style.colors.text .. [[;
    qproperty-alignment: 'AlignCenter';
  ]])
  valueLabel:setFont(getFont())
  
  -- Decrease button
  local decBtn = Geyser.Label:new({
    name = "dec_" .. item.key .. "_" .. uniqueName,
    x = "72%", y = 2,
    width = "10%", height = height + 5
  }, parent)
  decBtn:echo("−")
  decBtn:setStyleSheet(self:getButtonStyle())
  decBtn:setClickCallback(function() 
    local currentVal = self:getItemValue(item)
    local newVal = math.max(item.min, currentVal - item.step)
    self:setItemValue(item, newVal)
    self:refreshSlider(item, valueLabel)
  end)
  
  -- Increase button
  local incBtn = Geyser.Label:new({
    name = "inc_" .. item.key .. "_" .. uniqueName,
    x = "84%", y = 2,
    width = "10%", height = height + 5
  }, parent)
  incBtn:echo("+")
  incBtn:setStyleSheet(self:getButtonStyle())
  incBtn:setClickCallback(function()
    local currentVal = self:getItemValue(item)
    local newVal = math.min(item.max, currentVal + item.step)
    self:setItemValue(item, newVal)
    self:refreshSlider(item, valueLabel)
  end)
end

function ModernConfigManager:createDropdown(item, parent, height)
  local uniqueName = self.configDef.name
  local currentVal = self:getItemValue(item)
  local currentIndex = 1
  
  -- Validate options exist
  if not item.options or #item.options == 0 then
    item.options = {"Option 1", "Option 2"}
  end
  
  -- Find current option index
  for i, option in ipairs(item.options) do
    if option == currentVal then
      currentIndex = i
      break
    end
  end
  
  local dropdown = Geyser.Label:new({
    name = "dropdown_" .. item.key .. "_" .. uniqueName,
    x = "60%", y = 2,
    width = "35%", height = height + 5
  }, parent)
  
  dropdown:echo(tostring(currentVal) .. " ▼")
  dropdown:setStyleSheet([[
    QLabel {
      background: ]] .. self.style.colors.header .. [[;
      border: 1px solid ]] .. self.style.colors.border .. [[;
      border-radius: 4px;
      color: ]] .. self.style.colors.text .. [[;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background: ]] .. self.style.colors.hover .. [[;
    }
  ]])
  dropdown:setFont(getFont())
  
  dropdown:setClickCallback(function()
    local nextIndex = (currentIndex % #item.options) + 1
    local nextValue = item.options[nextIndex]
    self:setItemValue(item, nextValue)
    dropdown:echo(tostring(nextValue) .. " ▼")
    currentIndex = nextIndex
  end)
end

function ModernConfigManager:createInput(item, parent, height)
  local uniqueName = self.configDef.name
  
  -- For input, we'll use a simple label that opens a dialog when clicked
  local input = Geyser.Label:new({
    name = "input_" .. item.key .. "_" .. uniqueName,
    x = "50%", y = 2,
    width = "45%", height = height + 5
  }, parent)
  
  input:setStyleSheet([[
    QLabel {
      background: ]] .. self.style.colors.header .. [[;
      border: 1px solid ]] .. self.style.colors.border .. [[;
      border-radius: 4px;
      color: ]] .. self.style.colors.text .. [[;
      padding: 2px;
      qproperty-alignment: 'AlignLeft | AlignVCenter';
    }
    QLabel:hover {
      background: ]] .. self.style.colors.hover .. [[;
    }
  ]])
  input:setFont(getFont())
  
  local currentVal = self:getItemValue(item)
  local displayText = tostring(currentVal)
  
  -- Truncate long text for display
  if string.len(displayText) > 20 then
    displayText = string.sub(displayText, 1, 17) .. "..."
  end
  
  input:echo(displayText .. " ✏️")
  
  -- Set callback for when clicked - opens input dialog
  input:setClickCallback(function()
  
    -- For input, we'll use a simple command line
    local inputCmdLine = Geyser.CommandLine:new({
      name = "cmdLine_" .. item.key .. "_" .. uniqueName,
      x = "2%", y = "90%", 
      width = "96%", height = 20,
      stylesheet = "border: 1px solid silver; background-color: rgb(20,30,40);"
    }, parent)
    
    local currentValue = tostring(self:getItemValue(item))
    
    inputCmdLine:print(currentValue)
    inputCmdLine:selectText()
  
    inputCmdLine:setAction(
    function(commandLineInput)
      local newValue = tostring(commandLineInput)
      
      if item.inputType == "number" then
---@diagnostic disable-next-line: cast-local-type
        newValue = tonumber(newValue) or 0
      end
      
      self:setItemValue(item, newValue)
      
      inputCmdLine:hide()
      self:refresh()
    end)
  end)
end

-- function ModernConfigManager:createPopup(item, parent, height)
  -- local uniqueName = self.configDef.name
  -- local popup = Geyser.Label:new({
    -- name = "popup_" .. item.key .. "_" .. uniqueName,
    -- x = "70%", y = 2,
    -- width = "25%", height = height + 5
  -- }, parent)
  -- 
  -- local isEnabled = self:getItemValue(item)
  -- 
  -- local bgColor = isEnabled and self.style.colors.toggleOn or self.style.colors.toggleOff
  -- local text = "OPEN"
  -- 
  -- popup:setStyleSheet([[
    -- QLabel {
      -- background: ]] .. bgColor .. [[;
      -- border: 2px solid ]] .. self.style.colors.border .. [[;
      -- border-radius: ]] .. (height/2) .. [[px;
      -- color: ]] .. self.style.colors.text .. [[;
      -- font-weight: bold;
      -- qproperty-alignment: 'AlignCenter';
    -- }
    -- QLabel:hover {
      -- background: ]] .. (isEnabled and self.style.colors.selected or self.style.colors.hover) .. [[;
    -- }
  -- ]])
  -- popup:setFont(getFont())
  -- 
  -- popup:echo(text)
  -- popup:setClickCallback(function()
    -- -- self:toggleItem(item, toggle, height)
    -- print(popup.name .. " pressed.")
    -- item.default:create()
  -- end)
-- end

function ModernConfigManager:createPopup(item, parent, height)
  local uniqueName = self.configDef.name
  local popup = Geyser.Label:new({
    name = "popup_" .. item.key .. "_" .. uniqueName,
    x = "70%", y = 2,
    width = "25%", height = height + 5
  }, parent)

  popup:setStyleSheet([[
    QLabel {
      background: ]] .. self.style.colors.toggleOff .. [[;
      border: 2px solid ]] .. self.style.colors.border .. [[;
      border-radius: ]] .. (height/2) .. [[px;
      color: ]] .. self.style.colors.text .. [[;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background: ]] .. self.style.colors.hover .. [[;
    }
  ]])
  popup:setFont(getFont())
  popup:echo("OPEN")

  popup:setClickCallback(function()
    print(popup.name .. " pressed.")
    if type(item.window) == "table" and item.window.show then
      item.window:show()         -- open a config window
    elseif type(item.window) == "function" then
      item.window()              -- run a custom action
    else
      echo("Popup item '" .. item.name .. "' has no valid window or action\n")
    end
  end)
end



-- ============================================================================
-- VALUE MANAGEMENT
-- ============================================================================

function ModernConfigManager:getItemValue(item)
  if item.key and self.configTable then
    local value = self.configTable[item.key]
    if value ~= nil then
      return value
    end
  end
  return item.default
end

function ModernConfigManager:setItemValue(item, value)
  if item.key and self.configTable then
    self.configTable[item.key] = value
    
    -- Call item-specific onChange callback if provided
    if item.onChange and type(item.onChange) == "function" then
      pcall(item.onChange, value, item.key)
    end
    
    -- Call global onChange callback if provided
    if self.configDef.onChange and type(self.configDef.onChange) == "function" then
      pcall(self.configDef.onChange, item.key, value, self.configTable)
    end
  end
end

function ModernConfigManager:toggleItem(item, toggleWidget, height)
  local currentState = self:getItemValue(item)
  local newState = not currentState
  
  self:setItemValue(item, newState)
  
  -- Update the toggle appearance
  local bgColor = newState and self.style.colors.toggleOn or self.style.colors.toggleOff
  local hoverColor = newState and self.style.colors.selected or self.style.colors.hover
  local text = newState and "ON" or "OFF"
  
  toggleWidget:setStyleSheet([[
    QLabel {
      background: ]] .. bgColor .. [[;
      border: 2px solid ]] .. self.style.colors.border .. [[;
      border-radius: ]] .. (height/2) .. [[px;
      color: ]] .. self.style.colors.text .. [[;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background: ]] .. hoverColor .. [[;
    }
  ]])
  toggleWidget:setFont(getFont())
  
  toggleWidget:echo(text)
end

function ModernConfigManager:refreshSlider(item, valueLabel)
  local currentVal = self:getItemValue(item)
  valueLabel:echo(string.format("%.1f%s", currentVal, item.suffix or ""))
end

-- ============================================================================
-- STYLING HELPERS
-- ============================================================================

function ModernConfigManager:getButtonStyle()
  return [[
    QLabel {
      background: ]] .. self.style.colors.header .. [[;
      border: 1px solid ]] .. self.style.colors.border .. [[;
      border-radius: 4px;
      color: ]] .. self.style.colors.text .. [[;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background: ]] .. self.style.colors.hover .. [[;
    }
  ]]
end

function ModernConfigManager:getPrimaryButtonStyle()
  return [[
    QLabel {
      background: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1,
                                 stop: 0 ]] .. self.style.colors.selected .. [[,
                                 stop: 1 ]] .. self.style.colors.header .. [[);
      border: 2px solid ]] .. self.style.colors.border .. [[;
      border-radius: 8px;
      color: ]] .. self.style.colors.text .. [[;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1,
                                 stop: 0 rgba(100,149,237,200),
                                 stop: 1 ]] .. self.style.colors.hover .. [[);
    }
  ]]
end

function ModernConfigManager:getDangerButtonStyle()
  return [[
    QLabel {
      background: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1,
                                 stop: 0 ]] .. self.style.colors.toggleOff .. [[,
                                 stop: 1 ]] .. self.style.colors.header .. [[);
      border: 2px solid ]] .. self.style.colors.border .. [[;
      border-radius: 8px;
      color: ]] .. self.style.colors.text .. [[;
      font-weight: bold;
      qproperty-alignment: 'AlignCenter';
    }
    QLabel:hover {
      background: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1,
                                 stop: 0 rgba(255,69,0,200),
                                 stop: 1 ]] .. self.style.colors.hover .. [[);
    }
  ]]
end

-- ============================================================================
-- BOTTOM BUTTONS
-- ============================================================================

function ModernConfigManager:createBottomButtons()
  local buttonHeight = 35
  local buttonY = "87%"
  
  local buttonsConfig = self.configDef.buttons or {}
  local defaultButtons = {
    {name = "💾 Save", callback = self.configDef.onSave and function() self.configDef.onSave(self.configTable) end, style = "primary", x = "10%", width = "25%"},
    {name = "🔄 Reset", callback = function() self:resetToDefaults() end, style = "primary", x = "37.5%", width = "25%"},
    {name = "❌ Close", callback = function() self:hide() end, style = "danger", x = "65%", width = "25%"}
  }
  
  -- Include Load button only if onLoad callback is provided
  if self.configDef.onLoad then
    table.insert(defaultButtons, 2, {name = "📁 Load", callback = function() self.configDef.onLoad(self.configTable) self:refresh() end, style = "primary", x = "28.75%", width = "18.75%"})
    -- Adjust other button positions
    defaultButtons[1].x =  "8.75%"
    defaultButtons[1].width = "18.75%"
    defaultButtons[2].x = "28.75%"
    defaultButtons[2].width = "18.75%"
    defaultButtons[3].x = "48.75%"
    defaultButtons[3].width = "18.75%"
    defaultButtons[4].x = "68.75%"
    defaultButtons[4].width = "25%"
  end
  
  -- Use custom buttons if provided, otherwise use defaults
  local buttons = #buttonsConfig > 0 and buttonsConfig or defaultButtons
  
  for i, btnConfig in ipairs(buttons) do
    if btnConfig.callback then -- Only create button if it has a callback
      local uniqueName = self.configDef.name
      local btn = Geyser.Label:new({
        name = "configBtn_" .. i .. "_" .. uniqueName,
        x = btnConfig.x or "10%",
        y = buttonY,
        width = btnConfig.width or "25%",
        height = buttonHeight
      }, self.container)
      btn:setFont(getFont())
      
      btn:echo(btnConfig.name)
      
      local style = "primary"
      if btnConfig.style == "danger" then
        style = self:getDangerButtonStyle()
      else
        style = self:getPrimaryButtonStyle()
      end
      
      btn:setStyleSheet(style)
      btn:setClickCallback(btnConfig.callback)
    end
  end
end

-- ============================================================================
-- ADDITIONAL UTILITY FUNCTIONS
-- ============================================================================

function ModernConfigManager:resetToDefaults()
  if not self.configDef.categories then return end
  
  for _, category in ipairs(self.configDef.categories) do
    if category.items then
      for _, item in ipairs(category.items) do
        if item.key and item.default ~= nil then
          self.configTable[item.key] = item.default
        end
      end
    end
  end
  
  -- Refresh the UI
  self:refresh()
  
  -- Call onChange callback for reset
  if self.configDef.onChange and type(self.configDef.onChange) == "function" then
    pcall(self.configDef.onChange, "RESET", nil, self.configTable)
  end
end

function ModernConfigManager:refresh()
  if not self.container then return end

  self:hide()

  local parent = self.parent
  local lockStyle
  if self.container.locked then
    lockStyle = self.container.lockStyle
  end

  self.container = nil
  self.scrollArea = nil
  self.contentContainer = nil

  self:create(parent)
  if lockStyle then
    self.container:lockContainer(lockStyle)
  end
  self:show()
end


function ModernConfigManager:getConfig()
  return self.configTable
end

function ModernConfigManager:setConfig(newConfig)
  if type(newConfig) == "table" then
    for k, v in pairs(newConfig) do
      self.configTable[k] = v
    end
    self:refresh()
  end
end

-- ============================================================================
-- PUBLIC INTERFACE
-- ============================================================================

function ModernConfigManager:show()
  if not self.container then
    self:create()
  end
  tempTimer(0, 
    function() 
      self.container:show() 
      self.container:raise() 
    end
  )
end

function ModernConfigManager:hide()
  if self.container then
    self.container:hide()
  end
end

function ModernConfigManager:destroy()
  if self.container then
    self.container:hide()
    self.container = nil
  end
  self.scrollArea = nil
  self.contentContainer = nil
end

function ModernConfigManager:toggle()
  if self.container and not self.container.hidden then
    self:hide()
  else
    self:show()
  end
end

-- ============================================================================
-- EXAMPLE USAGE AND DOCUMENTATION
-- ============================================================================

--[[
COMPLETE USAGE EXAMPLE:

-- 1. Create your settings table (this persists your actual data)
MyApp = MyApp or {}
MyApp.settings = MyApp.settings or {}

-- 2. Define your configuration structure
local myConfigDefinition = {
  title = "My Amazing Mudlet Package Settings",
  name = "myapp", -- unique identifier
  configTable = MyApp.settings, -- reference to your settings table
  
  categories = {
    {
      name = "General Settings",
      items = {
        {
          name = "Enable Feature",
          key = "enableFeature",
          type = "toggle",
          default = true,
          description = "Enable the main feature of the application",
          icon = "✨",
          onChange = function(value, key)
            print("Feature toggled to: " .. tostring(value))
          end
        },
        {
          name = "Update Interval",
          key = "updateInterval",
          type = "slider",
          min = 1, max = 60, step = 1,
          default = 5,
          suffix = "s",
          description = "How often to update in seconds",
          icon = "⏱️"
        },
        {
          name = "Theme",
          key = "theme",
          type = "dropdown",
          options = {"dark", "light", "blue", "green"},
          default = "dark",
          description = "Select your preferred UI theme",
          icon = "🎨"
        },
        {
          name = "Player Name",
          key = "playerName",
          type = "input",
          default = "Anonymous",
          description = "Your character name",
          icon = "👤",
          inputType = "text"
        }
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
          description = "Enable debug logging and verbose output",
          icon = "🐛"
        },
        {
          name = "Max Retries",
          key = "maxRetries",
          type = "slider",
          min = 1, max = 10, step = 1,
          default = 3,
          suffix = " attempts",
          description = "Maximum number of retry attempts",
          icon = "🔄"
        }
      }
    }
  },
  
  -- Global callbacks
  onChange = function(key, value, configTable)
    print("Setting '" .. key .. "' changed to: " .. tostring(value))
    -- You could save to file here, update other systems, etc.
  end,
  
  onSave = function(configTable)
    print("Saving configuration...")
    -- Example: save to JSON file
    -- local json = require("dkjson")
    -- local file = io.open("myapp_config.json", "w")
    -- if file then
    --   file:write(json.encode(configTable))
    --   file:close()
    --   print("Configuration saved!")
    -- end
  end,
  
  onLoad = function(configTable)
    print("Loading configuration...")
    -- Example: load from JSON file
    -- local json = require("dkjson")
    -- local file = io.open("myapp_config.json", "r")
    -- if file then
    --   local content = file:read("*all")
    --   file:close()
    --   local loaded = json.decode(content)
    --   if loaded then
    --     for k, v in pairs(loaded) do
    --       configTable[k] = v
    --     end
    --     print("Configuration loaded!")
    --   end
    -- end
  end
}

-- 3. Create and show the config window
local myConfigWindow = ModernConfigManager:new(myConfigDefinition)

-- 4. Create aliases/triggers to show your config
-- In Mudlet, you might create an alias like:
-- Pattern: ^config$
-- Code: myConfigWindow:show()

-- Or add a menu item:
-- myConfigWindow:show()

-- 5. Access your settings anywhere in your code:
-- if MyApp.settings.enableFeature then
--   -- do something
-- end
-- print("Update interval is: " .. MyApp.settings.updateInterval)

CONTROL TYPES REFERENCE:

1. TOGGLE:
{
  name = "Enable Something",
  key = "enableSomething",
  type = "toggle",
  default = true,
  description = "Tooltip text",
  icon = "✨"
}

2. SLIDER:
{
  name = "Some Value",
  key = "someValue", 
  type = "slider",
  min = 0,           -- minimum value
  max = 100,         -- maximum value
  step = 1,          -- step size
  default = 50,
  suffix = "%",      -- optional unit display
  description = "Tooltip text",
  icon = "⚡"
}

3. DROPDOWN:
{
  name = "Select Option",
  key = "selectedOption",
  type = "dropdown", 
  options = {"option1", "option2", "option3"},
  default = "option1",
  description = "Tooltip text",
  icon = "📋"
}

4. INPUT:
{
  name = "Text Input",
  key = "textInput",
  type = "input",
  default = "default text",
  description = "Tooltip text", 
  icon = "✏️",
  inputType = "text"  -- or "number"
}

STYLING CUSTOMIZATION:

You can customize colors and layout by passing a style option:

local customStyle = {
  colors = {
    background = "rgba(20, 20, 30, 240)",
    header = "rgba(40, 40, 50, 200)",
    selected = "rgba(100, 150, 200, 150)",
    toggleOn = "#00ff00",
    toggleOff = "#ff0000",
    text = "#ffffff"
  }
}

local configWindow = ModernConfigManager:new(myConfigDef, {style = customStyle})

IMPORTANT NOTES:

• Always provide a unique 'name' in your config definition to avoid conflicts
• The 'configTable' should be a persistent table that holds your actual settings
• All control types support 'onChange' callbacks for individual items
• The global 'onChange' callback fires for any setting change
• Settings are automatically initialized with default values
• Use 'key' values that are valid Lua table keys (no spaces, special chars)
• Icons support Unicode emoji or simple text characters
• Tooltips appear when hovering over items

INTEGRATION TIPS:

• Create your config window once and reuse it
• Store the config window reference globally: MyApp.configWindow = ModernConfigManager:new(...)
• Use aliases or menu items to show/hide: myConfigWindow:toggle()
• Save/load functionality should be implemented in the onSave/onLoad callbacks
• Access settings directly from your configTable: MyApp.settings.enableFeature
--]]
