# Subplan 08 — Sizing

**Status:** Placeholder — not started. Already known stale against the as-built code (see
`docs/PLAN.md`'s "Resolved Decisions") even before this note: this doc's tail-sizing/control-surface
file paths and coefficients below (`TailSizingLevel1.m`, `ControlSurfaceSizer.m`, `c_HT=0.40`) describe
a design that was superseded three times — first 2026-07-28 (three-tier `tail_sizing` discipline,
corrected Raymer 7th ed. coefficients 0.315/0.063), then 2026-08-03 (that discipline absorbed into
Geometry, `ControlSurfaceSizer.m` deleted), then 2026-08-05 (the absorption reversed — `tail_sizing`
and `ControlSurfaceSizer.m` restored as standalone objects again, `SizingLoopL2` back to
dependency-injecting `tail`/`ctrl` — see `docs/PLAN.md`'s current "Tail sizing and control-surface
sizing" entry for the real, as-built file paths, which now again match this doc's `tail.size(...)` /
DI shape below more closely than the intervening absorbed-into-geometry state did). Not rewritten here
since this whole doc is a pre-implementation placeholder, not living documentation.
**Depends on:** Steps 0–7 (all prior steps complete and tested)
**Blocks:** Nothing — final integration step

---

## Objectives

Implement `SizingLoopL1` and `SizingLoopL2`. Generate XDSM diagrams before any MATLAB code is written. Validate against F-16 Brandt ground truth using F-16 discipline subclasses. `SizingLoopL2` adds tail sizing (L1 volume coefficients) and a quick control surface sizing pass.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/sizing/SizingLoopL1.m` | Single-variable iteration (W_TO only) |
| `src/sizing/SizingLoopL2.m` | Two-variable iteration (W_TO and T_SL); calls tail + control surface sizing each iteration |

### Layer 2 — F-16 specific (`examples/F16A/`)

The sizing loops are fully generic. F-16-specific work is in the design study scripts:

| File | Purpose |
|------|---------|
| `examples/F16A/models/sizing/design_study_01_L1.m` | F16L1 disciplines → SizingLoopL1 |
| `examples/F16A/models/sizing/design_study_02_L2.m` | F16L2 disciplines → SizingLoopL2 |
| `examples/F16A/models/sizing/design_study_03_L3.m` | F16L3 disciplines → SizingLoopL2 |

### Tests

| File | Tests |
|------|-------|
| `tests/sizing/TestSizingLoops.m` | Generic: convergence with mock discipline objects |
| `tests/examples/F16A/TestF16SizingStudies.m` | F-16: W_TO, T_SL, S_ref in physically reasonable range |

---

## Pre-Implementation: XDSM Diagrams

**Before writing any MATLAB:** review the sizing L1/L2 XDSM data-flow diagrams with the professor before implementing. The XDSM diagram scripts are no longer in the repo, but the data flow they capture must match the call sequence below.

---

## Design Notes

- `SizingLoopL1` and `SizingLoopL2` are plain handle classes (no abstract base). Constructor: `SizingLoopL1(aero, prop, wts, geom, miss, con)`.
- Under-relaxation factor = 0.5 (default); configurable via `opts` struct.
- Convergence tolerance: 1.0 lbf. Max iterations: 200.
- `run(req)` returns struct: `result.W_TO`, `result.S_ref`, `result.T_SL`, `result.n_iter`, `result.converged`, `result.history`.
- All discipline objects are mutated in-place (handle semantics). Always create fresh objects at the start of each design study.

---

## SizingLoopL1 — Call Sequence (per iteration)

Per the framework design intent (now captured in the repo's `CLAUDE.md` and `docs/PLAN.md`):
```matlab
opt        = con.optimal_point(aero, prop)   % → {W_S, T_W}
S_ref      = W_TO / opt.W_S
geom.S_ref = S_ref
req.S_ref  = S_ref
prop.T0    = opt.T_W * W_TO
W_fuel     = miss.compute_fuel(aero, prop, W_TO, req)
W_OEW      = wts.OEW(W_TO)
W_TO_new   = W_OEW + req.W_payload + W_fuel
W_TO       = 0.5*W_TO + 0.5*W_TO_new        % under-relaxation
```

---

## SizingLoopL2 — Call Sequence (per iteration)

Per the framework design intent (now captured in `CLAUDE.md` and `docs/PLAN.md`) + resolved decisions:

> **SUPERSEDED 2026-08-10 — `S_ref` is no longer fixed at L2/L3.** `SizingLoopL2` now solves for `S_ref` every iteration exactly as `SizingLoopL1` does (`S_ref = W_TO / WS_opt`, written into `geom.S_ref`), so `optimal_point()`'s `W/S` output is used, not discarded, and `result.S_ref` / `result.history(k).S_ref` are solved outputs. The JSON `.geometry.wing.S_ft2` value is only the starting point. See `src/sizing/SizingLoopL2.m`'s header for the feedback paths and the current converged F-16A numbers; the pseudocode below reflects the pre-2026-08-10 behavior.

```matlab
opt        = con.optimal_point(aero, prop)   % → {W_S, T_W}
S_ref      = W_TO / opt.W_S                  % ADDED 2026-08-10
geom.S_ref = S_ref                           % ADDED 2026-08-10
T_SL_new  = opt.T_W * W_TO
prop.T0   = T_SL_new

% Tail sizing (L1 volume coefficient method)
tail_result   = tail.size(S_ref, geom.b, geom.cbar, geom.L_fus)
geom.S_HT     = tail_result.S_HT
geom.S_VT     = tail_result.S_VT

% Control surface sizing (Raymer Fig 6.3, Table 6.5)
cs_result     = ctrl.size(geom)
geom.S_ail    = cs_result.S_ail    % aileron
geom.S_elev   = cs_result.S_elev   % elevator
geom.S_rud    = cs_result.S_rud    % rudder

W_fuel    = miss.compute_fuel(aero, prop, W_TO, req)
W_OEW     = wts.OEW(W_TO)
W_TO_new  = W_OEW + req.W_payload + W_fuel
W_TO      = 0.5*W_TO + 0.5*W_TO_new
T_SL      = 0.5*T_SL + 0.5*T_SL_new
```
Convergence: `|W_TO_new − W_TO| < tol` AND `|T_SL_new − T_SL| < tol`.

---

## Control Surface Sizing

**REWRITTEN 2026-08-10.** The table this section used to carry was wrong in three ways that the
implementation had already corrected: Raymer Table 6.5 has **no aileron column at all** (the aileron
guideline is Fig. 6.3, a shaded chart); Table 6.5's `Ce/C` and `Cr/C` are **tail-chord** fractions, not
area fractions of `S_HT`/`S_VT`, so a span-fraction factor is required to get an area; and the F-16 has
neither a separate aileron nor a separate elevator, so those were exactly the two surfaces the old
design sized. See `src/sizing/ControlSurfaceSizer.m`'s header, which is authoritative.

**File:** `src/sizing/ControlSurfaceSizer.m` (plain `handle` class, not abstract, no per-fidelity tier —
it has no equation set that varies with fidelity).

**Method:** `size(geom) → struct(S_ail, S_elev, S_rud, S_flaperon, S_lef, S_stab)`

Reads `geom.S_ref`, `geom.S_ht`, `geom.S_vt` and — for the wing flaps — `geom.lambda_wing`, all live.
Two families:

| Surface | Equation | Reference |
|---------|----------|-----------|
| Aileron | `S_ail = c_ail_frac × b_ail_frac × S_ref` | Raymer 6th ed. Fig. 6.3 (chord/span band, p.161) |
| Elevator | `S_elev = c_elev_frac × b_elev_frac × S_ht` | Raymer 6th ed. Table 6.5 `Ce/C`; p.161 ~90 % span |
| Rudder | `S_rud = c_rud_frac × b_rud_frac × S_vt` | Raymer 6th ed. Table 6.5 `Cr/C`; p.161 ~90 % span |
| Flaperon | `S_flaperon = c_frac × ratio(η_out, η_in, λ) × S_ref` | Roskam Part II Eq. 7.10 via `AeroL2.compute_S_flapped_ratio` |
| LE flap | `S_lef = c_frac × ratio(η_out, η_in, λ) × S_ref` | same |
| Stabilator | `S_stab = S_ht` when `ht_all_moving` | Raymer 6th ed. Table 6.5 footnote |

The wing flaps use span **stations** rather than a bare span fraction because Roskam Eq. 7.10 carries
the taper term: on a wing tapered to λ = 0.2275, the same span *extent* placed inboard or outboard
gives different areas, which a bare chord × span product cannot see.

**Role exclusivity, enforced in the constructor:** exactly one of (`S_ail`, `S_flaperon`) and one of
(`S_elev`, `S_stab`) is nonzero for a given airframe. A flaperon already *is* the roll surface, and an
all-moving stabilator has no hinged elevator, so declaring both of either pair double-counts one
physical surface and silently inflates every downstream area sum.

**For the F-16** (`examples/F16A/f16a_control_surfaces.m`, the single place the wiring lives): flaperon
+ leading-edge flaps + all-moving stabilator + rudder; `c_ail_frac = c_elev_frac = 0`. That function's
header carries every fraction's provenance and its measured accuracy against T.O. 1F-16A-1 Fig. 1-2.
Note the framework computes **estimates** and the T.O. areas are **comparison targets** — see
`VnV/BrandtF16A/todo.md` 2026-08-10 for the accuracy findings and the standing rule on not mixing the
two directions.

**Weights coupling (L3 only).** `F16GeomL3`'s `S_csw` (= `S_flaperon + S_lef`, Raymer Eq. 15.1), `S_r`
(= `S_rud`, Eq. 15.3) and `S_cs` (= `S_csw + S_stab + S_rud`, Eq. 15.17) are `Dependent` on the areas
this loop writes, so a wing or tail rescale reaches OEW. They were frozen inputs until 2026-08-10, which
meant the L3 weights kept a 300 ft²-wing control-surface area while the loop converged `S_ref` to
roughly 210. `F16GeomL2` has no such properties and `F16WeightsL2` consumes none, so at L2 the
control-surface areas remain report-only.

---

## Tail Sizing (L1 only — L2 is future work)

**File:** `src/disciplines/tail_sizing/TailSizingLevel1.m` (also `examples/F16A/disciplines/tail_sizing/F16TailSizingLevel1.m` wires in c_HT=0.40, c_VT=0.07 from F-16A Block 50.xlsx)

| Surface | Equation | Reference |
|---------|----------|-----------|
| S_HT | c_HT × cbar × S_ref / L_HT; L_HT = 0.5 × L_fus | Raymer 6th ed, eq 6.28 |
| S_VT | c_VT × b × S_ref / L_VT; L_VT = 0.5 × L_fus | Raymer 6th ed, eq 6.29 |
| c_HT (fighter) | 0.40 | Raymer 6th ed, historical table |
| c_VT (fighter) | 0.07 | Raymer 6th ed, historical table |

**L2 tail sizing:** Raymer Chapter 16 — deferred to future work.

---

## F-16 Design Studies

| Study | Aero | Prop | Weights | Mission | Constraints | Loop |
|-------|------|------|---------|---------|-------------|------|
| design_study_01_L1 | F16AeroL1 | F16PropL1 | F16WeightsL1 | MissionAnalysisL1 | F16ConstraintSet | SizingLoopL1 |
| design_study_02_L2 | F16AeroL2 | F16PropL2 | F16WeightsL2 | MissionAnalysisL2 | F16ConstraintSet | SizingLoopL2 |
| design_study_03_L3 | F16AeroL3 | F16PropL2 (no PropL3) | F16WeightsL3 | MissionAnalysisL3 | F16ConstraintSet | SizingLoopL2 |

---

## Tests

### Generic (`tests/sizing/TestSizingLoops.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| SizingLoopL1 converges with mock disciplines | `result.converged == true` | exact |
| SizingLoopL2 converges with mock disciplines | `result.converged == true` | exact |
| History has n_iter rows | correct size | exact |
| Control surface areas positive (L2) | S_ail, S_elev, S_rud > 0 | exact |
| S_HT, S_VT positive after tail sizing (L2) | > 0 | exact |

### F-16 specific (`tests/examples/F16A/TestF16SizingStudies.m`)
| Test | Study | Expected | Tolerance |
|------|-------|----------|-----------|
| W_TO | design_study_01 (L1) | 25,000–40,000 lb (±20% of Brandt 31,377) | textbook accuracy |
| W_TO | design_study_02 (L2) | 27,000–37,000 lb (±15% of Brandt) | better |
| T_SL | design_study_02 (L2) | 18,000–30,000 lbf (±20% of Brandt 23,770) | textbook accuracy |
| S_ref (L1 output) | design_study_01 | 250–360 ft² (±20% of Brandt 300) | textbook accuracy |
| All three studies converge | all | `converged == true` | exact |

---

## Verification

```matlab
runtests('tests/sizing/TestSizingLoops.m')
runtests('tests/examples/F16A/TestF16SizingStudies.m')
runtests('tests/')   % full suite — all prior tests still pass
```
All tests must pass. This is the final STOP — professor reviews all three design study outputs.
