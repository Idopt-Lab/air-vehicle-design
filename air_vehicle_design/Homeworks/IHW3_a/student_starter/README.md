# IHW3 — The Sizing Loop

**AOE 4065 · Test Twin Propeller Aircraft (TTPA)**

IHW1 closed the takeoff weight with a mission analysis. IHW2 found a design point on the
matching diagram and sized the wing and the engine once, at a weight typed in from IHW1.
IHW3 closes the loop: **how big is the airplane when its weight, wing, engine, drag and fuel
all agree?**

It takes two moves. First, raise every model to **Level 2** so it responds to the airplane's
size — the wing area `S_ref` and the engine power `P_SL` (Problems 1–9). Then **iterate**
until size and weight stop changing (Problems 10–12). The loop's XDSM is
`ttpa_mainloop_xdsm.png` in this folder.

## Given

| File | What it does |
| --- | --- |
| `Ttpa_requirements_IHW3.json` | **Read this first.** Every requirement and model input for IHW3 |
| `run_ttpa_sizing_mainloop.m` | the driver: runs your twelve files and prints the full history |
| `ttpa_disciplines.m` | builds the `obj` bundle: `prop` → `geom` → `aero` → `wts`, plus `miss` and `cons` |
| `wing_loading_sweep.m` | the W/S sweep, with the landing wall appended exactly |
| `sizing_snapshot.m` | records the whole airplane at the end of each pass |
| `mission_fuel.m` | runs the L1 or L2 mission and adds the 6 % reserve |
| `get_con.m`, `constraint_takeoff.m`, `constraint_landing.m`, `constraint_climb.m`, `run_constraints.m`, `matching_envelope.m` | the IHW2 constraint analysis |
| `run_mission.m`, `get_miss_seg.m` | the IHW1 mission |
| `get_state.m`, `AircraftState.m` | ISA atmosphere |
| `ConstraintSetImporter.m`, `MissionProfileReader.m`, `json_as_struct_array.m`, `ttpa_requirements_path.m` | readers |
| `AerodynamicsBase.m`, `GeometryBase.m`, `WeightsBase.m`, `PropulsionBase2.m` | the discipline interfaces |
| `wing_fuel_check.m`, `landing_gear_loads.m` | post-sizing checks the driver runs |

You do not need your own IHW2 files: the reference constraint analysis is given.

## What you write (twelve files, in this order)

Each one is already here as a template with the blanks marked. Fill them in.

| # | File | What it does |
| :---: | --- | --- |
| 1 | `TtpaProp.m` | engine weight and length from the power — Raymer Table 10.4 |
| 2 | `TtpaGeom.m` | the Level-2 airplane: planform, tails, wetted areas, nacelles |
| 3 | `TtpaAero.m` | `C_D0 = C_fe*S_wet/S_ref` — the drag follows the geometry |
| 4 | `TtpaWeights.m` | the component build-up, Raymer Table 15.2 and Sec. 15.3.3 |
| 5 | `constraint_cruise_speed.m` | the drag-based cruise constraint |
| 6 | `segment_cruise_L2.m` | cruise at the real lift coefficient |
| 7 | `segment_loiter_L2.m` | loiter at the real lift coefficient |
| 8 | `segment_climb_L2.m` | climb flown on excess power |
| 9 | `run_mission_L2.m` | the Level-2 mission |
| 10 | `SizingSteps.m` | the takeoff-weight closure and relaxation |
| 11 | `sizing_pass.m` | one pass of the loop |
| 12 | `sizing_mainloop.m` | the loop |

Then `run_ttpa_sizing_mainloop` runs all twelve end to end.

---

## Getting started

1. Read `Ttpa_requirements_IHW3.json` from top to bottom, including the underscore comments.
2. Check the Aerospace Toolbox:

```matlab
get_state(5000)     % must return rho = 0.0020481, sigma = 0.86167
```

3. **Build the classes one at a time.** Each needs only the ones before it, so you can check
   each as you finish it — `ttpa_disciplines()` needs all four:

```matlab
p    = ttpa_requirements_path();
prop = TtpaProp(p);                 prop.P_SL  = 600;      % after Problem 1
geom = TtpaGeom(p, prop);           geom.S_ref = 130;      % after Problem 2
aero = TtpaAero(p, geom);                                  % after Problem 3
wts  = TtpaWeights(p, geom, prop);                         % after Problem 4
obj  = ttpa_disciplines();                                 % all four done
```

4. Work through the rest in order. Every problem in MATLAB Grader gives the numbers your
   function should produce, so you can check each one before you submit. **Debug in MATLAB,
   not in Grader**: Grader tells you a test failed, not why.

## The one idea to hold on to

Every derived quantity is a MATLAB **Dependent** property — recomputed every time it is read,
never stored. So the loop resizes the whole airplane with two assignments,

```matlab
obj.prop.P_SL  = P0;
obj.geom.S_ref = S0;
```

and the span, the tails, the wetted area, `C_D0`, the mission fuel and the empty weight all
follow on their next read. If something in your answer does not move when one of these two
changes, it was computed once and stored somewhere. That is the bug.

## Anchor numbers

If `run_ttpa_sizing_mainloop` prints these, everything upstream is right:

```
closed in 34 passes
W_TO   5414.74 lbf      P_SL   606.15 hp (303.1 per engine)     S_ref  125.22 ft^2
W/S    43.2404 psf      W/P    8.9330 lb/hp                     driving: Cruise Speed
C_D0   0.02873          L/D_max 13.314
OEW    3039.32 lbf      fuel   1175.42 lbf                      payload 1200 lbf
```

The wing loading is 43.2404 on every pass. Problem 13 asks you why.
