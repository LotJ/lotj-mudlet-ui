lotj = lotj or {}
lotj.layout = lotj.layout or {}

local rightPanelWidthPct = 40
local upperRightHeightPct = 50

local inactiveTabStyle = [[
  background-color: #333333;
  border: 1px solid #00aaaa;
  margin: 3px 3px 0px 3px;
  font-family: "Bitstream Vera Sans Mono";
]]

local activeTabStyle = [[
  background-color: #336666;
  border: 1px solid #00aaaa;
  border-bottom: none;
  margin: 3px 3px 0px 3px;
  font-family: "Bitstream Vera Sans Mono";
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
  end
end

function lotj.layout.selectTab(tabData, tabName)
  for _, tab in pairs(tabData.tabs) do
    tab:setStyleSheet(inactiveTabStyle)
    tab:setBold(false)
  end
  for _, contents in pairs(tabData.contents) do
    contents:hide()
  end

  tabData.tabs[tabName]:setStyleSheet(activeTabStyle)
  tabData.tabs[tabName]:setBold(true)
  tabData.contents[tabName]:show()
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
  lotj.setup.registerEventHandler("sysWindowResizeEvent", function()
    setSizeOnResize()
  end)
  setSizeOnResize()


  -- Upper-right pane, for maps
  lotj.layout.upperContainer = Geyser.Container:new({
    x = 0, y = 0,
    width = "100%",
    height = upperRightHeightPct.."%",
  }, lotj.layout.rightPanel)
  
  local upperTabList = {}
  table.insert(upperTabList, {keyword = "map", label = "Map"})
  table.insert(upperTabList, {keyword = "system", label = "System"})
  table.insert(upperTabList, {keyword = "galaxy", label = "Galaxy"})
  
  lotj.layout.upperRightTabData = {}
  createTabbedPanel(lotj.layout.upperRightTabData, lotj.layout.upperContainer, upperTabList)


  -- Lower-right panel, for chat history
  lotj.layout.lowerContainer = Geyser.Container:new({
    x = 0, y = upperRightHeightPct.."%",
    width = "100%",
    height = (100-upperRightHeightPct).."%",
  }, lotj.layout.rightPanel)

  local lowerTabList = {}
  table.insert(lowerTabList, {keyword = "all", label = "All"})
  table.insert(lowerTabList, {keyword = "local", label = "Local"})
  table.insert(lowerTabList, {keyword = "commnet", label = "CommNet"})
  table.insert(lowerTabList, {keyword = "clan", label = "Clan"})
  table.insert(lowerTabList, {keyword = "ooc", label = "OOC"})
  table.insert(lowerTabList, {keyword = "tell", label = "Tell"})
  table.insert(lowerTabList, {keyword = "imm", label = "Imm"})

  lotj.layout.lowerRightTabData = {}
  createTabbedPanel(lotj.layout.lowerRightTabData, lotj.layout.lowerContainer, lowerTabList)


  -- Lower info panel, for prompt hp/move gauges and other basic status
  lotj.layout.lowerInfoPanelHeight = getFontSize()*5
  lotj.layout.lowerInfoPanel = Geyser.HBox:new({
    x = 0, y = -lotj.layout.lowerInfoPanelHeight,
    width = (100-rightPanelWidthPct).."%",
    height = lotj.layout.lowerInfoPanelHeight,
  })
  setBorderBottom(lotj.layout.lowerInfoPanelHeight)
end

function lotj.layout.teardown()
  lotj.layout.rightPanel:hide()
  lotj.layout.upperContainer:hide()
  lotj.layout.lowerContainer:hide()
  lotj.layout.lowerInfoPanel:hide()
  setBorderRight(0)
  setBorderBottom(0)
end