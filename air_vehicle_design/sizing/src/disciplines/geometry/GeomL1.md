# GeomL1.m — companion doc

Tier-3-adjacent static toolbox (`classdef GeomL1`, all `methods (Static)`). Not in the
inheritance chain. Called as `GeomL1.method(...)`. Implements Level-1 statistical-regression
geometry: total wetted area and fuselage length from takeoff gross weight.

## Methods in this file

### High-level (take the student object)

| Method | Computes | Citation |
|---|---|---|
| `get_S_wet_statistical(obj, W_TO)` | Total aircraft `S_wet`, ft², via `10^c * W_TO^d` | Roskam, *Airplane Design Vol. I*, Table 3.5 (see resolution below) |
| `get_L_fus(obj, W_TO)` | Fuselage length, ft, via `a * W_TO^C` | Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed., Table 6.3 |

### Low-level (pure math, scalars/strings only)

| Method | Computes | Citation |
|---|---|---|
| `compute_s_wet_regression(aircraft_category, W_TO)` | `S_wet = 10^c * W_TO^d` | Roskam Vol. I, Table 3.5 |
| `compute_l_fus_regression(aircraft_category, W_TO)` | `L_fus = a * W_TO^C` | Raymer 6th ed., Table 6.3 |
| `lookup_swet(cat)` | `[c, d]` regression constants by category (`jet_fighter`, `jet_bomber`, `transport_jet`, `business_jet`, `military_cargo`); errors `GeomL1:unknownCategory` for anything else | Roskam Vol. I, Table 3.5 |
| `lookup_lfus(cat)` | `[a, C]` regression constants by category (`jet_fighter`, `jet_trainer`, `transport_jet`, `military_cargo`); errors `GeomL1:unknownCategory` for anything else | Raymer 6th ed., Table 6.3 |

## Citation resolution: Roskam Table 3.5 vs Roskam Eq 3.22

`GeomL1.m`'s own docstring and `lookup_swet`'s comment cite **"Roskam Vol. I, Table 3.5"** for
the `S_wet = 10^c * W_TO^d` regression. `docs/subplans/02_geometry.md:61` instead cites
**"Roskam Airplane Design Vol I, eq 3.22"** for the identical formula/row (same c/d values, same
`jet_fighter` case). Per the user's explicit instruction, these are **the same source, not a
conflict** — Roskam Eq. 3.22 is the general form of the regression, and Table 3.5 is where the
per-category (c, d) constants live; document as one combined citation going forward:

> **Combined citation:** Roskam, *Airplane Design, Part I: Preliminary Sizing of Airplanes*,
> DARcorporation — Eq. 3.22 (functional form `S_wet = 10^c * W_TO^d`) with constants from
> Table 3.5 (per-aircraft-category c, d).

This is not logged to `VnV/BrandtF16A/todo.md` — it is not a VnV/BrandtF16A discrepancy, it is
an in-repo doc/code citation-granularity mismatch, and the user has already resolved it (see
above).

## Notes
- `L_fus` (Raymer 6th ed. Table 6.3) is independent of the `S_wet` regression (different table,
  different source book).
- Both lookups error explicitly (`GeomL1:unknownCategory`) rather than silently defaulting —
  matches the pattern the Task-2 lookups below (`AR_eq`, tail volume coefficients,
  control-surface fractions) should follow.

---

## Task 2 — new L1-tier equations approved for the next implementation phase

Not implemented yet. Exact spec below, verified per the user's instruction against the values
they supplied (I did not re-derive these from a Roskam/Raymer PDF; the user gave the numeric
constants directly and asked that they be used exactly).

### Equivalent aspect ratio (statistical, from design Mach number)
```
AR_eq = a * M_max^C
a = 5.416, C = -0.6222     (Jet fighter / "dogfighter" row only)
```
**Citation:** Raymer 7th ed., Table 4.1, "Jet fighter (dogfighter)" row.

**Scope restriction:** implement ONLY the jet-fighter/dogfighter row. Any other
`aircraft_category` passed to the lookup must **error explicitly** (e.g.
`GeomL1:unknownCategory`, matching `lookup_swet`/`lookup_lfus`'s existing pattern above) rather
than silently returning a wrong or interpolated value — Table 4.1's other rows (other fighter
subtypes, transports, etc.) are not implemented and must not be guessed.

### Tail volume coefficients (Raymer 7th ed., Table 6.4, "Jet fighter" row)
```
S_HT = c_HT * cbar * S_ref / L_HT
S_VT = c_VT * b    * S_ref / L_VT
c_HT_base = 0.40,  c_VT_base = 0.07
```
**Citation:** Raymer 7th ed., Table 6.4, "Jet fighter" row (base coefficients only, before the
F-16-specific text corrections below).

**F-16-specific corrections (both apply; document why each applies to this aircraft):**

1. **Active/computerized flight-control system (relaxed static stability).** The F-16 is
   fly-by-wire with a relaxed-static-stability design (this is why it needs an active FCS at
   all). Raymer's text correction for this configuration reduces both tail-volume coefficients:
   ```
   c_HT, c_VT  *=  (1 - 0.10)
   ```
2. **All-moving tail (applies to `c_HT` only).** The F-16 uses an all-moving stabilator, not a
   fixed horizontal stabilizer + elevator. Raymer's text correction for an all-moving tail is a
   further reduction on `c_HT` given as a **range, 0.10–0.15**; per the user's instruction, the
   **midpoint (0.125) was chosen** in the absence of a more specific value:
   ```
   c_HT  *=  (1 - 0.125)     [midpoint of Raymer's stated 0.10-0.15 range]
   ```
   (`c_VT` is unaffected — the all-moving-tail correction is HT-only.)

Applying both corrections to `c_HT`: `c_HT = 0.40 * (1-0.10) * (1-0.125) = 0.315`.
`c_VT = 0.07 * (1-0.10) = 0.063`.

**Tail arm (aft-mounted single engine).** Raymer's text rule for aft-fuselage-mounted-engine
aircraft (the F-16 is single-engine, aft-mounted) approximates the tail moment arm as a
fraction of fuselage length, given as a **range, 0.45–0.50**; per the user's instruction, the
**midpoint (0.475) was chosen**:
```
L_HT = L_VT = 0.475 * L_fus     [midpoint of Raymer's stated 0.45-0.50 range]
```

### Control-surface sizing (Raymer 7th ed., Table 6.5, "Jet fighter" row)
```
elevator:  C_e/c = 0.30   [supersonic all-moving tail — no separate elevator surface;
                           this is the all-moving-tail row value, not a hinged-elevator chord fraction]
rudder:    C_r/c = 0.33
```
**Citation:** Raymer 7th ed., Table 6.5, "Jet fighter" row.

**Gap — aileron fraction not available.** Table 6.5's "Jet fighter" row (as given to me) does
not include an aileron chord-fraction value. **Do not fabricate one.** Any later-phase test
that would require an aileron area/chord fraction from this table must be written to **fail
loudly** (e.g. call a lookup that errors `GeomL1:unknownControlSurface` for `'aileron'`) rather
than silently substituting a plausible-looking number or a different table's value.

