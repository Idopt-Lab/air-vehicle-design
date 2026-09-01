# GeomL3

Level-3 geometry static toolbox (`classdef GeomL3`, `methods (Static)` only). Called as
`GeomL3.method(...)`; never instantiated, not in the inheritance chain.

**L3 is the physical / T.O. 1F-16A-1 tier**, for higher-fidelity methods such as control stations.
Two statics compute wetted area from a station table: `compute_s_wet_from_perimeter_curve` is
Raymer's graphical integration [Fig. 7.37, p. 206]; `compute_frame_perimeter` is Brandt's chine
cosine section, one specific shape model rather than a general principle, so it keeps its citation.

The planform and wetted-area equations are `GeomL2`'s. What follows is unique to this tier.

A toolbox has no constructor, no inputs and no derived properties.

---

## 1. Methods

| Static | Arguments | Returns | Source |
|---|---|---|---|
| `denormalize_frames` | frames_normalized, L_fus, W_max, H_max | x, w, h [ft] | unit scaling |
| `compute_frame_cs_area` | w, h | station area [ft²] | Brandt cosine section, 6-point sampling |
| `compute_frame_cs_area_exact` | w, h | station area [ft²] | same section, exact `2/pi` |
| `compute_c_root_exposed` | c_root, c_tip, span_root_to_tip, span_clipped | chord LENGTH [ft] | Raymer 6th ed. Eq. 14.9-14.10, p. 502 |
| `compute_lifting_surface_cs_area` | x, Xexp, c_exp_root, c_tip, G_hs_exp, sweep_LE_deg, tc | cross-section [ft²] | Brandt `Geom!Y/AA/AC 26:45`, no textbook source |
| `compute_nacelle_cs_area` | x, n_engines, D_engine, x_start, x_end | cross-section [ft²] | circle-area identity |
| `compute_Amax_area_ruled` | A_total_stations, n_engines, D_engine | `Amax` [ft²] | Nicolai p. 219 for the deduction; `/5` is Brandt's |
| `compute_s_wet_from_perimeter_curve` | x, P | wetted area [ft²] | Raymer 6th ed. Fig. 7.37 p. 206, Fig. 7.4 p. 171 |
| `compute_s_wet_from_control_stations` | frame_x, frame_zchine, frame_z, frame_w, frame_h | wetted area [ft²] | Raymer 6th ed. Fig. 7.37 p. 206 |
| `compute_frame_perimeter` | w, h, z_chine, z_center | perimeter [ft] | Brandt frame model, no textbook source |
| `compute_engine_length` | D_engine | engine length [ft] | Brandt `Geom!D475`, $4.5 D$ |

`compute_c_root_exposed` belongs beside `GeomL2`'s exposed-area statics; it landed here during the
`Amax` work.

## 2. Equations

**Frame rescaling.** The stored table is normalized, so `Amax` responds to the envelope:

$$x_i = \left(\frac{x}{L}\right)_i L_{fus} \qquad
  w_i = \left(\frac{w}{W_{max}}\right)_i W_{max} \qquad
  h_i = \left(\frac{h}{H_{max}}\right)_i H_{max}$$

**Frame cross-section**, Brandt's 6-point sampling of the cosine section:

$$A_{frame} = w\,h \int_0^1 \cos\!\left(\tfrac{\pi}{2}t\right) dt
  \;\approx\; 0.63137515\,w\,h \qquad\text{(exact: } 2/\pi = 0.63661977\text{)}$$

**Lifting-surface cross-section** at station $x$, active for $X_{exp} < x < X_{exp} + X_{range}$:

$$A_{surf}(x) = \frac{(t/c)\,(c_{exp,root} + c_{tip})\,y_{span}
  \left[1 - \cos(2\pi\xi)\right]}{2}$$

$$X_{range} = \max\!\left(c_{exp,root},\; G_{hs,exp}\tan\Lambda_{LE} + c_{tip}\right) \qquad
  y_{span} = \min\!\left(G_{hs,exp},\; \frac{x - X_{exp}}{\tan\Lambda_{LE}}\right) \qquad
  \xi = \frac{x - X_{exp}}{X_{range}}$$

**Nacelle cross-section**, nonzero only between inlet and nacelle aft end:
$A_{nac} = n_{eng}\pi D_{eng}^{2}/4$.

**Exposed root chord**, linear taper:
$c_{exp,root} = c_{root} - \dfrac{b_{clipped}}{b_{root\to tip}}(c_{root} - c_{tip})$.

**Engine length** [Brandt `Geom!D475`]: $L_{eng} = 4.5\,D_{eng}$.

**Area-ruled maximum**, less the engine flow-through deduction:

$$A_{max} = \max_x\Big(A_{fuse} + A_{wing} + A_{HT} + A_{VT} + A_{nac}\Big)
  - \frac{n_{eng}\,\pi D_{eng}^{2}}{5}$$

Feeds the Sears-Haack term [Raymer 6th ed. Eq. 12.44] as $(A_{max}/l)^2$. L2 keeps the
fuselage-envelope ellipse instead.

## 3. Modelling notes

- **Round-trip control.** Rescaling with $L_{fus} = 46.5$ reproduces Brandt's `Geom!B20` to
  −0.0001 %. At the as-built 47.5 ft the result is 24.703652 ft²; the −1.62 % gap is the
  fuselage-length divergence, not a model error.
- **The strake is absent from `Amax`.** It is active only forward of the governing station, so
  including it moves `Amax` by 0.000 %.
- **Two Brandt spreadsheet bugs are not replicated**: the VT column's wing-tip-chord copy-paste and
  the strake column's divisor. Both worth 0.000 % here.
- **Canopy bulge.** $\max(h/H_{max}) = 1.50$, so "maximum fuselage depth" is not the tallest frame.
- **No chine: set `z_chine = z_center`.** The outline is then not an ellipse. For a round section of
  diameter $D$, `compute_frame_perimeter` returns 17.5275 ft against $\pi D$ = 18.8496, 7.01 % low,
  and 101 sample points reach only 17.5643. The model suits a chined body.
- **The leading (0, 0) station closes the nose to a point.** A component that does not needs a
  different first station.
- **Leave joined intersections out of the perimeter** [Raymer Fig. 7.37]. A wing-to-fuselage joint is
  not wetted.

## 4. As-built values

At the live F-16A L3 inputs:

| Quantity | Value |
|---|---|
| `S_wet` | 1472.0227642 ft² |
| `Amax` | 24.7036517 ft² |
| `L_engine` | 16.4876156 ft |
| `x_nacelle_aft` | 45.4876156 ft |
| `D_inlet` | 3.5370222 ft |

`L_engine` comes from `PropL2.engine_length_AB` [Raymer 6th ed. Eq. 10.11], not from this
toolbox's `compute_engine_length`, which on the same `D_inlet` returns 15.9166001 ft.

## 5. To-dos

| Item | Status |
|---|---|
| The affine frame-rescaling assumption and the cosine area-distribution model have **no textbook source** here. The one lead, Roskam Part VI, is absent | todo.md Phase 2 §4 |
| The flow-through divisor **5** is a bare literal; `readme_geom.md` §4.5 uses 4 for the same nacelle. Using 4 gives $A_{max}$ = 22.738503 (−7.95 %) and makes it thrust-insensitive | todo.md Phase 2 §5 |
| The 6-point frame sampling is 0.824 % low against the exact integral. `compute_frame_cs_area_exact` is a one-line swap worth +0.759 % on `Amax`; confirm or switch | todo.md Phase 2 §20 |
| The nacelle x-range endpoints differ by 1.0 ft from `readme_geom.md` §4.5, which uses a mislabelled inlet station | todo.md Phase 2 §18 |
| `compute_engine_length` holds Brandt's `4.5*D`. Raymer 6th ed. Eq. 10.11 is the cited alternative, in `PropL2.engine_length_AB` | this doc |
| `GeometryModelL3.m:105` still comments `L_engine % = 4.5*D_inlet [Brandt Geom!D475]`, which is stale. Enforcers are off-limits, so it is reported | this doc |
