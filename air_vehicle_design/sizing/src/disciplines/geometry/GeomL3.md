# GeomL3

Level-3 geometry static toolbox (`classdef GeomL3`, `methods (Static)` only). Called as
`GeomL3.method(...)`; never instantiated and not in the inheritance chain. `F16GeomL3` inherits
`GeometryModelL3` and delegates here.

**L3 is the physical / T.O. 1F-16A-1 tier.** This is the part where users are encouraged to utilize higher-fidelity geometric analysis methods. This includes, but isn't limited to, methods using control stations. The GeomL3 toolbox has methods for assisting computations of wetted areas if given a series of control stations. There are two. `compute_s_wet_from_perimeter_curve` is Raymer's graphical integration [Raymer 6th ed. Fig. 7.37, p. 206]. `compute_frame_perimeter` came from Brandt. It is one specific chine cosine section, not a basic geometric principle, so it keeps its citation.

---

## 1. Role

| Layer | Members |
|---|---|
| Low-level — originate here | `denormalize_frames`, `compute_frame_cs_area`(`_exact`), `compute_lifting_surface_cs_area`, `compute_nacelle_cs_area`, `compute_Amax_area_ruled`, `compute_c_root_exposed`, `compute_engine_length` |

## 2. Methods

| Method | Arguments | Returns | Source |
|---|---|---|---|
| `denormalize_frames` | frames_normalized, L_fus, W_max, H_max | x, w, h [ft] | generic geometry |
| `compute_frame_cs_area` | w, h | control station area [ft²] | generic geometry, structure from Brandt |
| `compute_frame_cs_area_exact` | w, h | control station area [ft²] | cosine section from Brandt, integral exact (`2/pi`) |
| `compute_c_root_exposed` | c_root, c_tip, span_root_to_tip, span_clipped | exposed root chord length [ft] | Raymer 6th ed, Eq. 14.9 - 14.10 |
| `compute_lifting_surface_cs_area` | x, Xexp, c_exp_root, c_tip, G_hs_exp, sweep_LE_deg, tc | cross-section area [ft²] | Brandt F-16A.xls, Geom!Y/AA/AC 26:45. Cosine area-distribution model, no textbook source |
| `compute_engine_length` | D_engine | engine length [ft] | Brandt F-16A.xls, Geom!D475 |
| `compute_Amax_area_ruled` | A_total_stations, n_engines, D_engine | Maximum cross-sectional area [ft²] | Nicolai & Carichner p. 219 for the flow-through deduction. The `/5` divisor is Brandt's |
| `compute_s_wet_from_perimeter_curve` | x, P | wetted area [ft²] | Raymer 6th ed, Fig 7.37 p206; Fig 7.4, p171|
| `compute_s_wet_from_control_stations` | frame_x, framz_zchine, frame_z, frame_w, frame_h | wetted area [ft²] | Raymer 6th ed, Fig 7.37 p206 |
| `compute_frame_perimeter` | w, h, z_chine, z_center | frame perimeter [ft] | Brandt F-16A.xls, frame model. No textbook source |


`compute_c_root_exposed` belongs beside `GeomL2`'s exposed-area statics; it lives here because it
was extracted during the `Amax` work.

## 3. Equations

The wetted-area and planform equations are `GeomL2`'s — see `GeomL2.md`. This is by choice, since the L3 toolbox's equations require more specific geometry, but both levels can provide similar results, and can be used interchangeably (but I recommend using L3's versions). What follows is unique to
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
- **No chine: set `z_chine = z_center`.** The outline then has $y$ linear in $t$ and $z$ cosine in
  $t$, which is not an ellipse. For a round section of diameter $D$, `compute_frame_perimeter`
  returns 17.5275 ft against the true $\pi D$ = 18.8496, so 7.01 % low, and 101 sample points reach
  only 17.5643. More points do not close the gap, because the shape itself differs. The model suits a
  chined body; a round or oval body needs an ellipse perimeter, which this toolbox does not hold.
- **The leading (0, 0) station closes the nose to a point.** A component that does not close to a
  point needs a different first station.
- **Leave joined intersections out of the perimeter** [Raymer 6th ed. Fig. 7.37, p. 206]. A
  wing-to-fuselage joint is not wetted.

## 5. To-dos

| Item | Status |
|---|---|
| The affine frame-rescaling assumption and the cosine area-distribution model have **no textbook source** in this repo. The one lead, Roskam Part VI, is not present | todo.md Phase 2 §4 |
| The flow-through divisor **5** is a bare literal with no justification in the workbook; `readme_geom.md` §4.5 uses 4 for the same nacelle. Using 4 gives $A_{max}$ = 22.738503 (−7.95 %) and makes it thrust-insensitive | todo.md Phase 2 §5 |
| The 6-point frame sampling is a modelling choice, 0.824 % low against the exact integral. `compute_frame_cs_area_exact` is a one-line swap worth +0.759 % on `Amax` — confirm or switch | todo.md Phase 2 §20 |
| The nacelle x-range endpoints differ by 1.0 ft from `readme_geom.md` §4.5, which uses a mislabelled inlet station | todo.md Phase 2 §18 |
| `GeomL3.compute_engine_length` is SUPERSEDED and has NO CONSUMER. `F16GeomL3.get.L_engine` calls `PropL2.engine_length_AB` instead [Raymer 6th ed. Eq. 10.11]. Kept as the record of Brandt's `4.5*D` | this doc |
| `GeometryModelL3.m:105` still comments `L_engine % = 4.5*D_inlet [Brandt Geom!D475]`, which is stale. The enforcers are off-limits, so it is reported, not edited | this doc |

### Value changes

| Quantity | Now | Record |
|---|---|---|
| F-16A L3 `S_wet` | 1472.0227642 ft² | was 1528.6514149, −3.70 %, 2026-08-24 |
| `L_engine` | 16.4876156 ft | was 15.9166, +3.59 %, 2026-08-19 |
| `x_nacelle_aft` | 45.4876156 ft | was 44.9166, +1.27 %, 2026-08-19 |
| `Amax` | 24.7036517 ft² | unchanged by either, because no frame station falls in the 0.57 ft the nacelle gained |

---

