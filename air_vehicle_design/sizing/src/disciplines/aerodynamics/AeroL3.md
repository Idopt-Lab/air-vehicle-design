# AeroL3

Level-3 aerodynamics static toolbox (`classdef AeroL3`, `methods (Static)` only). Called as
`AeroL3.method(...)`; never instantiated and not in the inheritance chain. `F16AeroL3` inherits
`AeroModelL3` and delegates here.

L3 replaces L2's equivalent skin friction with a **per-component** Reynolds / skin-friction /
form-factor buildup. The induced terms, shared skin-friction primitives and regime test stay in
`AeroL2`; this toolbox owns only the buildup-specific pieces.

**Component order everywhere: wing, HT, VT, fuselage, duct.**

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `drag_polar`, `get_CD0_buildup`, `get_K1`, `get_K2`, `get_e_osw`, `get_CL_alpha`, `compute_Re` |
| Low-level — originate here | `Cf_laminar`, `Re_cutoff_sub`, `Re_cutoff_sup`, `FF_surface`, `FF_body` |

## 2. Equations

**Component buildup** [Raymer 6th ed. Eq. 12.24]:

$$C_{D_0} = \frac{\sum_c C_{f,c}\,FF_c\,Q_c\,S_{wet,c}}{S_{ref}}
  + C_{D_0,misc} + C_{D_0,L\&P}$$

**Skin friction.** Laminar [Eq. 12.26], turbulent [Eq. 12.27, from `AeroL2`]:

$$C_{f,lam} = \frac{1.328}{\sqrt{Re}} \qquad
  C_{f,turb} = \frac{0.455}{\left(\log_{10} Re\right)^{2.58}\left(1 + 0.144M^2\right)^{0.65}}$$

The effective $C_f$ blends the two by the per-component laminar fraction.

**Cutoff Reynolds number** [Eq. 12.28 subsonic, Eq. 12.29 supersonic], with $k$ the surface
roughness:

$$Re_{cut} = 38.21\left(\frac{l}{k}\right)^{1.053} \qquad
  Re_{cut} = 44.62\left(\frac{l}{k}\right)^{1.053} M^{1.16}$$

**Surface form factor** [Eq. 12.30], with $\Lambda_m$ the max-thickness-line sweep:

$$FF = \left[1 + \frac{0.6}{(x/c)_{max}}\left(\frac{t}{c}\right)
  + 100\left(\frac{t}{c}\right)^{4}\right]
  \left(1.34\,M^{0.18}\cos^{0.28}\Lambda_m\right)$$

**Body form factor** [Eq. 12.31], with fineness ratio $f = L/D$:

$$FF = 1 + \frac{5}{f^{1.5}} + \frac{f}{400} \quad (f \le 6)
  \qquad
  FF = 1 + \frac{60}{f^{3}} + \frac{f}{400} \quad (f > 6)$$

**Supersonic wave drag** [Raymer 6th ed. Eq. 12.41, $M \ge 1.2$] is *not* here — it is
aircraft-specific and added by the concrete class's `get_CD0_buildup` override.

## 3. Domain guards

`get_CD0_buildup` errors when `state.mach <= 0`. At zero Mach the product of the terms is `NaN`, and
a `NaN` $C_{D_0}$ makes every constraint comparison false, so the point would report *satisfied*
rather than unevaluable. `Cf_laminar` likewise requires a positive Reynolds number.

The transonic band is not modelled; see `AeroL2.md`.

## 4. Per-component constants

Supplied by the concrete class from its `.aerodynamics` JSON block:
interference factor $Q$ and max-thickness station $(x/c)_{max}$ [Raymer 6th ed. Table 12.6], laminar
fraction, body/surface flag, and surface roughness $k$ [Table 12.4/12.5].

## 5. To-dos

| Item | Guard |
|---|---|
| `E_WD` (used by the concrete class's wave-drag term) is a tuned calibration knob, not a measured datum | `TestAeroL3.testTODO_EWDCalibrationInput` |
| The surface-roughness table is Raymer 12.4/12.5, not 12.2 — citation drift | `TestAeroL3.testTODO_RoughnessTableCitation` |
