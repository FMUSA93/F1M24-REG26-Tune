# Changes

Base-game values are F1 Manager 2024 v1.11, as documented by REG26 (`VALEURS_2026.md`, `scripts/patch_2026.py`).
With another race-data mod installed (e.g. RRacingV5), that mod's values replace the base values, and REG26 only
overwrites the fields below.

## A. REG26 v0.4.1: data values (pak `zzz_Reg2026_P` + written into memory by the Lua script and the DLL)

| Asset › field | Base game | REG26 | 2026 rationale |
|---|---|---|---|
| RaceSimDataAsset › `ERSAccelDeployBatteryRate` | −0.06 | −0.10 | 350 kW MGU-K (was 120 kW): 4 MJ last ~11 s, battery empty after ~10 s of deployment |
| RaceSimDataAsset › `ERSBrakingChargeBatteryRate` | 0.07 | 0.0875 | 350 kW braking harvest |
| RaceSimDataAsset › `ERSAccelerationMultiplier_Inactive` | 0.70 | 0.75 | Calibrated to 2026 lap times at Monza |
| RaceSimDataAsset › `ERSWearRate` | 13 | 15 | ERS works harder |
| RaceSimDataAsset › `SlipstreamAccelerationMultiplier` | 1.08 | 1.10 | With Straight Mode for all, slipstream creates the speed difference |
| RaceSimDataAsset › `DirtyAirMaxDist` | 220 | 150 | Less dirty air in 2026 |
| OvertakeData › `OvertakeAssistOvertakeDifficultyModifier` | 0.125 | 0.25 | Overtake Mode matters more |
| OvertakeData › `SlipstreamTimeToOvertake` | 2.5 | 1.5 | Passes complete sooner |
| OvertakeData › `OvertakeMaxStartDistance` | 40 | 50 | Attacks can start from further back |
| DriverTacticsDataAsset › `ERSDeployBudget` | 0.45 | 0.80 | More electric use (small effect on AI per REG26) |
| DriverTacticsDataAsset › `OvertakeStrategyStatMultiplier` (aggressive) | 1.2 | 1.3 | Sharper attacking strategy |
| CarStatsDataAsset › top speed `PowerWeight` / `DragReductionWeight` | 0.05 / 0.95 | 0.15 / 0.85 | 2026 engines matter more |
| CarStatsDataAsset › acceleration `PowerWeight` / `DragReductionWeight` | 0.5 / 0.5 | 0.6 / 0.4 | Same |
| CarStatsDataAsset › `DRSTopSpeedMultiplier` min/max | 1.0155 / 1.0431 | 1.03 / 1.06 | Straight Mode (front + rear wing, −55 % drag) is stronger than old DRS. The DLL also uses it as a check: do not change it |
| CarStatsDataAsset › `DRSAccelerationMultiplier` min/max | 1.0 / 1.146 | 1.05 / 1.20 | Same |
| CarStatsDataAsset › `AeroSpeedMultipliers` slow / medium / fast | 0.831/0.964, 0.769/1.0, 0.834/1.0 | 0.814/0.945, 0.731/0.95, 0.767/0.92 | −30 % downforce: −2 / −5 / −8 % cornering speed (**off in this tune**) |
| CarStatsDataAsset › `DirtyAirSpeedMultipliers` (×3) | 0.90 / 1.0 | 0.93 / 1.0 | ~90 % downforce kept at 20 m (**off in this tune**) |
| RaceSimAIDataAsset › `ERSChargingModeToggleThreshold` | 0.5 / 0.25 | unchanged | Copied as is |
| `DRSAccelerationSpeedCurce` | 0 → 0, 360 km/h → 1.0 | unchanged | Original curve |

## B. REG26 v0.4.1: logic (`Reg2026Patch.dll`, in memory only, after a byte check)

| Game code | Original | REG26 | 2026 rationale |
|---|---|---|---|
| exe+0x230C335 DRS lap rule | DRS 2 laps after start/restart | removed | Straight Mode from lap 1 |
| exe+0x230C440 1-second test | DRS only within 1 s | every car gets DRS (= Straight Mode); within 1 s → Overtake Mode | Straight Mode with no gap rule |
| Overtake Mode | – | +12.5 % battery credit (0.5 MJ of 4 MJ), once per lap, used within 0.6 s of the car ahead, full power to 337 km/h, then up to 20 % own battery until braking | +0.5 MJ, 350 kW to 337 km/h |
| exe+0x23084BE / 0x230856D ERS update | deploys at any speed | no deployment above `vitesse_max` (337 in Overtake Mode); super clipping recharge above it | 290 → 355 km/h taper (simplified to a cut) + 250 kW clipping |
| exe+0x231FBFE overtake chance | +0.2 if the attacker has DRS and the defender doesn't | +0.2 for an attacker within 1 s at detection, for 2 km | Old DRS bonus moved to Overtake Mode |
| ERS strategy (+0xEF2) | Deploy / Neutral / Top-Up / Harvest | Boost / Équilibré / Réserve (deploys only in Overtake Mode or in a battle within 1 s) / Lift & Coast (no electric power above 250 km/h) | Manual boost and 2026 energy management |

Zones (`zones.lua`): start/end points added on 15 circuits, without new detection points (those caused red flags).

## C. This tune (on top of REG26 v0.4.1)

| File › setting | REG26 | Tune | Why |
|---|---|---|---|
| `Scripts/main.lua` › `AERO_TABLES_2026` (new) | aero tables written by the DLL | `false`: `carstats.txt` is never written, a stale one is deleted at load, so the DLL leaves the tables alone | A 2026 database mod already sets 2026 performance. Shanghai pole was 1:34.414 vs the real 1:32.064 with both active |
| `superclipping.ini` › `vitesse_max` | 290 | 305 | Closer to the real 290 → 355 km/h taper. Felt balanced in testing |
| `superclipping.ini` › `recharge` | 0.002 | 0.004 | Braking harvest reaches its per-lap cap early in the lap; clipping refills the battery on the straights |
| `superclipping.ini` › `deploiement_boost` | 0.40 | 0.38 | Boost keeps deploying slightly longer |
| `superclipping.ini` › others | | unchanged | `actif=1`, `vitesse_max_overtake=337`, overtake settings |
