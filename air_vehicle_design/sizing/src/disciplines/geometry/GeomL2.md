# GeomL2

Level-2 geometry static toolbox (`classdef GeomL2`, `methods (Static)` only). Called as
`GeomL2.method(...)`; never instantiated and not in the inheritance chain. Concrete classes such as
`F16GeomL2` inherit `GeometryModelL2` and delegate here.

L2 computes component wetted areas from real planform geometry — exposed areas, thickness ratios,
fuselage envelope, duct dimensions. Geometry has **three** tiers; L3 is the physical/T.O. tier and
has its own toolbox, `GeomL3`.

---

## 1. Role

No static takes a design object. Every one takes scalars or arrays. A design class reads its
own properties and passes them in. The toolbox never learns how a design names things.

| Member | Consumers | Source |
|---|---|---|
| `compute_S_wet_planform_roskam` | 27 | Roskam Vol. II Eq. 12.1 |
| `compute_s_wet_duct` | 11 | Raymer 6th ed. Sec. 7.3 |
| `compute_S_exposed_horizontal` | 6 | Brandt; readme_geom.md Sec. 4.3 |
| `compute_s_wet_fus_cyl` | 4 | Roskam Vol. II Eq. 12.3 |
| `compute_S_wet_planform_raymer` | 4 | Raymer 6th ed. Eq. 7.12 |
| `compute_S_exposed_vertical` | 3 | Brandt; readme_geom.md Sec. 4.3 |

Six statics, all with consumers. None is unused.

## 1a. Changes of 2026-08-18

**The object-taking wrappers are gone.** `get_S_wet`, `get_S_wet_wing/_HT/_VT`,
`get_S_wet_fuselage`, `get_S_wet_duct`, `get_S_exposed_wing` and
`get_S_wet_fuselage_brandt_lowfi` each took a design object, read its properties, and called one
low-level static. They are commented out in the source, with their TODOs kept.

A toolbox must not know how a design names its own properties. A user may call their wingspan
`obj.sneepsnorp` and pass it in the wingspan slot. An object-taking static makes one spelling
mandatory for every aircraft.

**`compute_S_wet_planform_raymer` is Raymer, not Brandt.** The citation said
`[Brandt F-16A.xls, Geom!B13]`. `S_exp*(1.977 + 0.52*t/c)` is Raymer 6th ed. Eq. 7.12 word for
word. Brandt copied Raymer. The citation now names Raymer. The equation did not change, so no
number moved.

Raymer prints a second form, `S_wet = 2.003*S_exp` for `t/c < 0.05` (Eq. 7.11). It is NOT
used. All three F-16 surfaces sit below 0.05 (wing 0.0400, HT 0.0475, VT 0.0415), so the branch
would move every Brandt-alternate number by about +0.26%. It needs sign-off and a new baseline.

**Three Brandt-only statics moved out**, to
`examples/F16A/models/disciplines/geom/F16GeomBrandtAlt.m`:

| Moved | Was cited |
|---|---|
| `compute_s_wet_fus_brandt_lowfi` | Brandt Geom!B3 |
| `compute_s_wet_fus_brandt_highfi` | Brandt Geom!D23 |
| `compute_frame_perimeter` | Brandt frame model |

**Update 2026-08-19.** Casey moved the last two on to the `GeomL3` toolbox, and renamed the second
to `compute_s_wet_from_control_stations`. The integrator has a real citation there
(Raymer 6th ed. Fig. 7.37, p. 206), and the chine is a parameter, so a design with no chine sets
`z_chine = z_center`. See `GeomL3.md`. Only `compute_s_wet_fus_brandt_lowfi` stays in the F-16
example.

Brandt verifies the framework. He does not supply its equations. `compute_frame_perimeter` also
models a "chine", which is an F-16 shape feature, so it cannot be aircraft-agnostic. The
equations are unchanged, so every number holds. Only the comparison report and two tests call
them.

**`F16GeomL2` lost three Dependent properties**: `S_wet_wing`, `S_wet_ht` and `S_wet_vt`, with
their getters. Each getter called a removed method. Consumers now call
`GeomL2.compute_S_wet_planform_roskam` with explicit arguments. Casey chose this on 2026-08-18, over
the alternative of keeping the properties and pointing their getters at the toolbox.

`get_S_wet_fuselage` and `get_S_exposed_wing` STAY on `F16GeomL2`. `GeometryModelL2` declares
both abstract, so the class cannot be built without them.

**One bug fixed on the way.** `get_S_wet_fuselage` passed `W_max_fuselage`, 7.0 ft, the maximum
WIDTH. Roskam Eq. 12.3 takes the equivalent diameter `D_fus`, 6.0 ft. Fuselage `S_wet` read
12.776% high, and total `S_wet` 6.361% high, so drag, fuel and `W_TO` all rose with it. The
argument is now `D_fus`. L2 `W_TO` returns to 23087.2 lbf.

The equation was written twice, once inline in `get_S_wet` and once in `get_S_wet_fuselage`, so
the one fix had to be made twice. That is why a formula should have one home.

**Two statics were left alone.** Casey marked `compute_S_exposed_horizontal` and
`compute_S_exposed_vertical` "This is acceptable. Don't touch." on 2026-08-18. So the approved
rename of `hs`/`fw`/`fh`, and the change of `compute_S_exposed_vertical` to take a span instead
of `S` and `AR`, are both dropped.

### Still open

- **Roskam Vol. II is not scraped.** So `compute_S_wet_planform_roskam` (Eq. 12.1) and
  `compute_s_wet_fus_cyl` (Eq. 12.3) keep unverified citations. `roskam_vol2_data.md` is a
  49-line method summary with no equations. Worse, it numbers Eq. 12.3 as `CD0 = f/S`, not
  fuselage `S_wet`. Confirm both numbers when Vol. II lands.
- **`compute_S_exposed_horizontal` and `_vertical` still cite Brandt.** Both are plain trapezoid
  clipping, so a textbook source should exist. Marked "Don't touch", so the citation stays open.

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
- `compute_S_wet_planform_roskam` requires $(t/c)_t$ strictly positive (guards the ratio) and $\lambda$
  nonnegative (guards $1 + \lambda$).
- `compute_s_wet_fus_brandt_highfi` errors on mismatched per-frame vector lengths.

## 5. To-dos

None.
