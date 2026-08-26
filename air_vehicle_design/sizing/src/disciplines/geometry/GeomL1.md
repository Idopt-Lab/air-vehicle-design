# GeomL1

Level-1 geometry static toolbox (`classdef GeomL1`, `methods (Static)` only). Called as
`GeomL1.method(...)`; never instantiated and not in the inheritance chain. Concrete classes such as
`F16GeomL1` inherit `GeometryModelL1` and delegate here.

**L1 is a pure statistical tier**: geometry is estimated from takeoff gross weight and design Mach.
There is no planform.

---

## 1. Role

No static takes an aircraft object; every argument is a scalar or a category string.

A `compute_*` takes the **category**, calls its own `lookup_*` for the row, and evaluates the
equation. So a design class makes one call, not two. Each `lookup_*` stays public and returns its
row's coefficients directly.

`lookup_control_surface_fraction` has no `compute_*` partner: a chord fraction is read from the
table, not computed from it, so the lookup is the whole answer.

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `compute_s_wet_regression(aircraft_category, W_TO)` | total wetted area [ft²] | Roskam Vol. I Table 3.5 |
| `compute_l_fus_regression(aircraft_category, W_TO)` | fuselage length [ft] | Raymer 6th ed. Table 6.3 |
| `compute_AR_eq(aircraft_category, M_max)` | equivalent aspect ratio | Raymer 7th ed. Table 4.1 |
| `lookup_swet(aircraft_category)` | $[c, d]$ | Roskam Vol. I Table 3.5 |
| `lookup_lfus(aircraft_category)` | $[a, C]$ | Raymer 6th ed. Table 6.3 |
| `lookup_AR_eq(aircraft_category)` | $[a, C]$ | Raymer 7th ed. Table 4.1 |
| `lookup_control_surface_fraction(aircraft_category, surface)` | chord fraction $C/c$ | Raymer 7th ed. Table 6.5 |

**Tail sizing is not here.** `size_tail`, `compute_tail_volume_coeffs`,
`lookup_tail_volume_coeffs`, `compute_tail_arm`, `compute_S_HT`, and `compute_S_VT` live in
`src/disciplines/tail_sizing/TailL1.m`. Tail sizing and control-surface sizing are standalone
disciplines. See `src/disciplines/tail_sizing/TailSizing_scribe_plan.md` for the equation record.

## 3. Equations

**Wetted area** — Roskam Vol. I Eq. 3.22, p. 122. The book prints the log-log form, fit from 230
aircraft across twelve categories:

$$\log_{10} S_{wet} = c + d \log_{10} W_{TO} \quad\Longrightarrow\quad S_{wet} = 10^{c}\,W_{TO}^{\,d}$$


**Fuselage length** — Raymer 6th ed. Table 6.3:

$$L_{fus} = a\,W_{TO}^{\,C}$$

**Equivalent aspect ratio** — Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row:

$$AR_{eq} = a\,M_{max}^{\,C}$$

## 4. Coefficients

`lookup_swet` — Roskam Vol. I Table 3.5:

| Category | $c$ | $d$ |
|---|---|---|
| `jet_fighter` | −0.1289 | 0.7506 |
| `military_bomber` | 0.1628 | 0.7316 |
| `transport_jet` | 0.0199 | 0.7531 |
| `business_jet` | 0.2263 | 0.6977 |
| `military_cargo` | 0.1628 | 0.7316 |

The `transport_jet` exponent `d = 0.7531` follows disposition D3 (`metabook_data.md` Eq. 4.9 /
Eq. 4.42) and reproduces the printed `S_wet = 10^0.0199 · 766,800^0.7531 = 28,291 ft²`.

Roskam's row 10 is one row covering Mil. Patrol, Bomb *and* Transport, so `military_cargo` and
`military_bomber` both read it. Not a duplicate to collapse.


**Coverage.** The book table has twelve rows; `lookup_swet` holds four (5, 7, 9, 10). Absent:
1 Homebuilts, 2 Single Engine Propeller Driven, 3 Twin Engine Propeller Driven, 4 Agricultural,
6 Regional Turboprops, 8 Military Trainers, 11 Flying Boats/Amph./Float, 12 Supersonic Cruise.

**Limit of use.** Rows 8 and 9 correlate wetted area against **clean** maximum take-off weight, with
no stores (Table 3.5 note, p. 122). The F-16A carries stores in several mission segments, so the
`W_TO` fed to this regression is not always the weight the fit used.

`lookup_lfus` — Raymer 6th ed. Table 6.3, p. 157 (ft from lbf). All 13 printed rows, in book order.
The book also prints metric coefficients in braces; those are not carried.

| Category | $a$ | $C$ |
|---|---|---|
| `sailplane_unpowered` | 0.86 | 0.48 |
| `sailplane_powered` | 0.71 | 0.48 |
| `homebuilt_metal_wood` | 3.68 | 0.23 |
| `homebuilt_composite` | 3.50 | 0.23 |
| `general_aviation_single_engine` | 4.37 | 0.23 |
| `general_aviation_twin_engine` | 0.86 | 0.42 |
| `agricultural` | 4.04 | 0.23 |
| `twin_turboprop` | 0.37 | 0.51 |
| `flying_boat` | 1.05 | 0.40 |
| `jet_trainer` | 0.79 | 0.41 |
| `jet_fighter` | 0.93 | 0.39 |
| `military_cargo` | 0.23 | 0.50 |
| `military_bomber` | 0.23 | 0.50 |
| `transport_jet` | 0.67 | 0.43 |

Raymer prints one **Military cargo/bomber** row, so `military_cargo` and `military_bomber` both read
it, as they read row 10 in `lookup_swet`.

`lookup_AR_eq` — jet-fighter (dogfighter) only: $a = 5.416$, $C = -0.6222$.

`lookup_control_surface_fraction` — Raymer 7th ed. Table 6.5:

| Category | elevator | rudder |
|---|---|---|
| `jet_attack` | 0.30 | 0.30 |
| `jet_fighter` | 0.30 | 0.33 |
| `jet_transport` | 0.25 | 0.32 |
| `jet_trainer` | 0.35 | 0.35 |
| `business_jet` | 0.32 | 0.30 |
| `general_aviation_single_engine` | 0.45 | 0.40 |
| `general_aviation_twin_engine` | 0.36 | 0.46 |
| `sailplane` | 0.43 | 0.40 |

The jet-fighter elevator 0.30 is the all-moving-tail row value, not a hinged-elevator fraction.
**No category has an aileron fraction**, so `'aileron'` errors
(`GeomL1:unknownControlSurface`) on every row.

Every lookup errors (`GeomL1:unknownCategory`) for an unlisted category rather than guessing.

## 5. To-dos

| Item | Guard |
|---|---|
| Raymer Table 6.5 gives **no aileron chord fraction** on any row, so `'aileron'` errors rather than returning a fabricated value | `TestGeomL1.testTODO_AileronFractionNotAvailable` |
| **`military_bomber` resolves here but not in aerodynamics.** `AeroL1.to_CLmax_table_row` still lists `jet_bomber`, not `military_bomber`, so a spec carrying the new canonical value resolves in `lookup_swet` and then errors in `AeroL1` | none |
| Eight of Table 3.5's twelve rows are absent from `lookup_swet`, and `lookup_AR_eq` holds only the jet-fighter row. `lookup_lfus` is complete | in-code TODO on `lookup_AR_eq` |
| `GeometryModelL1.m:30`'s comment still says subclasses use `get_S_wet_statistical`. The abstract member is `get_design_S_wet_categorical`, and the enforcer's concrete `get_S_wet` forwards to it | none |
