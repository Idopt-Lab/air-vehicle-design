# F16GeomL2.m — companion doc

## 2026-07-22 — L3 tier eliminated for Geometry; merged into this file
Per the user's decision (see `src/disciplines/geometry/GeomL2.md`'s dated note for full
rationale), Geometry no longer has an L3 fidelity tier — only L1 and L2. This file is the merge
of the former `F16GeomL2.md` and `F16GeomL3.md` (`F16GeomL3.md` is deleted; its content lives
entirely below). Where the two source files described the *same* physical quantity under
different property names or with different levels of detail (e.g. HT/VT breakdown, sweep
values), both are shown so the naming inconsistency is visible and can be resolved during
implementation, rather than silently picking one and losing information.

**Instruction for implementation-loop agents:** `examples/F16A/F16GeomL3.m` must be **deleted**
when this is implemented — its properties and methods (HT/VT full detail set, duct) move into
`F16GeomL2.m`. Do not leave `F16GeomL3.m`/`F16GeomL3` in the tree. See
`src/disciplines/geometry/GeomL2.md`'s dated note for the full list of files that must be
deleted across the whole discipline (`GeometryModelL3.m`, `GeomL3.m`, `F16GeomL3.m`,
`TestGeomL3.m`).

---

Tier-3 concrete class (`classdef F16GeomL2 < GeometryModelL2`). Every abstract *method* is a
single delegation line to `GeomL2` statics, as designed. The problem documented below is entirely
in the **properties**: every planform-derived quantity is hand-frozen as a literal number with a
comment showing the formula that generated it, rather than the formula actually being run.

## Methods in this file

Combined method set — the existing L2 methods plus what used to be L3-only (`get_S_wet_duct`,
`get_S_exposed_wing`), now both delegating to the merged `GeomL2` toolbox:

| Method | Computes | Citation (delegates to) |
|---|---|---|
| `get_S_ref(obj)` | Returns `obj.S_ref` | none — property accessor |
| `get_S_wet(obj, W_TO)` | Total `S_wet` (wing+HT+VT+fuselage, plus duct once merged — see `GeomL2.md`'s note on `get_S_wet` post-merge) | `GeomL2.get_S_wet` — see `GeomL2.md` |
| `get_S_wet_wing(obj)` | Wing `S_wet` | `GeomL2.get_S_wet_wing` → `compute_wet_planform` (Brandt Geom!B13) |
| `get_S_wet_HT(obj)` | HT `S_wet` | `GeomL2.get_S_wet_HT` → `compute_wet_planform` |
| `get_S_wet_VT(obj)` | VT `S_wet` | `GeomL2.get_S_wet_VT` → `compute_wet_planform` |
| `get_S_wet_fuselage(obj)` | Fuselage `S_wet` | `GeomL2.get_S_wet_fuselage` → Roskam Vol. II Eq. 12.3 |
| `get_S_wet_duct(obj)` *(was L3-only)* | Duct `S_wet` | `GeomL2.get_S_wet_duct` → Raymer 6th ed. §7.3 frustum formula |
| `get_S_exposed_wing(obj)` *(was L3-only)* | Passthrough — returns `obj.S_exposed_wing` | none — property accessor |

**Open question carried from the L3 file:** the former `F16GeomL2` used `compute_wet_planform`
(Brandt uniform-tc) for wing/HT/VT `S_wet`, while the former `F16GeomL3` used
`compute_roskam_planform` (Roskam Eq. 12.1, variable root/tip tc) for the same three surfaces —
i.e. the two source classes did not just add a duct, they used a **different formula** for the
existing wing/HT/VT wetted areas. Once merged into a single `F16GeomL2` class, implementation
must decide which formula this concrete class's `get_S_wet_wing`/`get_S_wet_HT`/`get_S_wet_VT`
methods call by default (or whether it exposes both, e.g. via a flag/second method). This
documentation pass does not resolve that choice — flagging it explicitly for the implementation
phase.

## THE BUG: `QC_sweep_wing = 37` deg

`F16GeomL2.m:30` — `QC_sweep_wing = 37 % deg Λ_c/4 [derived from planform]`. The comment claims
this was derived; **it was never actually computed**. Independently applying the standard
sweep-conversion identity (see `GeometryBase.md`'s Task-2 section — citation for this identity
itself is unresolved, but the algebra is uncontroversial) at this model's own
`AR_wing=3.0`, `lambda_wing=0.2275`, `LE_sweep_wing=40°` gives **≈32.2°**, not 37°. Applying the
same formula to the HT's own AR/taper/LE-sweep gives ≈36.8°≈37° — strongly suggesting `37` was
copy-pasted from the HT calculation onto the wing property. This was flagged independently in
`docs/darshan-verification/2026-07-21_steps_01-05_review.md` (`F16GeomL2.m:30` /
former `F16GeomL3.m:42` entries) and is the headline bug motivating this whole documentation pass.
It feeds directly into `AeroL2`/`AeroL3`'s `CL_alpha` and `CLmax` (both consume `Lambda_c4_deg`,
independently hardcoded to `37` again in `F16AeroL2.m`/`F16AeroL3.m` — see
`docs/geometry_parameter_usage.md`), shifting them by an estimated −3% to −5.6%.

**The bug is confirmed precisely at the former L3 tier too** (`F16GeomL3.m:42`), and the two
source files cited it under two different, mutually inconsistent justifications: `F16GeomL2.m`
said "[derived from planform]", `F16GeomL3.m` said "[TO Fig. 1-2]" (claiming it's a directly
T.O.-sourced value). Neither citation was correct — the value from the sweep-conversion identity
at this model's own inputs (AR=3.0, λ=0.2275, Λ_LE=40°) is ≈32.2° either way.

**Precise cross-check — every OTHER "derived" sweep value in the former L3 file IS internally
self-consistent with the sweep-conversion identity; only the wing's quarter-chord sweep is not:**

| Property | Stated value | Value from the identity at this component's own AR/λ/Λ_LE | Self-consistent? |
|---|---|---|---|
| `QC_sweep_wing` (AR=3.0, λ=0.2275, Λ_LE=40°) | 37° | **32.2°** | **NO — off by ≈4.8°** |
| `TE_sweep_wing` (x=1.0, same wing inputs) | 0.0° | 0.0° | yes |
| `QC_sweep_HT` (AR=4.81, λ=0.390, Λ_LE=40°) | 37° | 36.8° | yes (rounds to 37) |
| `TE_sweep_HT` (x=1.0, same HT inputs) | 25° | 25.4° | yes |
| `QC_sweep_VT` (AR=1.45, λ=0.437, Λ_LE=47.5°) | 39° | 39.4° | yes |
| `TE_sweep_VT` (x=1.0, same VT inputs) | 1° | 0.6° | yes (rounds to ~1) |

This is strong evidence the wing's `QC_sweep_wing=37` was copy-pasted from the HT's own
(correctly self-consistent) 36.8°≈37° value, rather than computed from the wing's own AR/λ/Λ_LE
— exactly the review's hypothesis in `docs/darshan-verification/2026-07-21_steps_01-05_review.md`,
now confirmed by checking every sweep property in the (former L3) file rather than just the
flagged one. (Sweep-conversion identity itself: citation unresolved — see `GeometryBase.md`. The
check above uses the algebra only, not a specific textbook equation number, since the algebra is
what the existing "[derived]" comments in this file already claim to have used.)

## Root cause: no planform quantity here is ever actually computed
`b_wing`, `AR_wing`, `c_root_wing`, `c_tip_wing`, and `QC_sweep_wing`/`TE_sweep_wing` are all
hand-frozen literals with a formula shown only in a comment. `docs/subplans/02_geometry.md:68-69`
requires `c_root` and `cbar` to be computed formulas; none of this is wired to run. Independently
computing MAC from the stated geometry gives ≈11.32 ft — a value that appears **nowhere** in the
codebase (no `cbar`/MAC property exists on this class at all). Same root cause applied to every
planform quantity in the former L3 file (`b`, `AR`, `c_root`, `c_tip`, MAC/`cbar`, or any
sweep-station conversion, for wing/HT/VT alike) — zero test coverage exists on any of them
(`docs/darshan-verification/2026-07-21_steps_01-05_review.md`).

## Properties — hardcoded vs. computed status

### Top level / wing / fuselage (previously L2)

| Property | Current value | Status | What a later phase should do |
|---|---|---|---|
| `S_ref` | `300` ft² | Hardcoded, cited `[T.O. 1F-16A-1, Fig. 1-2]` | JSON-loaded input — genuine spec data |
| `S_wet` | `0` (placeholder) | Correct — populated by `get_S_wet()` on demand | No change needed |
| **Wing** | | | |
| `S_exposed_wing` | `196.4` ft², cited `[Brandt Geom H7]` | This is a **Brandt-computed output** (Brandt's own exposed-planform algorithm, `readme_geom.md` §4.3), frozen as a literal — not a genuine F-16 spec-sheet number. Per `PLAN.md`'s rule against hardcoding Brandt's back-calculated outputs as inputs, this should not stay a literal. | Computed value, via the new lifting-surface exposed-area method documented in `GeomL2.md`'s Task-2 section (fed by genuine wing S/AR/taper + fuselage max-width JSON inputs) |
| `S_wet_wing` | `0` (placeholder) | Correct | No change needed |
| `tc_wing` | `0.04`, cited `[NACA 64A204; TO]` | Genuine spec data | JSON-loaded input |
| `QC_sweep_wing` | `37` deg, cited "derived from planform" | **Bug** — see above. Never actually derived; wrong value. | Computed value, via the Base-tier sweep-conversion method (citation currently unresolved — see `GeometryBase.md`) |
| `lambda_wing` | `0.2275`, cited `[TO Fig. 1-2]` | Genuine spec data | JSON-loaded input |
| `b_wing` | `30` ft, cited "`[sqrt(AR*S)=sqrt(3*300)]`" | Formula shown in comment, never run | Computed value, via `b = sqrt(AR*S_ref)` (Base tier) |
| `AR_wing` | `3.0`, cited "`[b^2/S_ref=900/300]`" | Genuine spec data (AR=3.0 is the primary F-16 spec value per T.O. and `temp_AI/docs/disciplines/reference_extracts/usaf_f16_data.md`; the comment's causality is backwards — AR is the input, `b` is derived from it, not vice versa) | JSON-loaded input |
| `LE_sweep_wing` | `40` deg, cited `[TO Fig. 1-2]` | Genuine spec data | JSON-loaded input |
| `TE_sweep_wing` | `0.0` deg, cited "derived" | Formula never run (though for a straight-tapered wing this specific value can be computed directly from `c_root`, `c_tip`, `b`, and `LE_sweep_wing` without needing the general sweep-conversion identity — it does not strictly depend on the unresolved citation) | Computed value |
| `c_root_wing` | `16.3` ft, cited "`[2*S_ref/(b*(1+λ))]`" | Formula shown, never run | Computed value, via Base `c_root` (Raymer 7th ed. Eq. 7.6) |
| `c_tip_wing` | `3.71` ft, cited "`[λ*c_root]`" | Formula shown, never run | Computed value, via Base `c_tip` (Raymer 7th ed. Eq. 7.7) |
| `tc_r_wing`/`tc_t_wing` *(was L3-only)* | both `0.04`, cited `[NACA 64A204; TO / uniform section]` | Genuine spec data — wing airfoil is treated as constant-thickness across the span (unlike HT/VT below), so root and tip happen to be equal | JSON-loaded input |
| **Fuselage** | | | |
| `L_fuselage` | `47.5` ft, "(same as L_fus)" | Genuine spec data, but **duplicated** under two property names (`L_fuselage` from the `GeometryModelL2` abstract contract, `L_fus` used by `GeomL2.get_S_wet_fuselage`) | JSON-loaded input; collapse to one canonical name when the JSON schema is designed |
| `W_max_fuselage` | `5.0` ft, cited "estimated; TO cross-section ~4.5×5.5 ft" | Genuine spec estimate. **Declared abstract in `GeometryModelL2` but not actually read by any `GeomL2.m` method** — `get_S_wet_fuselage` reads `obj.D_fus`/`obj.L_fus` only, never `obj.W_max_fuselage`/`obj.H_max_fuselage`. See `docs/geometry_parameter_usage.md`. | JSON-loaded input; note the dead-property status for the next phase |
| `H_max_fuselage` | `4.5` ft, cited "estimated; TO cross-section" | Same dead-property note as above | JSON-loaded input |
| `D_fus` | `5.0` ft, cited "estimated; TO cross-section ~4.5×5.5 ft" | Genuine spec estimate, coincidentally equal to `W_max_fuselage`'s value here — this is the property actually consumed by `get_S_wet_fuselage` | JSON-loaded input |
| `L_fus` | `47.5` ft, cited `[TO, Fig. 1-2]` | Genuine spec data, duplicate of `L_fuselage` (see above) | JSON-loaded input; collapse duplicate |

### Horizontal tail — naming inconsistency between the merged sources

The former L2 file carried only a minimal HT property set (`S_exposed_ht`, `tc_ht`); the former
L3 file carried a full breakdown under **differently-cased** property names (`S_exposed_HT`,
`QC_sweep_HT`, etc.) plus a root/tip t/c split. Both are shown below.

**RESOLVED (2026-07-22, user decision):** standardize on a **lowercase `_ht`/`_vt` suffix**
throughout the merged class — matches the pre-existing L2 convention and the rest of the codebase
outside Geometry (`WeightsL2.S_ht`, `WeightsL3.AR_ht`, `F16WeightsL3.lambda_ht` are all
lowercase-suffixed). This standardizes only the trailing `HT`/`VT` suffix, not the whole property
name: every former-L3 property below that appears uppercase (`S_exposed_HT`, `QC_sweep_HT`,
`AR_HT`, `LE_sweep_HT`, `TE_sweep_HT`, `c_root_HT`, `c_tip_HT`, and the VT equivalents) keeps its
prefix capitalization exactly as-is and only lowercases the suffix — `S_exposed_ht`,
`QC_sweep_ht`, `AR_ht`, `LE_sweep_ht`, `TE_sweep_ht`, `c_root_ht`, `c_tip_ht` — matching the
pre-existing wing property `QC_sweep_wing`'s casing (wing was never uppercase and is untouched by
this resolution). **CORRECTED 2026-07-22 (second pass):** an earlier implementation of this
resolution misread "lowercase `_ht`/`_vt` suffix" as "lowercase the whole property," producing a
fully-lowercase `qc_sweep_ht`/`qc_sweep_vt` inconsistent with every other HT/VT property in this
same list (`AR_ht`, `LE_sweep_ht`, etc., which correctly kept their prefix capitalization). Fixed
to `QC_sweep_ht`/`QC_sweep_vt` in `GeometryModelL2.m`, `F16GeomL2.m`, and this note. The
minimal-vs-full-set question (whether the merged class carries the full former-L3 breakdown or
just the former-L2 minimal set) is resolved separately: since the merge keeps Roskam Eq. 12.1 as
the official S_wet formula (see `GeomL2.md`), which needs `tc_root`/`tc_tip` per surface, the
**full breakdown is required** — the minimal set alone is no longer sufficient.

| Property | Current value | Status | What a later phase should do |
|---|---|---|---|
| `S_exposed_ht` (L2 name) / `S_exposed_HT` (former L3 name) | `63.70` ft², cited `[TO, Block 10]` | **Naming concern, not resolved here:** this number matches the T.O.-quoted *total* HT planform area, not an "exposed" (post-fuselage-intersection) area in Brandt's sense — Brandt's own exposed pitch-control-surface area (`Geom!H8`) is 49.8473 ft², a different number. The property name may be mislabeling a full-planform value. Also note the two source files disagree on capitalization (`_ht` vs. `_HT`) for the same physical quantity. Flagging for review, not resolving. | If this is meant as a true exposed area, replace with the computed value from the new exposed-area method (`GeomL2.md` Task 2); if meant as full planform area, rename to avoid confusion with "exposed"; unify capitalization |
| `tc_ht` | `0.048`, cited "average; TO Sec I" | Genuine spec estimate — this is the single-value uniform-tc L2 property, used by `compute_wet_planform` | JSON-loaded input |
| `S_wet_HT` *(was L3-only)* | `0` (placeholder) | Correct | No change needed |
| `QC_sweep_HT` *(was L3-only)* | `37` deg, `[derived]` | Self-consistent with HT's own AR/λ/Λ_LE (see bug table above) — **not the bug**, but still not actually *computed* by running code; the comment claims derivation that didn't happen to run | Computed value, via Base-tier sweep-conversion method (same citation-TODO as wing) |
| `lambda_HT` *(was L3-only)* | `0.390`, `[TO Fig. 1-2]` | Genuine spec data | JSON-loaded input |
| `b_HT` *(was L3-only)* | `17.5` ft, "estimated; TO cross-sections" | Estimate, not a Raymer/Roskam-cited formula result | JSON-loaded input (estimate), or computed from `S_exposed_HT`/`AR_HT` via `b=sqrt(AR*S)` if those become the canonical inputs |
| `AR_HT` *(was L3-only)* | `4.81`, `[b^2/S=306.25/63.70]` | Formula shown, never run. **Also inconsistent with `examples/F16A/F16WeightsL3.m:58`'s `AR_ht = 2.114` for the same physical quantity** — two different hardcoded values for HT aspect ratio across discipline files. Not a VnV/BrandtF16A discrepancy (both are in the active `examples/` tree), but flagging for user review since it is exactly the kind of "geometry never gets computed/shared once" problem this whole effort targets. | Computed value (from genuine spec inputs) once the JSON schema unifies which number is canonical, resolving the Geom-vs-Weights mismatch |
| `LE_sweep_HT` *(was L3-only)* | `40` deg, "estimated; TO Sec I" | Genuine spec estimate | JSON-loaded input |
| `TE_sweep_HT` *(was L3-only)* | `25` deg, `[derived]` | Self-consistent (see bug table above), formula never run | Computed value |
| `c_root_HT` *(was L3-only)* | `5.24` ft, "`[2*S/(b*(1+λ))]`" | Formula shown, never run | Computed value, via Base `c_root` |
| `c_tip_HT` *(was L3-only)* | `2.04` ft, "`[λ*c_root]`" | Formula shown, never run | Computed value, via Base `c_tip` |
| `tc_r_ht` *(was L3-only)* | `0.060`, "TO Sec I; biconvex root ~6%" | Genuine spec estimate | JSON-loaded input |
| `tc_t_ht` *(was L3-only)* | `0.035`, "TO Sec I; biconvex tip ~3.5%" | Genuine spec estimate | JSON-loaded input |

### Vertical tail — same naming-inconsistency situation as HT

| Property | Current value | Status | What a later phase should do |
|---|---|---|---|
| `S_exposed_vt` (L2 name) / `S_exposed_VT` (former L3 name) | `54.75` ft², cited `[TO]` | Same naming concern as HT above (both the "exposed vs. full-planform" question and the `_vt`/`_VT` casing mismatch) | Same treatment |
| `tc_vt` | `0.042`, cited "average; TO Sec I" | Genuine spec estimate — single-value uniform-tc L2 property | JSON-loaded input |
| `S_wet_VT` *(was L3-only)* | `0` (placeholder) | Correct | No change needed |
| `QC_sweep_VT` *(was L3-only)* | `39` deg, "derived from planform; ΛLE=47.5°" | Self-consistent (see bug table above) | Computed value |
| `lambda_VT` *(was L3-only)* | `0.437`, `[TO Fig. 1-2]` | Genuine spec data | JSON-loaded input |
| `b_VT` *(was L3-only)* | `8.9` ft, "estimated; TO Sec I" | Estimate | JSON-loaded input |
| `AR_VT` *(was L3-only)* | `1.45`, `[b^2/S=79.21/54.75]` | Formula shown, never run. **Also inconsistent with `F16WeightsL3.m:66`'s `AR_vt = 1.294`** — same cross-file mismatch pattern as `AR_HT` above. | Computed value once unified |
| `LE_sweep_VT` *(was L3-only)* | `47.5` deg, "TO; reported" | Genuine spec data | JSON-loaded input |
| `TE_sweep_VT` *(was L3-only)* | `1` deg, "derived: near-vertical TE" | Self-consistent (see bug table above) | Computed value |
| `c_root_VT` *(was L3-only)* | `8.56` ft, "`[2*S/(b*(1+λ))]`" | Formula shown, never run | Computed value |
| `c_tip_VT` *(was L3-only)* | `3.74` ft, "`[λ*c_root]`" | Formula shown, never run | Computed value |
| `tc_r_vt` *(was L3-only)* | `0.053`, "TO Sec I; biconvex root ~5.3%" | Genuine spec estimate | JSON-loaded input |
| `tc_t_vt` *(was L3-only)* | `0.030`, "TO Sec I; biconvex tip ~3.0%" | Genuine spec estimate | JSON-loaded input |

### Inlet + engine duct *(was L3-only, now part of L2)*

| Property | Current value | Status | What a later phase should do |
|---|---|---|---|
| `D_inlet` | `3.4` ft, "estimated; TO Sec I cross-sections" | Estimate | JSON-loaded input |
| `D_exit` | `2.9` ft, "estimated; TO Sec I" | Estimate | JSON-loaded input |
| `L_duct` | `14.0` ft, "estimated" | Estimate | JSON-loaded input |

## Unused constant properties *(was L3-only)*
`mainwheel_S_front` and `nosewheel_S_front` (`properties (Constant)` on the former `F16GeomL3`)
are frontal areas for the main/nose landing-gear wheels. Neither was read by any method in the
former `GeomL3.m` or is read by `GeomL2.m` today — no landing-gear component exists in the
current `get_S_wet` aggregation. Flagging as dead/unwired, consistent with the other
dead-parameter findings in `docs/geometry_parameter_usage.md`. These constants have no L2
equivalent today; carry them forward into the merged `F16GeomL2.m` as-is (still unused) unless a
later phase actually wires up a landing-gear component.

## Class-level validation comment (S_wet breakdown)
`F16GeomL2.m:10-16`'s docstring shows a hand-computed S_wet breakdown **without duct** (wing
392.4, HT 127.5, VT 109.4, fuselage 644.7, total 1274.0 ft²) against "Brandt F-16A.xls Main!L3 →
1371 ft² (7% below; statistical)." The former `F16GeomL3.m:10-17`'s docstring shows a separate
hand-computed breakdown **with duct, using the Roskam Eq. 12.1 formula for wing/HT/VT instead of
Brandt's uniform-tc formula** (wing≈397, HT≈130, VT≈111, fuselage≈645, duct≈139, total≈1422 ft²)
against "Brandt 1371 ft² (+3.7%; duct dimensions are estimated)." Both are documentation only (a
comment), not a test — `docs/darshan-verification/2026-07-21_steps_01-05_review.md` notes zero
test coverage exists for any of the planform quantities either file hardcodes. Both breakdowns
are preserved here since the merged class's `get_S_wet` behavior (which formula for wing/HT/VT,
whether duct is included) is an open implementation decision (see "Open question" under Methods
above) — whichever choice is made, this comment should be updated to match at implementation
time. Not evaluated further in this phase.
