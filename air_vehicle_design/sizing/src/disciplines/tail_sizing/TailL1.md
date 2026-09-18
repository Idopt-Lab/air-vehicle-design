# TailL1

Level-1 tail-sizing static toolbox (`classdef TailL1`, `methods (Static)` only). Called as
`TailL1.method(...)`; never instantiated and not in any inheritance chain.

**L1 is the volume-coefficient method**: sizes `S_ht`/`S_vt` from a tail volume coefficient, a tail
moment arm taken as a fraction of fuselage length, and the wing planform (`S_ref`, `b`, `cbar`).
Every argument is a scalar or a string; no static takes a design object.

---

## 1. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `size` | `c_HT`, `c_VT`, `S_ref` [ft^2], `b` [ft], `cbar` [ft], `L_fus` [ft] | struct `S_ht`, `S_vt` [ft^2] | Raymer 7th ed. Table 6.4 + text |
| `compute_tail_volume_coeffs` | `aircraft_category`, `has_rss`, `has_all_moving_tail` | `c_HT`, `c_VT`, corrected | Raymer 7th ed. Table 6.4 + text |
| `lookup_tail_volume_coeffs` | `cat` | `c_HT`, `c_VT`, base | Raymer 7th ed. Table 6.4 |
| `compute_tail_arm` | `L_fus` [ft] | tail moment arm [ft] | Raymer 7th ed. text, aft-mounted engine |
| `compute_tail_arm_wing_mounted` | `L_fus` [ft] | tail moment arm [ft] | **UNCITED**, see §5 |
| `compute_S_HT` | `c_HT`, `cbar`, `S_ref`, `L_HT` | HT area [ft^2] | Raymer 7th ed. Table 6.4 |
| `compute_S_VT` | `c_VT`, `b`, `S_ref`, `L_VT` | VT area [ft^2] | Raymer 7th ed. Table 6.4 |

`size` joins the pieces: arm from `compute_tail_arm`, then the two areas. Its `c_HT`/`c_VT` must
already carry their text corrections. Both area methods delegate to
`TailSizingBase.tail_volume_area`, the one home for `coef * length_scale * S_ref / arm`.

## 2. Equations

**Tail moment arm.** 0.475 is the midpoint of Raymer's stated 0.45 to 0.50 range for an
aft-mounted-engine aircraft:

$$L_{HT} = L_{VT} = 0.475\,L_{fus}$$

**Tail areas from volume coefficients** [Table 6.4]. The horizontal tail uses the mean chord, the
vertical tail uses the span:

$$S_{HT} = \frac{c_{HT}\,\bar{c}\,S_{ref}}{L_{HT}} \qquad
  S_{VT} = \frac{c_{VT}\,b\,S_{ref}}{L_{VT}}$$

**Text corrections**, applied on top of the Table 6.4 base values. The two are independent:

$$c_{HT},\,c_{VT} \mathrel{\times}= (1 - 0.10) \quad \text{relaxed static stability}$$
$$c_{HT} \mathrel{\times}= (1 - 0.125) \quad \text{all-moving stabilator}$$

0.125 is the midpoint of Raymer's stated 10 to 15% range. With both applied to the jet-fighter row:

$$c_{HT} = 0.40 \times 0.90 \times 0.875 = 0.315 \qquad c_{VT} = 0.07 \times 0.90 = 0.063$$

## 3. Coefficients

[Raymer 7th ed. Table 6.4] Two rows implemented.

| Category | `c_HT` | `c_VT` |
|---|---|---|
| `jet_fighter` | 0.40 | 0.07 |
| `jet_transport` | 1.00 | 0.09 |

The `jet_transport` pair also agrees with `metabook_data.md` Ch.8 Eqs. 8.1/8.2. Any other category
errors rather than being guessed.

## 4. Errors

| Identifier | Raised when |
|---|---|
| `TailL1:unknownCategory` | the category matches no implemented Table 6.4 row |
| `MATLAB:validators:mustBePositive` | any length, area or arm argument is zero or negative |

`compute_S_HT` and `compute_S_VT` take `mustBeNonnegative` coefficients, so a zero volume
coefficient is allowed and returns zero area. Every other argument is `mustBePositive`.

## 5. Citation gap

`compute_tail_arm_wing_mounted` returns `0.525 * L_fus` for a wing-mounted-engine transport, the
midpoint of a stated 50 to 55% range. **That text is not in the repository extracts.** It must not
be cited to `metabook_data.md`. `TestB777Disciplines` carries a deliberately-failing
`testTODO_WingMountedTailArmUncited` that guards it until the Raymer text is transcribed.

## 6. Worked example

Independent hand check, not F-16 spec data. `c_HT=0.315`, `c_VT=0.063`, `S_ref=300` ft^2, `b=30` ft,
`cbar=11.320178695127362` ft, `L_fus=46.5` ft:

```
L_HT = L_VT = 0.475 * 46.5                               = 22.087500 ft
S_ht = 0.315 * 11.320178695127362 * 300 / 22.0875        = 48.432683 ft^2
S_vt = 0.063 * 30 * 300 / 22.0875                        = 25.670628 ft^2
```

See `F16TailL1.md` for the F-16 class's own worked example and Brandt comparison.

## 7. Migration record

These statics are ported, not re-derived, from the orphaned `src/disciplines/geometry/GeomL1.m`
methods of the same names. Full history: `docs/decision_log.md`; `TailSizing_scribe_plan.md` Sec. 2.

## 8. TODOs

| Date | Task | Location/function/context |
|---|---|---|
| 9/16/2026 | The 0.525 wing-mounted arm fraction is uncited | `compute_tail_arm_wing_mounted`; guarded by `TestB777Disciplines/testTODO_WingMountedTailArmUncited` |

The generic-versus-F-16-specific coefficient question is resolved at L2; see `TailL2.md`.
