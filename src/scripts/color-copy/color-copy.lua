-- Abort if the API isn't available. Mouse events become available on Mudlet version 4.13.
if addMouseEvent == nil then return end

function rgbToHex(r,g,b)
    local rgb = (r * 0x10000) + (g * 0x100) + b
    return string.format("%x", rgb)
end

local baseAnsiMap = {"&x","&r","&g","&O","&b","&p","&c","&w","&z","&R","&G","&Y","&B","&P","&C","&W"}
local colorCodes = {}

-- Map basic ANSI set
for i=0,15 do
  local hex = rgbToHex(unpack(color_table["ansi_" .. string.format("%03d", i)]))
  colorCodes[hex] = baseAnsiMap[i + 1]
end

-- Map the rest of 256 colors
for i=16,255 do
  local numStr = string.format("%03d", i)
  local hex = rgbToHex(unpack(color_table["ansi_" .. numStr]))
  colorCodes[hex] = "&" .. numStr
end

addMouseEvent("Copy with colors", "onCopyWithColors")

function onCopyWithColors(event, menu, window, startCol, startRow, endCol, endRow)
  if startCol == endCol and startRow == endRow then return end
  local parsed = ""
  local lastColor = nil
  for l = startRow, endRow do
    local cStart = l == startRow and startCol or 0
    moveCursor(window, cStart, l)
    local cEnd = l == endRow and endCol or #getCurrentLine() - 1
    for c = cStart, cEnd do
      selectSection(window, c, 1)
      local symbol = getSelection(window) or ""
      -- escape the tag symbol
      if symbol == "&" then symbol = "&&" end
      local color = rgbToHex(getFgColor(window))
      if color == lastColor then
        parsed = parsed .. symbol
      else
        lastColor = color
        -- Check whether the color is in the 256 set. Use gray (&w) for undefined colors.
        local cc = colorCodes[color] or "&#"..color
        parsed = parsed .. cc .. symbol
      end
    end
    if l ~= endRow then parsed = parsed .. "\n" end
  end
  setClipboardText(parsed)
end

registerAnonymousEventHandler("onCopyWithColors", "onCopyWithColors")