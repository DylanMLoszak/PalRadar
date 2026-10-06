# PalRadar

**A live in-game overlay for Palworld that shows you the eggs, lucky Pals, chests and skill fruit the game has
loaded around you, before you spot them yourself.**

[![Latest release](https://img.shields.io/github/v/release/DylanMLoszak/PalRadar?label=release)](https://github.com/DylanMLoszak/PalRadar/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/DylanMLoszak/PalRadar/total)](https://github.com/DylanMLoszak/PalRadar/releases)
![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue)
![Palworld](https://img.shields.io/badge/Palworld-1.0.4-orange)

PalRadar draws a marker over everything worth walking to within a few hundred metres: what it is, how far, and
an arrow at the edge of the screen when it is behind you. A huge egg, a lucky Pal, a species you are hunting or a
passive you are breeding for gets a chime, a spoken callout and a line at the top of the screen the moment it
loads in. Nothing is drawn that the game has not already streamed to your PC; PalRadar does not see further than
your client does.

---

## Contents

- [What it shows](#what-it-shows)
- [Requirements](#requirements)
- [Installation](#installation)
- [Using it](#using-it)
- [Settings](#settings)
- [Updating](#updating)
- [Privacy and safety](#privacy-and-safety)
- [Troubleshooting](#troubleshooting)
- [Uninstalling](#uninstalling)
- [Game data and compatibility](#game-data-and-compatibility)
- [Disclaimer](#disclaimer)
- [Licence](#licence)

## What it shows

| Marker | Detail on the label |
| --- | --- |
| **Eggs** | The species inside and its rarity, or just the element ("Fire egg") if you prefer the surprise. Huge eggs stand out and raise an alert. |
| **Lucky Pals** | Every lucky Pal in range, with level, gender and alpha badge. |
| **Wanted species** | Species you pick in Settings. Each one raises an alert when it appears. |
| **Watched traits** | Wild Pals carrying a passive you pick, with all their traits coloured by tier. |
| **Chests** | Treasure chests by grade, with a minimum grade so common ones stay hidden. |
| **Fishing spots** | Spots with a king, boss, rare or lucky fish shadow. |
| **Skill fruit trees** | Trees that currently carry fruit, listing each fruit with its element and rarity. |
| **Effigies** | Lifmunk Effigies you have not picked up yet. |

Everything outside your field of view clamps to the screen edge as an arrow with its distance, so you can turn
towards it.

## Requirements

- **Windows 10 or 11** and a PC that runs Palworld.
- **Palworld on Steam** with the game's official mod support present (the `Mods\NativeMods\UE4SS` folder inside
  the game folder). PalRadar installs a small script there; it does not install UE4SS itself.
- **Mods enabled in Palworld.** In the game's Mod Management screen, make sure mods are switched on.
- **Borderless windowed or windowed mode.** An overlay cannot draw over exclusive fullscreen.
- Speakers or headphones if you want the spoken callouts. Windows' built-in voice is used; no download.

No .NET install is needed; the runtime is bundled in the exe.

## Installation

1. Download `PalRadar.exe` from the [latest release](https://github.com/DylanMLoszak/PalRadar/releases/latest).
2. Put it in a folder you can write to (for example `Documents\PalRadar`). Avoid `Program Files`, where PalRadar
   cannot update itself.
3. Run it **before launching Palworld** the first time. Windows SmartScreen may warn that the app is unrecognised
   because it is not code-signed: choose **More info**, then **Run anyway**.
4. PalRadar unpacks its data to a `data` folder next to the exe, finds Palworld through your Steam libraries and
   installs the feed mod into the game's UE4SS folder. If the game is somewhere Steam does not list, start it once
   from a terminal with `PalRadar.exe --game "D:\Games\Palworld"`.
5. Launch Palworld. The overlay appears over the game window once you are in a world, and a tray icon shows while
   PalRadar runs.

The mod loads when Palworld starts, so after the first install, and after any update that changes the mod, start
PalRadar first and the game second. On every other day the order does not matter.

## Using it

| Key | Action |
| --- | --- |
| **+** (either plus key) | Open or hide the Settings window |
| **Numpad -** | Hide or show the overlay |

The tray icon's menu has the same two actions plus **Restart** and **Exit**. The overlay closes by itself about
ten seconds after Palworld does.

The overlay is click-through: it never takes your mouse or keyboard away from the game. The Settings window is a
normal window; drag it to a second monitor and leave it open if you like.

## Settings

Press **+** in game. Each row saves as you change it.

- **Show** rows turn each marker type on or off: eggs, effigies, chests (with a minimum grade), special fishing
  spots, skill fruit trees, lucky Pals.
- **Ignore eggs of** hides species you are done with. **Eggs: element only** labels eggs by element instead of
  naming the species inside.
- **Wanted species** and **Watched traits** open pickers. Anything you tick raises an alert when it loads in.
- **Alerts**, **Alert sound**, **Alert speech** and **Alert on huge eggs** control the chime, the spoken line and
  the on-screen message.
- **Pal: level / gender / alpha badge / all traits** choose how much is written under a Pal marker.
- **Range (m)** is how far out markers are drawn, 50 to 1000 m (300 by default).
- **Cushion**, **Pose** and **Lead** are smoothing options for the marker motion. The defaults suit most PCs; try
  **Pose: predict** if markers trail the camera when you turn fast.

Settings live in `data\hud.json` next to the exe and survive updates.

## Updating

PalRadar checks this page each time it starts. When a newer version is available it asks, once, whether to
update now. Nothing is downloaded or replaced until you say yes. PalRadar then downloads the new version,
verifies it against the SHA-256 checksum GitHub publishes for the release, swaps itself and restarts. If the
download fails or does not match, it is discarded and the version you have keeps working. After an update the
previous exe is kept beside the new one as `PalRadar.exe.old` and removed on a later start.

The version you are running is shown when you hover the tray icon.

## Privacy and safety

- **No telemetry.** PalRadar makes one kind of network request: the update check against this GitHub page.
- **Read-only.** The feed mod reads what Palworld has loaded and writes a small snapshot file into PalRadar's
  `data` folder twice a second. It never writes to a save file and never sends anything anywhere.
- **Local data.** The snapshot contains your position, your in-game player name and the things around you. It
  stays on your PC and is overwritten constantly. The log `hud.log` next to the exe records folder paths and what
  PalRadar was doing; read it before you send it to anyone.
- **Multiplayer.** PalRadar is a client-side mod. It shows only what your own client has loaded, but whether a
  mod is allowed on a given server is set by that server's rules, and using one there is your decision.

## Troubleshooting

| Problem | What to do |
| --- | --- |
| Nothing appears over the game | Make sure mods are enabled in Palworld's Mod Management screen and the game is in borderless windowed mode. Then check `hud.log` next to the exe for `feed mod installed` or `feed mod current`. |
| The log says the feed mod started but no snapshot ever arrives | Put PalRadar in a folder whose path has only plain Latin letters and digits. The mod writes its files through the game's Lua runtime, which cannot open paths with other characters. |
| "UE4SS Mods folder was not found" at start | Palworld is not in a Steam library PalRadar can see. Start it once with `PalRadar.exe --game "<your Palworld folder>"`. |
| Markers appear but the game did not pick up the new mod | The mod loads at game start. Close Palworld, start PalRadar, then start the game. |
| Markers trail behind when turning | Open Settings, set **Pose** to **predict**, and raise **Lead** a little. |
| No spoken callouts | Check **Alert speech** in Settings and that Windows has a voice installed under Settings > Time & Language > Speech. |
| No update prompt | You are on the latest version, or GitHub could not be reached; PalRadar tries again on the next start. |
| Something else | `hud.log` next to the exe says what PalRadar was doing when it went wrong. |

## Uninstalling

Next to the exe, delete `PalRadar.exe` itself, its `data` folder, `hud.log` and, if an update left it, `PalRadar.exe.old`.
Then delete the `PalRadarFeed` folder inside the game's `Mods\NativeMods\UE4SS\Mods`. Nothing else is written.

## Game data and compatibility

PalRadar ships names, tables and icons for **Palworld 1.0.4**. A game patch can rename the objects the mod reads
or change their layout; when that happens the overlay stops showing some or all markers until a new PalRadar
release is published, and the update prompt will offer it.

## Disclaimer

PalRadar is an unofficial fan-made tool. It is not affiliated with, endorsed by or sponsored by Pocketpair, Inc.
Palworld is a trademark of Pocketpair, Inc.

## Licence

PalRadar is free to download and use, and is provided as is, without warranty. This repository hosts releases
only; the source code is not published. See [LICENSE.md](LICENSE.md), and
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for the game data and open-source components it contains.
