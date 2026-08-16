# B777WeightsL2 — Boeing 777-200LR Level-2 weights (component build-up)

Companion to `B777WeightsL2.m`. The metabook Chapter 7 component build-up
(Algorithm 5, Example 7.1). Replaces `B777WeightsL1` (the L1 empty-weight
FRACTION + linear deltas).

**Inherits `WeightsModelL2`** — the aircraft-agnostic Tier-2 enforcer whose whole
purpose is this build-up ("surface density × area for the structural groups,
plus fractions of gross weight for landing gear, installed engine and
all-else-empty"). It exposes the same six component-weight Dependents
(`W_wings`, `W_tail`, `W_fuselage`, `W_landing_gear`, `W_installed_engine`,
`W_all_else_empty`) as `F16WeightsL2` and delegates every `weight_*` method to
the shared `WeightsL2` toolbox — so `OEW = WeightsL2.OEW(obj, W_TO)`. The only
per-aircraft differences from the F-16 are the `jet_transport` category
(Table 15.2 transport densities + 0.043 gear fraction), the Roskam engine model
(vs the fighter's Raymer Eq. 10.10), and no strake term.

Source: `docs/reference_extracts/metabook_data.md` §7.2 (Algorithm 5, Table
7.1/7.3); Raymer Table 15.2 areal densities; Roskam engine Eqs. 7.13–7.19.

## 1. The build-up

```
Wengine = Weng_dry + Weng_oil + Weng_rev + Weng_control + Weng_start   (Roskam 7.13-7.19, per engine, UNINSTALLED, at T0 = prop.T_SL/n)
OEW = 1.3·n·Wengine                        installed engine     [Table 7.1 1.3x]
    + 10.0·S_exposed_wing                  wing                 [Table 7.1 x Table 7.3 exposed area]
    + 5.5 ·S_exposed_ht                    H-tail
    + 5.5 ·S_exposed_vt                    V-tail
    + 5.0 ·get_S_wet_fuselage()            fuselage             [Table 7.1 x WETTED area]
    + 0.043·W0                             landing gear (transport)
    + 0.17 ·W0                             all-else empty
```

The exposed/wetted areas come from the injected `B777GeomL2` — read through the
`GeometryModelL2` core contract (`S_exposed_wing/ht/vt`, `get_S_wet_fuselage()`);
Table 7.3 — the
per-engine thrust `T0 = prop.T_SL/n` comes from the injected prop. The Table
7.1 areal densities and fractions are read from the `WeightsL2`/`WeightsL1`
toolbox statics (`wing_unit_weight` 10, `HT/VT_unit_weight` 5.5,
`fus_unit_weight` 5, `LG_fraction` 0.043, `engine_weight_roskam`).

## 2. Responds to all three sizing variables

| Variable | Path | Effect |
|---|---|---|
| **W0** | `0.043·W0 + 0.17·W0` | gear + all-else scale with gross weight |
| **S_ref** | `geom.S_exposed_wing` | a bigger wing → bigger exposed area → heavier wing |
| **T0** | `prop.T_SL / n` → Roskam | more thrust → heavier engine |

The closure is stable because the structural terms are **fixed**
(geometry/thrust, not W0), so only the `0.213·W0` gear+all-else fraction scales
— `We/W0` falls as `W0` rises.

## 3. Baseline value and the two metabook decisions

At the baseline (W0 = 766,800, S_ref = 4605, prop.T_SL = 220,000 → 110k/engine),
OEW ≈ **334,043 lb** — component breakdown validated in
`TestB777Disciplines.testOEWComponentBuildup`.

- **Installed engine 1.3×** (discrepancy D8): Algorithm 5's pseudocode omits the
  1.3, but Table 7.1/7.3 apply it (47,476 = 1.3·36,520), and the 323,778 total
  includes it. This class applies the 1.3.
- **Engine thrust** (discrepancy D9): Table 7.3 only reproduces at 89k/engine
  (178k total), but the constraint/T–S diagrams use 220k. **This class uses the
  sizing `prop.T_SL`** (USER decision 2026-08-15), so the engine responds to the
  real thrust. At 220k the Roskam engine is ~10k heavier than Table 7.3, so OEW
  ≈ 334k (+4% vs actual 320k — the Roskam regression over-predicts the modern
  GE90), NOT Table 7.3's 323,778.

## 4. Sizing result

With the L2 geom + weights, cruise M0.85, and the metabook Example 2.1 mission
(9,150 nmi + 30-min loiter, 78,821 lb crew+payload), `converge_W0(220000, 4605)`
closes to **W_TO ≈ 760,220 lb (−0.86% vs the real 766,800)**, OEW ≈ 332,640
(+3.95%). See `sanity_checks/b777_metabook_comparison.m`.
