# Aero481GeomL1

F-35 (Aero 481 provenance) Level-1 geometry. `classdef Aero481GeomL1 < GeometryModelL1`; every abstract
method is a one-line delegation into the `GeomL1` static toolbox. This class mirrors `F16GeomL1`
exactly -- both are fighter L1 statistical geometry classes.

**L1 is a statistical / regression tier.** There are almost no planform dimensions at all -- wetted
area and fuselage length are regressions on takeoff gross weight. The only true geometry inputs are
classification scalars plus the few numbers a spec sheet gives you (`AR`, `S_ref`, `Lambda_LE_deg`).

**Design provenance.** The design source is the University of Michigan AEROSP 481 (Fall 2024) starter
code by Max Arnson (Design01/A03) -- design PROVENANCE, **not** a primary source. Every `A481` value
carries a primary re-citation where one exists, else `_TODO -- UNCITED`. The published F-35A data
(`docs/reference_extracts/aero481_data.md` Part I) is a **cross-check only**. See
`examples/Aero481/aero481_scribe_plan.md` (section 1) and `examples/Aero481/aero481_discrepancies.md`
(A1-A9).

---

## 1. Constructor

```matlab
g1 = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
```

`Aero481GeomL1(json_path, req_path)` -- both paths required, no silent default (a short call errors
`MATLAB:minrhs`).

| Argument | Supplies |
|---|---|
| `json_path` | `aero481_L1.json` -> the one canonical top-level `aircraft_category`, and the `.geometry` block (`AR`, `S_ref`, `Lambda_LE_deg`, `n_engines`, `L_fus_ft`) |
| `req_path` | `aero481_requirements.json` -> `design_mach`, which becomes `M_max` |

`M_max` is a design **requirement**, not airframe spec data, so it comes from the requirements file
(where the F-16 puts it too). It still drives `get_AR_eq`, so this is a consolidation, not a removal.

Unlike `F16GeomL1` (where `S_ref` is a hardcoded literal), the F-35's `S_ref` **is** a JSON
`.geometry` input -- a published F-35A wing-area stand-in, marked `_TODO -- UNCITED` (see section 1.3).

---

## 2. Inputs

| Property | Value | Meaning / citation |
|---|---|---|
| `aircraft_category` | `"jet_fighter"` | drives the `GeomL1` table lookups |
| `AR` | 4 | wing aspect ratio; `[A481 Design01.m:49]`; **`_TODO -- UNCITED`** (A5) |
| `S_ref` | 460 ft^2 | published F-35A wing-area stand-in `[aero481_data.md Part I]`; **`_TODO -- UNCITED`** (see 1.3) |
| `Lambda_LE_deg` | 0 deg | wing LE sweep; **`_TODO -- UNCITED`** (unset/0 = A481's sweep-free Oswald, A2) |
| `M_max` | 1.6 | design max Mach -> `get_AR_eq`; from `aero481_requirements.json .design_mach` |
| `n_engines` | 1 | engine count `[A481 NEng=1; aero481_data.md Part I, single F135-PW-100]`; exposed for mission DI, not used by any L1 geometry regression |
| `L_fus_ft` | 50.5 ft | published F-35A fuselage length `[aero481_data.md Part I]`; **`_TODO -- UNCITED`** (published stand-in). FIXED tail-arm reference for the T-S-diagram tail resize; W_TO-free (read before the weight closure). Distinct from the W_TO-based `L_fuselage` regression (see section 7) |
| `S_ht` | `NaN` ft^2 | horizontal-tail area write-back slot; the T-S diagram writes it, feeds NOTHING at L1 (see section 7) |
| `S_vt` | `NaN` ft^2 | vertical-tail area write-back slot; the T-S diagram writes it, feeds NOTHING at L1 (see section 7) |
| `W_TO` | `NaN` lbf | A genuine L1 input: both regressions below are functions of TOGW, which geometry cannot know at this tier. The sizing loop mutates it between iterations |

## 3. Derived (`Dependent`)

| Property | Computes | Citation |
|---|---|---|
| `S_wet` | total wetted area from `W_TO` | **[Roskam Vol. I, Table 3.5, jet_fighter]** via `GeomL1.lookup_swet` -- REPLACES `Swet=4*S` (section 1.4) |
| `L_fuselage` | fuselage length from `W_TO` | **[Raymer 6th ed., Table 6.3, jet_fighter]** via `GeomL1.lookup_lfus` |
| `b_wing` | `sqrt(AR*S_ref)` (span) | definitional `AR = b^2/S_ref` via `GeometryBase.compute_span`; W_TO-free (see section 7) |
| `cbar_wing` | `S_ref/b_wing` (standard mean chord) | definitional; W_TO-free (see section 7) |
| `L_fus` | `= L_fus_ft` (fixed published length) | fixed tail-arm reference; **NOT** the `L_fuselage` regression; W_TO-free (see section 7) |

Both **error** (via the private `requireWTO`) while `W_TO` is unset, rather than returning a
placeholder. An unset `S_wet` would otherwise propagate as `CD0 = Cfe*S_wet/S_ref = 0` -- silent zero
parasite drag and infinite L/D -- through any aero object this geometry is injected into. `S_wet` and
`L_fuselage` are **derived**, not JSON inputs: they are `Dependent` getters on `W_TO`, recomputed live
and read-only. They never appear in the JSON.

---

### As-built values

There is no single validated TOGW for the F-35 at L1 (the design point is `W/S = 92.17 psf`,
`T/W = 1.2` -- Design01 does not fix a TOGW). Using the published F-35A `W_TO` order-of-magnitude
cross-check `65,900 lbf` (`aero481_data.md` Part I), hand-computed from the formulas above:

| Quantity | Formula | Value (approximate) |
|---|---|---|
| `S_wet` | `10^-0.1289 * 65900^0.7506` | approximately 3078 ft^2 |
| `L_fuselage` | `0.93 * 65900^0.39` | approximately 70.4 ft |
| `get_AR_eq` | `5.416 * 1.6^-0.6222` | approximately 4.04 |

Informational only, hand-computed (the Coordinator confirms the exact digits via `matlab -batch`;
the test-writer computes the pinned hand-values from these same formulas). `get_AR_eq` does not
depend on `W_TO`, so it needs no set TOGW.

---

## 4. The `Swet = 4*S` rejection (discrepancy A1)

`[A481 Design01.m:33-36]`:

```
%% Wetted Surface Area Regression
% I made this up
Aircraft.Swet_Fxn = @ (S) 4*S;
```

Uncited AND self-inconsistent (`A03.m:60-61` feeds it wing area `S`, with a commented alternative to
feed `MTOW` -- the author was unsure whether it is a function of area or weight). **REJECTED.** The
framework uses the cited Roskam Table 3.5 jet-fighter TOGW regression in `GeomL1.lookup_swet`, so
`S_wet` is a `Dependent` on `W_TO`, NOT a wing-area multiple and NOT a stored JSON input. There is no
`Swet = 4*S` anywhere in the F-35 classes.

---

## 5. `_TODO -- UNCITED` items (each needs a labelled `testTODO` guard)

| Item | Value | Stand-in / discrepancy | Needs |
|---|---|---|---|
| `AR` | 4 | `[A481 Design01.m:49]` student value; publ. F-35A AR ~= 2.66 (A5) | confirm design AR |
| `S_ref` | 460 ft^2 | published F-35A wing-area stand-in; Design01 fixes `W/S = 92.17 psf`, not `S_ref` | RFP / design `S_ref` (the design-point back-solve `S_ref = W_TO / 92.17` is a sizing-loop output, not stored) |
| `Lambda_LE_deg` | 0 deg | unset/0 = A481's sweep-free Oswald (A2) | F-35 planform document |
| `L_fus_ft` | 50.5 ft | published F-35A fuselage length stand-in `[aero481_data.md Part I]` (fixed tail-arm reference for the T-S diagram; see section 7) | primary fuselage-length citation or T.O./spec value |

### 5.1 The `AR = 4` `_TODO` (A5)

`AR = 4` `[A481 Design01.m:49]` is a student value, carried faithfully to Design01. The published
F-35A AR is approximately 2.66 (35 ft span, 460 ft^2: 35^2/460 = 2.66). The comparison report flags
this loudly as a fidelity/design gap; it is NOT silently overwritten. Confirm the design AR before
pinning.

### 5.2 `S_ref` stand-in decision (1.3)

Design01 fixes the DESIGN POINT (`W/S` = 92.17 psf, `T/W` = 1.2), **not** `S_ref` directly. In the
sizing loop `S_ref = W_TO / (W/S)` changes every iteration -- a sizing-loop output, not a static
input. Because `W_TO` is `state` (NaN at L1), a back-solved `S_ref` cannot be written as a fixed
number without inventing a `W_TO`. **Decision: carry the published F-35A `S_ref = 460 ft^2` as the
fixed spec stand-in, marked `_TODO -- UNCITED`.** The T-S study S-range 323-538 ft^2 matches Aero
481's 30-50 m^2 (`T_S.m:23`). Remove/replace `S_ref` when an RFP or a design `S_ref` is pinned.

### 5.3 `Lambda_LE_deg` (A2)

Wing leading-edge sweep is `_TODO -- UNCITED` (needs an F-35 planform document). It is 0 (unset),
which reproduces A481's sweep-free Oswald exactly (`AeroL2.oswald_eff` low-sweep branch, Raymer 6th
ed. Eq. 12.48). `Lambda_LE_deg` is carried on this geometry class for the complete planform spec and
is consumed by `Aero481AeroL1` (Oswald efficiency / `K1`), not by any L1 geometry regression here.

---

## 6. T-S-diagram tail-resize members (`b_wing`, `cbar_wing`, `L_fus`, `S_ht`, `S_vt`)

These members exist so the framework T-S diagram (`src/sizing/TSDiagram.m`) can drive this class.
`TSDiagram.converge_W0` prescribes each `(T, S)` cell and, **before** the weight closure sets
`W_TO`, resizes the tail:

```matlab
obj.geom.S_ref = S_ref;
tail_result = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, ...
                            obj.geom.cbar_wing, obj.geom.L_fus);
obj.geom.S_ht = tail_result.S_ht;   obj.geom.S_vt = tail_result.S_vt;
```

So this class must expose settable `S_ref` (it already does), readable `b_wing`/`cbar_wing`/`L_fus`,
and settable `S_ht`/`S_vt`. Two properties of this box drive the design:

- **None of `b_wing`/`cbar_wing`/`L_fus` may depend on `W_TO`.** The T-S diagram reads them
  *before* the weight closure sets `W_TO`, so a `W_TO`-dependent value would error (via
  `requireWTO`). `b_wing = sqrt(AR*S_ref)` and `cbar_wing = S_ref/b_wing` are generic wing
  identities that recompute live from the (mutated) `S_ref`; `L_fus` is the fixed published length
  `L_fus_ft`, deliberately **not** the `W_TO`-based `L_fuselage` regression (see below).
- **The tail areas feed NOTHING into OEW at L1.** L1 uses PURE historical weight fractions
  (`Aero481WeightsL1`, no tail-area delta term), so the `S_ht`/`S_vt` the resize writes back are inert:
  they exist ONLY so the T-S diagram can prescribe the cell. They default `NaN` until the resize
  writes them, and nothing downstream reads them at this fidelity.

### 6.1 `L_fus` (fixed) vs. `L_fuselage` (regression) -- two distinct lengths, on purpose

There are now two fuselage-length quantities on this class, and they are **not** the same number:

| Member | Value / formula | `W_TO`? | Role |
|---|---|---|---|
| `L_fus` | `= L_fus_ft = 50.5 ft` (fixed published length) | no | T-S-diagram tail-arm reference, read before `W_TO` is set |
| `L_fuselage` | `0.93*W_TO^0.39` `[Raymer 6th ed. Table 6.3]` via `GeomL1.get_L_fus` | yes | the `GeometryModelL1` contract regression quantity, unchanged |

`L_fus` is a fixed spec input because the T-S diagram needs a stable tail arm before any TOGW
iterate exists. `L_fuselage` remains the `W_TO`-driven statistical regression the `GeometryModelL1`
contract defines, and `get_L_fus(obj, W_TO)` is untouched. Keeping both means the fixed tail-arm
reference and the statistical fuselage length never silently overwrite one another.
`L_fus_ft = 50.5 ft` is `_TODO -- UNCITED` (a published stand-in from `aero481_data.md` Part I; see
section 6).
