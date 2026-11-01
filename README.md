# F1 Manager 2024: REG26 Tune (2026 regulations)

A tuning layer for [**REG26**](https://github.com/AndyD9/F1Manager24-REG26) by AndyD9. REG26 brings the 2026 F1 rules
into F1 Manager 2024's race simulation: Straight Mode for every car, Overtake Mode, 350 kW-style ERS and super
clipping. This tune recalibrates it for setups that **already run a 2026 season/database mod** (for example
*F1 Manager 2026 [Modular]* with the Sector33 database) and **RRacingV5**.

All of the simulation work is REG26's. This repo changes only two files on top of REG26 v0.4.1: one Lua switch and
the energy settings. It contains no game files.

## Features

Most of these come from REG26. The ones marked **(tune)** are changed by this repo.

- **Straight Mode for the whole grid.** Every car opens its wings in the zones from lap 1, with no 1-second gap
  rule. Extra zones are added on 15 circuits. Safety car, flags and wet track still block it.
- **Overtake Mode.** Within 1 s of the car ahead at a detection point:
  - +0.5 MJ of energy on top of the battery, held until the car ahead is within 0.6 s;
  - full deployment up to 337 km/h while the others stop deploying, then up to 20 % of the car's own battery until braking;
  - +0.2 overtake success probability for 2 km after each detection.
- **2026-style ERS.**
  - Faster battery drain and 350 kW braking harvest.
  - No deployment above **305 km/h (tune)**.
  - **Super clipping:** recharge at full throttle above that speed, **twice as strong (tune)**.
- **ERS strategies renamed and reworked.** Boost, Équilibré, Réserve and Lift & Coast. Boost deploys at full power
  while the battery is above **38 % (tune)**.
- **HUD.** STRAIGHT and OVERTAKE boxes replace the DRS box. A line above each driver shows speed, battery, ERS
  state and the remaining Overtake energy.
- **No double 2026 slowdown (tune).** REG26's 2026 aero tables are switched off (they cut cornering speed by
  2/5/8 %). A 2026 database mod already sets 2026-level performance, so applying both made the cars far too slow
  (see [Calibration](#calibration)).

## What this tune changes compared with REG26 v0.4.1

| File | Setting | REG26 v0.4.1 | Tune | Why |
|---|---|---|---|---|
| `Scripts/main.lua` | `AERO_TABLES_2026` (new switch) | aero tables on | **off** | 2026 database + RRacingV5 already give 2026 lap times |
| ↳ side effect | `AeroSpeedMultipliers` (slow/medium/fast) | 0.814/0.945, 0.731/0.95, 0.767/0.92 | your base mod's values | |
| ↳ side effect | `DirtyAirSpeedMultipliers` | 0.93 | your base mod's values | same code path in the DLL; no effect on single-lap pace |
| `superclipping.ini` | `vitesse_max` | 290 | **305** | a hard cut at 305 km/h behaves closer to the real 290→355 km/h taper |
| `superclipping.ini` | `recharge` | 0.002 | **0.004** | braking harvest hits its per-lap cap early in the lap; clipping refills the battery on the straights |
| `superclipping.ini` | `deploiement_boost` | 0.40 | **0.38** | Boost keeps deploying slightly longer |
| `superclipping.ini` | everything else | | unchanged | `actif=1`, `vitesse_max_overtake=337`, overtake settings |

The full list of values REG26 changes compared with the base game is in [CHANGES.md](CHANGES.md).

## Calibration

Shanghai qualifying, RRacingV5 + F1 Manager 2026 [Modular] (Sector33 database):

| | Lap time |
|---|---|
| Real 2026 pole (Antonelli) | **1:32.064** |
| In game, REG26 v0.4.1 stock (aero tables on) | 1:34.414 (+2.35 s) |
| In game, Q2 skipped (the game's own estimate, no physics sim) | 1:31.662 |

The game's own estimate is close to the real pole, so the base mods are already calibrated to 2026. The +2.35 s
came from REG26's extra cornering cut. The tune removes it and was then adjusted by feel in Shanghai and Miami
sessions. **There is no formal lap-time table after the tune yet.** Reports with real-vs-game times are welcome.

## Requirements

- F1 Manager 2024 on **Steam, v1.11**. The DLL checks the game code bytes and disables itself on any other version.
- [UE4SS v3.0.1](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/v3.0.1) in `F1Manager24\Binaries\Win64`.
- [REG26 v0.4.1](https://github.com/AndyD9/F1Manager24-REG26/releases/tag/v0.4.1) (`Reg2026_v0.4.1.zip`). If REG26
  is not installed yet, the install script installs it from this zip.
- Recommended base: a 2026 season/database mod. Without one, keep REG26's stock aero tables (see below).

## Install

Close the game, then run from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Reg26Zip "C:\path\to\Reg2026_v0.4.1.zip"
```

- `-Game "D:\SteamLibrary\steamapps\common\F1 Manager 2024"` if the game is not in the default Steam folder.
- If REG26 v0.4.1 is already installed, `-Reg26Zip` is not needed. Its `main.lua` and `superclipping.ini` are backed up first.
- The save folder is copied to `backup\SaveGames_<date>` before anything is changed.

Check it works:
- `F1Manager24\Binaries\Win64\ue4ss\Mods\Reg2026\patch.log` contains *"Straight Mode actif dès le 1er tour"*.
- `UE4SS.log` has **no** line *"tableaux aéro 2026 écrits"*.
- In a race, the STRAIGHT and OVERTAKE boxes appear in the driver panel.

Manual install: copy `mod\Reg2026\Scripts\main.lua` and `mod\Reg2026\superclipping.ini` over the same files in
`F1Manager24\Binaries\Win64\ue4ss\Mods\Reg2026\`, and delete `carstats.txt` there if it exists.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File scripts\uninstall.ps1
```

- If REG26 was already installed before the tune, its original files are restored.
- If the script installed REG26 too, REG26 is removed as well.

## In game

| Key | Action |
|---|---|
| **F6** | super clipping on/off (saved in `superclipping.ini`) |
| **F7** | 2026 rules ↔ original DRS rule (within 1 s, after 2 laps) |

On laptops, use **Fn+F6/F7** if the F-keys control volume or brightness. *ReducedDRS* ("DRS mod") also uses F7 and
shows its wing prompt: press 1 or 2 to close it.

`superclipping.ini` is re-read every second, so it can be edited while playing:

| Key | Tune | Meaning |
|---|---|---|
| `actif` | 1 | super clipping recharge above `vitesse_max` |
| `vitesse_max` | 305 | no deployment above this speed (km/h) |
| `vitesse_max_overtake` | 337 | same limit for a car in Overtake Mode |
| `recharge` | 0.004 | super clipping recharge per ERS update (0.0007 ≈ the real 250/350 kW ratio; much higher values keep batteries full and make energy management pointless) |
| `deploiement_boost` / `deploiement_equilibre` | 0.38 / 0.60 | Boost / Équilibré deploy at full power above this battery level; they resume 15 points higher |
| `overtake_vitesse_min` | 250 | Overtake energy is spent only above this speed |
| `overtake_ecart_attaque` | 0.6 | Overtake energy is spent only within this gap (s) to the car ahead |
| `overtake_batterie_max` | 0.20 | own battery an Overtake may use after the 0.5 MJ |
| `overtake_distance` | 2000 | metres the +0.2 overtake bonus lasts after a detection |

To turn REG26's 2026 aero tables back on (for a base game without a 2026 database), set
`local AERO_TABLES_2026 = true` in `Scripts\main.lua`.

## Compatibility notes

- **RRacingV5.** Its race data paks load in place of REG26's pak. REG26 writes its values into memory, so the result
  is RRacingV5 plus REG26's ERS, slipstream, overtake and car-stat weight values. The tune was made on this setup.
- **Track mods that move DRS zones** (e.g. *Track Straight Mode Zones* in F1 Manager 2026 [Modular], RRacingV5
  maps). REG26 adds its zones without checking the zones already in the map. Zones can overlap on Bahrain,
  Barcelona, Hungaroring, Jeddah, Monza, Shanghai, Silverstone and Suzuka. `UE4SS.log` shows `"<track> : zones X -> Y"`:
  an X above the base game's count means the map already had extra zones.
- **Mods replacing `RaceSim/AI/RaceSimAIDataAsset`** (e.g. ActionMod Chaos Edition). REG26's pak ships an unchanged
  copy of this file. If REG26's pak wins the load order, that mod's tweaks to this file are lost.
- **HUD mods** that replace `driverPanel/DRSDisplay.js` conflict with REG26's interface.

## Limitations

- **ERS only changes acceleration.** In the game's data ERS acts through acceleration multipliers (×0.75 when not
  deploying, REG26's value). It has no separate power curve. Top speed gaps from ERS and Overtake Mode are
  therefore smaller than in real 2026 racing.
- **Hard cut instead of a taper.** Real rules fade MGU-K power from 290 to 0 km/h at 355 km/h. Here deployment
  stops at one speed (305).
- **Super clipping is free.** Recharge above the limit costs no extra speed. In reality harvesting at full throttle
  slows the car.
- **Braking harvest still has the old per-lap cap.** Late in the lap (e.g. Miami sector 3) braking stops charging.
  The real rule allows up to 8.5 MJ per lap. Super clipping covers most of it.
- **Not configurable:** the 15-point Boost/Équilibré restart margin, the 250 km/h Lift & Coast limit and the 0.5 MJ
  Overtake energy are fixed in the DLL. The "no Overtake Mode for 2 laps after start/restart" rule comes from the
  game's DRS lap.
- **Not modelled:** the Miami revision (+150 kW race boost cap, 250 kW outside acceleration zones, 7 MJ quali recharge).
- **Calibration:** REG26 was measured in races at Monza. This tune was adjusted in Shanghai and Miami. Other tracks
  and qualifying are not measured systematically.
- **Version-locked:** Steam v1.11 only. The REG26 DLL is used as released; it is not rebuilt here.

## Credits and license

- **REG26** by AndyD9: simulation patch, Lua script, zones, paks and HUD. MIT, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
  `mod/Reg2026/Scripts/main.lua` is REG26's file with the `AERO_TABLES_2026` switch added.
- Tested with **RRacingV5** (overtake.gg) and **F1 Manager 2026 [Modular]** with the Sector33 database.
- This tune: MIT, see [LICENSE](LICENSE).

Fan project, not affiliated with Frontier Developments, Formula 1 or the FIA. No game files are included. You
need to own F1 Manager 2024.
