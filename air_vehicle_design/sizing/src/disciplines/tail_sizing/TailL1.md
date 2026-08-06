# TailL1

Level-1 tail-sizing static toolbox (`classdef TailL1`, `methods (Static)` only). Called as
`TailL1.method(...)`; never instantiated and not in the inheritance chain. `F16TailL1` inherits
`TailSizingModelL1` and delegates here.

**L1 is the volume-coefficient method**: sizes `S_ht`/`S_vt` from a tail volume coefficient, an
assumed tail moment arm (a fraction of fuselage length), and the wing planform (`S_ref`, `b`,
`cbar`) supplied as raw scalars by the caller.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `size` |
| Low-level — scalars and strings only | `compute_tail_volume_coeffs`, `compute_tail_arm`, `compute_S_HT`, `compute_S_VT` |
| Constants | `lookup_tail_volume_coeffs` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `size(obj, S_ref, b, cbar, L_fus)` | `struct('S_ht', S_ht, 'S_vt', S_vt)` | Raymer 7th ed. Table 6.4 + text |
| `compute_tail_volume_coeffs(cat, has_rss, has_all_moving_tail)` | `c_HT`, `c_VT` (corrected) | Raymer 7th ed. Table 6.4 + text |
| `lookup_tail_volume_coeffs(cat)` | `c_HT`, `c_VT` (base) | Raymer 7th ed. Table 6.4 |
| `compute_tail_arm(L_fus)` | tail moment arm [ft] | Raymer 7th ed. text rule |
| `compute_S_HT(c_HT, cbar, S_ref, L_HT)` | HT area [ft²] | Raymer 7th ed. Table 6.4 |
| `compute_S_VT(c_VT, b, S_ref, L_VT)` | VT area [ft²] | Raymer 7th ed. Table 6.4 |

## 3. Equations

**Tail moment arm** — Raymer 7th ed., aft-mounted single-engine text rule (0.475 is the midpoint of
the stated 0.45–0.50 range):

$$L_{HT} = L_{VT} = 0.475\,L_{fus}$$

**Tail areas from volume coefficients** — Raymer 7th ed. Table 6.4:

$$S_{HT} = \frac{c_{HT}\,\bar{c}\,S_{ref}}{L_{HT}} \qquad
  S_{VT} = \frac{c_{VT}\,b\,S_{ref}}{L_{VT}}$$

**Tail-volume text corrections**, applied on top of the Table 6.4 base values:

$$c_{HT},\,c_{VT} \mathrel{\times}= (1 - 0.10) \quad \text{if relaxed static stability (RSS)}$$
$$c_{HT} \mathrel{\times}= (1 - 0.125) \quad \text{if all-moving stabilator}$$

0.125 is the midpoint of Raymer's stated 10–15% range. For the F-16 both apply:

$$c_{HT} = 0.40 \times 0.90 \times 0.875 = 0.315 \qquad c_{VT} = 0.07 \times 0.90 = 0.063$$

## 4. Coefficients

`lookup_tail_volume_coeffs` — Raymer 7th ed. Table 6.4, jet-fighter row only: `c_HT = 0.40`,
`c_VT = 0.07`. Any other category errors (`TailL1:unknownCategory`) rather than being guessed.

## 5. Worked example (independent hand check, not F-16 spec data)

Using `S_ref=300 ft²`, `b=30 ft`, `cbar=11.320178695127362 ft`, `L_fus=46.5 ft` (F16GeomL2-consistent
wing numbers, used here only as representative scalars — see `F16TailL1.md` for the actual F-16
class's own worked example and Brandt comparison):

```
L_HT = L_VT = 0.475 * 46.5 = 22.0875 ft
S_ht = 0.315 * 11.320178695127362 * 300 / 22.0875 = 48.43268 ft^2
S_vt = 0.063 * 30 * 300 / 22.0875               = 25.67063 ft^2
```

## 6. Migration record (2026-07-28)

These statics are **ported, not re-derived**, from the orphaned `src/disciplines/geometry/GeomL1.m`
methods of the same names (`compute_tail_volume_coeffs`, `lookup_tail_volume_coeffs`,
`compute_tail_arm`, `compute_S_HT`, `compute_S_VT`). Two competing L1 tail-sizing implementations
existed in this repo simultaneously:

| | Live, wired, tested | Orphaned, never called |
|---|---|---|
| Coefficients | `c_HT=0.40`, `c_VT=0.07` | same base, but with RSS/all-moving-tail text corrections applied → `0.315`/`0.063` |
| Tail arm | `0.5*L_fus` | `0.475*L_fus` |
| Citation | Raymer 6th ed. | Raymer 7th ed. |

**Decision (user, 2026-07-28, `TailSizing_scribe_plan.md` Sec. 2): adopt the orphaned `GeomL1` set as
canonical.** `GeomL1.m` has had these five methods **deleted** as part of this migration — tail sizing
is not geometry's job, and leaving a second, now-stale copy there would recreate the exact
discrepancy just resolved. The old `TailSizingLevel1`/`F16TailSizingLevel1` classes (which carried the
now-superseded 0.40/0.07/6th-ed./`0.5*L_fus` values) are superseded by this toolbox and `F16TailL1`.

## 7. To-dos

None open for L1. (The generic-vs-F-16-specific coefficient question is resolved at L2 instead — see
`TailL2.md` Sec. 6/7.)
