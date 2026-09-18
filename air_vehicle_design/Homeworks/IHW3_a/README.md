# IHW3a — TTPA sizing loop

**AOE 4065 · Test Twin Propeller Aircraft**

Couples the IHW1 mission analysis and the IHW2 constraint analysis into one
calculation and iterates it to a converged airplane.

```matlab
run_ttpa_sizing
```

No arguments, no edits. Run it from this folder.

---

## What changed, and why the loop is needed

Three numbers were **fixed** in the earlier homeworks and are **outputs** here.

| | IHW1 / IHW2 | IHW3a |
| --- | --- | --- |
| `W_TO` | 5354 lbf, converged in IHW1 and typed into the IHW2 driver by hand | a state of the loop |
| `S_ref`, `P_SL` | computed **once** at the end, from that fixed `W_TO` | rewritten every iteration |
| `OEW` | `0.911·W_TO^0.947` — sees only the weight | Raymer Table 15.2 component build-up over real geometry |
| `CD0` | `0.028`, frozen | `Cfe·S_wet/S_ref` — follows the geometry |
| reserve fuel | `1.06` typed into the loop | read from the requirements file |

The first three are the reason the loop exists. At Level 1 the mission analysis
and the constraint analysis genuinely *are* independent — an empty-weight
regression that knows only `W_TO` doesn't care how big the wing is, and the
constraint analysis works in ratios. Once the empty weight is built up from real
areas and the drag comes from real wetted area, the geometry depends on the
weight and the weight depends on the geometry. That circle has to be closed by
iteration.

## The loop

Two states, `(W_TO, P_SL)`. A jet loop uses `(W_TO, T_SL)` with
`T_SL = (T/W)·W_TO`; a propeller airplane works in power loading, which is
inverted — a *bigger* `W/P` means a *smaller* engine — so the second state is
`P_SL = W_TO/(W/P)`. Both must converge.

One iteration, in order — **the order matters**:

1. **Wing** — `S_ref = W_TO/(W/S)`. Writing this one number resizes the span,
   the chords, the MAC, the exposed area, both tails through their volume
   coefficients, and every wetted area.
2. **Engine** — `P_SL` is written *before* the design point is solved, so the
   solve reads this iteration's engine. This is the classic ordering trap.
3. **Design point** — re-solve the matching envelope on the airplane as it now
   stands.
4. **Power** — `P_SL_new = W_TO/(W/P)`.
5. **Closure** — mission fuel and empty weight at the current weight, then
   `W_TO = W_payload / (1 − W_fuel/W_TO − OEW/W_TO)`.
6. **Test** both residuals, then **relax** both states.

## Files

**The sizing code — this is what IHW3a adds**

| File | What it does |
| --- | --- |
| `run_ttpa_sizing.m` | **the run file.** Builds, iterates, reports, checks, plots |
| `sizing_loop.m` | the two-state `(W_TO, P_SL)` loop |
| `SizingSteps.m` | `togw_update` (the closure) and `relax` (the damping) |
| `solve_design_point.m` | re-solves the design point each iteration, `selected` or `optimum` |
| `mission_fuel.m` | total mission fuel at a weight — IHW1's loop body, lifted out |
| `wing_fuel_check.m` | post-convergence: does the wing hold the fuel? |
| `landing_gear_loads.m` | post-convergence: static gear loads |
| `plot_sizing_convergence.m` | four-panel convergence history |
| `verify_ihw3a.m` | checks every claim made in this file and in the comments |

**Discipline models — upgraded from IHW2**

| File | What changed |
| --- | --- |
| `TtpaGeom.m` | was two NaNs. Now the whole L2 planform, all Dependent on `S_ref` |
| `TtpaWeights.m` | statistical regression → Raymer Table 15.2 component build-up |
| `TtpaAero.m` | `CD0` fixed → Dependent, `Cfe·S_wet/S_ref` (Raymer Eq. 12.23) |
| `TtpaProp.m` | IHW2 plus `engine_weight()` and `engine_length()` (Raymer Table 10.4) |
| `Ttpa_requirements_IHW3.json` | IHW2 blocks plus `geometry`, `weights`, `sizing` |
| `ttpa_disciplines.m` | now injects: `prop → geom → aero → wts` |
| `ttpa_requirements_path.m` | points at the IHW3 file |

**Carried over unchanged** — `run_mission.m` and `get_miss_seg.m` from IHW1;
`constraint_*.m`, `run_constraints.m`, `matching_envelope.m`,
`design_point_check.m`, `get_con.m`, `get_state.m` from IHW2; plus the four base
classes, `AircraftState`, `MissionProfileReader`, `ConstraintSetImporter`,
`json_as_struct_array`.

`run_mission.m` needed **no change at all**. It reads `obj.aero.LD_max`, which is
now Dependent on the geometry, so the Breguet segments automatically use the drag
of the airplane the loop has just laid out.

## Converged answer

Design point `(40, 9.25)`, starting guess 5000 lbf, 30 iterations:

```
W_TO      5138.7 lbf      S_ref   128.47 ft^2      b      32.06 ft
OEW       2919.7 lbf      S_ht     29.14 ft^2      MAC     4.25 ft
fuel      1018.9 lbf      S_vt     15.75 ft^2      CD0   0.02817
payload   1200.0 lbf      P_SL    555.5 hp        L/D max 13.446
                                  277.8 hp/engine
```

Against the IHW1/IHW2 baseline (`W_TO` held at 5354): −4.0 % weight, −5.6 % empty
weight, −4.0 % wing area and power. That movement is the expected result of
replacing a regression that cannot see the airplane with a build-up that can, not
an error.

## Equations and sources

| Quantity | Source |
| --- | --- |
| TOGW closure | metabook Ch. 2 Algorithm 1; Raymer Eq. 3.4 |
| Root/tip chord, MAC | Raymer Eqs. 7.6, 7.7, 7.8 |
| Lifting-surface wetted area | Raymer Eqs. 7.11, 7.12 |
| Fuselage wetted area | Raymer Eq. 7.13 |
| `CD0 = Cfe·S_wet/S_ref`, `Cfe = 0.0045` | Raymer Eq. 12.23, Table 12.3 (light twin) |
| Tail areas by volume coefficient | Raymer §6.5; Roskam Part II Ch. 8; Nicolai & Carichner Table 11.1 |
| Component weight build-up | Raymer Table 15.2, **General Aviation** column |
| Engine weight and length vs bhp | Raymer Table 10.4, horizontally-opposed |
| Wing fuel volume | Torenbeek |
| Landing-gear static loads | Raymer Ch. 11 |
| Mission weight fractions | Roskam Part I Table 2.2 (unchanged from IHW1) |
| Constraint methods | Roskam Part I §3.1, 3.2, 3.3, 3.6 (unchanged from IHW2) |

Two numbers in the geometry block are **layout assumptions, not textbook
values**, and are flagged as such in the JSON: the nacelle length factor (2.0)
and the fuselage nose/cabin/cone split. The nacelle factor is the weakest number
in the model — change it and the parasite drag moves.

## Three things worth knowing

**Under-relaxation is not optional.** At `relax = 1` the loop dies with
`closureInfeasible` from every starting guess tested (2500, 5000, 8000 lbf): a
full step overshoots into the region where the empty and fuel fractions consume
the whole takeoff weight. At `relax = 0.5` it converges from all 31 guesses
between 2500 and 10000 lbf, in 29–40 iterations, to within 0.003 lbf of the same
answer. The error is a *design* result, not a coding mistake, which is why the
loop raises it rather than returning a negative weight.

**The design point does not actually move.** The loop re-solves it every
iteration — that is the correct Level-2 structure — but for the TTPA the corner
stays at `(37.3747, 10.5049)` and the wall at `43.2404` regardless of how the
geometry changes. Of the six conditions, only Takeoff and Cruise Speed ever set
the envelope, and neither reads the drag polar: Takeoff reads only `CLmax_TO`,
Cruise Speed only the power index. The three climb curves *do* move with `CD0`,
but they are not binding. `result.history` carries the evidence rather than the
assumption. If you want the design point to respond to the geometry, the cruise
constraint has to be rewritten from Roskam's power-index correlation to the
actual power balance — that is a Level-2 upgrade IHW3a does not make.

**The cross-checks are the real answer key.** `run_ttpa_sizing` prints four:
the geometry-driven `CD0` against IHW2's frozen `0.028` (+0.6 %), the component
build-up against the IHW1 regression (−1.9 %), the four weights summing to
`W_TO` (residual ~1e-4 lbf), and the whole airplane against the IHW1/IHW2
baseline. Two independent methods agreeing within a couple of percent is the
evidence the geometry is right; if they diverge, look at the geometry first.

## Verification

`verify_ihw3a` checks all of it and prints the results: convergence from 31
starting guesses, the `relax = 1` failure, that the design point is stationary,
that `optimum` mode runs (and costs 242 lbf and 89 hp less than the selected
point — the price of the margin), that every Dependent property tracks `S_ref`,
that all seven weight rows and `CD0` reproduce by hand to machine precision, and
that the geometry at `S_ref = 134 ft²` reproduces the IHW3 reference notebooks:

```
b 32.74 ft (33)   c_root 5.85 (5.8)   c_tip 2.34 (2.3)   MAC 4.34 (4.3)
y_MAC 7.02 (7)    V_wf 37.07 ft^3 (37)
S_ht 31.04 ft^2 (31)   S_vt 16.78 ft^2 (17)   b_ht 13.07 ft (13)
```
