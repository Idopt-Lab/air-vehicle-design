# GeomL2

Level-2 geometry static toolbox (`classdef GeomL2`, `methods (Static)` only). Call it as
`GeomL2.method(...)`. It is never instantiated, and it is not in the inheritance chain. A concrete
class such as `F16GeomL2` inherits `GeometryModelL2` and calls these statics.

L2 computes component wetted areas from real planform geometry: exposed areas, thickness ratios, the
fuselage envelope, and duct dimensions. Geometry has **three** tiers. L3 is the physical and T.O.
tier, and it has its own toolbox, `GeomL3`.

**This is a toolbox, so it has no constructor, no input properties and no derived properties.** Those
three sections exist only in the companion docs of the concrete classes, such as `F16GeomL2.md`. The
sections below describe the statics instead.

---

## 1. Role

No static takes a design object. Each one takes scalars or arrays. A design class reads its own
properties and passes them in. The toolbox never learns how a design names things.

| Static | Call sites | Source |
|---|---|---|
| `compute_S_wet_planform_roskam` | 41 | Roskam Vol. II Eq. 12.1 |
| `compute_s_wet_duct` | 19 | Raymer 6th ed. §7.3 |
| `compute_S_exposed_horizontal` | 11 | Brandt; `readme_geom.md` §4.3 |
| `compute_s_wet_fus_cyl` | 9 | Roskam Vol. II Eq. 12.3 |
| `compute_S_exposed_vertical` | 5 | Brandt; `readme_geom.md` §4.3 |
| `compute_S_wet_planform_raymer` | 4 | Raymer 6th ed. Eq. 7.11 / 7.12 |
| `compute_S_wet_cylinder` | **0** | plain cylinder identity |
| `compute_S_wet_cone` | **0** | plain cone identity |

Eight statics. Six have consumers. **Two have none.** See §5.

## 2. Methods

Every member is a `Static`. None takes a design object.

| Static | Signature | Returns | Source |
|---|---|---|---|
| `compute_S_wet_planform_roskam` | `(S_exp, tc_r, tc_t, lambda)` | surface wetted area [ft²], root/tip t/c pair | Roskam Vol. II Eq. 12.1 |
| `compute_S_wet_planform_raymer` | `(S_exp, tc)` | surface wetted area [ft²], uniform t/c | Raymer 6th ed. Eq. 7.11 / 7.12 |
| `compute_s_wet_fus_cyl` | `(D_fus, L_fus)` | fuselage wetted area [ft²] | Roskam Vol. II Eq. 12.3 |
| `compute_s_wet_duct` | `(D_inlet, D_exit, L_duct)` | duct wetted area [ft²] | Raymer 6th ed. §7.3 |
| `compute_S_exposed_horizontal` | `(c_root, c_tip, hs, fw)` | exposed area [ft²], BOTH panels | Brandt; `readme_geom.md` §4.3 |
| `compute_S_exposed_vertical` | `(S, AR, c_root, c_tip, fh)` | exposed area [ft²], ONE panel | Brandt; `readme_geom.md` §4.3 |
| `compute_S_wet_cylinder` | `(r, L)` | cylinder surface area [ft²] | identity |
| `compute_S_wet_cone` | `(r, L)` | cone surface area [ft²] | identity |

The object-taking `get_*` methods of the earlier version are gone. A design class now assembles the
total itself. `F16GeomL2.get_design_S_wet_components` makes five calls, one per component, and
returns the sum.

The duct is not unconditional any more, because the assembly moved to the design class. A design with
no duct sets `D_inlet = D_exit = L_duct = 0`. `compute_s_wet_duct` reads that exact triple as "no
duct given", gives the warning `GeomL2:noDuctGeometry`, and returns 0. See
`TestGeomL2.testDuctNoDuctGivesWarningAndZero`.

`compute_S_exposed_vertical` still takes `S` and `AR`, and computes `sqrt(S*AR)` inside. That
duplicates `GeometryBase.compute_span`. The caller already holds the span as `obj.b_vt`. The fix is
cancelled, per the "Don't touch" mark.

## 3. Equations

**Lifting surfaces, root and tip t/c** — the official path [Roskam Vol. II Eq. 12.1]:

$$S_{wet} = 2\,S_{exp}\left[1 + 0.25\,(t/c)_r\,
  \frac{1 + \dfrac{(t/c)_r}{(t/c)_t}\lambda}{1 + \lambda}\right]$$

**Lifting surfaces, uniform t/c** — the named alternate, in two branches
[Raymer 6th ed. Eq. 7.11 and Eq. 7.12]:

$$S_{wet} = 2.003\,S_{exp} \quad (t/c < 0.05) \qquad
  S_{wet} = S_{exp}\,(1.977 + 0.52\,t/c) \quad (t/c \ge 0.05)$$

A paper-thin surface gives $2\,S_{exp}$. Thickness raises the area. Eq. 12.1 above is the general
form; this one is its equal-t/c case.

**Fuselage, cylindrical midsection** — the official path [Roskam Vol. II Eq. 12.3], with fineness
ratio $\lambda_f = L/D$:

$$S_{wet} = \pi D L \left(1 - \frac{2}{\lambda_f}\right)^{2/3}
  \left(1 + \frac{1}{\lambda_f^{2}}\right)$$

**Duct** — lateral area of a right circular frustum [Raymer 6th ed. §7.3]:

$$S_{wet} = \pi (r_1 + r_2)\sqrt{(r_2 - r_1)^2 + L^2}$$

**Exposed area of a mirrored surface** — trapezoid clipping at the fuselage side. The fuselage covers
the inboard part, so only the outboard part is exposed. The result counts BOTH panels.

**Exposed area of a vertical tail** — the same idea, with two differences. The fuselage covers the
LOWER part, and there is ONE panel, so there is no doubling.

The two Brandt fuselage forms and the frame-perimeter model are no longer here. See `GeomL3.md` and
`F16GeomBrandtAlt.m`.

## 4. Formula choices and guards

- Wing, HT and VT default to Eq. 12.1. The uniform-t/c Raymer form stays available as a named
  alternate for the comparison report.
- The fuselage defaults to Eq. 12.3. The Brandt forms are named alternates, and they now live
  elsewhere.
- `compute_s_wet_fus_cyl` gives an error (`GeomL2:invalidFinenessRatio`) when $L/D \le 2$. Eq. 12.3
  is invalid there, and it would return a complex number.
- `compute_S_wet_planform_roskam` needs $(t/c)_t$ more than zero, which guards the ratio, and
  $\lambda$ not less than zero, which guards $1 + \lambda$.
- `compute_S_wet_planform_raymer`'s two branches meet at $t/c = 0.05$, so the function is continuous.
  All three F-16 surfaces sit below 0.05, so each takes the Eq. 7.11 branch.
- **`compute_s_wet_fus_cyl` takes `D_fus`, the equivalent diameter, NOT `W_max_fuselage`.** On the
  F-16 those are 6.0 ft and 7.0 ft. Passing the width reads fuselage `S_wet` 12.776 % high and the
  total 6.361 % high, and drag, fuel and `W_TO` all rise with it.
- **A toolbox static never takes a design object.** It takes scalars or arrays, and the design class
  reads its own properties and passes them in. A static that reads `obj.aircraft_category` makes one
  spelling necessary for every aircraft that ever uses the toolbox.
- **Brandt verifies the framework. He does not supply its equations.** A Brandt-only static belongs
  in the aircraft example, not here. `compute_S_wet_planform_raymer` stays because
  `S_exp*(1.977 + 0.52*t/c)` is Raymer Eq. 7.12 word for word; Brandt copied Raymer.

### As-built values

Verified 2026-08-21 at the live F-16A L2 inputs. **No value has changed.**

| Call | Value |
|---|---|
| `compute_S_wet_planform_roskam` (wing) | 396.3766599 ft² |
| `compute_S_wet_planform_roskam` (HT) | 101.3878862 ft² |
| `compute_S_wet_planform_roskam` (VT) | 83.1398278 ft² |
| `compute_s_wet_fus_cyl` | 730.3023197 ft² |
| `compute_s_wet_duct` | 155.5663631 ft² |
| `compute_S_exposed_horizontal` (wing) | 196.2260692 ft² |
| `compute_S_exposed_vertical` (VT) | 40.8896688 ft² |
| **sum, the F-16A L2 `S_wet`** | **1466.7730567 ft²** |

For the alternate path, at the wing exposed area: `compute_S_wet_planform_raymer(196.2260692, 0.04)`
gives 393.0408166 ft², on the Eq. 7.11 branch.

## 5. To-dos

| Item | Guard |
|---|---|
| **`compute_S_wet_cylinder` and `compute_S_wet_cone` have NO CONSUMER.** Both are plain identities. They are the start of a generic-shape set: cone, pyramid, sphere, cylinder and oval, each taking its own dimensions. Both return the CLOSED body, so they count the attachment face, and a caller must subtract it | in-source note above `compute_S_wet_cylinder` |
| **Roskam Vol. II is not scraped**, so the Eq. 12.1 and Eq. 12.3 citations are UNVERIFIED. The only Vol. II extract is a 49-line method summary with no equations | this doc |
| **`compute_S_exposed_horizontal` and `_vertical` cite Brandt only.** Both are plain trapezoid clipping, so a textbook pin should exist. Marked "Don't touch" | this doc |
| **No static sizes the control mechanisms.** Casey, 2026-08-20: *"I'm not seeing a function to size the control mechanisms. Add that."* No statistical method exists in Raymer, Nicolai or Roskam, so L2 keeps the chord-fraction approach of `ControlSurfaceSizer`, and the criteria method (Nicolai Ch. 23) waits for L3 | in-source note |
| `compute_S_exposed_vertical` takes `S` and `AR` and computes the span inside, which duplicates `GeometryBase.compute_span` | cancelled by "Don't touch" |
| The `hs`, `fw` and `fh` argument names do not say what they mean. Each is a half-dimension, and `fw` is the fuselage HALF-width | cancelled by "Don't touch" |
