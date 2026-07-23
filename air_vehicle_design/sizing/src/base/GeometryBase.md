# GeometryBase.m — companion doc

Tier 1, abstract. `classdef (Abstract) GeometryBase < handle`. No concrete equations today —
pure interface enforcement.

## Current contents (as of this doc)

### Abstract properties
| Property | Meaning |
|---|---|
| `S_ref` | Wing reference area, ft² |
| `S_wet` | Total aircraft wetted area, ft² |

### Abstract methods
| Method | Computes | Citation |
|---|---|---|
| `get_S_ref(obj)` | Wing reference area, ft² | none — pass-through to a stored/input value, no equation |
| `get_S_wet(obj, W_TO)` | Total aircraft wetted area, ft² | none at this tier — dispatches to L1/L2 toolbox equations (see `GeomL1.md`/`GeomL2.md`; Geometry has no L3 — merged into L2 on 2026-07-22, see `GeomL2.md`'s header note). `W_TO` is unused by the L2 implementation; kept only so the same method signature works at every fidelity level (see the in-file `TODO (7/8/2026)` at `GeometryBase.m:23-24`). |

No equations, no coefficients, no concrete methods exist in this file at present.

---

## Task 2 — equations approved for the next implementation phase (Base tier)

These are **not implemented yet**. They are documented here as the exact spec for whichever
agent implements Step 2 next. All four are fidelity-independent planform identities that
belong in `GeometryBase` (or a Base-tier static toolbox alongside it) because every fidelity
level ≥ L2 needs them and the equations themselves never change with fidelity — only which
inputs feed them does.

### Root chord
```
c_root = 2*S_ref / (b*(1+lambda))
```
**Citation:** Raymer, *Aircraft Design: A Conceptual Approach*, 7th ed., Eq. 7.6.

### Tip chord
```
c_tip = lambda * c_root
```
**Citation:** Raymer 7th ed., Eq. 7.7.

### Mean aerodynamic chord (MAC / cbar)
```
cbar = (2/3) * c_root * (1 + lambda + lambda^2) / (1 + lambda)
```
**Citation:** Raymer 7th ed., Eq. 7.8.

### Span
```
b = sqrt(AR * S_ref)
```
**Citation:** definitional (AR ≡ b²/S_ref by definition of aspect ratio) — not a numbered
textbook equation. Already used informally as a comment in `F16GeomL2.m:32` (`b_wing = 30 % ft
[sqrt(AR*S) = sqrt(3*300)]`) but never actually called by code anywhere in the active tree.
(Formerly also appeared in `F16GeomL3.m`, now merged into `F16GeomL2.m` — see `GeomL2.md`'s
header note on the 2026-07-22 L3-elimination decision.)

### Sweep-angle conversion (LE sweep → sweep at any chord-fraction station)
**Status: CITATION UNRESOLVED — do not implement against a guessed equation number.**

The quantity needed is the standard "convert leading-edge sweep to sweep at chord fraction x"
identity, e.g. in the general form
```
tan(Lambda_x) = tan(Lambda_LE) - (4/AR) * x * (1-lambda)/(1+lambda)
```
(x=0.25 for quarter-chord, x=0.5 for mid-chord, etc.) This is the formula that, applied
correctly, would fix the F16GeomL2/L3 wing `QC_sweep_wing = 37` bug flagged in
`docs/darshan-verification/2026-07-21_steps_01-05_review.md` (correct value ≈32.2° at this
aircraft's own AR=3.0/λ=0.2275/Λ_LE=40°).

I searched for an authoritative citation and could **not** pin one down within what this repo
gives access to:
- `temp_AI/docs/disciplines/reference_extracts/*.md` (all 9 files: `raymer_data.md`,
  `roskam_vol1_data.md`, `roskam_vol2_data.md`, `roskam_vol3_data.md`, `mattingly_data.md`,
  `metabook_data.md`, `nicolai_data.md`, `usaf_f16_data.md`, `f35_data.md`) — grepped for
  "sweep", "tan(", "quarter-chord", "Λ_c" — no sweep-conversion identity with an equation
  number appears anywhere in these extracts. `metabook_data.md:351` has an unrelated MAC
  x-location formula that uses `tan(Lambda_LE)` but is not a sweep-conversion identity itself.
- `docs/PLAN.md`'s Rules section (Rule 7) points to two directories for physical references —
  `...\temp_AI\docs\disciplines\reference_extracts` (checked above) and two more paths under
  `C:\Users\John Freeman\Desktop\...\Documents\{References,Readings}` — **these two are on a
  different, stale machine and are not present in this repo or accessible from this one.**
  I cannot check them.
- `docs/subplans/02_geometry.md` does not cite a sweep-conversion formula at all; it only
  lists sweep as a raw spec input, never as a derived quantity.

**Action for the next phase:** either (a) get access to a Raymer/Roskam PDF to pin the exact
edition/chapter/equation number before writing this into a toolbox docstring, or (b) if the
identity is being taken as a standard aerodynamics identity independent of any specific
textbook, cite it as such explicitly (e.g. "standard swept-wing planform geometry identity,
uncited to a specific textbook edition") rather than attaching a Raymer/Roskam number that
was not actually verified against the text.

**RESOLVED (2026-07-21, user decision):** go with option (b) — implement `convert_sweep` next
phase, cited in the docstring as "standard swept-wing planform geometry identity (uncited — no
specific textbook edition/equation number verified against source text)." Not a blocker; proceed
with implementation.

---

## Note: edition mismatch to flag for the user

The Task-2 equations above were specified using **Raymer 7th ed.** section/equation numbers.
Every existing citation elsewhere in `GeomL1.m`/`GeomL2.m`/`GeomL3.m` and their tests cites
**Raymer 6th ed.** (e.g. `GeomL1.m`'s `L_fus` regression cites "Raymer, 6th ed., Table 6.3";
`AeroL1.m`/`AeroL3.m` cite "Raymer 6th ed." throughout). Raymer's chapter/equation numbering is
not guaranteed identical between the 6th and 7th editions. This is not a VnV/BrandtF16A
discrepancy (so it does not go in `VnV/BrandtF16A/todo.md`), but it is a citation-consistency
gap worth resolving before implementation: confirm whether the project intends to standardize
on 7th ed. going forward (re-citing the existing 6th-ed. equations to their 7th-ed. numbers) or
keep 6th ed. as the project standard and re-derive Eq. 7.6/7.7/7.8's 6th-ed. equivalents.

**RESOLVED (2026-07-21, user decision):** don't worry about it for now — cite each equation to
whichever edition it was actually verified against (7th ed. for the new Task-2 chord/MAC
equations, 6th ed. for everything pre-existing). A mixed-edition citation set across the codebase
is accepted for the time being; not a blocker for implementation.
