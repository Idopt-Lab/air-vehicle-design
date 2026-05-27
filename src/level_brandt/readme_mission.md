# BrandtMission — Mission Analysis Documentation

## Overview

`BrandtMission` reimplements the **Miss tab** of `Brandt-F16-A.xls` in MATLAB.
It computes per-segment fuel burn, time, and distance for a 14-segment F-16A
mission profile, producing three primary summary targets:

| Output              | Excel cell | Value       |
|---------------------|------------|-------------|
| Total fuel burn     | Miss!O9    | 6000.43 lb  |
| Total mission time  | Miss!O8    | 94.06 min   |
| Landing ground roll | Miss!O6    | 2884.95 ft  |

Ground truth is `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`.

---

## Architecture

`BrandtMission` is a MATLAB handle class that depends on three upstream objects:

```
BrandtGeometry  ──►  BrandtAerodynamics  ──►  BrandtMission
BrandtEngine    ──────────────────────────────►
```

All three must have `compute()` called before constructing `BrandtMission`.

`W_TO_lb` is now a **required parameter of `compute()`** (not read from JSON).
This supports the sizing loop: call `miss.compute(W_TO_lb)` with successive weight
guesses without rebuilding the object.

---

## Usage

```matlab
geom = BrandtGeometry();  geom.compute();
aero = BrandtAerodynamics(geom);  aero.compute();
eng  = BrandtEngine();             eng.compute();
miss = BrandtMission(aero, eng, geom);
miss.compute(31377.0);   % W_TO_lb [lb] — required, from sizing loop
miss.displayMissionTable();
```

Key outputs after `compute()`:

| Property          | Description                          |
|-------------------|--------------------------------------|
| `total_fuel_lb`   | Sum of fuel for segments 1–13 [lb]   |
| `total_time_min`  | Sum of time for segments 1–13 [min]  |
| `landing_dist_ft` | Landing ground roll [ft]             |
| `fuel_lb(i)`      | Fuel burned in segment i [lb]        |
| `time_min(i)`     | Time in segment i [min]              |
| `dist_nm(i)`      | Distance in segment i [nmi]          |
| `W_Wto(i)`        | W/W_TO weight fraction after seg i   |
| `dW_Wto(i)`       | ΔW/W_TO fuel fraction for seg i      |

---

## Mission Segment Sequence

Segments 1–13 consume fuel; segment 14 (Landing) computes ground roll only.

| # | Name     | h (ft) | Mach  | %AB | CDx   | Given dist/time      |
|---|----------|--------|-------|-----|-------|----------------------|
| 1 | Takeoff  | 0      | 0.282 | 100 | 0.035 | —                    |
| 2 | Accel    | 10000  | 0.87  | 0   | 0.010 | — (Ps-based time)    |
| 3 | Climb    | 40000  | 0.87  | 0   | 0.010 | — (Ps-based time)    |
| 4 | Cruise   | 40000  | 0.87  | 0   | 0.010 | 190.8 nm             |
| 5 | Patrol   | 40000  | 0.87  | 0   | 0.010 | 0 min                |
| 6 | Dash     | 40000  | 0.87  | 50  | 0.010 | 50 nm                |
| 7 | Patrol2  | 40000  | 0.87  | 0   | 0.010 | 0 min                |
| 8 | Combat   | 25000  | 0.87  | 50  | 0.010 | 2 min                |
| 9 | Egress   | 40000  | 0.87  | 0   | 0     | 50 nm                |
|10 | Patrol3  | 40000  | 0.87  | 0   | 0     | 0 min                |
|11 | Climb2   | 40000  | 0.87  | 0   | 0     | 0 min (same cond.)   |
|12 | Cruise2  | 40000  | 0.87  | 0   | 0     | 250 nm               |
|13 | Loiter   | 10000  | 0.30  | 0   | 0     | 20 min               |
|14 | Landing  | 0      | 0     | 0   | 0     | — (distance only)    |

Combat segment also drops 4400 lb payload (Miss!I10).

---

## Calculation Flow (ASCII Flowchart)

```
JSON Inputs (segment_names, altitude_ft, mach_end, pct_AB, CDx,
             dist_nm_given, time_min_given, drop_payload_lb)
     │
     ▼
compute(W_TO_lb)                      ← W_TO_lb from sizing loop
     │
     ├─── W/S = W_TO_lb / S_ref       (from BrandtGeometry)
     ├─── T/W = T_sl_AB / W_TO_lb    (from BrandtEngine)
     │
     ▼ (loop over 14 segments)
     │
     ├─ ISA atmosphere(h, M) ────────→ θ, δ₀, ρ, V, q
     ├─ TSFC_old(h, M, %AB) ─────────→ cT  (Old model: sqrt(θ) lapse)
     ├─ thrust_lapse(h, M, %AB) ─────→ α   (New model: δ₀×(1-0.3M-corr))
     ├─ BrandtAerodynamics.aero_at_mach(M) + CDx → CDo, k1, k2
     │
     ├─ Segment type?
     │   ├─ Takeoff   → ground-roll + warmup + start fuel
     │   ├─ Accel     → α×TW×cT×t (time from Ps)
     │   ├─ Combat    → (cT×T_avail×t + drop) / W_TO
     │   ├─ Landing   → landing ground roll distance only
     │   └─ Generic   → drag fuel + energy fuel + drop
     │       └─ Time? → given_time / given_dist / Ps-based
     │
     ├─── fuel_lb(i) = dW × W_TO_lb - drop_lb(i)
     ├─── W_frac -= dW
     └─── W_Wto(i) = W_frac

     ▼ (after all segments)
     total_fuel_lb  = sum(fuel_lb(1:13))     ← Miss!O9
     total_time_min = sum(time_min(1:13))    ← Miss!O8
     landing_dist_ft = landingDist_(...)     ← Miss!O6
```

---

## Engine Model (TSFC)

### "Old" Model — used in Miss tab (Miss rows 34–35)

The Miss tab uses the **Old TSFC formula** (labelled "Engn(s) Old" in Excel):

```
θ        = T_ISA(h) / 518.69          (static temperature ratio, Rankine)
install  = 1.08                        (Miss!C25 = Main!C25)

cT_dry = install × TSFC_sl_dry × (1 + 0.35 × |M|)     × sqrt(θ)
cT_AB  = install × TSFC_sl_AB  × (1 + 0.35 × |M-0.4|) × sqrt(θ)
cT     = cT_dry + (%AB/100) × (cT_AB - cT_dry)
```

Implemented in `BrandtMission.tsfc_old_()`.

### Why it differs from BrandtEngine

`BrandtEngine` uses the **New model** (more physically accurate):

```
cT_new = install × TSFC_sl × (1 + 0.35 × |M|) × (θ / δ₀)^0.5   [approximate]
```

The Miss tab intentionally uses the Old model to match the Excel ground-truth
cell formulas. `BrandtMission` replicates the Old model to achieve 1%
agreement on fuel totals.

### TSFC Averaging Rule

**Only Ps-based climb segments** average TSFC between start and end conditions.
Detection: `is_ps_climb = isnan(given_time) && isnan(given_dist)`

All other segments (including altitude-changing legs like Egress) use
**end-conditions TSFC only**. This matches the Excel Miss tab pattern where
only columns D and L (Climb / Climb2) show the averaged formula `(D34+C34)/2`.

---

## Thrust Lapse Model

Miss tab rows 41–42 use the **New model** (same as `BrandtEngine`):

```
TR         = 1                        (throttle ratio)
δ₀         = P_ISA(h) / P_SL         (static pressure ratio)
θ₀         = T_ISA(h) / T_SL         (static temperature ratio)

α_dry_norm = (T_sl_dry/T_sl_AB) × δ₀ × (1 − 0.3M − max(0, 1.7(θ₀−TR)/θ₀))
α_AB_norm  =                      δ₀ × (1 − 0.1√M − max(0, 2.2(θ₀−TR)/θ₀))
α_norm     = α_dry_norm + (%AB/100) × (α_AB_norm − α_dry_norm)
```

There is **no discrepancy** between `BrandtMission` and `BrandtEngine` for
thrust lapse; both use the New model.

---

## Fuel Formulas by Segment Type

### Takeoff (Miss!B13)

```
V_stall_TO = sqrt(2 × W/S / ρ_SL / CLmax_TO)

dW/W_TO = 1.2 × cT_AB / (g × 3600) × V_stall_TO   [ground-roll fuel]
        + TW × cT_dry_SLS / 60                       [1-min warmup at dry power]
        + 1000 × n_eng / W_TO                        [fixed start fuel per engine]
```

Ground-roll distance (Miss!B7):

```
d_ft = (W/S) / TW × liftoff_factor² / ρ_SL / CLmax_TO / g
       / (1 − CD_roll − μ_roll/TW)
CD_roll = (CDo_TO + CDx_TO)/2 × ρ_SL × (0.7 × V_liftoff)² / (W/S) / TW
```

### Accel (Miss!C13)

```
dW/W_TO = α × TW × cT_end × t_min / 60
```

Time from Ps (same as Climb). Uses special `q_accel_43` dynamic pressure
`= ρ_10000/2 × ((V_accel + V_liftoff)/2)²` (Miss!C43 = 344.0 psf), NOT the
standard `ρ × V²/2 = 770.7 psf` (which overcounts by ~2.24×).

### Generic — Climb, Cruise, Dash, Egress, Loiter, Cruise2, Patrol, Climb2 (Miss row 13)

```
dW/W_TO = cT/60 × q_avg × (CDo_avg/WS + k1_avg×(Wf/q_avg)²×WS
                                        + k2_avg×Wf/q_avg) × t_min    [drag fuel]
        + cT/3600 × Wf × (Δh×2/(V_s+V_e) + ΔV/g)                    [energy fuel, climbs]
        + drop_lb / W_TO                                                [payload drop]
```

where:
- `Wf` = weight fraction at **start** of segment (Miss!L13 uses L12)
- `CDo_avg`, `k1_avg`, `k2_avg` = average of previous-segment-end and current-segment-end aerodynamics
- `q_avg = (q_start + q_end) / 2`
- Energy term applied only when `alt_start ≠ alt_end` or `V_start ≠ V_end`

### Combat (Miss!I9, I13)

```
T_avail      = T_sl_AB × n_eng × α_AB_norm(h, M, %AB)
fuel_burn_lb = t_min/60 × cT_combat × T_avail
dW/W_TO      = (fuel_burn_lb + drop_lb) / W_TO
```

### Landing (no fuel, Miss!O6)

```
W_ref  = W_TO × W_frac_after_takeoff     (uses Miss!B12)
numer  = approach_factor² × W_ref²
denom  = ρ_SL × S × CLmax_land × g
         × (CDo_TO × W_frac_after_TO × W_TO × 0.83/CLmax_TO
            + μ_braking × W_TO × W_frac_after_TO)
d_land = numer / denom
```

where `approach_factor = 1.3`, `μ_braking = 0.5`.
Note: uses weight fraction **after takeoff** (B12), not current landing weight.

---

## Specific Excess Power (Ps) Calculation

Used for Ps-based climb time (Miss row 45 → row 44 → row 8 for Climb / Accel).

### Ps (Miss row 45)

```
dc_end   = CDo_end/WS + k1_end×(Wf/q_end)²×WS + k2_end×Wf/q_end
dc_start = CDo_start/WS + k1_start×(Wf/q_start)²×WS + k2_start×Wf/q_start

Ps_end   = V_end   × (α_end/Wf   × TW − q_end   × dc_end)
Ps_start = V_start × (α_start_mixed/Wf × TW − q_start × dc_start)
Ps       = (Ps_end + Ps_start) / 2
```

`α_start_mixed` uses **end-segment %AB** evaluated at start conditions
(matches Miss!D45: "D40 = alpha at start cond with D's %AB").

### Time from Ps (Miss!D8)

```
dV/dt = 32.2 × Ps / V_avg × 2      (linear velocity ramp approximation)
t     = |Δh / Ps / 60| + |ΔV / (dV/dt) / 60|
```

---

## Known Discrepancies from Excel Ground Truth

### 1. S_wet / CDmin (most significant)

| Source | S_wet_total (ft²) | CDmin_sub |
|--------|--------------------|-----------|
| Code   | 1332.69            | 0.01644   |
| Excel  | 1371.09            | 0.01691   |
| Delta  | −2.8%              | −2.8%     |

**Root cause**: Excel `Geom!B19` double-counts the strake chine term (cell K21
is added twice in the wetted area summation). Documented in `readme_geom.md`.
The code's value (1332.69 ft²) is the **correct** one.

**Impact on mission**: The 2.8% lower CDmin reduces drag, resulting in slightly
less fuel for cruise/climb/egress segments:

| Segment | Excel GT (lb) | Code (lb) | Deviation |
|---------|---------------|-----------|-----------|
| Climb   | 449.1         | ~444.3    | −1.06%    |
| Egress  | 304.6         | ~300.9    | −1.21%    |
| Cruise2 | 789.4         | ~777.5    | −1.50%    |

These three segments use 2% tolerance in the test suite. All other segments
pass at 1%. Consistent with FR-003 (±5% acceptable for known Excel errors).

### 2. TSFC Model (Old vs New)

| Context         | Model | Formula                              |
|-----------------|-------|--------------------------------------|
| BrandtMission   | Old   | `TSFC_sl × (1+0.35M) × sqrt(θ)`     |
| BrandtEngine    | New   | `TSFC_sl × (1+0.35M) × (θ/δ₀)^0.5` |

`BrandtMission` deliberately uses the Old model to replicate the Miss tab.
No discrepancy here — this is intentional.

### 3. Thrust Lapse

Both Miss tab and `BrandtEngine` use the same New model. **No discrepancy.**

---

## Validation Summary

| Target             | Excel GT    | Code        | % Dev  | Tolerance | Status |
|--------------------|-------------|-------------|--------|-----------|--------|
| Total fuel (lb)    | 6000.43     | ~6000       | ~0%    | 1%        | PASS   |
| Total time (min)   | 94.06       | ~94.1       | ~0%    | 1%        | PASS   |
| Landing dist (ft)  | 2884.95     | ~2885       | ~0%    | 1%        | PASS   |
| Final W/Wto        | 0.6685      | ~0.669      | ~0%    | 1%        | PASS   |
| Climb fuel (lb)    | 449.1       | ~444.3      | −1.06% | 2%*       | PASS*  |
| Egress fuel (lb)   | 304.6       | ~300.9      | −1.21% | 2%*       | PASS*  |
| Cruise2 fuel (lb)  | 789.4       | ~777.5      | −1.50% | 2%*       | PASS*  |

\* 2% tolerance applied; deviation traces to known Excel S_wet double-counting error.

Test suite: `src/level_brandt/tests/test_BrandtMission.m` — 43 checks total
(4 summary + 13 fuel + 13 time + 13 weight fractions).

Run: `results = runtests('src/level_brandt/tests/test_BrandtMission.m')`

---

## Cell References

Key Excel cells in the Miss tab:

| Cell     | Description                              |
|----------|------------------------------------------|
| Miss!O9  | Total fuel burn [lb]                     |
| Miss!O8  | Total mission time [min]                 |
| Miss!O6  | Landing ground roll [ft]                 |
| Miss!O12 | Final W/W_TO after Loiter                |
| Miss!B9:N9  | Per-segment fuel burns [lb]           |
| Miss!B8:N8  | Per-segment times [min]               |
| Miss!B12:N12| Per-segment weight fractions W/W_TO  |
| Miss!B7  | Takeoff ground roll [ft]                 |
| Miss!C25 | Installation factor (= 1.08)             |
| Miss!B13 | Takeoff dW/W_TO formula                  |
| Miss!D33 | Climb TSFC average formula               |
| Miss!D45 | Climb Ps formula                         |
| Miss!D8  | Climb time formula                       |
| Miss!I9  | Combat fuel burn [lb]                    |
| Miss!I13 | Combat dW/W_TO formula                   |
