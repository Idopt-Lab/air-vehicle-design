# F16TailL2

F-16A Level-2 ("historical sizing estimates") tail sizing. `classdef F16TailL2 < TailSizingModelL2`;
`size(obj)` is a single delegation into `TailL2` — no equation is duplicated here.

---

## 1. Constructor

```matlab
t2 = F16TailL2(geom);   % geom (1,1) GeometryModelL2, e.g. F16GeomL2(...)
```

`geom` is **required**, no silent default — a defaulted injection would silently re-freeze wing
geometry, the same defect class the DI pattern removes elsewhere (see `F16WeightsL2`'s `geom`/`prop`
injection for the precedent this follows). Only `geom.b_wing`, `geom.cbar_wing`, `geom.S_ref`,
`geom.L_fus` are read, and only read — `F16TailL2` never mutates the injected object.

## 2. Coefficients (hardcoded in the constructor, `SetAccess = private` thereafter)

| Property | Value | Source |
|---|---|---|
| `C_HT` | 0.3 | Nicolai & Carichner Table 11.6, "General Dynamics F-16" row, p.289 |
| `C_VT` | 0.094 | same source/row |

Hardcoded, **not** read from JSON (confirmed by the io agent, `TailSizing_scribe_plan.md` Sec. 5.3)
— Table 11.6 gives a coefficient per specific aircraft, not per generic category, so there is no
JSON-driven lookup here (contrast `F16TailL1`, whose coefficients derive from a category-driven
static). **Explicitly NOT** the conflicting `C_HT=0.68`/`C_VT=0.041` figure that appears in three
reference-digest files in `docs/reference_extracts/` (`nicolai_data.md`, `roskam_vol2_data.md`, `usaf_f16_data.md`) — see
`TailL2.md` Sec. 4 for the full note.

## 3. size(obj)

No scalar arguments — the wing planform and fuselage length are read live from the injected `geom`:

```
S_ref = geom.S_ref
b     = geom.b_wing
cbar  = geom.cbar_wing
L_fus = geom.L_fus

L_HT = L_VT = 0.475 * L_fus        [carried forward from L1 unchanged -- TailL1.compute_tail_arm]
S_ht = C_HT * cbar * S_ref / L_HT  [Nicolai & Carichner Eq. 11.2]
S_vt = C_VT * b    * S_ref / L_VT  [Nicolai & Carichner Eq. 11.1]
```

Returns `struct('S_ht', S_ht, 'S_vt', S_vt)` **only** — no exposed/wetted-area fields, no
`get_S_exposed_ht`-style accessor (locked decision, `TailSizing_scribe_plan.md` Sec. 5.2). The
geometry object is injected solely to read the four scalars above; area reuse downstream (exposed /
wetted area, weights' Table 15.2 reads) happens indirectly once the caller writes `S_ht`/`S_vt` back
into `geom` — see `TailL2.md` Sec. 5 for the full mechanism.

### Worked example — same representative wing numbers as F16TailL1's

`S_ref=300 ft²`, `b_wing=30 ft`, `cbar_wing=11.320178695127362 ft`, `L_fus=46.5 ft` — hand-computed
independently, not read from a live `F16GeomL2` instance:

```
L_HT = L_VT = 0.475 * 46.5 = 22.0875 ft          [identical to L1 at this example]
S_ht = 0.3   * 11.320178695127362 * 300 / 22.0875 = 46.12636 ft^2
S_vt = 0.094 * 30 * 300 / 22.0875                 = 38.30221 ft^2
```

**Brandt comparison (informational only, not a pass/fail gate):** vs. Brandt's `S_ht=108.0 ft²` /
`S_vt=60.0 ft²`: −57.3% / −36.2%. The VT number is noticeably closer to Brandt than L1's generic
category row gives (−57.2%), consistent with L2 using an F-16-*specific* measured coefficient rather
than a generic jet-fighter average — the HT number is not closer, so this is not read as a uniform
fidelity improvement, just reported.

## 4. To-dos

None open on this class. The three-digest-file coefficient mis-transcription remains an open,
unresolved-elsewhere issue in those files, not here (see `TailL2.md` Sec. 4/7).
