# Subplan 10 — Stability & Control (longitudinal static, steady level flight)

**Status:** **IMPLEMENTED (2026-08-04), ALL GAPS CLOSED.** `StabControlBase`/`SandCModelL2`/`SandCModelL3`/
`SandCL2`/`SandCL3`/`F16SandCL2`/`F16SandCL3` all exist; `tests/disciplines/TestSandCL2.m`/`TestSandCL3.m`
and `examples/F16A/sandc_brandt_comparison.{m,json,md}` are written and passing (`run_all_tests`: exactly
the pre-existing 12-failure baseline, zero S&C-specific failures). `F16SandCL2` computes only `x_cg`
(CG-only, per the DECIDED note below). `F16SandCL3` fully implements Eqs. 16.8/16.9/16.10/16.11/16.12/
16.15-16.19 plus `Cm_α,fus` (Eq. 16.25, `K_fus=0.025` per Casey's Fig. 16.14 read) with real citations.
Eqs. 16.13/16.14 (`CL_w`/`CL_h`) and 16.5/16.7 (`Cm_cg` trim) are ALL REAL as of 2026-08-04's closure pass:
`i_w=0°` [T.O. 1F-16A-1]; `i_h` reframed as a required caller argument (all-moving stabilator); `x_p`/`z_t`/
`F_p` resolved via Raymer's own text (Eqs. 16.26-16.28, p.604/p.609); and `Cm_acw` [Eq. 16.19, p.598] is a
real, cited formula (`SandCL3.Cm_acw_wing`) that needs one USER/STUDENT-SUPPLIED numeric input,
`Cm0_airfoil_wing` (the wing section's own 2D moment coefficient — airfoil-table data Ch. 16 does not
supply, no citable NACA 64A204 value found in this repo/session) — `Cm_cg_trim` returns NaN gracefully,
not an error, until that one field is filled in. The Brandt comparison surfaces a large, already-diagnosed,
non-bug `x_np`/`SM` gap (computed `SM≈+0.177` vs Brandt's `≈-0.002`/`+0.003`), root-caused to Brandt's own
ground truth using Roskam Eqns 3.17/3.19/3.24/3.38 rather than Raymer Ch. 16 for this exact quantity (see
"Major new lead" below) — not adjusted to force agreement, per this repo's informational-comparison rule.

Scribe documentation pass complete (2026-08-03) — see "Equations & Citations" below. Raymer
6th ed. Ch. 16 was a **citation GAP repo-wide**; Casey's physical-book read (2026-08-03) **CONFIRMED
Eqs. 16.4, 16.5/16.7, and 16.12** (3 of 3 spot-checked coefficients) — see "GAP summary" below. The
remaining three (**Eqs. 16.8, 16.9, 16.15**, flagged by Casey as large and needing more careful reading)
are now **CONFIRMED via a web cross-check** (2026-08-03, per Casey's explicit instruction to check
Raymer's book directly) — no full-book source could be searched, but two independent secondary sources
reproduce the exact `Cm_cg`/neutral-point buildup, resolve the long-open `/57.3` question (it belongs on
`Cm_αfus`'s own formula, not Eq. 16.9), and surfaced a candidate elevator-deflection formula for Δα_L0
(attributed to Eqs. 16.16/16.18) alongside a separate Ch. 12 general-flap candidate Casey independently
confirmed exists — **Casey decided (2026-08-03) to use the elevator-specific Eqs. 16.16/16.18 form**,
closing that scope question (see "GAP summary" below). **All nine of Casey's original items now have a
citable formula on record; nothing blocks `io` from starting.** A live-workbook read (coordinator
session, 2026-08-03) also found that **Brandt's own ground-truth workbook cites Roskam
Eqns 3.17/3.19/3.24/3.38, not Raymer Ch. 16**, for this exact `CLa`/neutral-point buildup — but a
follow-up check (same day) confirmed **that specific Roskam book is not in this repo either**: the three
`roskam_vol{1,2,3}_data.md` extracts are a different Roskam title (*Airplane Design*, Parts I/II/III),
not the *Flight Dynamics* book Brandt's sheet actually cites. **DECIDED (Casey, 2026-08-03): this lead
is dropped** — Casey does not have that book — see "Major new lead" below for the record. **Eqs. 16.13/
16.14/16.15 confirmed IN SCOPE (Casey, 2026-08-03)**, to be linked to the Aero toolbox rather than
re-derived — see the decision note under "Per-equation fidelity resolution" below. **Both
`VnV/BrandtF16A/todo.md` 2026-08-03 gap entries are now RESOLVED** (live-xls read confirmed both sheets'
existence and cell layout — see "Ground Truth" below). `io` has not started.
**Primary-source update (2026-08-04):** Casey supplied the actual Raymer 6th ed. PDF. A full read of Ch. 16
(book pp.585–619) **supersedes the 2026-08-03 web-cross-check** — see `VnV/BrandtF16A/todo.md`'s
2026-08-04 entry for full detail. Three corrections: (1) **Eq. 16.8 is `Cm_α` (the pitching-moment
derivative), not a "full itemized Cm_cg buildup"** — Row 3 below is relabeled accordingly. (2) **Eq. 16.9
DOES have a thrust term** (`F_pα(∂α_p/∂α)` in numerator and denominator) — the web source's "no thrust
term" claim was wrong — but Raymer's own text (p.593) explicitly sanctions dropping it for "power-off"
stability (with a documented 1–3%-of-SM allowance for jets), so this is still implementable without an
`x_p` input, now on a fully citable basis rather than a guess. (3) **Eq. 16.25's `Cm_α,fus` formula is
explicitly labeled "per deg" in the book** (p.603), CONFIRMING the `/57.3`-mystery Legacy Bugs entry with
full confidence (was "likely, web-sourced" — now primary-source-confirmed). Eq. 16.12's remaining 2
coefficients (the `0.4`/`1.1` breakpoints, the `2.5` exponent) are now also fully confirmed, not just the
3 Casey spot-checked. **New gap found and RESOLVED same day**: Eq. 16.25 needs `K_fus` off Fig. 16.14
(chart vs. root-quarter-chord position as % fuselage length) — no digitized/citable value existed
anywhere in this repo (legacy code read an undefined property). Casey read the chart directly at the
F-16's actual root-quarter-chord position (44.17% of fuselage length) and supplied **K_fus ≈ 0.025** —
now a citable scalar input, `examples/F16A/jsons/f16a_L3.json`'s new
`.stability_control.fuselage_moment.K_fus` key.

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

### Scribe kickoff (2026-08-03) — corrects a stale claim in the original spec

The paragraph below is preserved from the original spec for history; **its "still pending" claim about
the Nicolai extracts is now stale and incorrect.** Both extracts are complete and substantial:
`temp_AI/docs/disciplines/reference_extracts/Nicolat_Aircraft_Design_Vol_I/21_static_stability_and_control.md`
(Ch. 21, "Static Stability and Control," Eqs. 21.1–21.26, ~55 KB) and
`.../23_control_surface_sizing.md` (Ch. 23, "Control Surface Sizing Criteria," Eqs. 23.1–23.3 plus
Tables 23.1–23.3, ~25 KB) both carry an "extraction complete" marker and were read in full for this pass.

*Original paragraph, preserved:* "PLAN.md's tail-sizing L3 item was deferred specifically because 'no
verifiable Raymer Ch. 16 equation numbers exist anywhere in this repo's reference material today,' and
the Nicolai Ch. 21 ('Static Stability and Control')/Ch. 23 ('Control Surface Sizing Criteria') reference
extracts that could have substituted are both still listed 'pending' in
`temp_AI/docs/disciplines/reference_extracts/`. Casey has now supplied the Ch. 16 equation numbers
directly (table above), which removes most of that citation risk..."

**What this pass actually found:** supplying the equation *numbers* directly does not, by itself, close
the gap PLAN.md originally flagged, because this repo still has no Raymer Ch. 16 *text* to check those
numbers' formulas/coefficients against. Grepping the whole repo for any Raymer-Ch.16 citation
(`Raymer.*16\.\d` / `16\.\d.*Raymer`) turns up exactly three hits, all in
`temp_Casey/src/Disciplines/StabAndCont/SandCLevel3.m` (read-only reference; lines 195, 457, 510):
`"Raymer, 6th ed, fig 16.3"`, `"Raymer 6th ed, eq 16.25"`, `"Raymer 6th ed fig 16.16"` — **none of which
are among the nine items in Casey's table above.** `temp_AI/docs/disciplines/reference_extracts/
raymer_data.md` (re-read this pass, confirmed) covers only Ch. 10 (propulsion sizing), Ch. 12
(aerodynamics), and Ch. 15 (weights) — it jumps from §12.6 straight to Ch. 15, no Ch. 16 content at all.
So: Casey's nine equation *numbers* are trustworthy as numbers (supplied directly, presumably from the
physical book), but none of their *formulas or coefficients* can be independently verified against
Raymer's own text from anything in this repo. The Nicolai Ch. 21/23 extracts substitute as an
independent, different-book cross-check of each equation's underlying physics/formula-form (not Raymer's
specific numbering or coefficients) — see "Equations & Citations" below for the per-item result. This is
the same pattern the Subsystems scribe pass hit for Raymer Table 11.6/Table 11.1: **several items below
need Casey to read the physical Raymer 6th ed. Ch. 16 directly** before they can move past
UNVERIFIED/GAP.

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

### Per-equation fidelity resolution (scribe, 2026-08-03)

| Eq. | Quantity | Tier | Why |
|---|---|---|---|
| 16.4 | Moment about CG (dimensional) | L2/L3 | needs `x_cg`/`x_acw`/`x_ach`/`x_p` — geometry x-stations |
| 16.5/16.7 | Cm about CG (coefficient) | L2/L3 | same |
| 16.8 | Cm_cg buildup | L2/L3 | same |
| 16.9 | Neutral point | L2/L3 | output is itself an x-station; needs `x_acw`/`x_ach` |
| 16.11 | Static margin | L2/L3 | needs `x_np`, `x_cg`, `c̄` (MAC) |
| 16.12 | x_ac (longitudinal) | L2/L3 | needs `S_wing`, `x_c/4` |
| 16.13 | Wing lift coefficient | L2/L3* | formula itself is geometry-free (only needs a scalar `CL_α`, `i_w`, `α_0L`) |
| 16.14 | Aft-tail lift coefficient | L2/L3* | same caveat as 16.13 |
| 16.15 | Δα_L0 | L2/L3* | geometry-free in its base form; geometry-dependent only if the (uncited) flap sub-formula is used |

*Starred rows: the tiering rule stated above ("equations that depend on geometry belong in L2/L3;
equations that don't ... belong in L1") does not, on the equations' own content, put 16.13/16.14/16.15 in
L2/L3 — it is the **DI plan** (an Aero object is only injected from `F16AeroL2` onward for S&C; no
`F16AeroL1` injection is planned) that forces the tier, not geometry-dependence in the equation itself.

### DECIDED (Casey, 2026-08-03): F16SandCL2 is limited to the CG (x_cg) term only

The `io` pass (2026-08-03) found that **`F16GeomL2` exposes NO x-station properties at all** — no
`x_apex_wing`/`x_le_ht`/`x_le_vt`/`x_inlet`/tail-arm equivalent exists anywhere in `examples/F16A/
F16GeomL2.m` (confirmed by direct grep; only `F16GeomL3` has these). This means every row in the table
above except the bare `x_cg` weighted-average term genuinely cannot run at L2 today, regardless of how
the table above tiers them — Eqs. 16.4/16.5/16.7/16.8/16.9/16.11/16.12 all need `x_acw`/`x_ach`/`x_c/4`-
type geometry x-stations that simply do not exist on the injected L2 geometry object.

**Decision: `F16SandCL2` computes ONLY the CG buildup** — the weighted-average `x_cg = Σ(W_i·x_i)/ΣW_i`
over the component-weight/x-location table (see "Component-x-location buildup" below), which needs no
geometry x-stations at all, just the table itself plus `F16WeightsL2`'s weight values. **Every other
row above (16.4's full moment, 16.5/16.7, 16.8, 16.9, 16.11's `x_np`, 16.12's `x_ac`, and 16.13/16.14/
16.15's lift-coefficient terms) is L3-ONLY, not "L2/L3"** — the table above and this subplan's other
per-row entries should be read with that correction in mind; `F16SandCL2` is a genuinely thinner class
than `F16SandCL3`, not just a lower-fidelity version of the same contract. This was chosen over the two
alternatives considered (inject `F16GeomL3` into `F16SandCL2`, or add new x-station inputs to
`F16GeomL2` as a separate task) — both rejected as unnecessary scope for now.
Flagged so a future L1-collapse (per the "Fidelity-collapse contingency" above) does not mistakenly treat
these three as geometry-bound in the same sense as 16.4–16.12.

### Eqs. 16.13/16.14/16.15 stay in scope — decision (Casey, 2026-08-03): link them to the Aero toolbox

Casey confirmed these three equations stay in scope (the scope-fit flag above is answered: yes, keep
them), but asked that they "link" with the Aero toolbox rather than S&C computing its own lift-curve-
slope numbers from scratch. Checked what Aero already exposes:

- **Wing `CL_α`** already exists: `F16AeroL2.get_CL_alpha(obj, M)` / `F16AeroL3.get_CL_alpha(obj, M)`,
  built on the low-level static `AeroL2.CL_alpha(AR, Lambda_c4_deg, M, S_exposed, S_ref, F, Cl_alpha_2D)`
  [Raymer Eq. 12.6/12.8]. S&C's Eq. 16.13 (`CL_w`) should call the injected `F16AeroL2/L3` object's
  `get_CL_alpha` directly for `CL_α`, not re-derive it.
- **Tail `CL_αh`** does NOT exist anywhere in Aero today — no object-level wrapper computes a
  horizontal-tail lift-curve slope (Aero has no tail-specific `CL_alpha` property; `alpha_L0` is a
  wing-only input too). Rather than adding a new tail-specific method to Aero (out of scope for this
  subplan, and Aero's own "no feature beyond what's needed" rule), S&C should call **the same low-level
  static**, `AeroL2.CL_alpha(...)`, a second time — with the horizontal tail's own `AR`/`Lambda_c4_deg`/
  `S_exposed`/`Cl_alpha_2D` (from the injected `F16GeomL2/L3` object's HT properties) substituted for the
  wing's. This is the identical cross-toolbox-static-reuse pattern already used elsewhere in this repo
  (e.g. `GeomL3.size_tail` → `GeomL1.size_tail`; `SubsystemsL3.fuel_volume_from_weight` →
  `SubsystemsL2.fuel_volume_from_weight`) — `AeroL2.CL_alpha` is already a level-agnostic static that
  takes plain scalar geometry arguments, with no wing-specific assumption baked into its signature, so
  it works unmodified for any lifting surface.
- **Net effect on the "Files planned" table**: no new file/method needed on the Aero side. S&C's own
  `SandCL2`/`SandCL3` toolbox implements Eqs. 16.13/16.14/16.15 as statics that take `CL_α`/`CL_αh` as
  **arguments** (supplied by the concrete `F16SandCL2/L3` class, which reads them from its injected
  `F16AeroL2/L3` object and calls `AeroL2.CL_alpha` a second time for the tail) — S&C never recomputes a
  lift-curve slope with its own formula. This still leaves Eq. 16.15's flap-deflection sub-formula
  (`ΔCL_δf`) as an open GAP (see GAP summary below) — that piece has no home in Aero either, since no
  flap/control-surface deflection model exists there yet.

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
discipline needs is a **new, S&C-owned input table**, supplied alongside S&C's own JSON
(`examples/F16A/jsons/f16a_L{2,3}.json` `.stability_control.component_x_stations`). This is explicitly
**not** a retrofit of `WeightsL3`'s contract; `WeightsL3` continues to expose only weight values, and
S&C is the only consumer of the x-location mapping.

**FINALIZED (Casey, 2026-08-03), after two follow-up rounds:**

1. **Grouped by this framework's own weight groups, not the legacy sheet's 22 components.** An `io` pass
   first sourced this table directly from `temp_Casey/inputs/F-16A Block 50.xlsx`'s `Stability&Control`
   sheet (22 fine-grained rows). Casey rejected that in favor of building the table from `WeightsL2`'s/
   `WeightsL3`'s own weight groups instead — 10 groups: `wing`, `horizontal_tail`, `vertical_tail`,
   `fuselage`, `landing_gear`, `installed_engine`, `subsystems_lump` (everything Eqs. 15.16–15.24 lump
   together — flight controls, instruments, hydraulics, electrical, avionics, furnishings, air
   conditioning, handling gear), `strake`, `payload` (fixed + expendable), `fuel`. Weights are read live
   by DI from `F16WeightsL2`/`F16WeightsL3` — never duplicated into this table.
2. **Two station fields per group, tracked separately, per Casey's explicit instruction ("track the
   frontmost part edge and the center of gravity for each component, just for redundancy")**:
   `front_edge_x_ft` — a real, geometry-citable leading-edge/apex station, populated for 4 of the 10
   groups at L3 (`wing`←`x_apex_wing`, `horizontal_tail`←`x_le_ht`, `vertical_tail`←`x_le_vt`,
   `installed_engine`←`x_inlet`), and `N/A` for the rest (no such Geometry property exists) — entirely
   `N/A` at L2, since `F16GeomL2` has no x-station properties at all. `cg_x_ft` — an **engineering
   estimate** of the weight-centroid station for each group (a component's mass does not sit at its
   front edge, so `front_edge_x_ft` cannot be substituted for it without a further, equally-uncited
   offset assumption). `cg_x_ft` is computed by re-aggregating the legacy sheet's 22 real, live-read rows
   into these 10 coarser groups (weighted average per group) — using the legacy DATA as an estimate
   anchor, not as the table's structural source. Sanity check: the 10 groups' weights sum to 31,368 lbf,
   within 9 lbf (0.03%) of Brandt's own `W_TO`=31,377 lbf. `cg_x_ft` is identical at L2 and L3 (the
   legacy-data re-aggregation is fidelity-independent); only `front_edge_x_ft` differs between the two
   files. Full per-group arithmetic is recorded in each JSON group's `_cg_source` field.
3. **`F16SandCL2` uses only `cg_x_ft`** (per the "F16SandCL2 is limited to the CG term only" decision
   above) — `front_edge_x_ft` exists purely as the redundant cross-check field Casey asked for, and is
   not read by any Eq. 16.x formula in this subplan.

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
| `Xbar_p = 33.775` (thrust x-location) hardcoded "temporarily" | **RESOLVED (2026-08-04, Casey's closure request).** `x_p = F16GeomL3.x_inlet` (=15.0 ft) by DI reuse — justified because Raymer 6th ed. Eqs. 16.26–16.28 (p.604) define `F_p` as specifically the inlet-front-face normal force, so `x_inlet` IS the cited application point, not a guess (the literal `33.775` is never ported). `z_t`/`F_p` themselves are set to 0 as explicit, cited simplifications: Raymer p.604 ("If the thrust axis passes through or near the c.g., this term can be ignored") and p.609 ("it is common in early conceptual design to calculate the trim condition without including the thrust effects unless the thrust axis is well above or below the c.g."). See `examples/F16A/F16SandCL3.m`'s `Cm_cg_trim` header. |
| `eta_h` computed from `q_h/q` then immediately overwritten to a hardcoded `0.9` | **UPDATE (2026-08-04, primary source, p.591):** `η_h=0.90` is not an arbitrary legacy hack — Raymer's own text calls it out as "the typical value" ("[η_h] ranges from about 0.85–0.95... with 0.90 as the typical value"), for use when no better `q_h/q` data exists. The bug is not the *value*, it's *silently discarding a computed value in favor of the constant without saying so*. Fix: implement `η_h` as a required toolbox-static argument; `F16SandCL3` may pass `0.90` as its actual argument, cited to Raymer p.591's "typical value," as long as it's an explicit, commented default — not a silent override of something else computed and thrown away. |
| Ambiguous "FIGURE OUT WHAT C IS" comment re: mean-chord usage | Pin the exact chord definition (MAC vs. some other reference length) per equation before implementing, not after |
| **(found 2026-08-03, scribe pass)** `compute_SM` divides the correct ratio by an extra, uncited `100`: `output = ((Xbar_np - Xbar_cg)/c_bar)/100` — if SM is meant to be a fraction (as `readme_bsc.md`'s `SM=(x_np-x_cg)/MAC_W` and Nicolai Eq. 22.1 both give it), this silently shrinks the result 100×. Not in the subplan's original bug list; adding here since it directly touches Eq. 16.11. | Implement Eq. 16.11 as the bare ratio `(x_np - x_cg)/c̄`, no extra scaling; if a %-form is wanted for display, convert at the call site, not inside the toolbox static. |
| **CONFIRMED, primary source (2026-08-04)** — `SandCLevel3.compute_cm_alpha_fuselage` (`K_fus·W_f²·L_f/(c·S_w)`, code comment "% per deg", cites "Raymer 6th ed, eq 16.25" directly) computes the formula correctly AS A PER-DEG QUANTITY, matching Raymer Eq. 16.25 (p.603) exactly, which is explicitly labeled "per deg" in the book. The bug is real and now fully confirmed (was "likely, web-sourced" 2026-08-03): every downstream consumer (Eqs. 16.8/16.9, per-radian throughout) must multiply this term by `180/π` (≈57.3) before use — the legacy code never does this anywhere. | Implement `Cm_α,fus` per Eq. 16.25 exactly (per-deg units), then explicitly multiply by `180/π` at the one call site inside Eq. 16.8/16.9's toolbox static, commented as the unit conversion it is; implement Eq. 16.9 itself with NO `/57.3`/`/100`-style factor anywhere else. **New gap**: `K_fus` (Fig. 16.14 chart) has no digitized value anywhere in this repo — see `VnV/BrandtF16A/todo.md`'s 2026-08-04 entry. |

---

## Equations & Citations

Per-equation detail, mirroring the Subsystems scribe pass's format (`docs/subplans/09_subsystems.md`).
"CONFIRMED" = cross-checked against an in-repo extract (here: Nicolai & Carichner Ch. 21/23, since no
Raymer Ch. 16 text exists in-repo — see "Scribe kickoff" above) or the live Brandt workbook; where the
match is to a *different book's* independently-derived equation (same physics/formula-form, not Raymer's
own text), this is noted explicitly rather than overclaiming exact-citation confidence. "UNVERIFIED" =
the only source is a single uncross-checked legacy-code comment, with no corroboration anywhere else
in-repo. "GAP" = no in-repo source at all — needs Casey's physical Raymer 6th ed. read.

**Formulas below are transcribed from `temp_Casey/src/Disciplines/StabAndCont/SandCLevel3.m`
(read-only reference — cross-checked for citation purposes only, per CLAUDE.md; not to be copied
verbatim into the new implementation) unless noted otherwise.** Casey's equation *numbers* (16.4, 16.5/
16.7, etc.) are taken as given per the task brief; this pass could not itself confirm those numbers point
to these formulas in the physical book, only that the formulas are internally consistent with each other
and, where noted, with Nicolai's independently-derived equivalents.

**Web cross-check (2026-08-03, per Casey's instruction to "check through Raymer's book, yourself," for
the three items — 16.8, 16.9, 16.15 — flagged as needing a manual physical-book transcription).** No
Raymer Ch. 16 PDF or text exists anywhere in this repo (confirmed earlier this pass), and no full-book
PDF could be searched directly (the one public copy found is far too large for this session's fetch
tool). Two independent secondary web sources — a course-style aircraft-design reference site
(`computationaldesignlab.github.io/aircraft-design/long_stability/`) and a separate web search summary —
both reproduce the SAME `Cm_cg` buildup structure (matching this table's Row 2/3 formulas and the legacy
code's own transcription, a three-way agreement), plus give the full Eq. 16.9 neutral-point formula and
a candidate Eq. 16.16/16.18 elevator-deflection formula. **This is web-sourced, secondary-source
corroboration, NOT a primary physical-book read** — same honesty standard as this repo's existing
web-sourced `alpha_L0_deg` precedent (`f16a_L2.json`'s `_cite_alpha_L0_deg` note): cross-checked across
2 independent sources, but flagged wherever an exact Raymer equation NUMBER could not be pinned down
with confidence (16.7-vs-16.8, 16.15-vs-16.16/18), and Casey should still spot-check these against the
physical book when convenient, particularly the `/57.3` finding (Row 4) since it corrects a load-bearing
legacy-code discrepancy.

### §1 — Moment / Cm-about-CG family (Eqs. 16.4, 16.5/16.7, 16.8)

| # | Quantity | Formula | Citation | Status | Tier | DI collaborator(s) |
|---|---|---|---|---|---|---|
| 1 | Moment about CG (dimensional) | `M_cg = L(x_cg−x_acw) + M_w + M_w,δf·δf + M_fus − L_h(x_ach−x_cg) − T·z_t + F_p(x_cg−x_p)` | `[Raymer 6th ed. Eq. 16.4]` (Casey-supplied number); formula per `SandCLevel3.compute_MCG` | **CONFIRMED (2026-08-03, Casey's physical-book read)** — `M_w,δf·δf` and `M_fus` are both real Eq. 16.4 terms in the book, not `SandCLevel3`-only additions. Also matches the dimensionalized form of Nicolai & Carichner's aft-tail trim diagram, Fig. 21.4b / Eq. (21.1), p.582–583. Formula in this row now fully confirmed. | L2/L3 | `F16GeomL2/L3` (`x_cg`, `x_acw`, `x_ach`, `x_p` — the last from Prop, see below); `F16WeightsL2/L3` + new S&C x-location table (component weights → `x_cg`); `F16AeroL2/L3` (`L`, `M_w`); `F16PropL2` (`T`, `F_p`, `x_p` — legacy hardcodes `x_p=33.775`, a bug to avoid per Legacy Bugs table) |
| 2 | Cm about CG (coefficient form) | `Cm_cg = CL(x_cg−x_acw)/c̄ + Cm_acw + Cm_w,δf·δf − (q_h S_h)/(q S_w)·CL_h·(x_ach−x_cg)/c̄ − T_zt/(q S_w c̄) + F_p(x_cg−x_p)/(q S_w c̄)` | `[Raymer 6th ed. Eq. 16.5 (dimensional) / 16.7 (arm lengths as fractions of c̄)]`; formula per `SandCLevel3.compute_Cm_cg` | **CONFIRMED (2026-08-03, Casey's physical-book read)** — 16.5 and 16.7 are the SAME relation: 16.5 is dimensional (arm lengths in ft), 16.7 is the same equation with arm lengths expressed as fractions of the wing mean chord `c̄`. Not a general-vs.-aft-tail-specialized split, as this pass had guessed. Also algebraically equivalent to Nicolai Eq. (21.1) for the aft-tail case (see prior draft's cross-check). **`Cm_acw` CLOSED (2026-08-04, Casey's follow-up instruction — "search Raymer's text for an equation for it; if you cannot find it, the users/students must be able to supply their own value"):** `[Raymer 6th ed. Eq. 16.19, p.598]` gives `Cm_acw = Cm0_airfoil·(AR·cos²Λ)/(AR+2cosΛ)`, "for a straight wing or an untwisted swept wing at low subsonic speeds" — a real, citable equation (`SandCL3.Cm_acw_wing`). It bottoms out at `Cm0_airfoil`, the wing section's own 2D zero-lift moment coefficient, which Ch. 16 does not supply and which has no citable NACA 64A204 value anywhere in this repo/session — per Casey's own instruction, this one input (`Cm0_airfoil_wing`) is USER/STUDENT-SUPPLIED (defaults to NaN; `Cm_cg_trim` returns NaN gracefully, not an error, until filled in). | L2/L3 | same as Row 1 |
| 3 | `Cm_α` (pitching-moment derivative w.r.t. α) — **RELABELED 2026-08-04, was mis-attributed as "Cm_cg buildup (full itemized)"** | `Cm_α = CL_α(X̄cg−X̄acw) + Cm_α,fus − η_h(S_h/S_w)CL_αh(∂α_h/∂α)(X̄ach−X̄cg) + (F_pα/(qS_w))(∂α_p/∂α)(X̄cg−X̄p)` | `[Raymer 6th ed. Eq. 16.8]`, verbatim, primary-source read 2026-08-04 (p.592) | **CONFIRMED, primary source (2026-08-04) — see `VnV/BrandtF16A/todo.md`'s 2026-08-04 entry, "Correction 1."** This is a genuinely distinct quantity from Row 2 (the derivative of Cm_cg w.r.t. α, feeding directly into Eqs. 16.9/16.10/16.11), NOT an itemized variant of Row 2's Cm_cg — the 2026-08-03 web cross-check's guess was wrong about which equation number this is (the underlying `Cm_fus` term IS real, it's just already inside Row 2's Eq. 16.7, not a separate Eq. 16.8 term). `Cm_α,fus = K_fus·W_f²·L_f/(c·S_w)` **per Raymer Eq. 16.25 (p.603), explicitly labeled "per deg" in the book** — confirms the missing `×180/π` conversion factor with full confidence (was "likely, web-sourced" — see Legacy Bugs row below). `K_fus` comes from Fig. 16.14 (chart, NACA TR 711) — **no digitized value exists anywhere in this repo**, new gap, see todo.md entry. The `F_pα(∂α_p/∂α)` thrust term is present in the primary source (contra the 2026-08-03 web source's "no thrust term" claim, which actually applies to Eq. 16.9 with Raymer's own "power-off" sanction — see Row 4) — implementable via Eqs. 16.26–16.31 (F_p, F_pα momentum-based formulas), but still needs `x_p` (thrust x-location, GAP) for the `(X̄cg−X̄p)` factor. | L2/L3 | same as Row 1, plus: `K_fus` chart-digitization gap (new); `x_p` GAP (shared with Row 1) |

### §2 — Neutral point & static margin (Eqs. 16.9, 16.11)

| # | Quantity | Formula | Citation | Status | Tier | DI collaborator(s) |
|---|---|---|---|---|---|---|
| 4 | Neutral point | `X̄np = [CL_α·X̄acw − Cm_α,fus + η_h(S_h/S_w)CL_αh(∂α_h/∂α)X̄ach + (F_pα/(qS_w))(∂α_p/∂α)X̄p] / [CL_α + η_h(S_h/S_w)CL_αh(∂α_h/∂α) + (F_pα/(qS_w))(∂α_p/∂α)]` | `[Raymer 6th ed. Eq. 16.9]`, verbatim, primary-source read 2026-08-04 (p.592) | **CONFIRMED, primary source (2026-08-04) — see `VnV/BrandtF16A/todo.md`'s 2026-08-04 entry, "Correction 2."** The 2026-08-03 web source's "no thrust term" claim was WRONG — the primary source DOES include the `F_pα(∂α_p/∂α)` term in both numerator and denominator. However, Raymer's own text immediately after Eq. 16.9 (p.593) states: *"It is common to neglect the inlet or propeller force term `F_p` in Eq. (16.9) to determine 'power-off' stability... Typically, these allowances for power-on will reduce the static margin by about 1–3% for jets."* This is a Raymer-sanctioned, citable simplification for implementing Eq. 16.9 without an `x_p` input — matches Casey's independently-recalled "2% reduction" note almost exactly, which appears to be this exact passage. `Cm_α,fus` needs `K_fus` off Fig. 16.14 — new gap, see Row 3/todo.md. Also confirmed exists (not in Casey's original 9-item list, essentially free once this row is implemented): `[Eq. 16.10]` `Cm_α = −(CL_α + η_h(S_h/S_w)CL_αh(∂α_h/∂α))(X̄np−X̄cg)`. | L2/L3 | `F16GeomL2/L3` (`x_acw`, `x_ach`); `F16AeroL2/L3` (`CL_α`, `CL_αh`, `η_h` — legacy hardcodes `η_h=0.9`, a bug to avoid); thrust term dropped per the "power-off" citation above, not wired to Prop |
| 5 | Static margin | `SM = (x_np − x_cg)/c̄` | `[Raymer 6th ed. Eq. 16.11]`; formula per `readme_bsc.md` / `BrandtBalanceStabControl.m` (`SM_TO`/`SM_land`) and (modulo the `/100` bug, see Legacy Bugs table above) `SandCLevel3.compute_SM` | **CONFIRMED** — identical form independently given in Nicolai & Carichner as Eq. (22.1) (repeated in the Ch. 23 extract, p.616: *"SM = (x_n.p. − x_c.g.)/c̄"*), and matches `readme_bsc.md`'s own Brandt-ground-truth formula and live code exactly. This is the strongest cross-check in this whole set — two independent books, same relation, same repo-internal ground-truth code all agree. Only the specific Raymer eq. **number** `16.11` itself is unverifiable (Nicolai numbers it 22.1). | L2/L3 | `F16GeomL2/L3` (`c̄`); whatever supplies `x_np`/`x_cg` (Rows 1–4 chain) |

### §3 — Aerodynamic center, longitudinal location (Eq. 16.12)

| # | Quantity | Formula | Citation | Status | Tier | DI collaborator(s) |
|---|---|---|---|---|---|---|
| 6 | x_ac (longitudinal) | `x_ac = x_c/4 + Δx_ac·√S_wing`, with `Δx_ac(M)`: `0` for `M<0.4`; `0.26(M−0.4)^2.5` for `0.4≤M≤1.1`; `0.112−0.004M` for `M>1.1` | `[Raymer 6th ed. Eq. 16.12]`; formula per `SandCLevel3.get_delta_x_ac`/`compute_delta_x_ac_subsonic`/`compute_delta_x_ac_supersonic` | **CONFIRMED, all 5 of 5 coefficients (2026-08-04, primary-source PDF read, p.594)** — upgraded from the 2026-08-03 partial (3 of 5, Casey's physical-book spot-check). The primary-source text confirms `0.26`, `0.112`, `0.004`, AND the `0.4`/`1.1` Mach breakpoints and the `2.5` exponent, verbatim, no discrepancy from the legacy transcription. Nicolai's Fig. 21.3 also corroborates the general phenomenon (a.c. moves aft with Mach). | L2/L3 | `F16GeomL2/L3` (`S_wing`, `x_c/4`); flight-condition object (`M`) |

### §4 — Lift coefficients & Δα_L0 (Eqs. 16.13, 16.14, 16.15)

| # | Quantity | Formula | Citation | Status | Tier | DI collaborator(s) |
|---|---|---|---|---|---|---|
| 7 | Wing lift coefficient | `CL_w = CL_α(α + i_w − α_0L)` | `[Raymer 6th ed. Eq. 16.13]`; formula per `SandCLevel3.compute_CL_wing` | **CONFIRMED (standard relation)** — the universal linear lift-curve-slope identity, implicit throughout Nicolai (e.g. the aft-tail `C_LT` formula below is the same relation applied to a tail surface). Raymer's specific eq. **number** is unverifiable in-repo. **CLOSED (2026-08-04):** `i_w=0°` — **T.O. 1F-16A-1** (USAF Flight Manual), "WINGS" data block: "Incidence ... 0°" — a real, primary-source, aircraft-specific value (the legacy code only ever had an uncited `i_w=0, "Assume 0 for now"`). `α_0L=-1.33°` was already cited (`F16AeroL3.alpha_L0`, NACA 64A204). No longer GAP-blocked. | L2/L3* (see fidelity-resolution note above — formula itself is geometry-free) | `F16AeroL2/L3` (`CL_α`, `α_0L`); T.O. 1F-16A-1 (`i_w`) |
| 8 | Aft-tail lift coefficient | `CL_h = CL_αh(α + i_h − ε − α_0Lh)` | `[Raymer 6th ed. Eq. 16.14]`; formula per `SandCLevel3.compute_CL_tail` | **CONFIRMED (form)** — matches Nicolai's stationary-stabilizer/movable-elevator tail-lift formula (p.584, unnumbered): `C_LT = m_T[(1−dε/dα)α − α_0LT]`, algebraically equivalent once `ε` is read as the actual downwash angle at that condition rather than `(dε/dα)·α`. **Scope note:** this equation carries an explicit downwash term `ε` — per this subplan's own rule ("wherever a full Raymer equation includes a downwash term, the implementation notes the simplification explicitly rather than silently dropping it"), any simplification of `ε` here (e.g. `ε=0`, since downwash is out of scope) must be commented, not silently defaulted — this is exactly the `eta_h`-hardcoded-to-`0.9` legacy bug pattern to avoid. **CLOSED, reframed (2026-08-04):** `i_h` is NOT a spec constant — the F-16 tail is an all-moving stabilator (`c_elev_frac=0`), so `i_h` IS the trim control variable. `F16SandCL3.CL_h(obj, alpha_deg, i_h_deg)` now takes it as a required caller argument, same standing as `alpha_deg`. `α_0Lh=0°` — T.O. 1F-16A-1's HT airfoil is symmetric biconvex (6% root/3.5% tip), and a symmetric section's zero-lift AoA is 0° by definition, not an assumption. No longer GAP-blocked. | L2/L3* (same caveat as Row 7) | `F16AeroL2/L3` (`CL_αh`); T.O. 1F-16A-1 (tail airfoil symmetry → `α_0Lh=0`); caller (`i_h`, trim condition) |
| 9 | Δα_L0 (change in zero-lift AoA) | Base: `Δα_L0 = −ΔCL/CL_α`. **DECIDED (Casey, 2026-08-03): use the elevator-specific sub-formula** — `α_hL0 = -[1.576(c_e/c)³ − 3.458(c_e/c)² + 2.882(c_e/c)]·δ_e` | `[Raymer 6th ed. Eq. 16.15]` for the base relation; elevator sub-formula per `[Raymer Eqs. 16.16/16.18]` (web-sourced, see "Web cross-check" note below) | **CONFIRMED scope, web-sourced formula (cross-checked 2026-08-03).** Casey chose the elevator-deflection form (Eqs. 16.16/16.18) over the Ch. 12 general flap form Casey separately confirmed exists near Figs. 12.18/12.19 — the Ch. 12 equation is therefore OUT of this discipline's scope, not needed. Formula itself is still web-sourced, not yet checked against the physical book — worth a page-glance next time Casey has it open, same as the Eq. 16.9 `/57.3` fix. | L2/L3 (needs `c_e/c`, the elevator chord ratio) | `F16AeroL2/L3` (`CL_α`, `ΔCL` if the base relation is also needed); `F16GeomL2/L3` (`c_e/c`, elevator chord ratio) |

#### Δα_L0 (Eq. 16.15) Ch. 12 dependency — resolved: elevator-specific form chosen (Casey, 2026-08-03)

The subplan's original table flags this as needing scribe resolution: *"16.15, and possibly a second
Ch. 12 equation near the ΔCL_max tabulations."* Checked `temp_AI/docs/disciplines/reference_extracts/
raymer_data.md` (the only in-repo Raymer extract) directly: its §12.4 "Lift" section runs Eqs. 12.6–12.17
(lift-curve slope, `CL_max`, `α_CLmax`), and separately lists, **without any equation number**: *"Table
12.1"* (leading-edge sharpness parameter `Δy` — unrelated to `Δα_L0`) and *"Flap types (Fig 12.18) & LE
devices (Fig 12.19) discussed for `ΔCL_max_TO/L`"* — **figures only, no formula transcribed, no equation
number given.** So: no equation number exists anywhere in this repo's Raymer extract in the vicinity of
the `ΔCL_max` tabulations.

**Update (web cross-check, 2026-08-03):** a web-sourced secondary reference gives a specific,
numerically-detailed elevator-deflection formula, attributed to **Eqs. 16.16/16.18** (Ch. 16, not
Ch. 12): `α_hL0 = -[1.576(c_e/c)³ − 3.458(c_e/c)² + 2.882(c_e/c)]·δ_e`. Casey separately confirmed
(2026-08-03, physical-book read) that a related equation genuinely exists near Figs. 12.18/12.19 in
Ch. 12 too — so there were **two distinct candidate sub-formulas**: a Ch. 12 form (general
flap/high-lift-device `ΔCL`) and this Ch. 16 form (specific to elevator trim deflection).

**DECIDED (Casey, 2026-08-03): use the elevator-specific form (Eqs. 16.16/16.18).** This discipline
computes *trim* behavior (elevator deflection for level-flight equilibrium), which is exactly what the
Ch. 16 elevator form models — the Ch. 12 general flap `ΔCL_max` relation (meant for high-lift/takeoff-
landing analysis) is confirmed OUT of scope for this subplan. The Ch. 16 formula above is still
web-sourced, not yet checked against the physical book — worth a page-glance next time Casey has it
open, alongside the Eq. 16.9 `/57.3` fix (Row 4).

**Separate scope-fit flag, not a citation gap — RESOLVED (Casey, 2026-08-03).** Eqs. 16.13/16.14/16.15
compute *absolute* lift coefficients and a trim-related zero-lift-angle correction — these look like
inputs to a **trim solve** (finding the elevator deflection / angle of attack at which `Cm_cg=0` for
level-flight equilibrium), not to the **stability derivative** quantities (`Cm_α`, neutral point, static
margin) that Rows 1–6 compute. Casey confirmed all three stay IN SCOPE regardless — see the "Eqs.
16.13/16.14/16.15 stay in scope" decision note under "Per-equation fidelity resolution" above for the
full rationale and the DI/reuse plan (link to the Aero toolbox rather than re-derive).

### GAP summary — Casey's physical-book read (2026-08-03)

| Item | What was needed | Casey's answer |
|---|---|---|
| Eq. 16.4 | Exact term list (confirm `M_w,δf·δf` and `M_fus` are real Eq. 16.4 terms, not `SandCLevel3`-only additions) | **CONFIRMED, both real.** `M_w,δf·δf` (wing flap-deflection moment term) and `M_fus` (fuselage moment term) are both genuine Eq. 16.4 terms in the book, not additions by the legacy code. Row 1's formula stands as-is. |
| Eq. 16.5 vs. 16.7 | Why two numbers for one relation? | **RESOLVED — same equation, two forms.** Eq. 16.5 is the dimensional form (arm lengths in ft); Eq. 16.7 is the same relation with arm lengths expressed as fractions of the wing mean chord `c̄` (i.e. divided through by `c̄`) — not a general-vs.-aft-tail-specialized split as this pass had guessed. Update Row 2's citation to read "16.5 (dimensional) / 16.7 (same, arm lengths as fractions of `c̄`)." |
| Eq. 16.8 | The `Cm_fus` sub-term's own source formula | **CONFIRMED (web-sourced, cross-checked, 2026-08-03)** — see Row 3 and the "Web cross-check" note above. A quick page-check of the exact 16.7-vs-16.8 numbering is still worthwhile but no longer blocking. |
| Eq. 16.9 | Full formula; confirm the `/57.3` question | **CONFIRMED (web-sourced, cross-checked, 2026-08-03)** — see Row 4. The `/57.3` question is resolved: it does NOT belong in Eq. 16.9; it likely belongs on `Cm_αfus`'s own formula instead (new Legacy Bugs row above). A page-check is still recommended (load-bearing correction) but no longer blocking. |
| Eq. 16.12 | The `Δx_ac(M)` piecewise coefficients | **CONFIRMED, 3 of 3 spot-checked.** Casey confirmed `0.26`, `0.112`, and `0.004` are the coefficients printed in the "where" section directly below Eq. 16.12 in the book. (The `0.4`/`1.1` Mach breakpoints and the `2.5` exponent were already in the legacy transcription and were not separately contradicted — treat those three as still only UNVERIFIED, not yet independently reconfirmed, pending a follow-up spot-check.) |
| Eq. 16.15 | Full formula; Ch. 12 companion equation | **RESOLVED (web-sourced formula, cross-checked; scope decided by Casey, 2026-08-03)** — see Row 9. A candidate formula was found, attributed to Eqs. 16.16/16.18, not 16.15; Casey independently confirmed a SEPARATE Ch. 12 equation also exists, and **decided to use the elevator-specific Eqs. 16.16/16.18 form**, not the Ch. 12 general-flap form — the Ch. 12 equation is out of scope. |

**Nothing left blocks `io` from starting.** All nine of Casey's original items now have at least a
web-cross-checked or physical-book-confirmed formula on record (per Casey's 2026-08-03 instruction to
check Raymer's book directly for the three still-open items). Two follow-ups are still worth a quick
page-glance from Casey when convenient — the Eq. 16.9 `/57.3` correction, and the chosen Eq. 16.16/16.18
elevator formula's exact coefficients — but neither blocks starting `io`/implementation on the rest.

Eqs. 16.11 and 16.13/16.14 do **not** need a physical-book read to proceed with reasonable confidence —
each has an independent, in-repo cross-check (Nicolai Eq. 22.1 / p.584 relation, respectively) that
corroborates the formula's *form*, even though the exact Raymer numbering stays unverified.

### Major new lead (live-workbook read, 2026-08-03): Brandt's OWN ground-truth workbook cites Roskam, not Raymer, for this exact buildup

Opened both candidate workbooks directly via MATLAB `readcell` (read-only; neither file was modified) —
see "Ground Truth" below for the full cell-layout writeup. **`VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls`
has a sheet named `S&C (2)`**, exactly the sheet this subplan speculated about. Its longitudinal-static-
stability rows (`CLa`, `xbarnp`/`xnp`, `SM`) cite **Roskam Eqn 3.24** (`CLa`), **Roskam Eqn 3.38**
(neutral point), and give `a`/`a0L`/`aHS` via **Roskam Eqn 3.17/3.19** — i.e. Brandt's own ground-truth
values for this exact deliverable were built from **Roskam**, not Raymer Ch. 16. This is a second,
already-in-repo-extractable citation path (`temp_AI/docs/disciplines/reference_extracts/
roskam_vol1_data.md`/`roskam_vol2_data.md`/`roskam_vol3_data.md` all exist) that a future scribe/io pass
should check for Eqns 3.17/3.19/3.24/3.38 BEFORE assuming Eq. 16.9's Casey-pending transcription is the
only path to a citable neutral-point formula — it may turn out Roskam's Eq. 3.38 is the cleaner,
already-partially-in-repo citation for this framework's neutral point, with Raymer 16.9 kept only as a
cross-check. Not decided here — flagging as a live option for the next pass, not a unilateral switch.

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

### Live-workbook read (2026-08-03, coordinator session) — both sheets opened, cell layout now pinned

The scribe pass above could not open either `.xlsx`/`.xls` file (no COM/`actxserver` tool available that
session). A follow-up in the coordinator session opened both directly via MATLAB `readcell` (read-only —
neither file was modified) and confirmed exact sheet names and cell layouts:

**`temp_Casey/inputs/F-16A Block 50.xlsx`, sheet `Stability&Control`** (confirmed real, per Casey)
— 24 rows × 5 columns. Header row: `[blank] | Weight (lbf) | CG X-Location (ft) | X-MAC | Y-MAC` (the
last two columns are unpopulated in every row checked). Rows 2–23 are one component per row:

```
Wing, Fuselage, HT, VT, Nacelles, Strakes, Engine, Gear, Inlet duct, Controls, Electrical,
Hydraulics, ECS, Other, Avionics, Armaments, Fixed Payload, Exp Payload 1, Exp Payload 2,
Fuel 1, Fuel 2, Fuel 3
```
e.g. row 2 = `Wing | 1785 | 27.28`, row 8 = `Engine | 4730 | 33`, row 21 = `Fuel 1 | 2098 | 24`. This is
confirmed to be exactly the "component name → weight, x-station" table `SandCUtils.m`/`SandCLevel3`
read from, and its 22-component list matches `BrandtBalanceStabControl.m`'s own `xcg_*_ft` property list
(wing/fuse/pitch[HT]/vert[VT]/nacelle/strake/engine/gear/inlet/ctrl/elec/hyd/ECS/other/avionics/
armament/perm_pay/exp_pay/fuel{1,2,3}) almost 1:1 — strong evidence this sheet is the intended source
for (or at least parallels exactly) both this subplan's new x-location table and the existing BSC code's
own component breakdown. **Not yet decided:** whether `io` sources the new table from this legacy sheet
directly, rebuilds it fresh from `WeightsL3`/`GeomL3` per the subplan's original plan, or cross-checks
both — deferred to the `io` pass.

**`VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls`, sheet `S&C (2)`** — confirmed to exist, resolving the
subplan's original speculation ("almost certainly the 'S&C (2)' sheet"). 118 rows × 23 columns; most of
it is **out of this subplan's scope** (lateral-directional derivatives `CNB`/`ClB`/`CYB` rows 39–70;
short-period dynamic response `Cmq`/`Cmadot`/`Zal`/`Mal`/root-locus rows 79–118 — all explicitly excluded
per this subplan's "Explicitly out of scope" list). The **in-scope** rows, with real cell citations:

| Row | Quantity | Value | Citation printed in the sheet |
|---|---|---|---|
| 4–14 | Wing/HT/VT geometry (`b`, `cr`, `ct`, `x`, `Lle`, `S`, `AR`, `MAC`, …) | (per-surface, see sheet) | — |
| 15–22 | `xacW`/`xacHS`/`xacVS`, `xcgW`/`xcgHS`/`xcgVS`, `yacW`/`zacW`/… | e.g. `xacW=25.589 ft`, `xcgW=28.419 ft` | — |
| 24 | `CLaW`/`CLaHS`/`CLaVS` (per-surface lift-curve slope) | `3.2684`/`3.2684`/`3.4254` rad⁻¹ | — |
| 32 | `CLa` (aircraft) | `4.445` rad⁻¹ = `0.07758`/deg | **Roskam Eqn 3.24** |
| 33 | `xbarnp`/`xnp` (neutral point) | `2.3116` (frac. MAC) / `26.1677 ft` | **Roskam Eqn 3.38** |
| 34 | `xbarcg_Lndg`/`xcg_Lndg` | `2.3089` / `26.1369 ft` | — |
| 35 | `SMLndg` | `0.002723` | — |
| 36 | `xbarcgTakeoff`/`xcgTakeoff` | `2.3138` / `26.1925 ft` | — |
| 37 | `SM` | `-0.0021882` | — |
| 62, 64 | `a` (wing 0-lift AoA slope), `aHS` | **Roskam Eqn 3.17**, **Roskam Eqn 3.19** | |

Row 33's `xnp = 26.1677 ft`, row 34's `xcg_Lndg = 26.1369 ft`, and row 36's `xcgTakeoff = 26.1925 ft`
match `readme_bsc.md`'s already-recorded ground-truth values (`x_np≈26.168`, `x_cg_land≈26.137`,
`x_cg_TO≈26.193`) essentially exactly — confirming `readme_bsc.md`/`BrandtBalanceStabControl.m` already
consumes this sheet's numbers, even though `cell-map.md` never documented the cell references. **Gear
split/tipback/rollover data is NOT on this sheet** — grepped for "gear"/"tipback"/"rollover"/"split," zero
matches; that data lives on the separate `Gear` sheet, consistent with `f16a_geometry.json`'s existing
`gear` block citation ("Gear tab") and its already-logged provenance caveat (2026-07-31 `todo.md` entry).

**Major new lead:** rows 32/33/62/64 show Brandt's own ground truth for `CLa`/neutral-point/`a`/`aHS` is
built from **Roskam Eqns 3.17, 3.19, 3.24, 3.38** — not Raymer Ch. 16. See the "Major new lead" callout
in "Equations & Citations" above for what this means for the still-open Eq. 16.9 gap.

**Follow-up check (2026-08-03, per Casey's "check in addition to the Ch. 16 read"): this specific Roskam
book is NOT in this repo.** Searched every file under `temp_AI/docs/disciplines/reference_extracts/`
(the three `roskam_vol{1,2,3}_data.md` files plus every other extract) for "3.17", "3.19", "3.24", "3.38"
— no genuine match anywhere (a few numeric coincidences in unrelated Mattingly/Nicolai section numbers,
nothing about lift-curve slope or neutral point). The reason: **`roskam_vol1/2/3_data.md` extract a
different Roskam title** — *Airplane Design, Parts I/II/III* (preliminary sizing, configuration/drag
polar, and fuselage/wing/empennage layout, respectively) — not the book Brandt's sheet actually cites.
Chapter 3 "Static Longitudinal Stability and Control," with equations numbered in exactly this
3.17–3.38 neighborhood, is characteristic of Roskam's *separate* title, **"Airplane Flight Dynamics and
Automatic Flight Controls, Part I"** — a book this repo has never extracted at all, under any filename.
**So this lead does NOT close Eq. 16.9 for free** — it swaps one physical-book-read dependency (Raymer
Ch. 16) for a different, equally unmet one (Roskam's Flight Dynamics book, Ch. 3). Logged as a new,
distinct citation gap rather than resolved. **DECIDED (Casey, 2026-08-03): dropped** — Casey does not
have a copy of Roskam's *Airplane Flight Dynamics and Automatic Flight Controls, Part I*. Eq. 16.9 waits
on the Raymer Ch. 16 physical-book read alone (same as Eqs. 16.8 and 16.15 — see "GAP summary" above).
The Roskam Eqns 3.17/3.19/3.24/3.38 citation stays on record here as a known-real, known-unavailable
cross-check for a future session if that book ever becomes accessible — not pursued further now.

Both `todo.md` gap entries this finding closes are marked `RESOLVED (live-xls read, 2026-08-03)` in
place — see `VnV/BrandtF16A/todo.md`'s 2026-08-03 section.
