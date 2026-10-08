lotj = lotj or {}
lotj.tutorial = lotj.tutorial or {}
lotj.tutorial.data = lotj.tutorial.data or {}
local path = getMudletHomeDir() .. "/lotj-ui-tutorial.lua"

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

--- Return values:
--- `1` : `v1` is newer
--- `-1`: `v2` is newer
--- `0` :  Versions are equal
function lotj.tutorial.compareVersions(v1, v2)
  -- Remove 'v' prefix if present
  v1 = v1:gsub("^v", "")
  v2 = v2:gsub("^v", "")

  -- Split versions into parts
  local v1_parts = {}
  local v2_parts = {}

  for num in v1:gmatch("%d+") do
    table.insert(v1_parts, tonumber(num))
  end

  for num in v2:gmatch("%d+") do
    table.insert(v2_parts, tonumber(num))
  end

  -- Compare each part
  for i = 1, math.max(#v1_parts, #v2_parts) do
    local v1_part = v1_parts[i] or 0
    local v2_part = v2_parts[i] or 0

    if v1_part < v2_part then
      return -1  -- v2 is newer
    elseif v1_part > v2_part then
      return 1   -- v1 is newer
    end
  end

  return 0  -- versions are equal
end

function lotj.tutorial.teardown()
  local els = lotj.tutorial.activeElements
  if not els then return end
  if els.cleanup then els.cleanup() end
  for _, g in ipairs(els) do
    if g and g.name then deleteLabel(g.name) end
  end
  if els.upperCon then deleteLabel(els.upperCon.name) end
  if els.lowerCon then deleteLabel(els.lowerCon.name) end
  if els.farewell  then deleteLabel(els.farewell.name)  end
  lotj.tutorial.activeElements = nil
end

--- This function contains all the code that will run when a user installs this
--- version of the package for the first time. There is no guarantee that the
--- user viewed the tutorial for the previous version, so only remove tutorial
--- features if absolutely necessary, prefer to add on.
function lotj.tutorial.run()
  lotj.tutorial.teardown()
  local tutorialElements = {}
  lotj.tutorial.activeElements = tutorialElements
  local flashTimerKillID = nil
  local labelCount = 0
  local fakeShipDataActive = false
  local currentStepIdx = 0

  local function hideTutorialElements()
    for _, g in ipairs(tutorialElements) do g:hide() end
    if tutorialElements.upperCon then tutorialElements.upperCon:hide() end
    if tutorialElements.lowerCon then tutorialElements.lowerCon:hide() end
    if tutorialElements.farewell  then tutorialElements.farewell:hide()  end
  end

  local function recursiveFlash(label)
    label:flash()
    flashTimerKillID = tempTimer(2, function()
      label:flash()
      recursiveFlash(label)
    end)
  end

  local function recursiveFlashMulti(labels)
    for _, lbl in ipairs(labels) do lbl:flash() end
    flashTimerKillID = tempTimer(2, function() recursiveFlashMulti(labels) end)
  end

  local function killFlash()
    if flashTimerKillID then killTimer(flashTimerKillID) end
  end

  local function clearFakeShipData()
    if fakeShipDataActive then
      lotj.infoPanel.setShipPreview(nil)
      fakeShipDataActive = false
    end
  end

  local function injectFakeShipData(piloting)
    lotj.infoPanel.setShipPreview({
      shield = 80, maxShield = 100,
      hull   = 95, maxHull   = 100,
      energy = 60, maxEnergy = 100,
      piloting = piloting ~= false,
      speed = 75, maxSpeed = 100,
      posX = 100, posY = 200, posZ = 50,
    })
    fakeShipDataActive = true
  end

  tutorialElements.cleanup = function()
    killFlash()
    clearFakeShipData()
  end

  local function sendRerunHint()
    cecho("[<cyan>LOTJ UI<reset>] Tutorial Complete. Rerun at any time with command: ")
    cechoLink("<cyan><u>lotj tutorial<reset>", [[lotj.tutorial.run()]], "Click to rerun the tutorial", true)
    cecho("\n")
  end

  local greenBtnStyle = [[QLabel { background-color: #004400; border: 1px solid #00aa00; border-radius: 3px; }]]
  local redBtnStyle   = [[QLabel { background-color: #440000; border: 1px solid #aa0000; border-radius: 3px; }]]
  local grayBtnStyle  = [[QLabel { background-color: #222222; border: 1px solid #555555; border-radius: 3px; }]]

  local function createHighlightOverlay(parent)
    labelCount = labelCount + 1
    local ov = Geyser.Label:new({
      name = "tutorial_ov_" .. labelCount,
      x = "0%", y = "0%", width = "100%", height = "100%",
    }, parent)
    ov:setStyleSheet([[QLabel { background-color: rgba(0,170,255,20); border: 2px solid #00aaff; border-radius: 3px; }]])
    ov:raiseAll()
    table.insert(tutorialElements, ov)
    return ov
  end

  local function createInfoLabel(message)
    if fakeShipDataActive then
      message = '<p style="color: #aaaaaa;">Tutorial preview: example ship values.</p>'..message
    end
    labelCount = labelCount + 1
    local lbl = Geyser.Label:new({
      name = "tutorial_info_" .. labelCount,
      x = "25%", y = "20%", width = "50%", height = "50%",
      fontSize = 14,
      message = "<center>" .. message .. "</center>",
    })
    lbl:setStyleSheet(style)
    table.insert(tutorialElements, lbl)
    return lbl
  end

  tutorialElements.upperCon = Geyser.Label:new({
    name = "tutorial_upperCon",
    x = "0%", y = "0%", width = "100%", height = "100%",
    fontSize = 14,
  }, lotj.layout.upperContainer)
  tutorialElements.upperCon:setStyleSheet(style)
  tutorialElements.upperCon:hide()

  tutorialElements.lowerCon = Geyser.Label:new({
    name = "tutorial_lowerCon",
    x = "0%", y = "0%", width = "100%", height = "100%",
    fontSize = 14,
  }, lotj.layout.lowerContainer)
  tutorialElements.lowerCon:setStyleSheet(style)
  tutorialElements.lowerCon:hide()

  local steps, goTo, goNext, goPrev, showNavButtons

  local function endTutorial()
    if currentStepIdx > 0 and steps and steps[currentStepIdx] and steps[currentStepIdx].cleanup then
      steps[currentStepIdx].cleanup()
    end
    clearFakeShipData()
    hideTutorialElements()
    lotj.tutorial.data.ran = true
    table.save(path, lotj.tutorial.data)
    sendRerunHint()
  end

  showNavButtons = function(container, idx)
    local total = #steps
    labelCount = labelCount + 1
    local base = "tutorial_nav_" .. labelCount
    local hasPrev = idx > 1
    local hasEnd  = idx < total
    local nextLabel = (idx == 1) and "Start Tutorial →" or (idx == total) and "Finish" or "Next →"
    local nextCb    = (idx == total) and function() endTutorial() end or function() goNext() end

    -- All buttons share the same row (y=85%, h=10%); widths vary by count
    local prevX, prevW, nextX, nextW, endX, endW
    if hasPrev and hasEnd then
      prevX, prevW = "3%",  "29%"
      nextX, nextW = "35%", "29%"
      endX,  endW  = "67%", "30%"
    elseif hasPrev then
      prevX, prevW = "5%",  "40%"
      nextX, nextW = "55%", "40%"
    else
      nextX, nextW = "5%",  "40%"
      endX,  endW  = "55%", "40%"
    end

    if hasPrev then
      local prevBtn = Geyser.Label:new({
        name = base .. "_prev",
        x = prevX, y = "85%", width = prevW, height = "10%",
        fontSize = 12,
        message = "<center>← Previous</center>",
      }, container)
      prevBtn:setStyleSheet(grayBtnStyle)
      prevBtn:setCursor("PointingHand")
      prevBtn:setClickCallback(function() goPrev() end)
      prevBtn:raiseAll()
      table.insert(tutorialElements, prevBtn)
    end

    local nextBtn = Geyser.Label:new({
      name = base .. "_next",
      x = nextX, y = "85%", width = nextW, height = "10%",
      fontSize = 12,
      message = "<center>" .. nextLabel .. "</center>",
    }, container)
    nextBtn:setStyleSheet(greenBtnStyle)
    nextBtn:setCursor("PointingHand")
    nextBtn:setClickCallback(nextCb)
    nextBtn:raiseAll()
    table.insert(tutorialElements, nextBtn)

    if hasEnd then
      local endBtn = Geyser.Label:new({
        name = base .. "_end",
        x = endX, y = "85%", width = endW, height = "10%",
        fontSize = 12,
        message = "<center>End Tutorial</center>",
      }, container)
      endBtn:setStyleSheet(redBtnStyle)
      endBtn:setCursor("PointingHand")
      endBtn:setClickCallback(function() endTutorial() end)
      endBtn:raiseAll()
      table.insert(tutorialElements, endBtn)
    end
  end

  goTo = function(idx)
    if currentStepIdx > 0 and steps[currentStepIdx] and steps[currentStepIdx].cleanup then
      steps[currentStepIdx].cleanup()
    end
    hideTutorialElements()
    currentStepIdx = idx
    local container = steps[idx].show()
    showNavButtons(container, idx)
  end

  goNext = function()
    if currentStepIdx < #steps then goTo(currentStepIdx + 1) end
  end

  goPrev = function()
    if currentStepIdx > 1 then goTo(currentStepIdx - 1) end
  end

  local function makeCategoryStep(categoryKey, title, body)
    local category
    local function resetCategory()
      killFlash()
      if category then
        category:setClickCallback(function() end)
        category:setCursor("Reset")
        category = nil
      end
    end
    return {
      show = function()
        lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
        local con = tutorialElements.upperCon
        con:clear()
        con:echo("<center>" .. title .. body .. "</center>")
        con:show()
        con:raiseAll()
        category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList[categoryKey]
        category:setClickCallback(resetCategory)
        category:setCursor("PointingHand")
        recursiveFlash(category)
        return lotj.layout.upperContainer
      end,
      cleanup = resetCategory,
    }
  end

  local mana_saved, mana_savedMax, mana_faking

  steps = {
    -- 1: Welcome
    {
      show = function()
        labelCount = labelCount + 1
        local lbl = Geyser.Label:new({
          name = "tutorial_info_" .. labelCount,
          x = "25%", y = "25%", width = "50%", height = "50%",
          fontSize = 14,
          message = [[<center>
          <p>Welcome to LOTJ Mudlet UI @VERSION@!</p>
          <p>Use the buttons below to start the feature tutorial<br>
          or dismiss it permanently</p>
          </center>]],
        })
        lbl:setStyleSheet(style)
        lbl:raiseAll()
        table.insert(tutorialElements, lbl)
        return lbl
      end,
    },
    -- 2: Status Bar
    {
      show = function()
        local ov1 = createHighlightOverlay(lotj.infoPanel.basicStatsContainer)
        local ov2 = createHighlightOverlay(lotj.infoPanel.combatContainer)
        local ov3 = createHighlightOverlay(lotj.infoPanel.chatContainer)
        recursiveFlashMulti({ov1, ov2, ov3})
        local lbl = createInfoLabel([[
          <h1>Status Bar</h1>
          <p>The bar at the bottom of your screen<br>
          shows your character's vitals</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 3: HP
    {
      show = function()
        local ov = createHighlightOverlay(lotj.infoPanel.healthGauge)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Hit Points</h1>
          <p>The red gauge shows your current HP<br>
          Keep a close eye on this during combat!<br></p>
          <p>The yellow line marks your <a href="send:help wimpy" style="color: #00aaff; text-decoration: underline;">wimpy</a> threshold (if set).</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 4: Movement
    {
      show = function()
        local ov = createHighlightOverlay(lotj.infoPanel.movementGauge)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Movement</h1>
          <p>The green gauge shows your current<br>
          movement points. Used when traveling<br>
          between rooms or using skills</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 5: Mana/Force
    {
      show = function()
        mana_saved    = gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.mana
        mana_savedMax = gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.maxMana
        mana_faking   = not mana_savedMax or mana_savedMax == 0
        if mana_faking then
          gmcp.Char = gmcp.Char or {}
          gmcp.Char.Vitals = gmcp.Char.Vitals or {}
          gmcp.Char.Vitals.maxMana = 100
          gmcp.Char.Vitals.mana    = 75
          raiseEvent("gmcp.Char.Vitals")
        end
        local ov = createHighlightOverlay(lotj.infoPanel.manaGauge)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Force</h1>
          <p>The blue gauge shows your Force<br>
          points (if your class uses them)<br>
          It stays hidden when not applicable</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = function()
        killFlash()
        if mana_faking then
          gmcp.Char.Vitals.maxMana = mana_savedMax or 0
          gmcp.Char.Vitals.mana    = mana_saved    or 0
          raiseEvent("gmcp.Char.Vitals")
        end
      end,
    },
    -- 6: Combat target
    {
      show = function()
        local ov = createHighlightOverlay(lotj.infoPanel.combatContainer)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Combat Target</h1>
          <p>The orange gauge shows the health<br>
          percentage of your current combat target</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 7: Comlink
    {
      show = function()
        local ov = createHighlightOverlay(lotj.infoPanel.chatContainer)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Commlink</h1>
          <p>This area shows your active commlink<br>
          channel and encryption code when<br>
          you have a commlink set</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 8: Ship intro (backward boundary: clears fake data on exit)
    {
      show = function()
        injectFakeShipData()
        local ov1 = createHighlightOverlay(lotj.infoPanel.shipGaugesContainer)
        local ov2 = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
        recursiveFlashMulti({ov1, ov2})
        local lbl = createInfoLabel([[
          <h1>Ship Status Bar</h1>
          <p>When you board a ship, a second status<br>
          bar appears with info about your ship</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = function()
        killFlash()
        clearFakeShipData()
      end,
    },
    -- 9: Shields
    {
      show = function()
        injectFakeShipData()
        local ov = createHighlightOverlay(lotj.infoPanel.shipShieldGauge)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Shields</h1>
          <p>The teal gauge shows your ship's<br>
          shield strength — shields absorb damage<br>
          before the hull takes hits</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 10: Hull
    {
      show = function()
        injectFakeShipData()
        local ov = createHighlightOverlay(lotj.infoPanel.shipHullGauge)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Hull</h1>
          <p>The gray gauge shows your ship's<br>
          structural integrity — if it reaches<br>
          zero the ship is destroyed</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 11: Energy
    {
      show = function()
        injectFakeShipData()
        local ov = createHighlightOverlay(lotj.infoPanel.shipEnergyGauge)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Energy</h1>
          <p>The yellow gauge shows your ship's<br>
          energy reserves — weapons, shields,<br>
          and engines all draw from this pool</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 12: Pilot inactive
    {
      show = function()
        injectFakeShipData(false)
        local ov = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Pilot Status</h1>
          <p>The ship icon shows whether you are<br>
          piloting the ship or just a passenger</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 13: Pilot active
    {
      show = function()
        injectFakeShipData(true)
        local ov = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Pilot Status (Active)</h1>
          <p>When you are at the controls the ship icon<br>
          lights up green to show you are piloting</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = killFlash,
    },
    -- 14: Speed & Coords (forward boundary: clears fake data on exit)
    {
      show = function()
        injectFakeShipData()
        local ov = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
        recursiveFlash(ov)
        local lbl = createInfoLabel([[
          <h1>Speed &amp; Coordinates</h1>
          <p>The arrow icon indicates your speed and the XYZ<br>
          icon shows your coordinates in the system</p>
        ]])
        lbl:raiseAll()
        return lbl
      end,
      cleanup = function()
        killFlash()
        clearFakeShipData()
      end,
    },
    -- 15: Map tab
    {
      show = function()
        lotj.layout.selectTab(lotj.layout.upperRightTabData, "map")
        local con = tutorialElements.lowerCon
        con:clear()
        con:echo([[<center>
        <h1>Map</h1>
        <p>The mapper tracks your position as you move<br>
        through the galaxy and records new rooms.</p>
        <p>You start with the Newbie Academy pre-mapped.<br>
        The rest of the galaxy you must map on your own.</p>
        <p>Use <a href="send:map help" style="color: #00aaff; text-decoration: underline;">map help</a> for commands and tips.</p>
        </center>]])
        con:show()
        con:raiseAll()
        return lotj.layout.lowerContainer
      end,
    },
    -- 16: System tab
    {
      show = function()
        lotj.layout.selectTab(lotj.layout.upperRightTabData, "system")
        local con = tutorialElements.lowerCon
        con:clear()
        con:echo([[<center>
        <h1>System</h1>
        <p>The system tab shows a visual radar of nearby<br>
        objects when in space</p>
        <p>Use the plus and minus buttons to change the<br>
        radar's zoom, and click the radar button to<br>
        refresh the radar's data</p>
        </center>]])
        con:show()
        con:raiseAll()
        return lotj.layout.lowerContainer
      end,
    },
    -- 17: Galaxy tab
    {
      show = function()
        lotj.layout.selectTab(lotj.layout.upperRightTabData, "galaxy")
        local con = tutorialElements.lowerCon
        con:clear()
        con:echo([[<center>
        <h1>Galaxy Map</h1>
        <p>This map will show all the publicly known planets.<br>
        A datapad is required to initialize and update.</p>
        <p>Use <a href="send:gmap" style="color: #00aaff; text-decoration: underline;">gmap</a> for a list of commands.</p>
        </center>]])
        con:show()
        con:raiseAll()
        return lotj.layout.lowerContainer
      end,
    },
    -- 18: Galaxy + button
    {
      show = function()
        lotj.layout.selectTab(lotj.layout.upperRightTabData, "galaxy")
        local ov = createHighlightOverlay(lotj.galaxyMap.addButton)
        recursiveFlash(ov)
        local con = tutorialElements.lowerCon
        con:clear()
        con:echo([[<center>
        <h1>Galaxy Map - Custom Locations</h1>
        <p>Use the flashing (+) button at the top right to manually<br>
        add locations to the map.</p>
        <p>Useful for marking points of interest,<br>
        or hidden planets and spacestations</p>
        <p>Note: The button is disabled for this step of the tutorial</p>
        </center>]])
        con:show()
        con:raiseAll()
        return lotj.layout.lowerContainer
      end,
      cleanup = killFlash,
    },
    -- 19: Galaxy right-click
    {
      show = function()
        lotj.layout.selectTab(lotj.layout.upperRightTabData, "galaxy")
        local con = tutorialElements.lowerCon
        con:clear()
        con:echo([[<center>
        <h1>Galaxy Map - Planet Context Menu</h1>
        <p>Right-clicking any planet or point on the map<br>
        will pop up with an interactive menu.</p>
        <p>You can calculate a jump, lookup planetary info, or<br>
        delete manually added locations.</p>
        </center>]])
        con:show()
        con:raiseAll()
        return lotj.layout.lowerContainer
      end,
    },
    -- 20: Settings intro
    {
      show = function()
        lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
        local con = tutorialElements.upperCon
        con:clear()
        con:echo([[<center>
        <h1>Settings</h1>
        <p>Below is the Settings tab</p>
        <p>Here you'll find all the settings the LotJ-UI can modify</p>
        </center>]])
        con:show()
        con:raiseAll()
        tempTimer(1  , function() lotj.chat["settings"]:flash(0.2) end)
        tempTimer(1.5, function() lotj.chat["settings"]:flash(0.2) end)
        tempTimer(2  , function() lotj.chat["settings"]:flash(0.2) end)
        return lotj.layout.upperContainer
      end,
    },
    -- 21: Gag Options
    makeCategoryStep("category_Gag_Options_lotj",
      "<h1>Settings - Gag Options</h1>",
      [[<p>These options enable gagging various channels from the main<br>
      window and only show them in the chat tabs.</p>]]
    ),
    -- 22: Keybinds
    makeCategoryStep("category_Keybinds_lotj",
      "<h1>Settings - Keybinds</h1>",
      [[<p>These settings enable various directional actions with the numpad.</p>]]
    ),
    -- 23: Notifications
    makeCategoryStep("category_Notification_Settings_lotj",
      "<h1>Settings - Notification Settings</h1>",
      [[<p>Enabling any of these will make their respective<br>
      tabs flash when they receive a new message</p>]]
    ),
    -- 24: Extras
    makeCategoryStep("category_Extras_lotj",
      "<h1>Settings - Extras</h1>",
      [[<p>Miscellaneous or uncategorized settings.</p>
      <p>Used to enable study triggers and clickable change logs</p>]]
    ),
    -- 25: GUI Preferences
    makeCategoryStep("category_GUI_Preferences_lotj",
      "<h1>Settings - GUI Preferences</h1>",
      [[<p>Click to toggle which tabs you want in focus on startup.</p>]]
    ),
    -- 26: Logging
    makeCategoryStep("category_Logging_lotj",
      "<h1>Settings - Logging</h1>",
      [[<p>Toggles logging. Logs start and end<br>
      on connect/disconnect events</p>
      <p>Timer option will automatically stop<br>
      and start a new log daily</p>
      <p>Log files save in the default log directory<br>
      in a folder labeled with the character's name.</p>
      <p>Can use TXT or HTML. Use HTML to save in color.</p>]]
    ),
    -- 27: Debug Options
    makeCategoryStep("category_Debug_Options_lotj",
      "<h1>Settings - Debug</h1>",
      [[<p>Advanced settings for developers who<br>
      like to play with GMCP.</p>
      <p>Must click the <b>Reload Profile</b> button for<br>
      the debug tab to show after enabling.</p>
      <p>The input field can be used to run Lua code<br>
      right from the debug tab.</p>]]
    ),
    -- 28: Bottom buttons
    {
      show = function()
        lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
        local con = tutorialElements.upperCon
        con:clear()
        con:echo([[<center>
        <h1>Settings - Buttons</h1>
        <p>Buttons on the bottom will save, load, <br>or reset settings to default.</p>
        <p>Changes will impact the current session, but must be saved<br>
        if you want them to persist after closing and re-opening.</p>
        <p>Use load to revert back to your last saved state.</p>
        <p>Reload the profile if an unexpected UI bug occurs</p>
        </center>]])
        con:show()
        con:raiseAll()
        recursiveFlashMulti({
          lotj.configWindow.buttons[1],
          lotj.configWindow.buttons[2],
          lotj.configWindow.buttons[3],
          lotj.configWindow.buttons[4],
        })
        return lotj.layout.upperContainer
      end,
      cleanup = killFlash,
    },
    -- 29: Farewell
    {
      show = function()
        local discord_link = (gmcp.External and gmcp.External.Discord and gmcp.External.Discord.Info and gmcp.External.Discord.Info.inviteurl) or "https://discord.gg/f7tajUT"
        if not tutorialElements.farewell then
          tutorialElements.farewell = Geyser.Label:new({
            name = "tutorial_farwell",
            x = "25%", y = "25%", width = "50%", height = "50%",
            fontSize = 14,
          })
          tutorialElements.farewell:setStyleSheet(style)
        end
        tutorialElements.farewell:echo([[<center>
        <p>You made it to the end of the tutorial.</p>
        <h1>Welcome to Legends of the Jedi!</h1>
        <p>We're a very welcoming community. If you get lost or have questions,<br>
        don't hesitate to reach out for help on the OOC channel or Discord.</p>
        <p>Join our <a href="]]..discord_link..[[" style="color: #00aaff; text-decoration: underline;">Discord</a></p>
        <p>Visit our official <a href="https://legendsofthejedi.com" style="color: #00aaff; text-decoration: underline;">website</p>
        </center>]])
        tutorialElements.farewell:show()
        tutorialElements.farewell:raiseAll()
        lotj.tutorial.data.ran = true
        table.save(path, lotj.tutorial.data)
        return tutorialElements.farewell
      end,
    },
  }

  goTo(1)
end

function lotj.tutorial.setup()
  lotj.tutorial.data = {}
  local version = getPackageInfo("@PKGNAME@").version

  if io.exists(path) then
    table.load(path, lotj.tutorial.data)
  else
    lotj.tutorial.data = {
      newest = version,
      ran = false
    }
    table.save(path, lotj.tutorial.data)
  end

  local out = lotj.tutorial.compareVersions(version, lotj.tutorial.data.newest or "0")
  -- We have the same version
  if out == 0 then
    -- Tutorial has already run
    if lotj.tutorial.data.ran then
      return
    -- Tutorial has not run
    else
      lotj.setup.registerEventHandler("lotjUiLoaded", lotj.tutorial.run)
    end
  -- The stored version is newer - probably shouldn't happen
  elseif out == -1 then
    return
  -- We have installed a new version
  elseif out == 1 then
    -- No need to check if the tutorial has already run
    lotj.tutorial.data.ran = false
    lotj.tutorial.data.newest = version
    lotj.setup.registerEventHandler("lotjUiLoaded", lotj.tutorial.run)
  end
end
