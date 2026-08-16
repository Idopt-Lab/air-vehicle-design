# Aero481TailL1

F-35 Level-1 (volume-coefficient) tail sizing. `classdef Aero481TailL1 < TailSizingModelL1`; `size(...)` is
a single delegation into the `TailL1` static toolbox — no equations are duplicated here.

Mirrors `F16TailL1` (aft-mounted single-engine fighter), with one deliberate difference at this
fidelity: it carries the UNCORRECTED base jet-fighter coefficients (like the B777), because the F-35
RSS / all-moving-tail flags are not yet cited.

---

## 1. Constructor

```matlab
t1 = Aero481TailL1();
```

`Aero481TailL1()` — takes no arguments. `jet_fighter` is an F-35 spec fact, baked in here rather than read
from JSON (same pattern as `F16TailL1` / `B777TailL1`). The constructor sets the volume coefficients
from the UNCORRECTED base lookup:

```matlab
[obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_fighter');
```

---

## 2. Inputs

`properties (SetAccess = private)`, set once by the constructor.

| Property | Value | Meaning / citation |
|---|---|---|
| `c_HT` | 0.40 | horizontal-tail volume coefficient [Raymer 7th ed. Table 6.4 jet-fighter row; metabook Ch.8], uncorrected base |
| `c_VT` | 0.07 | vertical-tail volume coefficient [Raymer 7th ed. Table 6.4 jet-fighter row; metabook Ch.8], uncorrected base |

No geometry object is injected at L1: `GeometryModelL1` has no planform (only a `W_TO` regression), so
the caller supplies `S_ref`/`b`/`cbar`/`L_fus` raw. Typical wiring reads them off `Aero481GeomL1`:

```matlab
geom = Aero481GeomL1(aero481_spec_path(1), prop);
r    = Aero481TailL1().size(geom.S_ref, geom.b, geom.cbar, geom.L_fuselage);
```

## 3. Derived

None. This class holds no `Dependent` block — the tail areas are computed inside `size(...)` on demand,
not stored. `size` recomputes from its arguments every call, so it cannot go stale.

---

## 4. Methods

| Method | Delegates to / does | Source |
|---|---|---|
| `size(S_ref, b, cbar, L_fus)` | `struct('S_ht', S_ht, 'S_vt', S_vt)` — the `TailSizingBase` contract. Delegates to `TailL1.size(obj, ...)`, which uses the aft-mounted arm `L_arm = 0.475·L_fus` [`TailL1.compute_tail_arm`], then `S_ht = TailL1.compute_S_HT(c_HT, cbar, S_ref, L_arm)` and `S_vt = TailL1.compute_S_VT(c_VT, b, S_ref, L_arm)` | [Raymer 7th ed. Table 6.4]; arm [Raymer aft-mounted single-engine text rule] |

The two areas reuse the same cited `TailL1.compute_S_HT` / `compute_S_VT` statics the F-16 path uses.

---

## 5. Design decisions — F-35 vs F-16 / B777

1. **UNCORRECTED BASE COEFFICIENTS.** The F-35 takes the Raymer Table 6.4 jet-fighter coefficients
   DIRECTLY (`c_HT = 0.40`, `c_VT = 0.07`) via `TailL1.lookup_tail_volume_coeffs('jet_fighter')`.
   `F16TailL1` by contrast applies −10 % (relaxed static stability) and −12.5 % (all-moving stabilator)
   corrections via `TailL1.compute_tail_volume_coeffs`. Whether the F-35 takes those same corrections is
   **_TODO — UNCITED_** (its RSS / all-moving-tail flags are not yet pinned in the repo extracts —
   scribe plan Sec. 5), so this class carries the UNCORRECTED base until a flag is set, exactly as the
   B777 does. It calls `lookup_tail_volume_coeffs`, NOT `compute_tail_volume_coeffs`.

2. **AFT-MOUNTED TAIL ARM (unlike the B777).** `L_HT = L_VT = 0.475·L_fus`
   [`TailL1.compute_tail_arm`], the aft-mounted single-engine fighter rule — the same one the F-16
   uses. This arm IS cited [Raymer 7th ed. aft-mounted single-engine text rule; 0.475 is the midpoint of
   the stated 0.45–0.50 range], in contrast to the B777's UNCITED wing-mounted `0.525·L_fus`.

3. **`size()` delegates to `TailL1.size` directly.** Because the arm is the aft-mounted one, no in-line
   arm computation is needed (unlike `B777TailL1`); `size` calls `TailL1.size(obj, ...)`, the same path
   the F-16 takes.

---

## 6. To-dos

| Item | Guard |
|---|---|
| The F-35 RSS (relaxed static stability) / all-moving-tail flags are **_TODO — UNCITED._** The F-16 applies −10 % (RSS) and −12.5 % (all-moving) via `TailL1.compute_tail_volume_coeffs`; whether the F-35 takes these is not yet pinned in the repo extracts. Until then this class carries the UNCORRECTED base fighter coefficients (like the B777). | a deliberately-failing `testTODO` must guard the flags until they are cited |

### As-built values

`c_HT = 0.40`, `c_VT = 0.07` (uncorrected jet-fighter base), arm fraction `0.475` (cited, Raymer
aft-mounted single-engine rule). The two areas depend on the wing planform passed in from `Aero481GeomL1`
(`S_ref`, `b`, `cbar`, `L_fuselage`).
