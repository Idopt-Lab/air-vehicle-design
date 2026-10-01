# IHW3a — TTPA sizing on the preliminary design framework

**AOE 4065 · Test Twin Propeller Aircraft**

```bash
matlab -batch run_ttpa_sizing          # size the airplane, end to end
matlab -batch run_ttpa_sizing_mainloop # the whiteboard loop: S_ref is an OUTPUT
matlab -batch run_ttpa_trade_studies   # sweep the design variables
matlab -batch verify_ihw3a             # check the sizing/geometry claims
matlab -batch verify_framework         # check the framework claims
```

---

## The framework

This implements the **preliminary design framework** of the sizing-refinement
lecture, in propeller form. Every box, and the file it lives in:

| Lecture box | Inputs | Output | File |
| --- | --- | --- | --- |
| Tail sizing | `S_ref`, `L_fus`, `D_fus` | `S_ht`, `S_vt` | `TtpaGeom` (Dependent) |
| Drag polar II | `S_ref`, fuselage, tails, `AR`, `e` | `C_D0`, `K` | `TtpaAero.CD0` |
| Wing loading | `S_ref`, `W_0` | `W_0/S_ref` | `sizing_loop` step 3 |
| Design diagram | `C_D0`, `K`, `W_0/S_ref`, `s_FL`,`G`,`CLmax` | `(W/P)` required | `design_diagram` |
| Fuel fraction | `c`, `R`, `V`, polar, **`W_0/S_ref`** | `W_f/W_0` | `mission_fuel` |
| Empty weight II/III | `S_ref`, fuselage, tails, `P_0`, `W_0`, (III: `AR`) | `W_e/W_0` | `TtpaWeights` |
| MTOW iteration | `W_e/W_0`, `W_f/W_0` | `W_0` ↺ | `SizingSteps.togw_update` |
| P₀ iteration | `(W/P)`, `W_0` | `P_0` ↺ | `sizing_loop` step 5 |

Two red loops, exactly as the lecture draws them: `W_0,guess` closed by the MTOW
iteration, and `P_0,guess` (the lecture's `T_0,guess`) closed by the power
iteration.

**`S_ref` is a green input.** The wing loading is *computed*, `W/S = W_0/S_ref`,
and the design diagram is read at that **one** wing loading — the lecture's own
note on the box: *"You don't need to draw the entire chart because W/S is
fixed."* That is what makes the trade studies possible.

## Four switches, all in the requirements file

Every one is **measured**, not asserted. `run_ttpa_sizing` prints the comparison
table; the numbers below are from it.

| Switch | Options | W_TO |
| --- | --- | --- |
| `sizing.mode` | `fixed_wing_area` (lecture) / `design_point` (IHW2) | 5322 / 5434 |
| `missions.…method` | `L2` (improved) / `L1` (IHW1) | 5322 / 4933 |
| `weights.method` | `table_15_2` (EW-II) / `raymer_ga_III` (EW-III) | 5322 / 6268 |
| cruise `method` | `power_index` (Roskam) / `drag_based` | 5322 / 5443 |

### `sizing.mode`
`fixed_wing_area` is the lecture: `S_ref` in, `W/S` computed, engine sized
**exactly** to the binding constraint. `design_point` is the IHW2 route — solve
the matching diagram, `S_ref` comes out — and it is what the framework's own
`SizingLoopL2` does for the F-16 and the 777. The second is the special case of
the first where `S_ref` lands on the envelope corner, and `verify_framework`
proves it: the two modes rebuild the *identical* airplane to **1.3 × 10⁻⁷**.

### `missions.method` — the biggest single error in the old code
IHW1 flies cruise at `L/D_max`. But 200 KTAS at 8000 ft with `W/S ≈ 39` pins
`C_L = 0.366`, where the real `L/D` is **10.53**, not 13.45 — the model was
**27.6 % optimistic**. Best-L/D speed is 139 kt and the requirement is 200 kt, so
the airplane genuinely cruises well below best L/D. In loiter the error runs the
other way: 120 KTAS at 4000 ft lands almost exactly on best L/D, so the `0.866`
factor is 13 % pessimistic. Net effect on mission fuel: **+12.1 %**.

This is the lecture's "no correlation between L/D and the estimated drag polar",
and the `W_0/S_ref → Fuel fraction` arrow is the fix. `run_mission_L2` segments
the cruise (12 sub-segments), recomputes `C_L` in each, uses an energy-method
climb, and flies loiter at its actual condition. `run_mission.m` (IHW1) is
untouched and still selectable.

**One lecture rule deliberately not adopted.** The 15-min-idle ground-fuel rule
is written for a jet. Applied to this piston twin with a constant BSFC it gives
**6.5 lbf** for start, taxi and takeoff against Roskam's **82 lbf**, because
piston SFC at idle is far worse than at cruise and a constant-BSFC model cannot
see it. The lecture says to use the idle fuel flow *"for your particular
engine"* — data this model does not carry. Roskam's GA-calibrated fraction is
the better answer, and the lecture makes the same call for descent and landing.
The rule is implemented and available as `lecture_idle_rule`.

### `weights.method` — and the lecture's own trade study, reproduced
Empty weight II is Raymer Table 15.2: an areal density times an area, with **no
aspect ratio in it**. Empty weight III swaps two rows for the Raymer §15.3.3 GA
statistical equations — **Eq. 15.46** for the wing, which carries
`(A/cos²Λ)^0.6`, and **Eq. 15.52** for the installed engine, which *includes the
propeller* (Table 15.2's `1.4 ×` factor models no propeller at all).

`run_ttpa_trade_studies` reproduces the lecture's aspect-ratio slide exactly:

| AR | EW-II MTOW | EW-III MTOW |
| --- | --- | --- |
| 6 | 5511.7 | 6292.6 |
| 7.5 | ~5340 | **6262.9 ← minimum** |
| 10 | 5268.1 | 6328.3 |
| 12 | **5240.4 ← still falling** | 6425.8 |

Empty weight II says *more AR is always better*. Empty weight III produces a
real interior minimum at **AR = 7.5** — the lecture's own answer. Note the
objective must be **MTOW**, not fuel: fuel falls with AR under both models,
because a longer span always cuts induced drag. It is the takeoff weight that
shows the trade.

### cruise `method`
The Roskam power index does not read the drag polar, which is why the TTPA
design point never moves. Replacing it with the actual power balance:

```
at W/S = 40:   power_index  W/P <= 11.243      drag_based  W/P <= 8.670
envelope corner: (37.375, 10.505)    ->    (43.196, 9.066)
```

So the IHW2 design point of 9.25 is about **6 % short of 200 KTAS at the
specified 80 % power setting** — it makes the speed at full throttle with 17 %
margin. Either the `Ip = 1.4` reading or the 0.8 power setting is optimistic.
Under `drag_based` the corner genuinely moves as the geometry changes.

## The main loop — `run_ttpa_sizing_mainloop`, where `S_ref` is an OUTPUT

```bash
matlab -batch run_ttpa_sizing_mainloop
```

`run_ttpa_sizing` runs the **lecture** framework: `S_ref` is a green input you
choose and the wing loading `W_0/S_ref` is computed. `run_ttpa_sizing_mainloop`
runs the **whiteboard** framework, which is the other direction — the
constraint analysis is solved for its own least-engine corner on every pass and
`S_ref = W_0/(W/S)` falls out. Three states are iterated, not two:

| | box | file |
| --- | --- | --- |
| **1** | constraint analysis → `W/S`, `W/P` | `matching_envelope` → `run_constraints` |
| **2** | `S = W_0/(W/S)`, `P = W_0/(W/P)` → tails, wetted area, `C_D0`, engine | `TtpaGeom`, `TtpaProp`, `TtpaAero` (all Dependent) |
| **3** | mission analysis → `W_f` | `mission_fuel` → `run_mission_L2` |
| **4** | `S → W_w`, `P → W_e` → `OEW` | `TtpaWeights.OEW_breakdown` |
| **5** | TOGW closure → `W_0^new` | `SizingSteps.togw_update` |
| **6** | `|ΔW_0| < ε` and `|ΔP_0| < ε` | else relax all three and go to 1 |

`sizing_loop.m`, `run_ttpa_sizing.m` and every discipline class are **unchanged
by this file** — it is a second, independent driver, and the two agree (below).

### Converged answer

```
W_TO   5414.74 lbf    W/S   43.2404 psf    C_D0  0.02873    L/D max 13.314
P_SL    606.15 hp     W/P    8.9330 lb/hp  S_ht  28.041 ft² b      31.651 ft
S_ref   125.22 ft²  ← OUTPUT              S_vt  15.155 ft²  OEW   3039.3 lbf
fuel   1175.42 lbf    303.1 hp/engine     driving: Cruise Speed
```

34 passes at the measured relaxation of 0.45. **15 of 15** starting guesses
(`W_0` 2500–10000 lbf × `S_0` 90–200 ft²) reach this same point — including
`W_0 = 2500`, where the `fixed_wing_area` mode of `sizing_loop` fails.

### It reproduces the existing loop to 1.3 × 10⁻⁷

Run with `'corner', "selected", 'cruise', "power_index"` and the mainloop is
solving the same problem `sizing_loop` solves in `design_point` mode:

```
sizing_loop  design_point/selected :  W 5433.4729  P 587.4023  S 135.8368
mainloop     corner = selected     :  W 5433.4722  P 587.4021  S 135.8367
relative difference                :  1.3e-07     2.3e-07     5.8e-07
```

Two independently written three-state and two-state loops landing on the same
airplane is the verification that matters here.

### What actually sets `S_ref` — and it is not a trade

This is the finding the loop exists to produce, and it is not the flattering
one. For `S_ref` to be a genuine answer, something in the constraint analysis
has to notice that the wing changed. Measured:

| condition | reads | moves with `S_ref`? |
| --- | --- | --- |
| Takeoff | `CLmax`, `W/S` | no |
| Landing (wall) | `CLmax`, `W/S` | no |
| Climb ×3 | `C_D0`, `K` | **yes** — but never bind |
| Cruise `power_index` | Roskam correlation | no |
| Cruise `drag_based` | the drag polar | **yes** |

So the mainloop defaults to `drag_based`. But the converged design lands on the
**landing wall**: `W/S = 43.2404 psf` on every single pass, 0.00 % margin.
At 200 KTAS this airplane flies at `C_L ≈ 0.37`, far below best L/D, so cruise
wants *less* wing, and the 1500 ft landing requirement is the only thing
stopping it. `S_ref` is therefore `W_TO` divided by a constant — the constant is
just a landing requirement instead of a frozen correlation.

The corner only becomes interior when the airplane is heavy enough to want more
wing. Under Empty Weight III it closes at `S_ref = 141.78 ft²`, `W/S = 42.42`,
**1.89 % inside the wall, driven by Takeoff** — and there the design diagram is
genuinely trading power against wing area.

**Bottom line:** this loop is the correct *closure*, and it is the structure the
F-16 and 777 examples use. It is not an optimiser, and on this airplane in most
configurations `S_ref` is set by one binding requirement rather than by an
aerodynamics-against-weight optimum. For a true optimum use
`run_ttpa_sizing_optim`.

### What each switch is worth

Every row re-runs the whole loop with one switch moved.

| configuration | W_TO | P_SL | S_ref | W_fuel | OEW | passes |
| --- | --- | --- | --- | --- | --- | --- |
| baseline (`drag_based`, EW-II, L2, optimum) | 5414.7 | 606.1 | 125.22 | 1175.4 | 3039.3 | 34 |
| cruise `power_index` | 5242.3 | 499.0 | 140.26 | 1166.4 | 2875.9 | 32 |
| weights III (Raymer §15.3.3) | 6015.0 | 648.9 | **141.78** | 1270.0 | 3544.9 | 52 |
| mission L1 (IHW1 fractions) | 5219.5 | 593.0 | 120.71 | 1047.8 | 2971.6 | 30 |
| corner `selected` (IHW2 point) | 5433.5 | 587.4 | 135.84 | 1188.4 | 3045.1 | 43 |

### Options

`'cruise'` · `'weights'` · `'mission'` · `'corner'` · `'W_guess'` · `'S_guess'`
· `'tol'` · `'max_iter'` · `'relax'` · `'trace'` (`"ends"`/`"all"`/`"off"`) ·
`'compare'` · `'plot'`.

```matlab
run_ttpa_sizing_mainloop('weights', "raymer_ga_III", 'trace', "all")
```

### What it prints

The full per-pass history of **everything that moves**, in six tables.

The **headline table** carries one whole pass on one line — the three states
going in, the geometry and drag they produce, every row of the weight
build-up, and the closure that hands the next takeoff weight back to step 1:

```
  # W_TO in P_SL S_ref S_wet C_D0 S_HT S_VT | wing ht vt fuselage gear engine all-else OEW OEW/W_0 | W_fuel payload W_TO out
```

`W_TO in` is what the pass started from, `W_TO out` is `W_payload/denom` from
step 5; the gap between them is the residual. `payload` is constant by
definition — it is the one weight the loop solves *around* rather than *for*.
The line is 160 characters, so widen the terminal or it will wrap.

Then: the constraint-analysis output with the driving constraint and both
margins; the planform (`b`, `MAC`, chords, `S_ht`, `S_vt`, nacelle, fuel
volume); the five wetted areas with `C_D0`, `e` and `L/D max`; the engine and
the mission fuel; the seven weight rows again on their own; and the closure
with all three residuals. Plus a stage-by-stage trace through the six boxes,
and a six-panel convergence figure written to
`output/ttpa_mainloop_convergence.png`.

### Relaxation

`sizing.relaxation_mainloop = 0.45` in the requirements file. Three states
couple more strongly than two — a weight overshoot is also a wing overshoot —
so this loop needs its own value. Measured, not guessed; every value reaches the
same fixed point to within 0.003 lbf:

| relax | 0.50 | 0.45 | 0.40 | 0.35 | 0.30 | 0.25 | 0.20 | 0.15 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| passes | 95 | **34** | 35 | 41 | 49 | 60 | 76 | 103 |

A retry ladder (`0.30 → 0.20 → 0.12`) catches any configuration that rings.

### Changes this made outside the new file

Two, both minimal:

- **`TtpaProp.rated_bhp_per_engine` is now public.** `P_SL` is an *output* of
  the sizing loop, so whether the converged engine falls inside the 60–500 bhp
  band Raymer Table 10.4 is printed for is a post-convergence check a driver has
  to be able to make. Private forced every driver to re-implement the comparison
  against `bhp_range`. No behaviour change.
- **`sizing.relaxation_mainloop` added to the requirements JSON.** Read only by
  this file.

`TtpaGeom`, `TtpaAero` and `TtpaWeights` needed **no change** — every coupling
this loop exercises was already there, because the Dependent-property design
means `S_ref` and `P_SL` are the only two writes needed to resize the whole
airplane. The one weakness the loop does expose is documentation, not code: the
installed engine is **43.4 % of OEW**, the largest single row, and under
`table_15_2` that row is `1.4 × W_bare`, which models no propeller at all.
The driver now says so at the end of every run and points at Empty Weight III
(Raymer Eq. 15.52), which includes it.

## Files

**Framework** — `sizing_loop` · `design_diagram` · `SizingSteps` ·
`mission_fuel` · `run_mission_L2` · `solve_design_point`
**Disciplines** — `TtpaGeom` · `TtpaAero` · `TtpaProp` · `TtpaWeights` ·
`ttpa_disciplines` · `Ttpa_requirements_IHW3.json`
**Studies** — `run_ttpa_sizing` · **`run_ttpa_sizing_mainloop`** ·
`run_ttpa_trade_studies` · `run_ttpa_sizing_optim` · `run_ttpa_PS_diagram` ·
`TtpaPSDiagram` · `plot_sizing_convergence`
**XDSM** — `docs/xdsm_ttpa_sizing.py` (lecture loop) ·
`docs/xdsm_ttpa_mainloop.py` (main loop) — see `docs/README.md`
**Checks** — `wing_fuel_check` · `landing_gear_loads` · `verify_ihw3a` ·
`verify_framework` · `sens.m` · `slice.m`
**Unchanged from IHW1/IHW2** — `run_mission` · `get_miss_seg` ·
`constraint_takeoff/landing/climb` · `run_constraints` · `matching_envelope` ·
`design_point_check` · `get_con` · the four base classes · `AircraftState` ·
the two readers

`constraint_cruise_speed` and `get_con` gained a method switch; `get_state`
gained a memo (bit-identical, 18× faster — the L2 mission and the P–S scan make
roughly a million atmosphere calls without it).

## Converged answer

Default configuration (`fixed_wing_area`, mission L2, weights II, power index),
`S_ref = 128.47 ft²`:

```
W_TO   5322.0 lbf    W/S   41.43 psf     CD0   0.02819    L/D max 13.44
OEW    2957.4 lbf    W/P    9.492 lb/hp  S_ht  29.14 ft²  b      32.06 ft
fuel   1164.6 lbf    P_SL  560.7 hp      S_vt  15.75 ft²
```

Against the IHW1/IHW2 baseline of 5354 lbf: **−0.6 %** on takeoff weight. Two
large corrections nearly cancel — the improved fuel fractions add weight, the
component build-up removes it.

## Numerical behaviour

**Relaxation is mode-dependent, and measurably so.** `fixed_wing_area` rings:
a heavier airplane raises `W/S`, which the takeoff constraint answers with a
lower allowed `W/P`, which is a bigger and heavier engine. At 0.5 it takes ~110
iterations with a visible oscillation; at **0.40** it takes ~60.
`design_point` is well behaved at **0.50** (~32 iterations).

**Guess robustness** (2500–10000 lbf, 16 guesses): `design_point` **16/16**,
`fixed_wing_area` **15/16** (fails only at 2500, a 2× underestimate). Both
converge to within 5 × 10⁻³ lbf of the same answer. A transient-recovery guard
in `sizing_loop` catches both failure modes — a non-closing denominator and a
mission that cannot climb on the engine a low trial weight implies.

## Verification

`verify_ihw3a` (9 claims) and `verify_framework` (6 claims). Highlights:

- the two sizing modes rebuild the identical airplane to **1.3 × 10⁻⁷**
- the L2 cruise `C_L`/`L/D` match a hand calculation exactly (0.3661 / 10.534)
- EW-II gives an edge minimum, EW-III an interior one at **AR = 7.5**
- all seven weight rows and `CD0` reproduce by hand to machine precision
- geometry at `S_ref = 134 ft²` reproduces the IHW3 notebooks (b 32.74 vs 33,
  MAC 4.34 vs 4.3, `V_wf` 37.07 vs 37, `S_ht` 31.04 vs 31)
- the P–S diagram and the loop agree to the grid resolution
- `get_state` memoisation is bit-identical, σ at sea level exactly 1

`sens.m` quantifies the uncited modelling assumptions (nacelle length factor,
tail-cone closure, fuselage split): all move `W_TO` by **≤ 2 %** over generous
ranges.

## Known approximations

- Tail **weight** rows use theoretical area, not exposed — the volume-coefficient
  method defines area to the centreline, and an exposed tail area needs a
  fuselage width at the tail station the cabin-driven model does not carry.
  Worth about 9 lbf, under 0.4 % of OEW.
- Empty weight III swaps only the wing and engine rows; the other five stay at
  Table 15.2. Swapping them needs a dozen new inputs for a few percent, and the
  lecture's point is about the wing.
- The nacelle length factor (2.0) is a layout assumption, not a textbook value —
  the weakest input in the model.
