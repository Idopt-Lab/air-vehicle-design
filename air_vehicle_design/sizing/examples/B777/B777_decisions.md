# B777 example — decisions for the user gate

Three choices need user input before the JSON and code phases start. Each has a recommendation and
its rationale. Companion docs: `inputs/b777_L1.md` (spec), `inputs/b777_requirements.md`
(requirements). Ground-truth source: `docs/reference_extracts/metabook_data.md` worked Example 4.2.

---

## D5 — thrust-lapse exponent `m` for `B777PropL1.thrust_lapse`

**The conflict.** The metabook Example 4.2 uses `alpha = sigma^0.6` (Eqs. 4.55–4.57), the generic
Eq. 10.9 fit with `m = 0.6`, and gives no engine-type justification. The metabook's OWN GE90
Table 10.1 data (the real 777 engine, high BPR) fits `m ≈ 1.0–1.1`:
- climb thrust M 0.6, 10,000 → 40,000 ft: T ratio 13,699/42,091 = 0.326, ISA sigma ratio 0.333 → m ≈ 1.02.
- climb thrust M 0.7, 20,000 → 40,000 ft: m ≈ 1.07.

So `sigma^0.6` UNDER-predicts the lapse (optimistic thrust at altitude) for the 777 class. At
40,000 ft: `0.2846^0.6 = 0.470` (printed) vs `0.2462^0.6 = 0.431` (ISA sigma, m = 0.6) vs
`0.246` (m = 1, GE90-like). Full numbers in `metabook_data.md` D5.

**What is fixed regardless.** The comparison report evaluates the printed Eqs. 4.56/4.57 with the
PRINTED off-ISA density ratios (0.2846, 0.2331) for parity with the worked example. That choice is
independent of `m`. The `m` decision only affects what `B777PropL1.thrust_lapse` MODELS.

**Recommendation: `m = 0.6`, as a cited JSON input (`lapse_exponent_m`).**
- Rationale: the B777 example exists to reproduce the metabook Example 4.2 method. Using the
  method's own exponent keeps the framework model consistent with the worked example it mirrors.
  `m = 0.6` is the value `PropL1.lookup_lapse_exponent` already returns for `high_bypass_turbofan`,
  so no toolbox change is needed.
- Making `m` a cited JSON input either way means the choice is explicit and one edit switches it. If
  the user prefers realism over method-parity, set `m = 1.0` (GE90 fit) — cite it to the metabook
  Table 10.1 GE90 empirical fit (D5), and expect the constraint-diagram thrust demand at altitude to
  rise relative to the printed example.

**User choice needed:** `m = 0.6` (metabook method, recommended) or `m ≈ 1.0` (GE90 fit, realistic).

---

## D2/D1-linked — config-CLmax basis (which CLmax the config table carries)

**The conflict.** A single config-table CLmax cannot reproduce BOTH printed equation families:
- The takeoff FIELD-LENGTH equation (Eq. 4.48) uses `CLmax_TO = 2.0` [Roskam Table 3.1, p. 45].
- The takeoff-config CLIMB equations (Eqs. 4.49–4.51) use `CLmax = 2.2` (discrepancy D1, RESOLVED
  in favour of the printed 2.2 for parity).

`TakeoffFieldLengthConstraint` and `ClimbGradientConstraint` BOTH read the SAME
`takeoff_flaps_gear_up` / `takeoff_flaps_gear_down` config CLmax through `aero.get_config_polar`. So
whichever CLmax the config carries, one of the two printed families will not match exactly.

**Options.**
- **(A) Config table carries the physical CLmax (2.0 TO / 2.6 landing).** Then
  `TakeoffFieldLength` / `LandingFieldLength` reproduce Eqs. 4.48 / 4.46 exactly. The climb rows then
  read CLmax = 2.0, so their T/W differs from the printed Eqs. 4.49–4.51 (which used 2.2) by roughly
  the `(2.2/2.0)`-type factor in the induced/zero-lift split. The comparison report annotates that
  gap as D1.
- **(B) Takeoff-flap config CLmax set to 2.2.** Then the climb Eqs. 4.49–4.51 reproduce exactly, but
  `TakeoffFieldLength` reads CLmax = 2.2 and its T/W differs from the printed Eq. 4.48 (which used
  2.0). The comparison report annotates that gap instead.

**Recommendation: Option (A) — config table carries the physical CLmax (2.0 TO / 2.6 landing).**
- Rationale: the physical CLmax values (2.0 / 2.6) are the primary-source Roskam Table 3.1 numbers
  and are what the FIELD-LENGTH equations, the more design-driving constraints, actually use. The
  2.2 in Eqs. 4.49–4.51 is an unexplained metabook-internal value (D1) that matches none of the
  p. 45 assumptions. Carrying the cited physical CLmax and annotating the climb-row gap as D1 keeps
  the aero data honest to the primary source, while the comparison report still shows exactly where
  and why the climb rows differ from the printed equations.
- The comparison report will annotate the six climb rows: "climb CLmax = 2.0 (physical, Roskam
  Table 3.1); printed Eqs. 4.49–4.51 used 2.2 (D1) — T/W differs by the CLmax ratio, BY DESIGN."
- D2 (Eq. 4.49 gear-up CD0 for a gear-down FAR segment): handled in the config CD0 data — Climb 1
  uses the `takeoff_flaps_gear_up` config (CD0 = 0.03597), reproducing the printed gear-up CD0 for
  parity, annotated D2. This is the disposition already recorded (Sarojini 2026-08-13); it is not
  re-opened here.

**User choice needed:** confirm Option (A) (recommended), or choose Option (B).

---

## TODO-row approach — confirm the repo-policy stand-in convention

Every uncited value is carried as a stand-in with an explicit `_TODO` marker naming the primary
source needed (the same convention as the F-16A JSONs' `_TODO_*` keys and
`TestWeightsL1.testTODO_*` guards). The full list:

| Value | File | Stand-in | Primary source needed |
|---|---|---|---|
| `L_fus` | b777_L1 (geometry) | 209 ft | Boeing 777-200LR length (type / Airport Planning doc) |
| GE90-110B per-engine rating | b777_L1 (prop / weights) | 110,000 lbf | GE / Boeing engine rating document |
| `W_payload` | b777_L1 (weights) | ~100,000 lb (order) | 777-200LR payload-range chart |
| `design_range_nmi` / cruise range | b777_requirements | 8,555 nmi | 777-200LR payload-range chart |
| ceiling `mach` | b777_requirements | 0.84 (cruise Mach) | a ceiling Mach, or accept the cruise-Mach recommendation |
| `wing_taper` (if MAC-from-taper needed) | b777_L1 (geometry) | not carried | recommend `cbar = S/b` instead — no taper needed |

**Recommendation: accept the stand-in + `_TODO` convention.** It matches CLAUDE.md's citation-gap
policy and the existing F-16A `_TODO_*` idiom: a traceable stand-in ships now, the `_TODO` key names
exactly what document would close it, and the value is removed/pinned when the professor supplies the
primary source. No fabricated precise values are carried.

**User choice needed:** confirm the stand-in + `_TODO` approach is acceptable for these six items.

---

## Two implementation-phase code changes flagged (not gate decisions, but user should know)

These are not choices — they are code additions the implement phase MUST make, recorded so the
coordinator can surface them:

1. **`TailL1` needs a `jet_transport` row.** `TailL1.lookup_tail_volume_coeffs` implements only the
   `jet_fighter` row and errors otherwise. A `jet_transport` row (`c_HT = 1.0`, `c_VT = 0.09`,
   [metabook Eqs. 8.1/8.2]) must be added before the B777 can size a tail through that toolbox.
   (Not exercised by Example 4.2's own sizing.)
2. **A transport fixed-fraction `MissionEquations` row does not exist yet.** The transport profile
   (Raymer Table 3.4 historical fractions + one Breguet cruise + Eq. 2.17 reserve) is not a current
   `MissionEquations` entry. It must be added before the B777 `long_range` mission runs.

No `VnV/BrandtF16A/todo.md` entries were logged for this pass — the B777 example is metabook-sourced,
not Brandt-sourced, so the Brandt-internal-discrepancy rule does not apply. The metabook-internal
discrepancies (D1, D2, D3, D5) are already logged in `metabook_data.md` "Known discrepancies" with
user dispositions; this pass only consumes those dispositions, it does not add to them.

---

## D10 (2026-08-17) — toolbox-source the derivable L1 aero inputs

**Problem.** `b777_L1.json` `.aerodynamics` HARDCODES values the shared aero toolboxes can already
compute: `Cfe = 0.0026`, `e_clean = 0.85`, and the entire six-row `config_polars` table (CD0 / K1 /
CLmax per config). This diverges from the F-16 convention: `F16AeroL1` hardcodes NO per-config number
— it looks every ΔCD0 / e / CLmax up from `AeroL1.Delta_CD0` (Roskam Table 3.6) and
`AeroL1.CLmax_table` (Roskam Table 3.1) through its private `roskam_*` helpers. The B777's hardcoded
table is redundant with, and can drift from, those same toolbox Constants.

**Resolution.** Route the derivable quantities through the shared toolboxes; `B777AeroL1` gains
private lookup helpers mirroring `F16AeroL1`'s `roskam_*`. NO edit to `AeroL1.m` / `AeroL2.m` — both
are read-only shared toolboxes; the B777 reads the SAME `AeroL1.Delta_CD0` Constant and the SAME
`AeroL2.lookup_Cfe` / `AeroL2.CD0_from_Cf` statics.

| Quantity | Was (JSON hardcode) | Now (derived) | Citation |
|---|---|---|---|
| `Cfe` | 0.0026 | `AeroL2.lookup_Cfe("civil_transport")` | [Raymer Table 12.3] |
| `e_clean` + per-config e | 0.85 / 0.80 / 0.75 (via K1 rows) | UPPER bound of `AeroL1.Delta_CD0` e_osw column | [Roskam Table 3.6] |
| per-config ΔCD0 | config_polars CD0 − clean CD0 | UPPER bound of `AeroL1.Delta_CD0` ΔCD0 column, 6→4 map | [Roskam Table 3.6] |
| clean CD0 | 0.01597 (stored) | `AeroL2.CD0_from_Cf(Cfe, S_wet, S_ref)` live | [metabook Eq. 4.8 = Raymer Eq. 12.23] |
| per-config CLmax | config_polars CLmax | the three `CLmax_*` overrides; approach = 0.85·landing | [Roskam Table 3.1] — USER |

**The ONE design choice = UPPER bound of the Roskam Table 3.6 ranges.** `AeroL1.Delta_CD0` gives ΔCD0
and e_osw as ranges. `F16AeroL1` reads the MEAN of each range; `B777AeroL1` reads the UPPER bound
(metabook Example 4.2 convention). Both aircraft read the SAME toolbox Constant — the difference is
the statistic B777's private helpers take, not a new table. Upper bounds: clean e = 0.85; takeoff
ΔCD0 = 0.020 & e = 0.80; landing ΔCD0 = 0.075 & e = 0.75; gear ΔCD0 = 0.025. The 6→4 config map (six
constraint configs onto four Roskam rows) adds the `landing_gear` upper bound (0.025) onto the flap
row for gear-down configs; approach is the metabook Climb-6 mean of the two gear-down rows.

**The `jet_transport → civil_transport` Cfe translation.** The canonical top-level
`aircraft_category` is `jet_transport`, but `AeroL2.lookup_Cfe` prints its Raymer Table 12.3 row as
`civil_transport`. `B777AeroL1` translates the canonical key to that row name (mirroring
`AeroL1.to_CLmax_table_row`'s `jet_fighter → fighter`). Do NOT rename the table row — the row name is
what Raymer Table 12.3 prints.

**What STAYS an input.** The three physical CLmax values (`CLmax_clean = 0.9`, `CLmax_takeoff = 2.0`,
`CLmax_landing = 2.6`) are a USER decision (2026-08-14) that deliberately deviates from the Roskam
`transport_jet` table row, so they REMAIN genuine JSON inputs — the only surviving aero inputs.
Approach CLmax derives as 0.85·`CLmax_landing`. These three keys already exist in the JSON but were
read by no code; D10 makes them the live CLmax-override inputs.

**Dead keys removed by the io phase.**
- `aerodynamics.Cfe`, `aerodynamics.e_clean`, `aerodynamics.config_polars` (all now derived).
- `propulsion.T_per_engine` (read by no `.m` file — grep-verified).
- `weights.W0_baseline`, `weights.S_baseline`, `weights.T_baseline_per_engine` (deleted-`B777WeightsL1`
  delta-model inputs, read by no `.m` file — grep-verified).

**Residual concern (flagged, not smoothed).** The derived K1 differs from the removed `config_polars.K1`
rows in the 4th–5th decimal: clean 0.03821 vs 0.03815, takeoff 0.04060 vs 0.04054, landing 0.04331 vs
0.04324. Cause: the derived path uses the EXACT Table 3.6 upper-bound e (0.85 / 0.80 / 0.75); the
removed rows used the metabook's rounded-up "e implied" (0.8515 / 0.8013 / 0.7513). The derived
0.03821 is what the current `e_clean = 0.85` input ALREADY yields through `drag_polar` (documented in
the class header), while `config_polars.clean.K1 = 0.03815` disagrees with that same input — so D10
removes a PRE-EXISTING JSON inconsistency rather than introducing one. The shift is ≈ +0.16 % on K1,
well inside the L1 constraint tolerances. CD0 reproduces exactly. Cross-reference: `inputs/b777_L1.md`
§3 (esp. §3.1 as-built table and §3.5 K1 residual), `models/disciplines/aero/B777AeroL1.md` §2/§4.
