# GeomL2.m — companion doc

## 2026-07-22 — L3 tier eliminated for Geometry; merged into this file
**User decision:** Geometry no longer has an L3 fidelity tier. Unlike Aerodynamics/Propulsion/
Weights (which keep their existing L1/L2/L3 structure), Geometry now has **only L1 and L2**.
This is Geometry-specific — no other discipline's tiering changed.

**Rationale:** the former `GeomL3` added exactly two things beyond `GeomL2`: (a) a variable
root/tip thickness-ratio version of the lifting-surface wetted-area formula (Roskam Vol. II
Eq. 12.1, vs. `GeomL2`'s uniform-tc Brandt formula), and (b) an inlet/duct component. Neither
is "meaningfully higher fidelity" in a way that justifies a whole separate tier — both are now
folded into `GeomL2` as **additional, separately-citable named methods**, alongside the existing
uniform-tc Brandt formula and the already-approved-but-not-yet-implemented Brandt low-fi/high-fi
fuselage formulas (see the Task 2 section below). This mirrors the pattern already established
for the fuselage-formula-options work: `GeomL2` ends up with multiple named static methods for
the same physical quantity (e.g. three lifting-surface wetted-area options, three fuselage
wetted-area options), rather than multiple fidelity tiers.

This file is the merge of the former `GeomL2.md` and `GeomL3.md` (`GeomL3.md` is deleted; its
content lives entirely below). The former L2-only content is unchanged; the former L3-only
content (Roskam Eq. 12.1, the duct/inlet frustum formula) is folded in as additional method
options, clearly marked below as "(moved from former L3)". The "Main-tab computed fields
(aileron/LE-flap/TE-flap)" section that used to appear in this file has been **removed entirely**
per a separate user decision — that work is out of scope now, not deferred, not a TODO, just
dropped. (It is not carried forward anywhere; see `VnV/BrandtF16A/todo.md` Finding 5 if the raw
Excel-formula research is ever needed again.)

**Instruction for implementation-loop agents:** when this documentation is implemented in code,
the following files must be **deleted**, not left as legacy/orphaned code — their content has
already moved into their L2 equivalents:
- `src/disciplines/geometry/GeometryModelL3.m` → merge any still-needed abstract contract
  (HT/VT full property sets, `get_S_wet_duct`, `get_S_exposed_wing`) into `GeometryModelL2.m`
- `src/disciplines/geometry/GeomL3.m` → its statics (`compute_roskam_planform`,
  `compute_s_wet_duct`, `get_S_wet_duct`, `get_S_exposed_wing`) move into `GeomL2.m`
- `examples/F16A/F16GeomL3.m` → its properties/methods (HT/VT detail, duct) move into
  `F16GeomL2.m`
- `tests/disciplines/TestGeomL3.m` → its test cases move into `TestGeomL2.m`

Do not leave any of the four files above in the tree after implementation, and do not leave a
`GeometryModelL3`/`GeomL3`/`F16GeomL3` class reachable from anywhere in `src/`, `examples/`, or
`tests/`.

---

Tier-3-adjacent static toolbox (`classdef GeomL2`, all `methods (Static)`). Not in the
inheritance chain. Called as `GeomL2.method(...)`. Implements Level-2 component-level wetted
areas from exposed-planform areas and thickness ratios — both the original uniform-tc surface
set (wing/HT/VT/fuselage) and, as of the L3 merge above, the variable-tc lifting-surface option
and the inlet/duct component that used to live in `GeomL3.m`.

## Methods in this file

### High-level (take the student object)

| Method | Computes | Citation |
|---|---|---|
| `get_S_wet(obj, ~)` | Sum of wing + HT + VT + fuselage `S_wet` (plus duct, for a concrete class that has one — see note below) | (aggregator — no equation of its own) |
| `get_S_wet_wing(obj)` | Wing `S_wet` from `obj.S_exposed_wing`, `obj.tc_wing` | see `compute_wet_planform` below |
| `get_S_wet_HT(obj)` | HT `S_wet` from `obj.S_exposed_ht`, `obj.tc_ht` | see `compute_wet_planform` below |
| `get_S_wet_VT(obj)` | VT `S_wet` from `obj.S_exposed_vt`, `obj.tc_vt` | see `compute_wet_planform` below |
| `get_S_wet_fuselage(obj)` | Fuselage `S_wet` from `obj.D_fus`, `obj.L_fus` | see `compute_s_wet_fus_cyl` below |
| `get_S_wet_duct(obj)` *(moved from former L3)* | Duct `S_wet` from `obj.D_inlet`, `obj.D_exit`, `obj.L_duct` | Raymer 6th ed., §7.3 (frustum lateral-area formula) |
| `get_S_exposed_wing(obj)` *(moved from former L3)* | Passthrough — returns `obj.S_exposed_wing` unchanged | none — not a computation, just a property accessor |

**Note on `get_S_wet` post-merge:** the former `GeomL2.get_S_wet` summed wing+HT+VT+fuselage
only; the former `GeomL3.get_S_wet` summed wing+HT+VT+fuselage+duct. Once merged, `GeomL2.m`'s
aggregator should include the duct term (matching the former L3 behavior) since the duct method
now lives in this same file — implementation should decide whether the duct term is
unconditionally included or only added when the concrete class actually defines duct properties
(the former L2-tier concrete classes, e.g. a hypothetical simpler F-16 model, had no duct
properties at all). Flagging as an implementation decision, not resolving here.

### Low-level (pure math, scalars/arrays only)

| Method | Computes | Citation |
|---|---|---|
| `compute_wet_planform(S_exp, tc)` | `S_wet = S_exposed * (1.977 + 0.52*tc)` (uniform t/c) | **Brandt F-16A workbook, Geom sheet, cell B13** (this is Brandt's own lifting-surface formula, not an independent Roskam/Raymer citation) |
| `compute_roskam_planform(S_exp, tc_r, tc_t, lambda)` *(moved from former L3)* | `S_wet = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda))` (variable root/tip t/c) | Roskam Vol. II, Eq. 12.1 |
| `compute_s_wet_fus_cyl(D_fus, L_fus)` | `S_wet = pi*D*L*(1-2/lambda_f)^(2/3)*(1+1/lambda_f^2)`, `lambda_f = L/D` | Roskam, *Airplane Design Vol. II*, Eq. 12.3 |
| `compute_s_wet_duct(D_inlet, D_exit, L_duct)` *(moved from former L3)* | Lateral area of a right circular frustum: `pi*(r1+r2)*sqrt((r2-r1)^2+L^2)` | Raymer 6th ed., §7.3 — degenerates to `pi*D*L` for a constant-section duct |

`compute_wet_planform` and `compute_roskam_planform` are two options for the same physical
quantity (lifting-surface wetted area) — the former assumes uniform thickness ratio across the
span (Brandt's own approach), the latter allows a variable root/tip split (Roskam's more
detailed formula). Neither replaces the other; a caller picks whichever fits the data it has.

**RESOLVED (2026-07-22, user decision):** `get_S_wet_wing`/`get_S_wet_HT`/`get_S_wet_VT` (the
required `GeometryModelL2` abstract-method answers) delegate to `compute_roskam_planform` (Eq.
12.1, variable root/tip tc) as the **official** result — it's a strict generalization of
`compute_wet_planform` (uniform-tc is the special case `tc_root=tc_tip`), and was already the
higher-fidelity former-L3 answer. `compute_wet_planform` (Brandt's uniform-tc formula) stays
available as a named alternate method for the comparison report, not removed.

## Notes on `compute_wet_planform`
The formula (`S_wet = S_exposed*(1.977 + 0.52*tc)`) matches the Raymer-family lifting-surface
wetted-area formula documented independently in `VnV/BrandtF16A/readme_geom.md` §4.3 as "Raymer
formula (confirmed from Geom tab)" — Brandt's own workbook uses this same closed form for wing,
strake, and pitch-control S_wet at cells `Geom!B14:B17` (verified live against
`Brandt-F16-A.xls`, see Task 4 findings / `VnV/BrandtF16A/todo.md`). The two citations (this
file's "Brandt F-16A workbook Geom!B13" and `readme_geom.md`'s "Raymer formula") describe the
same equation from two angles — Brandt's workbook cell vs. the textbook formula it implements —
not a conflict.

## Guard gaps (coding-practice note, not equation errors)
**FIXED (2026-07-22, OOP/coding-practice pass):** both gaps below are now guarded in code.
- `compute_s_wet_fus_cyl` is only valid for fineness ratio `lambda_f = L/D > 2`; unguarded, a
  short/wide fuselage input (`lambda_f <= 2`) would return a **complex number** with no error
  (flagged independently in `docs/darshan-verification/2026-07-21_steps_01-05_review.md`,
  `GeomL2.m:53-60` entry). Now guarded: an `arguments` block enforces `D_fus`/`L_fus` positive,
  and an explicit `if lambda_f <= 2 ... error('GeomL2:invalidFinenessRatio', ...)` check runs
  before the fractional-power formula.
- `compute_roskam_planform` *(moved from former L3)* divides by `(1+lambda)` and by
  `(tc_r/tc_t)`; a zero tip t/c (`tc_t=0`) used to silently return `Inf` (same review, former
  `GeomL3.m:58-65` entry). Now guarded: an `arguments` block requires `tc_r`/`tc_t` strictly
  positive (`mustBePositive`) and `lambda` nonnegative (guards the `(1+lambda)` denominator too).
- The former `GeomL3.m` duplicated `compute_s_wet_fus_cyl` verbatim rather than sharing `GeomL2`'s
  copy (flagged in the same review, former `GeomL3.m:67-74` entry). Post-merge this duplication
  is moot — there is only one `compute_s_wet_fus_cyl` in the merged file — but noting it here so
  the history isn't lost.

---

## Task 2 — L2 tier: existing implementation vs. planned Brandt additions

### `compute_wet_planform` already IS Brandt's formula — no duplicate needed
As noted above, `GeomL2.compute_wet_planform` already implements the same lifting-surface
formula Brandt's own workbook uses (`Geom!B14:B17`, per `readme_geom.md` §4.3 and confirmed
live against the `.xls`, see `VnV/BrandtF16A/todo.md`). **A later phase should NOT add a
separate `compute_wet_planform_brandt` method** — this one already is that method. The only gap
is that `S_exposed_wing`/`S_exposed_ht`/`S_exposed_vt` are currently hand-frozen literals in
`F16GeomL2` (formerly also duplicated in `F16GeomL3`, now merged) rather than computed (see
`F16GeomL2.md`) — that is a Tier-3-class gap, not a `GeomL2.m` toolbox gap.

### `compute_roskam_planform` (Roskam Eq. 12.1, variable root/tip tc) *(moved from former L3)*
`GeomL2.compute_roskam_planform`'s formula is a **different, more detailed** formula than
`compute_wet_planform` (constant-tc closed form) — it adds variable root/tip thickness. This was
previously documented as "the intended L2→L3 fidelity progression"; per the 2026-07-22 decision
above, it is now simply a second named option living alongside `compute_wet_planform` in the
same file, not a separate fidelity tier. It is already a genuine textbook citation distinct from
Brandt's own formula, so there is no "Brandt has its own separate formula" question to resolve
for this one the way there is for the fuselage S_wet (below).

### Fuselage S_wet: Brandt has a SEPARATE, additional method (candidate for a later phase)
The current `compute_s_wet_fus_cyl` implements the Roskam Vol. II Eq. 12.3 cylindrical-midsection
formula. Brandt's Geom tab computes fuselage S_wet with two of its **own**, different formulas —
neither of which is Roskam Eq. 12.3. Per `VnV/BrandtF16A/readme_geom.md` §4.1 (cross-checked live
against `Brandt-F16-A.xls`, see Task 4 findings):

**Low-fidelity ("1/3-cone + 2/3-cylinder" approximation, per Brandt's own workbook label)** —
`Geom!B3`, live value 730.422 ft²:
```
D_avg = (max_width + max_height) / 2
S_wet = (5/6) * pi * D_avg * L_fuse
```
Verified live: `Geom!C3` (the cell immediately next to `B3`) literally contains the text
"1/3 Cone and 2/3 Cylinder approximation" — `readme_geom.md` §4.1's naming matches the live
workbook's own label exactly (not a mislabel). The `5/6` numeric coefficient in the area formula
is simply what falls out of integrating that named geometric assumption (conical nose section +
cylindrical afterbody) — it is not meant to equal "1/3" itself, so there is no inconsistency
between the label and the formula's leading constant.

**High-fidelity (frame-integration)** — `Geom!D23`, live value 676.3289 ft²:
```
S_wet = sum over frames of (P_i + P_{i+1})/2 * dx_i    (trapezoidal integration of per-frame perimeter)
```
Per-frame perimeter uses a cosine cross-section model (`readme_geom.md` §4.2) driven by 20
fuselage frames' `(x, z_chine, z, w, h)` data (`VnV/BrandtF16A/GroundTruth/f16a_geometry.json`,
`fuselage.frames`).

**RESOLVED (2026-07-21, user decision, `VnV/BrandtF16A/todo.md` Finding 3):** the fuselage
S_wet ground truth is confirmed as `Geom!B3` (low-fi, 730.422) / `Geom!D23` (high-fi, 676.3289) —
not `Geom!A3`/`A4`, which are label cells, not a second value pair. This is the target the new
methods below and any comparison report should validate against.

**Recommendation for the next phase:** add these as new, separately-named static methods (e.g.
`compute_s_wet_fus_brandt_lowfi`, `compute_s_wet_fus_brandt_highfi`) alongside the existing
`compute_s_wet_fus_cyl` — as an *additional option*, not a replacement. The Roskam Eq. 12.3
method stays; Brandt's methods become alternatives a caller can select. (Now that L3 no longer
exists, this applies uniformly — there is no separate L3 fuselage method to also update.)

### Lifting-surface exposed-area computation — NOT implemented anywhere today
`S_exposed_wing`, `S_exposed_ht`, `S_exposed_vt` are hardcoded literals on the F16GeomL2
Tier-3 object (see `F16GeomL2.md`; formerly also on `F16GeomL3`, now merged) — nowhere in
`GeomL2.m` is there a method that actually computes an exposed area from a full-span planform +
fuselage width/height. Brandt's own workbook computes this (`readme_geom.md` §4.3, confirmed
live at `Geom!A5:I10`, see Task 4):

**Horizontal surfaces (wing, pitch control/stabilator, strake)** — boundary = fuselage
**half-width**:
```
fw         = max_width / 2
c_exp_root = c_root - (fw/hs) * (c_root - c_tip)
hs_exp     = hs - fw
S_exposed  = (c_exp_root + c_tip)/2 * hs_exp * 2      (both panels, mirrored)
```

**Vertical tail** — boundary = fuselage **half-height** (not half-width), full span, single
panel (no mirroring):
```
fh          = max_height / 2
b_vt        = sqrt(S * AR)
c_exp_root  = c_root - (fh/b_vt) * (c_root - c_tip)
span_exp    = b_vt - fh
S_exposed   = (c_exp_root + c_tip)/2 * span_exp
```

**Recommendation for the next phase:** implement this as a new method (e.g.
`compute_S_exposed_horizontal(...)` / `compute_S_exposed_vertical(...)`) — there is no existing
equivalent in `GeomL2.m` to preserve or duplicate; this is a genuinely new capability.

### Duct/inlet frustum formula *(moved from former L3, now an additional L2 component)*
`compute_s_wet_duct` (Raymer 6th ed. §7.3) computes the lateral surface area of the
inlet/engine duct as a right circular frustum between the inlet face diameter and the exit
(engine-face) diameter:
```
S_wet = pi*(r1+r2)*sqrt((r2-r1)^2+L^2)     [r1=D_inlet/2, r2=D_exit/2, L=L_duct]
```
This degenerates to `pi*D*L` (a simple cylinder) when `D_inlet == D_exit`. As of the 2026-07-22
merge decision, this is available to any `GeomL2`-based concrete class as an optional additional
component in its `get_S_wet` aggregation — not something that requires a separate fidelity tier.
The F-16's own duct dimensions (`D_inlet`, `D_exit`, `L_duct`) remain T.O.-based estimates, not
Brandt-sourced values (see `examples/F16A/F16GeomL2.md`).
