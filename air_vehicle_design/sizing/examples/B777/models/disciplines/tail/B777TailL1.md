# B777TailL1

Boeing 777-200LR Level-1 (volume-coefficient) tail sizing. `classdef B777TailL1 <
TailSizingModelL1`; `size(...)` computes the arm and two areas from the `TailL1` static toolbox — no
equations are duplicated here.

Mirrors `F16TailL1`, with three deliberate differences for a jet transport.

---

## 1. Constructor

```matlab
t1 = B777TailL1();
```

`B777TailL1()` — takes no arguments. `jet_transport` is a B777 spec fact, baked in here rather than
read from JSON (same pattern as `F16TailL1`). The constructor sets the volume coefficients from the
UNCORRECTED base lookup:

```matlab
[obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_transport');
```

---

## 2. Inputs

`properties (SetAccess = private)`, set once by the constructor.

| Property | Value | Meaning / citation |
|---|---|---|
| `c_HT` | 1.00 | horizontal-tail volume coefficient [metabook Ch.8 Eq. 8.2; Raymer 7th ed. Table 6.4 jet-transport row] |
| `c_VT` | 0.09 | vertical-tail volume coefficient [metabook Ch.8 Eq. 8.1; Raymer 7th ed. Table 6.4 jet-transport row] |

No geometry object is injected at L1: `GeometryModelL1` exposes `S_ref`/`b`/`cbar` as scalars, so the
caller supplies `S_ref`/`b`/`cbar`/`L_fus` raw. Typical wiring reads them off `B777GeomL1`:

```matlab
geom = B777GeomL1(b777_spec_path(1));
r    = B777TailL1().size(geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus);
```

## 3. Derived

None. This class holds no `Dependent` block — the tail areas are computed inside `size(...)` on demand,
not stored. `size` recomputes from its arguments every call, so it cannot go stale.

---

## 4. Methods

| Method | Delegates to / does | Source |
|---|---|---|
| `size(S_ref, b, cbar, L_fus)` | `struct('S_ht', S_ht, 'S_vt', S_vt)` — the `TailSizingBase` contract. `L_arm = 0.525·L_fus` [`TailL1.compute_tail_arm_wing_mounted`]; `S_ht = TailL1.compute_S_HT(c_HT, cbar, S_ref, L_arm)`; `S_vt = TailL1.compute_S_VT(c_VT, b, S_ref, L_arm)` | [metabook Ch.8 Eqs. 8.1/8.2; Raymer 7th ed. Table 6.4]; arm = **_TODO** (§5) |

The two areas reuse the same cited `TailL1.compute_S_HT` / `compute_S_VT` statics the F-16 path uses.

---

## 5. Design decisions — the three B777-vs-F16 differences

1. **BASE COEFFICIENTS, NO CORRECTIONS.** A jet transport is conventionally stable with a fixed
   (non-all-moving) horizontal tail, so it takes the Raymer Table 6.4 / metabook Ch.8 jet-transport
   coefficients DIRECTLY (`c_HT = 1.00`, `c_VT = 0.09`) via
   `TailL1.lookup_tail_volume_coeffs('jet_transport')`. `F16TailL1` by contrast applies −10 % (relaxed
   static stability) and −12.5 % (all-moving stabilator) corrections via
   `TailL1.compute_tail_volume_coeffs` — NEITHER applies to the B777, so this class calls the
   UNCORRECTED base lookup, not `compute_tail_volume_coeffs`.

2. **WING-MOUNTED-ENGINE TAIL ARM.** `L_HT = L_VT = 0.525·L_fus`
   [`TailL1.compute_tail_arm_wing_mounted`], the wing-mounted-engine transport rule, vs. `F16TailL1`'s
   aft-mounted `0.475·L_fus`. **_TODO — THE 0.525 ARM IS UNCITED IN THE REPO EXTRACTS._** See §6.

3. **`size()` computes the arm and areas directly here**, rather than calling `TailL1.size` (whose arm
   comes from `compute_tail_arm`, the aft-mounted 0.475). To use the WING-MOUNTED arm, this class
   computes `L_arm = 0.525·L_fus` and the two areas in-line.

---

## 6. To-dos

| Item | Guard |
|---|---|
| The wing-mounted `0.525·L_fus` tail arm is **_TODO — UNCITED IN THE REPO EXTRACTS._** `metabook_data.md` carries the jet-transport tail-volume coefficients (c_HT = 1.0, c_VT = 0.09) but NOT the 50–55 % wing-mounted arm fraction. It is a labeled TODO in `TailL1.compute_tail_arm_wing_mounted`'s header | a deliberately-failing `testTODO` must guard it until the printed Raymer text is transcribed |

### As-built values

`c_HT = 1.00`, `c_VT = 0.09` (uncorrected jet-transport base), arm fraction `0.525` (uncited TODO).
The two areas depend on the wing planform passed in from `B777GeomL1` (`S_ref = 4605`, `b_wing`,
`cbar_wing`, `L_fus = 209`).
