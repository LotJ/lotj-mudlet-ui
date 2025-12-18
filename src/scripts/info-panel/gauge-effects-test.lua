lotj = lotj or {}
lotj.test = lotj.test or {}

-- Test gauge effects - various visual styles to preview
-- To hide all test gauges: lotj.test.hideAll()

-- Color palette definitions
lotj.test.colorPalette = {
  {name = "Cyan", baseColor = "#00b2b2", colors = {"#31d0d0", "#22cfcf", "#00b2b2", "#009494", "#00b2b2"}, darkColors = {"#113f3f", "#073f3f", "#003333", "#002222", "#001111"}},
  {name = "Blue", baseColor = "#2020cc", colors = {"#5050ff", "#4040ee", "#3030dd", "#2020cc", "#1010bb"}, darkColors = {"#1a1a4f", "#161645", "#12123a", "#0c0c38", "#08082a"}},
  {name = "Purple", baseColor = "#8800ff", colors = {"#aa33ff", "#9922ee", "#8800ff", "#6600cc", "#8800ff"}, darkColors = {"#2f113f", "#270a3f", "#220038", "#180025", "#0f0018"}},
  {name = "Magenta", baseColor = "#ff00ff", colors = {"#ff33ff", "#ee22ee", "#ff00ff", "#cc00cc", "#ff00ff"}, darkColors = {"#3f113f", "#3f073f", "#330033", "#220022", "#110011"}},
  {name = "Pink", baseColor = "#ff66b2", colors = {"#ff99cc", "#ff88bb", "#ff66b2", "#dd4488", "#ff66b2"}, darkColors = {"#5a2545", "#4a1f38", "#4a1f38", "#381525", "#381525"}},
  {name = "Red", baseColor = "#ff3333", colors = {"#ff6666", "#ff4444", "#ff2222", "#cc1111", "#ff2222"}, darkColors = {"#4f2020", "#401010", "#350000", "#250000", "#2f0000"}},
  {name = "Orange", baseColor = "#ff8800", colors = {"#ff9933", "#ff8822", "#ff8800", "#dd7700", "#ff8800"}, darkColors = {"#3f2611", "#3f2207", "#331c00", "#221400", "#110a00"}},
  {name = "Yellow", baseColor = "#ffcc00", colors = {"#ffdd33", "#ffcc22", "#ffcc00", "#ccaa00", "#ffcc00"}, darkColors = {"#483800", "#3f3007", "#332800", "#221c00", "#110e00"}},
  {name = "Lime", baseColor = "#88ff00", colors = {"#aaff33", "#99ff22", "#88ff00", "#66cc00", "#88ff00"}, darkColors = {"#2f5a11", "#254a07", "#1f3800", "#152800", "#0a1400"}},
  {name = "Green", baseColor = "#00cc00", colors = {"#33ff33", "#22ee22", "#11dd11", "#00cc00", "#009900"}, darkColors = {"#1a4f1a", "#164516", "#123a12", "#003800", "#002a00"}},
  {name = "Teal", baseColor = "#00cc88", colors = {"#33eeaa", "#11dd99", "#00cc88", "#009966", "#00aa77"}, darkColors = {"#204f3a", "#104030", "#003525", "#002519", "#002f22"}},
  {name = "Sky Blue", baseColor = "#00ccff", colors = {"#33ddff", "#22d3ff", "#00ccff", "#00aadd", "#00ccff"}, darkColors = {"#11373f", "#0a343f", "#003038", "#002228", "#001118"}},
  {name = "Indigo", baseColor = "#6600cc", colors = {"#8833ee", "#7722dd", "#6600cc", "#5500aa", "#6600cc"}, darkColors = {"#2f113f", "#220a3f", "#220038", "#1a002a", "#150025"}},
  {name = "Rose", baseColor = "#ff0088", colors = {"#ff33aa", "#ff22aa", "#ff0088", "#cc0066", "#ff0088"}, darkColors = {"#3f112f", "#3f0a2f", "#330025", "#220018", "#110010"}},
  {name = "Gold", baseColor = "#ddaa00", colors = {"#ffcc33", "#eebb22", "#ddaa00", "#bb8800", "#ddaa00"}, darkColors = {"#3f3500", "#3f3007", "#332800", "#221c00", "#110e00"}},
  {name = "Emerald", baseColor = "#00aa55", colors = {"#33dd88", "#11cc77", "#00aa55", "#008844", "#00aa55"}, darkColors = {"#113f2a", "#0a3f22", "#003819", "#002212", "#001f11"}},
}

-- Style template functions - these create style CSS based on color palette
lotj.test.styleTemplates = {
  -- Style 1: Vertical Gradient
  [1] = {
    name = "Vertical Gradient",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border-top: 1px solid rgba(0, 0, 0, 180);
        border-left: 1px solid rgba(0, 0, 0, 180);
        border-bottom: 1px solid rgba(0, 0, 0, 180);
        border-right: 1px solid rgba(255, 255, 255, 40);
        border-radius: 3px;
        padding: 3px;
      ]], c[1], c[2], c[3], c[4], c[5])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border-top: 1px solid rgba(0, 0, 0, 180);
        border-left: 1px solid rgba(0, 0, 0, 180);
        border-bottom: 1px solid rgba(0, 0, 0, 180);
        border-right: 1px solid rgba(0, 0, 0, 200);
        border-radius: 3px;
        padding: 3px;
      ]], c[1], c[2], c[3], c[4], c[5])
    end
  },

  -- Style 2: Enhanced Glossy
  [2] = {
    name = "Enhanced Glossy",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1,
          stop: 0 %s,
          stop: 0.05 %s,
          stop: 0.1 %s,
          stop: 0.45 %s,
          stop: 0.5 %s,
          stop: 0.55 %s,
          stop: 1 %s);
        border-top: 1px solid rgba(255, 255, 255, 100);
        border-left: 1px solid rgba(255, 255, 255, 60);
        border-bottom: 1px solid rgba(0, 0, 0, 200);
        border-right: 1px solid rgba(255, 255, 255, 80);
        border-radius: 4px;
        padding: 3px;
      ]], c[1], c[2], c[3], c[4], c[5], c[4], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1,
          stop: 0 %s,
          stop: 0.05 %s,
          stop: 0.1 %s,
          stop: 0.45 %s,
          stop: 0.5 %s,
          stop: 0.55 %s,
          stop: 1 %s);
        border-top: 1px solid rgba(255, 255, 255, 20);
        border-left: 1px solid rgba(255, 255, 255, 10);
        border-bottom: 1px solid rgba(0, 0, 0, 200);
        border-right: 1px solid rgba(255, 255, 255, 15);
        border-radius: 4px;
        padding: 3px;
      ]], c[1], c[2], c[3], c[4], c[5], c[4], c[3])
    end
  },

  -- Style 3: Inner Shadow/Glow
  [3] = {
    name = "Inner Shadow/Glow",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: inset 0 2px 4px rgba(0, 0, 0, 150), inset 0 -2px 4px rgba(255, 255, 255, 50);
      ]], c[1], c[2], c[3], c[4], c[5], c[1])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: inset 0 2px 4px rgba(0, 0, 0, 200), inset 0 -2px 4px rgba(255, 255, 255, 10);
      ]], c[1], c[2], c[3], c[4], c[5], c[1])
    end
  },

  -- Style 4: Outer Glow
  [4] = {
    name = "Outer Glow",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border: 1px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: 0 0 8px %s, 0 0 4px %s;
      ]], c[1], c[2], c[3], c[4], c[5], c[1], c[1], c[2])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border: 1px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: 0 0 4px %s, 0 0 2px %s;
      ]], c[1], c[2], c[3], c[4], c[5], c[1], c[1], c[2])
    end
  },

  -- Style 5: Horizontal Shimmer
  [5] = {
    name = "Horizontal Shimmer",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 %s, stop: 0.3 %s, stop: 0.5 %s, stop: 0.7 %s, stop: 1 %s);
        border-top: 1px solid rgba(0, 0, 0, 180);
        border-left: 1px solid rgba(0, 0, 0, 180);
        border-bottom: 1px solid rgba(0, 0, 0, 180);
        border-right: 1px solid rgba(255, 255, 255, 40);
        border-radius: 3px;
        padding: 3px;
      ]], c[4], c[3], c[1], c[3], c[4])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 %s, stop: 0.3 %s, stop: 0.5 %s, stop: 0.7 %s, stop: 1 %s);
        border-top: 1px solid rgba(0, 0, 0, 180);
        border-left: 1px solid rgba(0, 0, 0, 180);
        border-bottom: 1px solid rgba(0, 0, 0, 180);
        border-right: 1px solid rgba(0, 0, 0, 200);
        border-radius: 3px;
        padding: 3px;
      ]], c[5], c[3], c[1], c[3], c[5])
    end
  },

  -- Style 6: Metallic
  [6] = {
    name = "Metallic",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.2 %s, stop: 0.4 %s, stop: 0.5 %s, stop: 0.6 %s, stop: 0.8 %s, stop: 1 %s);
        border: 1px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 1px 1px rgba(255, 255, 255, 100), inset 0 -1px 1px rgba(0, 0, 0, 100);
      ]], c[1], c[2], c[3], c[4], c[3], c[2], c[3], c[4])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.2 %s, stop: 0.4 %s, stop: 0.5 %s, stop: 0.6 %s, stop: 0.8 %s, stop: 1 %s);
        border: 1px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 1px 1px rgba(255, 255, 255, 20), inset 0 -1px 1px rgba(0, 0, 0, 150);
      ]], c[1], c[2], c[3], c[4], c[3], c[2], c[3], c[5])
    end
  },

  -- Style 7: Glass/Transparent
  [7] = {
    name = "Glass/Transparent",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 2px 6px rgba(255, 255, 255, 100), 0 0 12px %s;
      ]], c[1], c[2], c[3], c[4], c[1], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 2px 6px rgba(255, 255, 255, 20), 0 0 6px %s;
      ]], c[1], c[2], c[3], c[4], c[1], c[4])
    end
  },

  -- Style 8: Bold Flat
  [8] = {
    name = "Bold Flat",
    front = function(c)
      return string.format([[
        background-color: %s;
        border: 3px solid %s;
        border-radius: 2px;
        padding: 3px;
        box-shadow: 0 0 6px %s;
      ]], c[3], c[1], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: %s;
        border: 3px solid %s;
        border-radius: 2px;
        padding: 3px;
        box-shadow: 0 0 3px %s;
      ]], c[3], c[1], c[4])
    end
  },

  -- Style 9: Shimmer + Strong Borders
  [9] = {
    name = "Shimmer + Strong Borders",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 %s, stop: 0.3 %s, stop: 0.5 %s, stop: 0.7 %s, stop: 1 %s);
        border: 3px solid %s;
        border-radius: 2px;
        padding: 3px;
        box-shadow: 0 0 6px %s;
      ]], c[4], c[3], c[1], c[3], c[4], c[1], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 1, y2: 0, stop: 0 %s, stop: 0.3 %s, stop: 0.5 %s, stop: 0.7 %s, stop: 1 %s);
        border: 3px solid %s;
        border-radius: 2px;
        padding: 3px;
        box-shadow: 0 0 3px %s;
      ]], c[5], c[3], c[1], c[3], c[5], c[1], c[4])
    end
  },

  -- Style 10: Glossy + Outer Glow
  [10] = {
    name = "Glossy + Outer Glow",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.05 %s, stop: 0.1 %s, stop: 0.45 %s, stop: 0.5 %s, stop: 0.55 %s, stop: 1 %s);
        border: 1px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: 0 0 8px %s, 0 0 4px %s;
      ]], c[1], c[2], c[3], c[3], c[5], c[3], c[3], c[1], c[3], c[2])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.05 %s, stop: 0.1 %s, stop: 0.45 %s, stop: 0.5 %s, stop: 0.55 %s, stop: 1 %s);
        border: 1px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: 0 0 4px %s, 0 0 2px %s;
      ]], c[1], c[2], c[3], c[3], c[5], c[3], c[3], c[1], c[3], c[4])
    end
  },

  -- Style 11: Metallic + Strong Borders
  [11] = {
    name = "Metallic + Strong Borders",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.2 %s, stop: 0.4 %s, stop: 0.5 %s, stop: 0.6 %s, stop: 0.8 %s, stop: 1 %s);
        border: 3px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 1px 1px rgba(255, 255, 255, 100), 0 0 6px %s;
      ]], c[1], c[2], c[3], c[4], c[3], c[2], c[3], c[1], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.2 %s, stop: 0.4 %s, stop: 0.5 %s, stop: 0.6 %s, stop: 0.8 %s, stop: 1 %s);
        border: 3px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 1px 1px rgba(255, 255, 255, 20), 0 0 3px %s;
      ]], c[1], c[2], c[3], c[4], c[3], c[2], c[3], c[1], c[4])
    end
  },

  -- Style 12: Glass + Enhanced Inner Shadow
  [12] = {
    name = "Glass + Inner Shadow",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 3px 6px rgba(0, 0, 0, 180), inset 0 -3px 6px rgba(255, 255, 255, 80), 0 0 12px %s;
      ]], c[1], c[2], c[3], c[4], c[1], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 5px;
        padding: 3px;
        box-shadow: inset 0 3px 6px rgba(0, 0, 0, 220), inset 0 -3px 6px rgba(255, 255, 255, 20), 0 0 6px %s;
      ]], c[1], c[2], c[3], c[4], c[1], c[4])
    end
  },

  -- Style 13: Diagonal Gradient
  [13] = {
    name = "Diagonal Gradient",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 1, y2: 1, stop: 0 %s, stop: 0.3 %s, stop: 0.5 %s, stop: 0.7 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
      ]], c[4], c[3], c[1], c[3], c[4], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 1, y2: 1, stop: 0 %s, stop: 0.3 %s, stop: 0.5 %s, stop: 0.7 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
      ]], c[5], c[3], c[1], c[3], c[5], c[3])
    end
  },

  -- Style 14: Double Border
  [14] = {
    name = "Double Border",
    front = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 150), 0 0 8px %s;
      ]], c[1], c[2], c[3], c[4], c[3], c[1], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 %s, stop: 0.1 %s, stop: 0.49 %s, stop: 0.5 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
        box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 200), 0 0 4px %s;
      ]], c[1], c[2], c[3], c[4], c[5], c[1], c[4])
    end
  },

  -- Style 15: Neon Glow
  [15] = {
    name = "Neon Glow",
    front = function(c)
      return string.format([[
        background-color: %s;
        border: 2px solid %s;
        border-radius: 3px;
        padding: 3px;
        box-shadow: 0 0 12px %s, 0 0 6px %s, inset 0 0 8px %s;
      ]], c[3], c[1], c[1], c[1], c[1])
    end,
    back = function(c)
      return string.format([[
        background-color: %s;
        border: 2px solid %s;
        border-radius: 3px;
        padding: 3px;
        box-shadow: 0 0 6px %s, 0 0 3px %s, inset 0 0 4px %s;
      ]], c[3], c[1], c[1], c[1], c[1])
    end
  },

  -- Style 16: Radial Gradient
  [16] = {
    name = "Radial Gradient",
    front = function(c)
      return string.format([[
        background-color: QRadialGradient( cx: 0.5, cy: 0.5, radius: 1, stop: 0 %s, stop: 0.3 %s, stop: 0.7 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
      ]], c[1], c[3], c[4], c[4], c[3])
    end,
    back = function(c)
      return string.format([[
        background-color: QRadialGradient( cx: 0.5, cy: 0.5, radius: 1, stop: 0 %s, stop: 0.3 %s, stop: 0.7 %s, stop: 1 %s);
        border: 2px solid %s;
        border-radius: 4px;
        padding: 3px;
      ]], c[1], c[3], c[5], c[4], c[3])
    end
  },
}

function lotj.test.createEffectSamples()
  if lotj.test.container then
    lotj.test.hideAll()
    return
  end

  -- Main test container - adjustable/draggable container
  lotj.test.container = Adjustable.Container:new({
    name = "testGaugeContainer",
    x = "2%", y = "2%",
    width = "35%", height = "95%",
  })

  local testBg = Geyser.Label:new({
    x = 0, y = 0,
    width = "100%", height = "100%",
  }, lotj.test.container)
  testBg:setStyleSheet([[
    background-color: rgba(20, 20, 20, 230);
    border: 2px solid #00aaaa;
    border-radius: 5px;
  ]])

  -- Title
  local title = Geyser.Label:new({
    x = "5%", y = "2%",
    width = "90%", height = 30,
  }, lotj.test.container)
  title:echo("<center><b>Gauge Visual Effect Tests</b> - Click colors to change</center>", nil, "c14")

  -- Instructions
  local instructions = Geyser.Label:new({
    x = "5%", y = "8%",
    width = "60%", height = 20,
  }, lotj.test.container)
  instructions:echo("<center>Run: <yellow>lotj.test.hideAll()</yellow> to close</center>", nil, "c11")

  -- Randomize button
  local randomizeButton = Geyser.Label:new({
    x = "67%", y = "8%",
    width = "28%", height = 20,
  }, lotj.test.container)
  randomizeButton:setStyleSheet([[
    background-color: #336666;
    border: 1px solid #00aaaa;
    border-radius: 3px;
  ]])
  randomizeButton:echo("<center><b>Randomize Values</b></center>", nil, "c11")
  randomizeButton:setClickCallback(function()
    lotj.test.randomizeGauges()
  end)

  -- Color palette section - vertical strip on right side
  local paletteStartY = 80
  local paletteX = "96%"
  local paletteSquareSize = 22
  local paletteSpacing = 27

  lotj.test.colorSquares = {}

  for i, colorDef in ipairs(lotj.test.colorPalette) do
    local square = Geyser.Label:new({
      x = paletteX, y = paletteStartY + (i-1) * paletteSpacing,
      width = paletteSquareSize, height = paletteSquareSize,
    }, lotj.test.container)
    square:setStyleSheet([[
      background-color: ]]..colorDef.baseColor..[[;
      border: 2px solid #666666;
      border-radius: 3px;
    ]])
    square:setClickCallback(function()
      lotj.test.applyColorToAllGauges(i)
    end)
    square:setToolTip(colorDef.name)
    lotj.test.colorSquares[i] = square
  end

  local gaugeWidth = "42%"  -- Narrower to make room for color palette
  local gaugeHeight = 30
  local startY = 80  -- Start after title and instructions
  local spacing = gaugeHeight + 45  -- Space for label + gauge + gap
  local leftColumnX = "2%"
  local rightColumnX = "49%"  -- Start right column closer due to narrower gauges

  -- Create test gauges with different styles
  lotj.test.gauges = {}
  lotj.test.currentColor = 1  -- Start with Cyan

  -- Get the color palette for initial gauges
  local colorDef = lotj.test.colorPalette[lotj.test.currentColor]

  -- Create all 16 gauges using templates
  for i = 1, 16 do
    local yPos = startY + ((i-1) % 8) * spacing
    local xPos = (i <= 8) and leftColumnX or rightColumnX
    local template = lotj.test.styleTemplates[i]
    local label = i .. ". " .. template.name

    lotj.test.createTestGauge(i, yPos, xPos, gaugeWidth, gaugeHeight, label, colorDef.colors, colorDef.darkColors, i)
  end

  cecho("\n<green>Test gauge panel created! Click color squares to change all gauges.\n")
  cecho("<green>Run <yellow>lotj.test.hideAll()<green> when done.\n")
end

function lotj.test.createTestGauge(index, yPos, xPos, width, height, label, colors, darkColors, styleIndex)
  -- Label for this style
  local labelWidget = Geyser.Label:new({
    x = xPos, y = yPos,
    width = width, height = 18,
  }, lotj.test.container)
  labelWidget:echo("<b>"..label.."</b>", nil, "l10")

  -- The gauge itself
  local gauge = Geyser.Gauge:new({
    x = xPos, y = yPos + 20,
    width = width, height = height,
  }, lotj.test.container)

  -- Apply styles using the template
  local template = lotj.test.styleTemplates[styleIndex]
  gauge.front:setStyleSheet(template.front(colors))
  gauge.back:setStyleSheet(template.back(darkColors))

  gauge:setValue(750, 1000, "Shield: 750/1000")
  gauge:setFontSize(getFontSize())

  lotj.test.gauges[index] = {
    gauge = gauge,
    label = labelWidget,
    styleIndex = styleIndex
  }
end

function lotj.test.applyColorToAllGauges(colorIndex)
  if not lotj.test.gauges then return end

  lotj.test.currentColor = colorIndex
  local colorDef = lotj.test.colorPalette[colorIndex]

  -- Update all gauges with the new color
  for _, gaugeData in pairs(lotj.test.gauges) do
    local template = lotj.test.styleTemplates[gaugeData.styleIndex]
    gaugeData.gauge.front:setStyleSheet(template.front(colorDef.colors))
    gaugeData.gauge.back:setStyleSheet(template.back(colorDef.darkColors))
  end

  cecho("\n<green>Applied <yellow>"..colorDef.name.."<green> color to all gauges!\n")
end

function lotj.test.randomizeGauges()
  if not lotj.test.gauges then return end

  for _, gaugeData in pairs(lotj.test.gauges) do
    local maxValue = 1000
    local currentValue = math.random(0, maxValue)
    gaugeData.gauge:setValue(currentValue, maxValue, "Shield: "..currentValue.."/"..maxValue)
  end

  cecho("\n<green>Gauge values randomized!\n")
end

function lotj.test.hideAll()
  if lotj.test.container then
    lotj.test.container:hide()
    lotj.test.container = nil
    lotj.test.gauges = nil
    lotj.test.colorSquares = nil
    cecho("\n<green>Test gauge panel hidden.\n")
  end
end

-- Auto-create when this file loads
lotj.test.createEffectSamples()
lotj.test.container:show()
