# F16WeightsL3

**STATUS: AS-BUILT (reconciled 2026-07-25, step 2d).** This doc previously described the Phase-4
*target*; everything below now describes what shipped. Rows still tagged `AS-IS` describe the
**pre-Phase-4** code and are kept only where they explain a defect that was fixed — read them as `WAS`.
**All six settled decisions of 2026-07-25 are implemented** (`docs/weights_parameter_usage.md` Part
A.2); every one of them touches L3:

| # | Decision | Effect at L3 |
|---|---|---|
| 1 | `W_en` **UNINSTALLED** (no ×1.3 here; ×1.3 is L2-only) | engine group 3639.26 → **3381.70** |
| 2 | `SFC_mission` **DERIVED** = `prop.get_TSFC(cruise)` | **1.007116** 1/hr; fuel system 386.79 → **423.47** |
| 3 | `V_t` **RESTORED** as a JSON input, 940 gal | no change; uncited-density warning kept |
| 4 | `W_l` **DERIVED** = `0.95 · W_TO` | LG total 1057.27 → **1160.93**; also fixes a newly-found frozen-under-mutation bug (§E.3) |
| 5 | new `f16a_requirements.json` supplies the cruise condition + `design_mach` | 3 new inputs; `.weights.vertical_tail.M_design` becomes a duplicate to delete |
| 6 | `K_d` **unchanged**, silent zero retained | §D.5 |

F-16A Block 10/15 Level-3 weight concrete class (`classdef F16WeightsL3 < WeightsModelL3`). Implements
the **Raymer §15.3.1 Fighter/Attack statistical component build-up, Eqs. 15.1–15.24**. Every abstract
method is a single delegation line into the `WeightsL3` static toolbox.

L3 carries the largest Phase-4 delta: review finding **#11** (constructor reads nothing; ~22 geometry
constants frozen as literals), finding **#12** (five NaN "computed total" properties), and the
`F16GeomL3` + `F16PropL2` injections.

> **★ STANDING TO-DO, NOT CLEARED: every §15.3.1 exponent.** Locked decision (user 2026-07-24,
> approach 2): **keep every current code value as-is** — including the two code-vs-extract
> CONFLICTS, Eq. 15.13 `N_en^1.023` and Eq. 15.3 `cos(Λ_vt)^−0.323` — **re-cite them to a consistent
> Raymer 7th ed. §15.3.1 reference**, and **do not declare them book-verified**. The complete 62-row
> checklist is `VnV/BrandtF16A/todo.md` 2026-07-24 Weights §3a. **Shipped guard:
> `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified`** — labelled, verified red 2026-07-25,
> keyed off `WeightsL3.m`'s own standing-TO-DO sentence (there is no JSON marker key for it).
> **Zero exponent VALUES changed.**
>
> ★ **And a false claim was REMOVED from `WeightsL3.m`'s header.** It previously asserted the
> exponents had been *"re-verified letter-for-letter against the Raymer 6th ed. p.572 equation page
> image (not OCR)"* — a claim that (a) cannot be checked, because no such image exists anywhere in this
> repo, and (b) directly contradicted the `[verify]` warnings on the same equations elsewhere in the
> same file. It is replaced by an honest tally: **2 CONFLICT / 9 FROM-CODE / 24 VERIFY / 27 IMAGE-ONLY
> / 5 extract-clean**, with the IMAGE-ONLY entry stating plainly that the claim was not checkable. The
> same claim was stripped from the wing / HT / VT / fuselage / gear / mounts method comments, which had
> been saying "all exponents confirmed" while the high-level methods above them said `[verify]`.

Numbers marked *(live)* were computed 2026-07-25 via `mcp__matlab__evaluate_matlab_code`. Brandt cells
marked *(live)* were read directly from `VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls` over Excel COM
the same day.

---

## A. Constructor / input mechanism — review finding #11, **FIXED**

```matlab
prop = F16PropL2(f16a_spec_path(2));          % no L3 propulsion tier exists
g3   = F16GeomL3(f16a_spec_path(3), prop);
w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
```

| | As built | `WAS` (pre-Phase-4) |
|---|---|---|
| Signature | **`F16WeightsL3(json_path, req_path, geom, prop)`** — all four required, no silent default | `F16WeightsL3()` — no-arg, **empty body** |
| `geom` guard | `geom (1,1) GeometryModelL3`, i.e. `F16GeomL3` — the **full L3 geometry tier**, NOT `F16GeomL2`. A wrong tier fails at **construction** (`testWrongGeomTierErrorsAtConstruction`) | *(none)* |
| `prop` guard | `prop (1,1) PropulsionBase`. ★ At the L3 rung this is an **`F16PropL2`**: there is no L3 propulsion tier (locked decision 2026-07-25), and anything reporting an "L3 propulsion" number must say so | *(none)* |
| Spec data | **37** numeric scalars from `.weights` + `aircraft_category` (top level) + **3** from the requirements file + **2** deliberately-unread state variables = 42 numeric inputs; plus 21 geometry + 3 propulsion quantities arriving as `Dependent` getters by DI | **72 hardcoded classdef defaults** (counted live), of which **23 were geometry** |
| JSON read | `jsondecode(fileread(json_path))` → top-level `aircraft_category` + `.weights.{N_z, W_payload_*, wing, horizontal_tail, vertical_tail, landing_gear, engine_section, systems}` | **none — the entire `.weights` block of `f16a_L3.json` was DEAD** |
| Requirements read | `jsondecode(fileread(req_path))` → **`design_mach`**, **`cruise.altitude_ft`**, **`cruise.mach`** (decision 5). Weights **builds the `AircraftState` itself** inside `get.SFC_mission` — the earlier "inject an `AircraftState`" idea was reversed by the user; nothing is injected but `geom` and `prop` | *(none)* |

**Finding #11, quoted so the fix stays traceable.** The pre-Phase-4 `F16WeightsL3.m:156-164` — the
whole constructor:

```matlab
function obj = F16WeightsL3()
    % B_h is set directly from the reported USAF full span (see the
    % property default above) -- no longer derived from AR_ht/S_ht.
    % Note: The AR and S_ht are derived from the USAF manual. ...
end
```

Comment only. No assignment, no argument, no JSON — so the `.weights` block Phase 3 carefully minimised
was read by nothing, and every value the class used was a literal in the classdef.
`TestWeightsL3.testJSONInputsAreActuallyRead` and `testRequirementsAreReadFromTheRequirementsFile` are
the shipped regression guards against that regressing.

---

## B. INPUT vs DERIVED classification — as built

Pattern per CLAUDE.md → "Optimization-ready property design"; reference implementation
`examples/F16A/F16GeomL2.m` header. **Inputs** = plain mutable `properties` set once by the
constructor. **Derived** = `properties (Dependent)`, `get.<name>` recomputes live on every read, no
stored copy, read-only (assigning errors — they are outputs).

**COUNTS, verified live 2026-07-25 from the metaclass `PropertyList`: 45 plain / 31 `Dependent`** —
the 45 plain being **43 INPUTS (42 numeric + `aircraft_category`) + 2 injected objects** (`geom`,
`prop`). **2 properties were DELETED** (§B.4). No input is left "open": decisions 2–5 closed all three
of the earlier revision's held items.

Where the **42 numeric inputs** come from, as built:

| Source | Count | Which |
|---|---|---|
| `f16a_L3.json .weights` | **37** | `N_z`, both payloads, 5 `K_*` flags (`K_dw`, `K_vs`, `K_rht`, `K_dwf`, `K_vsh`), 6 landing gear, 10 engine section, 13 systems (incl. `V_t`, restored by decision 3) |
| `f16a_requirements.json` | **3** | `design_mach`, `cruise_altitude_ft`, `cruise_mach` |
| not read — sizing/mission **state** | **2** | `W_TO`, `W_energy` — deliberately left `NaN` |

`WAS`, pre-Phase-4, counted live: **72 plain properties, 0 `Dependent`** — 5 NaN "computed total"
placeholders (finding #12), **23 frozen geometry literals** (21 wired to `geom` in §B.2, 2 dead per
§B.4), 2 frozen propulsion literals (`T_max`, `W_en`), plus `W_l` and `SFC_mission` which are now
derived, and 40 genuine inputs. **32 of the 72 changed kind or were deleted**, and `aircraft_category`
+ the 3 requirements scalars were added.

The 31 derived split as: **21** geometry-by-DI (§B.2 rows 1–21), **1** propulsion-by-DI (`T_max`),
**2** computed engine weights (`W_en` official + `W_en_brandt` alternate), **2** newly derived by
decisions 2 and 4 (`SFC_mission`, `W_l`), **5** group totals. `TestWeightsL3` locks the count directly:
`testAllThirtyOneDependentPropertiesExist` and `testNoDependentPropertyIsNonFinite`.

*(As built there is no `Dependent cruise_state` intermediate — `get.SFC_mission` constructs the
`AircraftState` inline. Noted because an earlier revision floated it as optional.)*

### B.1 INPUTS (42 numeric + `aircraft_category`)

#### Sizing-loop / payload (`WeightsBase` contract) — 4

| # | Property | Value | Units | Citation | Why an input |
|---|---|---|---|---|---|
| 1 | `W_TO` | `NaN` | lbf | `WeightsBase` contract | The optimizer's variable, mutated in place by the sizing loop |
| 2 | `W_energy` | `NaN` (AS-IS **6296.3**) | lbf | `WeightsBase` contract | Set by mission analysis. AS-IS 6296.3 is `Brandt Wt!B6` = `=B3-B4-B5-B12` *(live formula)*, a back-calculated **output** — forbidden as an input. Deleted from the JSON in Phase 3 |
| 3 | `W_payload_fixed` | **700** (AS-IS 220) | lbf | `[Brandt Wt!B4 = 700.000000 (live), =Main!O16]` | Mission spec |
| 4 | `W_payload_expendable` | **4400** (AS-IS 0) | lbf | `[Brandt Wt!B5 = 4400.000000 (live), =Main!O17]` | Mission spec |

#### Load factor, Raymer K-flags, requirements — 9 (6 flags/load-factor + 3 requirements)

| # | Property | Value | JSON key | Citation | Why an input |
|---|---|---|---|---|---|
| 5 | `N_z` | 13.5 | `.weights.N_z` | `[T.O. 1F-16A-1 §5; Raymer 7th ed. §15.3.1 N_z = 1.5 × n_limit = 1.5×9]` | Structural design requirement, not derivable from geometry. **Not to be conflated with Brandt's `Main!Q27` n_ult = 9** — a different model |
| 6 | `K_dw` | 1.0 | `.weights.wing.K_dw` | `[Raymer 7th ed. §15.3.1 — not a delta wing]` | Configuration flag |
| 7 | `K_vs` | 1.0 | `.weights.wing.K_vs` | `[Raymer 7th ed. §15.3.1 — not variable sweep]` | Configuration flag |
| 8 | `K_rht` | 1.047 | `.weights.horizontal_tail.K_rht` | `[Raymer 7th ed. §15.3 — rolling (all-moving) tail]` | Configuration flag. Applied in Eq. **15.3** (VT), not 15.2 — as printed in the book, not a mix-up (`WeightsL3.m:193-196`) |
| 9 | `K_dwf` | 1.0 | `.weights.vertical_tail.K_dwf` | `[Raymer 7th ed. §15.3.1 — not a delta-wing fuselage]` | Configuration flag |
| 10 | `design_mach` (was `M_design`) | 2.0 | ★ **`f16a_requirements.json` → `design_mach`** — **DELETE** `.weights.vertical_tail.M_design`, now a duplicate | `[Brandt Main! aircraft.Mmax = 2.0; GroundTruth/f16a_geometry.json:9]` — ★ **NOT** the T.O. Mach **limit** 2.05 (`f16a_ground_truth.json:228`, `_source: "T.O. 1F-16A-1 operating limits."`). 2.0 ≠ 2.05, −2.44 %. Live `W_en` sensitivity: 2775.0210 → 2792.2046 (+0.62 %). Do not cite 2.0 to the T.O. — todo §P4-13 | Design max Mach: an aircraft **requirement**, not weights spec data. Feeds Eq. 15.3 `M^0.341`, Eq. 15.17 `M^0.003`, **and** Eq. 10.10 `M^0.25` for `W_en`. Settled decision 5 closes §P4-3 |
| 10a | `cruise_altitude_ft` | 36000 | **`f16a_requirements.json` → `cruise.altitude_ft`** | `[Brandt Consts! row 24 cruise condition (pct_AB = 0, dry/mil); GroundTruth/f16a_ground_truth.json .propulsion.thrust_lapse_at_constraint_conditions cruise row, live-verified 2026-07-24]` | Flight condition at which `SFC_mission` is evaluated. **NEW** (decision 5). Weights builds `AircraftState(cruise_altitude_ft, cruise_mach)` itself — no `AircraftState` is injected |
| 10b | `cruise_mach` | 0.87 | **`f16a_requirements.json` → `cruise.mach`** | same | as 10a. **NEW** |
| 11 | `K_vsh` | 1.0 | `.weights.systems.K_vsh` | `[Raymer 7th ed. §15.3.1 — no variable-sweep hydraulics]` | Configuration flag |

#### Landing gear — 6 (+ `W_l`, see §B.3)

| # | Property | Value | JSON key | Citation | Why an input |
|---|---|---|---|---|---|
| 12 | `N_l` | 2.67 | `.weights.landing_gear.N_l` | `[standard military; verify T.O. §5 — estimate]` | Landing load factor: a requirement |
| 13 | `L_m` | 5.5 ft | `.weights.landing_gear.L_m` | `[estimate, unpinned]` | Main-gear strut length. No gear geometry anywhere in the repo. ★ Converted to **inches** (×12) inside `WeightsL3.weight_landing_gear` per Raymer's nomenclature (6th ed. pp.577–578) |
| 14 | `L_n` | 3.5 ft | `.weights.landing_gear.L_n` | `[estimate, unpinned]` | Nose-gear strut length; same inch conversion |
| 15 | `K_cb` | 1.0 | `.weights.landing_gear.K_cb` | `[Raymer 7th ed. §15.3.1 — not carrier-based]` | Configuration flag |
| 16 | `K_tpg` | 1.0 | `.weights.landing_gear.K_tpg` | `[Raymer 7th ed. §15.3.1 — not kneeling gear]` | Configuration flag |
| 17 | `N_nw` | 1 | `.weights.landing_gear.N_nw` | `[T.O. 1F-16A-1]` | Nose-wheel count |

#### Engine section — 10 (+ `W_en`, `T_max`, see §B.2)

| # | Property | Value | JSON key | Citation | Why an input |
|---|---|---|---|---|---|
| 18 | `N_en` | 1 | `.weights.engine_section.N_en` | `[T.O. 1F-16A-1]` | Engine count. Not derivable — no propulsion class exposes a count (todo 2026-07-25 Phase 2 §22) |
| 19 | `S_fw` | 0 | `.weights.engine_section.S_fw` | `[Raymer 7th ed. §15.3.1 — no piston firewall on a jet]` | Config; makes Eq. 15.8 return 0 |
| 20 | `D_e` | 3.33 ft | `.weights.engine_section.D_e` | `[estimate, ≈40 in, unpinned]` | ⚠ **geometry analog exists** — `geom.D_exit` = 3.537022. Wiring it is an OPEN decision, §B.5 |
| 21 | `L_tp` | 4.5 ft | `.weights.engine_section.L_tp` | `[estimate, unpinned]` | Tailpipe length; no repo geometry analog |
| 22 | `L_sh` | 8.0 ft | `.weights.engine_section.L_sh` | `[estimate, unpinned]` | Engine shroud length; no analog |
| 23 | `L_ec` | 5.0 ft | `.weights.engine_section.L_ec` | `[estimate, unpinned]` | Engine-controls run; no analog |
| 24 | `L_d` | 7.5 ft | `.weights.engine_section.L_d` | `[estimate, unpinned]` | ⚠ **geometry analog exists** — `geom.L_duct` = **14.0** `[Brandt Main!F32]`, +86.7 %. OPEN, §B.5 |
| 25 | `L_s` | 3.0 ft | `.weights.engine_section.L_s` | `[estimate, unpinned]` | Splitter length; no analog. ⚠ `L_s = 0` → `(L_s/L_d)^−0.373` = `Inf`, §D.5 |
| 26 | `K_vg` | 1.0 | `.weights.engine_section.K_vg` | `[Raymer 7th ed. §15.3.1 — fixed-geometry inlet]` | Configuration flag |
| 27 | `K_d` | 1.0 | `.weights.engine_section.K_d` | `[Raymer 7th ed. §15.3.1; "use 1.0 as baseline; verify from §15.3.1"]` | Duct-shape flag. ⚠ `WeightsL3.m:276` documents `K_d = 0` as the legitimate straight-duct value, and `0^0.182 = 0` silently zeroes the entire air-induction term — a **reachable-by-design** silent-zero path, §D.5 |

#### Systems — 13 (`SFC_mission` is DERIVED, §B.2 row 24b — it is not one of these 13)

| # | Property | Value | JSON key | Citation | Why an input |
|---|---|---|---|---|---|
| 27a | `V_t` | **940 gal** | `.weights.systems.V_t` — ★ **RESTORED** (settled decision 3) | `[derived by Brandt-style arithmetic: Wt!B6 = 6296.30 lbf ÷ 6.7 lb/gal ≈ 940 gal]` — ★ **the 6.7 lb/gal density is cited NOWHERE in this repo.** Grepped `air_vehicle_design/sizing/` 2026-07-25: 6.7 lb/gal appears only in the `F16WeightsL3.m:125` comment, and **no JP-4/JP-5/JP-8 density is cited anywhere** (not in `metabook_data.md`, `raymer_data.md`, `readme_wt.md`, or `F16Baseline.m`) | Total internal fuel volume. **Deliberately an INPUT, not derived**: `V_t = W_energy / ρ_fuel` would replace one Brandt-traceable number with an **uncited constant**, making provenance worse. (The arithmetic also yields 939.746, not 940.) Provenance warning stays open: todo §P4-5b |
| 28 | `V_i` | 500 gal | `.weights.systems.V_i` | `[estimate; F-16 wing integral tanks, unpinned]` | Integral-tank volume; no repo source |
| 29 | `V_p` | 0 gal | `.weights.systems.V_p` | `[estimate, unpinned]` | Pressurised-tank volume |
| 30 | `N_t` | 3 | `.weights.systems.N_t` | `[estimate: 2 wing + 1 fuselage; verify T.O.]` | Tank count |
| 31 | `N_s` | 4 | `.weights.systems.N_s` | `[estimate: flaperon, stab, rudder, LEF]` | Control-surface count |
| 32 | `N_c` | 1 | `.weights.systems.N_c` | `[T.O. 1F-16A-1 — single-seat]` | Crew/cockpit count |
| 33 | `N_ci` | 3 | `.weights.systems.N_ci` | `[estimate; F-16 Block 10, unpinned]` | Comm/ID item count |
| 34 | `N_u` | 5 | `.weights.systems.N_u` | `[estimate, unpinned]` | Hydraulic utility functions |
| 35 | `R_kva` | 80 kVA | `.weights.systems.R_kva` | `[estimate; F-16 Block 10 ≈60–80 kVA, unpinned]` | Electrical power requirement |
| 36 | `L_a` | 10.0 ft | `.weights.systems.L_a` | `[estimate, unpinned]` | Electrical lead length |
| 37 | `N_gen` | 1 | `.weights.systems.N_gen` | `[T.O. 1F-16A-1]` | Generator count |
| 38 | `W_uav` | 1500 lbf | `.weights.systems.W_uav` | `[estimate; F-16 Block 10 simple suite, unpinned]` | Uninstalled avionics weight |
| 39 | `K_mc` | 1.0 | `.weights.systems.K_mc` | `[Raymer 7th ed. §15.3.1 — ≤2 generators]` | Configuration flag |
| — | `aircraft_category` | `'jet_fighter'` | top-level | `[f16a_L3.json aircraft_category]` | **ADDED in Phase 4** (`WAS`: the class had no such property). ★ No `WeightsL3` static reads it, and that is correct **by construction** — `WeightsL3` implements only Raymer's Fighter/Attack build-up, so there is one path and no category lookup. It is carried for interface parity with L1/L2 (which do key their lookups off it) and for report labelling. See §D.7 |

#### Injected objects — 2 (not numeric)

| Object | Class | Supplies | Note |
|---|---|---|---|
| `geom` | **`F16GeomL3`** | 21 derived geometry quantities (§B.2 rows 1–21) | The full L3 geometry tier — `examples/F16A/F16GeomL3.md` |
| `prop` | `F16PropL2` | `T_max`, and `T_SL`/`bypass_ratio` for Eq. 10.10 | ★ **No L3 propulsion tier exists** — `F16PropL2` sits at the L3 rung and must be labelled as such (locked decision 2026-07-25) |

### B.2 DERIVED (31) — `properties (Dependent)`, recomputed live

*(Row numbering below runs 1–21, 22–24, 24a, 24b, 25–29 = **31** properties.)*

#### Geometry, by DI from `F16GeomL3` (21) — closes finding #11's frozen literals

| # | Derived | `geom` member | Value *(live)* | `WAS` literal | Raymer eq. | Citation |
|---|---|---|---|---|---|---|
| 1 | `S_w` | `S_exposed_wing` | 196.2261 | 196.23 | 15.1 | `[Brandt Geom!7; readme_geom.md §4.3]` via `GeomL2.compute_S_exposed_horizontal` |
| 2 | `AR_w` | `AR_wing` | 3.0 | 3.0 | 15.1 | `[Brandt Main!B19]`; corroborated `[T.O. Fig. 1-2]` |
| 3 | `tc_root` | `tc_r_wing` | 0.04 | 0.04 | 15.1 | `[Brandt Main!B22 = 1404 → 4 % t/c]`; `[T.O. Fig. 1-2, NACA 64A204]` |
| 4 | `lambda_w` | `lambda_wing` | 0.2275 | 0.2275 | 15.1 | `[Brandt Main!B20]` |
| 5 | `Lambda_LE_w` | `LE_sweep_wing` | 40 | 40 | 15.1 | `[Brandt Main!B21]` |
| 6 | `S_csw` | `S_csw` | 68.03 | 68.03 | 15.1 | `[T.O. Fig. 1-2: flaperon 31.32 + LEF 36.71]` |
| 7 | `S_ht` | ★ **`S_exposed_ht`** — **NOT** `geom.S_ht` = 108 | **51.1486** | **49.85** | 15.2 | `GeomL2.compute_S_exposed_horizontal` on the option-B HT chords; `[readme_geom.md §4.3]`. **+2.605 %** — an INTENTIONAL Decision-1 divergence (`F16GeomL3.md` §A.4) |
| 8 | `F_w` | `F_w` | 7.0 | 7.0 | 15.2 | `[Brandt Main!C32 max-width proxy — estimate]` |
| 9 | `B_h` | `B_h` | 18.5 | 18.5 | 15.2 | `[USAF 3-view, 18 ft 6 in]` |
| 10 | `S_vt` | ★ **`S_exposed_vt`** — **NOT** `geom.S_vt` = 60 | 40.8897 | 40.89 | 15.3 | `GeomL2.compute_S_exposed_vertical`; `[readme_geom.md §4.3]` |
| 11 | `AR_vt` | ★ **`AR_exposed_vt`** — **NOT** `geom.AR_vt` = 1.6 | 1.294 | 1.294 | 15.3 | `[physical construction value; T.O./USAF]` |
| 12 | `lambda_vt` | ★ **`lambda_exposed_vt`** — **NOT** `geom.lambda_vt` = 0.5 | 0.437 | 0.437 | 15.3 | `[physical; T.O./USAF]` |
| 13 | `Lambda_LE_vt` | `LE_sweep_vt` | 47.5 | 47.5 | 15.3 | `[T.O. 1F-16A-1]` — intentional divergence from `Brandt Main!H21` = 40 |
| 14 | `H_t` | `H_t` | 0 | 0 | 15.3 | `[Raymer 7th ed. §15.3 — conventional (non-T) tail]` |
| 15 | `H_v` | `H_v` | 1 | 1 | 15.3 | `[Raymer 7th ed. §15.3 — any nonzero denominator]` |
| 16 | `L_t` | `L_t` | 22.0 | 22.0 | 15.3 | `[estimate; verify T.O.]` — not derivable (needs the MAC y-station, `F16GeomL3.md` §A.1 #33) |
| 17 | `S_r` | `S_r` | 11.65 | 11.65 | 15.3 | `[T.O. Fig. 1-2]` |
| 18 | `L_fus` | `L_fus` | 47.5 | 47.5 | 15.4 | `[T.O. 1F-16A-1]` — intentional divergence from `Brandt Main!B32` = 46.5 |
| 19 | `D_fus` | ★ **`H_max_fuselage`** — **NOT** `geom.D_fus` = 6.0 | **5.0** | 5.0 | 15.4 | `[Brandt Main!D32; T.O. cross-section]`. Eq. 15.4's **structural depth**, not the Roskam Eq. 12.3 equivalent diameter |
| 20 | `W_fus` | `W_max_fuselage` | 7.0 | 7.0 | 15.4 | `[Brandt Main!C32; T.O.]` |
| 21 | `S_cs` | `S_cs` | 190 | 190 | 15.17 | `[estimate: flaperon + HT + rudder + LEF, unpinned]` |

#### Propulsion, by DI from `F16PropL2` (1) + computed engine weight (2)

| # | Derived | Formula | Value *(live)* | `WAS` | Citation |
|---|---|---|---|---|---|
| 22 | `T_max` | `prop.T_SL` | 23770 | 23770 (frozen literal) | `[Brandt Engn(s)!T_AB_SLS = Main!D29]`. Feeds Eqs. 15.7, 15.15, 15.16 |
| 23 | `W_en` | `PropL2.engine_weight_AB(prop.T_SL, design_mach, prop.bypass_ratio)` — ★ **UNINSTALLED, no ×1.3** | **2775.0210** | 3030 `[estimate]` | `[Raymer 7th ed. Eq. 10.10]`, coefficient 0.0637 at `raymer_data.md:38`. **Settled decision 1** — see §D.2 for why uninstalled at L3 and installed at L2 |
| 24 | `W_en_brandt` | `0.199 · prop.T_SL` — **no ×1.3** | **4730.2300** | — | `[Brandt Wt!B11 = 4730.230000 (live)]`; 0.199 literal at `'Engn(s)'!D22` *(live)*. **NEW** — comparison-report alternate only, never summed. `readme_wt.md:230` confirms it is already installed |
| 24a | **`W_l`** | ★ `0.95 · obj.W_TO` | **29808.15** at `W_TO`=31377 | **20681** (frozen literal, `[Brandt Wt!B41]`) | **Settled decision 4.** ★ **The 0.95 factor has NO citation in this repo** — user-supplied; logged open, todo §P4-16. Feeds Eqs. 15.5, 15.6. Fixes a frozen-under-mutation bug: see §E.3 |
| 24b | **`SFC_mission`** | ★ `prop.get_TSFC(AircraftState(cruise_altitude_ft, cruise_mach))` | **1.007116** 1/hr | **0.70** (frozen literal, `[Brandt Main!C30]`) | **Settled decision 2.** `get_TSFC` resolves to the **mil (dry), UNINSTALLED** path at that state; Brandt's own `Consts!` cruise row is `pct_AB = 0`, so the power setting matches. **+43.87 % vs Brandt's 0.70, accepted by decision** — see §D.6. Feeds Eq. 15.16 |

#### Group totals — closes finding #12's five NaN placeholders (5)

| # | Derived | Formula | Value at `W_TO`=31377 *(live)* | `WAS` |
|---|---|---|---|---|
| 25 | `W_wings` | `WeightsL3.weight_wing(obj, requireWTO)` | **2396.77** | `NaN`, never assigned |
| 26 | `W_tail` | `WeightsL3.weight_tail(obj, requireWTO)` → `struct(HT, VT)` | HT **200.5412**, VT **313.06** | `NaN` |
| 27 | `W_fuselage` | `WeightsL3.weight_fuselage(obj, requireWTO)` | **3674.20** | `NaN` |
| 28 | `W_installed_engine` | `WeightsL3.weight_engine_section(obj, obj.W_TO).total` = engine + mounts + firewall + section + induction + tailpipe + cooling + oil + controls + starter | **3381.6984** (`WAS` 3639.26) | `NaN`, never assigned |
| 29 | `W_subsystems` | `WeightsL3.weight_systems(obj, requireWTO).total` | **4578.1340** (`WAS` 4541.46; the +36.67 is `SFC_mission` 0.70 → 1.007116, row 24b) | `NaN` |

★ **`W_subsystems`' documented contract — FIXED.** `WeightsModelL3` previously declared
`W_subsystems  % Includes landing gear`, which was false: `WeightsL3.OEW` adds
`W_lg.main + W_lg.nose` **separately** from `W_sys.total`, and `weight_systems` contains no
landing-gear term. The comment now says so explicitly and records the old wording as wrong.
`TestWeightsL3.testSystemsGroupContainsNoLandingGearTerm` is the guard. todo §P4-10 — **RESOLVED**.

`OEW(W_TO)` stays a **method** per the `WeightsBase` contract; it sums rows 25–29 plus the landing gear.

**Unset-`W_TO` behaviour — as built, and NOT uniform on purpose.** Five getters are guarded by
`requireWTO` because they genuinely carry Raymer's `W_dg` or `W_l`: `W_wings`, `W_tail`, `W_fuselage`,
`W_subsystems` and `W_l`. Reading any of them with `W_TO = NaN` throws `F16WeightsL3:WTONotSet` — the
Phase-1f precedent (`F16GeomL1.requireWTO`): an identified error, never a silent `NaN`.
**`W_installed_engine` is deliberately NOT guarded**: `WeightsL3.weight_engine_section` declares its
second argument as `~`, so the engine group is built from thrust and component geometry and carries no
gross-weight term at all. An earlier Phase-4 revision guarded it anyway; that was withdrawn on the
principle *a guard must encode a real dependency, not a house style*
(`TestWeightsL3.testWTODependentPropertiesErrorWhenWTOUnset`; todo §P4-18).

### B.3 The four quantities Phase 3 deleted — ALL SETTLED (2026-07-25)

Phase 3 removed these from `f16a_L3.json` as Brandt outputs / duplicates, but their consumers still
read them. Every one now has a disposition.

| Property | AS-IS | Consumer | **SETTLED** | Effect *(live)* |
|---|---|---|---|---|
| `W_l` | 20681 `[Brandt Wt!B41]` | Eqs. 15.5, 15.6 | **DERIVED = `0.95 · W_TO`** (decision 4) — §B.2 row 24a | `W_l` = **29808.15** at 31377; LG total 1057.27 → **1160.93** (+9.81 %). ★ 0.95 has **no repo citation** (§P4-16). Live `Wt!B41` = **20680.700578** (`=SUM(B16:B32)`, a back-calculated Brandt output) becomes a **comparison reference only**; 29808.15 is **+44.14 %** above it |
| `V_t` | 940 gal | Eq. 15.16 | **RESTORED as a JSON input** (decision 3) — §B.1 row 27a | none. The 6.7 lb/gal density that produced 940 is cited **nowhere** in the repo; the alternative (`V_t = W_energy/6.7` = 939.746) would substitute an uncited constant for a Brandt-traceable figure. Warning stays open (§P4-5b) |
| `SFC_mission` | 0.70 `[Brandt Main!C30]` | Eq. 15.16 | **DERIVED by DI at the cruise condition** (decision 2) — §B.2 row 24b | **1.007116** 1/hr; fuel system 386.794 → **423.465** (+36.67, +9.48 %). +43.87 % vs Brandt, accepted (§D.6) |
| `W_energy` | 6296.3 | *(nothing reads it)* | stays a **`NaN` state input** set by mission analysis | none. `Wt!B6` = `=B3-B4-B5-B12` *(live)* is a back-calculated output |

For the record, the alternatives that were **not** chosen, all computed live at `W_TO` = 31377 —
kept so the decision trail stays legible:

| Alternative | Value | Resulting component |
|---|---|---|
| `W_l` = `W_TO` | 31377 | LG total 1176.272 |
| `W_l` = `OEW + payload + ½·fuel` | 23828.85 | LG total 1096.299 |
| `W_l` = `Brandt Wt!B41` (AS-IS) | 20680.70 / 20681 | LG total 1057.273 |
| `SFC_mission` = `compute_TSFC_installed` at SLS | 0.975240 | fuel system 420.087 |
| `SFC_mission` = `PropL2.SFC_cruise_AB(0.71)` [Raymer Eq. 10.15] | 0.911340 | fuel system 413.058 |
| `V_t` = `W_energy / 6.7` | 939.746 | fuel system 386.742 (vs 386.794 at 940) |

### B.4 DELETED — two dead inputs

`AR_ht` = 2.114 and `lambda_ht` = 0.390 (formerly `F16WeightsL3.m:63-64`) were **never read by any
`WeightsL3` equation** — verified by grep of `obj.AR_ht` / `obj.lambda_ht` in `src/disciplines/weights/`
2026-07-25: **zero matches**. Raymer Eq. 15.2 takes only `(W_dg, N_z, S_ht, F_w, B_h)`. **Both are
DELETED, not rewired** to `geom.AR_exposed_ht` / `geom.lambda_exposed_ht` — the geometry object still
exposes those two members, and `F16WeightsL3.m` carries an explicit `NOTE:` at the HT getter block
saying why they are not wired. Guard:
`TestWeightsL3.testDeadHTAspectRatioAndTaperAreDeleted`. todo §P4-6 — **RESOLVED**.

(Their property comments already flag the problem obliquely: `B_h = 18.5` is annotated
"supersedes the earlier `sqrt(AR_ht*S_ht)` = 11.61 ft derivation … AR_ht/S_ht above not reconciled".
The reconciliation question dissolves once the unused properties go.)

### B.5 Candidate geometry DI that is NOT locked — user decision required

| Weights symbol | AS-IS | `geom` analog | Analog value *(live)* | Consumer | Effect if wired *(live)* |
|---|---|---|---|---|---|
| `L_d` | 7.5 `[estimate]` | `geom.L_duct` | **14.0** `[Brandt Main!F32, label E32 "Compr Face"]` | Eq. 15.10 | induction **227.54 → 429.01 lbf (+88.5 %)**; OEW +201.47 |
| `D_e` | 3.33 `[estimate]` | `geom.D_exit` (= `D_inlet` = `sqrt(T_AB/1900)`) | **3.537022** | Eqs. 15.10/15.11/15.12 | induction 227.54→241.69, tailpipe 52.45→55.71, cooling 121.21→128.75; OEW +24.94 |

Both are cases where an `[estimate]` currently coexists with a cited geometry quantity of arguably the
same meaning. Wiring them removes two unpinned estimates; not wiring them keeps the L3 weight closer
to its as-tested value. **Not decided here** — todo §P4-4.

---

## C. Methods — all delegate to `WeightsL3`

`OEW` = Σ(wing + HT + VT + fuselage + LG.main + LG.nose + engine-group.total + systems-group.total).

| Method | Low-level static | Eq. | `WeightsL3.m` | Citation (target) | §3a exponent status |
|---|---|---|---|---|---|
| `weight_wing` | `WeightsL3.wing` | 15.1 | :156–175 | `[Raymer 7th ed. Eq. 15.1]` | UNVERIFIED — rows 37–44 |
| `weight_tail`.HT | `WeightsL3.horizontal_tail` | 15.2 | :177–186 | `[Raymer 7th ed. Eq. 15.2]` | UNVERIFIED — rows 45–47 |
| `weight_tail`.VT | `WeightsL3.vertical_tail` | 15.3 | :188–210 | `[Raymer 7th ed. Eq. 15.3]` | **CONFLICT row 2** (`cos(Λ_vt)^−0.323` kept vs extract −1.0) + rows 48–55 |
| `weight_fuselage` | `WeightsL3.fuselage` | 15.4 | :212–224 | `[Raymer 7th ed. Eq. 15.4]` | UNVERIFIED — rows 56–60 |
| `weight_landing_gear`.main | `WeightsL3.main_gear` | 15.5 | :226–236 | `[Raymer 7th ed. Eq. 15.5]` — `L_m` in **inches** (`obj.L_m·12`) | UNVERIFIED — rows 14–15 |
| `weight_landing_gear`.nose | `WeightsL3.nose_gear` | 15.6 | :238–247 | `[Raymer 7th ed. Eq. 15.6]` — `L_n` in **inches** | UNVERIFIED — rows 16–18 |
| `weight_engine_section`.engine | `W_en · N_en` | — | :117 | **not a §15.3.1 equation** — `W_en` comes from `[Raymer 7th ed. Eq. 10.10]`, UNINSTALLED (§B.2 row 23) | n/a |
| `weight_engine_section`.mounts | `WeightsL3.engine_mounts` | 15.7 | :249–255 | `[Raymer 7th ed. Eq. 15.7]` | UNVERIFIED — rows 61–62 |
| `weight_engine_section`.firewall | `WeightsL3.firewall` | 15.8 | :257–262 | `[Raymer 7th ed. Eq. 15.8]` | extract-clean; still in the standing all-equations TO-DO |
| `weight_engine_section`.section | `WeightsL3.engine_section` | 15.9 | :264–270 | `[Raymer 7th ed. Eq. 15.9]` | UNVERIFIED — row 19 |
| `weight_engine_section`.induction | `WeightsL3.air_induction` | 15.10 | :272–281 | `[Raymer 7th ed. Eq. 15.10]` | UNVERIFIED — rows 3–7 (three FROM-CODE) |
| `weight_engine_section`.tailpipe | `WeightsL3.tailpipe` | 15.11 | :283–287 | `[Raymer 7th ed. Eq. 15.11]` | extract-clean |
| `weight_engine_section`.cooling | `WeightsL3.engine_cooling` | 15.12 | :289–293 | `[Raymer 7th ed. Eq. 15.12]` | extract-clean |
| `weight_engine_section`.oil | `WeightsL3.oil_cooling` | 15.13 | :295–299 | `[Raymer 7th ed. Eq. 15.13]` | **CONFLICT row 1** (`N_en^1.023` kept vs extract 1.078) |
| `weight_engine_section`.controls | `WeightsL3.engine_controls` | 15.14 | :305–309 | `[Raymer 7th ed. Eq. 15.14]` | UNVERIFIED — rows 8–9 (both FROM-CODE) |
| `weight_engine_section`.starter | `WeightsL3.starter` | 15.15 | :311–316 | `[Raymer 7th ed. Eq. 15.15]` | UNVERIFIED — rows 20–21 |
| `weight_systems`.fuel_sys | `WeightsL3.fuel_system` | 15.16 | :318–332 | `[Raymer 7th ed. Eq. 15.16]` | UNVERIFIED — rows 22–26 |
| `weight_systems`.flight_ctrl | `WeightsL3.flight_controls` | 15.17 | :334–341 | `[Raymer 7th ed. Eq. 15.17]` | UNVERIFIED — rows 10–13 |
| `weight_systems`.instruments | `WeightsL3.instruments` | 15.18 | :343–349 | `[Raymer 7th ed. Eq. 15.18]` | UNVERIFIED — rows 27–29 |
| `weight_systems`.hydraulics | `WeightsL3.hydraulics` | 15.19 | :351–357 | `[Raymer 7th ed. Eq. 15.19]` | UNVERIFIED — row 30 |
| `weight_systems`.electrical | `WeightsL3.electrical` | 15.20 | :359–366 | `[Raymer 7th ed. Eq. 15.20]` | UNVERIFIED — rows 31–34 |
| `weight_systems`.avionics | `WeightsL3.avionics` | 15.21 | :368–373 | `[Raymer 7th ed. Eq. 15.21]` | UNVERIFIED — row 35 |
| `weight_systems`.furnishings | `WeightsL3.furnishings` | 15.22 | :375–379 | `[Raymer 7th ed. Eq. 15.22]` | extract-clean |
| `weight_systems`.ac_antiice | `WeightsL3.ac_antiice` | 15.23 | :381–386 | `[Raymer 7th ed. Eq. 15.23]` | UNVERIFIED — row 36 |
| `weight_systems`.handling | `WeightsL3.handling_gear` | 15.24 | :388–392 | `[Raymer 7th ed. Eq. 15.24]` | extract-clean |

Units per equation: `W_dg`/`T`/`W_l`/`W_en`/`W_uav` [lbf]; `S_*` [ft²]; `L_fus`/`D_fus`/`W_fus`/`D_e`/
`L_d`/`L_s`/`L_tp`/`L_sh`/`L_ec`/`L_t`/`L_a`/`B_h`/`F_w`/`H_t`/`H_v` [ft]; `L_m`/`L_n` [**inches** at
the equation, converted from ft]; `V_*` [gal]; `SFC` [1/hr]; `R_kva` [kVA]; `M` and all `K_*`/`N_*`
dimensionless. All outputs lbf.

---

## D. Deviations, limitations, standing TO-DOs

### D.1 ★ Unverified §15.3.1 exponents — the standing TO-DO (locked, approach 2)

Full 62-row enumeration: `VnV/BrandtF16A/todo.md` 2026-07-24 Weights §3a. Category summary:

- **CONFLICT (2, code value KEPT):** Eq. 15.13 `N_en^1.023` vs extract 1.078; Eq. 15.3
  `cos(Λ_vt)^−0.323` vs extract −1.0.
- **FROM-CODE (9)** — absent from the repo extract, cited "from `WeightLevel3.m`": Eq. 15.10
  `N_en^1.498`, `(L_s/L_d)^−0.373`, linear `D_e`; Eq. 15.14 `N_en^1.008`, `L_ec^0.222`; Eq. 15.17
  `N_c^0.127`; Eq. 15.5 `L_m^0.973`; Eq. 15.6 `N_nw^0.525`.
- **VERIFY (24)** — present in `raymer_data.md` but OCR-flagged `[verify]`: Eqs. 15.9, 15.10 (2), 15.15
  (2), 15.16 (5), 15.17 (3), 15.18 (3), 15.19, 15.20 (4), 15.21, 15.23, 15.5, 15.6 (2).
- **IMAGE-ONLY (27)** — Eqs. 15.1–15.7; the in-code claim of re-verification against a "Raymer 6th ed.
  p.572 equation image" cannot be checked because that image is **not in the repo**, and the extract
  still marks these `[verify]`.
- **extract-clean (5):** Eqs. 15.8, 15.11, 15.12, 15.22, 15.24 — still inside the standing
  "every equation must be checked against the physical book" obligation.

Two extra Eq. 15.1 uncertainties beyond the `[verify]` tag: (a) `tc_root^(−0.4)` — the low-level
comment (`WeightsL3.m:160-164`) says the superscript "is not legible in the printed page's line-wrap",
so −0.4 was assumed from the "widely-corroborated published form" + `temp_Casey`, not read off the
page; (b) sweep **station** — code uses `cos(Λ_LE)` while the comment (`:60-61`, `:165-166`) flags
"some editions use quarter-chord sweep — verify".

**In-code self-contradiction on Eqs. 15.1 / 15.4 — RESOLVED, on the `[verify]` side.** The high-level
`weight_wing` / `weight_fuselage` comments said "⚠ Exponents `[verify]`" while the low-level `wing` /
`fuselage` comments said "all exponents confirmed". Same equations, opposite claims. The
"confirmed"/"re-verified against the p.572 equation image" wording is **removed** from the header and
from the wing / HT / VT / fuselage / gear / mounts method comments; every one now reads
`⚠ EXPONENTS NOT BOOK-VERIFIED (class header, IMAGE-ONLY rows …)`. **No exponent value changed.**

**Page-citation inconsistency — RESOLVED.** `WeightsL3.m` now cites the **section only**
(`Raymer 7th ed. §15.3.1`) and repeats no page number per method. The former mix of "p.572" (header)
and "p.602" (methods) pointed at the same content by two schemes — `raymer_data.md:115` maps §15.3.1 to
book pp.572–573 = PDF pp.602–603 (PDF = book + 30). todo §3c item 3 — **RESOLVED**.

**Shipped guard: `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified`** — labelled, verified red
2026-07-25, following `TestGeomL3.testTODO_OverallLengthCitationNotPinned` and
`TestAeroL2.testTODO_ClAlpha2DUnverified`. It keys off `WeightsL3.m`'s own standing-TO-DO sentence
(there is no JSON marker key for it), enumerates the CONFLICT + FROM-CODE rows in its docstring, and
states that the values must **not** be changed to make it green.

### D.2 ★ `W_en` — SETTLED: UNINSTALLED at L3

**SETTLED (user, 2026-07-25, decision 1): L3 consumes the UNINSTALLED Eq. 10.10 value, 2775.0210 lbf.
`×1.3` is L2-only.**

**Why: `×1.3` would double-count what §15.3.1 builds up item by item.**
`WeightsL3.weight_engine_section` (`:105-130`) sums the dry engine **plus** mounts (15.7), firewall
(15.8), section (15.9), induction (15.10), tailpipe (15.11), cooling (15.12), oil (15.13), controls
(15.14) and starter (15.15) — and its own docstring says exactly this: *"Raymer §15.3.1 gives the
installation-hardware items … as ADDITIONS on top of the engine's own dry weight."* Raymer's
nomenclature for Eq. 15.9's `W_en` is likewise the engine weight *each* (dry). A single 1.3 factor is a
lumped stand-in for precisely those nine items; applying both counts the installation twice. L2 has no
such buildup, which is why 1.3 is correct **there** and only there.

Live consequence (`W_TO` = 31377, everything else at the §B settled target):

| `W_en` | `.engine` | `.section` (15.9) | sum | L3 `OEW` | vs `Wt!B12` | Status |
|---|---|---|---|---|---|---|
| AS-IS 3030 `[estimate]` | 3030.00 | 42.318 | 3072.32 | 15818.48 | −20.83 % | replaced |
| **Uninstalled 2775.0210** | 2775.02 | 39.733 | **2814.75** | **15705.33** | **−21.40 %** | ★ **SETTLED** |
| Installed 3607.5273 (×1.3) | 3607.53 | 47.957 | 3655.48 | 16546.06 | −17.19 % | **REJECTED** |

**Note explicitly: the settled choice moves L3 FURTHER from Brandt** (−21.40 % vs −17.19 %). The
`×1.3` variant's *better* agreement was **the reason to distrust it**, not a reason to keep it — a
number that agrees because a factor is counted twice is not agreement. Closes §P4-1b.

**And the Brandt alternate gets NO ×1.3 at either level.** `readme_wt.md:230` states verbatim that
`0.199·T_AB` *is* the installed-engine formula, so `W_en_brandt` = **4730.2300** as-is (§B.2 row 24).
The 0.199 literal's cell is now on record: `'Engn(s)'!D22 = 0.199` *(live)*, routed through
`'Engn(s) Old'!D22`, labelled `'Engn(s) Old'!C22` = `"Engine with AB:  Weng = "`. Closes §P4-1a.

### D.3 `N_z` = 13.5 vs Brandt's `n_ult` = 9 — not an error

Raymer §15.3.1's `N_z` is the **ultimate** load factor = 1.5 × 9g limit = 13.5. Brandt's Wt-tab psf
model uses `Main!Q27` = 9 (verified via `Wt!C9`'s live formula, which contains `Main!Q27^0.2`). Two
different models — do not conflate. Already noted in `f16a_L3.json .weights._note`.

### D.4 `K_rht` is applied to Eq. 15.3, not 15.2

`WeightsL3.vertical_tail` takes `K_rht` = 1.047 (rolling/all-moving tail). The in-code comment
(`:193-196`) states this is "exactly as printed/defined in the book, not a mix-up". The JSON keys it
under `.weights.horizontal_tail.K_rht` because the *flag* describes the HT. Keep both facts visible at
the DI site — it reads like a bug otherwise.

### D.5 ★ `K_d` and the other domain guards — SETTLED: NO CHANGE this phase

**SETTLED (user, 2026-07-25, decision 6): leave `K_d` alone. No guard is added. §P4-11 stays OPEN.**

Stated plainly, and not softened: **`K_d = 0` remains a legal input that silently zeroes a 227.54 lbf
component.** `WeightsL3.air_induction` (Eq. 15.10) contains `K_d^0.182`; `WeightsL3.m:276` documents
`K_d = 0` as the legitimate **straight-duct** value; `0^0.182 = 0` (verified live), so the entire
air-induction term evaluates to exactly **0.0000** with no error, no warning, and not even a `NaN` to
notice downstream. L3 `OEW` would read **15477.79** instead of 15705.33 *(live)*.

This is the **same silent-zero class as the Phase-1 defect** in `F16GeomL1`, where a frozen `S_wet = 0`
made `CD0 = Cfe·S_wet/S_ref = 0` and produced an infinite L/D with no warning (finding #9, fixed in
Phase 1f). The difference is that here the zero is reachable through a **documented, legal** input
value rather than an uninitialised one.

**Corollary worth recording:** if `K_d = 0` is legal, then the code's `K_d` **cannot** be Raymer's
`K_d` as a multiplicative base — a straight duct does not weigh nothing. So the term's exponent or
placement is itself suspect. That is `todo §3a` checklist row 7 (`K_d` exponent 0.182, `[VERIFY]`),
inside the standing verify-against-the-book obligation. A guard alone would mask it, which is one
reason not to add one blind.

The other three paths deferred from Phase 1e (`~/.claude/plans/serene-conjuring-kitten.md` §1e last
bullet) are likewise **not** guarded this phase, for scope consistency with decision 6:

| Input | Value | Eq. | Term | Result | Reachability |
|---|---|---|---|---|---|
| `H_v` | 0 | 15.3 | `(1 + H_t/H_v)^0.5` | `H_t = 0` → `0/0` = `NaN`; `H_t > 0` → `Inf` | plausible mis-entry — the property is documented as "any nonzero denominator", i.e. its value is arbitrary and 0 looks harmless |
| `L_s` | 0 | 15.10 | `(L_s/L_d)^(−0.373)` | `Inf` | plausible mis-entry (no splitter) |
| `V_t` | 0 | 15.16 | `V_t^0.47` · `(1+V_i/V_t)^(−0.095)` · `(1+V_p/V_t)` | `0 × Inf` → `NaN` | now only via an explicit JSON `0`, since decision 3 keeps `V_t` a 940 **input** rather than deriving it from a `NaN`-initialised `W_energy` |

If guards are added later, the pattern is Phase 1e's: identified errors at the **public entry points**
(`WeightsL3.weight_tail`, `weight_engine_section`, `weight_systems`), not silent propagation.
**§P4-11 remains OPEN.**

### D.6 ★ `SFC_mission` — SETTLED as a DI, with an accepted +43.87 % divergence

**SETTLED (user, 2026-07-25, decision 2).** `SFC_mission` is a `Dependent` getter evaluating
`prop.get_TSFC(AircraftState(cruise_altitude_ft, cruise_mach))` at the requirements-file cruise point
**36,000 ft / M 0.87** — whatever comes out, no correction, no calibration to Brandt.

| Quantity | Value *(live)* | Note |
|---|---|---|
| `prop.get_TSFC(AircraftState(36000, 0.87))` | **1.007116** 1/hr | the value used. Identical to `prop.compute_TSFC_mil` at that state → `get_TSFC` resolves to the **mil (dry), UNINSTALLED** path |
| `prop.compute_TSFC_installed` at the same state | 1.087685 | = ×1.08, reference only |
| Brandt `Main!C30` | 0.70 | a single **already-installed** SLS structural-sizing constant |
| **Divergence** | **+43.87 %** | **accepted by decision.** Two independent deliberate causes: (a) *condition* — a real cruise point vs Brandt's one stored SLS number; (b) *installation basis* — uninstalled vs installed |

**One consistency point in the framework's favour:** Brandt's own cruise condition (`Consts!` row 24,
via `f16a_ground_truth.json .propulsion.thrust_lapse_at_constraint_conditions`) is `pct_AB = 0`, i.e.
**dry/mil** — and `get_TSFC` resolves to the mil path at that state. The *power setting* therefore
matches Brandt's own cruise definition; only the condition and the installation basis differ.

Eq. 15.16 is weakly sensitive (`((T·SFC)/1000)^0.249`): the fuel system moves 386.794 → **423.465 lbf**
(+9.48 %, **+36.67** on OEW). The *value* barely matters; the *provenance* is now explicit.

> **★ The Phase-3 rationale for deleting this key was FALSE, and is corrected on the record.**
> `f16a_L3.json .weights._not_inputs` claimed *"SFC_mission [Main!C30] duplicates what
> `PropL2.get_TSFC` computes"*, and the Phase-3 commit message said the same. It does not: the two
> differ by **+43.87 %** and no reference condition was ever specified. The correction is carried in
> `F16WeightsL3.m`'s `get.SFC_mission` comment. todo §P4-15 — **corrected on the record; verify the
> JSON note wording at review.**

### D.7 `aircraft_category` at L3 — property ADDED, and the false JSON note CORRECTED

As built, `F16WeightsL3` **does** carry an `aircraft_category` input, read from the JSON's top level.
No `WeightsL3` static reads it, and that is correct **by construction**: `WeightsL3` implements only
Raymer's Fighter/Attack build-up, so there is one path and no category lookup. It is carried for
interface parity with `F16WeightsL1`/`L2` (which *do* key their table lookups off it) and for report
labelling.

`f16a_L3.json .weights._note` previously asserted *"Raymer §15.3.1 exponents/coefficients are
aircraft_category-selected toolbox Constants"* — **false**: every §15.3.1 coefficient (0.0103, 3.316,
0.452, 0.499, …) is a bare literal inside a `WeightsL3` static, with no `switch`, no lookup and no
category key. The note now states the truth and records that the earlier version was wrong.
todo §P4-9 — **RESOLVED (note corrected, not by implementing a lookup).**

### D.8 `WEIGHTSMODELG3` typo — FIXED

The `F16WeightsL3.m` property-block banner used to read `WEIGHTSMODELG3 ABSTRACT PROPERTIES` (G→L).
Gone: the as-built property block carries the input/derived banners instead. Cosmetic.
todo 2026-07-24 §3c item 5 — **RESOLVED**.

### D.9 Many inputs remain unpinned `[estimate]`s — and two settled quantities join them

`L_m`, `L_n`, `N_l`, `D_e`, `L_tp`, `L_sh`, `L_ec`, `L_d`, `L_s`, `V_i`, `V_p`, `N_t`, `N_s`, `N_ci`,
`N_u`, `R_kva`, `L_a`, `W_uav` — 18 of the 42 numeric inputs. Plus the DI'd-but-unpinned `F_w`, `L_t`,
`S_cs` (which are `[estimate]` on `F16GeomL3`, not on weights). These are spec-data gaps, **not**
equation-citation issues, and are separate from the §3a exponent TO-DO. Each should carry its
`[estimate, unpinned]` tag into the JSON `_src` strings.

**Two of the 2026-07-25 settled decisions add uncited constants to this list, deliberately and with
the gap recorded rather than papered over:**

| Constant | Where | Status |
|---|---|---|
| **0.95** in `W_l = 0.95 · W_TO` | §B.2 row 24a, decision 4 | ★ **user-supplied; no citation anywhere in the repo.** Not a Raymer/Roskam/Brandt figure. Grepped 2026-07-25. Logged **OPEN**: todo §P4-16 |
| **6.7 lb/gal** behind `V_t` = 940 | §B.1 row 27a, decision 3 | ★ **cited nowhere in the repo**; the only trace is the `F16WeightsL3.m:125` comment. No JP-4/JP-5/JP-8 density exists anywhere in `sizing/`. This is exactly why `V_t` was **kept as an input** rather than derived — the derivation would put the uncited constant into the equation. todo §P4-5b |

---

## E. Values, computed live 2026-07-25

### E.1 `WAS` (pre-Phase-4) breakdown at `W_TO` = 31,377 lbf

| Group | Component | lbf |
|---|---|---|
| Structural | wing (15.1) | 2396.80 |
| | HT (15.2) | 196.43 |
| | VT (15.3) | 313.06 |
| | fuselage (15.4) | 3674.20 |
| Landing gear | main (15.5) | 903.52 |
| | nose (15.6) | 153.75 |
| Engine group | engine (vendor) | 3030.00 |
| | mounts / firewall / section | 59.98 / 0.00 / 42.32 |
| | induction / tailpipe / cooling | 227.54 / 52.45 / 121.21 |
| | oil / controls / starter | 37.82 / 15.01 / 52.93 |
| | **total** | **3639.26** |
| Systems | fuel_sys / flight_ctrl / instruments | 386.79 / 925.29 / 228.17 |
| | hydraulics / electrical / avionics | 108.39 / 421.99 / 1945.42 |
| | furnishings / ac_antiice / handling | 217.60 / 297.76 / 10.04 |
| | **total** | **4541.46** |
| | **OEW** | **15818.48** |

−20.83 % vs `Wt!B12` = 19980.700578; −17.39 % vs corrections.xls 19148.08.

### E.2 AS-BUILT values and the deltas that produced them — all six decisions applied

As-built basis: `W_en` uninstalled 2775.0210, `W_l` = 0.95·`W_TO`, `V_t` = 940 input,
`SFC_mission` = 1.007116, `design_mach` = 2.0, `K_d` = 1.0 unchanged. Every "AS BUILT" figure below was
recomputed live 2026-07-25 against the shipped classes, not carried over from the target spec.

| Component | `WAS` | **AS BUILT** | Δ | Cause |
|---|---|---|---|---|
| Wing (15.1) | 2396.80 | 2396.77 | −0.03 | `S_w` 196.23 → 196.2261 (geom DI) |
| **HT (15.2)** | 196.43 | **200.5412** | **+4.11 (+2.09 %)** | ★ `S_ht` **49.85 → 51.1486** — geom DI, option-B 18.5 ft span |
| VT (15.3) | 313.06 | 313.06 | −0.002 | `S_vt` geom DI; `M_design` unchanged at 2.0 |
| Fuselage (15.4) | 3674.20 | 3674.20 | 0 | `L_fus`/`D_fus`/`W_fus` values unchanged by DI (only their provenance changes) |
| **LG main (15.5)** | 903.52 | **989.98** | **+86.46** | ★ `W_l` **20681 (frozen) → 0.95·31377 = 29808.15** (decision 4) |
| **LG nose (15.6)** | 153.75 | **170.95** | **+17.20** | same |
| **LG total** | **1057.27** | **1160.9336** | **+103.66 (+9.81 %)** | decision 4 |
| Engine `.engine`+`.section` | 3072.32 | **2814.75** | **−257.57** | ★ `W_en` 3030 → **2775.0210 UNINSTALLED** (decision 1) |
| **Engine group total** | **3639.26** | **3381.6984** | **−257.57** | as above; every other engine item unchanged |
| **Systems `.fuel_sys` (15.16)** | 386.79 | **423.465** | **+36.67 (+9.48 %)** | ★ `SFC_mission` **0.70 → 1.007116** (decision 2); `V_t` = 940 unchanged (decision 3) |
| **Systems group total** | **4541.46** | **4578.1340** | **+36.67** | as above |
| **`OEW(31377)`** | **15818.48** | **15705.3313** | **−113.15** | **−21.40 %** vs `Wt!B12`; **−17.98 %** vs `corrections.xls` |
| **`OEW(45000)`** | **16870.15** | **16869.6310** | **−0.52** | −15.57 % vs `Wt!B12`. ★ The near-zero net at 45,000 lbf is **coincidence** — +215.90 from the now-live LG, −257.57 from `W_en`, +36.67 from SFC, +4.4 from `S_ht`. Do **not** read it as "nothing changed" |
| **`OEW(60000)`** | *(n/a — the frozen-`W_l` code was never quoted here)* | **17930.7085** | — | recomputed live 2026-07-25 for the §E.3 mutation table |

**REJECTED variant, kept so the decision is auditable:** with `W_en` × 1.3 = 3607.5273 the
`OEW(31377)` would be **16546.06**, i.e. **−17.19 %** vs `Wt!B12` — *closer* than the settled
−21.40 %. Per decision 1, that closer agreement is the evidence **against** `×1.3` (§D.2).

Sensitivities for the items **STILL OPEN**, each applied alone on the as-built 15705.3313 *(all live)*.
These are the four rows section 6 of the comparison report carries:

| Still-open item | Choice | `OEW` | Δ | todo |
|---|---|---|---|---|
| `L_d` ← `geom.L_duct` | 7.5 → 14.0 ft | 15906.80 | +201.47 | §P4-4, **OPEN** |
| `D_e` ← `geom.D_exit` | 3.33 → 3.537022 ft | 15730.27 | +24.94 | §P4-4, **OPEN** |
| `design_mach` ← T.O. limit | 2.0 → 2.05 | 15725.41 | +20.08 | §P4-13, **OPEN** (citation, not value) |
| `K_d` = 0 (legal straight duct) | induction 227.54 → **0.0000** | **15477.7874** | **−227.54** | §P4-11, **OPEN — unguarded by decision 6** (§D.5) |

### E.3 ★ §P4-17 — L3's landing gear was frozen under mutation too — **FIXED**

Not among the original 15 review findings; surfaced while quantifying decision 4. Pre-Phase-4 `W_l` =
20681 was a stored constant **and** `WeightsL3.weight_landing_gear` took no `W_TO` argument, so
**`WeightsL3`'s entire landing-gear group was completely insensitive to `W_TO`** — bit-identical at
every gross weight. Both halves are fixed: `W_l` is `Dependent` = `0.95·W_TO`, and
`weight_landing_gear(obj, W_TO)` now takes the weight. Verified live 2026-07-25:

| `W_TO` | `WAS` LG total | **AS-BUILT** LG total (`W_l` = 0.95·`W_TO`) |
|---|---|---|
| 31,377 | 1057.273 | **1160.9336** |
| 45,000 | **1057.273** | **1273.1680** |
| 60,000 | **1057.273** | **1370.4685** |

Same defect class as review finding #5 (`W_all_else_empty` frozen at `0.17·31377` on `F16WeightsL2`),
and the same signature — a Brandt **output** (`Wt!B41` = 20680.700578, `=SUM(B16:B32)`) frozen as an
input — one tier up. Shipped guards: `TestWeightsL3.testLandingGearScalesWithWTO`,
`testLandingGearIsNotTheFrozenValue`, `testLandingGearArgumentWinsOverStaleObjectWTO` and
`testLandingWeightIsDerivedFromWTO`. Logged: todo §P4-17 — **RESOLVED**. The `0.95` factor's missing
citation (§P4-16) remains **OPEN** and is a separate item.

---

## F. Unit tier — as built

**The OEW-vs-Brandt agreement check LEFT the unit tier**, per CLAUDE.md's two-tier rule.
`TestWeightsL3` as shipped: **44 cases, 43 green + 1 labelled deliberate red** (verified 2026-07-25).

| Test | Disposition | Why |
|---|---|---|
| `testOEWWithinBroadBounds` (`expected = 19148` ±40 % cited "[Brandt F-16A.xls, B12]") | **REMOVED** → now a report row against **19,980.70** with 19,148.08 in `Alt` | Finding #14: `Wt!B12` is live-verified **19980.700578**. A ±40 % tolerance on a mis-cited target is not a unit test |
| `testOEWPrintBreakdown` (printed, always passed, hardcoded 19148) | **REMOVED** → its content is the comparison report's per-group rows | A `verifyTrue(true)` diagnostic is not a unit test |
| `testOEWLessThanWTO`, `testOEWGreaterThanZero`, `testOEWAboveSanityMinimum` | KEPT / ADDED | Physical invariants + sanity floor, no external expected |
| `testComponentSanityBounds` | KEPT in bound form, **re-based** | Replaces the five separate `…PositiveAndPlausible` tests. The old docstrings quoted Brandt comparison figures (1852, 199.39, 245.34, 3652, 1066.8) that belong in the report, and the HT bound's rationale cited `S_ht` = 49.85 → now **51.1486**, so the quoted ~196 lbf is now **200.5412** |
| `testEngineWeightsPositive`, `testSystemsWeightsPositive` | KEPT | Non-negativity over every struct field |
| `testIsa*` ×3 | KEPT | Contract/interface |
| `testWingWeightEq151HandComputed`, `testTailWeightsEq152And153HandComputed`, `testFuselageWeightEq154HandComputed`, `testLandingGearEqs155And156HandComputed`, `testEngineInstallationItemsHandComputed`, `testEngineGroupTotalHandComputed`, `testSystemsItemsHandComputed`, `testSystemsGroupTotalHandComputed`, `testOEWHandComputed` | **ADDED** | Per-equation expecteds hand-evaluated in the comment block from the §B inputs — **never** from a ground-truth file, **never** by calling the code under test. This is what replaces the removed OEW gate as the correctness evidence, and it closes the old `TODO (2026-07-22)` about `engine_controls` never being directly tested |
| `testStrutLengthsAreConvertedToInches` | **ADDED** | Locks Raymer's Eqs. 15.5/15.6 nomenclature: `L_m`/`L_n` are ft on the class, **inches** at the equation |
| `testEngineDryWeightIsUninstalledEq1010` | **ADDED** | Decision 1: L3 must consume the **uninstalled** 2775.0210, i.e. **no ×1.3** |
| `testOEWEqualsSumOfItsGroups`, `testOEWScalesWithItsArgument`, `testOEWWorksWithWTOUnset` | **ADDED** | Internal-consistency identity + `OEW` is a pure function of its argument |
| ★ `testLandingGearScalesWithWTO`, `testLandingGearIsNotTheFrozenValue`, `testLandingGearArgumentWinsOverStaleObjectWTO`, `testLandingWeightIsDerivedFromWTO` | **ADDED — the §P4-17 regression guards** | `W_l` = 0.95·`W_TO` makes the LG group track `W_TO`. Hand-computed at 45,000: `W_l` = 42750, `main` = `1.0·1.0·(42750·2.67)^0.25·66^0.973`, `nose` = `(42750·2.67)^0.290·42^0.5·1^0.525` — evaluated in the comment block from the equations, **not** by calling the code. Before the fix the LG total was 1057.273 at *every* `W_TO` |
| `testSFCMissionIsDIAtCruiseCondition` | **ADDED** | `w3.SFC_mission == prop.get_TSFC(AircraftState(36000, 0.87))` — an identity against the injected object that must **change** when the cruise condition is mutated. It deliberately does **not** assert 1.007116 as a literal, which would freeze a propulsion output into a weights test |
| `testJSONInputsAreActuallyRead`, `testRequirementsAreReadFromTheRequirementsFile` | **ADDED** | The finding-#11 guards: the `.weights` block is no longer dead, and `design_mach`/cruise come from the requirements file, not `.weights` |
| `testPropulsionDIReplacesFrozenThrust` | **ADDED** | `T_max` tracks `prop.T_SL` rather than a frozen 23770 |
| `testAllThirtyOneDependentPropertiesExist`, `testNoDependentPropertyIsNonFinite` | **ADDED** | Finding-#12 guards, and they pin the derived **count** at 31 |
| `testDerivedPropertiesAreReadOnly` | **ADDED** | Assigning to any of the **31** `Dependent` properties must error — mirrors `TestGeomL3.testFormerlyFrozenPropertiesAreReadOnly` |
| `testDerivedLiveRecomputeOnMutation` | **ADDED** | `geom` ↑ → `S_ht` (exposed) and `W_tail.HT` move; `prop.T_SL` ↑ → `T_max`, `W_en` and the mounts/starter terms all move. The finding-#11 regression guard |
| `testNameTrapExposedVsFullTailAreas`, `testNameTrapExposedVsFullVTPlanformShape`, `testNameTrapFuselageDepthVsEquivalentDiameter` | **ADDED** | `w3.D_fus == geom.H_max_fuselage` (5.0) and `~= geom.D_fus` (6.0); `w3.S_ht == geom.S_exposed_ht` and `~= geom.S_ht`; same for VT AR/taper. Locks the §B.2 traps against a future rewiring |
| `testDeadHTAspectRatioAndTaperAreDeleted` | **ADDED** | §B.4: `AR_ht`/`lambda_ht` must stay gone, not get quietly rewired |
| `testSystemsGroupContainsNoLandingGearTerm` | **ADDED** | §P4-10: the `W_subsystems` contract is now true and stays true |
| `testConstructorRequiresAllFourArguments`, `testWrongGeomTierErrorsAtConstruction` | **ADDED** | No silent default; passing an `F16GeomL2` must throw at construction |
| `testWTODependentPropertiesErrorWhenWTOUnset` | **ADDED** | The five genuinely `W_dg`/`W_l`-dependent getters must throw `F16WeightsL3:WTONotSet`, not return `NaN` — and `W_installed_engine` must **not** be guarded (§B.2) |
| ★ `testTODO_Raymer1531ExponentsNotBookVerified` | **ADDED — labelled deliberate RED** | §D.1. Stays red while todo §3a is open |
| ~~domain-guard tests~~ | **NOT ADDED, deliberately** | Decision 6 leaves `K_d`/`H_v`/`L_s`/`V_t` unguarded. **No guard tests were added for behaviour that is not guarded** — that would create a false green. §P4-11 stays **OPEN**, and §D.5 is the record |

The stale header reference block is fixed: `TestWeightsL3.m` no longer states
`[Brandt] OEW = 19,148 lbf [Brandt F-16A.xls, sheet "Wt", B12]`.

---

## G. Cross-references

- **Comparison-report documentation: `examples/F16A/F16WeightsL2.md` §G**; artefacts
  `examples/F16A/weights_brandt_comparison.{m,json,md}`.
- Step-level as-built summary: `docs/subplans/05_weights.md`.
- `docs/weights_parameter_usage.md` — full parameter → consumer → source tables, both DI maps, and the
  live Brandt cell/formula reads.
- `examples/F16A/F16GeomL3.md` §A — the complete `F16GeomL3` input/derived table (the injection
  target); §A.4 for why `S_exposed_ht` = 51.1486; §B for the exposed-vs-FULL rename.
- `VnV/BrandtF16A/todo.md` — 2026-07-24 Weights §3a (the 62-row exponent checklist), §3b, §3c;
  2026-07-24 GeomL3 §5 (the name traps); 2026-07-25 Phase 4 §P4-0 … §P4-17 plus the 2026-07-25 step-2d
  as-built re-status and its new items §P4-18 … §P4-22.
