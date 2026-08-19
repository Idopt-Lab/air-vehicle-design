# GeomL1

Level-1 geometry static toolbox (`classdef GeomL1`, `methods (Static)` only). Called as
`GeomL1.method(...)`; never instantiated and not in the inheritance chain. Concrete classes such as
`F16GeomL1` inherit `GeometryModelL1` and delegate here.

**L1 is a pure statistical tier**: geometry is estimated from takeoff gross weight and design Mach.
There is no planform.

---

## 1. Role

No static takes an aircraft object. A `lookup_*` returns the coefficients of one table row. A
`compute_*` evaluates one equation on coefficients the caller supplies. The design class picks
the row, then feeds the equation.

| Layer | Members |
|---|---|
| Equations — scalars only | `compute_s_wet_regression`, `compute_l_fus_regression`, `compute_AR_eq` |
| Tables — category string in, coefficients out | `lookup_swet`, `lookup_lfus`, `lookup_AR_eq`, `lookup_control_surface_fraction` |

The design class holds the two steps, so the path is visible where it is used:

```matlab
function val = get_S_wet(obj, W_TO)
    [c, d] = GeomL1.lookup_swet(obj.aircraft_category);
    val    = GeomL1.compute_s_wet_regression(c, d, W_TO);
end
```

`lookup_control_surface_fraction` has no `compute_*` partner. A chord fraction is read from the
table, not computed from it, so the lookup is the whole answer.

## 1a. Removed 2026-08-17

Five statics took an aircraft object. A toolbox must not know how a design names its own
properties: a user may call their wingspan `obj.sneepsnorp` and pass it in the wingspan slot.
An object-taking static makes one spelling mandatory for every aircraft. Removing them also
makes each static testable from literals, with no JSON and no constructor.

| Removed | Replaced by |
|---|---|
| `get_S_wet_statistical(obj, W_TO)` | `lookup_swet` + `compute_s_wet_regression`, joined in the design class |
| `get_L_fus(obj, W_TO)` | `lookup_lfus` + `compute_l_fus_regression` |
| `get_AR_eq(obj)` | `lookup_AR_eq` + `compute_AR_eq(a, C, M_max)` |
| `get_control_surface_fraction(obj, surface)` | `lookup_control_surface_fraction(cat, surface)` |
| `compute_control_surface_fraction` | `lookup_control_surface_fraction`. It was a pure pass-through. |

`compute_AR_eq` also stopped calling `lookup_AR_eq` for the caller. It now takes `(a, C, M_max)`.

Call sites updated: `F16GeomL1`, `Aero481GeomL1`, `TestGeomL1`. `TestGeomL1`'s
`testGetControlSurfaceFractionObjectLevel` was deleted: it covered only the removed wrapper and
duplicated `testControlSurfaceFractionElevator`'s assertion of 0.30.

The change is numerically inert. The equations and coefficients did not change.

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `compute_s_wet_regression(c, d, W_TO)` | total wetted area [ft²] | Roskam Vol. I Eq. 3.22, p. 122 |
| `compute_l_fus_regression(a, c, W_TO)` | fuselage length [ft] | Raymer 6th ed. Table 6.3 |
| `compute_AR_eq(a, C, M_max)` | equivalent aspect ratio | Raymer 7th ed. Table 4.1 |
| `lookup_control_surface_fraction(cat, surface)` | chord fraction $C/c$ | Raymer 7th ed. Table 6.5 |

**Tail sizing is not here.** `size_tail`, `compute_tail_volume_coeffs`,
`lookup_tail_volume_coeffs`, `compute_tail_arm`, `compute_S_HT`, and `compute_S_VT` live in
`src/disciplines/tail_sizing/TailL1.m`. Tail sizing and control-surface sizing are standalone
disciplines. See `src/disciplines/tail_sizing/TailSizing_scribe_plan.md` for the equation record.

## 3. Equations

**Wetted area** — Roskam Vol. I Eq. 3.22, p. 122. The book prints the log-log form, fit from 230
aircraft across twelve categories:

$$\log_{10} S_{wet} = c + d \log_{10} W_{TO} \quad\Longrightarrow\quad S_{wet} = 10^{c}\,W_{TO}^{\,d}$$

Citation closed 2026-08-17 by the Roskam Vol. I scrape. Before that the equation number was open,
because the repo held only Roskam Ch. 2.

**Fuselage length** — Raymer 6th ed. Table 6.3:

$$L_{fus} = a\,W_{TO}^{\,C}$$

**Equivalent aspect ratio** — Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row:

$$AR_{eq} = a\,M_{max}^{\,C}$$

## 4. Coefficients

`lookup_swet` — Roskam Vol. I Table 3.5:

| Category | $c$ | $d$ |
|---|---|---|
| `jet_fighter` | −0.1289 | 0.7506 |
| `jet_bomber` | 0.1213 | 0.7306 |
| `transport_jet` | 0.0199 | 0.7531 |
| `business_jet` | 0.2263 | 0.6977 |
| `military_cargo` | −0.0866 | 0.8099 |

The `transport_jet` exponent is `d = 0.7531` per disposition D3 (`metabook_data.md` Eq. 4.9 /
Eq. 4.42). It reproduces the printed `S_wet = 10^0.0199 · 766,800^0.7531 = 28,291 ft²`. The
`jet_fighter` row (the F-16A path) is unaffected.

### 4a. `lookup_swet` against the printed Table 3.5 — OPEN, 2026-08-17

Casey supplied the Table 3.5 page scan, so the **book** is the reference here, not the extract.
Three of five rows agree. Two do not. **No coefficient was changed.** Rule 3: log a discrepancy,
never resolve it alone.

| Code row | Code $c$, $d$ | Book row | Book $c$, $d$ | Finding |
|---|---|---|---|---|
| `jet_fighter` | −0.1289, 0.7506 | 9. Fighters | −0.1289, 0.7506 | agrees |
| `transport_jet` | 0.0199, 0.7531 | 7. Transport Jets | 0.0199, 0.7531 | agrees |
| `business_jet` | 0.2263, 0.6977 | 5. Business Jets | 0.2263, 0.6977 | agrees |
| `military_cargo` | −0.0866, 0.8099 | **6. Regional Turboprops** | −0.0866, 0.8099 | right numbers, **wrong row**. Roskam's military-cargo equivalent is row 10, Mil. Patrol/Bomb/Transport, at 0.1628, 0.7316. |
| `jet_bomber` | **0.1213, 0.7306** | 10. Mil. Patrol/Bomb/Transport | 0.1628, 0.7316 | matches no book row, and appears nowhere in `docs/reference_extracts/`. No source. |

Neither row is used today. F-16A and Aero481 are `jet_fighter`; B777 is a transport on L2 geometry.
So a correction changes no number in any current report.

**Docs error found in the same check.** `reference_extracts/Roskam_Vol_I/02_sizing_to_performance_requirements_part1.md:525`
transcribes Business Jets `d` as `0.6971`. The book reads `0.6977`. The extract is wrong; the code
is right. A scraped extract is a secondary source and can carry a transcription error, so compare
against the page scan before logging a discrepancy against working code.

**Coverage.** The book table has twelve rows. `lookup_swet` holds four of them (5, 6, 7, 9) plus the
unsourced `jet_bomber`. Absent: 1 Homebuilts, 2 Single Engine Propeller Driven, 3 Twin Engine
Propeller Driven, 4 Agricultural, 8 Military Trainers, 10 Mil. Patrol/Bomb/Transport, 11 Flying
Boats/Amph./Float, 12 Supersonic Cruise.

**Limit of use.** Rows 8 and 9 correlate wetted area against **clean** maximum take-off weight, with
no stores (Table 3.5 note, p. 122). The F-16A carries stores in several mission segments, so the
`W_TO` fed to this regression is not always the weight the fit used.

`lookup_lfus` — Raymer 6th ed. Table 6.3 (ft from lbf):

| Category | $a$ | $C$ |
|---|---|---|
| `jet_fighter` | 0.93 | 0.39 |
| `jet_trainer` | 0.79 | 0.41 |
| `transport_jet` | 0.67 | 0.43 |
| `military_cargo` | 0.23 | 0.50 |

Jet-fighter only: `lookup_AR_eq` $a = 5.416$, $C = -0.6222$; `lookup_control_surface_fraction`
elevator 0.30 (the all-moving-tail row value, not a hinged-elevator fraction), rudder 0.33.

Every lookup errors (`GeomL1:unknownCategory`) for an unlisted category rather than guessing.

## 5. To-dos

| Item | Guard |
|---|---|
| Raymer Table 6.5's jet-fighter row carries **no aileron chord fraction**, so `'aileron'` errors rather than returning a fabricated value | `TestGeomL1.testTODO_AileronFractionNotAvailable` |
| `lookup_swet`: `military_cargo` holds the Regional Turboprops row, and `jet_bomber` has no source. See §4a. Needs sign-off before any change | none; §4a is the record |
| Eight of Table 3.5's twelve rows are absent, as are most rows of `lookup_AR_eq` and `lookup_control_surface_fraction`. The printed tables are now in the repo | none |
| **S-2, open.** `GeometryBase` declares `get_S_wet(obj, W_TO)`; `GeometryModelL1` declares `get_S_wet_statistical(obj, W_TO)`. Two names, one quantity, so every L1 geometry class carries both methods. Dropping the `_statistical` declaration would clear the duplicate from `F16GeomL1`, `Aero481GeomL1` and `B777GeomL2`, and would touch `TestGeomL1`, `TestB777Disciplines` and `TestAero481Disciplines` | none |
