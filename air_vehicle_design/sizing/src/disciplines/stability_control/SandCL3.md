# SandCL3

Level-3 stability & control static toolbox (`classdef SandCL3`, `methods (Static)` only). Called as
`SandCL3.method(...)`; never instantiated and not in the inheritance chain. `F16SandCL3` inherits
`SandCModelL3` and delegates here.

**Every method is level-agnostic**: plain scalar arguments only, never reading tier-level `obj`
state — exactly like `AeroL2.CL_alpha`/`AeroL1.oswald_eff`
(`docs/subplans/10_stability_control.md`'s "Fidelity-collapse contingency"). `F16SandCL3` reads its
injected collaborators' CURRENT state, converts units (deg→rad, per-deg→per-rad, x-station→MAC
fraction), and calls these statics; none of that glue lives here.

Primary source: Raymer 6th ed., *Aircraft Design: A Conceptual Approach*, Ch. 16 Sec. 16.3
"Longitudinal Static Stability and Control" (Eqs. 16.8–16.18, 16.25), primary-source page read
2026-08-04 (book pp.585–619) — supersedes an earlier 2026-08-03 web cross-check; see
`VnV/BrandtF16A/todo.md`'s 2026-08-04 entry for the full correction record.

---

## 1. Role

| Layer | Members |
|---|---|
| Eq. 16.12 (aerodynamic center) | `y_MAC_span`, `x_LE_MAC`, `delta_x_ac`, `x_ac_wing`, `x_ac_surface` |
| Eq. 16.25 (fuselage moment) | `Cm_alpha_fus_per_deg`, `Cm_alpha_fus_per_rad` |
| Tail lift-curve slope (reused from Aero) | `CL_alpha_h` |
| Eqs. 16.8/16.9/16.10/16.11 | `Cm_alpha`, `neutral_point`, `Cm_alpha_from_neutral_point`, `static_margin` |
| Eqs. 16.13/16.14 | `CL_w`, `CL_h` |
| Eqs. 16.15/16.16/16.18 | `delta_alpha_L0_elevator` |
| Eqs. 16.5/16.7 (full trim buildup) | `Cm_cg_coefficient` |

## 2. Equations & citations

### Eq. 16.12 — aerodynamic center, longitudinal location

$$y_{MAC} = \frac{b}{6}\frac{1+2\lambda}{1+\lambda} \qquad
  x_{LEMAC} = x_{apex} + y_{MAC}\tan\Lambda_{LE} \qquad
  x_{c/4} = x_{LEMAC} + 0.25\,\bar c$$

$$\Delta x_{ac}(M) = \begin{cases}
  0 & M < 0.4 \\
  0.26(M-0.4)^{2.5} & 0.4 \le M \le 1.1 \\
  0.112 - 0.004M & M > 1.1
\end{cases} \qquad
  x_{ac} = x_{c/4} + \Delta x_{ac}(M)\sqrt{S_{wing}}$$

`y_MAC_span`/`x_LE_MAC` carry no single pinned Raymer equation number — standard linearly-tapered-
wing planform identities (same citation status as `GeometryBase.compute_Amax_elliptical`), matching
`VnV/BrandtF16A/readme_bsc.md`'s own `x_MAC = x_LE,r + y_MAC*tan(Lambda_LE)` formula. All 5
`delta_x_ac` coefficients (`0.26`/`0.4`/`1.1`/`2.5`/`0.112`/`0.004`) are primary-source-confirmed
(2026-08-04, p.594).

`x_ac_surface` applies the SAME `x_c/4` construction WITHOUT the `Delta_x_ac(M)` term, used for the
horizontal tail's aerodynamic center — see that method's own header for why (the Mach-shift
coefficients are calibrated against `S_wing`, and Raymer gives no equivalent tail correction; a
documented simplification, not a citation gap).

**Sanity check** (hand-computed, no MATLAB execution available in this pass — see
`examples/F16A/models/disciplines/sandc/F16SandCL3.md` §6 for the full worked numbers): `x_ac_wing` fed `F16GeomL3`'s own wing
inputs at `M < 0.4` (`Delta_x_ac = 0`) gives `x_acw ≈ 25.591 ft`, within **+0.01%** of Brandt's own
live `S&C (2)` sheet `xacW = 25.589 ft` (`docs/subplans/10_stability_control.md` "Ground Truth") —
strong corroboration despite the different geometry basis (`GeomL3` physical vs. Brandt's own).

### Eq. 16.25 — fuselage pitching-moment-derivative contribution

$$C_{m_\alpha,fus}\,[\text{per deg}] = \frac{K_{fus}\,W_f^2\,L_f}{c\,S_w} \qquad
  C_{m_\alpha,fus}\,[\text{per rad}] = C_{m_\alpha,fus}\,[\text{per deg}] \times \frac{180}{\pi}$$

Explicitly labeled "per deg" in the book (p.603) — the `×(180/pi)` conversion is the exact factor
the legacy `temp_Casey/src/Disciplines/StabAndCont/SandCLevel3.m` `compute_cm_alpha_fuselage` never
applies before using the term inside Eqs. 16.8/16.9 (per-radian throughout). `K_fus` off Fig. 16.14
(NACA TR 711), read by Casey directly at the F-16's actual root-quarter-chord position (44.17% of
fuselage length) → `K_fus ≈ 0.025` — `f16a_L3.json` `.stability_control.fuselage_moment.K_fus`.

### Tail lift-curve slope — `CL_alpha_h`

Reuses `AeroL2.CL_alpha` [Raymer 6th ed. Eq. 12.6/12.8] a second time with the horizontal tail's own
`AR`/quarter-chord sweep substituted for the wing's — not a new Aero method
(`docs/subplans/10_stability_control.md`'s "Eqs. 16.13/16.14/16.15 stay in scope" decision). The
exposed-area knockdown factor and 2-D section lift slope are left empty, exactly as
`F16AeroL2/L3.get_CL_alpha` already does for the wing itself, invoking `AeroL2.CL_alpha`'s own
documented `eta=0.95` default [Eq. 12.8] rather than inventing an HT-specific value.

### Eq. 16.8 — `Cm_alpha`; Eq. 16.9 — neutral point; Eq. 16.10 — bonus cross-check; Eq. 16.11 — static margin

$$C_{m_\alpha} = C_{L_\alpha}(\bar X_{cg}-\bar X_{acw}) + C_{m_\alpha,fus}
  - \eta_h\frac{S_h}{S_w}C_{L_{\alpha h}}\frac{\partial\alpha_h}{\partial\alpha}(\bar X_{ach}-\bar X_{cg})
  + \frac{F_{p\alpha}}{qS_w}\frac{\partial\alpha_p}{\partial\alpha}(\bar X_{cg}-\bar X_p)$$

$$\bar X_{np} = \frac{C_{L_\alpha}\bar X_{acw} - C_{m_\alpha,fus}
  + \eta_h\frac{S_h}{S_w}C_{L_{\alpha h}}\frac{\partial\alpha_h}{\partial\alpha}\bar X_{ach}
  + \frac{F_{p\alpha}}{qS_w}\frac{\partial\alpha_p}{\partial\alpha}\bar X_p}
  {C_{L_\alpha} + \eta_h\frac{S_h}{S_w}C_{L_{\alpha h}}\frac{\partial\alpha_h}{\partial\alpha}
  + \frac{F_{p\alpha}}{qS_w}\frac{\partial\alpha_p}{\partial\alpha}}$$

$$C_{m_\alpha} = -\left(C_{L_\alpha} + \eta_h\frac{S_h}{S_w}C_{L_{\alpha h}}\frac{\partial\alpha_h}{\partial\alpha}\right)(\bar X_{np}-\bar X_{cg}) \qquad \text{[Eq. 16.10, bonus]}$$

$$SM = \bar X_{np} - \bar X_{cg} \qquad \text{[Eq. 16.11 — bare ratio, NO extra /100]}$$

All `X-bar` terms are x-stations **divided by the wing MAC** (`cbar_wing`) — dimensionless,
referenced to a common datum; only DIFFERENCES of `X-bar` terms ever appear, so any common x-datum
works as long as every term shares the same `cbar_wing` divisor (matches
`readme_bsc.md`'s `SM = (x_np-x_cg)/MAC_W` convention). `CL_alpha`/`CL_alpha_h` are per radian;
`Cm_alpha_fus` MUST already be the per-rad form.

**The thrust term is a REQUIRED argument, never a silent default inside this toolbox.**
`F16SandCL3` passes `Fp_alpha_over_qSw=0`/`dalphap_dalpha=0`/`Xp_bar=0` explicitly, invoking Raymer's
own text (p.593): *"It is common to neglect the inlet or propeller force term F_p in Eq. (16.9) to
determine 'power-off' stability... Typically, these allowances for power-on will reduce the static
margin by about 1–3% for jets."*

`Cm_alpha_from_neutral_point` (Eq. 16.10) is a bonus cross-check, not required by the subplan —
implemented because it is essentially free once `neutral_point`/`Cm_alpha` exist.

`static_margin` divides by nothing further — Eq. 16.11 is the bare ratio. The legacy
`temp_Casey` `SandCLevel3.compute_SM` divides by an extra, uncited `100`; this static deliberately
does not.

### Eqs. 16.13/16.14 — wing/tail lift coefficients

$$C_{L_w} = C_{L_\alpha}(\alpha + i_w - \alpha_{0L}) \qquad
  C_{L_h} = C_{L_{\alpha h}}(\alpha + i_h - \varepsilon - \alpha_{0Lh})$$

Angle sums converted deg→rad before multiplying the per-radian lift-curve slope (matches this
repo's existing `deg2rad` convention, e.g. `AeroL2.compute_CL_minD`). `epsilon` (downwash) is a
REQUIRED argument on `CL_h` — `F16SandCL3` would pass `0` explicitly (downwash out of scope), but
`CL_w`/`CL_h`'s F-16 wrappers never reach this static at all — see §3.

### Eqs. 16.15/16.16/16.18 — `Delta alpha_L0` (control-surface deflection family)

$$\alpha_{hL0} = -\left[1.576\left(\frac{c_e}{c}\right)^3 - 3.458\left(\frac{c_e}{c}\right)^2 + 2.882\frac{c_e}{c}\right]\delta_e$$

The GENERAL plain-flap/control-surface family the book applies to "elevator, aileron, and rudder"
alike (primary-source-confirmed 2026-08-04, p.596–598) — NOT a separately-numbered elevator-only
equation, despite the earlier web-cross-check pass's phrasing. Evaluates to `0` identically for the
F-16 (`c_elev_frac=0`, all-moving stabilator, no separate elevator) — a real, expected answer for
this airframe.

### Eqs. 16.5/16.7 — full pitching-moment-about-CG trim buildup

$$C_{m_{cg}} = C_L\frac{x_{cg}-x_{acw}}{\bar c} + C_{m_{acw}} + C_{m_w,\delta_f}\delta_f
  - \eta_h\frac{S_h}{S_w}C_{L_h}\frac{x_{ach}-x_{cg}}{\bar c}
  - \frac{T z_t}{qS_w\bar c} + \frac{F_p(x_{cg}-x_p)}{qS_w\bar c}$$

Eq. 16.5 (dimensional arm lengths, ft) and Eq. 16.7 (same relation, arm lengths as fractions of
`cbar`) are the SAME relation, confirmed by Casey's 2026-08-03 physical-book read. `eta_h*(S_h/S_w)`
stands in for Raymer's own `(q_h*S_h)/(q*S_w)` — `eta_h = q_h/q`, the same tail dynamic-pressure
ratio used in Eqs. 16.8/16.9, kept consistent rather than introducing a second `q_h` variable.

`Cm_cg_coefficient` is **complete and real** — ready the instant a citable `x_p`/`z_t` value exists.
`F16SandCL3.Cm_cg_trim` errors BEFORE ever calling it: the GAP is the F-16 wrapper's missing inputs,
not this formula. Unlike Eq. 16.8/16.9's derivative thrust term, this term is NOT droppable via
Raymer's "power-off" sanction — that sanction is specifically about the Cm_alpha/neutral-point
DERIVATIVE, not the trim moment balance itself.

## 3. Documented citation GAPs — the F-16 wrappers, not these statics

| Quantity | Blocked by | Wrapper | Guard |
|---|---|---|---|
| `CL_w` | wing incidence `i_w` — no citable value anywhere in this repo | `F16SandCL3.CL_w` | `F16SandCL3:wingIncidenceNotAvailable` |
| `CL_h` | tail incidence `i_h` — no citable value anywhere in this repo | `F16SandCL3.CL_h` | `F16SandCL3:tailIncidenceNotAvailable` |
| `Cm_cg_coefficient` | thrust x-location `x_p` and vertical offset `z_t` — no citable value anywhere in this repo | `F16SandCL3.Cm_cg_trim` | `F16SandCL3:thrustLocationNotAvailable` |

See `docs/subplans/10_stability_control.md`'s `_TODO_x_p`/`_TODO_i_w_i_h` notes and the matching
`f16a_L3.json` `.stability_control` keys for the full gap record. No placeholder value is guessed
anywhere for `x_p`, `z_t`, `i_w`, or `i_h`.

## 4. Legacy bugs avoided (from `temp_Casey/src/Disciplines/StabAndCont/SandCLevel3.m`)

| Bug | Fix here |
|---|---|
| `get_np()` stub, no body | Every declared method has a real implementation; GAP methods are documented-error stubs, not empty ones |
| `Xbar_p = 33.775` hardcoded "temporarily" | Never ported — `Cm_cg_trim` errors instead |
| `eta_h` computed then silently overwritten to `0.9` | `eta_h` is a REQUIRED toolbox-static argument; `F16SandCL3` passes `0.90` explicitly, cited to Raymer p.591's "typical value" |
| Ambiguous "FIGURE OUT WHAT C IS" | Every `c`/`cbar` above is the WING MAC (`cbar_wing`) — pinned, not left ambiguous |
| `compute_SM` divides by an extra, uncited `100` | `static_margin` is the bare `Xnp_bar - Xcg_bar` |
| `compute_cm_alpha_fuselage` missing `×180/pi` | `Cm_alpha_fus_per_rad` applies it explicitly, at the one call site that needs it |
