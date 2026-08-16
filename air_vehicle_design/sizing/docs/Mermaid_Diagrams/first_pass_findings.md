# Mermaid diagram first pass: findings log

This file records every error and problem found while the diagrams in this
folder were written. Nothing here is fixed yet. The first pass goes through
the whole discipline directory and logs. A second pass fixes.

Entry types:
- **D**, diagram defect — the diagram says something the source does not.
- **K**, known and scheduled — Casey's own TODOs, confirmed and already planned.
- **P**, proposed solution — Casey's decision on how to resolve something.
- **S**, source observation — the source itself has a problem the diagram made
  visible.

## Where the charts live

Casey reorganized the folder on 2026-08-14. The layout is now:

```
docs/Mermaid_Diagrams/
    first_pass_findings.md          this file
    Claude-made/
        Aero/          F16AAero1/2/3_mermaid.md
        Geom/          F16AGeom1/2/3_mermaid.md
        LandingGear/   F16ALandingGear2/3_mermaid.md
        Prop/          F16APropulsion1/2_mermaid.md
        SandC/         F16ASandC2/3_mermaid.md
        Subsystems/    F16ASubsystems1/2/3_mermaid.md
        Tail/          F16ATail1/2/3_mermaid.md
        Weights/       F16AWeights1/2/3_mermaid.md
    hand-made/
        AeroL1.md, GeomL1.md, F16AGeomL1_handmade.md
```

18 charts, 8 disciplines. Every chart names its own source files in a table at
the bottom, so the discipline folders do not need an index.

Two link consequences of the move, both handled: a link between charts in the
SAME discipline stays a bare filename, and a link to this file from inside a
discipline folder needs `../../first_pass_findings.md`.

`hand-made/` holds Casey's own diagrams and is not part of this pass.

---

## Diagram defects

### D-0. Label pass, 2026-08-14

Casey: "If you NEED to use an input block, then the outputs immediately
downstream should carry the exact labels of whatever output they're carrying
to whatever receiving function is immediately downstream of them." The input
blocks may stay. Every arrow that leaves one must name its field. Judge the
result from the RENDER.

Done in `F16AAero1_mermaid.md`, `F16AGeom2_mermaid.md` and
`F16AGeom3_mermaid.md`. Every arrow in all three now carries a label.

A label must be true, so writing them FIXED defects D-1, D-2 and D-3 in the
L2 chart, and exposed four more that the unlabeled arrows had hidden. All are
now correct in L2:

- `get.x_mac_le_wing`, `get.x_c4_ht` and `get.x_c4_vt` read the surface's
  `LE_sweep`, not its `QC_sweep`. The chart drew the arrow from the
  `TE_sweep` / `QC_sweep` getter and labeled it `QC_sweep_*`. Wrong source
  and wrong label.
- `get.x_c4_ht` and `get.x_c4_vt` each make FOUR `GeometryBase` calls
  (`compute_mac`, then `compute_y_mac` or `compute_y_mac_panel`, then
  `compute_x_mac_le`, then `compute_x_mac_quarter_chord`). The chart drew one
  each.
- The wetted-area getters read the root/tip t/c PAIR plus `lambda`. The chart
  drew `get.tc_ht` feeding `get.S_wet_ht`, which does not happen: the mean is
  used only by the comparison alternate and the form factor.
- `get.D_inlet` took an arrow from the engine inputs. It reads only
  `T_AB_SLS_lb`.

### D-1. RESOLVED. `F16AGeom2_mermaid.md`: `get.b_vt` shown as a toolbox call

The chart draws `V1 (get.b_vt) --> TB1 (GeometryBase.compute_span)`.
`F16GeomL2.get.b_vt` (line 464) computes `sqrt(obj.S_vt * obj.AR_vt)` inline
and calls nothing. The node must become a yellow passthrough and the edge to
`TB1` must go. The L3 chart already draws this correctly.

Fixed in the label pass: `V1` is now `passthrough`, the `V1 --> TB1` edge is
gone, and the `linkStyle` indices were recounted. L2 now has 126 edges.

### D-2. RESOLVED. `F16AGeom2_mermaid.md`: wrong `compute_mac` signature

The chart says `GeometryBase.compute_mac(c_root, c_tip)` and gives node `W4`
the inputs `c_root_wing, c_tip_wing`. The real signature is
`compute_mac(c_root, lambda)` (`GeometryBase.m:50`), and `F16GeomL2.m:408`
passes `obj.c_root_wing, obj.lambda_wing`. The tip chord is not an argument.

Fixed in the label pass.

### D-3. RESOLVED. `F16AGeom2_mermaid.md`: wrong `compute_S_exposed_vertical` signature

The chart says `GeomL2.compute_S_exposed_vertical(c_root, c_tip, span)` and
gives node `V7` the inputs `c_root_vt, c_tip_vt, b_vt`. The real signature is
`compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)` (`GeomL2.m:268`), and
`F16GeomL2.m:493` passes `obj.S_vt, obj.AR_vt, obj.c_root_vt, obj.c_tip_vt,
obj.H_max_fuselage/2`. The chart is missing three arguments, including the
fuselage half-height clip.

Fixed in the label pass, including the missing `INFUS --> V7` half-height
edge. The L3 chart already drew this correctly.

### D-3a. `F16AGeom3_mermaid.md` omits the taper-ratio arrows

L3's chord and MAC getters read `lambda` as well as the root chord, but the
chart has no arrow carrying it into `get.c_tip_*`, `get.cbar_wing` or the
`get.c_root_*` getters. The labels written in the label pass are all true;
the arrows are simply missing. L2 has them, so the two charts now differ.

Not fixed, because adding an arrow shifts every `linkStyle` index after it,
and L3 has 206 edges. Do it with the other L3 work.

### D-4. All charts: the render is too wide to read

Reported by Casey on the L2 render. At L2 the bottom toolbox strip is a
single rank of 23 nodes, which sets the whole chart's width and squeezes the
top half into the middle third. L3 is worse: about 100 nodes and 206 edges.

Options costed during the L2 review, cheapest first:
1. Formatting only, no content removed. Drop the `in:`/`out:` lines from the
   class-function boxes (the same values are already on the incoming edges
   and in the field-by-field table), shorten edge labels to the source
   function name without the argument list, and split one wide toolbox
   subgraph into several stacked ones. Estimated 50 to 60 percent width
   reduction, zero information loss. The L3 chart already splits its
   toolboxes four ways.
2. Move the no-upstream-call chain to its own small chart below the main one.
   Those nodes carry no live data and cost width in the widest rank.
3. Split by component: one chart each for wing, HT, VT, fuselage and duct,
   MAC and totals. About 10 nodes each. Cross-component edges get repeated.
4. Collapse the repeated lifting-surface pattern into one template chart plus
   a variant table. Removes about 16 boxes at L2, more at L3, but this is the
   only option that drops detail from the diagram.

Option 0, applied to `F16AGeom3_mermaid.md` on 2026-08-14 at Casey's
direction: reorient the whole chart from `flowchart TD` to `flowchart LR`.
Data then flows left to right through each component group, and the groups
themselves become parallel branches off the constructor, so they stack
vertically as horizontal bands. Width becomes height, which a display can
scroll. This costs nothing: no node, edge, or label changes, so the
positional `linkStyle` indices stay valid.

Casey confirmed the L3 result on 2026-08-14: "The reorientation helped. It's
still massive, but it's relatively easier to read." He still had to split the
render into three screenshots to share it, so `LR` alone is necessary but not
sufficient at that node count.

STANDING RULE from that exchange: orient every large diagram so the RENDER is
readable on a 1920x1080 monitor. Judge the choice by the preview at 100
percent, not by the source.

`F16AGeom2_mermaid.md` was reoriented to `LR` in the same pass.
`F16AGeom1_mermaid.md` stays `TD`: it has 10 nodes and already fits one
screen, so the rule does not bite.

Options 1 through 4 are still open on top of the reorientation, and L3 still
needs them.

### D-5. RESOLVED. The geometry charts still use "Inputs" blocks

Casey, 2026-08-14: "Why are there dedicated 'input' blocks? Inputs and
outputs should be labeled clearly on their corresponding lines/arrows."

The blocks came from an explicit plan exception: plain constructor-set
properties have no function to show, and `F16GeomL3` sets 38 of them, so one
node each would be unreadable.

Casey then refined the rule: an input block MAY stay if it is needed, but
every arrow leaving it must carry the exact label of the value it moves. See
D-0. `F16AAero1_mermaid.md` had no need for one at all, since the class has
only seven inputs, so its block was deleted and the fields moved onto the
constructor's outgoing arrows. `F16AGeom2` and `F16AGeom3` keep their blocks
and have labeled arrows instead.

### D-7. Coefficient values do not belong in node labels

Casey, 2026-08-14, on `F16AWeights1_mermaid.md`'s `lookup_roskam_coeffs` node:
"You can remove the highlighted part... We don't need details like that in the
blocks."

A node label carries the function name, its inputs, its output and its
citation. It does NOT carry the numeric values a lookup returns. Those belong in
the field-by-field table.

Fixed in `F16AWeights1_mermaid.md`: both lookup nodes now name their source
table instead of listing coefficients.

Still to sweep. Node labels carrying returned values or computed results:

| File | Nodes |
| --- | --- |
| `F16AAero1_mermaid.md` | `get_CLmax` = 1.50, `get_CLmax_TO` = 1.70, `get_CLmax_L` = 2.10; `mattingly_K2` gives K2 = 0 |
| `F16AAero2_mermaid.md` | `get.Cfe` = 0.0035; `get.W_en`-style values on the polar nodes; `lookup_TSFC_coeffs`-style coefficient lists |
| `F16AAero3_mermaid.md` | `E_WD` = 2.2 on the wave-drag node |
| `F16AGeom2_mermaid.md` | `Amax` = (pi/4)WH shown as a formula, `tc` means |
| `F16AGeom3_mermaid.md` | `AR_ht` = 3.169, `tc_ht` = 0.0475, `tc_vt` = 0.0415, `x_c4_wing` = 25.5891, `S_csw` = 68.03, `S_cs` = 187.68 |
| `F16APropulsion2_mermaid.md` | `TR` = 1.0; `lookup_TSFC_coeffs` lists all four C values |
| `F16AWeights2_mermaid.md` | every group-weight node carries its lbf value; the six unit-weight lookups carry their psf values |
| `F16ALandingGear2/3_mermaid.md` | `lookup_tire_sizing_coeffs` lists the four Jet fighter/trainer coefficients |

The values are correct and are already in each file's notes table, so this is a
readability fix, not a correctness one. It also shortens the widest nodes, which
helps D-4.

### D-6. `linkStyle` indices are positional and fragile

Every chart colors its edges by numbered index in write order. Any edit that
adds, removes, or reorders an edge silently mis-colors everything after it.
L1 has 13 edges, L2 has 115, L3 has 206. Each fix above forces a full
recount.

**Fix option to consider:** none of Mermaid's syntax avoids this. The
practical mitigation is to write all edges of one color contiguously, so an
insertion touches one `linkStyle` line instead of three.

---

## Known and scheduled

### K-1. Subclass-era wrapper statics, to be removed in the fix pass

Casey's own TODOs, confirmed 2026-08-14: the toolboxes used to be subclasses
of the enforcers, and the object-taking wrapper statics left over from that
arrangement are superfluous. They will be removed later. Not defects, and not
findings. Listed here only so the diagrams' red nodes and the S-entries below
can be read against one known cause.

Sites the charts touch, each carrying its own TODO in the source:

| Toolbox | Wrappers tagged |
| --- | --- |
| `AeroL1` | `drag_polar`, `get_CLmax`, `interp_curve` |
| `AeroL2` | `drag_polar`, `get_CLmax`, `get_e_osw`, `get_CD0`, `get_CD0_supersonic`, `get_K1`, `get_K2`, `compute_CL_minD`, `compute_Delta_CL_max_values` |
| `AeroL3` | `drag_polar`, `get_CD0_buildup`, `get_e_osw`, `get_K1`, `get_K2`, `get_CL_alpha` |
| `PropL1` | `get_thrust_lapse`, `get_TSFC` |
| `GeomL3` | `get_S_wet`, and the area-rule statics flagged as too design-specific |

Two consequences worth carrying into the fix pass, both already logged
separately: the six unreached `AeroL3` wrappers in S-18 are this same
category, and the unreachable `AeroL2` supersonic chain in S-14 hangs off one
of these wrappers.

## Source observations

### S-1. `F16GeomL1`: two `Dependent` properties have no getter

`S_wet` and `L_fuselage` are declared `properties (Dependent)`, but
`get.S_wet` and `get.L_fuselage` are commented out. Reading `geom.S_wet` or
`geom.L_fuselage` errors at runtime, because MATLAB requires an explicit
getter for every `Dependent` property. The underscore-named instance methods
`get_S_wet`, `get_S_wet_statistical` and `get_L_fus` are unaffected and all
work.

### S-2. `F16GeomL1`: `get_S_wet` and `get_S_wet_statistical` are duplicates

Both call `GeomL1.get_S_wet_statistical` with the same arguments and return
the same value. The source records why: `% TODO (8/13/20206): Duplicate
method function, but needed to satisfy the enforcer.` `GeometryModelL1`
requires the `_statistical` name. Both methods are live and correct. The
question is whether the enforcer should require that name at all.

### S-3. `F16GeomL3`: `S_ail` and `S_elev` stay `NaN`, not 0

The class header says both are "0 for the F-16", and `GeometryModelL3`
repeats it. The constructor seeds `S_flaperon`, `S_lef`, `S_rud` and
`S_stab`, but never touches `S_ail` or `S_elev`, so a freshly constructed
object carries `NaN` in both. The header block above the properties also says
"At L3 all six are SEEDED from the T.O. measured areas", which is not what
the constructor does. Either the comment or the constructor is wrong.

### S-4. MOVED to K-1.

`GeomL3.get_S_wet` is a subclass-era wrapper, and the same five-term sum
wrapper exists at L2. See K-1.

### S-5. `GeomL3`: three open citation gaps, all visible in the chart

- `denormalize_frames` — the affine frame-table rescaling has no textbook
  source.
- `compute_Amax_area_ruled` — the `/5` inlet flow-through divisor is a bare
  literal from the workbook.
- `compute_engine_length` — `4.5*D`, marked `% TODO (8/14/2026): Unsourced.`
- `compute_surface_cs_area` — the cosine area-distribution model is Brandt's
  own construction with no textbook source.

All four are recorded in `VnV/BrandtF16A/todo.md` already. The diagram labels
them, so they stay visible.

### S-6. `GeomL3`: two statics flagged as too design-specific for a toolbox

`compute_surface_cs_area` and `compute_Amax_area_ruled` both carry TODOs
asking to relocate or generalize them, because they reference Brandt directly
and encode one aircraft's layout. `compute_surface_cs_area` also carries a
request to decompose the wetted-area work into generic shape functions
(`Cone`, `Cylinder`, `Oval`, and so on).

### S-7. `f16a_L3.json`: `overall_length_ft` is unpinned

The value 47.65 ft is user-approved but traceable to no document in the repo.
The JSON carries its own `_TODO_overall_length_ft` key saying so. It feeds
only the Raymer Eq. 12.44 wave-drag term.

### S-8. `F16AeroL1` cannot be constructed

Both aero enforcers have uncommitted edits that add abstract members the
concrete class does not supply:

- `AerodynamicsBase` adds abstract properties `e_osw`, `CD0`, `CL`, `CL_max`,
  `K1`, `K2`, and the abstract method `get_CD0`.
- `AeroModelL1` adds abstract properties `AR_equivalent` and `LD_max`, and
  abstract methods `get_AR_eq`, `get_LD_max`, `get_CD0`.

`F16AeroL1` has none of them, so MATLAB cannot instantiate it. Both edits
carry a TODO saying the equations are still needed, so this is work in
progress, not an accident. Two further problems in the same edit:

- The abstract method signatures take no object: `AR_equivalent =
  get_AR_eq();`. An instance method needs `obj`, so the declared contract
  cannot be satisfied by a normal method.
- `AeroModelL1`'s own header still says "this enforcer adds no further
  abstract members", which the new block contradicts.
- `get_CD0` is now declared abstract in BOTH `AerodynamicsBase` and
  `AeroModelL1`.

The chart draws no node for any of these, because the members do not exist in
the concrete class yet.

### S-8a. `AeroModelL2` will not parse: `properties (Abstrct)`

Line 17 of the uncommitted edit misspells `Abstract`:

```matlab
properties (Abstrct)
    CL_alpha
    CDi
end
```

MATLAB rejects an unknown property attribute, so the enforcer file itself
fails to parse and nothing below it can load. This is more severe than S-8,
which was an unsatisfied contract; this is a syntax error. The typo appears
only in `AeroModelL2.m`, not in `AeroModelL1.m` or `AeroModelL3.m`.

Three further problems behind it, all in the same edit:

- `cl_alpha` and `Cfe` are declared `Abstract, Constant`. `F16AeroL2` has
  `Cfe` as `Dependent`, which does not satisfy a `Constant` contract, and has
  no `cl_alpha` at all. Its airfoil slope is `cl_alpha_2D`.
- The abstract methods `get_CL_alpha()`, `get_CD0()` and `get_CDi()` take no
  `obj`, so no instance method can satisfy them.
- `F16AeroL2` has no `get_CDi`.

### S-8b. `AeroModelL3` requires members `F16AeroL3` does not have

Same shape as S-8, and it includes a name mismatch:

- Abstract properties `CL_alpha`, `CD0_misc`, `CD0_L_and_P`, `CDi`.
  `F16AeroL3` has `CD0_misc` as a `Dependent`, but its leakage term is
  `CD0_LandP`, NOT `CD0_L_and_P`. The two names differ, so the contract is
  unsatisfiable as written. `CL_alpha` and `CDi` do not exist at all.
- Abstract CONSTANT properties `cl_alpha` and `k`. `F16AeroL3` has `k` as a
  plain mutable property, which does not satisfy a `Constant` contract, and
  has no `cl_alpha`. Its airfoil slope is `cl_alpha_2D`.
- Abstract methods `get_CDi()` and `get_CD0()`, both with no `obj`, and
  `F16AeroL3` has neither.

So all three aero levels are blocked: L1 by an unsatisfied contract, L2 by a
parse error plus an unsatisfied contract, L3 by an unsatisfied contract with a
name mismatch inside it. `get_CD0` is declared abstract in `AerodynamicsBase`
AND in all three enforcers.

### S-9. `AeroL1`: three private normalizers have no caller

`normalize_DeltaCD0_quantity`, `normalize_flapconfig` and
`normalize_CL_condition` are never called, in source or in tests. The public
methods pass the exact table strings, so nothing normalizes anything. They are
about 90 lines of the file.

### S-10. `AeroL1` calls `AeroL2`

`k1_from_geometry` calls `AeroL2.flight_regime`, `oswald_eff`, `K1_subsonic`
and `K1_supersonic`. The source flags it: `% TODO (8/13/2026): AeroL1 should
not be using AeroL2.` The reuse is deliberate and cited, but it makes L1
depend on the L2 toolbox and inherits the Eq. 12.51 transonic NaN band, which
L1's own CD0 curve does not have.

### S-11. `AeroL1`: two open questions beyond the K-1 wrappers

The wrapper TODOs on `drag_polar`, `get_CLmax` and `interp_curve` belong to
K-1. Two items in the same file are separate questions:

- `drag_polar`: "I thought we were ditching the Mattingly K1 tabulation
  approach." K1 no longer comes from a curve, but CD0 still does, from the
  placeholder table in S-12. The comment may be about a change that is only
  half done.
- `to_CLmax_table_row`: only `jet_fighter` and `fighter` are mapped. Every
  other category passes through unmapped, and the source carries "Add
  remaining aircraft classifications." A CLmax lookup for any other aircraft
  therefore depends on the JSON key already matching Roskam's own row name.

### S-12. `f16a_L1.json`: the CD0 curve is a placeholder

`.aerodynamics.cd0_curve` is marked `_placeholder: true`. Mattingly Fig. 2.10
is not in the repo, so the 8 breakpoints come from 5 AAF worked-example
points, and `Future` is a copy of `Current`. Guarded by
`TestAeroL1.testTODO_MattinglyCurvesArePlaceholder`.

### S-14. `AeroL2`: the supersonic CD0 path is unreachable from L2

`F16AeroL2.drag_polar` overrides the supersonic regime, so
`AeroL2.get_CD0_supersonic` and its chain (`compute_Re`, `Cf_turbulent`,
`dyn_viscosity`) never run through this class. The toolbox still carries a
supersonic branch in `AeroL2.drag_polar` that would call them.

The override exists for a real reason: the toolbox's supersonic CD0 is
turbulent skin friction with NO wave-drag term, so it read LOWER at M = 1.6
than subsonic, which is backwards, and made the L2 Max Mach constraint curve
read 70 to 80 percent low against Brandt.

The question the chart raises is whether the toolbox's dead supersonic branch
should stay. `compute_Re` even carries the TODO "Where is this used?" and
`Cf_turbulent` carries "It appears that some of the component-level drag
buildup has bled into L2."

### S-15. `f16a_L2.json`: three airfoil values are unpinned

`alpha_L0_deg = -1.33` is web-sourced, not a primary NACA report, and the
JSON says so: public 64A20X wind-tunnel data is scarce, and secondary sources
estimate the family from 64A210. `cl_max_2D = 1.2` (Abbott and von Doenhoff)
conflicts with NTRS-19870017427's 1.0. `cl_alpha_per_deg = 0.105` is an
internet-band midpoint. All three have failing-test guards in `TestAeroL2`.

### S-16. `delta_flap_TO_deg` disagrees between L2 and L3

L2 uses 15 deg, L3 uses 20 deg, for the same flaperon on the same aircraft.
L2's value is uncited. L3 records web-sourced evidence that takeoff and
landing use the same 20 deg setting. L2 was left at 15 deliberately, since
changing it moves the L2 takeoff CLmax. Already in
`VnV/BrandtF16A/todo.md`.

### S-17. MOVED to K-1.

Nine `AeroL2` statics are subclass-era wrappers. See K-1.

### S-18. `AeroL3`: six wrapper statics have no caller

`compute_Cf_lam`, `compute_Cf_turb`, `compute_FF_surface`, `compute_FF_fus`,
`compute_Cf` and `get_R_cutoff` are each a one-line wrapper over a low-level
static. `get_CD0_buildup` calls the low-level statics directly and branches on
Mach itself, so none of the six is reached. Grepped the whole tree, tests
included: no caller.

### S-19. `F16AeroL3`: injecting an L2 geometry silently changes `Amax`

The constructor accepts `GeometryModelL2` or `GeometryModelL3`. With an L3
geometry, `Amax_ft2` is the area-ruled buildup, 24.7037, which is the quantity
Raymer Eq. 12.44 wants. With an L2 geometry it becomes the fuselage-envelope
ellipse, 27.4889, and inflates the wave-drag term by about 23 percent. No
error, no warning. The class header documents it; the type guard does not
prevent it.

### S-20. `F16AeroL3`: `strut_ref_length` decides a drag branch

`strut_ref_length = 0.3` ft carries its own "TODO verify". It is an estimated
strut diameter, and `compute_Delta_CD0_geardown` uses the resulting Reynolds
number to pick between `Dq_strut_highRE = 0.30` and `Dq_strut_lowRE = 1.17`.
Those differ by a factor of about four, so an unverified length selects a
four-times drag difference at a hard threshold.

### S-21. `F16AeroL3`: the roughness JSON block is read once, not per component

`.aerodynamics.surface_roughness_k_ft` carries a value for all five
components, but the constructor reads `.wing` only and applies it uniformly,
which the comment states. The other four keys have no consumer.

### S-22. Two contracts name the same propulsion quantities differently

`PropulsionBase` requires `thrust_lapse` and `get_TSFC`.
`PropulsionModelL1` requires `get_thrust_lapse` and `lookup_TSFC`. They are
the same two quantities under different names, so `F16PropL1` carries four
methods where two would do, each pair delegating to the same static.

All four are live and correct. This is the same shape as S-2 in `F16GeomL1`,
where the enforcer's `_statistical` name forced a duplicate. The question is
whether the enforcer layer should be allowed to rename what the base already
declares.

### S-23. `PropL1.lookup_TSFC_table` returns two different physical quantities

Every `engine_type` returns thrust-specific consumption in 1/hr, except
`turboprop`, which returns Raymer Table 3.4 `Cbhp` in lb/hr/bhp. That is a
power-specific quantity and not interchangeable. The code raises a warning and
says so plainly, and the values were corrected 2026-07-30 from a
mis-transcribed duplicate of the turbojet row. Recorded because one table
returning two unit bases is a trap for the next caller, warning or not.

### S-24. `PropL1`: sea-level density is hardcoded, twice flagged

`RHO_SL = 0.002377` is a private constant in the toolbox with two TODOs, dated
2026-07-13 and 2026-08-14, both saying sea-level standard conditions should be
their own class. `AircraftState` already models the atmosphere, so the lapse
computes a density ratio against a number the state object could supply.

### S-25. MOVED to K-1.

`PropL1.get_thrust_lapse` and `get_TSFC` are subclass-era wrappers. See K-1,
which lists every site.

### S-26. `PropL2`: 12 of the 13 Raymer Ch. 10 engine-scaling statics are unused

`F16PropL2` calls none of them. Only `engine_weight_AB` is live, and it is
reached from outside, by `F16WeightsL2` and `F16WeightsL3` reading `prop.T_SL`
and `prop.bypass_ratio` off the injected object.

- `engine_length_AB`, `SFC_max_AB`, `SFC_cruise_AB`: called only by
  `TestPropL2`.
- `engine_diam_AB`, `thrust_cruise_AB`: no caller anywhere.
- All six `*_nonAB` statics: no caller anywhere. The whole non-afterburning
  half of the family is unused, which follows from the F-16 being an
  afterburning aircraft.
- `warnIfImplausibleEngineDiameter`: no caller. It guards the two
  `engine_diam_*` statics, neither of which is called.

This is the largest unused block the charts have found. It is not the K-1
wrapper pattern: these are genuine low-level equations with citations, just
with no consumer yet.

### S-27. `TR` is 1.0 by construction, not by measurement

`compute_TR(T_t4_max_R, T_t4_SLS_R)` defaults its second argument to the
first, and `F16PropL2.get.TR` passes only one, because `T_t4_SLS` is unknown.
So the throttle ratio is exactly 1 and every Mattingly lapse branch compares
`theta_0` against 1.0. The class header states this. Worth flagging because
`TR` is a real engine parameter here reduced to a constant by a missing input,
and the default hides it at the call site.

### S-28. `f16a_L2.json`: `engine_model` has no consumer

`.propulsion.engine_model = "F100-PW-200"` is in the JSON, and the constructor
does not read it. A descriptor with no property behind it. The same file's
`bypass_ratio` had this problem until Phase 4 needed it.

### S-29. The two payload weights are inert at every weights level

`W_payload_fixed = 700` and `W_payload_expendable = 4400` are read from the
JSON and stored, and no `WeightsL1`, `WeightsL2` or `WeightsL3` static reads
either one. The source says so and explains why they are set: they satisfy the
`WeightsBase` closure contract and are waiting for the sizing loop.

Recorded because the charts cannot show it. Properties are never nodes, so an
input with no consumer is invisible in a function-level diagram. It is the same
class of gap as `engine_model` in S-28 and `bypass_ratio` before Phase 4, and
the pattern is now three for three: a JSON key can be added, cited and stored
with nothing reading it, and nothing in the test suite objects.

### S-30. `D_fus` means two different things across the injection boundary

`F16WeightsL3.get.D_fus` returns `geom.H_max_fuselage`, the 5.0 ft structural
DEPTH that Raymer Eq. 15.4 takes. The geometry object also has its own
`D_fus`, which is the 6.0 ft Roskam equivalent diameter `(W+H)/2`. Two
quantities, one name, on either side of the injection.

Reading the wrong one gives a fuselage weight that is wrong by the ratio of the
two, with no error. The geometry class header already names this trap. Recorded
because the chart cannot show it: both are property reads, and properties are
never nodes.

### S-31. `WeightsL3.landing_weight` has no textbook source

The gear equations take a landing weight derived from `W_TO`, and the rule that
derives it is uncited. It sets `W_l` for both Eq. 15.5 and Eq. 15.6, so it
scales the whole landing-gear group.

### S-32. Landing gear L2 and L3 are the same class twice

`F16LandingGearL3` has the same four inputs, the same eight derived getters and
the same equations as `F16LandingGearL2`, and it calls L2's statics rather than
defining any. The only differences are the JSON path and the `bay_volume` error
identifier.

The class header already states this is a judgment call, kept to match the
subplan's file list and the parallel JSON block. Recorded because the two charts
are identical apart from three labels, which is the clearest evidence that the
tier split carries no fidelity difference today.

### S-33. `F16SandCL3` injects `prop` and never reads it

The constructor takes five objects and requires all of them. Nothing in the
class reads `prop`. The header says it is stored for future thrust-term use.

The class also READS `component_front_edge_x_ft` from the JSON, ten values, and
uses it nowhere. Both are documented, so neither is a defect. Recorded because
a required argument that is never read still forces every caller to build an
`F16PropL2`, and CLAUDE.md's own rule argues against wiring an unused
collaborator in anticipation. `F16LandingGearL2` made the opposite choice for
the same reason and left geometry out until the citation lands.

### S-34. `Cm0_airfoil_wing` has no source and no default

It defaults to `NaN`, has no JSON key, and `get.Cm_acw` therefore returns `NaN`
until a user assigns it by hand. `Cm_acw` feeds `Cm_cg_trim`, so the trim
moment is unavailable on a freshly constructed object.

### S-35. `f16a_L1.json` subsystems: three keys are read by nobody

`.subsystems.fuel.density_lb_per_gal`, `.subsystems.avionics.weight_fraction`
and `.subsystems.avionics.density_lb_per_ft3` are all present in the JSON, and
`F16SubsystemsL1`'s constructor reads only `fuel_type` and
`aircraft_category_table_row`. Every number comes from a toolbox table instead.

Two of the three DUPLICATE a value the toolbox already holds:
`avionics.density_lb_per_ft3` matches the constant inside
`SubsystemsL1.avionics_density`, and `avionics.weight_fraction` matches the
Table 11.6 midpoint the lookup computes. So the same number exists in two
places with nothing keeping them in agreement, which is the defect class the
Phase 3 `Cfe` change removed elsewhere.

`f16a_L2.json` is worse. NINE unread keys in `.subsystems` alone:

| Key | Duplicates |
| --- | --- |
| `fuel.density_lb_per_gal` | nothing, no consumer |
| `fuel.packaging_factor` | `SubsystemsL2.lookup_packaging_factor`'s returned value |
| `avionics.density_lb_per_ft3` | the constant inside `SubsystemsL2.avionics_density` |
| `avionics.weight_fraction` | the Table 11.6 midpoint the lookup computes |
| `landing_gear.tire_sizing.diameter_coeff_A` and `_B` | `F16LandingGearL2.lookup_tire_sizing_coeffs` |
| `landing_gear.tire_sizing.width_coeff_A` and `_B` | the same switch |

Seven of the nine hold a number that also exists in MATLAB source, with nothing
keeping the two copies in agreement. The tire-sizing four are the clearest: the
JSON carries the Jet fighter/trainer coefficients, and
`F16LandingGearL2`'s constructor reads only the row NAME, then the switch
reproduces the same four numbers.

This is now the fourth site of the unread-JSON-key pattern, after
`engine_model` (S-28), the payload weights (S-29) and `bypass_ratio` before
Phase 4. It is the same defect class the Phase 3 `Cfe` change removed in
aerodynamics: a published constant held as an input invites someone to tune it.

### P-1. PROPOSED, Casey 2026-08-14: renumber the tail-sizing tiers

Casey's proposed resolution of the L3 citation gap:

> The pre-existing L1 should become L2, and the pre-existing L2 should become
> L3. L1 should not exist for tail sizing.

So the tier set becomes L2 and L3 only, with no L1:

| Now | Becomes | Content |
| --- | --- | --- |
| `TailL1` / `F16TailL1` | L2 | Raymer Table 6.4 volume coefficients, arms supplied by the caller |
| `TailL2` / `F16TailL2` | L3 | Nicolai and Carichner Table 11.6 F-16 coefficients, arms from a CG estimate, injected geometry |
| `TailL3` / `F16TailL3` | deleted | the erroring citation-gap tier |

**What this fixes.** The all-red L3 tier disappears, so the discipline no longer
ships a tier that only errors. It also aligns tail sizing with landing gear and
stability and control, which already have no L1. And the new L3 genuinely earns
its number: it injects geometry and derives its own tail arms, where the new L2
takes them from the caller.

**What it does not fix by itself.**

- S-36 survives, renumbered. The new L2 takes six arguments and the new L3 takes
  one, against a base contract that declares six.
- S-38 survives. The two tiers still differ by which textbook supplies the
  coefficients, and neither reads a JSON file, so neither set is an input a
  study can vary.
- S-37 survives for the two remaining enforcers, which are still empty.

**Rename cost, measured.** A straight rename collides, because `TailL2` and
`F16TailL2` already exist, so it needs two steps (old L2 to L3 first, then old
L1 to L2). Call sites to update:

| Symbol | Production call sites | Test and script call sites |
| --- | --- | --- |
| `TailL1.*` | 6, of which 4 are `F16GeomL2`/`F16GeomL3` calling `compute_tail_arm_quarter_chord` | about 30, mostly `TestTailL1` |
| `TailL2.*` | 5, all inside `TailL2` itself | about 18 |
| `F16TailL*` | 24 files mention one of the three, including `SizingLoopL2`, `ControlSurfaceSizer`, two design studies and a run script | included in that count |

The geometry coupling is the item to watch: `F16GeomL2` and `F16GeomL3` reach
into the tail toolbox for `compute_tail_arm_quarter_chord`, so a tail rename
edits geometry. Also `tests/sizing/FixedTailStub.m` calls `TailL1.compute_S_HT`
and `compute_S_VT` directly.

The three tail charts in this folder are named `F16ATail1/2/3_mermaid.md` and
will need renaming and rewriting with the classes.

### S-36. The three tail classes disagree on `size`'s signature

`TailSizingBase` declares one abstract method:

```matlab
result = size(obj, S_ref, b, cbar, L_HT, L_VT)
```

The three concrete classes implement three different arities:

| Class | Signature | Where the data comes from |
| --- | --- | --- |
| `F16TailL1` | `size(obj, S_ref, b, cbar, L_HT, L_VT)` | all five from the caller |
| `F16TailL2` | `size(obj)` | all from the injected geometry object |
| `F16TailL3` | `size(obj, varargin)` | nothing, it errors |

MATLAB does not enforce argument counts on abstract methods, so all three load.
But a caller cannot treat the tier as interchangeable, which is the point of
having a base contract. L3's `varargin` looks like a deliberate accommodation so
a caller written against either real signature still reaches the citation-gap
error instead of an arity error.

Also worth noting: the method is named `size`, which shadows MATLAB's built-in
`size` for these classes. The contract chose the name, so every class must use
it.

### S-37. All three `TailSizingModelL*` enforcers are empty

Each is a `classdef (Abstract) ... < TailSizingBase` with no properties and no
methods. The Tier-2 layer adds nothing at any level. Compare
`SubsystemsModelL1/2/3`, which each declare a real set.

Not a defect. Recorded because it means the three-tier pattern is carrying no
weight in this discipline, and the same question S-32 raises about landing gear
applies: what is the tier for?

### S-38. L1 and L2 tail sizing use different SOURCES, not different fidelities

L1's volume coefficients come from Raymer 7th ed. Table 6.4 plus its text
corrections, selected by category and two configuration flags. L2's are
hardcoded from Nicolai and Carichner Table 11.6's own F-16 row.

The sizing equations are otherwise identical in form. So the tier difference is
which textbook's coefficients are used, plus L2's better tail arm. That is
defensible, but it is not the usual meaning of a fidelity step, and neither
class reads a JSON file, so neither coefficient set is an input a study can
vary.

### S-13. `x_inlet` mislabel in the read-only ground truth

`GroundTruth/f16a_geometry.json` has `inlet_x_ft = 14.0`, which is Brandt
`Main!F32`, the DUCT LENGTH, not an x-station. The real inlet station is
15.0 (`Main!F31`). `BrandtGeometry.nacelleFrameArea` consumes the mislabel,
so its nacelle range is 1.0 ft low at both ends. Numerically harmless on
these 20 stations, wrong on any other grid. Already in
`VnV/BrandtF16A/todo.md` §18.
