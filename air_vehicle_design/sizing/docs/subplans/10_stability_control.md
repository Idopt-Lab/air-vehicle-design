# Subplan 10 — Stability & Control (longitudinal static, steady level flight)

**Status:** Not started — target spec only. Per agreed sequencing, `scribe` kickoff for this discipline
is **deferred to a future session** (unlike Subsystems, subplan 09) — see "Why scribe is deferred" below.
**Depends on:** Step 2 (Geometry L2/L3 — MAC, x_ac, tail geometry), Step 3 (Aerodynamics — `CL_alpha`,
wing/tail lift coefficients), Step 4 (Propulsion L2 — thrust x-location / inlet mass-flow terms), Step 5
(Weights L3 — component weight values for the CG buildup).
**Blocks:** none directly yet, but directly informs PLAN.md's deferred Tail-Sizing L3 item ("Raymer
Ch. 16 stability-and-control-based sizing... no verifiable Raymer Ch. 16 equation numbers exist anywhere
in this repo's reference material today") — this subplan's equation list is the first real input toward
closing that gap, even though it is not itself scoped as tail-sizing work.

---

## Objective, scoped precisely by Casey

Determine whether a design exhibits **longitudinal static stability, in steady, level flight, only.** No
dynamic/nonsteady stability analysis — that's explicitly left for later.

### In scope — Raymer 6th ed. Ch. 16 equation set (Casey-supplied)

| Quantity | Eq. |
|---|---|
| Moment about the CG | 16.4 |
| Coefficient of moment about the CG | 16.5 / 16.7 |
| Pitching-moment coefficient about the CG (`Cm_cg` buildup) | 16.8 |
| Neutral point | 16.9 |
| Static margin | 16.11 |
| Aerodynamic center, longitudinal location | 16.12 |
| Wing lift coefficient | 16.13 |
| Aft-tail lift coefficient | 16.14 |
| Change in zero-lift angle of attack (`Δα_L0`) — may be needed as a dependency | 16.15, and possibly a second Ch. 12 equation near the `ΔCL_max` tabulations — scribe confirms which is actually used |

### Explicitly out of scope (do not implement)

- Downwash (`dε/dα` terms) — set aside for now. Wherever a full Raymer equation includes a downwash
  term, the implementation notes the simplification explicitly rather than silently dropping it.
- Ground effect.
- Takeoff rotation.
- Velocity (speed) stability.
- Lateral-directional static stability and control.
- Handling qualities.

Only the longitudinal-stability section of Ch. 16 and its explicit equation dependencies are in scope.

### Why scribe is deferred, but the risk is now low

PLAN.md's tail-sizing L3 item was deferred specifically because "no verifiable Raymer Ch. 16 equation
numbers exist anywhere in this repo's reference material today," and the Nicolai Ch. 21 ("Static
Stability and Control")/Ch. 23 ("Control Surface Sizing Criteria") reference extracts that could have
substituted are both still listed "pending" in `temp_AI/docs/disciplines/reference_extracts/`. Casey has
now supplied the Ch. 16 equation numbers directly (table above), which removes most of that citation
risk — scribe's remaining job is to transcribe/verify Raymer's actual formulas and constants against this
list, not to locate the equations from scratch. This subplan is written and ready for that, but per the
agreed session scope, the scribe kickoff itself happens in a future session, not this one.

---

## Fidelity tiering

Per Casey: equations that depend on geometry belong in **L2/L3**; equations that don't (the non-geometry
parts of the `Cm_cg`/neutral-point buildup) belong in **L1**. This is the normal three-tier discipline
pattern — scribe determines the precise per-equation L1/L2/L3 split during the docs pass; this subplan
does not prescribe it in advance.

### Fidelity-collapse contingency

It's possible the course's own assignment scope will turn out to strictly disallow a 3-tier L1/L2/L3
Stability & Control discipline. To keep a collapse to a single fidelity level cheap if that happens, this
discipline must follow the same toolbox-static rule the rest of the repo already follows, with **no
shortcuts**:

- Every Ch. 16 equation lives as a **level-agnostic static method** on the `SandCL*` toolbox — explicit
  scalar/object arguments only, never reading tier-level `obj` state — exactly like `AeroL1.oswald_eff`
  is a shared static called by L1 *and* L2/L3.
- The L1/L2/L3 **split** (which equations each `SandCModelL*`/`F16SandCL*` tier calls) lives *only* in the
  thin `Model`/Tier-3 dispatch classes, never inside the equations themselves.
- Unit tests are written **per static method**, not per fidelity-level narrative, for the same reason.

If a collapse is later forced, the fix is then mechanical: delete/merge the `Model`/Tier-3 tiers down to
one, which calls every Ch. 16 static directly. The toolbox, its citations, and its tests do not change.

---

## Files planned (once scribe/io/implementation actually start)

Same three-tier + toolbox pattern as every other discipline:

| Layer | Path | Purpose |
|---|---|---|
| Base | `src/base/StabControlBase.m` | Abstract contract — `static_margin`, `neutral_point`, `Cm_cg` |
| Enforcers | `src/disciplines/stability_control/SandCModelL1/L2/L3.m` | Per-level abstract method/property declarations |
| Toolboxes | `src/disciplines/stability_control/SandCL1/L2/L3.m` | The actual Ch. 16 equations, cited, level-agnostic statics (see collapse contingency above) |
| Concrete | `examples/F16A/F16SandCL1/L2/L3.m` | F-16 wiring, single delegation lines into the toolbox |
| Tests | `tests/disciplines/TestSandCL1/L2/L3.m` | Per-static-method unit tests |
| Report | `examples/F16A/sandc_brandt_comparison.{m,json,md}` | Informational comparison vs. `BrandtBalanceStabControl` |

---

## Component-x-location buildup — scoped as an S&C-owned input

Per Casey's decision (confirmed): the per-component weight **x-location** (moment-arm station) data this
discipline needs is a **new, S&C-owned input table** (component name → weight, x-station), supplied
alongside S&C's own JSON — populated by cross-referencing `WeightsL3`'s existing component breakdown with
`GeomL3` station data. This is explicitly **not** a retrofit of `WeightsL3`'s contract; `WeightsL3`
continues to expose only weight values, and S&C is the only consumer of the x-location mapping.

---

## Dependency Injection

`F16SandCL2`/`F16SandCL3` inject:
- `F16GeomL2`/`F16GeomL3` (MAC, x_ac, tail geometry — level-appropriate)
- `F16WeightsL2`/`F16WeightsL3` (component weight values, matched by name against the x-location table)
- `F16AeroL2`/`F16AeroL3` (`CL_alpha`, wing/tail lift coefficients)
- `F16PropL2` (thrust x-location / inlet mass-flow terms for the moment buildup — note there is no L3
  propulsion tier repo-wide, so this is `F16PropL2` at every S&C fidelity level, same as Weights)

`F16SandCL1` (if an L1 tier is confirmed useful — see Fidelity Tiering above) injects only what the
non-geometry equations need, likely `F16WeightsL1` and nothing else.

---

## Legacy Bugs to Avoid (from `temp_Casey/src/Disciplines/StabAndCont/SandCLevel3.m`)

| Bug | Fix in the new framework |
|---|---|
| `get_np()` is a stub with no arguments and no body — errors if called | Every declared method has a real implementation before it ships; no stubs |
| `get_static_stability` convenience wrapper passes its arguments to `get_static_margin` in the wrong order and omits required args | Don't add a convenience wrapper until its argument order is tested directly, not just exercised indirectly by a caller that happens to bypass it |
| `Xbar_p = 33.775` (thrust x-location) hardcoded "temporarily" | Thrust x-location comes from injected geometry/propulsion data, not a literal |
| `eta_h` computed from `q_h/q` then immediately overwritten to a hardcoded `0.9` | If a term is genuinely simplified (e.g. downwash, which is out of scope here), say so explicitly in the citation/comment — don't compute a real value and then discard it silently |
| Ambiguous "FIGURE OUT WHAT C IS" comment re: mean-chord usage | Pin the exact chord definition (MAC vs. some other reference length) per equation before implementing, not after |

---

## Ground Truth

`VnV/BrandtF16A/BrandtBalanceStabControl.m` / `readme_bsc.md` (already exists) is the primary comparison
target: `x_np ≈ 26.168 ft`, `x_cg_TO ≈ 26.193 ft`, `x_cg_land ≈ 26.137 ft`, gear split ≈ 26.7% main /
73.3% nose. It is informally called "BSC" in this repo and is not currently mapped to a named Excel sheet
in `VnV/BrandtF16A/GroundTruth/cell-map.md`.

Direct inspection of `temp_Casey/inputs/F-16A Block 50.xlsx` (this session) confirms a sheet literally
named **`Stability&Control`** exists in the source workbook — almost certainly the "S&C (2)" sheet Casey
has in mind. Scribe's job during the docs phase: open that sheet, confirm it's the right source (versus
just cross-checking `BrandtBalanceStabControl`'s already-computed values), and pin its exact cell
references — including whether there's a second "(2)" sub-block (e.g. a takeoff vs. landing CG case) —
the way every other discipline's ground-truth JSON does.
