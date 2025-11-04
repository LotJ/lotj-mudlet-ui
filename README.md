# lotj-mudlet-ui

This is an attempt to provide a richer UI for [Legends of the Jedi MUD](https://www.legendsofthejedi.com/) in Mudlet.

![Image of UI with ground map](https://raw.githubusercontent.com/LotJ/lotj-mudlet-ui/main/images/ground-map.png)


## Features

### Ground Map

This package includes a script hooking into Mudlet's mapper so you can map by (mostly) just walking around an unexplored area.

It works fairly well on all existing planets. It's based on room vnums, which means it will consider each ship to be fully unique rooms.

### Local System Map

![Image of UI with ground map](https://raw.githubusercontent.com/LotJ/lotj-mudlet-ui/main/images/system-map.png)

When flying in a system, triggers capture radar output and draw a visual representation of the radar, including zooming in/out and updating proximity of each other entity as your position changes.

### Galaxy Map

![Image of UI with ground map](https://raw.githubusercontent.com/LotJ/lotj-mudlet-ui/main/images/galaxy-map.png)

After initializing it by running various in-game commands, this map will show all publicly listed starsystems, including coloring each government's planets differently. It will also attempt to highlight your current system when known, although that only works while in space.

### Chat windows

Certain types of chat content are scraped from the main console and copied into tabbed chat windows for easier history browsing.

### Live-updating Status Bar

![Image of Status Bar](https://raw.githubusercontent.com/LotJ/lotj-mudlet-ui/main/images/stats-bar.png)

Right above your input box, you'll see a bunch of useful information which updates live. This includes:

- Your HP/Move/(Mana?)
- Opponent's name and percentage
- Current comlink channel and encryption code
- Ship speed, coordinates, hull, shield, energy
- Piloting and chaff indicators, and a countdown to the next space tick


## Installing

After creating a Mudlet profile to connect to LOTJ, do the following to add the package:

1. Download a release of this package (the `.mpackage` file) from the [releases page](https://github.com/LotJ/lotj-mudlet-ui/releases)
1. Open the **Package Manager**
   1. If present, uninstall the **generic-mapper** package. It conflicts with the one provided here.
   1. Select the `lotj-ui-<version>.mpackage` file you downloaded before for installation
1. Restart Mudlet and reconnect. The UI should populate fully once you log into a character.


## Contributing

The source for this package is structured to use [muddler](https://github.com/demonnic/muddler) to package it into a Mudlet package. 

**Note:** Many updates were made to muddler since this projects started. One new feature in particular will cause problems, because it replicates script files that have the same name as the folder that contains them, which is how most of the scripts in this project are structured.

IE:
```
lotj-mudlet-ui/
├── src/
│   ├── scripts/
│   │   ├── autoresearch/         --Contains same code as autoresearch.lua
│   │   │   └── autoresearch.lua
│   │   ├── chat/                 --Contains same code as chat.lua
│   │   │   └── chat.lua
│   │   ├── color-copy/           --etc
│   │   │   └── color-copy.lua
│   │   ├── comlink-info/
│   │   │   └── comlink-info.lua
│   │   ├── galaxy-map/
│   │   │   └── galaxy-map.lua
│   │   ├── info-panel/
│   │   │   └── info-panel.lua
│   │   ├── layout/
│   │   │   ├── layout.lua
│   │   │   └── util.lua
│   │   ├── mapper/
│   │   │   └── mapper.lua
│   │   ├── setup/
│   │   │   ├── setup.lua
│   │   │   └── util.lua
│   │   └── system-map/
│   │       └── system-map.lua
```

 This can create very frustrating behavior that seems inexplicable until you finally realize what is causing it. For that reason, you should specifically use version `0.13` to compile this project.

You can, of course, just modify the triggers/aliases/scripts directly within Mudlet if you want to test local changes, but they'll be overwritten if you want to update to future versions of this package.

To change the source for this package, modify the JSON files and associated Lua scripts inside the `src` directory, then run `muddler` to regenerate the package. The resulting `.mpackage` file will be inside the `build` directory.

If you have Docker set up, it can be easiest to run a command like this to regenerate the package, from the root of the repository:

```
docker run --rm -it -u $(id -u):$(id -g) -v $PWD:/$PWD -w /$PWD demonnic/muddler:0.13
```

If that's a pain, just make a pull request and someone else can generate the package with your changes to make sure they work.
