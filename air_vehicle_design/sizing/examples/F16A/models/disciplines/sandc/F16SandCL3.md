# F16SandCL3

F-16A Block 10/15 Level-3 stability & control student class
(`classdef F16SandCL3 < SandCModelL3`). Every abstract member is satisfied by a single delegation
into the `SandCL2`/`SandCL3` static toolboxes — no equations are duplicated here; this file is
DI/unit-conversion glue only. See `src/disciplines/stability_control/SandCL3.md` for the full
equation/citation detail.

---

## 1. Role

The full Raymer 6th ed. Ch. 16 Sec. 16.3 longitudinal-static-stability set that is actually
implementable today (primary-source-corrected 2026-08-04):

| Quantity | Status |
|---|---|
| `x_cg` | fully implemented — SAME static (`SandCL2.weighted_cg`) `F16SandCL2` uses |
| `x_acw` | fully implemented — [Eq. 16.12] |
| `x_ach` | fully implemented — quarter-MAC identity, no Mach-shift term (documented simplification) |
| `CL_alpha_wing` | fully implemented — read directly from Aero, not re-derived |
| `CL_alpha_tail` | fully implemented — reuses `AeroL2.CL_alpha` with HT geometry |
| `Cm_alpha_fus` | fully implemented — [Eq. 16.25] × (180/π) |
| `x_np`, `Cm_alpha` | fully implemented — [Eqs. 16.9, 16.8], thrust term DROPPED (Raymer's own "power-off" sanction) |
| `SM` | fully implemented — [Eq. 16.11], bare `(x_np-x_cg)/cbar_wing`, no `/100` |
| `Delta_alpha_L0(delta_e_deg)` | fully implemented — [Eqs. 16.15/16.16/16.18], evaluates to `0` for the F-16 |
| `Cm_alpha_via_neutral_point()` | fully implemented (bonus, Eq. 16.10 cross-check; not part of the abstract contract) |
| `Cm_acw` | fully implemented — [Eq. 16.19]; returns `NaN` until `Cm0_airfoil_wing` is USER/STUDENT-SUPPLIED (§8) |
| `CL_w(alpha_deg)` | fully implemented — [Eq. 16.13], `i_w=0°` [T.O. 1F-16A-1] (§8) |
| `CL_h(alpha_deg, i_h_deg)` | fully implemented — [Eq. 16.14], `i_h` reframed as a required caller argument (§8) |
| `Cm_cg_trim(alpha_deg, i_h_deg)` | fully implemented — [Eq. 16.5/16.7]; returns `NaN` until `Cm0_airfoil_wing` is supplied (§8) |

## 2. Dependency injection

| Argument | Type | Supplies |
|---|---|---|
| `geom` | `(1,1) F16GeomL3` (CONCRETE) | `x_apex_wing`, `x_le_ht`, `LE_sweep_wing`/`ht`, `b_wing`/`b_ht`, `lambda_wing`/`ht`, `cbar_wing`, `c_root_ht`, `S_ref`, `S_ht`, `AR_ht`, `QC_sweep_ht`, `W_max_fuselage`, `L_fus` |
| `weights` | `(1,1) F16WeightsL3` (CONCRETE) | every component group's WEIGHT (live), plus `weights.cruise_mach` as the ANALYSIS MACH (see §3) |
| `aero` | `(1,1) F16AeroL3` (CONCRETE) | `get_CL_alpha(M)` for the wing lift-curve slope, directly |
| `prop` | `(1,1) F16PropL2` (no L3 propulsion tier exists repo-wide) | stored for completeness/future thrust-term use; not read by any quantity implemented this pass |
| `ctrl` | `(1,1) ControlSurfaceSizer` | `c_elev_frac=0` [Raymer 6th ed. Table 6.5, F-16 all-moving stabilator] — the one input `Delta_alpha_L0` needs |

All five typed CONCRETELY, same rationale as `F16SandCL2`'s `weights` argument (§3 of that file's
doc) — several members read (`x_apex_wing`, `x_le_ht`, `W_strake`, `weight_landing_gear`,
`W_subsystems`, `cruise_mach`) are not on any abstract `GeometryModelL3`/`WeightsBase` contract.

**2026-08-10 fix:** `geom` does NOT supply `c_elev_frac`. The 2026-08-06 tail/control-surface
re-extraction (commit `06c1db9`) moved that property off `F16GeomL3` onto the standalone
`ControlSurfaceSizer` collaborator, but this class (written against the pre-re-extraction state)
kept reading `obj.geom.c_elev_frac` — a property that no longer existed, so `Delta_alpha_L0` errored
at runtime. Fixed by adding `ctrl` as a sixth required constructor argument and reading
`obj.ctrl.c_elev_frac` instead — the SAME `ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90)` object
`design_study_02_L2.m`/`design_study_03_L3.m` already inject into `SizingLoopL2`.

## 3. Judgment call: the analysis Mach is `weights.cruise_mach`, not a new requirements-file read

Every Mach-dependent quantity (`x_acw`'s Eq. 16.12 shift, `CL_alpha_wing`, `CL_alpha_tail`) needs a
flight condition. Rather than adding a SECOND `f16a_requirements.json` read into this class's own
constructor, `F16SandCL3` reuses `obj.weights.cruise_mach` (0.87) — itself already read by
`F16WeightsL3` from `f16a_requirements.json` in its own constructor, for its `SFC_mission` Dependent
property's identical "evaluate at the REQUIREMENTS cruise Mach" convention. This is a DI reuse, not
a new input.

## 4. Component-group weight mapping (`group_weight`, matches the JSON's `weights_property` field)

| Group | Weight source | Notes |
|---|---|---|
| `wing` | `W_wings` | guarded by `requireWTO` |
| `horizontal_tail` | `W_tail.HT` | guarded |
| `vertical_tail` | `W_tail.VT` | guarded |
| `fuselage` | `W_fuselage` | guarded |
| `landing_gear` | `weight_landing_gear(W_TO).main + .nose` | METHOD at L3, not a property; NOT internally guarded (bypasses `requireWTO`, so a `NaN` `W_TO` here silently NaNs rather than erroring — a pre-existing `F16WeightsL3` API asymmetry, not introduced by this class) |
| `installed_engine` | `W_installed_engine` | not `W_TO`-dependent |
| `subsystems_lump` | `W_subsystems` | guarded by `requireWTO` |
| `strake` | `W_strake` | not `W_TO`-dependent |
| `payload` | `W_payload_fixed + W_payload_expendable` | plain properties |
| `fuel` | `W_energy` | mission-analysis STATE, plain property, `NaN` pre-mission — propagates gracefully |

`component_front_edge_x_ft` is read from the JSON (real citations for `wing`/`horizontal_tail`/
`vertical_tail`/`installed_engine`; `NaN` for the other 6) and stored for traceability, but is NOT
consumed by any Eq. 16.x formula this pass — matches `F16SandCL2`'s own "never read it" note (there
it is never even stored, since it is always `null` at L2).

## 5. `eta_h` / `dalphah_dalpha` — explicit, cited, never a silent override

| Property | Value | Citation |
|---|---|---|
| `eta_h` | `0.90` | Raymer 6th ed. p.591: *"[eta_h] ranges from about 0.85–0.95... with 0.90 as the typical value."* |
| `dalphah_dalpha` | `1.0` | `= 1 - d(epsilon)/d(alpha)` [Eq. 16.23]; downwash out of scope this pass (`d(epsilon)/d(alpha)=0`) |

The legacy bug this avoids is not the VALUE `0.90` — it is silently discarding a separately-computed
value with no comment. This class never computes a separate `eta_h`; `0.90` is the only value ever
used, explicitly, with its own citation.

## 6. Hand-verification (no MATLAB execution available in this pass)

No MATLAB MCP tool was available to this implementation pass — the numbers below are hand-computed
from `F16GeomL3`'s own documented input values, not run in MATLAB. Flagged for the coordinator/
test-verifier to confirm numerically.

**`x_acw`** (Eq. 16.12, `M < 0.4` ⇒ `Delta_x_ac = 0`), fed `F16GeomL3`'s wing inputs
(`x_apex_wing=17.786`, `LE_sweep_wing=40°`, `b_wing=30`, `lambda_wing=0.2275`, `cbar_wing≈11.319`):

- `y_MAC ≈ 5.929 ft`, `x_LEMAC ≈ 22.761 ft`, `x_acw ≈ 25.591 ft`
- Compare Brandt's live `S&C (2)` sheet `xacW = 25.589 ft` — **+0.01%**, strong corroboration.

**`x_ach`** (quarter-MAC, no Mach term), fed `F16GeomL3`'s HT inputs (`x_le_ht=36.0`,
`LE_sweep_ht=40°`, `b_ht=18.5`, `lambda_ht=0.2275`, `cbar_ht≈6.612`):

- `y_MAC_ht ≈ 3.657 ft`, `x_LEMAC_ht ≈ 39.069 ft`, `x_ach ≈ 40.722 ft`

**`Cm_alpha_fus`** (`K_fus=0.025`, `W_f=7.0`, `L_f=47.5`, `c≈11.325`, `S_w=300`):

- per-deg `≈ 0.01713`, per-rad `≈ 0.981`

**`x_np`/`SM`** (dropping the thrust term, `eta_h=0.90`, `Sh/Sw=0.36`, `CL_alpha≈CL_alpha_h≈3.27`
[Brandt's own `CLaW=CLaHS=3.2684` used as a ballpark stand-in for this hand-check, not the actual
`AeroL2.CL_alpha` output]):

- `Xnp_bar ≈ 2.360`, `x_np ≈ 26.72 ft` — compare Brandt's Roskam-based ground truth `x_np ≈ 26.168
  ft`: **+2.1%**, a reasonable divergence given the different textbook (Raymer Ch. 16 vs. Roskam
  Ch. 3), different geometry basis, and the dropped thrust term (Raymer's own stated 1–3% SM
  allowance for jets).

## 7. Constructor

`F16SandCL3(json_path, geom, weights, aero, prop)` — all five REQUIRED, no silent default (mirrors
`F16WeightsL3`'s DI convention).

## 8. Gap-closure pass (2026-08-04, Casey's request to close `x_p`/`i_w`/`i_h`)

- **`i_w` CLOSED**: `i_w_deg=0` [T.O. 1F-16A-1, "WINGS" data block: "Incidence ... 0°"] — a real
  primary-source value, now a constructor input (`obj.i_w_deg`, from `f16a_L3.json
  .stability_control.i_w_deg`). `CL_w(obj, alpha_deg)` no longer errors.
- **`i_h` CLOSED, reframed**: not a spec constant — the F-16's all-moving stabilator means `i_h` is
  the trim control variable itself. `CL_h(obj, alpha_deg, i_h_deg)` now takes it as a required
  caller argument (`alpha_0Lh=0°` since the tail's biconvex section is symmetric — T.O. 1F-16A-1).
- **`x_p` CLOSED**: `= obj.geom.x_inlet` (15.0 ft) by DI reuse, justified because Raymer Eqs.
  16.26–16.28 (p.604) define `F_p` as specifically the inlet-front-face normal force.
- **`z_t`/`F_p` CLOSED as documented simplifications**: both 0, cited to Raymer p.604 ("if the
  thrust axis passes through or near the c.g., this term can be ignored") and p.609 ("common in
  early conceptual design to calculate the trim condition without including the thrust effects
  unless the thrust axis is well above or below the c.g.").
- **`Cm_acw`/`Cm_cg_trim` now CLOSED (2026-08-04, same day, Casey's follow-up instruction: "Search
  Raymer's text for an equation for it. If you cannot find it, then the users/students must be able
  to supply their own value.")**: Raymer 6th ed. Eq. 16.19 (p.598, "Wing Pitching Moment") DOES give
  a citable formula, `Cm_acw = Cm0_airfoil·(AR·cos²Λ)/(AR+2cosΛ)` — implemented as
  `SandCL3.Cm_acw_wing`. It bottoms out at `Cm0_airfoil`, the wing section's own 2D zero-lift moment
  coefficient about its AC, which Ch. 16 does not supply and which has no citable NACA 64A204 value
  anywhere in this repo/session. Per Casey's own instruction, this ONE remaining numeric input,
  `Cm0_airfoil_wing`, is USER/STUDENT-SUPPLIED: a plain mutable property, defaults to NaN
  (`f16a_L3.json .stability_control.Cm0_airfoil_wing = null`). `F16SandCL3.Cm_acw`/`Cm_cg_trim` (now
  `Cm_cg_trim(obj, alpha_deg, i_h_deg)` — `i_h_deg` added as a required argument, same reframing as
  `CL_h`) compute and return NaN gracefully whenever `Cm0_airfoil_wing` is unsupplied, rather than
  erroring — `SandCL3.Cm_cg_coefficient` and `SandCL3.Cm_acw_wing` are both complete, real toolbox
  statics; nothing left is architecturally blocked, only one number is unfilled. Two paths remain
  logged (not pursued) for a future pass that wants a citable `Cm0_airfoil_wing` number instead of a
  synthetic test value: Roskam Eq. 3.24's span-integral formula (needs section `cm_ac` data plus the
  wing's twist distribution, T.O. 1F-16A-1: BL 54.0=0°/BL 180.0=3°), or a direct NACA 64A204 airfoil
  report/table lookup.
