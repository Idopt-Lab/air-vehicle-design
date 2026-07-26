# GeomL1

Level-1 geometry static toolbox (`classdef GeomL1`, `methods (Static)` only). Called as
`GeomL1.method(...)`; never instantiated and not in the inheritance chain. Concrete classes such as
`F16GeomL1` inherit `GeometryModelL1` and delegate here.

**L1 is a pure statistical tier**: geometry is estimated from takeoff gross weight and design Mach.
There is no planform.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `get_S_wet_statistical`, `get_L_fus`, `get_AR_eq`, `get_control_surface_fraction` |
| Low-level — scalars and strings only | `compute_*` |
| Constants | `lookup_*`, one per `compute_*` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `get_S_wet_statistical(obj, W_TO)` | total wetted area [ft²] | Roskam Vol. I Table 3.5 |
| `get_L_fus(obj, W_TO)` | fuselage length [ft] | Raymer 6th ed. Table 6.3 |
| `get_AR_eq(obj)` | equivalent aspect ratio | Raymer 7th ed. Table 4.1 |
| `get_control_surface_fraction(obj, surface)` | chord fraction $C/c$ | Raymer 7th ed. Table 6.5 |
| `compute_tail_volume_coeffs(cat, has_rss, has_all_moving_tail)` | $c_{HT}$, $c_{VT}$ | Raymer 7th ed. Table 6.4 + text |
| `compute_tail_arm(L_{fus})` | tail moment arm [ft] | Raymer 7th ed. text rule |
| `compute_S_HT`, `compute_S_VT` | tail areas [ft²] | Raymer 7th ed. Table 6.4 |

## 3. Equations

**Wetted area** — Roskam Vol. I Table 3.5:

$$S_{wet} = 10^{c}\,W_{TO}^{\,d}$$

**Fuselage length** — Raymer 6th ed. Table 6.3:

$$L_{fus} = a\,W_{TO}^{\,C}$$

**Equivalent aspect ratio** — Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row:

$$AR_{eq} = a\,M_{max}^{\,C}$$

**Tail areas from volume coefficients** — Raymer 7th ed. Table 6.4:

$$S_{HT} = \frac{c_{HT}\,\bar{c}\,S_{ref}}{L_{HT}} \qquad
  S_{VT} = \frac{c_{VT}\,b\,S_{ref}}{L_{VT}}$$

**Tail moment arm** — Raymer 7th ed., aft-mounted single-engine text rule (0.475 is the midpoint of
the stated 0.45–0.50 range):

$$L_{HT} = L_{VT} = 0.475\,L_{fus}$$

**Tail-volume text corrections** applied on top of the Table 6.4 base values:

$$c_{HT},\,c_{VT} \mathrel{\times}= (1 - 0.10) \quad \text{if relaxed static stability}$$
$$c_{HT} \mathrel{\times}= (1 - 0.125) \quad \text{if all-moving stabilator}$$

The 0.125 is the midpoint of Raymer's stated 10–15 % range. For the F-16 both apply, giving
$c_{HT} = 0.315$ and $c_{VT} = 0.063$.

## 4. Coefficients

`lookup_swet` — Roskam Vol. I Table 3.5:

| Category | $c$ | $d$ |
|---|---|---|
| `jet_fighter` | −0.1289 | 0.7506 |
| `jet_bomber` | 0.1213 | 0.7306 |
| `transport_jet` | 0.0199 | 0.7351 |
| `business_jet` | 0.2263 | 0.6977 |
| `military_cargo` | −0.0866 | 0.8099 |

`lookup_lfus` — Raymer 6th ed. Table 6.3 (ft from lbf):

| Category | $a$ | $C$ |
|---|---|---|
| `jet_fighter` | 0.93 | 0.39 |
| `jet_trainer` | 0.79 | 0.41 |
| `transport_jet` | 0.67 | 0.43 |
| `military_cargo` | 0.23 | 0.50 |

Jet-fighter only: `lookup_AR_eq` $a = 5.416$, $C = -0.6222$; `lookup_tail_volume_coeffs`
$c_{HT} = 0.40$, $c_{VT} = 0.07$; `lookup_control_surface_fraction` elevator 0.30 (the
all-moving-tail row value, not a hinged-elevator fraction), rudder 0.33.

Every lookup errors (`GeomL1:unknownCategory`) for an unlisted category rather than guessing.

## 5. To-dos

| Item | Guard |
|---|---|
| Raymer Table 6.5's jet-fighter row carries **no aileron chord fraction**, so `'aileron'` errors rather than returning a fabricated value | `TestGeomL1.testTODO_AileronFractionNotAvailable` |
