# IHW2 starter pack — Constraint Analysis

**AOE 4065 · Test Twin Propeller Aircraft (TTPA)**

Put every file of this folder in ONE working folder and set MATLAB's Current Folder to
it. Everything then runs with no `addpath`.

> **Do not put your IHW1 folder on the path at the same time.** Both folders hold a file
> called `TtpaAero.m` and a file called `TtpaProp.m`, and MATLAB would silently use
> whichever one it finds first. Work in this folder only. The IHW2 versions of those two
> classes are the ones you extend here.

---

## What is given (do not modify)

| File | What it does |
| --- | --- |
| `Ttpa_requirements_IHW2.json` | **Read this first.** Every requirement and every model input for IHW2 |
| `ttpa_requirements_path.m` | finds the JSON |
| `ttpa_disciplines.m` | builds the `obj` bundle: `aero`, `geom`, `prop`, `wts`, `miss`, `cons` |
| `get_state.m` | ISA atmosphere at an altitude — `state.rho` and `state.sigma` |
| `AircraftState.m` | the atmosphere itself, wraps `atmosisa` |
| `ConstraintSetImporter.m` | reads the six constraint conditions out of the JSON |
| `MissionProfileReader.m` | reads the mission profile, as in IHW1 |
| `json_as_struct_array.m` | JSON helper used by both readers |
| `AerodynamicsBase.m`, `GeometryBase.m`, `WeightsBase.m`, `PropulsionBase2.m` | the discipline interfaces your classes inherit |
| `TtpaGeom.m`, `TtpaWeights.m` | unchanged from IHW1 |

Nothing from your IHW1 mission analysis is needed here. The final script uses a fixed
takeoff weight of 5354 lbf. If you would rather it came from your own mission analysis,
copy your `run_mission.m`, `get_miss_seg.m` and `missionAnalysis` into this folder and
follow the note at the top of `run_ttpa_constraint_analysis.m`.

## What you write (twelve files, in this order)

Each one is already here as a template with the blanks marked. Fill them in.

| # | File | What it does |
| :---: | --- | --- |
| 1 | `TtpaAero.m` | add the configuration CLmax and the configuration drag polar |
| 2 | `TtpaProp.m` | add the power lapse, the power ratio and a climb propeller efficiency |
| 3 | `get_con.m` | pull one constraint condition out of the set |
| 4 | `constraint_takeoff.m` | takeoff ground roll |
| 5 | `constraint_landing.m` | landing ground roll |
| 6 | `constraint_climb.m` | the three FAR 23 climb gradients |
| 7 | `constraint_cruise_speed.m` | cruise speed |
| 8 | `run_constraints.m` | every condition, over the wing-loading sweep |
| 9 | `matching_envelope.m` | the envelope, the wall and the best point |
| 10 | `design_point_check.m` | margins of a chosen design point |
| 11 | `size_from_design_point.m` | wing area and installed power |
| 12 | `plot_matching_diagram.m` | the diagram |

Then `run_ttpa_constraint_analysis.m` runs all twelve end to end.

---

## Getting started

1. Read `Ttpa_requirements_IHW2.json` from top to bottom, including the underscore
   comments. They say which block each model reads and how to pull each key.
2. Check that the Aerospace Toolbox is available:

```matlab
get_state(5000)     % must return rho = 0.0020481, sigma = 0.86167
```

3. Fill in `TtpaAero.m` and `TtpaProp.m`, then confirm the bundle builds:

```matlab
obj = ttpa_disciplines()
```

4. Work through the rest in order. Every problem in MATLAB Grader gives the numbers your
   function should produce, so you can check each one before you submit.

## Anchor numbers

If your finished analysis produces these, everything upstream is right:

```
landing wall                 43.24  lbf/ft^2
best point                   W/S = 37.40 lbf/ft^2 , W/P = 10.51 lbf/hp
selected design point        W/S = 40    lbf/ft^2 , W/P =  9.25 lbf/hp
   power margin  +5.9 %      wing-loading margin  +7.5 %
sized wing                   133.8 ft^2 , span 32.7 ft
installed power              578.8 hp total , 289.4 hp per engine
landing ground roll check    1388 ft  <= 1500 ft required
```

The takeoff gross weight those come from is `W_TO = 5354` lbf, the value your IHW1
mission analysis converges to.
