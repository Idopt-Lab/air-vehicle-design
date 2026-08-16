# GeomL2

Level-2 geometry static toolbox (`classdef GeomL2`, `methods (Static)` only). Called as
`GeomL2.method(...)`; never instantiated and not in the inheritance chain. Concrete classes such as
`F16GeomL2` inherit `GeometryModelL2` and delegate here.

L2 computes component wetted areas from real planform geometry — exposed areas, thickness ratios,
fuselage envelope, duct dimensions. Geometry has **three** tiers; L3 is the physical/T.O. tier and
has its own toolbox, `GeomL3`.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `get_S_wet`, `get_S_wet_wing/_HT/_VT`, `get_S_wet_fuselage`, `get_S_wet_duct`, `get_S_exposed_wing`, `get_S_wet_fuselage_brandt_lowfi` |
| Low-level — scalars and arrays only | `compute_*` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `get_S_wet(obj)` | total: wing + HT + VT + fuselage + duct | — |
| `get_S_wet_wing/_HT/_VT(obj)` | surface wetted area [ft²] | Roskam Vol. II Eq. 12.1 |
| `get_S_wet_fuselage(obj)` | fuselage wetted area [ft²] | Roskam Vol. II Eq. 12.3 |
| `get_S_wet_duct(obj)` | duct wetted area [ft²] | Raymer 6th ed. Sec. 7.3 |
| `get_S_exposed_wing(obj)` | passthrough of `obj.S_exposed_wing` | — |
| `compute_S_exposed_horizontal/_vertical` | exposed planform area [ft²] | Brandt F-16A.xls; `readme_geom.md` §4.3 |

`get_S_wet` takes no `W_TO` argument (contrast L1) and includes the duct unconditionally; a concrete
class with no duct sets `D_inlet = D_exit = L_duct = 0`. `compute_s_wet_duct` treats this exact triple
as "no duct given," warns (`GeomL2:noDuctGeometry`), and returns 0. See
`TestGeomL2.testDuctNoDuctGivesWarningAndZero`.

## 3. Equations

**Lifting surfaces, variable root/tip t/c** — the official path
[Roskam Vol. II Eq. 12.1]:

$$S_{wet} = 2\,S_{exp}\left[1 + 0.25\,(t/c)_r\,
  \frac{1 + \dfrac{(t/c)_r}{(t/c)_t}\lambda}{1 + \lambda}\right]$$

**Lifting surfaces, uniform t/c** — Brandt's own form, kept as a named alternate. It is the special
case $(t/c)_r = (t/c)_t$ of the above [Brandt F-16A.xls, Geom!B13]:

$$S_{wet} = S_{exp}\,(1.977 + 0.52\,t/c)$$

**Fuselage, cylindrical midsection** — the official path [Roskam Vol. II Eq. 12.3], with fineness
ratio $\lambda_f = L/D$:

$$S_{wet} = \pi D L \left(1 - \frac{2}{\lambda_f}\right)^{2/3}
  \left(1 + \frac{1}{\lambda_f^{2}}\right)$$

**Fuselage, Brandt low-fidelity** — "⅓-cone + ⅔-cylinder" [Brandt F-16A.xls, Geom!B3]:

$$D_{avg} = \frac{w_{max} + h_{max}}{2} \qquad
  S_{wet} = \frac{5}{6}\,\pi D_{avg} L$$

**Fuselage, Brandt high-fidelity** — trapezoidal integration of per-frame perimeter
[Brandt F-16A.xls, Geom!D23]:

$$S_{wet} = \sum_i \frac{P_i + P_{i+1}}{2}\,\Delta x_i$$

with each perimeter from the cosine cross-section model, sampled at 6 points per quarter and doubled
for symmetry.

**Duct** — lateral area of a right circular frustum [Raymer 6th ed. Sec. 7.3]:

$$S_{wet} = \pi (r_1 + r_2)\sqrt{(r_2 - r_1)^2 + L^2}$$

## 4. Formula choices and guards

- Wing/HT/VT default to Eq. 12.1; the Brandt uniform-t/c form stays available as a named alternate
  for the comparison report.
- The fuselage defaults to Eq. 12.3; both Brandt forms are named alternates.
- `compute_s_wet_fus_cyl` errors (`GeomL2:invalidFinenessRatio`) when $L/D \le 2$, where Eq. 12.3 is
  invalid and would otherwise return a complex number.
- `compute_roskam_planform` requires $(t/c)_t$ strictly positive (guards the ratio) and $\lambda$
  nonnegative (guards $1 + \lambda$).
- `compute_s_wet_fus_brandt_highfi` errors on mismatched per-frame vector lengths.

## 5. To-dos

None.
