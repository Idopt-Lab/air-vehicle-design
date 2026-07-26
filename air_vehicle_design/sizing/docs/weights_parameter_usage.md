# Weights parameter usage

Which weight quantity is produced at which fidelity level, by which function, under what citation,
and who consumes it. As-built from `src/base/WeightsBase.m`,
`src/disciplines/weights/WeightsL{1,2,3}.m` + `WeightsModelL{1,2,3}.m`, and
`examples/F16A/F16WeightsL{1,2,3}.m`. Companions: `geometry_parameter_usage.md`,
`aerodynamics_parameter_usage.md`, `propulsion_parameter_usage.md`.

The three levels are different **models**, not refinements of one model: L1 is a statistical
`W_E/W_TO` power law, L2 is surface-density × area plus fractions, L3 is the Raymer §15.3.1
component build-up. Per-component agreement between levels — or with Brandt — is not expected.

---

## 1. Downstream consumers

`OEW(W_TO)` is the only output anything reads. No mission or sizing orchestrator exists yet
(steps 7–8 not started), so today the consumers are `weights_brandt_comparison` and
`fidelity_comparison`. The component/group properties are `Dependent` and exist for reporting and for
the sizing loop that will drive `W_TO`.

`W_TO` and `W_energy` are `NaN` state inputs on the object, mutated by the sizing loop. Getters that
genuinely carry a gross-weight term **error** while `W_TO` is unset rather than returning `NaN`.

---

## 2. Dependency injection

| Direction | Mechanism | What crosses |
|---|---|---|
| geometry → weights | `F16WeightsL2(json_path, req_path, geom, prop)` requires `GeometryModelL2`; `F16WeightsL3(…)` requires `GeometryModelL3` | exposed areas, tail planform, fuselage envelope, control-surface areas, duct/engine lengths — 21 `Dependent` getters at L3 |
| propulsion → weights | same constructors | `prop.T_SL` → `T_max` and Eq. 10.10; `prop.bypass_ratio`; at L3 `prop.get_TSFC(cruise)` → `SFC_mission` |
| requirements → weights | `f16a_requirements_path()` | `design_mach` (Eq. 10.10, 15.3, 15.17); `cruise.altitude_ft` / `cruise.mach` (L3 builds its own `AircraftState`) |

`F16WeightsL1(json_path)` is single-argument — L1 injects nothing, its regressions take only `W_TO`.

Three DI name traps, all real: weights must read `geom.H_max_fuselage` (5.0) not `geom.D_fus` (6.0),
and `geom.S_exposed_ht`/`_vt` (51.1486 / 40.8897) not `geom.S_ht`/`S_vt` (108 / 60). Each wrong-but-
valid wiring produces a plausible number, not an error. The weights-side `AR_ht`/`lambda_ht` were
dead and are deleted, not re-pointed.

---

## 3. Quantity → level, member, citation

### L1 — statistical empty-weight regressions

| Quantity | Function | Formula | Citation |
|---|---|---|---|
| OEW (central estimate) | `WeightsL1.OEW` → `We_fraction_power_law(K_vs, A, C, W_TO)` | `OEW = (K_vs·A·W_TO^C)·W_TO` | Raymer Table 3.1 (jet fighter A = 2.34, C = −0.13, K_vs = 1.00) |
| `W_E` (minimum bound) | `WeightsL1.compute_We_roskam` → `We_roskam(A, B, W_TO)` | `W_E = 10^((log₁₀W_TO − A)/B)` | Roskam Part I Eq. 2.16 + Table 2.15 (jet fighter A = 0.5091, B = 0.9505) |

All four `lookup_coeffs` rows and all five `lookup_roskam_coeffs` rows match their repo extracts
exactly. Both extracts are secondary/OCR sources, not the books.

### L2 — surface density × area, plus fractions

| Quantity | Function | Formula | Coefficient | Citation |
|---|---|---|---|---|
| Wing | `WeightsL2.weight_wing` | `ρ_w·S_w` | 9 lb/ft² | Raymer Table 15.2 |
| HT / VT | `WeightsL2.weight_tail` | `ρ·S` | 4 / 5.3 lb/ft² | Raymer Table 15.2 |
| Fuselage | `WeightsL2.weight_fuselage` | `ρ_fus·S_wet_fus` | 4.8 lb/ft² | Raymer Table 15.2 |
| Landing gear | `WeightsL2.weight_landing_gear` | `f_lg·W_TO` | 0.033 | AE481 metabook §7, "Fraction-Based Weight Estimates" |
| Installed engine | `WeightsL2.weight_installed_engine` | `1.3·N_en·W_en` | 1.3 | AE481 metabook §7 |
| All-else-empty | `WeightsL2.weight_all_else_empty` | `0.17·W_TO` | 0.17 | AE481 metabook §7 |

The three fractions are **not** Raymer Table 15.2 — in the repo extract that table is the psf
surface-density table only, and the fractions are a separate unnumbered metabook table. Brandt uses
0.034 for landing gear; the framework uses the metabook's 0.033. Different models, reported side by
side.

`OEW(W_TO)` recomputes both fraction terms at the **passed** argument. It must not read the
`W_all_else_empty`/`W_installed_engine` properties, which are pinned to the object's own `W_TO`.

### L3 — Raymer §15.3.1 fighter/attack component build-up

Eqs. 15.1–15.24, Raymer 7th ed. Grouped as the class groups them:

| Group | Components (equation) |
|---|---|
| Structural | wing (15.1), HT (15.2), VT (15.3), fuselage (15.4) |
| Landing gear | main (15.5), nose (15.6) — `L_m`/`L_n` in **inches** per Raymer nomenclature |
| Engine | dry engine (Eq. 10.10, not §15.3.1), mounts (15.7), firewall (15.8), section (15.9), air induction (15.10), tailpipe (15.11), cooling (15.12), oil cooling (15.13), controls (15.14), starter (15.15) |
| Systems | fuel system (15.16), flight controls (15.17), instruments (15.18), hydraulics (15.19), electrical (15.20), avionics (15.21), furnishings (15.22), AC/anti-ice (15.23), handling gear (15.24) |

**Every exponent is a standing verify-against-book TO-DO** — 62 rows, tallied 2 CONFLICT / 9
FROM-CODE / 24 VERIFY / 27 IMAGE-ONLY / 5 extract-clean in `WeightsL3.m`'s header and enumerated in
`VnV/BrandtF16A/todo.md` §3a. The two CONFLICTs keep their **code** values: Eq. 15.13 `N_en^1.023`
(extract says 1.078) and Eq. 15.3 `cos(Λ_vt)^−0.323` (extract says −1.0). The values must not be
declared book-verified, and must not be changed to make the guard test green.

`W_l` = `0.95·W_TO` is `Dependent`, feeding Eqs. 15.5/15.6. `W_subsystems` does **not** include the
landing gear — that is `weight_landing_gear(obj, W_TO)`.

### Engine weight — Raymer official, Brandt alternate

| Model | Formula | Basis | Value |
|---|---|---|---|
| **Raymer (official)** | `0.0637·T^1.1·M^0.25·e^(−0.81·BPR)` (Eq. 10.10, via `PropL2.engine_weight_AB`) | uninstalled | 2775.021 lbf |
| Raymer × 1.3 | `1.3 × 2775.021` | installed | 3607.5273 lbf |
| Brandt alternate | `0.199·T_AB_SLS` | already installed | 4730.23 lbf |

**The level determines the basis.** L2 applies `×1.3`; L3 consumes the **uninstalled** value, because
§15.3.1 builds the installation up item by item (mounts, firewall, section, induction, tailpipe,
cooling, oil, controls, starter) — exactly what `×1.3` lumps into one factor. The Brandt alternate
gets no `×1.3` (it is already installed) and is **never summed into `OEW`**; it is a report row and a
positive control on the propulsion DI, locked by
`TestWeightsL2.testBrandtEngineAlternateIsNeverSummedIntoOEW`.

The `×1.3`-at-L3 variant agrees *better* with Brandt (16546.06 vs 15705.33 against 19980.70). That
was the reason to reject it: a number that agrees because a factor is double-counted is not
agreement.

---

## 4. As-built values

Computed live 2026-07-26 at `W_TO` = 31,377 lbf.

| Component | L2 | L3 | Brandt | Cell |
|---|---|---|---|---|
| Wing | 1766.0346 | 2396.7669 | 1785.9468 | `Wt!C9` |
| HT | 199.3890 | 200.5412 | 648.0000 | `Wt!E9` |
| VT | 216.7152 | 313.0598 | 360.0000 | `Wt!F9` |
| Fuselage | 3505.4511 | 3674.1974 | 3652.1100 | `Wt!D9` |
| Landing gear | 1035.4410 | 1160.9336 | 1066.8180 | `Wt!B23` |
| Engine group | 3607.5273 | 3381.6984 | 4730.2300 | `Wt!B11` |
| Systems / all-else | 5334.0900 | 4578.1340 | — | distributed |
| **OEW** | **15664.648** | **15705.331** | **19980.7006** | **`Wt!B12`** |
| L1 OEW | 19110.313 | — | — | — |

Brandt's HT/VT rows use the **full** planform areas (108 / 60); the framework uses the **exposed**
areas per Raymer's definition, so those two rows are `DEFINITIONAL`, not a divergence. Brandt also
carries nacelle (186.82), strake (90.00), other-structure (2016.86) and armament-support (440.00)
line items with no framework analog — about 2733.68 lbf, 13.68 % of `Wt!B12`.

Other live L3 values: `W_l` = 29808.15 (`0.95·W_TO`; Brandt's `Wt!B41` = 20680.70 is a
back-calculated output of his own weight statement, a different quantity); `SFC_mission` = 1.007116
1/hr via propulsion DI at 36,000 ft / M 0.87 (Brandt `Main!C30` = 0.70, +43.87 %, accepted);
`V_t` = 940 gal (a JSON input, deliberately not derived).

Payload is 700 fixed / 4400 expendable at every level `[Brandt Wt!B4/B5]`. Closure is exact:
`31377 − 19980.70 − 6296.30 = 5100 = 700 + 4400`.

**OEW ground truth is 19,980.70 `[Wt!B12]`, live-verified.** 19,148.08 comes from Casey's
`corrections.xls` and appears only as a labelled alternate column in `weights_brandt_comparison`.
The OEW-vs-Brandt agreement check lives in that report, **not** in the unit tier — per CLAUDE.md's
two-tier rule an agreement check is not a unit test. The unit tier keeps `OEW < W_TO`, `OEW > 0`, a
sanity minimum, the fraction identity, and per-equation hand-computed values.

---

## 5. Open items

| Item | Status |
|---|---|
| **Darshan -> Krish: High-Priority To-Do: L2 and L3 weights** | These need to be cross-checked. They are giving significantly lower than Brandt. |
| All 62 Raymer §15.3.1 exponents unverified against the printed book | guarded red by `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified`; todo §3a |
| Raymer Table 6.1 coefficients are not in the repo (code uses Table 3.1) | guarded red by `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`; todo §P4-8 |
| The `0.95` in `W_l = 0.95·W_TO` has no citation | todo §P4-16 — needs a cited landing-weight fraction |
| `K_d = 0` silently zeroes the 227.54 lbf air-induction term (`0^0.182 = 0`) — no error, no warning, not even NaN | **unguarded by decision**; todo §P4-11. Visible only as a sensitivity row in the comparison report. If `K_d = 0` is legal, `K_d` cannot be Raymer's multiplicative base, so the exponent/placement is itself suspect |
| `design_mach` = 2.0 cited to Brandt; the T.O. limit is 2.05 | todo §P4-13 — user to confirm which is the design requirement |
| `WeightsL2.LG_fraction` has an uncited `general_aviation` 0.057 row and no `navy_fighter` 0.045 row | todo §P4-7; the absence is pinned by `testLGFractionHasNoNavyFighterRow` |
| The 6.7 lb/gal fuel density behind `V_t` = 940 is cited nowhere in `sizing/` | todo §P4-5b — `V_t` stays an input so the uncited constant never enters an equation |
| `L_d` / `D_e` have cited geometry analogs that are deliberately not wired | todo §P4-4; both are sensitivity rows in the comparison report |
