# GeometryBase

Tier-1 abstract enforcer (`classdef (Abstract) GeometryBase < handle`) for every geometry discipline
class. It declares the minimum contract orchestrators rely on, and provides the fidelity-independent
identities every level shares. No per-aircraft data, no per-fidelity equations.

---

## 1. Inheritance

```
GeometryBase → GeometryModelLN (abstract) → F16GeomLN (concrete)
```

Each `GeometryModelLN` enforcer inherits `GeometryBase` **directly**, not `GeometryModelL(N-1)`.

The `GeomL1` / `GeomL2` / `GeomL3` static toolboxes hold the per-fidelity equations and are **not**
in this chain — concrete classes call them as `GeomLN.method(...)`.

**Geometry has all three tiers, L1 / L2 / L3.** L1 is statistical (regressions on `W_TO`), L2 is the
Brandt-reference tier, L3 is the physical / T.O. 1F-16A-1 tier.

## 2. Abstract contract

Properties every concrete class must define:

| Property | Meaning |
|---|---|
| `S_ref` | wing reference area, ft² |
| `S_wet` | total aircraft wetted area, ft² |

Methods every concrete class must implement:

| Method | Notes |
|---|---|
| `get_S_ref(obj)` | wing reference area, ft² |
| `get_S_wet(obj, W_TO)` | total wetted area, ft². The `(obj, W_TO)` signature is the widest any implementer needs — L1's statistical regression needs TOGW, while L2/L3 have real planform geometry and implement `get_S_wet(obj)` with no second argument. MATLAB does not enforce matching arity between an abstract declaration and its concrete override, so this is legal |

This contract is deliberately **narrow**, and that has a consequence worth knowing: a bare
`GeometryBase` type guard is too weak for anything that reads real geometry. `F16AeroL2`/`L3` read
~20 members off the injected object, so their guards were narrowed to
`mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])`.

## 3. Concrete utilities

Fidelity-independent identities, shared unchanged across all levels. Each takes only scalars and
returns a scalar.

| Method | Formula | Source |
|---|---|---|
| `compute_root_chord(S_ref, b, lambda)` | `2·S_ref/(b(1+λ))` | Raymer 7th ed. Eq. 7.6 |
| `compute_tip_chord(c_root, lambda)` | `λ·c_root` | Raymer 7th ed. Eq. 7.7 |
| `compute_mac(c_root, lambda)` | `(2/3)·c_root·(1+λ+λ²)/(1+λ)` | Raymer 7th ed. Eq. 7.8 |
| `compute_span(AR, S_ref)` | `sqrt(AR·S_ref)` | definitional (`AR = b²/S_ref`) |
| `convert_sweep(Lambda_LE_deg, AR, lambda, x)` | **MIRRORED** surfaces: `tan Λ_x = tan Λ_LE − (4/AR)·x(1−λ)/(1+λ)`; `x = 0.25` gives quarter-chord, `x = 1.0` trailing edge | standard planform identity (§4) |
| `convert_sweep_panel(Lambda_LE_deg, AR, lambda, x)` | **SINGLE-PANEL** surfaces: same identity with `2/AR` | as above (§4) |

Argument validators guard the denominators: `lambda` is `mustBeNonnegative` (protects `1+λ`), areas /
spans / chords are `mustBePositive`, and `x` is constrained to `[0,1]`.

`compute_Amax_elliptical` **left this file on 2026-08-19** for `F16GeomL2`. See §3a. The earlier
claim here, that both `F16GeomL2` and `F16GeomL3` call it, was wrong: `F16GeomL2.get.Amax` is the
only caller.

---

## 3a. Change record — gate 4, 2026-08-19

Gate 4 of the toolbox-trim pass. One static left this class. One stayed.

### `compute_nacelle_diameter` moved out

New home: **`F16GeomL2`, as a `methods (Static)`**. Casey's decision, 2026-08-19. It passed through
`F16GeomBrandtAlt` and then `F16GeomL3` earlier the same day; both are now clear of it, and
`F16GeomBrandtAlt` is once more report-only.

| Item | Detail |
|---|---|
| Why | The equation is Brandt's, from the `Engn(s)` tab. The `1900` divisor is an F-16 convention, not a textbook rule. `GeometryBase` holds only aircraft-agnostic identities. |
| Equation | Unchanged. `sqrt(T_AB_SLS/1900)`. |
| TODOs | Both travelled verbatim. The 7/28 "relocate this" TODO is now done. |
| Consumers repointed | `F16GeomL2.get.D_inlet`, `F16GeomL3.get.D_inlet`. Three doc comments and the `F16GeomL3` class header also name the new home. |
| Declaration | It must sit in a `methods (Static)` block. MATLAB reads the first argument of an instance method as the object, so in an ordinary `methods` block `T_AB_SLS_lb` takes the object slot and the `arguments` block rejects the geometry object. That happened once on 2026-08-19 and was fixed. |
| Tests | No test calls this static directly. No test edit was needed. |
| Frozen examples | Neither B777 nor Aero481 calls it, so the freeze is clear. |

**Numerically inert.** `D_inlet` reads 3.5370222385 ft at both tiers, before and after. `S_wet`
1466.7730567344 (L2) and 1528.6514148855 (L3); `Amax` 27.4889357189 (L2) and 24.7036516658 (L3).
Suite: 964 tests, 22 failures = 19 baseline `testTODO_` guards + 3 frozen Aero481 + 0 real.

**One architectural consequence, flagged not fixed. `F16GeomL3.get.D_inlet` now calls INTO
`F16GeomL2`.**

Both geometry tiers need the nacelle diameter, and one home is right: two copies of one formula is
what produced the `W_max_fuselage` bug on 2026-08-18. With the home at L2, L3 reaches down to it.
That is the L3-to-L2 link Casey retracted on 2026-08-18, so it needs his sign-off. It is also the
reason the static sat in `GeometryBase` until today. `F16GeomL3.get.D_inlet` carries a `_TODO`.

**Casey accepts the Brandt content, on the record.** His TODO on the static, 2026-08-19: *"This
appears to use a Brandt equation. While I want to avoid using his work as much as possible in THIS
part of the code, this is an exception because it's necessary and I cannot find any substitutes from
Raymer, Nicolai, or Roskam. Need to do a scan with Claude, later."* So the ground rule "substitute a
textbook equivalent where one exists" is satisfied by the second half of the rule: none exists, so
the Brandt form is relocated into the F-16 example and the gap is flagged. **A reference scan for a
substitute nacelle-diameter correlation is owed.**

The one option with no link either way: **move it to `F16PropL2`.** The nacelle diameter comes from
engine SLS thrust, and `CLAUDE.md` already states that is engine data, not airframe data. Both
geometry tiers hold an injected `prop` object, so `obj.prop` supplies the value directly.

`F16GeomBrandtAlt` is back to holding only report-only alternates, so its "Alt" name is correct
again, and Casey's 2026-08-18 "may be removed" note is safe: no sizing path calls it. Only the
comparison report and `TestGeomL2` would need edits.

### `compute_Amax_elliptical` moved to `F16GeomL2`

Casey's 7/28 TODO asked for this relocation. Gate 4 declined it. **Gate 4 was wrong, and Casey moved
the static on 2026-08-19.** It now sits in `F16GeomL2`'s `methods (Static)` block, beside
`compute_nacelle_diameter`.

The gate-4 argument rested on a false premise: that both `F16GeomL2` and `F16GeomL3` call it. Only
`F16GeomL2.get.Amax` calls it. `F16GeomL3.get.Amax` calls `obj.get_Amax()`, the whole-aircraft
area-ruled buildup, and `F16GeomL3.m:248` says so in as many words: *"NOT the envelope ellipse (that
is L2's, and stays there)."* `B777GeomL2` never declares `Amax`, and `GeometryModelL2` does not
declare it abstract, because the 2026-08-15 slimming made drag-buildup geometry concrete on
`F16GeomL2`. So a per-fidelity home cannot recreate the L2-to-L3 inversion, because L3 never calls it.

**Numerically inert.** `Amax` holds at 27.4889357189 ft² at L2. One call site moved
(`F16GeomL2.m:379`) plus comment-only references in `F16GeomL2.m:145`, `F16GeomL3.m:5`,
`SubsystemsL2.m:169`, `TestAeroL3.m:193`, `GeomL3.md`, `SubsystemsL2.md`. No test calls the static
directly. Both TODOs travelled with the function, verbatim, and the citation status stays open.

**The tradeoff, on the record.** A future non-F-16 L2 design that wants an envelope `Amax` writes its
own `(π/4)·W·H`. That is the tradeoff already taken for `compute_nacelle_diameter`. `SubsystemsL2`
builds on the same elliptical-envelope assumption but does not call the function, so it is unaffected.

## 4. Conventions — sweep-angle conversion, mirrored vs. single-panel

`GeometryBase.m`'s `convert_sweep` / `convert_sweep_panel` citation notes point readers here.

The coefficient follows from what root→tip spans:

- **Mirrored** (`convert_sweep`) — root→tip spans the **semi**span `b/2`, and `AR = b²/S` is defined
  on the full mirrored planform. `tan Λ_x = tan Λ_LE − x(c_root − c_tip)/(b/2)`, which with
  `c_root = 2S/(b(1+λ))` gives the **4/AR** form. Use for the wing and a conventional horizontal tail.
- **Single panel** (`convert_sweep_panel`) — a vertical tail is one panel: root→tip spans the **full**
  `b`, and `AR = b²/S` is defined on that single panel. The same derivation over `b` instead of `b/2`
  gives **2/AR**, exactly half.

Passing a single-panel AR to `convert_sweep` double-counts the taper term. That was a live defect
until 2026-07-25: the F-16's VT trailing-edge sweep read a physically impossible **0.33°** where the
correct value is **22.90°** (quarter-chord 32.24° → **36.31°**). Verified against the repo's own VT
chords (`readme_geom.md` §4.3: `S_vt` = 60, `AR_vt` = 1.6, `λ_vt` = 0.5 → `b_vt` = 9.798,
`c_root` = 8.165, `c_tip` = 4.082).

## 5. To-dos

| Item | Status |
|---|---|
| `convert_sweep` and `convert_sweep_panel` are cited as a standard planform-geometry identity, not to a specific textbook equation — no Raymer/Roskam edition and equation could be pinned to either against the references in this repo | accepted by decision (2026-07-21) |
| `compute_Amax_elliptical` likewise has **no** known Raymer/Roskam/Mattingly/Brandt equation number and appears in no reference extract here. Documented as a standard identity following the `convert_sweep` precedent; no equation number was invented | todo §4 — **still open**; the question moved with the function to `F16GeomL2` (§3a) |
| `compute_nacelle_diameter` hardcodes **1900**, which silently assumes an afterburning engine — Brandt uses `Engn(s)!L22` = 1900 only when `T_dry ≠ T_AB`, and `L10` = 2000 otherwise | todo §18 — **moved 2026-08-19** to `F16GeomL2`; the divisor question moves with it (§3a). A reference scan for a substitute correlation is still OWED |
| `compute_Amax_elliptical`: Casey's 7/28 TODO asks to relocate it to the F-16 example | **CLOSED 2026-08-19** — Casey moved it to `F16GeomL2`; gate 4's refusal was based on a false premise (§3a) |
| `F16GeomL3` calls `F16GeomL2.compute_nacelle_diameter`, the L3-to-L2 link retracted on 2026-08-18. The one link-free home is `F16PropL2`, since the value comes from engine thrust | **SIGNED OFF 2026-08-19** — Casey accepts the link; `F16PropL2` is not taken |

Brandt's `Geom!B20` = 25.110556 ft² is **not** a comparison target for `compute_Amax_elliptical`: it
is a whole-aircraft area-ruled `MAX` net of an engine flow-through deduction, a different quantity
(F-16A envelope 27.4889, +9.47 %). L3 computes the area-ruled figure instead — see `F16GeomL3.md` §4.
