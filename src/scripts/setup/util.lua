---@diagnostic disable-next-line: deprecated
local unpack = table.unpack or unpack

function splitargs(args)
  local retval = {}
  local spat, epat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=], nil, nil
  for str in args:gmatch("%S+") do
    local squoted = str:match(spat)
    local equoted = str:match(epat)
    local escaped = str:match([=[(\*)['"]$]=])
    if squoted and not quoted and not equoted then
      buf, quoted = str, squoted
    elseif buf and equoted == quoted and #escaped % 2 == 0 then
      str, buf, quoted = buf .. ' ' .. str, nil, nil
    elseif buf then
      buf = buf .. ' ' .. str
    end
    if not buf then table.insert(retval, (str:gsub(spat,""):gsub(epat,""))) end
  end
  if buf then error("Missing matching quote for "..buf) end
  return retval
end

function os.exists(filename)
  local f = io.open(filename, "r")
  if f then
    io.close(f)
    return true
  else
    return false
  end
end

function gmcpVarByPath(varPath)
  local temp = gmcp
  for varStep in varPath:gmatch("([^\\.]+)") do
    if temp and temp[varStep] then
      temp = temp[varStep]
    else
      return nil
    end
  end
  return temp
end

-- Handles matching argument text to a list of subcommands.
-- Each subcommand should be an object with the following properties:
-- args: List of elements to match input against, each matching:
--   a string to match exactly for the argument in this position
--   a token indicating a type of variable argument in this position, one of:
-- `    argName:string - any string`  
-- `    argName:string? - any string, optional`  
-- `    argName:number - any number`  
-- `    argName:number? - any number, optional`  
--   all optional arguments must appear after all non-optional arguments.
-- action: A function, taking each variable argument as an argument.
-- helpText: Description of what this subcommand does.
--
-- For example:  
-- ```
-- local subcommands = {{  
--   "args": {"list"},  
--   "action": function() ...do stuff... end,  
--   "helpText": "List the things."  
-- },{  
--   "args": {"show", "<thingName:string>"},  
--   "action": function(thingName) ...do stuff... end,  
--   "helpText": "Find a given thing by name and show it"  
-- }}  
-- ```
-- This would match against the second subcommand, effectively calling your function
-- with "testName" as the argument.
-- processCommand("shopkeeper", subcommands, "show testName")
--
-- Calling this with "help" or any nonmatching argument will print out the list of
-- subcommands and descriptions, using the commandName argument as the overall command
-- name for documentation.
function processCommand(commandName, subcommands, input)
  inputArgs = splitargs(input)

  for _, subcommand in pairs(subcommands) do
    local match = true
    local matchArgs = {}
    local foundOptArg = false

    -- Go through each subcommand arg to look for non-matches. Innocent until proven guilty.
    for i, arg in ipairs(subcommand.args) do
      local startIdx, _, argName, varType, argOpt = arg:find("([^:]+):?([^?]*)([?]?)")
      if not startIdx then
        error("Invalid subcommand argument specifier: "..arg)
      elseif foundOptArg and argOpt ~= "?" then
        error("Found non-optional argument ("..arg..") after optional argument.")
      end

      if varType == "" then
        -- Exact match for subcommand name
        if inputArgs[i] ~= argName then
          match = false
        end
      else
        -- Variable. Check type and optional state
        local rawValue = inputArgs[i]

        if varType == "number" then
          rawValue = tonumber(rawValue)
          if not rawValue then
            match = false
          end
        end

        -- Check that optional arguments are given values, or no match
        if argOpt == "?" then
          foundOptArg = true
        elseif not rawValue or rawValue == "" then
          match = false
        end

        table.insert(matchArgs, rawValue)
      end
    end

    -- Got too many arguments, fail
    if #inputArgs > #subcommand.args then
      match = false
    end

    if match then
      subcommand.action(unpack(matchArgs))
      return
    end
  end

  if not (#inputArgs == 1 and inputArgs[1] == "help") then
    cecho("<red>Invalid syntax.<reset>\n\n")
  end
  cecho("<white>Available options for "..commandName.." command:<reset>")
  for _, subcommand in pairs(subcommands) do
    cecho("\n\n<yellow>"..commandName)
    for _, arg in ipairs(subcommand.args) do
      local _, _, argName, varType, argOpt = arg:find("([^:]+):?([^?]*)([?]?)")
      if varType == "" then
        cecho(" <yellow>"..argName)
      elseif argOpt == "?" then
        cecho(" <yellow>[<ansi_light_black>"..argName.."<yellow>]")
      else
        cecho(" <yellow><<light_gray>"..argName.."<yellow>>")
      end
    end
    cecho("<reset>\n\n"..subcommand.helpText)
  end
  echo("\n\n")
end

local function clamp(v, min, max)
  if v < min then return min end
  if v > max then return max end
  return v
end

-- Parses Qt colors into r,g,b,a (0–255)
local function parseColor(val)
  if not val then return nil end

  -- rgba(r,g,b,a)
  local r, g, b, a = val:match(
    "rgba%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([%d%.]+)%s*%)"
  )
  if r then
    r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
    if a <= 1 then a = a * 255 end
    return r, g, b, clamp(a, 0, 255)
  end

  -- #RRGGBB
  local rr, gg, bb = val:match("#(%x%x)(%x%x)(%x%x)$")
  if rr then
    return tonumber(rr, 16), tonumber(gg, 16), tonumber(bb, 16), 255
  end

  -- #AARRGGBB (Qt)
  local aa, rr2, gg2, bb2 = val:match("#(%x%x)(%x%x)(%x%x)(%x%x)$")
  if aa then
    return tonumber(rr2, 16),
           tonumber(gg2, 16),
           tonumber(bb2, 16),
           tonumber(aa, 16)
  end

  return nil
end

-- Converts "#AARRGGBB" -> r, g, b, a (0–255)
local function argbHexToRgba(hex)
  if type(hex) ~= "string" then return nil end

  local a, r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)(%x%x)$")
  if not a then return nil end

  return
    tonumber(r, 16),
    tonumber(g, 16),
    tonumber(b, 16),
    tonumber(a, 16)
end

local function colorToRgba(r, g, b, a)
  return string.format(
    "rgba(%d, %d, %d, %d)",
    clamp(math.floor(r + 0.5), 0, 255),
    clamp(math.floor(g + 0.5), 0, 255),
    clamp(math.floor(b + 0.5), 0, 255),
    clamp(math.floor(a + 0.5), 0, 255)
  )
end

local function interpolatePx(from, to, t)
  local f = tonumber(from:match("([%d%.]+)px"))
  local e = tonumber(to:match("([%d%.]+)px"))
  if not f or not e then return to end
  return (f + (e - f) * t) .. "px"
end

local function interpolateColor(from, to, t)
  local r1, g1, b1, a1 = parseColor(from)
  local r2, g2, b2, a2 = parseColor(to)
  if not r1 or not r2 then return to end

  return colorToRgba(
    r1 + (r2 - r1) * t,
    g1 + (g2 - g1) * t,
    b1 + (b2 - b1) * t,
    a1 + (a2 - a1) * t
  )
end

-- `object` - The Geyser object whose style will be interpolated  
-- `styleTo` - The style to be interpolated into. This can be one style or a list of styles  
-- `time` - [default 1] The duration of the interpolation in seconds  
-- `steps` - [default 100] Defines the coarseness of the interpolation - higher values look smoother but require linearally more calculation
function Geyser.Label.interpolate(object, styleTo, time, steps)
  time  = time  or 1
  steps = steps or 100

  local StyleSheet = Geyser.StyleSheet

  -- Normalize styleTo into a list
  local targets = {}
  if type(styleTo) == "string" then
    targets[1] = styleTo
  elseif type(styleTo) == "table" then
    targets = styleTo
  else
    error("styleTo must be a stylesheet string or a list of strings")
  end

  if #targets == 0 then return end

  local segments = #targets
  local timePerSegment  = time / segments
  local stepsPerSegment = math.max(1, math.floor(steps / segments))

  local segmentIndex = 1
  local timer

  local function runSegment()
    if segmentIndex > segments then return end

    local fromSheet = StyleSheet:new(object.stylesheet or "")
    local toSheet   = StyleSheet:new(targets[segmentIndex])

    local fromTbl = fromSheet:getStyleTable(true)
    local toTbl   = toSheet:getStyleTable(true)

    local keys = {}
    for k in pairs(fromTbl) do keys[k] = true end
    for k in pairs(toTbl)   do keys[k] = true end

    local step = 0
    local stepTime = timePerSegment / stepsPerSegment

    timer = tempTimer(stepTime, function()
      step = step + 1
      local t = step / stepsPerSegment

      local current = {}

      for key in pairs(keys) do
        local fromVal = fromTbl[key]
        local toVal   = toTbl[key]

        if fromVal and toVal then
          if parseColor(fromVal) and parseColor(toVal) then
            current[key] = interpolateColor(fromVal, toVal, t)

          elseif fromVal:match("px") and toVal:match("px") then
            current[key] = interpolatePx(fromVal, toVal, t)

          else
            current[key] = toVal
          end

        elseif fromVal then
          current[key] = fromVal
        elseif toVal then
          current[key] = toVal
        end
      end

      local target = toSheet.target or fromSheet.target
      local outSheet = StyleSheet:new("", nil, target)
      outSheet:setStyleTable(current)
      object:setStyleSheet(outSheet:getCSS())

      if step >= stepsPerSegment then
        killTimer(timer)
        object:setStyleSheet(toSheet:getCSS())
        segmentIndex = segmentIndex + 1
        runSegment()
      end
    end, true)
  end

  runSegment()
end
