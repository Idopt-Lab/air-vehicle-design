# Tail Sizing — scribe planning doc (pre-implementation)

**RETIRED 2026-08-03:** the standalone `tail_sizing` discipline this doc planned is deleted — tail
sizing is organizationally part of the Geometry discipline now (Casey's decision), with the same
equations/citations/coefficients ported into `src/disciplines/geometry/GeomL1.m`/`GeomL2.m`/`GeomL3.m`
and `examples/F16A/F16GeomL1.m`/`F16GeomL2.m`/`F16GeomL3.m`'s "TAIL SIZING" marked sections. This file
is kept solely as the historical discrepancy-resolution record (several `.m`/test comments in the
Geometry files above cite it by name); every other file in the former `src/disciplines/tail_sizing/`
directory is deleted.

**Status:** planning only, FINALIZED 2026-07-28 (coordinator/user sign-off on all open items — see
§8). No `.m` implementation files exist yet for the three-tier discipline; this doc lays out
equations/citations/inputs/outputs per tier, with the decisions below now locked, so it can be split
into the usual per-file companion `.md` docs the moment `geometry-equations-expert`/
`matlab-oop-expert` create the real files. Per the scribe brief, this file contains **zero
implementation code**.

**Supersedes** `docs/PLAN.md`'s "Resolved Decisions" entry: *"Tail sizing levels: L1: Volume
coefficient method only. L2: Left for future work — Raymer Chapter 16 (not in scope)."* — the
coordinator will update `PLAN.md` directly. Finalized replacement structure (decided 2026-07-28, full
rationale in §§2/4/5/6 below):

- **L1** — volume-coefficient method. Canonical coefficients `c_HT=0.315`, `c_VT=0.063` (Raymer 7th
  ed. Table 6.4 base 0.40/0.07 with RSS ×(1−10%) and all-moving-tail ×(1−12.5%) text corrections
  applied — the F-16 has both properties). Tail arm `L_HT=L_VT=0.475*L_fus`. Cites Raymer **7th**
  ed. going forward, not 6th. The previously-orphaned, competing implementation in `GeomL1.m` is
  retired; its logic is the one that survives, ported into the new `TailL1` toolbox.
- **L2** — "historical sizing estimates." Same volume-coefficient functional form, fed real L2 wing
  geometry (`b_wing`/`cbar_wing`/`S_ref`/`L_fus`, injected `GeometryModelL2` object), but with
  Nicolai & Carichner's F-16-**specific** measured coefficient (`C_HT=0.3`, `C_VT=0.094`, Table
  11.6) rather than a generic category row. Tail arm carries forward L1's `0.475*L_fus` (L2 geometry
  has no x-stations to do better — see §5.1).
- **L3** — Raymer Ch. 16 stability-and-control tail sizing. Shipped now as a documented-TODO /
  deliberately-failing-test structure (the citation-gap exception CLAUDE.md explicitly allows),
  matching the convention already used by `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`
  — not blocked on further research. See §6.
- Reuse of geometry's exposed/wetted-area machinery at L2/L3 is **indirect only**: tail sizing
  returns `S_ht`/`S_vt` and nothing else; the caller writes them into the geometry object, whose own
  `Dependent` properties do the rest (already how `SizingLoopL2` operates today). See §5.2.
- `SizingLoopL2.m`'s `tail (1,1) TailSizingLevel1` constructor type constraint is a **confirmed**
  in-scope change for the implementation loop (must become the shared abstract base). See §3.

---

## 0. Scope

Sizes **only** `S_ht`/`S_vt` (horizontal/vertical **tail reference/exposed/wetted areas**) and
whatever geometric parameters that requires (moment arm, volume coefficients, AR/taper/t/c
*assumptions* where needed). Explicitly **excludes** control-surface sizing (elevator/rudder/aileron
fractions) — that stays `src/sizing/ControlSurfaceSizer.m`, untouched, a separate discipline.

Files to create (per the coordinator's approved structure):

| Tier | File | Role |
|---|---|---|
| 1 (abstract) | `src/base/TailSizingBase.m` | Declares the contract every level implements |
| 2 (abstract enforcer) | `src/disciplines/tail_sizing/TailSizingModelL1.m` | L1-specific abstract additions |
| 2 (abstract enforcer) | `src/disciplines/tail_sizing/TailSizingModelL2.m` | L2-specific abstract additions |
| 2 (abstract enforcer) | `src/disciplines/tail_sizing/TailSizingModelL3.m` | L3-specific abstract additions (TODO-stub, §6) |
| static toolbox | `src/disciplines/tail_sizing/TailL1.m` | L1 volume-coefficient equations |
| static toolbox | `src/disciplines/tail_sizing/TailL2.m` | L2 historical-estimate equations |
| static toolbox | `src/disciplines/tail_sizing/TailL3.m` | L3 stability-and-control equations (TODO-stub, §6) |
| Tier 3 concrete | `examples/F16A/F16TailL1.m` | F-16 wiring, delegates to `TailL1` |
| Tier 3 concrete | `examples/F16A/F16TailL2.m` | F-16 wiring, delegates to `TailL2` |
| Tier 3 concrete | `examples/F16A/F16TailL3.m` | F-16 wiring, delegates to `TailL3` (TODO-stub, §6) |

**Finalized integration contract, all three levels** (§5.2): the abstract method every tier
implements returns exactly `struct('S_ht', S_ht, 'S_vt', S_vt)` — no other fields, no injected
geometry object read back out of it. `TailSizingBase`/`TailSizingModelL{1,2,3}` should declare this
return shape once, at the top of the hierarchy, rather than per level.

---

## 1. Existing-code inventory — what this migrates, what it leaves alone

| File | Status |
|---|---|
| `src/disciplines/tail_sizing/TailSizingLevel1.m` | Migrates into `TailL1`/`TailSizingModelL1`. **Values change** during migration: `c_HT`/`c_VT` become 0.315/0.063, tail arm becomes `0.475*L_fus`, citation becomes Raymer 7th ed. — see §2/§4. |
| `examples/F16A/disciplines/F16TailSizingLevel1.m` | Migrates into `examples/F16A/F16TailL1.m` with the updated 0.315/0.063 wiring. |
| `tests/tail_sizing/TestTailSizingLevel1.m` | Existing green test asserting the OLD 0.40/0.07/`0.5*L_fus` values — will need `test-writer` to update expected values to match the finalized 0.315/0.063/`0.475*L_fus`, not scribe's call to edit but flagged so it isn't missed. |
| `src/disciplines/geometry/GeomL1.m` | **RETIRE** `compute_tail_volume_coeffs`, `lookup_tail_volume_coeffs`, `compute_tail_arm`, `compute_S_HT`, `compute_S_VT` — decided 2026-07-28 (§2). Their logic is what becomes `TailL1` (ported, not duplicated). |
| `src/disciplines/geometry/GeomL1.md` | Remove the corresponding rows/sections (§§2–4 tail-volume entries) once the methods are deleted from `GeomL1.m`. |
| `tests/disciplines/TestGeomL1.m` | Remove `testTailVolumeCoeffsF16`, `testUnknownCategoryTailVolumeThrows`, `testTailArmFormula`, and the `compute_S_HT`/`compute_S_VT`-adjacent tests once the methods move — again a `test-writer`/`geometry-equations-expert` task, flagged here. |
| `src/sizing/SizingLoopL2.m` | **Confirmed in-scope change** (not a scribe edit): `tail (1,1) TailSizingLevel1` → `tail (1,1) TailSizingBase` (or whichever tier is common to L1/L2/L3). See §3. |
| `examples/F16A/design_study_02_L2.m`, `design_study_03_L3.m` | Both currently construct `F16TailSizingLevel1()` regardless of fidelity level. Once `F16TailL2`/`F16TailL3` exist, whether these switch to the matching tier is an implementation-loop decision — not re-litigated here. |
| `tests/sizing/TestSizingLoopL2.m`, `tests/sizing/FixedGeomStub.m` | Existing green tests constructing `TailSizingLevel1(...)` directly — must keep passing or be explicitly superseded by `test-writer`. |
| `src/sizing/ControlSurfaceSizer.m` | **Out of scope**, untouched. |

---

## 2. RESOLVED (2026-07-28) — canonical L1 tail-volume coefficients, retiring the orphaned `GeomL1` implementation

Two implementations of the same L1 volume-coefficient method existed in this repo simultaneously: the
live, tested, actually-wired `TailSizingLevel1.m`/`F16TailSizingLevel1.m` (0.40/0.07, `0.5*L_fus`,
Raymer 6th ed., no text corrections), and an orphaned, never-called, but tested and documented
alternate inside `src/disciplines/geometry/GeomL1.m` (`compute_tail_volume_coeffs`,
`compute_tail_arm`, `compute_S_HT`, `compute_S_VT` — Raymer 7th ed., `0.475*L_fus`, plus RSS and
all-moving-tail text corrections). Logged as a discrepancy in `VnV/BrandtF16A/todo.md` (Finding 2);
**decision made by the user, 2026-07-28** — this is that entry's resolution record.

**Decision: adopt `GeomL1`'s corrected set as canonical.**

| Quantity | Value | Citation |
|---|---|---|
| `c_HT` (jet fighter, base) | 0.40 | Raymer 7th ed. Table 6.4, "Jet fighter" row |
| `c_VT` (jet fighter, base) | 0.07 | Raymer 7th ed. Table 6.4, "Jet fighter" row |
| RSS correction (F-16 has relaxed static stability) | `c_HT, c_VT *= (1 − 0.10)` | Raymer 7th ed. Table 6.4 text |
| All-moving-tail correction (F-16's stabilator) | `c_HT *= (1 − 0.125)` (0.125 = midpoint of the stated 10–15% range) | Raymer 7th ed. Table 6.4 text |
| **F-16 net `c_HT`** | **0.40 × 0.90 × 0.875 = 0.315** | — |
| **F-16 net `c_VT`** | **0.07 × 0.90 = 0.063** | — |
| Tail arm | `L_HT = L_VT = 0.475 * L_fus` (midpoint of the stated 0.45–0.50 range) | Raymer 7th ed., aft-mounted single-engine text rule |

**Consequences, locked in:**
1. `TailL1`'s statics are `GeomL1`'s orphaned methods, ported verbatim (module renamed, not
   re-derived) — `compute_tail_volume_coeffs`/`lookup_tail_volume_coeffs`/`compute_tail_arm`/
   `compute_S_HT`/`compute_S_VT` become `TailL1`'s low-level statics.
2. `GeomL1.m`, `GeomL1.md`, and `TestGeomL1.m` **lose** these methods/rows/tests entirely — tail
   sizing is not geometry's job, and leaving a second, now-stale copy in the geometry toolbox after
   this migration would recreate exactly the discrepancy just resolved. This is an implementation/
   test-writer task (deleting code and tests), not something this doc does, but it is now a locked
   requirement, not an option.
3. `TailSizingLevel1.m`/`F16TailSizingLevel1.m`'s live values update to match during the migration
   into `TailL1`/`F16TailL1` — the migrated class does **not** keep the old 0.40/0.07/`0.5*L_fus`/6th-
   ed. numbers. `TestTailSizingLevel1.m`'s hand-computed expected values will need updating by
   `test-writer` to match (flagged in §1's inventory table).
4. Downstream numeric effect (for the record, not re-derived here): the RSS/all-moving-tail
   corrections *reduce* `c_HT`/`c_VT` further below Raymer's already-low end, which *widens* — not
   narrows — the existing gap against Brandt's `S_ht=108`/`S_vt=60` documented in the current
   `TestTailSizingLevel1.m` header (flat 0.40/0.07 already gives `S_ht≈58.4 ft²` (−46%),
   `S_vt≈27.1 ft²` (−55%) against Brandt; 0.315/0.063 will be lower still). This is an expected,
   accepted consequence of the decision, not a new problem — a historical-average volume-coefficient
   method is not expected to reproduce one specific real aircraft's back-calculated Brandt areas
   tightly, and the comparison report will annotate this, not gate a test on it.

---

## 3. CONFIRMED (2026-07-28) — live downstream consumers this migration affects

`SizingLoopL2.m`'s constructor type-checks its `tail` argument against the **concrete** class:

```matlab
tail (1,1) TailSizingLevel1
```

**Confirmed, in scope for the implementation loop:** this line must change to the new common
abstract base (`TailSizingBase`, or whichever tier ends up shared by `F16TailL1`/`F16TailL2`/
`F16TailL3`) so that L2/L3 tail objects — which will not be `TailSizingLevel1` instances — satisfy
the type check. This is no longer an open question; it is a required part of the
`geometry-equations-expert`/`matlab-oop-expert` implementation pass, called out here so it is not
missed (it lives outside `src/disciplines/tail_sizing/`'s own directory and would otherwise be easy
to overlook).

Also still live and **not** re-litigated by this finalization pass (unchanged from the original
plan, carried forward as context, not new decisions):
- `examples/F16A/design_study_02_L2.m` and `design_study_03_L3.m` both construct
  `F16TailSizingLevel1()` today. Whether they switch to the matching new tier once `F16TailL2`/
  `F16TailL3` exist is left to the implementation loop's judgment.
- `tests/tail_sizing/TestTailSizingLevel1.m`, `tests/sizing/TestSizingLoopL2.m` (via
  `TailSizingLevel1(0.40, 0.07)`-style direct construction) are existing green tests. CLAUDE.md's
  rule 2 (`run_all_tests` green after every step) still applies — `test-writer` updates or
  supersedes these as needed; not resolved by this doc.

---

## 4. L1 — Volume Coefficient Method (FINALIZED values)

**Equations** [Raymer, *Aircraft Design: A Conceptual Approach*, 7th ed., AIAA, 2018, Table 6.4 +
accompanying text — citation and values finalized 2026-07-28 per §2; the underlying `S_HT`/`S_VT`
equation numbering (previously cited as Eq. 6.28/6.29 in the 6th-ed.-cited version of this class) is
carried forward unchanged in form, cited now to the 7th ed. table + text rather than the 6th ed.]:

```
L_HT = L_VT = 0.475 * L_fus
c_HT = 0.40 * (1 - 0.10) * (1 - 0.125) = 0.315     [RSS + all-moving-tail corrections, both apply to the F-16]
c_VT = 0.07 * (1 - 0.10)               = 0.063     [RSS correction only -- no VT-specific text correction in Table 6.4]
S_vt = c_VT * b    * S_ref / L_VT
S_ht = c_HT * cbar * S_ref / L_HT
```

**Inputs:** `S_ref`, `b` (wing span), `cbar` (wing MAC), `L_fus` (fuselage length) — passed as raw
scalars by the caller, unchanged from the current `TailSizingLevel1.size(obj, S_ref, b, cbar,
L_fus)` signature. `GeometryModelL1` has no planform at all (no `b_wing`/`cbar_wing`/`S_ht`/`S_vt` in
its abstract contract — only `W_TO`-regression `S_wet`/`L_fuselage`), so `TailL1` cannot be
geometry-object-driven the way L2/L3 are (§5); the caller (today, `SizingLoopL2`, reading L2+
geometry even when nominally "running L1 tail sizing") supplies the scalars. **No interface change
needed** — recommend keeping the exact `size(obj, S_ref, b, cbar, L_fus)` signature on
`TailSizingBase`/`TailSizingModelL1`, satisfied by `TailL1`'s statics, returning
`struct('S_ht', S_ht, 'S_vt', S_vt)` per §0's finalized contract.

**Aircraft-category corrections** (both baked into the F-16's concrete `c_HT`/`c_VT` at the `F16TailL1`
level — the generic `TailL1` toolbox keeps `compute_tail_volume_coeffs(aircraft_category, has_rss,
has_all_moving_tail)` as a low-level static so a different aircraft's Tier-3 class can apply a
different combination):
- Relaxed static stability (RSS): `c_HT, c_VT *= (1 − 0.10)`. The F-16 is RSS by design (FLCS-era
  fighter) — applies.
- All-moving stabilator: `c_HT *= (1 − 0.125)`. The F-16's horizontal tail is an all-moving
  stabilator (already documented as such throughout `F16GeomL2`/`F16GeomL3` and
  `ControlSurfaceSizer`'s F-16 wiring, where `S_elev=0`) — applies.

**Output:** `struct('S_ht', S_ht, 'S_vt', S_vt)` — lowercase fields, unchanged contract (matches
`GeometryBase`-derived classes' own `S_ht`/`S_vt` casing).

**No geometry-static reuse applies at L1**, unchanged from the original plan: `F16GeomL1` has no
exposed/wetted-area concept for tail surfaces (its only `S_wet` is a whole-aircraft `W_TO`
regression, independent of `S_ht`/`S_vt` entirely).

---

## 5. L2 — "Historical sizing estimates" (FINALIZED method)

### 5.1 Method (RESOLVED 2026-07-28)

Same governing identity as L1 — confirmed **algebraically identical** to two independent textbook
sources already in-repo:

- Raymer 7th ed. Table 6.4 + text (as finalized for L1, §4)
- Nicolai & Carichner Eq. (11.1)/(11.2) [`docs/reference_extracts/11_tail_sizing.md`
  §§11.2–11.3, p. 286, p. 289]: `C_VT = (l_VT·S_VT)/(b·S_ref)`, `C_HT = (l_HT·S_HT)/(c̄·S_ref)` — same
  functional form, solved for the same unknowns.

**Decision: use Nicolai & Carichner's F-16-specific measured coefficient, not a generic category
row.**

```
C_HT = 0.3     [Nicolai & Carichner Table 11.6, "General Dynamics F-16" row, p. 289 --
                docs/reference_extracts/11_tail_sizing.md, the page-cited,
                fully-reproduced extract]
C_VT = 0.094   [same source/row]
```

**Explicitly NOT used:** the conflicting `C_HT=0.68, C_VT=0.041` figure that appears in
`nicolai_data.md`/`roskam_vol2_data.md`/`usaf_f16_data.md` (three reference-digest files in `docs/reference_extracts/`
that mis-transcribe the same Table 11.6 row). That transcription error stays flagged as a known
issue in those three files — fixing them is out of scope for this deep-dive (see
`VnV/BrandtF16A/todo.md` Finding 1, left open/unresolved-elsewhere).

**L2-specific fidelity gain vs. L1:** real wing geometry. L1 has no planform at all
(`GeometryModelL1` carries only a `W_TO` regression); L2 (`F16GeomL2`) has real `b_wing`/
`cbar_wing`/`S_ref`/`L_fus` as live `Dependent` properties (from actual `AR_wing`/`lambda_wing`/
`LE_sweep_wing` inputs). `TailL2`/`F16TailL2` take an **injected `GeometryModelL2` object** (read-only
use — matching the DI pattern `F16WeightsL2` already uses for its geometry collaborator) and read
`geom.b_wing`, `geom.cbar_wing`, `geom.S_ref`, `geom.L_fus` live, rather than the caller
hand-computing scalars as `TestTailSizingLevel1.m` currently does for its Brandt-comparison test.

**Tail moment arm at L2 — carries forward L1's value, unchanged.** `GeometryModelL2` has no
x-station properties at all (no `x_apex_wing`/`x_le_ht`/`x_le_vt` — those first appear on
`GeometryModelL3`), so a genuinely geometry-derived moment arm is not achievable at L2 with today's
inputs. `TailL2` therefore reuses the same `0.475 * L_fus` rule finalized for L1 (§4) — L2's fidelity
gain over L1 is confined to the coefficient source (aircraft-specific vs. generic category) and the
wing-geometry precision, not the arm. (Borrowing L3's x-stations down into L2 to do better remains a
possible future enhancement, out of scope here, as originally noted — not reopened by this
finalization.)

### 5.2 Area reuse mechanism (RESOLVED 2026-07-28 — indirect only)

**Decision: indirect reuse only.** `TailL2`/`TailL3` predict `S_ht`/`S_vt` and return **only**
`struct('S_ht', S_ht, 'S_vt', S_vt)` — the same shape as L1 (§0's finalized contract). No geometry
object is injected *for the purpose of computing exposed/wetted area inside tail sizing*, and no
`get_S_exposed_ht`-style convenience accessor is added to `TailL2`/`TailL3`.

The integration contract is exactly what `SizingLoopL2.m` already does every iteration:
```matlab
tail_result   = tail.size(...);
geom.S_ht     = tail_result.S_ht;
geom.S_vt     = tail_result.S_vt;
```
Because `S_exposed_ht`/`S_wet_ht`/`S_exposed_vt`/`S_wet_vt` (and downstream, aero's `obj.S_wet` and
weights' `obj.S_ht`/`obj.S_vt` reads for Raymer Eq. 15.2/15.3) are all `Dependent` properties on the
`GeometryModelL2`/`GeometryModelL3` concrete classes that recompute live from `obj.S_ht`/`obj.S_vt`
on every read (verified against `GeomL2.m`'s `compute_S_exposed_horizontal`/`compute_S_exposed_vertical`/
`compute_roskam_planform` chain and `AeroL2.get_CD0`'s `obj.S_wet` read), the moment the caller writes
`tail_result.S_ht`/`S_vt` into the geometry object, every downstream consumer automatically reflects
the new area. No direct call from `TailL2`/`TailL3` into `GeomL2`/`GeomL3`'s statics is needed, and
none is implemented. This finding — worked through in the original plan's §5.2 — is what makes the
indirect-only decision sufficient rather than a shortcut: the mechanism was already proven to work
end-to-end (aero and weights both confirmed to read the right live properties) before the decision
was made.

`AR_ht`/`lambda_ht`/`tc_r_ht`/`tc_t_ht`/`LE_sweep_ht` (and VT equivalents) remain geometry's own,
separate, pre-existing input properties, untouched by tail sizing at any level — this was already
correctly out of scope in the original plan and remains so; not reopened here.

### 5.3 L2 inputs/outputs summary (finalized)

| Input | Source |
|---|---|
| `b_wing`, `cbar_wing`, `S_ref`, `L_fus` | injected `GeometryModelL2` object, read live via its `Dependent` properties |
| `C_HT=0.3`, `C_VT=0.094` | Nicolai & Carichner Table 11.6, F-16 row (hardcoded in `F16TailL2`, not a JSON input — same category as `F16TailSizingLevel1`'s current 0.40/0.07 wiring) |
| tail-arm fraction `0.475` | carried forward from L1 (§4) |

| Output | Fields |
|---|---|
| `struct('S_ht', ..., 'S_vt', ...)` | only these two — no exposed/wetted-area fields (§5.2) |

---

## 6. L3 — Stability-and-control-based sizing (Raymer Ch. 16) — FINALIZED as a documented-TODO stub

**Decision (2026-07-28): ship `F16TailL3`/`TailL3`/`TailSizingModelL3` now, as a documented-TODO /
deliberately-failing-test structure — the exception CLAUDE.md's testing rule explicitly allows
("deliberately-failing TODO tests for missing citations... clearly labeled") — rather than blocking
on Raymer Ch. 16 page access or a Nicolai Ch. 21/23 extraction effort.** This mirrors the existing
convention in this repo, e.g. `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`
(`tests/disciplines/TestWeightsL1.m`): a labeled, EXPECTED-red test that documents exactly what
citation is missing, why, and what would resolve it, without inventing a coefficient or an equation
number to make it pass.

**Reaffirmed citation-gap finding (unchanged from the original plan, now the accepted basis for
shipping a stub rather than real equations):** exact Raymer 6th ed. Chapter 16 equation numbers for
(a) sizing `S_HT` from a required static margin/`C_mα`, or (b) sizing `S_VT` from a required
directional-stability derivative, are not verifiable from anything in this repository —
`docs/reference_extracts/` is Nicolai & Carichner, not Raymer, and defers the
closed-form criteria-based equations to its own Ch. 21/23, both "pending" (not extracted);
`raymer_data.md`'s actual Raymer OCR extract has no Ch. 4/6/16 content; `temp_Casey`'s
`SandCLevel3.m` citations ("eq 16.25", "fig 16.3", "fig 16.16") are unverified against the book and
are forward-analysis only; `VnV/BrandtF16A/BrandtBalanceStabControl.m` is likewise forward-analysis
only and not wired to this framework's own weights classes. Full detail in
`VnV/BrandtF16A/todo.md`'s 2026-07-28 Finding 3 (status: RESOLVED-DEFERRED per this decision — see
§7).

**Intended contract/inputs, documented now as best understood, for the TODO stub to target once real
equations exist** (this is design intent for the eventual implementation, not something built now):
- **HT sizing via static margin.** Invert a neutral-point equation of the general form demonstrated
  (uncited-per-equation-number) in `temp_Casey`'s `SandCLevel3.compute_Xbar_np` and
  `BrandtBalanceStabControl.analyze`'s `xnp_ft` formula for `S_HT` given a target static margin
  `SM_required` (or target `C_mα`) and a CG estimate.
- **VT sizing via directional stability.** Nicolai §11.2 (in-repo, citable as narrative, p. 284)
  gives the criteria: subsonic cruise `C_nβ` target 0.08–0.17 rad⁻¹, high-speed (`M>2`) minimum
  `C_nβ=0.08` rad⁻¹. Invert a `C_nβ` buildup (VT contribution + wing/fuselage baseline) for `S_VT`.
- **VT sizing via crosswind landing.** Nicolai §11.2 item 1 — applicable to the F-16, narrative only.
- **One-engine-out yaw balance — SKIPPED.** Not physically applicable to the F-16 (single engine).
  May remain in the generic `TailSizingBase`/`TailL3` contract for other airframes if a future
  aircraft needs it, but `F16TailL3` does not exercise it (parallels `ControlSurfaceSizer`'s
  documented F-16 all-moving-tail exception to Table 6.5).

**Decision: do NOT add new inputs yet.** The following were identified as required for the equations
above but are **deliberately deferred**, per the coordinator's instruction, until real Raymer Ch. 16
equations are actually implemented — `io` must **not** add placeholder values for these now:
- CG range (forward/aft limits) or a converged `x_cg` — no `f16a_requirements.json` field, no new
  cross-discipline injection from weights/balance.
- Target static margin `SM_required` (or target `C_mα`) — no `f16a_requirements.json` field.
- Target `C_nβ,required` — no `f16a_requirements.json` field (even though the *narrative* target
  range is citable to Nicolai §11.2 today, the numeric requirement is not being wired in yet).
- Crosswind design condition (max crosswind velocity) — no `f16a_requirements.json` field.
- A new `TailL3`-injects-`aero` DI pattern (to read `CL_α`, downwash `dε/dα`) — deferred; no
  discipline in this framework currently injects an aero object into anything, and this would be a
  new architectural pattern, not just a new input.

**What the TODO stub should look like** (guidance for the implementation loop, not built here):
`TailSizingModelL3` declares the same `size(...) -> struct('S_ht','S_vt')` abstract contract as
L1/L2 (§0); `TailL3`'s statics either error with a clear "citation not available, see
`VnV/BrandtF16A/todo.md` 2026-07-28 Finding 3" message or return `NaN`, matching whichever of this
repo's two existing TODO idioms (`GeomL1.lookup_control_surface_fraction`'s `error(...)` for the
missing aileron fraction, vs. `TestWeightsL1`'s red-assertion-on-a-standing-comment style) the
`test-writer`/`geometry-equations-expert` pair judges more appropriate at implementation time; a
companion `tests/disciplines/TestTailL3.m` (or wherever `test-writer` places it) carries a
deliberately-red `testTODO_RaymerChapter16EquationsNotInRepo`-style test, following the
`TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` template exactly (EXPECTED RED, labeled,
references this doc and the todo.md entry, does not invent a passing value).

---

## 7. Discrepancies logged to `VnV/BrandtF16A/todo.md` (2026-07-28) — status after finalization

Full entries are in that file. Status updated 2026-07-28 per the coordinator's decisions:

### 7.1 — Nicolai & Carichner F-16 tail-volume-coefficient value: propagation error across three reference data-digest files
**Status: still OPEN / unresolved elsewhere — out of scope for this deep-dive.** `nicolai_data.md`,
`roskam_vol2_data.md`, and `usaf_f16_data.md` still carry the incorrect `C_HT=0.68, C_VT=0.041`
figure; only the correct, page-cited `11_tail_sizing.md` value (`C_HT=0.3, C_VT=0.094`) is used by
this plan (§5.1). The three digest files themselves are not being corrected as part of this work.

### 7.2 — Competing, disagreeing L1 tail-sizing implementations within this repo's own `src/`
**Status: RESOLVED 2026-07-28.** Decision: adopt `GeomL1`'s corrected set (`c_HT=0.315, c_VT=0.063`,
Raymer 7th ed., tail arm `0.475*L_fus`) as canonical; retire the orphaned methods from `GeomL1.m`/
`GeomL1.md`/`TestGeomL1.m`; port their logic into the new `TailL1` toolbox; update
`TailSizingLevel1`/`F16TailSizingLevel1`'s values to match during migration. Full record in §2 above.

### 7.3 — Raymer Ch. 16 (stability-and-control tail sizing) has no verifiable equation numbers anywhere in this repository
**Status: RESOLVED-DEFERRED 2026-07-28.** Decision: proceed with `F16TailL3`/`TailL3`/
`TailSizingModelL3` as a documented-TODO / deliberately-failing-test structure now, rather than
blocking on Raymer Ch. 16 page access or a Nicolai Ch. 21/23 extraction effort. New
`f16a_requirements.json` fields and the Tail→Aero DI pattern that real equations would need are
explicitly deferred, not added speculatively. Full record in §6 above.

---

## 8. Decision record (finalized 2026-07-28)

All open items from the original plan's §8 are now resolved:

1. **L1 coefficients/arm/edition** (§2/§4): `c_HT=0.315`, `c_VT=0.063` (Raymer 7th ed. Table 6.4 base
   0.40/0.07 with RSS + all-moving-tail corrections), tail arm `0.475*L_fus`. Orphaned `GeomL1`
   methods retired; their logic becomes `TailL1`.
2. **`SizingLoopL2.m` type constraint** (§3): confirmed in scope — `tail (1,1) TailSizingLevel1` →
   `tail (1,1) TailSizingBase` (or the shared tier), implementation-loop task.
3. **L2 coefficient source** (§5.1): Nicolai & Carichner Table 11.6 F-16-specific row, `C_HT=0.3`,
   `C_VT=0.094` — not the generic Raymer category row, not the conflicting 0.68/0.041 figure.
4. **L2/L3 area-reuse mechanism** (§5.2): indirect only — `size()` returns `struct('S_ht','S_vt')`
   only, at every level; no injected geometry object inside tail sizing, no direct-reuse accessor.
5. **L3 approach** (§6): ship now as a documented-TODO / deliberately-failing-test structure,
   conceptual contract documented, new requirements-file fields and Tail→Aero DI deferred until real
   equations exist.

Nothing remains open in this doc. Next step (per the coordinator): bring in the `io` agent to turn
this into the L1/L2 JSON inputs (`F16TailL2`'s Nicolai coefficients, `F16TailL1`'s corrected
coefficients) and the Brandt ground-truth comparison JSON — L3 produces no new JSON inputs yet, per
§6's deferral.
