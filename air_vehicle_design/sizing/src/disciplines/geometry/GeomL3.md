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
| High-level — take the concrete object | `get_S_wet`, `get_S_wet_wing/_HT/_VT`, `get_S_wet_fuselage`, `get_S_wet_duct`, `get_S_exposed_wing`, `get_Amax` |
| Low-level — originate here | `denormalize_frames`, `compute_frame_cs_area`(`_exact`), `compute_surface_cs_area`, `compute_nacelle_cs_area`, `compute_Amax_area_ruled`, `compute_c_root_exposed`, `compute_engine_length` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `get_S_wet_wing/_HT/_VT(obj)` | surface wetted area [ft²] | Roskam Vol. II Eq. 12.1, fed the T.O. root/tip t/c splits |
| `get_S_wet_fuselage(obj)` | fuselage wetted area [ft²] | Roskam Vol. II Eq. 12.3 |
| `get_S_wet_duct(obj)` | duct wetted area [ft²] | Raymer 6th ed. Sec. 7.3 |
| `get_S_wet(obj)` | total, including the duct | — |
| `get_Amax(obj)` | whole-aircraft area-ruled max cross-section [ft²] | Brandt F-16A.xls, Geom!H47 → B20 |

`compute_c_root_exposed` belongs beside `GeomL2`'s exposed-area statics; it lives here only because
it was extracted during the `Amax` work.

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
`GeometryBase.compute_Amax_elliptical`.

## 4. Modelling notes

- **Round-trip control.** Rescaling with $L_{fus} = 46.5$ reproduces Brandt's `Geom!B20` to
  −0.0001 %. At the as-built 47.5 ft the result is 24.703652 ft², and that −1.62 % gap is the
  fuselage-length divergence, not a model error.
- **The strake is deliberately absent.** It is active only forward of the governing station, so
  including it changes `Amax` by exactly 0.000 %.
- **Two Brandt spreadsheet bugs are not replicated**: the VT column's wing-tip-chord copy-paste, and
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
