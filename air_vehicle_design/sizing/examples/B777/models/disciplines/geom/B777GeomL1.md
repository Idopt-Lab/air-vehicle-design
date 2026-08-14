# B777GeomL1

Boeing 777-200LR Level-1 geometry — the metabook Example 4.2 tier. `classdef B777GeomL1 <
GeometryModelL1`; every contract method is a one-line delegation into the `GeometryBase` statics, and
no equation is duplicated here.

Unlike `F16GeomL1` — whose L1 geometry is a pure `W_TO` statistical regression — the B777's L1
geometry carries a **real wing planform** (`S_ref`, `AR` from metabook Table 4.3) plus the metabook
Eq. 4.58 wetted-area decomposition. It therefore ADDS the planform `Dependent` members (span, mean
chord) that `F16GeomL1` lacks.

This class follows the **INPUT vs DERIVED pattern** (reference implementation:
`examples/F16A/models/disciplines/geom/F16GeomL2.m`). Inputs are a plain mutable block of genuine
design-variable spec data; derived quantities are `Dependent` getters that recompute live on every
read. There is no stored or cached copy, so a derived value can never go stale — the instant an
optimizer changes an input, every dependent read reflects it.

**The live CD0(S) coupling is the whole point of the Dependent `S_wet`.** `B777AeroL1.drag_polar`
computes `CD0 = Cfe·(S_wet/S_ref)`, and `S_wet = S_wet_rest + 2·S_ref` [metabook Eq. 4.58]. So when
the L2 sizing loop mutates the wing area `S_ref`, `S_wet` and hence `CD0` track it automatically.
Freezing `S_wet` in the constructor would silently pin `CD0` to the old wing — the stale-under-mutation
defect this pattern removes.

---

## 1. Constructor

```matlab
g1 = B777GeomL1(b777_spec_path(1));
```

`B777GeomL1(json_path)` — path required, no silent default (a no-arg call errors `MATLAB:minrhs`).
Reads the `.geometry` block of `b777_L1.json`. Sets ONLY the input properties; every derived quantity
is produced live by its `Dependent` getter. The tail slots `S_ht`/`S_vt` stay `NaN` until the tail
loop writes them.

---

## 2. Inputs

Plain mutable `properties`, set once from the JSON.

| Property | Value | Unit | Meaning / citation |
|---|---|---|---|
| `S_ref` | 4605 | ft² | wing reference area [metabook Table 4.3] |
| `AR` | 9.8 | — | wing aspect ratio [metabook Table 4.3] |
| `S_wet_rest` | 19081 | ft² | wetted area of everything EXCEPT the wing [metabook Eq. 4.58 decomposition; = 28291 − 2·4605]. The wing part (2·S_ref) is added live by `S_wet` |
| `L_fus` | 209 | ft | fuselage / overall length [**_TODO** stand-in = published 777-200LR length; `b777_L1.md` §2.2]. Feeds the tail moment arm; the metabook Example 4.2 itself does not use it |
| `n_engines` | 2 | — | engine count [metabook §4.11, 2× GE90-110B]. Exposed for mission DI; not used by any L1 geometry quantity |
| `S_ht` | NaN | ft² | HT reference area — sizing-loop WRITE-BACK slot [`B777TailL1.size`]; NaN = not-yet-sized sentinel |
| `S_vt` | NaN | ft² | VT reference area — sizing-loop WRITE-BACK slot [`B777TailL1.size`]; NaN = not-yet-sized sentinel |

**Tail write-back slots.** `S_ht`/`S_vt` are plain (not `Dependent`) because there is no closed-form
`get.S_ht`/`get.S_vt` in terms of this class's OWN inputs — the tail areas come from a separate
discipline (`B777TailL1`, sized against this geometry). Same pattern as `F16GeomL2`'s tail slots.
Default `NaN` so a read before the tail loop runs is an obvious not-yet-sized sentinel, not a
plausible 0.

**No wing taper carried at L1.** The metabook Example 4.2 never uses the wing taper ratio; it takes
`S_wet` from the MTOW regression, not from planform chords (`b777_L1.md` §2.3). Where a mean chord is
needed, `cbar = S/b` is used.

### 2.1 `S_wet_rest` decomposition

```
Swet      = 10^0.0199 · 766,800^0.7531 = 28,291 ft²        [metabook Eq. 4.42]
Swet      = Swet_rest + 2·S                                 [metabook Eq. 4.58]
Swet_rest = 28,291 − 2·4,605 = 19,081 ft²
```

The exponent `d = 0.7531` is the metabook value (discrepancy **D3** in `metabook_data.md`, RESOLVED
2026-08-13 in favour of the metabook), NOT the current repo `GeomL1.lookup_swet` `d = 0.7351`. The
full-airplane regressed `Swet = 28,291 ft²` is a DERIVED cross-check regenerated from the Eq. 4.42
regression at the baseline W0, not a stored input.

## 3. Derived (`Dependent`)

Computed live from the inputs on every read (no cache, never stale). Read-only: assigning errors,
which is correct — they are outputs.

| Property | Formula | Unit | Source |
|---|---|---|---|
| `S_wet` | `S_wet_rest + 2·S_ref` | ft² | [metabook Eq. 4.58] — the live CD0(S) coupling |
| `b_wing` | `sqrt(AR·S_ref)` | ft | definitional; `GeometryBase.compute_span` |
| `cbar_wing` | `S_ref / b_wing` | ft | standard mean chord [metabook Eq. 11.5 note] — the S/b definition, NOT the trapezoidal MAC (no taper at L1) |
| `L_fuselage` | mirrors `L_fus` | ft | duplicate name required by the `GeometryModelL1` abstract contract |

`L_fuselage` satisfies the `GeometryModelL1` abstract property; `S_wet` satisfies `GeometryBase`'s.

---

## 4. Methods

| Method | Delegates to / does | Source |
|---|---|---|
| `get_S_ref()` | returns `obj.S_ref` | — |
| `get_S_wet(~)` | returns `obj.S_wet` (the Dependent getter); the trailing `~` absorbs the abstract `W_TO` argument — the B777 has a real planform, so it never needs a `W_TO` | [metabook Eq. 4.58] |
| `get_S_wet_statistical(~)` | **ERRORS** `B777GeomL1:notApplicable` | see below |
| `get_L_fus(~)` | **ERRORS** `B777GeomL1:notApplicable` | see below |

**The two `W_TO`-regression methods are NOT APPLICABLE and fail loud.** `GeometryModelL1` declares
`get_S_wet_statistical(obj, W_TO)` and `get_L_fus(obj, W_TO)` abstract — the `W_TO`-regression path
`F16GeomL1` uses. The B777's L1 geometry uses the Eq. 4.58 PLANFORM decomposition and a direct-input
`L_fus`, not a Roskam TOGW regression. MATLAB requires every abstract member be satisfied, so both
methods are implemented, but they ERROR rather than return a wrong-model number (fail loud, not
silent). The error text points the caller at `obj.S_wet` / `obj.L_fus` instead.

### As-built values (baseline S_ref = 4605, AR = 9.8)

| Quantity | Value | | Quantity | Value |
|---|---|---|---|---|
| `S_wet` | **28,291 ft²** | | `b_wing` | 212.4 ft (`sqrt(9.8·4605)`) |
| `cbar_wing` | 21.68 ft (`4605/212.4`) | | — | — |

`S_wet = 28,291 ft²` reproduces the metabook Example 4.2 Eq. 4.42 figure exactly (see §2.1).

---

## 5. To-dos

| Item | Guard |
|---|---|
| `L_fus` = 209 ft is a **_TODO** stand-in = the published 777-200LR overall length; the metabook Example 4.2 does not print a fuselage or overall length | `b777_L1.md` §2.2 / §6 — needs a Boeing type-doc / Airport Planning primary source |
| `S_wet_rest` uses the metabook `d = 0.7531`, which disagrees with the repo `GeomL1.lookup_swet` transport_jet row `d = 0.7351` | discrepancy **D3**, `metabook_data.md` — RESOLVED in favour of the metabook value; repo row to be corrected in the src-extension batch |
