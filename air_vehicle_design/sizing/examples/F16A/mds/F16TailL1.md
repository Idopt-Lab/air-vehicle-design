# F16TailL1

F-16A Level-1 (volume-coefficient) tail sizing. `classdef F16TailL1 < TailSizingModelL1`; `size(...)`
is a single delegation into `TailL1` — no equation is duplicated here.

---

## 1. Constructor

```matlab
t1 = F16TailL1();
```

No arguments. The F-16's category (`jet_fighter`) and both correction flags (relaxed static
stability, all-moving stabilator) are F-16 spec facts, baked in via
`TailL1.compute_tail_volume_coeffs('jet_fighter', true, true)` — not read from JSON, matching the
category of decision already used for the superseded `F16TailSizingLevel1`'s hardcoded 0.40/0.07.

## 2. Coefficients (computed at construction, `SetAccess = private` thereafter)

| Property | Value | Derivation |
|---|---|---|
| `c_HT` | 0.315 | `0.40 * (1-0.10) * (1-0.125)` [Raymer 7th ed. Table 6.4 jet-fighter row, RSS + all-moving-tail text corrections] |
| `c_VT` | 0.063 | `0.07 * (1-0.10)` [same table, RSS correction only] |

RSS applies because the F-16 is relaxed-static-stability by design (FLCS-era fighter). The
all-moving-tail correction applies because the F-16's horizontal tail is an all-moving stabilator
(documented throughout `F16GeomL2`/`F16GeomL3` and `ControlSurfaceSizer`'s F-16 wiring, where
`S_elev=0`).

## 3. size(obj, S_ref, b, cbar, L_fus)

No geometry object is injected — `GeometryModelL1` has no planform at all (only a `W_TO` regression),
so the caller supplies the wing planform and fuselage length as raw scalars, unchanged from the
retired `TailSizingLevel1.size` interface.

```
L_HT = L_VT = 0.475 * L_fus
S_ht = c_HT * cbar * S_ref / L_HT
S_vt = c_VT * b    * S_ref / L_VT
```

Returns `struct('S_ht', S_ht, 'S_vt', S_vt)`.

### Worked example — F16GeomL2's own wing numbers used as representative scalars

`S_ref=300 ft²`, `b_wing=30 ft` (`AR_wing=3.0`), `cbar_wing=11.320178695127362 ft`
(`GeometryBase.compute_mac` at `lambda_wing=0.2275`), `L_fus=46.5 ft` [`F16GeomL2.m`, Brandt
`Main!B32`] — **hand-computed independently**, not read from a live `F16GeomL2` instance, so this
number cannot silently track a future change to that class:

```
L_HT = L_VT = 0.475 * 46.5 = 22.0875 ft
S_ht = 0.315 * 11.320178695127362 * 300 / 22.0875 = 48.43268 ft^2
S_vt = 0.063 * 30 * 300 / 22.0875                 = 25.67063 ft^2
```

**Brandt comparison (informational only, not a pass/fail gate):** Brandt's `S_ht=108.0 ft²` /
`S_vt=60.0 ft²` (`F16GeomL2.m`, Brandt `Main!C18`/`H18`) are −55.2% / −57.2% away from the worked
example above. Table 6.4's own coefficients are described as "conservative averages" across many
aircraft in a category, so an individual real aircraft reading this far from a historical-average
coefficient is not implausible for this coarse method — but it is large enough to flag, not quietly
accept (same finding the retired `TestTailSizingLevel1.testF16TailAreasVsBrandt` already made at the
pre-correction 0.40/0.07/`0.5*L_fus` values, where the gap was −46%/−55%; the RSS/all-moving-tail
corrections and the smaller `0.475` arm fraction widen it further, not narrow it — see
`TailSizing_scribe_plan.md` Sec. 2 item 4).

## 4. Migration record (2026-07-28)

Supersedes `examples/F16TailSizingLevel1.m` (`c_HT=0.40`, `c_VT=0.07`, tail arm `0.5*L_fus`, Raymer
6th ed.) — see `TailL1.md` Sec. 6 for the full discrepancy-resolution record. The old class and its
test (`tests/tail_sizing/TestTailSizingLevel1.m`) are deleted (removal completed 2026-07-30, per the
scribe plan's "once tests pass, remove" gate). This class and `TailL1` are the only implementation
now.

## 5. To-dos

None open.
