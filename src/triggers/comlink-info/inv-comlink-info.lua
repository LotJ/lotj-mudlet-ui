if not lotj.comlinkInfo.comlinks then
  return
end

local line = lotj.comlinkInfo.cleanupComlinkName(matches[1])
local comlink = lotj.comlinkInfo.comlinks[line]
if comlink ~= nil then -- found a comlink with stored data
  cecho(" <yellow>-> <gray>(Chan:<red>" .. comlink.channel .. "<gray> Enc:<red>" .. comlink.encryption .. "<gray>" .. ((comlink.note and " Note:") or "") .. "<red>" .. ((comlink.note and comlink.note) or "") .. "<gray>)")
end

setTriggerStayOpen("inventory-comlinks", 1)
