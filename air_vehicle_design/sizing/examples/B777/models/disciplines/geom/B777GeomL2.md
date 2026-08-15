# B777GeomL2 — Boeing 777-200LR Level-2 geometry

Companion to `B777GeomL2.m`. Real trapezoidal planform with mean aerodynamic
chord and **exposed** planform areas, per metabook Chapter 7 (Example 7.1).
Replaces `B777GeomL1` (the L1 `S_ref/AR` + Eq. 4.58 wetted-area decomposition).

Source: `docs/reference_extracts/metabook_data.md` §7.2 (Table 7.2/7.3,
Eq. 7.2–7.9); S_ref/AR [Table 4.3]; S_wet_rest [Eq. 4.58].

## 1. Why L2

The component-weight build-up (`B777WeightsL2`, Algorithm 5) needs the **exposed
planform areas** of the wing/H-tail/V-tail and the **wetted area** of the
fuselage (metabook Table 7.1 multipliers). L1 carried only the reference area
and a lumped `S_wet_rest`, so it could not supply them. L2 adds the Table 7.2
equivalent-trapezoidal parameters and derives the exposed/wetted areas and the
MAC from them.

The `L2` tag is the geometry *fidelity*. The class inherits **`GeometryModelL2`**,
which was slimmed on 2026-08-15 to the aircraft-**agnostic** L2 core: exposed
wing/H-tail/V-tail planform areas, H/V-tail reference-area write-back slots, wing
span, fuselage length, and `get_S_wet_fuselage`/`get_S_exposed_wing`. This class
supplies exactly that core. It does **not** carry the F-16's detailed per-surface
drag-build-up geometry (per-surface t/c, LE/TE/QC sweeps, taper, aspect ratios,
root/tip chords, inlet duct, wave-drag `Amax`/`L_aircraft`) — that detail is
fighter-specific, lives concretely on `F16GeomL2`, and a transport with a simple
`Cfe·Swet/Sref` polar has no use for it. It also preserves the `B777GeomL1`
consumer contract (`S_ref`, `S_wet`, `cbar_wing`, `L_fus`/`L_fuselage`,
`n_engines`, `get_S_ref`, `get_S_wet`), so `B777AeroL1`, the tail sizing, and the
constraint/mission stacks read it unchanged.

> **Why `GeometryModelL2` now, not `GeometryModelL1`?** Before the 2026-08-15
> slim, the L2 enforcer *was* the F-16's fully-decomposed member set, so this
> class inherited `GeometryModelL1` to avoid it. With `GeometryModelL2` reduced
> to the agnostic core, that reason is gone: an L2 transport geometry belongs
> under the L2 enforcer, and the weights DI (`B777WeightsL2`) now types its
> injected geom against `GeometryModelL2` rather than the bare `GeometryBase`.

## 2. Inputs (Table 7.2 + fuselage)

| Input | Value | Source |
|---|---|---|
| `S_ref` (design variable) | 4605 ft² | metabook Table 4.3 |
| `AR` | 9.8 | metabook Table 4.3 |
| `S_wet_rest` | 19081 ft² | metabook Eq. 4.58 |
| `L_fus` | 209 ft | _TODO stand-in |
| `wing_trapezoid` | c_root 41.3, c_tip 4.7, b 206.0, Λ_LE 33.7°, x_RLE 64.0 | Table 7.2 |
| `htail_trapezoid` | c_root 23.0, c_tip 8.2, b 71.0, Λ_LE 38.7°, x_RLE 173.4 | Table 7.2 |
| `vtail_trapezoid` | c_root 27.8, c_tip 8.2, b 33.6, Λ_LE 44.4°, x_RLE 166.2 | Table 7.2 |
| `fuselage` | diameter 20.33, width_at_wing 20.65, width_at_htail 9.29, wetted_form_factor 0.9832 | see §4 |

## 3. Derived quantities

| Member | Formula | Baseline value | Source |
|---|---|---|---|
| `S_wet` | `S_wet_rest + 2·S_ref` | 28,291 ft² | Eq. 4.58 |
| `b_wing` / `cbar_wing` | `sqrt(AR·S_ref)` / `S_ref/b_wing` | 212.44 / 21.68 ft | — |
| `S_exposed_wing` | gross trapezoid − fuselage-covered center | **3,923 ft²** | Table 7.3 |
| `S_exposed_ht` | gross trapezoid − tailcone-covered center | **903 ft²** | Table 7.3 |
| `S_exposed_vt` | whole trapezoid (root is exposed) | **604 ft²** | Table 7.3 |
| `S_wet_fus` (= `get_S_wet_fuselage()`) | `π·D·L_fus·wetted_form_factor` | **13,125 ft²** | Table 7.3 |
| `MAC_wing` / `MAC_vtail` | `(2/3)(c_r + c_t − c_r·c_t/(c_r+c_t))` | 27.9 / 19.8 ft | Eq. 7.5/7.8 |
| `x40MAC_wing` | `x_RLE + (b/6)(c_r+2c_t)/(c_r+c_t)·tan Λ + 0.4·MAC` | 100.4 ft | Eq. 7.6 |
| `x40MAC_htail` | (as wing) | 192.1 ft | Eq. 7.7 |
| `x40MAC_vtail` | (as wing but with **2·b**) | 187.6 ft | Eq. 7.9 |

## 4. Exposed-area method and the tuned body widths

`exposed = gross_trapezoid − covered`, where `covered = w_body·c_root −
(c_root−c_tip)/b·(w_body²/2)` (the chord integrated over |y| < w_body/2, both
sides). The V-tail root is the exposed root, so `w_body = 0` and its exposed
area is the whole trapezoid.

The metabook prints the exposed areas (Table 7.3) but **not** the exposed-area
equations, so the local body widths (fuselage ≈ 20.3 ft at the wing, tailcone
≈ 9.3 ft at the H-tail) and the fuselage wetted form factor (`S_wet_fus =
π·D·L·factor`, factor ≈ 0.983 for nose/tail taper) are set to reproduce Table
7.3. Validated in `tests/examples/B777/TestB777Disciplines.m`
(`testExposedAreasMatchTable73`, `testMACAndX40MAC`): 3923.0 / 902.9 / 604.8 /
13124.3, MAC/40%-MAC all matching Eq. 7.5–7.9.

## 5. S_ref coupling (the sizing lever)

`S_ref` is the wing design variable. The wing trapezoid scales isometrically
(linear dims ∝ `sqrt(S_ref/4605)`, holding trapezoidal AR and taper), so the
exposed wing area — and hence the wing weight — tracks a sizing change to
`S_ref`. Because the fuselage width is fixed, a larger wing is covered by a
relatively smaller center, so the exposed **fraction** rises (0.840 at S=4000,
0.852 at 4605, 0.862 at 5200). The H/V-tail and fuselage are held at their
Table 7.2 baseline (the wing is the dominant weight-vs-area lever); `S_ht`/`S_vt`
remain the tail-sizing write-back slots for the aero/tail-volume path.
