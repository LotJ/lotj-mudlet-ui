---@diagnostic disable-next-line: deprecated
table.unpack = table.unpack or unpack

local text = matches[2]
local granularity = tonumber(matches[3]) or 1
local mode = matches[4] or "rgb"
local colors = string.split(matches[5]:sub(2), " ")

-- Convert mixed ANSI / hex inputs into RGB tables
local gradargs = parseMixedColors(colors)

-- Always pass mode explicitly (no implied defaults)
local codedString = lotjgradient(
  text,
  granularity,
  mode,
  table.unpack(gradargs)
)

send(codedString)
