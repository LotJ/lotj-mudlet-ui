lotj.comlinkInfo.registerComlink(matches.comlink, matches.channel, matches.encryption)
echo("\n")
if matches.comlink then
  lotj.comlinkInfo.log("Stored comlink: "..matches.comlink)
end
if matches.channel then
  lotj.comlinkInfo.log("Stored channel: "..matches.channel)
end
if matches.encryption then
    lotj.comlinkInfo.log("Stored encryption: "..matches.encryption)
end
