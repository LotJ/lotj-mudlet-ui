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

  local tabContainer = Geyser.HBox:new({
    x = "2%", y = 0,
    width = "96%", height = 30,
  }, container)

  local contentsContainer = Geyser.Label:new({
    x = 0, y = 30,
    width = "100%",
  }, container)

  lotj.layout.resizeTabContents(container, tabContainer, contentsContainer)
  registerAnonymousEventHandler("sysWindowResizeEvent", function()
    lotj.layout.resizeTabContents(container, tabContainer, contentsContainer)
  end)

  for _, tabInfo in ipairs(tabList) do
    local keyword = tabInfo.keyword
    local label = tabInfo.label
    
    tabData.tabs[keyword] = Geyser.Label:new({}, tabContainer)
    tabData.tabs[keyword]:setClickCallback("lotj.layout.selectTab", tabData, keyword)
    tabData.tabs[keyword]:setFontSize(12)
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


registerAnonymousEventHandler("sysLoadEvent", function()
  local rightPanel = Geyser.Container:new({
    width = rightPanelWidthPct.."%",
    x = (100-rightPanelWidthPct).."%",
    y = 0, height = "100%",
  })
  registerAnonymousEventHandler("sysWindowResizeEvent", function()
    local newBorder = math.floor(rightPanel:get_width())
    if getBorderRight() ~= newBorder then
      setBorderRight(newBorder)
    end
  end)


  -- Upper-right pane, for maps
  local upperContainer = Geyser.Container:new({
    x = 0, y = 0,
    width = "100%",
    height = upperRightHeightPct.."%",
  }, rightPanel)
  
  local upperTabList = {}
  table.insert(upperTabList, {keyword = "map", label = "Map"})
  table.insert(upperTabList, {keyword = "system", label = "System"})
  table.insert(upperTabList, {keyword = "galaxy", label = "Galaxy"})
  
  lotj.layout.upperRightTabData = {}
  createTabbedPanel(lotj.layout.upperRightTabData, upperContainer, upperTabList)


  -- Lower-right panel, for chat history
  local lowerContainer = Geyser.Container:new({
    x = 0, y = upperRightHeightPct.."%",
    width = "100%",
    height = (100-upperRightHeightPct).."%",
  }, rightPanel)

  local lowerTabList = {}
  table.insert(lowerTabList, {keyword = "all", label = "All"})
  table.insert(lowerTabList, {keyword = "commnet", label = "CommNet"})
  table.insert(lowerTabList, {keyword = "clan", label = "Clan"})
  table.insert(lowerTabList, {keyword = "ooc", label = "OOC"})
  table.insert(lowerTabList, {keyword = "tell", label = "Tell"})
  table.insert(lowerTabList, {keyword = "imm", label = "Imm"})

  lotj.layout.lowerRightTabData = {}
  createTabbedPanel(lotj.layout.lowerRightTabData, lowerContainer, lowerTabList)


  -- Lower info panel, for prompt hp/move gauges and other basic status
  lotj.layout.lowerInfoPanel = Geyser.HBox:new({
    x = 0, y = -60,
    width = (100-rightPanelWidthPct).."%",
    height = 60,
  })
  setBorderBottom(60)

  raiseEvent("lotjUICreated")

  lotj.layout.selectTab(lotj.layout.upperRightTabData, "map")
  lotj.layout.selectTab(lotj.layout.lowerRightTabData, "all")
end)
