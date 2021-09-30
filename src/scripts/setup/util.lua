function splitargs(args)
  local retval = {}
  local spat, epat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=]
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
--     argName:string - any string
--     argName:string? - any string, optional
--     argName:number - any number
--     argName:number? - any number, optional
--   all optional arguments must appear after all non-optional arguments.
-- action: A function, taking each variable argument as an argument.
-- helpText: Description of what this subcommand does.
--
-- If 
-- For example:
-- local subcommands = {{
--   "args": {"list"},
--   "action": function() ...do stuff... end,
--   "helpText": "List the things."
-- },{
--   "args": {"show", "<thingName:string>"},
--   "action": function(thingName) ...do stuff... end,
--   "helpText": "Find a given thing by name and show it"
-- }}
-- 
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