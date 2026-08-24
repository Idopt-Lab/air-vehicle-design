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

## 1a. Changes of 2026-08-18

**The object-taking wrappers are gone.** `get_S_wet`, `get_S_wet_wing/_HT/_VT`,
`get_S_wet_fuselage`, `get_S_wet_duct`, `get_S_exposed_wing` and
`get_S_wet_fuselage_brandt_lowfi` each took a design object, read its properties, and called one
low-level static. They are commented out in the source, and their TODOs stay.

A toolbox must not know how a design names its own properties. A user can call their wingspan
`obj.sneepsnorp` and pass it in the wingspan slot. An object-taking static makes one spelling
necessary for every aircraft.

**`compute_S_wet_planform_raymer` is Raymer.** The citation said
`[Brandt F-16A.xls, Geom!B13]`. `S_exp*(1.977 + 0.52*t/c)` is Raymer 6th ed. Eq. 7.12 word for word.
Brandt copied Raymer. The citation now names Raymer. The equation did not change, so no number moved.

**The Eq. 7.11 branch is now in the code.** An earlier version of this doc said the second Raymer
form was not used. That is no longer true. The static now selects between the two forms:

    t/c <  0.05:  S_wet = 2.003 * S_exp                [Raymer 6th ed. Eq. 7.11]
    t/c >= 0.05:  S_wet = S_exp * (1.977 + 0.52*t/c)   [Raymer 6th ed. Eq. 7.12]

All three F-16 surfaces sit below 0.05 (wing 0.0400, HT 0.0475, VT 0.0415), so each one now takes the
Eq. 7.11 branch. The three Brandt-alternate rows moved: wing +0.260 %, HT +0.065 %, VT +0.221 %.
Casey wrote the branch and approved the move.

The two forms meet exactly at `t/c = 0.05`, because `1.977 + 0.52*0.05 = 2.003`. So the branch is
continuous, and no step appears at the threshold.

**Three Brandt-only statics moved out**, to
`examples/F16A/models/disciplines/geom/F16GeomBrandtAlt.m`:

| Moved | Was cited |
|---|---|
| `compute_s_wet_fus_brandt_lowfi` | Brandt `Geom!B3` |
| `compute_s_wet_fus_brandt_highfi` | Brandt `Geom!D23` |
| `compute_frame_perimeter` | Brandt frame model |

**Update 2026-08-19.** Casey moved the last two on to the `GeomL3` toolbox, and renamed the second to
`compute_s_wet_from_control_stations`. The integrator has a real citation there (Raymer 6th ed.
Fig. 7.37, p. 206), and the chine is a parameter, so a design with no chine sets
`z_chine = z_center`. See `GeomL3.md`. Only `compute_s_wet_fus_brandt_lowfi` stays in the F-16
example.

Brandt verifies the framework. He does not supply its equations. `compute_frame_perimeter` also
models a chine, which is an F-16 shape feature, so it cannot be aircraft-agnostic. The equations did
not change, so every number holds. Only the comparison report and two tests call them.

**`F16GeomL2` lost three Dependent properties**: `S_wet_wing`, `S_wet_ht` and `S_wet_vt`, with their
getters. Each getter called a removed method.

**Reversed 2026-08-24.** Casey put the three back, and added `S_wet_duct`. Each getter now calls the
toolbox with explicit arguments, which is the alternative that was open on 2026-08-18. So a consumer
may read `g2.S_wet_wing` again, and the toolbox still takes no design object. That is why the
call-site counts in §1 went up.

`get_S_exposed_wing` STAYS on `F16GeomL2`. It is the one method `GeometryModelL2` still declares
abstract, so the class cannot be built without it. `get_S_wet_fuselage` is no longer part of that
contract: the enforcer now declares only `get_S_exposed_wing`, plus the abstract properties `b_wing`
and `S_exposed_wing`.

**One bug fixed on the way.** `get_S_wet_fuselage` passed `W_max_fuselage`, 7.0 ft, the maximum
WIDTH. Roskam Eq. 12.3 takes the equivalent diameter `D_fus`, 6.0 ft. Fuselage `S_wet` read 12.776 %
high, and total `S_wet` 6.361 % high, so drag, fuel and `W_TO` all rose with it. The argument is now
`D_fus`. L2 `W_TO` returns to 23087.2 lbf.

The equation was written twice, once inline in `get_S_wet` and once in `get_S_wet_fuselage`, so the
one fix had to be made twice. That is why a formula needs one home.

**Two statics were left alone.** Casey marked `compute_S_exposed_horizontal` and
`compute_S_exposed_vertical` "This is acceptable. Don't touch." on 2026-08-18. So the approved rename
of `hs`, `fw` and `fh`, and the change of `compute_S_exposed_vertical` to take a span in place of `S`
and `AR`, are both dropped.

### Still open

- **Roskam Vol. II is not scraped.** So `compute_S_wet_planform_roskam` (Eq. 12.1) and
  `compute_s_wet_fus_cyl` (Eq. 12.3) keep unverified citations. `roskam_vol2_data.md` is a 49-line
  method summary with no equations. Worse, it numbers Eq. 12.3 as `CD0 = f/S`, not fuselage `S_wet`.
  Confirm both numbers when Vol. II arrives.
- **`compute_S_exposed_horizontal` and `_vertical` still cite Brandt.** Both are plain trapezoid
  clipping, so a textbook source should exist. Marked "Don't touch", so the citation stays open.

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
