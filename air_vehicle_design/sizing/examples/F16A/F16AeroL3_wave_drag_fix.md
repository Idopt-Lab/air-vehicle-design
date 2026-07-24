# F16AeroL3.m — supersonic wave-drag fix (companion doc)

**Status: documentation only.** This file specifies what should change in
`examples/F16A/F16AeroL3.m`'s `compute_CD0_wave` (and its call site
`get_CD0_buildup`) plus one open sourcing question (canopy). No `.m` file has
been edited. Gated on user approval before `geometry-equations-expert` /
`matlab-oop-expert` implement it.

Scope: `examples/F16A/F16AeroL3.m` only. `src/disciplines/aerodynamics/AeroL3.m`
(the shared L3 toolbox) is confirmed correct as-is — no change needed there
(see "Confirmation 1" below).

---

## 1. Corrected equation set

### Eq. 12.41 — overall CD0 buildup (already implemented correctly; citation
### on the *wave term itself* is what's wrong, not this)

Raymer 6th ed. Eq. 12.41 (supersonic CD0 buildup):
```
CD0_supersonic = SUM_c( Cf_c * FF_c * Q_c * S_wet_c ) / S_ref
                  + CD0_misc + CD0_L&P + CD0_wave
```
i.e. the same per-component skin-friction sum used subsonically, plus three
*additive, independent* terms: miscellaneous drag (Table 12.7 items),
leakage/protuberance allowance, and wave drag due to volume.

**Confirmation 1 (re-read both files, not taken on faith):**
- `AeroL3.get_CD0_buildup` (`src/disciplines/aerodynamics/AeroL3.m:192-218`)
  computes exactly `SUM_c(cf_eff*FF*Q*S_wet)/S_ref + obj.CD0_misc +
  obj.CD0_LandP` — the skin-friction-sum + misc + L&P part of Eq. 12.41's
  shape. Confirmed by direct read; this file's own header comment (line 26)
  already cites this line "Eq 12.41", which is correct.
- `F16AeroL3.get_CD0_buildup` (`examples/F16A/F16AeroL3.m:291-307`) calls the
  above, then adds `obj.compute_CD0_wave(state)` when `state.mach >= 1.2` —
  completing the fourth term, `CD0_wave`. Confirmed by direct read.
- So the **overall Eq. 12.41 shape is already correctly implemented** across
  `AeroL3.m` + `F16AeroL3.m` together. Nothing about the buildup structure
  needs to change. The bug is narrower: `compute_CD0_wave`'s own docstring
  (line 311) cites **the wave-drag formula itself** as "Eq. 12.41," which is
  wrong — 12.41 is the outer sum this term gets added into, not the formula
  for the term. That mislabel is what needs fixing, in `compute_CD0_wave`
  and in the `get_CD0_buildup` override's comment (line 294) that repeats it.

### Eq. 12.44 — Sears-Haack minimum-wave-drag body
```
(D/q)_Sears-Haack = (9*pi/2) * (Amax/l)^2
```
- `Amax` — maximum cross-sectional area of the **whole aircraft** (not one
  component), ft².
- `l` — overall aircraft length, ft.

### Eq. 12.45 — wave drag with Raymer's empirical area-ruling/sweep correction
```
(D/q)_wave = E_WD * [ 1 - 0.386*(M-1.2)^0.57 * (1 - (pi*Lambda_LE_deg^0.77)/100) ]
             * (D/q)_Sears-Haack
```
`CD0_wave = (D/q)_wave / S_ref`. Valid for `M >= 1.2` (the `(M-1.2)^0.57` term
is undefined below that Mach) — matches the existing `state.mach >= 1.2` gate
in `get_CD0_buildup`, no change needed there.
- `E_WD` — empirical wave-drag efficiency factor (1.0 = perfectly area-ruled
  Sears-Haack body); already a correctly-cited class constant
  (`F16AeroL3.m:106-114`, `E_WD=2.2`, cross-checked against
  `temp_AI/docs/disciplines/01_aerodynamics.md` §5 and `temp_Casey`'s
  independently-hardcoded same value). **No change needed to `E_WD`.**
- `Lambda_LE_deg` — wing leading-edge sweep (already an existing, correctly
  cited class property, `40°` `[T.O. 1F-16A-1, Fig. 1-2]`). **No change
  needed.**

**Corroboration (temp_Casey, read-only reference):** `temp_Casey/src/Level_III_Fidelity/Aerodynamics/Drag_Polar_III.m:400-401`
and `temp_Casey/src/Level_IV_Fidelity/Aerodynamics/Drag_Polar_IV.m:410-411`
both cite this exact Eq. 12.44/12.45 split explicitly (`% eq 12.44, 6th ed`,
`% eq 12.45, 6th ed`) for the same two-formula decomposition, and both sum
`CD0_supersonic = Component_Drags_sup/S_ref + CD_misc + CD_LandP + CD_wave`
— the identical four-term Eq. 12.41 shape confirmed above. This independently
corroborates the corrected citations (12.44/12.45), even though temp_Casey
itself never labels the outer sum "12.41" in a comment. Note also:
temp_Casey's own `Dq_searshaack`/`Dq_wave` (same two files) compute
`A_max = pi*(D_fus/2)^2` and use `l = L_fus` (fuselage-only, not whole-aircraft)
— **the same fuselage-only-cylinder bug** `F16AeroL3.compute_CD0_wave` has
today. This is a case of the framework's from-scratch F-16 class inheriting a
known temp_Casey approximation rather than an independent framework bug — see
Item 2 below for the fix, which does not appear anywhere in temp_Casey.

---

## 2. The Amax / l bug and its fix

### Current (buggy) code
`examples/F16A/F16AeroL3.m:309-330`, `compute_CD0_wave`:
```matlab
l_fus = obj.l_ref_comp(4);          % = 47.5 ft  (fuselage COMPONENT length only)
D_fus = obj.D_comp(4);              % = 5.0 ft
A_max = pi * (D_fus/2)^2;           % = 19.635 ft^2  (crude fuselage-only cylinder)
```
Two problems, both flagged by the class's own citation reasoning at
line 318-322 ("A_max/l come from this class's own fuselage component... genuine
T.O. 1F-16A-1 geometry already used elsewhere") — that reasoning is the bug:
1. **`A_max` should be the whole-aircraft maximum cross-section**, not a bare
   circle from the fuselage's own diameter. A real aircraft's max
   cross-section station also carries wing/tail/nacelle cross-sectional area
   at that x — Raymer's Sears-Haack term is a **whole-vehicle** slender-body
   result, not a fuselage-only one (see "important physics note" below).
2. **`l` should be overall aircraft length** (nose to the aftmost point —
   fuselage, nozzle, or vertical-tail trailing edge, whichever is furthest
   aft), not the fuselage component's own 47.5 ft. `l_ref_comp(4)`'s 47.5 ft
   is correct and should **stay unchanged** as the fuselage body's own
   reference length for `FF_body`/`Re` in the skin-friction buildup (Raymer
   Eqs. 12.25/12.28/12.29/12.31) — it is simply the wrong length scale for
   the wave-drag term specifically. Do not conflate the two.

### Correct values and citation chain
Sourced from `VnV/BrandtF16A` (Brandt's own F-16A ground truth), verified at
three independent levels that all agree:

| Level | Amax | l (aircraft length) | Source |
|---|---|---|---|
| Live `Brandt-F16-A.xls` cell, confirmed live 2026-07-21 via `actxserver`/COM read | **25.1106 ft²** (`Geom!B20`, label "Total Aircraft Amax:"; `Geom!H47` holds the same value — see note below) | **48.3039 ft** (`Geom!B21`, label "Total Aircraft Length:") | `VnV/BrandtF16A/GroundTruth/geometry_comparison_values.json` `Amax_ft2`/`aircraft_length_ft` entries |
| `BrandtGeometry.m`'s independent from-scratch MATLAB replica | **25.110556 ft²** (`computeAmax()`, `BrandtGeometry.m:996-1069`) | **48.304 ft** (`aircraft_length_ft`, computed `BrandtGeometry.m:108-111`) | `BrandtGeometry.m` (own computation, not a copy of the Excel value) |
| Validated agreement | +0.002% | 0.000% | `VnV/BrandtF16A/readme_geom.md` §8, Table 2 ("Amax: 25.111 computed vs 25.110 GT, +0.002%, PASS"; "Aircraft length: 48.304 vs 48.304, 0.000%, PASS") |

Both numbers round-trip to the same value at every level checked — this is
**not** a discrepancy needing a `todo.md` entry (see §6).

**`Amax` derivation (why it's not just the raw whole-aircraft peak):**
`BrandtGeometry.computeAmax()` (`BrandtGeometry.m:996-1069`) replicates
`Geom!H26:H47`, a 20-frame area-ruled cross-section table summing, at every
fuselage x-station, the fuselage + wing + pitch-control(stabilator) + vertical
tail + strake + nacelle cross-sectional areas present at that station
(`A_total = A_fuse + A_wing + A_pitch + A_vert + A_strake + A_nac`,
`BrandtGeometry.m:1058`). The raw peak of that table is **~32.971 ft²** (near
x≈29.1 ft, per `readme_geom.md` §4.5). Brandt's `Geom!H47`/`B20` result then
**subtracts the engine inlet flow-through area**,
`N_eng*pi*D_eng²/5.0 = pi*3.537²/5.0 ≈ 7.860 ft²` (`BrandtGeometry.m:1067-1068`,
`D_eng≈3.537 ft` from `computeNacelle()`), giving the final
`25.110556 ≈ 32.971 − 7.860` ft². **User-confirmed choice:** use this
flow-through-corrected value (25.110556), not the raw peak (~32.971) — air
passing through the engine is not displaced volume for wave-drag purposes, so
the physically correct Raymer `Amax` for an air-breathing vehicle excludes the
inlet capture area.

`l` derivation: `aircraft_length_ft = max(fuselage.length_ft, nozzle_x_ft,
vert_tail.x_te_tip_ft)` (`BrandtGeometry.m:110-111`) = 48.304 ft — this is the
true overall-vehicle length (the aftmost of: fuselage end, engine nozzle exit
station, or vertical-tail trailing-edge-at-tip station), not the fuselage
component's own 46.5 ft (`Geom!B32`, Brandt's raw fuselage-length input) or
`F16AeroL3`'s existing 47.5 ft fuselage-component figure.

**On the `Geom!H26:H45` vs `Geom!H26:H47` range language in `BrandtGeometry.m`'s
own comments** (line 999: "Replicates Geom H26:H47"; line 1007: "Amax =
MAX(H26:H45)"): checked and **not a conflict** — `H26:H45` is the range of
per-frame area values being maxed over; `H47` is the single result cell that
*holds* `MAX(H26:H45)` minus the inlet correction (confirmed against
`GroundTruth/cell-map.md:27-28`: `Geom!H47` = "Amax (ft²)" / `Geom!H26:H45` =
"Per-frame cross-section areas" — two different, non-conflicting things,
correctly both cited in the same function). No `todo.md` entry warranted for
this.

**Important physics note (also resolves part of Item 3's canopy question,
§4):** Raymer's Eq. 12.44/12.45 wave-drag-due-to-volume term is **not**
additive per component the way the skin-friction buildup is — it is a single
whole-vehicle `Amax`/`l` pair from slender-body (supersonic area rule) theory.
There is no separate "wing wave drag" or "canopy wave drag" term to add on
top of it the way there is a separate wing/HT/VT/fuselage/duct term in the
skin-friction sum. Once `Amax` is sourced from Brandt's whole-aircraft
cross-section table (which already sums wing+tail+strake+nacelle area at the
governing station), the wing/tail/nacelle contribution to wave drag is
already captured. This means `tests/disciplines/TestAeroL3.m`'s existing
comments (lines 118, 178-179: "no wing/boat-tail/canopy wave-drag terms")
describe the **current pre-fix** state correctly, but will become partly
inaccurate once this fix lands — flagging for whoever next touches that test
file's comments/tolerances, not changing the test here (scribe does not edit
`.m` files).

### Quantified effect of the fix (informational — not a test assertion)
```
Current (buggy):   A_max/l = 19.635/47.5  = 0.41337   -> (A_max/l)^2 = 0.17087
Corrected:         A_max/l = 25.110556/48.304 = 0.51988 -> (A_max/l)^2 = 0.27027
```
The `(Amax/l)^2` factor increases by **≈+58%** holding `M`, `E_WD`,
`Lambda_LE_deg` fixed — i.e. `CD0_wave` roughly increases by that same factor
(the bracketed Raymer sweep/Mach correction is unchanged by this fix). This
should reduce (not necessarily close) the existing under-prediction
`TestAeroL3.testCD0AtBrandtMachPoints` documents at rows 4-5 (M=1.5, 2.0:
currently ~−28%/−30% vs. Brandt after the wave-drag term was first added,
per that test's own comment, lines 177-181). Re-verifying the exact new gap
is a `test-verifier` job once implemented, not asserted here.

### Recommended property additions (plain inputs, not Dependent)
Per CLAUDE.md's input-vs-derived split: these are genuine, independently-
sourced spec/ground-truth constants for this F-16 example — not computed from
any of `F16AeroL3`'s own other properties — so they belong as new entries in
the existing plain `properties` block, the same way `l_ref_comp`/`D_comp`
already are, **not** as `Dependent` getters and **not** as a live read from a
`BrandtGeometry` object at runtime (per the task framing: `F16AeroL3` is the
framework's own from-scratch textbook implementation, independent of the
`VnV/BrandtF16A` replica; it hardcodes its own sourced constants the way it
already does for every other geometry input in this class).

```matlab
Amax_ft2      = 25.110556  % ft^2  whole-aircraft max cross-section, net of
                            %       engine flow-through area [Brandt Geom!B20/H47,
                            %       25.1106 ft^2 live; BrandtGeometry.m computeAmax()
                            %       independently reproduces 25.110556, +0.002%]
L_aircraft_ft = 48.304     % ft    overall aircraft length (nose to aftmost of
                            %       fuselage/nozzle/VT-TE) [Brandt Geom!B21,
                            %       48.3039 ft live; BrandtGeometry.m
                            %       aircraft_length_ft reproduces 48.304, 0.000%]
```
(Exact literal precision — 25.110556 vs. 25.1106 vs. 25.11 — is an
implementation-phase style choice; all three are the same number at
different rounding. Not resolving that choice here.)

### Corrected `compute_CD0_wave`
```matlab
function val = compute_CD0_wave(obj, state)
%COMPUTE_CD0_WAVE  Supersonic wave drag due to volume distribution.
%   Raymer 6th ed. Eq. 12.44 (Sears-Haack) + Eq. 12.45 (E_WD/sweep/Mach
%   correction), valid M >= 1.2:
%     (D/q)_SH   = (9*pi/2) * (Amax/l)^2                                    [12.44]
%     (D/q)_wave = E_WD*[1 - 0.386*(M-1.2)^0.57*(1-(pi*Lambda_LE_deg^0.77)/100)]
%                  * (D/q)_SH                                               [12.45]
%     CD0_wave   = (D/q)_wave / S_ref
%   Amax/l are WHOLE-AIRCRAFT quantities [Brandt Geom!B20/H47, B21 -- see
%   F16AeroL3_wave_drag_fix.md], distinct from l_ref_comp(4)/D_comp(4)
%   (fuselage-component-only values used elsewhere in this class for the
%   skin-friction Re/FF_body calc -- do not conflate the two length scales).
    M = state.mach;
    Dq_SH = (9*pi/2) * (obj.Amax_ft2 / obj.L_aircraft_ft)^2;
    val = obj.E_WD ...
        * (1 - 0.386*(M-1.2)^0.57*(1 - (pi*obj.Lambda_LE_deg^0.77)/100)) ...
        * Dq_SH / obj.S_ref;
end
```
Also fix the stale "Eq. 12.41" citation in the `get_CD0_buildup` override's
comment (`F16AeroL3.m:294-296`, "...supersonic wave-drag-due-to-volume term
(Raymer 6th ed. Eq. 12.41)...") to "Eqs. 12.44-12.45", and the class header
block's line 7 ("`compute_CD0_wave`, Raymer 6th ed. Eq. 12.41") likewise.

---

## 3. Canopy component — research findings

**No citable numeric canopy geometry (length, diameter, wetted area) exists
anywhere in this repo or its reference extracts.** Searched exhaustively:

- **`temp_Casey`** (all of it, case-insensitive "canopy" grep, 4 hits total):
  `src/Disciplines/Aerodynamics/AeroLevel3.m:312` and
  `examples/F-16A B Block 10 and 15/Aerodynamics/F16AeroLevel3.m:548,568`
  define **"smooth canopy" only as a component-***type*** dispatch branch**
  in the generic form-factor lookup (`get_FF`), sharing the same Raymer
  Eq. 12.31 body form factor as "fuselage" and requiring `l`, `d`, `A_max`
  from a `component_specs` struct. **This dispatch branch is never actually
  invoked with real F-16 numbers anywhere in `temp_Casey`** — I traced every
  call site (`get_component_drag_values_sub`/`_supersonic`,
  `F16AeroLevel3.m:627-676`) and the F-16-specific class only ever builds
  `fuselage_specs`/`wings_specs`/`HT_specs`/`VT_specs` (4 components: fuselage,
  mainwings, HT, VT) — no `canopy_specs` struct exists, no numeric
  length/diameter/S_wet for a canopy appears anywhere in that file or its
  sibling generic toolboxes (`Drag_Polar_III.m`/`Drag_Polar_IV.m`, which also
  only *mention* "smooth canopy" in a component-list comment, same as
  `AeroLevel3.m`). This is dead/unwired capability in `temp_Casey`, not a
  data source.
- **`VnV/BrandtF16A`**: zero matches for "canopy" (case-insensitive) anywhere
  — no `.m`, `.md`, or `.json` file mentions it.
- **`temp_AI/docs/disciplines/reference_extracts/`**: zero matches.

**Suggestive (not conclusive) evidence that Brandt's fuselage S_wet already
implicitly includes the canopy, rather than omitting it:** `BrandtGeometry.m`'s
fuselage cross-section is built from 20 literal frame stations
(`GroundTruth/f16a_geometry.json` `fuselage.frames`, each with `x_ft`/`z_ft`/
`w_ft`/`h_ft`) fed directly into `frameCrossSection()`
(`BrandtGeometry.m:1079-1096`) with no separate canopy term added anywhere in
`computeFrameGeometry`/`computeSwetAccurate`. The frame `h_ft` column shows a
local bulge right where a cockpit/canopy would sit — frame 4 (x=12.0 ft,
h=5.0) → frame 5 (x=13.5, h=6.0) → frame 6 (x=15.0, h=**7.5**, the table's
local max) → frame 7 (x=16.975, h=7.0) → frame 8 (x=20.0, h=6.0) → settling to
h=5.0/4.0 further aft — i.e. the frame *height* locally exceeds the fuselage's
own nominal `max_height_ft=5.0` (`Main!D31`/`D32`) specifically over
frames 4-8 (x≈12-20 ft), the plausible canopy/cockpit station range, then
returns to ≤5.0 elsewhere. This is consistent with the canopy bulge being
baked directly into the frame table Brandt's `Geom!B3`/`D23` fuselage S_wet
integrates over, rather than needing (or having) a separate additive term.
**This is inference from the shape of the frame data, not an explicit
"canopy" label anywhere in Brandt's workbook or `BrandtGeometry.m`'s own
comments** — treat as suggestive, not as a citable confirmation either way.

**Recommendation / open item for the user:** do **not** fabricate a canopy
`l`/`d`/`S_wet` triple. Two honest options, both requiring user input:
1. **Don't add a 6th canopy component.** If Brandt's fuselage frame data (and
   by extension `F16AeroL3`'s own hand-copied `S_wet_comp(4)=644 ft²`
   fuselage estimate, which is itself *not* live-read from any Geometry
   class per the file's own comment at line 45) already implicitly includes
   canopy wetted area, adding a separate canopy term would **double-count**
   it. There is no documentation anywhere establishing whether `644` already
   includes a canopy allowance or not — this is itself an open question, not
   just the canopy dimensions.
2. **Add a 6th component**, but only once the user supplies (or points to) a
   primary-source canopy `l`/max-width-or-diameter/`S_wet` (e.g. a T.O.
   1F-16A-1 canopy drawing dimension), and confirms whether `S_wet_comp(4)`
   (fuselage) should be reduced to avoid double-counting the canopy glazing
   area if it's currently folded in.

Either way this needs an explicit user decision before implementation touches
the component arrays — flagging per the task instruction, not guessing.

**DECISION (2026-07-23, user):** Skip the canopy component. No canopy
`l`/diameter/`S_wet` dimension is available anywhere in this repo (`temp_Casey`,
`VnV/BrandtF16A`, or `temp_AI/docs/disciplines/reference_extracts/`), and the
user was unable to locate one independently either. `F16AeroL3`'s component
buildup stays at 5 entries (wing, HT, VT, fuselage, duct) — no 6th canopy line
is added by this fix. This also leaves open whether the existing
`S_wet_comp(4)=644` fuselage figure already implicitly includes canopy area
(§3's frame-bulge evidence suggests it might, in Brandt's own model) — that
question is unresolved and out of scope for this fix; implementation should
add a `TODO` comment on `S_wet_comp`/the component array noting the missing
canopy geometry and the open double-counting question, so it isn't silently
forgotten.

---

## 4. Gun port / hook / L&P — confirmed no change needed

Per §1's confirmed Eq. 12.41 structure, `CD0_misc` and `CD0_L&P` are
**separate additive terms** from both the per-component skin-friction sum and
`CD0_wave` — they are flat `Dq` (drag-area) lookups from Raymer Table 12.7,
divided by `S_ref`, with no Mach or sweep dependence and no interaction with
the wave-drag term. `F16AeroL3.m`'s existing implementation already reflects
this exactly:
```matlab
CD0_misc = (Dq_gun_port + Dq_hook_USAF) / S_ref;   % constructor, line 236
```
— a single cannon port (`Dq_gun_port=0.20`) + USAF arresting hook
(`Dq_hook_USAF=0.10`), Raymer Table 12.7, set once and never touched by
`compute_CD0_wave` or the wave-drag gate. **Confirmed: gun port and hook do
not need to become buildup components and do not need their own wave-drag
contribution.** (I could not independently verify Table 12.7's exact
row/value against a physical copy of Raymer — this repo has no digitized
Table 12.7 to cross-check beyond what `F16AeroL3.m`'s own pre-existing
citation already claims; noting this as an inherited-trust boundary, not a
new gap introduced by this fix.)

---

## 5. Inlet / duct — confirmed, no additional action

`F16AeroL3`'s existing 5th component (`l=14.0 ft, D_avg=3.15 ft, is_body_comp=true`,
Raymer Eq. 12.31 form factor, `Q=1.0`) already represents the **inlet duct's
own skin-friction drag** in the Eq. 12.41 component sum — this satisfies "the
inlet" for the skin-friction buildup. Separately, for the **wave-drag** term
(§2): Brandt's whole-aircraft `Amax` table already includes a nacelle/duct
cross-section contribution (`A_nac`, `BrandtGeometry.computeAmax():1056-1058`)
in the raw per-frame sum before the flow-through correction is subtracted —
so the corrected `Amax_ft2=25.110556` sourced in §2 already accounts for the
duct/inlet's contribution to the whole-vehicle wave-drag-relevant cross
section, net of the internal flow-through area. **No separate "inlet wave
drag" or "additive drag" term is needed or implied by Raymer Eq. 12.44/12.45**
— that would be a propulsion-installation-loss concept (spillage/additive
drag), not something Raymer's slender-body wave-drag-due-to-volume formula
computes, and nothing in this repo's citation set calls for it. If the user
meant something else by "the inlet" (e.g. installed-thrust lapse from
spillage), that is a Propulsion-discipline concept, not an Aero CD0-buildup
term — flagging the ambiguity rather than assuming.

---

## 6. VnV/BrandtF16A discrepancy check

Checked for internal disagreement (doc vs. doc, doc vs. `.m`, or either vs.
the live `.xls`) touching every quantity used in this fix (`Amax`, aircraft
length, `E_WD`, the wave-drag formula itself). **No new discrepancy found —
no entry added to `VnV/BrandtF16A/todo.md`.** Specifically checked and found
consistent:
- `Amax`/aircraft-length values agree across the live `.xls` cells
  (`Geom!B20`/`H47`/`B21`), `BrandtGeometry.m`'s independent computation, and
  `readme_geom.md`'s validation table (§2 above) — all within 0.002%.
- The `Geom!H26:H45` vs. `H26:H47` range wording inside `BrandtGeometry.m`'s
  own comments is not a conflict (§2's dedicated note above).
- `E_WD=2.2` agrees between `temp_AI/docs/disciplines/01_aerodynamics.md` and
  `temp_Casey`'s independently-hardcoded same value (already noted in
  `F16AeroL3.m`'s own existing citation, re-confirmed here, no change).

**Noted but NOT logged to `todo.md` (this is expected divergence, not a
`VnV/BrandtF16A`-internal conflict):** Brandt's own wave-drag formula
(`BrandtAerodynamics.m:358-362`, `readme_aero.md` lines 184-187) —
```
wave_factor = (4.5*pi/S_ref) * (Amax/L_ac)^2 * Ewd * (0.74 + 0.37*cos(Lambda_LE))
```
— shares Raymer's `9*pi/2 = 4.5*pi` Sears-Haack leading constant, but uses a
**different** empirical correction factor than Raymer 6th ed. Eq. 12.45's
`[1 - 0.386*(M-1.2)^0.57*(1-(pi*Lambda_LE_deg^0.77)/100)]` bracket — Brandt's
factor depends on sweep only (no direct Mach term in `wave_factor` itself;
Mach enters separately via `CDwave = wave_factor*(1-0.3*(M-M_wave)^0.5)` in
the supersonic branch). This is Brandt's own self-consistent calibrated
model (matches between its `.m` code and its own `readme_aero.md`), not an
internal disagreement — and per `PLAN.md`'s explicit rule against hardcoding
Brandt's back-calculated calibration values into the F-16 example class,
`F16AeroL3` should keep implementing Raymer's actual textbook Eq. 12.45
bracket (as specified in §2 above), **not** switch to Brandt's formula.
Recording this here only so the difference isn't mistaken for an error later.

---

## 7. Cross-file note (out of scope for this fix — flagging for awareness only)

`F16AeroL3.l_ref_comp(4)=47.5 ft` (fuselage length, cited `T.O. 1F-16A-1`) and
`F16AeroL3.D_comp(4)=5.0 ft` do not match the **current**
`examples/F16A/F16GeomL2.m` code's own fuselage figures:
`F16GeomL2.L_fus=46.5 ft` (`[Brandt Main!B32]`, `F16GeomL2.m:123`) and
`F16GeomL2.D_fus` — now a `Dependent` getter,
`(W_max_fuselage+H_max_fuselage)/2 = (7.0+5.0)/2 = 6.0 ft`
(`F16GeomL2.m:173,359-360`), not `5.0`. `F16GeomL2.md`'s own written table
(line 129: `L_fus = 47.5 ft [TO, Fig. 1-2]`) and
`docs/geometry_parameter_usage.md`'s claim that `WeightsL3`'s hardcoded
`47.5` "agrees with `F16GeomL2.L_fus`" are **both now stale** relative to the
live `F16GeomL2.m` code (which has since moved to the Brandt-sourced `46.5`).
This is a **cross-`examples/F16A/`-file** staleness/mismatch, not a
`VnV/BrandtF16A`-internal one, so it does not go in that `todo.md` — flagging
here for user visibility since it surfaced while researching this fix. Out of
scope to resolve as part of the wave-drag change (this fix does not touch
`l_ref_comp`/`D_comp`, only adds the two new `Amax_ft2`/`L_aircraft_ft`
properties).

---

## Summary for approval-gate decision

**Ready to implement, no blockers, three items need a decision:**
1. Citation fix: `compute_CD0_wave`'s formula citation changes from
   "Eq. 12.41" to "Eqs. 12.44-12.45" (§1, §2) — mechanical, no open question.
2. `Amax`/`l` sourcing: replace the fuselage-only `pi*(D_comp(4)/2)^2` /
   `l_ref_comp(4)` with two new hardcoded properties,
   `Amax_ft2=25.110556`, `L_aircraft_ft=48.304`, cited to Brandt
   `Geom!B20`/`H47`/`B21` and cross-validated against `BrandtGeometry.m`'s
   independent computation (§2) — fully sourced, no open question.
3. **Canopy (needs a user decision, §3):** no citable numeric canopy geometry
   exists anywhere in this repo. Recommend **not** adding a 6th component
   until the user either (a) supplies a primary-source canopy dimension, or
   (b) confirms the existing fuselage `S_wet_comp(4)=644` should absorb it
   with no separate term — either choice needs to also address whether `644`
   already includes canopy area, which nothing in the repo currently answers.
4. Gun port / hook / L&P (§4) and duct/inlet (§5): **confirmed no change
   needed**, both stay exactly as-is.
5. No new `VnV/BrandtF16A/todo.md` entry was needed (§6) — everything
   cross-checked came back consistent.
6. One tangential, out-of-scope cross-file mismatch flagged for awareness
   only (§7): `F16AeroL3`'s fuselage `L=47.5 ft`/`D=5.0 ft` vs.
   `F16GeomL2`'s current `L_fus=46.5 ft`/`D_fus=6.0 ft` (Dependent).
