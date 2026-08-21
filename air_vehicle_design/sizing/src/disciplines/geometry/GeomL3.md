# GeomL3

Level-3 geometry static toolbox (`classdef GeomL3`, `methods (Static)` only). Called as
`GeomL3.method(...)`; never instantiated and not in the inheritance chain. `F16GeomL3` inherits
`GeometryModelL3` and delegates here.

**L3 is the physical / T.O. 1F-16A-1 tier.** Most equations are *reused* from `GeomL2` and
`GeometryBase` — L3 differs by the inputs it is fed, not by the formulas. The only formulas
originating here are the area-ruled `Amax` buildup and two helpers.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | **none left.** All are removed. `get_Amax` was the last, moved to `F16GeomL3` on 2026-08-19 |
| Low-level — originate here | `denormalize_frames`, `compute_frame_cs_area`(`_exact`), `compute_surface_cs_area`, `compute_nacelle_cs_area`, `compute_Amax_area_ruled`, `compute_c_root_exposed`, `compute_engine_length` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `get_S_wet_wing/_HT/_VT(obj)` | surface wetted area [ft²] | Roskam Vol. II Eq. 12.1, fed the T.O. root/tip t/c splits |
| `get_S_wet_fuselage(obj)` | fuselage wetted area [ft²] | Roskam Vol. II Eq. 12.3 |
| `get_S_wet_duct(obj)` | duct wetted area [ft²] | Raymer 6th ed. Sec. 7.3 |
| `get_S_wet(obj)` | total, including the duct | — |
| ~~`get_Amax(obj)`~~ | **moved to `F16GeomL3` on 2026-08-19.** Its six helpers stay here | Brandt F-16A.xls, Geom!H47 → B20 |

`compute_c_root_exposed` belongs beside `GeomL2`'s exposed-area statics; it lives here because it
was extracted during the `Amax` work.

## 3. Equations

The wetted-area and planform equations are `GeomL2`'s — see `GeomL2.md`. What follows is unique to
this tier.

**Frame rescaling.** The stored table is normalized, so `Amax` responds to the fuselage envelope:

$$x_i = \left(\frac{x}{L}\right)_i L_{fus} \qquad
  w_i = \left(\frac{w}{W_{max}}\right)_i W_{max} \qquad
  h_i = \left(\frac{h}{H_{max}}\right)_i H_{max}$$

**Frame cross-section**, cosine section model, using Brandt's 6-point sampling of
$\int_0^1 \cos(\tfrac{\pi}{2}t)\,dt$:

$$A_{frame} = w\,h \int_0^1 \cos\!\left(\tfrac{\pi}{2}t\right) dt
  \;\approx\; 0.63137515\,w\,h
  \qquad\text{(exact: } 2/\pi = 0.63661977\text{)}$$

**Lifting-surface cross-section** at station $x$, active only for
$X_{exp} < x < X_{exp} + X_{range}$:

$$A_{surf}(x) = \frac{(t/c)\,(c_{exp,root} + c_{tip})\,y_{span}
  \left[1 - \cos(2\pi\xi)\right]}{2}$$

with

$$X_{range} = \max\!\left(c_{exp,root},\; G_{hs,exp}\tan\Lambda_{LE} + c_{tip}\right) \qquad
  y_{span} = \min\!\left(G_{hs,exp},\; \frac{x - X_{exp}}{\tan\Lambda_{LE}}\right) \qquad
  \xi = \frac{x - X_{exp}}{X_{range}}$$

**Nacelle cross-section**, nonzero only between the inlet and the nacelle aft end:

$$A_{nac}(x) = \frac{n_{eng}\,\pi D_{eng}^{2}}{4}$$

**Exposed root chord** — linear taper between root and tip:

$$c_{exp,root} = c_{root} - \frac{b_{clipped}}{b_{root\to tip}}\left(c_{root} - c_{tip}\right)$$

**Engine length** [Brandt F-16A.xls, Geom!D475]: $L_{eng} = 4.5\,D_{eng}$.

**Area-ruled maximum**, less the engine flow-through deduction:

$$A_{max} = \max_x\Big(A_{fuse} + A_{wing} + A_{HT} + A_{VT} + A_{nac}\Big)
  - \frac{n_{eng}\,\pi D_{eng}^{2}}{5}$$

Feeds the Sears-Haack term [Raymer 6th ed. Eq. 12.44] as $(A_{max}/l)^2$. This replaces the
fuselage-envelope ellipse **at this tier only** — L2 keeps
`F16GeomL2.compute_Amax_elliptical` (moved out of `GeometryBase` on 2026-08-19).

## 4. Modelling notes

- **Round-trip control.** Rescaling with $L_{fus} = 46.5$ reproduces Brandt's `Geom!B20` to
  −0.0001 %. At the as-built 47.5 ft the result is 24.703652 ft². The −1.62 % gap is the
  fuselage-length divergence, not a model error.
- **The strake is deliberately absent.** It is active only forward of the governing station, so
  including it changes `Amax` by 0.000 %.
- **Two Brandt spreadsheet bugs are not replicated**: the VT column's wing-tip-chord copy-paste and
  the strake column's divisor. Both are worth 0.000 % here.
- **Canopy bulge.** $\max(h/H_{max}) = 1.50$, so "maximum fuselage depth" is not the tallest frame in
  the table it scales.

## 5. To-dos

| Item | Status |
|---|---|
| The affine frame-rescaling assumption and the cosine area-distribution model have **no textbook source** in this repo. The one lead, Roskam Part VI, is not present | todo.md Phase 2 §4 |
| The flow-through divisor **5** is a bare literal with no justification in the workbook; `readme_geom.md` §4.5 uses 4 for the same nacelle. Using 4 gives $A_{max}$ = 22.738503 (−7.95 %) and makes it thrust-insensitive | todo.md Phase 2 §5 |
| The 6-point frame sampling is a modelling choice, 0.824 % low against the exact integral. `compute_frame_cs_area_exact` is a one-line swap worth +0.759 % on `Amax` — confirm or switch | todo.md Phase 2 §20 |
| The nacelle x-range endpoints differ by 1.0 ft from `readme_geom.md` §4.5, which uses a mislabelled inlet station | todo.md Phase 2 §18 |

## `L_engine` re-cited to Raymer, 2026-08-19

Casey: *"For 'compute_engine_length,' use Raymer's version. Since it's also a statistical method, it
should go in L2, but can be recycled/called from L3."*

The statistical form was already in the repo, in the propulsion L2 toolbox, cited and tested:

| | Formula | Source | F-16A value |
|---|---|---|---|
| Was | `4.5 * D_engine` | Brandt Geom!D475 | 15.9166 ft |
| Now | `PropL2.engine_length_AB(T, M)` = `0.255*T^0.4*M^0.2` | **Raymer 6th ed. Eq. 10.11** | **16.4876 ft** |

So no new function was written. `F16GeomL3.get.L_engine` calls the propulsion static. That satisfies
"it should go in L2": engine length from thrust is engine data, like the nacelle diameter.

Raymer Eq. 10.1 (`L = L_nominal * SF^0.4`) was the other candidate. It needs a nominal engine's
length and thrust, which this repo does not hold, so Eq. 10.11 is the better fit.

**One new input, and a constructor change.** Raymer Eq. 10.11 needs the design Mach, so `F16GeomL3`
gains `M_max`. It is a design requirement, not spec data, so it comes from `f16a_requirements.json`
`.design_mach`, exactly as `F16GeomL1`'s `M_max` does.

The signature is now **`F16GeomL3(json_path, prop, req_path)`**, every argument required, no silent
default. 30 call sites in 22 files updated, all inside the F-16 example and its tests; B777 and
Aero481 do not use this class. `TestGeomL3`'s arity guard gained a case: a two-argument call must
raise `MATLAB:minrhs`.

**What moved.** `L_engine` +3.59 %, and `x_nacelle_aft` 44.9166 to 45.4876 ft with it. **Nothing
downstream moved**: `Amax` still reads 24.7036516658 ft², because no frame station falls in the
0.57 ft the nacelle gained. `S_wet` 1528.6514148855 unchanged. Suite: 964 tests, 22 failures =
19 baseline guards + 3 frozen Aero481 + 0 real.

`GeomL3.compute_engine_length` stays as the record of Brandt's value, flagged SUPERSEDED and
NO CONSUMER.

**One stale comment left alone.** `GeometryModelL3.m:105` still reads `L_engine % = 4.5*D_inlet
[Brandt Geom!D475]`. Casey's 2026-08-18 rule is "Don't touch the Models", so it is reported, not
edited.

---

## Two statics moved IN, 2026-08-19

Casey's decision. Both came from `examples/F16A/models/disciplines/geom/F16GeomBrandtAlt.m`, where
they had landed on 2026-08-18 as Brandt-only content. Bodies unchanged, so the number holds:
**677.9259778028362 ft², bit-exact before and after.**

| Static | Was called | Citation now |
|---|---|---|
| `compute_s_wet_from_control_stations(frame_x, frame_zchine, frame_z, frame_w, frame_h)` | `compute_s_wet_fus_brandt_highfi`, renamed by Casey | **Method: Raymer 6th ed. Fig. 7.37, p. 206.** Perimeter against station, area under the curve = wetted area. Fig. 7.4, p. 171 applies it per component: fuselage, wing, tail, canopy, nacelle. |
| `compute_frame_perimeter(w, h, z_chine, z_center)` | same name | Brandt frame model. **No textbook source** in `docs/reference_extracts/`. |

**Why the integrator belongs in a toolbox.** It is Raymer's graphical-integration method, not
Brandt's. Raymer states it is more accurate than Eq. 7.13, and Fig. 7.4 shows it used per component,
so it is not fuselage-only. That closes the Brandt objection for this half.

**Why the chine stays a parameter, and what that costs.** Casey, 2026-08-19: *"The 'chine' component
should be kept, because if designs don't have a chine, they can set it so that it's 0 or something."*

Measured, so the limit is on the record. Set `z_chine = z_center` for no chine. The outline then has
`y` linear in `t` and `z` cosine in `t`, which is **not** an ellipse:

| Case | Perimeter |
|---|---|
| `compute_frame_perimeter(6, 6, 0, 0)` | 17.5275 ft |
| True circle, `pi*D` | 18.8496 ft |
| Gap | **7.01 % low** |
| Same curve at 101 sample points | 17.5643 ft, still 6.8 % low |

More sample points do not close the gap, because the shape itself differs. So the model suits a
chined body. A round or oval body needs an ellipse perimeter, which this toolbox does not yet hold.
The docstring records this, and the F-16 numbers are unaffected.

Two further limits, carried in the docstrings:

- The leading `(0, 0)` station closes the nose to a point. A component that does not close to a
  point needs a different first station.
- Raymer says to leave joined intersections out of the perimeter. A wing-to-fuselage joint is not
  wetted.

Consumers: `examples/F16A/sanity_checks/geometry_brandt_comparison.m:107` and
`tests/disciplines/TestGeomL2.m:554`. Both repointed from `F16GeomBrandtAlt` to `GeomL3`.

---

## Changes of 2026-08-19 (gate 3)

**Seven object-taking wrappers are gone** from `GeomL3`: `get_S_wet`, `get_S_wet_wing`,
`get_S_wet_HT`, `get_S_wet_VT`, `get_S_wet_fuselage`, `get_S_wet_duct` and
`get_S_exposed_wing`. Casey removed them. `F16GeomL3` still called all seven, so the class
could not run. Every body now calls the toolbox with explicit arguments.

**`F16GeomL3.get_S_wet` became `get_design_S_wet_components`**, to match Casey's
`GeometryModelL3` overhaul of 2026-08-19, where a concrete `get_S_wet` on the enforcer calls
`obj.get_design_S_wet_components()`.

Its old body assigned to `S_wet_wing`, `S_wet_ht`, `S_wet_vt`, `S_wet_fuselage` and
`S_wet_duct`. Three of those are read-only `Dependent`, and the last two are not properties at
all, so the assignments could only error. The sum now uses locals.

**`F16AeroL3.get.S_wet_comp` reads the toolbox, not the geometry class.** It used to read
`g.S_wet_wing`, `g.S_wet_ht`, `g.S_wet_vt` and call `g.get_S_wet_fuselage()` /
`g.get_S_wet_duct()`. Only L3 carries the per-component properties, and the constructor accepts
an L2 **or** an L3 geometry, so those reads worked on L3 and failed on L2. All five terms now
come from `GeomL2` statics, which both tiers can feed.

**Numerically inert.** L3 `S_wet` 1488.2514149, wing 396.3766599, HT 104.0348823, VT
83.1398278, `Amax` 24.7036517. All match the pre-overhaul backup.

### OPEN: eight L3-to-L2 links

Casey retracted approval of the L3-to-L2 link on 2026-08-18, then chose the same day to leave
the links in place and flag them. Resolve in the gate-4b dependency sweep.

| Site | Calls |
|---|---|
| `F16GeomL3.get_design_S_wet_components` | `GeomL2.compute_s_wet_fus_cyl`, `compute_s_wet_duct` |
| `F16GeomL3.get.S_wet_wing` / `_ht` / `_vt` | `GeomL2.compute_S_wet_planform_roskam` x3 |
| `F16GeomL3` lines 400, 442 | `GeomL2.compute_S_exposed_horizontal` x2 |
| `F16GeomL3` line 476 | `GeomL2.compute_S_exposed_vertical` |

Options recorded for the sweep: promote the shared identities to `GeometryBase`, the Tier-1 home
that already holds `compute_span`, `compute_root_chord`, `compute_mac` and `convert_sweep`; or
give `GeomL3` its own copies. The first avoids duplication. The second keeps gate 2 untouched.

### OPEN: S-19, fidelity leak by injection

`F16AeroL3`'s constructor accepts `GeometryModelL2` OR `GeometryModelL3`. With an L2 object,
`Amax` silently becomes the envelope ellipse, 27.4889, instead of the area-ruled buildup,
24.7037. That inflates the Raymer Eq. 12.44 wave-drag term by about 23%, with no error and no
warning. Several `TestAeroL3` and constraint tests inject an L2 geometry today.

### OPEN: citation gaps in GeomL3

| Static | Gap |
|---|---|
| `denormalize_frames` | affine frame rescaling, no textbook source |
| `compute_surface_cs_area` | Brandt's own cosine area-distribution model |
| `compute_Amax_area_ruled` | the `/5` flow-through divisor is a bare literal |
| `compute_engine_length` | `4.5*D`, unsourced |
| `compute_frame_cs_area` | Brandt's 6-point sampling grid |

### Statics with no consumer — flagged, not deleted

`compute_frame_cs_area_exact`, `compute_S_wet_cylinder`, `compute_S_wet_cone`. The last two are
new (Casey, 2026-08-18) and are the start of the generic-shape idea in `GeomL2`'s TODO.

**Resolved 2026-08-19: `get_Amax` moved to `F16GeomL3`.** A design class may read its own
properties, so the wide-signature problem disappears instead of being solved. `Amax` still reads
24.7036516658 ft². The historical note follows.

`get_Amax` is the deferred wide static: it reads about 20 fields off the design object. Casey,
2026-08-17: "Make no changes yet. We'll address that problem once we get there."
