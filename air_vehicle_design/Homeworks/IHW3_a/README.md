# IHW3a — TTPA sizing on the preliminary design framework

**AOE 4065 · Test Twin Propeller Aircraft**

```bash
matlab -batch run_ttpa_sizing          # size the airplane, end to end
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

## Files

**Framework** — `sizing_loop` · `design_diagram` · `SizingSteps` ·
`mission_fuel` · `run_mission_L2` · `solve_design_point`
**Disciplines** — `TtpaGeom` · `TtpaAero` · `TtpaProp` · `TtpaWeights` ·
`ttpa_disciplines` · `Ttpa_requirements_IHW3.json`
**Studies** — `run_ttpa_sizing` · `run_ttpa_trade_studies` ·
`run_ttpa_PS_diagram` · `TtpaPSDiagram` · `plot_sizing_convergence`
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
