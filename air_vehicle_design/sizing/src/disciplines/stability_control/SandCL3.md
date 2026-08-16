# SandCL3

Level-3 stability & control static toolbox (`classdef SandCL3`, `methods (Static)` only). Called as
`SandCL3.method(...)`; never instantiated and not in the inheritance chain. `F16SandCL3` inherits
`SandCModelL3` and delegates here.

**Every method is level-agnostic**: plain scalar arguments only, never reading tier-level `obj`
state — like `AeroL2.CL_alpha`/`AeroL1.oswald_eff`. `F16SandCL3` reads its injected collaborators'
state, converts units (deg→rad, per-deg→per-rad, x-station→MAC fraction), and calls these statics;
none of that glue lives here.

Primary source: Raymer 6th ed., *Aircraft Design: A Conceptual Approach*, Ch. 16 Sec. 16.3
"Longitudinal Static Stability and Control" (Eqs. 16.8–16.18, 16.25), pp.585–619.

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
wing planform identities, matching `VnV/BrandtF16A/readme_bsc.md`'s
`x_MAC = x_LE,r + y_MAC*tan(Lambda_LE)` formula. All 5 `delta_x_ac` coefficients
(`0.26`/`0.4`/`1.1`/`2.5`/`0.112`/`0.004`) are from p.594.

`x_ac_surface` applies the SAME `x_c/4` construction WITHOUT the `Delta_x_ac(M)` term, used for the
horizontal tail's aerodynamic center — the Mach-shift coefficients are calibrated against `S_wing`,
and Raymer gives no equivalent tail correction; a documented simplification, not a citation gap.

**Sanity check** (see `examples/F16A/models/disciplines/sandc/F16SandCL3.md` §6 for the worked
numbers): `x_ac_wing` fed `F16GeomL3`'s wing inputs at `M < 0.4` (`Delta_x_ac = 0`) gives
`x_acw ≈ 25.591 ft`, within **+0.01%** of Brandt's live `S&C (2)` sheet `xacW = 25.589 ft`, despite
the different geometry basis (`GeomL3` physical vs. Brandt's own).

### Eq. 16.25 — fuselage pitching-moment-derivative contribution

$$C_{m_\alpha,fus}\,[\text{per deg}] = \frac{K_{fus}\,W_f^2\,L_f}{c\,S_w} \qquad
  C_{m_\alpha,fus}\,[\text{per rad}] = C_{m_\alpha,fus}\,[\text{per deg}] \times \frac{180}{\pi}$$

Labeled "per deg" in the book (p.603) — the `×(180/pi)` converts the term to per-radian for use
inside Eqs. 16.8/16.9. `K_fus` off Fig. 16.14 (NACA TR 711), read at the F-16's root-quarter-chord
position (44.17% of fuselage length) → `K_fus ≈ 0.025` — `f16a_L3.json`
`.stability_control.fuselage_moment.K_fus`.

### Tail lift-curve slope — `CL_alpha_h`

Reuses `AeroL2.CL_alpha` [Raymer 6th ed. Eq. 12.6/12.8] with the horizontal tail's own
`AR`/quarter-chord sweep in place of the wing's — not a new Aero method. The exposed-area knockdown
factor and 2-D section lift slope are left empty, as `F16AeroL2/L3.get_CL_alpha` does for the wing,
invoking `AeroL2.CL_alpha`'s documented `eta=0.95` default [Eq. 12.8] rather than inventing an
HT-specific value.

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

**The thrust term is a REQUIRED argument, never a silent default.** `F16SandCL3` passes
`Fp_alpha_over_qSw=0`/`dalphap_dalpha=0`/`Xp_bar=0` explicitly, invoking Raymer (p.593): *"It is
common to neglect the inlet or propeller force term F_p in Eq. (16.9) to determine 'power-off'
stability... Typically, these allowances for power-on will reduce the static margin by about 1–3%
for jets."*

`Cm_alpha_from_neutral_point` (Eq. 16.10) is a bonus cross-check, essentially free once
`neutral_point`/`Cm_alpha` exist.

`static_margin` divides by nothing further — Eq. 16.11 is the bare ratio, with no extra `/100`.

### Eqs. 16.13/16.14 — wing/tail lift coefficients

$$C_{L_w} = C_{L_\alpha}(\alpha + i_w - \alpha_{0L}) \qquad
  C_{L_h} = C_{L_{\alpha h}}(\alpha + i_h - \varepsilon - \alpha_{0Lh})$$

Angle sums converted deg→rad before multiplying the per-radian lift-curve slope. `epsilon` (downwash)
is a REQUIRED argument on `CL_h` — `F16SandCL3` would pass `0` (downwash out of scope), but
`CL_w`/`CL_h`'s F-16 wrappers never reach this static — see §3.

### Eqs. 16.15/16.16/16.18 — `Delta alpha_L0` (control-surface deflection family)

$$\alpha_{hL0} = -\left[1.576\left(\frac{c_e}{c}\right)^3 - 3.458\left(\frac{c_e}{c}\right)^2 + 2.882\frac{c_e}{c}\right]\delta_e$$

The general plain-flap/control-surface family the book applies to "elevator, aileron, and rudder"
alike (p.596–598) — NOT a separately-numbered elevator-only equation. Evaluates to `0` for the
F-16 (`c_elev_frac=0`, all-moving stabilator, no separate elevator) — a real, expected answer for
this airframe.

### Eqs. 16.5/16.7 — full pitching-moment-about-CG trim buildup

$$C_{m_{cg}} = C_L\frac{x_{cg}-x_{acw}}{\bar c} + C_{m_{acw}} + C_{m_w,\delta_f}\delta_f
  - \eta_h\frac{S_h}{S_w}C_{L_h}\frac{x_{ach}-x_{cg}}{\bar c}
  - \frac{T z_t}{qS_w\bar c} + \frac{F_p(x_{cg}-x_p)}{qS_w\bar c}$$

Eq. 16.5 (dimensional arm lengths, ft) and Eq. 16.7 (same relation, arms as fractions of `cbar`) are
the SAME relation. `eta_h*(S_h/S_w)` stands in for Raymer's `(q_h*S_h)/(q*S_w)` — `eta_h = q_h/q`,
the same tail dynamic-pressure ratio used in Eqs. 16.8/16.9.

`Cm_cg_coefficient` is complete — ready once a citable `x_p`/`z_t` value exists.
`F16SandCL3.Cm_cg_trim` errors before calling it: the gap is the F-16 wrapper's missing inputs, not
this formula. Unlike Eq. 16.8/16.9's derivative thrust term, this term is NOT droppable via Raymer's
"power-off" sanction — that sanction is about the `Cm_alpha`/neutral-point derivative, not the trim
moment balance.

## 3. Documented citation GAPs — the F-16 wrappers, not these statics

| Quantity | Blocked by | Wrapper | Guard |
|---|---|---|---|
| `CL_w` | wing incidence `i_w` — no citable value anywhere in this repo | `F16SandCL3.CL_w` | `F16SandCL3:wingIncidenceNotAvailable` |
| `CL_h` | tail incidence `i_h` — no citable value anywhere in this repo | `F16SandCL3.CL_h` | `F16SandCL3:tailIncidenceNotAvailable` |
| `Cm_cg_coefficient` | thrust x-location `x_p` and vertical offset `z_t` — no citable value anywhere in this repo | `F16SandCL3.Cm_cg_trim` | `F16SandCL3:thrustLocationNotAvailable` |

See the `f16a_L3.json` `.stability_control` `_TODO_x_p`/`_TODO_i_w_i_h` keys for the full gap record.
No placeholder value is guessed for `x_p`, `z_t`, `i_w`, or `i_h`.

## 4. Conventions pinned

| Item | Here |
|---|---|
| GAP methods | Documented-error stubs, not empty ones; every declared method has a real body |
| `x_p` | Never hardcoded — `Cm_cg_trim` errors instead |
| `eta_h` | REQUIRED toolbox-static argument; `F16SandCL3` passes `0.90` explicitly, cited to Raymer p.591's "typical value" |
| `c`/`cbar` | The WING MAC (`cbar_wing`) throughout — pinned, not ambiguous |
| `static_margin` | The bare `Xnp_bar - Xcg_bar`, no extra `/100` |
| Fuselage per-rad conversion | `Cm_alpha_fus_per_rad` applies `×180/pi` at the one call site that needs it |
