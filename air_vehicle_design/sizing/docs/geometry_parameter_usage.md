# Geometry parameter usage table

**2026-07-22 note:** Geometry's L3 fidelity tier has been eliminated and merged into L2 (user
decision — see `src/disciplines/geometry/GeomL2.md`'s dated note for full rationale). This table
was originally written while `GeomL3`/`F16GeomL3`/`GeometryModelL3` still existed as a separate
tier; references to those below have been reframed to L2 (`GeomL2`/`F16GeomL2`), since that is
where the content now lives. This does **not** apply to Aerodynamics, Propulsion, or Weights —
`AeroL3`, `WeightsL3`, etc. below are untouched and still refer to a real, separate L3 tier for
those disciplines.

Which discipline/fidelity/function consumes which geometric parameter, and under what citation.
Derived by reading `src/base/AerodynamicsBase.m`, `src/disciplines/aerodynamics/AeroL1.m`,
`AeroL2.m`, `AeroL3.m`, `examples/F16A/F16AeroL1.m`, `F16AeroL2.m`, `F16AeroL3.m`,
`src/base/PropulsionBase.m`, `src/disciplines/propulsion/PropL1.m`, `PropL2.m`,
`examples/F16A/F16PropL1.m`, `F16PropL2.m`, `src/base/WeightsBase.m`,
`src/disciplines/weights/WeightsL1.m`, `WeightsL2.m`, `WeightsL3.m`,
`examples/F16A/F16WeightsL1.m`, `F16WeightsL2.m`, `F16WeightsL3.m`.

## Headline finding: no live data flow

**No orchestrator file exists yet in the active tree** (`SizingLoop*.m`, `ConstraintAnalysis*.m`,
`MissionAnalysis*.m` — grepped for, none found outside `temp_Casey/`). As a result, every
discipline's F-16 Tier-3 class independently **re-hardcodes its own copy** of whatever
geometric numbers it needs; nothing reads a `F16GeomL2` instance's properties or
method outputs at runtime. Where two disciplines hardcode the "same" quantity, the numbers
sometimes agree and sometimes silently disagree (see the `AR_HT`/`AR_VT`/`S_wet_fus` rows
below) — a direct consequence of nothing being computed once and shared.

## Propulsion consumes zero geometric parameters

Confirmed directly: `PropulsionBase.m`, `PropL1.m`, `PropL2.m`, `F16PropL1.m`, `F16PropL2.m`
contain no reference to `S_ref`, `AR`, `b`, any sweep angle, chord, `S_wet`, or any fuselage/duct
dimension as an *input*. Propulsion only **produces** engine geometry as outputs
(`PropL2.engine_length_nonAB/AB`, `engine_diam_nonAB/AB` — Raymer 6th ed. Eqs. 10.5/10.6/10.11/10.12,
functions of thrust `T`, Mach `M`, bypass ratio `BPR` only), and nothing in the active codebase
reads those outputs back in — `F16GeomL2`'s duct properties (`D_inlet`, `D_exit`, `L_duct`,
formerly on `F16GeomL3` before the L3-to-L2 merge) are independently hardcoded estimates, not
sourced from a `PropL2` call.

---

## Wing reference / planform parameters

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `S_ref` | `AerodynamicsBase.compute_CL(L,q,S_ref)` | `CL = L/(q*S_ref)` — definitional | |
| `S_ref` | `AeroL1.get_CD0` → `CD0_from_Cf(Cf, S_wet, S_ref)` | Raymer 6th ed. §12.3 | Also used identically by `AeroL2.get_CD0` (delegates to `AeroL1`) |
| `S_ref` | `AeroL3.get_CD0_buildup` (normalizes `cd0_sum / obj.S_ref`) | Raymer 6th ed. §12.3 component-buildup form | |
| `S_ref` | `AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)` / `AeroL3` same | Raymer 6th ed. Eq. 12.21 | **Never called anywhere in the active tree — see "Dead/unwired parameters" below** |
| `S_ref` | `WeightsL2`/`WeightsL3` — indirectly, via each discipline's own hardcoded `S_w` (see Wing structural row below), not read from Geometry's `S_ref` | — | |
| `S_ref` | *(planned, Task 2)* `S_HT = c_HT*cbar*S_ref/L_HT`, `S_VT = c_VT*b*S_ref/L_VT` | Raymer 7th ed. Table 6.4 | Not implemented yet — see `GeomL1.md` |
| `AR` (wing) | `AeroL1.oswald_eff(AR, Lambda_LE_deg)` | Raymer 6th ed. Eq. 12.48 (Λ<30°) / 12.49 (Λ≥30°) | |
| `AR` | `AeroL1.K1_subsonic(e, AR)` | Raymer 6th ed. Eq. 12.50 | |
| `AR` | `AeroL1.K1_supersonic(M, AR, Lambda_LE_deg)` | Raymer 6th ed. Eq. 12.51 | Guaranteed crash at exactly M=1.0 — separately flagged in the 2026-07-21 review, not re-litigated here |
| `AR` | `AeroL2.CL_alpha(AR, Lambda_c4_deg, M)` (via `get_CL_alpha`) | Raymer 6th ed. Eq. 12.6 | |
| `AR` | `AeroL2`/`AeroL3.get_CL_max_values` — `wing_param = (C1+1)*AR*cosd(Lambda_LE_deg)` | Raymer 6th ed. Fig. 12.13/12.9 AR check | |
| `AR` | `WeightsL3.wing(...)` — `S_w^0.622 * AR^0.785 * ...` | Raymer 6th ed. Eq. 15.1 | Consumed as `obj.AR_w` on `F16WeightsL3` (independently hardcoded `3.0`, happens to agree with `F16GeomL2.AR_wing=3.0`) |
| `b` (span) | `AeroL1.compute_AR_wet(b, S_wet)` | Raymer 6th ed. Eq. 3.11 | **Dead/unwired — see below** |
| `b` | `AeroL2`/`AeroL3.compute_F(d, b)` (fuselage lift interference factor) | Raymer 6th ed. Eq. 12.9 | **Dead/unwired — see below** |
| `b` | *(planned, Task 2)* `S_VT = c_VT*b*S_ref/L_VT` | Raymer 7th ed. Table 6.4 | Not implemented yet |
| `Lambda_LE_deg` (wing LE sweep) | `AeroL1.oswald_eff`, `K1_supersonic` (see `AR` rows above) | Raymer 6th ed. Eqs. 12.48/12.49/12.51 | |
| `Lambda_LE_deg` | `AeroL2`/`AeroL3.get_CL_max_values` (`wing_param` formula, see above) | Raymer 6th ed. Fig. 12.13/12.9 | |
| `Lambda_LE_deg` | `AeroL3.get_CL_alpha` (generic toolbox static — **approximation**, uses `Lambda_LE_deg` in place of `Lambda_c4_deg`; own comment admits this) | Raymer 6th ed. Eq. 12.6 | `F16AeroL3.get_CL_alpha` (the concrete override, `F16AeroL3.m:225-228`) does NOT use this approximation — it calls `AeroL2.CL_alpha(obj.AR, obj.Lambda_c4_deg, M)` directly, correctly using quarter-chord sweep. Documenting the toolbox-level approximation exists but is bypassed by the F-16 concrete class. |
| `Lambda_LE_deg` | `WeightsL3.wing(...)` — `cos(Lambda_LE)^(-1.0)` | Raymer 6th ed. Eq. 15.1 | Code comment flags uncertainty: "some editions use quarter-chord sweep — verify sweep definition" (`WeightsL3.m:56-57`) — documenting the existing uncertainty, not resolving it |
| `Lambda_c4_deg` (wing quarter-chord sweep) | `AeroL2.CL_alpha` (via `get_CL_alpha`) | Raymer 6th ed. Eq. 12.6 | **This is the property carrying the 37°/should-be-32.2° bug — see `F16GeomL2.md`.** Hardcoded independently (again) as `37` directly on `F16AeroL2`/`F16AeroL3`, not read from `F16GeomL2` at all — same wrong number duplicated a third and fourth time. |
| `Lambda_c4_deg` | `AeroL2.CLmax_clean(cl_max_2D, Lambda_c4_deg)` (via `get_CLmax`) | Raymer 6th ed. §12.2 | Same 37° value, same bug propagation |
| `Lambda_c4_deg` | `F16AeroL3.get_CL_alpha` override (see above) | Raymer 6th ed. Eq. 12.6 | |
| `lambda_wing` (taper) | `WeightsL3.wing(...)` — `(1+lambda)^0.05` | Raymer 6th ed. Eq. 15.1 | Consumed as `obj.lambda_w` (independently hardcoded `0.2275` on `F16WeightsL3`, agrees with `F16GeomL2`) |
| `S_csw` (wing control-surface area) | `WeightsL3.wing(...)` — `S_csw^0.04` | Raymer 6th ed. Eq. 15.1 | `F16WeightsL3.S_csw=69.0` annotated "estimate; from WeightLevel3.m hardcode; verify" — not sourced from any Geometry class (Geometry has no control-surface-area property at all today; Task 2's planned `C_e/c`/`C_r/c` fractions, `GeomL1.md`, would let this become a computed value) |
| `tc_root` (wing) | `WeightsL3.wing(...)` — `tc_root^(-0.4)` | Raymer 6th ed. Eq. 15.1 | Consumed as `obj.tc_root` (independently hardcoded `0.04`, agrees with `F16GeomL2.tc_wing`/`tc_r_wing`) |

## Chords / MAC (Base-tier, planned)

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `c_root`, `c_tip` | *(planned, Task 2)* not consumed by any existing discipline function today — no discipline reads `F16GeomL2.c_root_wing`/`c_tip_wing` anywhere | Raymer 7th ed. Eqs. 7.6/7.7 | Currently hardcoded, never computed, and never consumed downstream either — fully inert today |
| `cbar` (MAC) | *(planned, Task 2)* `S_HT = c_HT*cbar*S_ref/L_HT` | Raymer 7th ed. Table 6.4 / Eq. 7.8 | No `cbar` property exists anywhere in the codebase today (confirmed by grep) — independent hand-computation from the stated F-16 geometry gives ≈11.32 ft |

## S_wet (total and per-component)

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `S_wet` (total) | `AeroL1`/`AeroL2.get_CD0` → `CD0_from_Cf(Cf, S_wet, S_ref)` | Raymer 6th ed. §12.3 | `F16AeroL1/L2.S_wet=1371` hardcoded from `[Brandt F-16A.xls Main!L3]` — independent of `F16GeomL1/L2`'s own `get_S_wet()` output, which the constructors never call |
| `S_wet_comp` (per-component array: wing/HT/VT/fus/duct) | `AeroL3.get_CD0_buildup` — `cd0_sum += cf_eff*ff_i*Q_comp(i)*S_wet_comp(i)` | Raymer 6th ed. component-buildup method, Eqs. 12.25–12.31 | `F16AeroL3.S_wet_comp = [397, 130, 111, 644, 139]` — these numbers match `F16GeomL2.md`'s "with duct" class-level validation comment (wing≈397, HT≈130, VT≈111, fus≈645, duct≈139 — formerly `F16GeomL3.m`'s docstring before the L3-to-L2 merge) almost exactly, strongly suggesting they were **hand-copied from that comment once**, not live-read from a `F16GeomL2` object at runtime. No code path connects the two classes. |
| `S_wet_fus` | `WeightsL2.weight_fuselage` — `W = rho_fus * obj.S_wet_fus` | Raymer 6th ed. Table 15.2 | `F16WeightsL2.S_wet_fus = 750` ft², annotated "estimate; verify TO 1F-16A-1" — **disagrees with `F16GeomL2`'s own computed-in-comment fuselage S_wet (≈644.7 ft², Roskam Eq. 12.3 at D=5.0/L=47.5) by ≈16%.** Flagging as a cross-file inconsistency; not a VnV/BrandtF16A discrepancy (both files are in the active `examples/` tree) so not logged to `VnV/BrandtF16A/todo.md`, but worth the same kind of "compute once, share" fix. |

## Thickness ratio / component geometry (AeroL3 CD0 buildup)

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `tc_comp` (per-component t/c) | `AeroL3.FF_surface(tc, x_c_max, Lambda_m_deg, M)` | Raymer 6th ed. Eq. 12.30 | Wing `tc_comp=0.04` matches `F16GeomL2.tc_r_wing`/`tc_t_wing`; HT `tc_comp=0.047` and VT `tc_comp=0.042` are each close to (but not exactly) the average of `F16GeomL2`'s own root/tip t/c pairs — independently chosen, not computed from the Geometry class |
| `l_ref_comp` (per-component reference length — MAC for surfaces, overall length for bodies) | `AeroL3.compute_Re(state, l_ref)`, `Re_cutoff_sub/sup` | Raymer 6th ed. Eqs. 12.25/12.28/12.29 | Wing entry hardcoded `12.0` ft — does not match the ≈11.32 ft MAC an independent hand-computation gives from `F16GeomL2`'s own stated root/tip chords (no `cbar` property exists to compare against directly) |
| `D_comp` (per-component diameter, bodies only) | `AeroL3.FF_body(L_body, D_body)` (via `is_body_comp` branch) | Raymer 6th ed. Eq. 12.31 | Fuselage `D_comp=5.0` agrees with `F16GeomL2.D_fus=5.0`; duct `D_comp=3.15` = average of `F16GeomL2.D_inlet=3.4`/`D_exit=2.9`, consistent but independently computed, not read live |
| `x_c_max_comp` | `AeroL3.FF_surface` (same as `tc_comp` row) | Raymer 6th ed. Eq. 12.30 | Airfoil-level datum (chordwise location of max thickness), not a planform quantity Geometry produces — sourced independently `[T.O.; Raymer Table 12.6]` |
| `Lambda_m_comp` (sweep at max-thickness line, per component) | `AeroL3.FF_surface` (same) | Raymer 6th ed. Eq. 12.30 | Wing `Lambda_m_comp=35°`; a spot-check using the (unresolved-citation) sweep-conversion identity at the wing's own AR/λ/Λ_LE and x=0.40 (the wing's own `x_c_max_comp`) gives ≈26.7°, and at x=0.50 gives ≈22.8° — neither matches 35°. Not deeply investigated further here (this is an Aero-owned, not Geometry-owned, hardcoded estimate), but flagging as a further instance of the same "estimated, not computed" pattern. |

## Fuselage L/D/W

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `D_fus`, `L_fus` | `GeomL2.compute_s_wet_fus_cyl` | Roskam Vol. II Eq. 12.3 | Within Geometry itself — the one place a "computed from inputs" chain genuinely runs today |
| `L_fus` | `WeightsL3.fuselage(...)` — `L_fus^0.5` | Raymer 6th ed. Eq. 15.4 | Consumed as `obj.L_fus` (hardcoded `47.5`, agrees with `F16GeomL2.L_fus`) |
| `D_fus` | `WeightsL3.fuselage(...)` — `D_fus^0.849` | Raymer 6th ed. Eq. 15.4 | Agrees (`5.0` both places) |
| `W_fus` (max fuselage width) | `WeightsL3.fuselage(...)` — `W_fus^0.685` | Raymer 6th ed. Eq. 15.4 | `F16WeightsL3.W_fus=7.0` ft — **disagrees with `F16GeomL2.W_max_fuselage=5.0`** ft for what both name "max fuselage width." (`7.0` actually matches the live Brandt `Main!C32` max-width cell, `5.0` does not — see Task 4 findings — so Weights' number happens to be the value Brandt's own workbook uses, while Geometry's is an independent T.O.-cross-section estimate.) Flagging the cross-file mismatch; not resolving. |
| `W_max_fuselage`, `H_max_fuselage` | **Not consumed anywhere** — declared `Abstract` in `GeometryModelL2` but no `GeomL2.m` method reads them (`get_S_wet_fuselage` reads `D_fus`/`L_fus` only) | — | Dead properties within Geometry itself, not just cross-discipline |

## Tail areas, AR, taper, sweep (HT/VT)

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `S_ht`/`S_ht` | `WeightsL2.weight_tail` — `W.HT = rho_ht*obj.S_ht` | Raymer 6th ed. Table 15.2 | `F16WeightsL2.S_ht=63.70` agrees with `F16GeomL2.S_exposed_ht`/`S_exposed_HT` |
| `S_vt` | `WeightsL2.weight_tail` — `W.VT = rho_vt*obj.S_vt` | Raymer 6th ed. Table 15.2 | Agrees, `54.75` both places |
| `S_ht`, `F_w`, `B_h` | `WeightsL3.horizontal_tail(...)` | Raymer 6th ed. Eq. 15.2 | `F_w=7.0` (fuselage width at HT) — same `7.0` vs `5.0` mismatch noted in the fuselage-width row above; `B_h` computed in `F16WeightsL3`'s constructor as `sqrt(AR_ht*S_ht)`, i.e. **is** actually computed, just from `F16WeightsL3`'s own independently-hardcoded `AR_ht`, not from Geometry |
| `AR_ht` (HT aspect ratio) | `F16WeightsL3` constructor (`B_h = sqrt(obj.AR_ht * obj.S_ht)`) and `WeightsL3.vertical_tail` (indirectly, `AR_vt` for VT) | — | `F16WeightsL3.AR_ht = 2.114` **disagrees with `F16GeomL2.AR_HT = 4.81`** for the same physical quantity — see `F16GeomL2.md`. `2.114` matches `temp_AI/docs/disciplines/reference_extracts/usaf_f16_data.md`'s reported HT aspect ratio; `4.81` is `F16GeomL2`'s own `b_HT^2/S_exposed_HT` computed-in-comment value from its own (differently sourced) `b_HT=17.5` estimate. |
| `S_vt`, `H_t`, `H_v`, `M_design`, `L_t`, `S_r`, `AR_vt`, `lambda_vt`, `Lambda_LE_vt` | `WeightsL3.vertical_tail(...)` | Raymer 6th ed. Eq. 15.3 | `F16WeightsL3.AR_vt = 1.294` **disagrees with `F16GeomL2.AR_VT = 1.45`** — same pattern as `AR_ht` above; `1.294` matches `usaf_f16_data.md`. `lambda_vt=0.437` and `Lambda_LE_vt=47.5` DO agree with `F16GeomL2`. `L_t=22.0` ft annotated "estimate; verify TO 1F-16A-1" — no Geometry-class tail-arm property exists to compare against (Task 2's planned `L_HT=L_VT=0.475*L_fus` would give `0.475*47.5=22.56` ft, coincidentally close). `S_r=50.0` ft² annotated "estimate; from WeightLevel3.m code" — Task 2's planned rudder chord fraction (`C_r/c=0.33`, Raymer 7th ed. Table 6.5) would let this become a computed value once VT chord geometry is computed. |

## Control-surface areas

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `S_flapped`, `Lambda_HL_deg` | `AeroL2`/`AeroL3.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)` | Raymer 6th ed. Eq. 12.21 | **Dead/unwired — see below.** No `F16AeroL2`/`F16AeroL3` property or call site supplies real values; the method is defined but never invoked. |
| control-surface chord fractions (elevator, rudder, aileron) | *(planned, Task 2)* `C_e/c=0.30`, `C_r/c=0.33` (jet fighter, Raymer 7th ed. Table 6.5); aileron fraction NOT available in the given table | Raymer 7th ed. Table 6.5 | Not implemented; no existing consumer either — `S_csw` (Weights L3) and `S_cs` (Weights L3 flight-controls) are both currently independent hardcoded estimates, not computed from a chord-fraction × tail/wing planform relationship |
| `S_csw` (wing control-surface area) | `WeightsL3.wing(...)` | Raymer 6th ed. Eq. 15.1 | See Wing-parameters section above |
| `S_cs` (total control-surface area) | `WeightsL3.flight_controls(M, S_cs, N_s, N_c)` | Raymer 6th ed. Eq. 15.17 | `F16WeightsL3.S_cs=190` ft², annotated "estimate: flaperon+HT+rudder+LEF" — sum of components none of which exist as Geometry outputs today |

## Engine/duct geometry

| Parameter | Consumed by | Citation | Notes |
|---|---|---|---|
| `D_inlet`, `D_exit`, `L_duct` | `GeomL2.get_S_wet_duct` → `compute_s_wet_duct` (formerly `GeomL3`, moved into `GeomL2` per the 2026-07-22 L3-elimination decision) | Raymer 6th ed. §7.3 (frustum lateral-area formula) | Within Geometry itself |
| `D_e` (engine face/nozzle diameter) | `WeightsL3.air_induction`, `tailpipe`, `engine_cooling` | Raymer 6th ed. Eqs. 15.10/15.11/15.12 | `F16WeightsL3.D_e=3.33` ft — independent estimate, not derived from `F16GeomL2.D_inlet=3.4`/`D_exit=2.9`, and not read from any `PropL2` engine-sizing output either (recall: Propulsion produces engine diameter as an output via `engine_diam_AB`, but nothing calls it and feeds it here) |
| `L_d`, `L_s` | `WeightsL3.air_induction` | Raymer 6th ed. Eq. 15.10 | Independent estimates, not sourced from `F16GeomL2.L_duct` |
| `L_tp`, `L_sh`, `L_ec` | `WeightsL3.tailpipe`/`engine_cooling`/`oil_cooling` | Raymer 6th ed. Eqs. 15.11/15.12/15.13 | Independent estimates; no Geometry-class equivalent exists |

---

## Dead / unwired parameters (confirmed by grep — zero call sites with real arguments anywhere outside their own definitions, and no orchestrator file exists in the active tree to wire them)

| Parameter | Formal parameter of | Would-be citation |
|---|---|---|
| `b` (wing span) | `AeroL1.compute_AR_wet(b, S_wet)` | Raymer 6th ed. Eq. 3.11 |
| `b`, `d` (fuselage diameter) | `AeroL2`/`AeroL3.compute_F(d, b)` | Raymer 6th ed. Eq. 12.9 |
| `S_flapped`, `Lambda_HL_deg` | `AeroL2`/`AeroL3.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)` | Raymer 6th ed. Eq. 12.21 |

Confirmed via `grep -r "compute_AR_wet\|compute_F(\|compute_Delta_CL_max_values"` across `tests/` (zero matches) and across `src/`/`examples/` (matches only in the methods' own definitions/delegation chains, never a call site supplying real geometry). No `SizingLoop*.m`/`ConstraintAnalysis*.m`/`MissionAnalysis*.m` orchestrator file exists yet in the active tree, which is the reason nothing calls these with real values — consistent with Steps 6–8 (constraints/mission/sizing) not having started per `CLAUDE.md`'s step list.
