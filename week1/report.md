# King Air C90GT — Week 1 Report

## General Mission Idea

Each simulation run goes through these common steps:

1. **Ground Roll (V0 → V1):** Aircraft on the ground goes from initial V0 to V1 speed. Both engines at takeoff power.
2. **Continued Roll (V1 → Vr):** Aircraft still on ground accelerates from V1 speed to Vr speed, committed to takeoff now.
3. **Rotation:** Aircraft lifts off and starts climbing to 35 ft altitude. Two other phases are also checked at this point.
4. **Balanced Field Solve:** Finds V1 such that the distance to clear the 35 ft obstacle equals the distance to come to a complete stop when aborting at V1. Checks if taking off at this speed is safe.
5. **Engine Out Climb:** If one engine fails, checks whether the aircraft can still climb past the 35 ft altitude.
6. **Climb:** Aircraft climbs at constant airspeed and vertical speed to reach cruising altitude.
7. **Cruise:** Aircraft flies at cruising altitude and constant airspeed.
8. **Descent:** Aircraft descends at constant airspeed and vertical speed to reach sea level at the exact mission range.

---

## Mission Input Values for KING_AIR_C90GT

*Source: `examples/KingAirC90GT.py`*

| Variable Name           | Value  | Unit   | Description                       |
|-------------------------|--------|--------|-----------------------------------|
| `climb.fltcond\|vs`     | 1500   | ft/min | Climb vertical speed              |
| `climb.fltcond\|Ueas`   | 124    | kn     | Climb airspeed                    |
| `cruise.fltcond\|vs`    | 0.01   | ft/min | Cruise vertical speed (near zero) |
| `cruise.fltcond\|Ueas`  | 170    | kn     | Cruise airspeed                   |
| `descent.fltcond\|vs`   | -600   | ft/min | Descent vertical speed            |
| `descent.fltcond\|Ueas` | 140    | kn     | Descent airspeed                  |
| `cruise\|h0`            | 29,000 | ft     | Cruise altitude                   |
| `mission_range`         | 1000   | NM     | Total mission range               |
| `payload`               | 1000   | lb     | Payload                           |
| `v0v1.throttle`         | 0.75   | —      | Ground roll throttle (derated)    |
| `v1vr.throttle`         | 0.75   | —      | Rotation throttle (derated)       |
| `rotate.throttle`       | 0.75   | —      | Liftoff throttle (derated)        |

---

## Aircraft Design Input Values for KING_AIR_C90GT

*Source: `examples/aircraft_data/KingAirC90GT.py`*

| Variable Name                         | Value  | Unit   | Description                        |
|---------------------------------------|--------|--------|------------------------------------|
| `ac\|weights\|MTOW`                   | 10,099 | lb     | Max takeoff weight                 |
| `ac\|weights\|W_fuel_max`             | 2,571  | lb     | Max fuel capacity                  |
| `ac\|weights\|MLW`                    | 9,601  | lb     | Max landing weight                 |
| `ac\|propulsion\|engine\|rating`      | 750    | hp     | Engine max power (per engine)      |
| `ac\|propulsion\|propeller\|diameter` | 2.28   | m      | Propeller diameter                 |
| `ac\|geom\|wing\|S_ref`               | 27.308 | m²     | Wing reference area                |
| `ac\|geom\|wing\|AR`                  | 8.5834 | —      | Wing aspect ratio                  |
| `ac\|geom\|wing\|taper`               | 0.397  | —      | Wing taper ratio                   |
| `ac\|geom\|wing\|toverc`              | 0.19   | —      | Wing thickness-to-chord ratio      |
| `ac\|geom\|fuselage\|length`          | 10.79  | m      | Fuselage length                    |
| `ac\|geom\|fuselage\|width`           | 1.6    | m      | Fuselage width                     |
| `ac\|geom\|fuselage\|height`          | 1.9    | m      | Fuselage height                    |
| `ac\|aero\|polar\|CD0_cruise`         | 0.022  | —      | Zero-lift drag coefficient, cruise |
| `ac\|aero\|polar\|CD0_TO`             | 0.040  | —      | Zero-lift drag coefficient, takeoff|
| `ac\|aero\|polar\|e`                  | 0.80   | —      | Oswald efficiency factor           |
| `ac\|aero\|CLmax_TO`                  | 1.52   | —      | Max lift coefficient at takeoff    |
| `ac\|num_engines`                     | 2      | —      | Number of engines                  |
| `ac\|num_passengers_max`              | 8      | —      | Max passenger count                |
| `ac\|q_cruise`                        | 98     | lb/ft² | Dynamic pressure at cruise         |

---

## Mission Statement

King Air C90GT starts at sea level with 1,000 lb payload and 10,099 lb MTOW. It uses derated takeoff power (75% throttle), accelerates down the runway, commits to takeoff at the balanced field decision speed (V1), and clears the 35 ft obstacle. It then climbs at 124 kn / 1,500 ft/min to reach cruising altitude of 29,000 ft. It cruises at near-zero vertical speed and 170 kn airspeed. It then descends at 140 kn / 600 ft/min to reach sea level. The total range of the flight at this point equals the mission range of 1,000 NM.

---

## Outputs for KING_AIR_C90GT

| Output                   | Value    | Unit | Description                  |
|--------------------------|----------|------|------------------------------|
| MTOW                     | 10,099   | lb   | Max takeoff weight (same as input) |
| OEW                      | 6,471.5  | lb   | Operating empty weight       |
| Fuel used                | 1,666.7  | lb   | Total fuel burned on mission |
| TOFL (over 35 ft obstacle) | 3,054.6 | ft  | Takeoff field length         |



## Values That Need Verification

> **Note:** The following is based on best assumption from my understanding of the mission structure.

The following output quantities need verification against historical data and independent equations:

- OEW
- Fuel used
- TOFL
- Mission input values need to be checked for physical plausibility for this aircraft class.

---

## AI Usage
I used Claude Code and GPT-5.4 to understand the codebase, variables, and simulation logs. This document was created solely by Prakhar Modi with no AI assistance.
