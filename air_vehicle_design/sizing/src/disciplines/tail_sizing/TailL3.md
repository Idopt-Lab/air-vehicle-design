# TailL3

Level-3 tail-sizing static toolbox (`classdef TailL3`, `methods (Static)` only). Called as
`TailL3.method(...)`; never instantiated. `F16TailL3` inherits `TailSizingModelL3` and delegates here.

**DOCUMENTED-TODO STUB.** No real equations are implemented. The file exists so the three-tier
structure is constructible now. History and rationale: `docs/decision_log.md`;
`TailSizing_scribe_plan.md` Sec. 6.

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
| `size(obj)` | **Always errors**, `TailL3:citationNotAvailable`. Never returns a fabricated value or a silent `NaN`. |

Same idiom as `GeomL1.lookup_control_surface_fraction`'s error on the missing Raymer Table 6.5
aileron chord fraction — an explicit, labeled failure rather than a guess.

## 3. Intended future contract (design intent only — not built)

Target shape for a future implementer. **None of this is implemented.**

- **HT sizing via static margin.** Invert a neutral-point equation (form in `temp_Casey`'s
  `SandCLevel3.compute_Xbar_np` and `BrandtBalanceStabControl.analyze`'s `xnp_ft`) for `S_HT` given a
  target static margin `SM_required` (or `C_m_alpha`) and a CG estimate.
- **VT sizing via directional stability.** Nicolai Sec. 11.2 (p.284) gives the criteria: subsonic
  cruise `C_n_beta` target 0.08–0.17 rad⁻¹, high-speed (`M>2`) minimum `C_n_beta=0.08` rad⁻¹. Invert
  a `C_n_beta` buildup for `S_VT`.
- **VT sizing via crosswind landing.** Nicolai Sec. 11.2 item 1 — applicable to the F-16.
- **One-engine-out yaw balance — SKIPPED.** Not applicable to the single-engine F-16; may remain in
  the generic contract for a future multi-engine airframe.

**Deliberately deferred — do NOT add speculatively:** CG range / converged `x_cg`; target
`SM_required` (or `C_m_alpha`); target `C_n_beta,required`; crosswind design condition; a new
`TailL3`-injects-`aero` DI pattern. None have a `f16a_requirements.json` field today. See
`docs/decision_log.md`.

## 4. To-dos

| Item | Guard |
|---|---|
| Raymer Ch. 16 stability-and-control tail-sizing equation numbers are not verifiable from anything in this repository — see Sec. 1 above | deliberately-failing `TailL3:citationNotAvailable` error; companion test (test-writer's responsibility) should assert this error fires, following the `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` labeled-EXPECTED-RED convention |
