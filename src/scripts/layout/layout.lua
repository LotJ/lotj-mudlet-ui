lotj = lotj or {}
lotj.layout = lotj.layout or {}

local rightPanelWidthPct = 40
local upperRightHeightPct = 50

local inactiveTabStyle = [[
  background-color: #333333;
  border: 1px solid #00aaaa;
  border-top-right-radius: 4px;
  border-top-left-radius: 4px;
  margin: 3px 3px 0px 3px;
  font-family: ]] .. getFont() .. [[;
]]

local activeTabStyle = [[
  background-color: #336666;
  border: 1px solid #00aaaa;
  border-top-right-radius: 4px;
  border-top-left-radius: 4px;
  border-bottom: none;
  margin: 3px 3px 0px 3px;
  font-family: ]] .. getFont() .. [[;
]]

local notificationTabStyle = [[
  background-color: #00ffff;
  border: 1px solid #00aaaa;
  border-top-right-radius: 4px;
  border-top-left-radius: 4px;
  border-bottom: none;
  margin: 3px 3px 0px 3px;
  font-family: ]] .. getFont() .. [[;
]]

local backgroundTabStyle = [[
  background-color: #000000;
  border: 1px solid #00aaaa;
  border-top-right-radius: 4px;
  border-top-left-radius: 4px;
  margin: 3px 3px 0px 3px;
  font-family: ]] .. getFont() .. [[;
]]

local vanish = [[
  background-color: #00000000;
]]


local function createTabbedPanel(tabData, container, tabList)
  tabData.tabs = {}
  tabData.contents = {}

  local tabContainerHeight = getFontSize()*2+4
  local tabContainer = Geyser.HBox:new({
    x = "2%", y = 0,
    width = "96%", height = tabContainerHeight,
  }, container)

  local contentsContainer = Geyser.Label:new({
    x = 0, y = tabContainerHeight,
    width = "100%",
  }, container)
  contentsContainer:setStyleSheet(vanish)

  lotj.layout.resizeTabContents(container, tabContainer, contentsContainer)
  lotj.setup.registerEventHandler("sysWindowResizeEvent", function()
    lotj.layout.resizeTabContents(container, tabContainer, contentsContainer)
  end)

  local totalSpace = 0
  for _, tabInfo in ipairs(tabList) do
    totalSpace = totalSpace + #tabInfo.label + 4 -- Account for 2 characters on either side as padding
  end

  for _, tabInfo in ipairs(tabList) do
    local keyword = tabInfo.keyword
    local label = tabInfo.label
    
    tabData.tabs[keyword] = Geyser.Label:new({
      h_stretch_factor = (#tabInfo.label + 4) / totalSpace,
    }, tabContainer)
    tabData.tabs[keyword]:setClickCallback("lotj.layout.selectTab", tabData, keyword)
    tabData.tabs[keyword]:setFontSize(getFontSize())
    tabData.tabs[keyword]:echo("<center>"..label)
    
    tabData.contents[keyword] = Geyser.Label:new({
      x = 0, y = 0,
      width = "100%",
      height = "100%",
    }, contentsContainer)
    tabData.contents[keyword]:setStyleSheet(backgroundTabStyle)
  end
end

function lotj.layout.selectTab(tabData, tabName)
  tabData.tabs[tabData.selectedTab]:setStyleSheet(inactiveTabStyle)
  tabData.tabs[tabData.selectedTab]:setBold(false)
  tabData.selectedTab = tabName

  for _, contents in pairs(tabData.contents) do
    contents:hide()
  end

  lotj.layout.markTabRead(tabData, tabName)
  tabData.tabs[tabName]:setBold(true)
  tabData.contents[tabName]:show()
  if tabName == "settings" then lotj.configWindow:show() end
end

function lotj.layout.markTabUnread(tabData, tabName)
  if tabData.selectedTab == tabName then return end
  if tabData.tabs[tabName].unread then return end

  tabData.tabs[tabName].unread = true
  tabData.tabs[tabName]:interpolate(notificationTabStyle)
end

function lotj.layout.markTabRead(tabData, tabName)
  tabData.tabs[tabName].unread = false
  tabData.tabs[tabName]:setStyleSheet(activeTabStyle)
end

-- Dynamically assess which tab to switch to based on keyboard input  
-- Ex: `selectTabNumber(lowerRightTabData, 3)` switches to third chat tab
function lotj.layout.selectTabNumber(tabData, number)
  local tabCount = #tabData.tabList
  if number > tabCount then number = tabCount end
  lotj.layout.selectTab(tabData, tabData.tabList[number].keyword)
end

function lotj.layout.resizeTabContents(parentContainer, tabContainer, contentsContainer)
  local newHeight = parentContainer:get_height()-tabContainer:get_height()
  contentsContainer:resize(nil, newHeight)
end

function setSizeOnResize()
  local newBorder = math.floor(lotj.layout.rightPanel:get_width())
  if getBorderRight() ~= newBorder then
    setBorderRight(newBorder)
    -- We could do this following line if we want the main window to set its text wrapping automatically.
    -- As-is, players will need to edit their mudlet settings to control this.
    -- setWindowWrap("main", getColumnCount("main")-3)
  end
end

function lotj.layout.setup()
  if lotj.layout.drawn then return end

  lotj.layout.rightPanel = Geyser.Container:new({
    width = rightPanelWidthPct.."%",
    x = (100-rightPanelWidthPct).."%",
    y = 0, height = "100%",
  })
  lotj.setup.registerEventHandler("sysWindowResizeEvent", setSizeOnResize)
  setSizeOnResize()


  -- Upper-right pane, for maps
  lotj.layout.upperContainer = Geyser.Container:new({
    name = "Maps",
    x = 0, y = 0,
    width = "100%",
    height = upperRightHeightPct.."%",
  }, lotj.layout.rightPanel)

  lotj.layout.upperRightTabData = {}

  lotj.layout.upperRightTabData.tabList = {}
  table.insert(lotj.layout.upperRightTabData.tabList, {keyword = "map", label = "Map"})
  table.insert(lotj.layout.upperRightTabData.tabList, {keyword = "system", label = "System"})
  table.insert(lotj.layout.upperRightTabData.tabList, {keyword = "galaxy", label = "Galaxy"})

  createTabbedPanel(lotj.layout.upperRightTabData, lotj.layout.upperContainer, lotj.layout.upperRightTabData.tabList)

  -- Lower-right panel, for chat history
  lotj.layout.lowerContainer = Geyser.Container:new({
    name = "Chat History",
    x = 0, y = upperRightHeightPct.."%",
    width = "100%",
    height = (100-upperRightHeightPct).."%",
  }, lotj.layout.rightPanel)

  lotj.layout.lowerRightTabData = {}

  lotj.layout.lowerRightTabData.tabList = {}
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "all", label = "All"})
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "local", label = "Local"})
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "commnet", label = "CommNet"})
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "clan", label = "Clan"})
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "broadcast", label = "Broadcast"})
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "ooc", label = "OOC"})
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "tell", label = "Tell"})
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "imm", label = "Imm"})
  if lotj.settings.debugMode then
    table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "debug", label = "Debug"})
  end

  -- Settings is a special case, don't try to echo to it like the others
  table.insert(lotj.layout.lowerRightTabData.tabList, {keyword = "settings", label = "⚙️"})

  createTabbedPanel(lotj.layout.lowerRightTabData, lotj.layout.lowerContainer, lotj.layout.lowerRightTabData.tabList)

  -- Hacky, but selectTab relies on these lines, do not delete
  lotj.layout.upperRightTabData.selectedTab = "map"
  lotj.layout.lowerRightTabData.selectedTab = "all"

  for _, tab in pairs(lotj.layout.upperRightTabData.tabs) do
    tab:setStyleSheet(inactiveTabStyle)
    tab:setBold(false)
  end

  for _, tab in pairs(lotj.layout.lowerRightTabData.tabs) do
    tab:setStyleSheet(inactiveTabStyle)
    tab:setBold(false)
  end

  -- Lower info panel, for prompt hp/move gauges and other basic status
  lotj.layout.lowerInfoPanelHeight = getFontSize()*2.5
  lotj.layout.lowerInfoPanel = Geyser.HBox:new({
    x = 0, y = -lotj.layout.lowerInfoPanelHeight,
    width = (100-rightPanelWidthPct).."%",
    height = lotj.layout.lowerInfoPanelHeight,
  })
  setBorderBottom(lotj.layout.lowerInfoPanelHeight)

  -- Ship overlay panel, shown just above the bottom info panel when piloting
  lotj.layout.shipOverlayHeight = getFontSize()*2.5
  lotj.layout.shipOverlay = Geyser.HBox:new({
    x = 0, y = -(lotj.layout.lowerInfoPanelHeight + lotj.layout.shipOverlayHeight),
    width = (100-rightPanelWidthPct).."%",
    height = lotj.layout.shipOverlayHeight,
  })
  lotj.layout.shipOverlay:hide()
  lotj.layout.drawn = true
end

function lotj.layout.teardown()
  lotj.layout.rightPanel:hide()
  lotj.layout.upperContainer:hide()
  lotj.layout.lowerContainer:hide()
  lotj.layout.lowerInfoPanel:hide()
  lotj.layout.shipOverlay:hide()
  setBorderRight(0)
  setBorderBottom(0)
  setBorderTop(0)
end
