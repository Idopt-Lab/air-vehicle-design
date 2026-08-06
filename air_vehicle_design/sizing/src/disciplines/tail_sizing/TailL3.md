# TailL3

Level-3 tail-sizing static toolbox (`classdef TailL3`, `methods (Static)` only). Called as
`TailL3.method(...)`; never instantiated and not in the inheritance chain. `F16TailL3` inherits
`TailSizingModelL3` and delegates here.

**DOCUMENTED-TODO STUB.** No real equations are implemented. This file exists so the three-tier
structure is complete and constructible now, per `TailSizing_scribe_plan.md` Sec. 6's finalized
decision to ship a citation-missing failure structure rather than block on further research or invent
an equation number.

---

## 1. Why there are no equations here

Raymer 6th ed. Chapter 16's stability-and-control tail-sizing equations — (a) sizing `S_HT` from a
required static margin / `C_m_alpha`, (b) sizing `S_VT` from a required directional-stability
derivative — are not verifiable from anything in this repository:

| Candidate source | Why it doesn't pin a citation |
|---|---|
| `temp_AI/docs/disciplines/reference_extracts/` | Nicolai & Carichner, not Raymer; defers the closed-form criteria-based equations to its own Ch. 21/23, both marked "pending" (not extracted) |
| `raymer_data.md` | The actual Raymer OCR extract in this repo has no Ch. 4/6/16 content |
| `temp_Casey/SandCLevel3.m` | Cites "eq 16.25", "fig 16.3", "fig 16.16" but these are unverified against the book — forward-analysis only, read-only reference per CLAUDE.md |
| `VnV/BrandtF16A/BrandtBalanceStabControl.m` | Likewise forward-analysis only, not wired to this framework's own weights classes |

Full record: `VnV/BrandtF16A/todo.md` 2026-07-28 Finding 3 (status **RESOLVED-DEFERRED**);
`TailSizing_scribe_plan.md` Sec. 6/7.3.

## 2. What exists instead

| Method | Behavior |
|---|---|
| `size(obj)` | **Always errors**, `TailL3:citationNotAvailable`, with a message pointing at this file and the todo.md finding. Never returns a fabricated value or a silent `NaN`. |

This follows the same idiom as `GeomL1.lookup_control_surface_fraction`'s error on the missing Raymer
Table 6.5 aileron chord fraction — an explicit, loud, labeled failure rather than a guess.

## 3. Intended future contract (design intent only — not built)

Documented here so a future implementer has the target shape without re-deriving it, per the scribe
plan's explicit request. **None of this is implemented; do not treat it as available.**

- **HT sizing via static margin.** Invert a neutral-point equation of the general form demonstrated
  (uncited-per-equation-number) in `temp_Casey`'s `SandCLevel3.compute_Xbar_np` and
  `BrandtBalanceStabControl.analyze`'s `xnp_ft` formula for `S_HT` given a target static margin
  `SM_required` (or target `C_m_alpha`) and a CG estimate.
- **VT sizing via directional stability.** Nicolai Sec. 11.2 (in-repo, citable as narrative, p.284)
  gives the criteria: subsonic cruise `C_n_beta` target 0.08–0.17 rad⁻¹, high-speed (`M>2`) minimum
  `C_n_beta=0.08` rad⁻¹. Invert a `C_n_beta` buildup (VT contribution + wing/fuselage baseline) for
  `S_VT`.
- **VT sizing via crosswind landing.** Nicolai Sec. 11.2 item 1 — applicable to the F-16, narrative
  only.
- **One-engine-out yaw balance — SKIPPED.** Not physically applicable to the F-16 (single engine).
  May remain in the generic `TailSizingBase`/`TailL3` contract for a future multi-engine airframe
  (parallels `ControlSurfaceSizer`'s documented F-16 all-moving-tail exception to Table 6.5).

**Deliberately deferred, per the coordinator's instruction — do NOT add speculatively:**

- CG range (forward/aft limits) or a converged `x_cg` — no `f16a_requirements.json` field, no new
  cross-discipline injection from weights/balance.
- Target static margin `SM_required` (or target `C_m_alpha`) — no `f16a_requirements.json` field.
- Target `C_n_beta,required` — no `f16a_requirements.json` field (even though the *narrative* target
  range is citable to Nicolai Sec. 11.2 today, the numeric requirement is not being wired in yet).
- Crosswind design condition (max crosswind velocity) — no `f16a_requirements.json` field.
- A new `TailL3`-injects-`aero` DI pattern (to read `CL_alpha`, downwash `d(epsilon)/d(alpha)`) —
  deferred; no discipline in this framework currently injects an aero object into anything, and this
  would be a new architectural pattern, not just a new input.

## 4. To-dos

| Item | Guard |
|---|---|
| Raymer Ch. 16 stability-and-control tail-sizing equation numbers are not verifiable from anything in this repository — see Sec. 1 above | deliberately-failing `TailL3:citationNotAvailable` error; companion test (test-writer's responsibility) should assert this error fires, following the `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` labeled-EXPECTED-RED convention |
