# GeomL2

Level-2 geometry static toolbox (`classdef GeomL2`, `methods (Static)` only). Called as
`GeomL2.method(...)`; never instantiated, not in the inheritance chain.

L2 computes component wetted areas from real planform geometry. L3 is the physical / T.O. tier and
has its own toolbox.

A toolbox has no constructor, no inputs and no derived properties.

---

## 1. Methods

| Static | Signature | Returns | Source |
|---|---|---|---|
| `compute_S_wet_planform_roskam` | `(S_exp, tc_r, tc_t, lambda)` | surface `S_wet` [ft²], root/tip t/c pair | Roskam Vol. II Eq. 12.1 |
| `compute_S_wet_planform_raymer` | `(S_exp, tc)` | surface `S_wet` [ft²], uniform t/c | Raymer 6th ed. Eq. 7.11 / 7.12 |
| `compute_s_wet_fus_cyl` | `(D_fus, L_fus)` | fuselage `S_wet` [ft²] | Roskam Vol. II Eq. 12.3 |
| `compute_s_wet_duct` | `(D_inlet, D_exit, L_duct)` | duct `S_wet` [ft²] | Raymer 6th ed. §7.3 |
| `compute_S_exposed_horizontal` | `(c_root, c_tip, hs, fw)` | exposed area [ft²], BOTH panels | Brandt; `readme_geom.md` §4.3 |
| `compute_S_exposed_vertical` | `(S, AR, c_root, c_tip, fh)` | exposed area [ft²], ONE panel | Brandt; `readme_geom.md` §4.3 |
| `compute_S_wet_cylinder` | `(r, L)` | closed cylinder area [ft²] | identity |
| `compute_S_wet_cone` | `(r, L)` | closed cone area [ft²] | identity |

The design class assembles the total. `F16GeomL2.get_design_S_wet_components` makes five calls, one
per component, and sums them.

## 2. Equations

**Lifting surfaces, root/tip t/c** [Roskam Vol. II Eq. 12.1]:

$$S_{wet} = 2\,S_{exp}\left[1 + 0.25\,(t/c)_r\,
  \frac{1 + \dfrac{(t/c)_r}{(t/c)_t}\lambda}{1 + \lambda}\right]$$

**Lifting surfaces, uniform t/c**, the named alternate [Raymer 6th ed. Eq. 7.11 / 7.12]:

$$S_{wet} = 2.003\,S_{exp} \quad (t/c < 0.05) \qquad
  S_{wet} = S_{exp}\,(1.977 + 0.52\,t/c) \quad (t/c \ge 0.05)$$

**Fuselage**, fineness ratio $\lambda_f = L/D$ [Roskam Vol. II Eq. 12.3]:

$$S_{wet} = \pi D L \left(1 - \frac{2}{\lambda_f}\right)^{2/3}
  \left(1 + \frac{1}{\lambda_f^{2}}\right)$$

**Duct**, frustum lateral area [Raymer 6th ed. §7.3]:

$$S_{wet} = \pi (r_1 + r_2)\sqrt{(r_2 - r_1)^2 + L^2}$$

**Exposed areas** are trapezoid clipping at the fuselage. The horizontal form clips inboard and
returns both panels; the vertical clips the lower part and returns one.

## 3. Guards

- **`compute_s_wet_fus_cyl` takes `D_fus`, the equivalent diameter, NOT `W_max_fuselage`.** On the
  F-16 those are 6.0 and 7.0 ft. The width reads fuselage `S_wet` 12.776 % high, total 6.361 % high.
- `compute_s_wet_fus_cyl` errors for $L/D \le 2$ (`GeomL2:invalidFinenessRatio`): Eq. 12.3 returns a
  complex number there.
- `compute_S_wet_planform_roskam` needs $(t/c)_t > 0$ and $\lambda \ge 0$.
- `compute_S_wet_planform_raymer`'s branches meet at $t/c = 0.05$, so it is continuous. Of the
  F-16 surfaces only the wing, at 0.040, takes the Eq. 7.11 branch; the HT and VT roots, 0.060
  and 0.053, take Eq. 7.12.
- `compute_s_wet_duct` reads `D_inlet = D_exit = L_duct = 0` as "no duct", warns
  `GeomL2:noDuctGeometry` and returns 0.
- **A static never takes a design object.** One that read `obj.aircraft_category` would make that
  spelling mandatory for every aircraft using the toolbox.
- **Brandt verifies the framework; he does not supply its equations.**
  `compute_S_wet_planform_raymer` stays because `S_exp*(1.977 + 0.52*t/c)` is Raymer Eq. 7.12 verbatim.

## 4. As-built values

At the live F-16A L2 inputs.

| Call | Value |
|---|---|
| `compute_S_wet_planform_roskam` (wing / HT / VT) | 396.3766599 / 101.3878862 / 83.1398278 ft² |
| `compute_s_wet_fus_cyl` | 730.3023197 ft² |
| `compute_s_wet_duct` | 155.5663631 ft² |
| `compute_S_exposed_horizontal` (wing) | 196.2260692 ft² |
| `compute_S_exposed_vertical` (VT) | 40.8896688 ft² |
| **sum, F-16A L2 `S_wet`** | **1466.7730567 ft²** |
| `compute_S_wet_planform_raymer(196.2260692, 0.04)` | 393.0408166 ft², Eq. 7.11 branch |

## 5. To-dos

| Item | Guard |
|---|---|
| `compute_S_wet_cylinder` and `_cone` return the CLOSED body, so a caller must subtract the attachment face. Start of a generic-shape set: cone, pyramid, sphere, cylinder, oval | in-source note |
| **Roskam Vol. II is not scraped**, so Eq. 12.1 and Eq. 12.3 are UNVERIFIED | this doc |
| `compute_S_exposed_horizontal` and `_vertical` cite Brandt only; a textbook pin should exist. Marked "Don't touch" | this doc |
| **No static sizes the control mechanisms.** No statistical method exists in Raymer, Nicolai or Roskam, so L2 keeps `ControlSurfaceSizer`'s chord fractions; Nicolai Ch. 23's criteria method waits for L3 | in-source note |
| `compute_S_exposed_vertical` computes `sqrt(S*AR)` inside, duplicating `GeometryBase.compute_span` | cancelled by "Don't touch" |
| `hs`, `fw` and `fh` do not say they are half-dimensions, and `fw` is the fuselage HALF-width | cancelled by "Don't touch" |
