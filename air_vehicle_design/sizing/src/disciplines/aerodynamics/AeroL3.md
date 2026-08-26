# AeroL3

Level-3 aerodynamics static toolbox (`classdef AeroL3`, `methods (Static)` only). Called as
`AeroL3.method(...)`; never instantiated, not in the inheritance chain.

L3 replaces L2's equivalent skin friction with a **per-component** Reynolds / skin-friction /
form-factor buildup. The induced terms, the shared skin-friction primitives and the regime test stay
in `AeroL2` as the single source of truth. This toolbox owns only the buildup-specific pieces.

Component geometry reaches the buildup through the concrete class's `Dependent` getters, never as an
object. A toolbox has no constructor, no inputs and no derived properties.

---

## 1. Methods

| Static | Signature | Returns | Source |
|---|---|---|---|
| `compute_Re` | `(state, l_ref)` | Reynolds number | forwards to `AeroL2.compute_Re`, Raymer Eq. 12.25 |
| `Re_cutoff_sub` | `(l, k)` | roughness-limited Re, subsonic | Raymer 6th ed. Eq. 12.28 |
| `Re_cutoff_sup` | `(l, k, M)` | roughness-limited Re, supersonic | Raymer 6th ed. Eq. 12.29 |
| `Cf_laminar` | `(Re)` | laminar skin friction | Raymer 6th ed. Eq. 12.26 |
| `FF_surface` | `(tc, x_c_max, Lambda_m_deg, M)` | lifting-surface form factor | Raymer 6th ed. Eq. 12.30 |
| `FF_body` | `(L_body, D_body)` | body form factor | Raymer 6th ed. Eq. 12.31 |
| `compute_CD0_misc_CD_pi` | `(CD_pi, frontal_area, S_ref)` | misc-item CD0 contribution | Raymer 6th ed. Table 12.6 |
| `compute_CD0_misc_DQ` | `(D_q, S_ref)` | misc-item CD0 contribution | Raymer 6th ed. Table 12.7 |

`compute_Re` is a one-line forward to the identical L2 equation, so the primitive has one home.

Table 12.6 tabulates a dimensionless `CD_pi` = (D/q)/frontal area, so it needs the item's own
frontal area; Table 12.7 gives D/q [ft²] directly.

**The component summation is not here.** `F16AeroL3.CD0_buildup` assembles it, together with the
turbulent `Cf` from `AeroL2` and the aircraft-specific wave-drag term.

## 2. Equations

**Component buildup** [Raymer 6th ed. Eq. 12.24], assembled by the concrete class:

$$C_{D_0} = \frac{\sum_c C_{f,c}\,FF_c\,Q_c\,S_{wet,c}}{S_{ref}}
  + C_{D_0,misc} + C_{D_0,L\&P}$$

**Skin friction**, laminar here [Eq. 12.26] and turbulent from `AeroL2` [Eq. 12.27]. The effective
$C_f$ blends the two by the per-component laminar fraction:

$$C_{f,lam} = \frac{1.328}{\sqrt{Re}}$$

**Cutoff Reynolds number** [Eq. 12.28 subsonic, Eq. 12.29 supersonic], $k$ the surface roughness:

$$Re_{cut} = 38.21\left(\frac{l}{k}\right)^{1.053} \qquad
  Re_{cut} = 44.62\left(\frac{l}{k}\right)^{1.053} M^{1.16}$$

**Surface form factor** [Eq. 12.30], $\Lambda_m$ the max-thickness-line sweep:

$$FF = \left[1 + \frac{0.6}{(x/c)_{max}}\left(\frac{t}{c}\right)
  + 100\left(\frac{t}{c}\right)^{4}\right]
  \left(1.34\,M^{0.18}\cos^{0.28}\Lambda_m\right)$$

**Body form factor** [Eq. 12.31], fineness ratio $f = L/D$:

$$FF = 1 + \frac{5}{f^{1.5}} + \frac{f}{400} \quad (f \le 6)
  \qquad
  FF = 1 + \frac{60}{f^{3}} + \frac{f}{400} \quad (f > 6)$$

Supersonic wave drag [Eq. 12.41, $M \ge 1.2$] is aircraft-specific and lives on the concrete class.
The transonic band is not modelled; see `AeroL2.md`.

## 3. Guards

- `Cf_laminar` requires a positive Reynolds number.
- `FF_surface` guards `x_c_max` positive: it is the `0.6/x_c_max` denominator.
- `FF_body` guards both arguments positive, and branches at $f = 6$.
- `F16AeroL3.CD0_buildup` errors for `state.mach <= 0`. At zero Mach the product is `NaN`, and a
  `NaN` `CD0` makes every constraint comparison false, so the point would report satisfied rather
  than unevaluable.

## 4. Per-component constants

The concrete class supplies these from its `.aerodynamics` JSON block:

| Constant | Source |
|---|---|
| interference factor $Q$ | Raymer 6th ed. §12.6.5, p. 418, prose typical values |
| max-thickness station $(x/c)_{max}$ | airfoil geometry, per surface; no table |
| laminar fraction | Raymer 6th ed. Table 12.4, p. 419 |
| surface roughness $k$ | Raymer 6th ed. Table 12.5 |
| body-or-surface flag | selects Eq. 12.31 over Eq. 12.30 |

## 5. To-dos

| Item | Guard |
|---|---|
| `E_WD`, used by the concrete class's wave-drag term, is a tuned calibration knob, not a measured datum | `TestAeroL3.testTODO_EWDCalibrationInput` |
| The surface-roughness table is Raymer 12.4 / 12.5, not 12.2: citation drift | `TestAeroL3.testTODO_RoughnessTableCitation` |
| The F-16 leading-edge-flap schedule is not pinned | `TestAeroL3.testTODO_LEFScheduleNotPinned` |
