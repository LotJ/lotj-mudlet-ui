---@diagnostic disable: param-type-mismatch
-- lotj-gradient.lua
-- 24-bit color gradient rendering for LoTJ / Mudlet
-- Contract:
--   lotjgradient(text, granularity, mode, {r,g,b}, {r,g,b}, ...)

------------------------------------------------------------
-- Utilities
------------------------------------------------------------

ansiColors = {}
for key, value in pairs(color_table) do
  if key:match("^ansi_%d+$") then
    ansiColors[key:gsub("ansi_", "")] = value
  end
end

local function clamp(v, lo, hi)
  return math.min(hi, math.max(lo, v))
end

local function rgb2hex(rgb)
  return string.format("%02x%02x%02x", rgb[1], rgb[2], rgb[3])
end

------------------------------------------------------------
-- parseMixedColors
-- Converts mixed color tokens into RGB tables
-- Accepts:
--   "#rrggbb"
--   "123" (ANSI color code)
-- Returns:
--   { {r,g,b}, {r,g,b}, ... }
------------------------------------------------------------

function parseMixedColors(tokens)
  assert(type(tokens) == "table", "parseMixedColors expects a table")

  local out = {}

  for _, token in ipairs(tokens) do
    if type(token) ~= "string" then
      error("Color token must be a string")
    end

    -- Hex color
    if token:match("^#%x%x%x%x%x%x$") then
      local hex = token:sub(2)
      out[#out + 1] = {
        tonumber(hex:sub(1,2), 16),
        tonumber(hex:sub(3,4), 16),
        tonumber(hex:sub(5,6), 16)
      }

    -- ANSI numeric code
    elseif ansiColors and ansiColors[token] then
      local c = ansiColors[token]
      out[#out + 1] = { c[1], c[2], c[3] }

    else
      error("Invalid color token: " .. token)
    end
  end

  assert(#out >= 2, "At least two colors are required")
  return out
end


------------------------------------------------------------
-- Gamma-correct RGB helpers
------------------------------------------------------------

local GAMMA = 2.2

local function srgbToLinear(c)
  c = c / 255
  return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ GAMMA
end

local function linearToSrgb(c)
  c = clamp(c, 0, 1)
  local v = c <= 0.0031308
    and c * 12.92
    or 1.055 * (c ^ (1 / GAMMA)) - 0.055
  return clamp(math.floor(v * 255 + 0.5), 0, 255)
end

------------------------------------------------------------
-- HSV
------------------------------------------------------------

local function rgbToHsv(r, g, b)
  r, g, b = r/255, g/255, b/255
  local maxv, minv = math.max(r,g,b), math.min(r,g,b)
  local d = maxv - minv

  local h = 0
  if d ~= 0 then
    if maxv == r then
      h = ((g - b) / d) % 6
    elseif maxv == g then
      h = ((b - r) / d) + 2
    else
      h = ((r - g) / d) + 4
    end
    h = h * 60
  end

  local s = maxv == 0 and 0 or d / maxv
  return h, s, maxv
end

local function hsvToRgb(h, s, v)
  h = h % 360
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c

  local r, g, b
  if h < 60 then
    r, g, b = c, x, 0
  elseif h < 120 then
    r, g, b = x, c, 0
  elseif h < 180 then
    r, g, b = 0, c, x
  elseif h < 240 then
    r, g, b = 0, x, c
  elseif h < 300 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end

  return
    clamp(math.floor((r + m) * 255 + 0.5), 0, 255),
    clamp(math.floor((g + m) * 255 + 0.5), 0, 255),
    clamp(math.floor((b + m) * 255 + 0.5), 0, 255)
end

------------------------------------------------------------
-- LAB (D65)
------------------------------------------------------------

local function rgbToLab(r, g, b)
  r, g, b = srgbToLinear(r), srgbToLinear(g), srgbToLinear(b)

  local x = (r*0.4124 + g*0.3576 + b*0.1805) / 0.95047
  local y = (r*0.2126 + g*0.7152 + b*0.0722)
  local z = (r*0.0193 + g*0.1192 + b*0.9505) / 1.08883

  local f = function(t)
    return t > 0.008856 and t^(1/3) or (7.787 * t + 16/116)
  end

  local fx, fy, fz = f(x), f(y), f(z)
  return 116*fy - 16, 500*(fx - fy), 200*(fy - fz)
end

local function labToRgb(L, a, b)
  local fy = (L + 16) / 116
  local fx = fy + a / 500
  local fz = fy - b / 200

  local f = function(t)
    return t^3 > 0.008856 and t^3 or (t - 16/116) / 7.787
  end

  local x = f(fx) * 0.95047
  local y = f(fy)
  local z = f(fz) * 1.08883

  local r =  3.2406*x - 1.5372*y - 0.4986*z
  local g = -0.9689*x + 1.8758*y + 0.0415*z
  local b =  0.0557*x - 0.2040*y + 1.0570*z

  return linearToSrgb(r), linearToSrgb(g), linearToSrgb(b)
end

------------------------------------------------------------
-- Interpolation
------------------------------------------------------------

local function interpolate(c1, c2, t, mode)
  if mode == "hsv" then
    local h1,s1,v1 = rgbToHsv(c1[1],c1[2],c1[3])
    local h2,s2,v2 = rgbToHsv(c2[1],c2[2],c2[3])
    return {
      hsvToRgb(
        h1 + (h2 - h1) * t,
        s1 + (s2 - s1) * t,
        v1 + (v2 - v1) * t
      )
    }
  elseif mode == "lab" then
    local l1,a1,b1 = rgbToLab(c1[1],c1[2],c1[3])
    local l2,a2,b2 = rgbToLab(c2[1],c2[2],c2[3])
    return {
      labToRgb(
        l1 + (l2 - l1) * t,
        a1 + (a2 - a1) * t,
        b1 + (b2 - b1) * t
      )
    }
  end

  -- gamma-correct RGB
  local out = {}
  for i = 1, 3 do
    local l1 = srgbToLinear(c1[i])
    local l2 = srgbToLinear(c2[i])
    out[i] = linearToSrgb(l1 + (l2 - l1) * t)
  end
  return out
end

------------------------------------------------------------
-- Gradient builder
------------------------------------------------------------

local function buildGradient(steps, colors, mode)
  local out = {}
  local segments = #colors - 1

  for i = 1, steps do
    local pos = (i - 1) / (steps - 1)
    local seg = math.min(segments, math.floor(pos * segments) + 1)
    local t = (pos * segments) - (seg - 1)
    out[i] = interpolate(colors[seg], colors[seg + 1], t, mode)
  end

  return out
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function lotjgradient(text, granularity, mode, ...)
  granularity = tonumber(granularity) or 1
  if granularity < 1 then granularity = 1 end

  assert(type(mode) == "string", "mode must be supplied explicitly")

  local colors = {...}
  assert(#colors >= 2, "At least two colors are required")

  for _, c in ipairs(colors) do
    assert(
      type(c) == "table" and #c == 3,
      "lotjgradient expects RGB tables {r,g,b}"
    )
  end

  local steps = math.ceil(#text / granularity)
  local gradient = buildGradient(steps, colors, mode)

  local out, gi = {}, 1
  for i = 1, #text do
    if i > 1 and (i - 1) % granularity == 0 then
      gi = gi + 1
    end
    out[#out + 1] =
      "&#" .. rgb2hex(gradient[gi]) .. text:sub(i, i)
  end

  return table.concat(out)
end
