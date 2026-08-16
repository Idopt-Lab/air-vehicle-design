# TailL2

Level-2 tail-sizing static toolbox (`classdef TailL2`, `methods (Static)` only). Called as
`TailL2.method(...)`; never instantiated. `F16TailL2` inherits `TailSizingModelL2` and delegates here.

**L2 is "historical sizing estimates"**: same volume-coefficient functional form as L1, but fed real
L2 wing geometry (read live from an injected `GeometryModelL2` object) and an F-16-**specific**
measured coefficient (Nicolai & Carichner Table 11.6) instead of a generic Raymer category row.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object, read its injected `geom` | `size` |
| Low-level — scalars only, no object access | `compute_S_HT`, `compute_S_VT` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `size(obj)` | `struct('S_ht', S_ht, 'S_vt', S_vt)` | Nicolai & Carichner Table 11.6 + Raymer 7th ed. tail-arm text rule |
| `compute_S_HT(C_HT, cbar, S_ref, L_HT)` | HT area [ft²] | Nicolai & Carichner Eq. 11.2 |
| `compute_S_VT(C_VT, b, S_ref, L_VT)` | VT area [ft²] | Nicolai & Carichner Eq. 11.1 |

`size(obj)` reads `obj.geom.S_ref`, `obj.geom.b_wing`, `obj.geom.cbar_wing`, `obj.geom.L_fus` **live**
on every call (no cached copy), and `obj.C_HT`/`obj.C_VT` (hardcoded on `F16TailL2`, not read here).

## 3. Equations

**Governing identity** — confirmed algebraically identical to Raymer 7th ed. Table 6.4's own form
(the basis for `TailL1`), and to Nicolai & Carichner's own Eq. (11.1)/(11.2)
[`temp_AI/docs/disciplines/reference_extracts/11_tail_sizing.md` Secs. 11.2–11.3, pp. 286, 289]:

$$C_{VT} = \frac{l_{VT}\,S_{VT}}{b\,S_{ref}} \;\Longrightarrow\; S_{VT} = \frac{C_{VT}\,b\,S_{ref}}{l_{VT}}
\qquad
C_{HT} = \frac{l_{HT}\,S_{HT}}{\bar{c}\,S_{ref}} \;\Longrightarrow\; S_{HT} = \frac{C_{HT}\,\bar{c}\,S_{ref}}{l_{HT}}$$

**Tail moment arm — carries L1's rule forward, unchanged**:

$$L_{HT} = L_{VT} = \texttt{TailL1.compute\_tail\_arm}(L_{fus}) = 0.475\,L_{fus}$$

`GeometryModelL2` has no x-station properties, so a geometry-derived moment arm is not achievable at
L2. `TailL2.size` calls `TailL1.compute_tail_arm` directly — cross-toolbox reuse, not a copy (same
idiom as `AeroL1.oswald_eff`).

## 4. Coefficients

Nicolai & Carichner Table 11.6, "General Dynamics F-16" row, p.289
[`temp_AI/docs/disciplines/reference_extracts/11_tail_sizing.md`]:

$$C_{HT} = 0.3 \qquad C_{VT} = 0.094$$

**Explicitly NOT used**: the conflicting `C_HT=0.68, C_VT=0.041` figure that other digest files
mis-transcribe from the same Table 11.6 row (`VnV/BrandtF16A/todo.md` Finding 1, OPEN elsewhere).

These coefficients are **hardcoded in `F16TailL2`'s constructor**, not read from JSON — Table 11.6
lists a coefficient per specific aircraft, not per category, so there is no category-driven lookup
here (contrast `TailL1.lookup_tail_volume_coeffs`).

## 5. Area-reuse mechanism (indirect only)

`size(obj)` returns **only** `struct('S_ht', S_ht, 'S_vt', S_vt)` — the same shape as L1. The
integration contract is what `SizingLoopL2.m` does every iteration:

```matlab
tail_result = tail.size(...);
geom.S_ht   = tail_result.S_ht;
geom.S_vt   = tail_result.S_vt;
```

`S_exposed_ht`/`S_wet_ht`/`S_exposed_vt`/`S_wet_vt` are `Dependent` properties on
`GeometryModelL2`/`GeometryModelL3` that recompute live from `obj.S_ht`/`obj.S_vt`, so the write
propagates automatically to every downstream consumer. No direct call from `TailL2` into
`GeomL2`/`GeomL3` is needed or implemented.

## 6. Worked example (independent hand check)

Using the same representative wing numbers as `TailL1.md` (`S_ref=300 ft²`, `b=30 ft`,
`cbar=11.320178695127362 ft`, `L_fus=46.5 ft`) so the two toolboxes' outputs are directly comparable:

```
L_HT = L_VT = 0.475 * 46.5 = 22.0875 ft   [identical to L1 -- carried forward]
S_ht = 0.3   * 11.320178695127362 * 300 / 22.0875 = 46.12636 ft^2
S_vt = 0.094 * 30 * 300 / 22.0875                 = 38.30221 ft^2
```

Cross-check via the coefficient ratio (arm is identical between the two toolboxes at this example, so
the ratio of results must equal the ratio of coefficients): `S_ht` ratio `0.3/0.315 = 0.952381` ×
`48.43268` (L1's `S_ht`) `= 46.1264` ✓; `S_vt` ratio `0.094/0.063 = 1.492063` × `25.67063` (L1's
`S_vt`) `= 38.3022` ✓.

## 7. Brandt comparison (informational only, not a pass/fail gate)

Against Brandt's `S_ht=108.0 ft²` / `S_vt=60.0 ft²` (`F16GeomL2.m`, Brandt `Main!C18`/`H18`): the
worked-example `S_ht=46.126 ft²` is −57.3%, `S_vt=38.302 ft²` is −36.2%. A volume-coefficient method
is not expected to reproduce one aircraft's back-calculated Brandt areas tightly. See
`TailSizing_scribe_plan.md` Sec. 2 item 4.

## 8. To-dos

None open. The competing Nicolai coefficient transcription (`0.68`/`0.041`) remains OPEN in the
digest files named above, not this toolbox.
