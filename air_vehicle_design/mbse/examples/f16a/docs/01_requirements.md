# R Layer — Requirements

> `requirements/f16a.slreqx` (26) · `f16a_functional_derived.slreqx` (D01–D09) ·
> `f16a_logical_derived.slreqx` (L01–L03) · `f16a_physical_derived.slreqx` (P01, P02)

The R layer tells **what the F-16A must achieve**, independently of a design. It is a Requirements
Toolbox set. Thus the other layers can link to it and show coverage.

## Provenance: only inputs become requirements

The requirements come from the **Brandt F-16A reference sizing model** (`sizing/VnV/BrandtF16A`).
They are cross-referenced against `Brandt-F16-A.xls`. One rule keeps the set correct:

> **Only spreadsheet _input_ cells become requirement values.** A computed cell (for example, a
> liftoff Mach that the spreadsheet calculates) is named in the Description for traceability. It is
> never stated as a value.

A requirement is something that you demand of the design. It is not a value that the analysis
produces. The Description of each requirement names its cells. `f16a.slreqx` holds only these
requirements. Needs found later are in separate derived sets.

## Structure

There are eight containers under `REQ_F16A_000`: Mission, Point performance, Structural, Weight,
Materials, Balance, Stability & control, Cost.

| ID | Mission segment | Key input condition | Source cells |
|----|---------|---------------------|---|
| 001 | Takeoff | Sea level, 100% afterburner | `Main!K33, K36` |
| 002 | Accel | 10,000 ft → Mach 0.87, dry | `Main!L33, L35, L36` |
| 003 | Climb | → 40,000 ft, dry | `Main!M33, M36` |
| 004 | Cruise | dry-power cruise to combat area | `Main!N36` |
| 005 | Dash | 50% afterburner, 50 nm | `Main!P36, P38` |
| 006 | Combat | 25,000 ft, 2 min, releases the expendable payload | `Main!R33, R39`, drop `Miss!I10` |
| 007 | Egress | dry, 50 nm, 40,000 ft | `Main!S33, S36, S38` |
| 008 | Cruise2 | dry-power return cruise | `Main!V36` |
| 009 | Loiter | 10,000 ft, Mach 0.30, 20 min | `Main!W33, W35, W36, W39` |
| 010 | Landing | sea level | `Main!X33` |

| ID | Point performance (`Ps = 0` unless stated) | Source row |
|----|--------------|---|
| 011 | Mach 1.6 at 36,000 ft | `Main!S3:X3` |
| 012 | Mach 0.87 at 36,000 ft, dry | `Main!S4:X4` |
| 013 | 50,000 ft at Mach 0.87 | `Main!S5:X5` |
| 014 | subsonic turn, n ≥ 4.5 at Mach 0.87, 20,000 ft | `Main!S6:X6` |
| 015 | supersonic turn, n ≥ 1.4 at Mach 1.4, 36,000 ft | `Main!S7:X7` |
| 016 | `Ps` ≥ 500 ft/s at Mach 0.87, 10,000 ft | `Main!S8:X8` |
| 017 | takeoff ground roll ≤ 4,000 ft | `Main!S12:X12` |
| 018 | landing ground roll ≤ 4,000 ft | `Main!S13:X13` |

| ID | Requirement | Source |
|----|-------------|---|
| 019 | ultimate load factor 9 g | `Main!Q27` |
| 020 | permanent payload 700 lb | `Main!O16` |
| 021 | expendable payload 4,400 lb, released in Combat | `Main!O17` |
| 022 | composite fraction ≤ 20% (Al 65 / CF 20 / Ti 10 / Steel 5 / FG 0) | `Cost!B41:B45` |
| 023 | tipback angle — **blank, a student exercise** | — |
| 024 | rollover angle — **blank, a student exercise** | — |
| 025 | static margin −6 %MAC ≤ SM < 0 — **violated at landing** | floor is an `Estimate` (D-030) |
| 026 | unit flyaway cost — **minimize** (a Measure of Merit, not a threshold) | ≈ $68.4M DAPCA IV, context only |

## The derived sets

- **`D01`–`D09` (functional).** The decomposition of the functions found needs that the spreadsheet
  does not mention: maneuvering, fuel management, navigation, communication, and the five targeting
  steps of combat. They are recorded as derived requirements with `TBD` criteria. **The blanks are
  the assignment** (D-045). No external source defines them, so any number would be invented.
- **`L01`–`L03` (logical).** Each one states a design decision: which kind realizes the propulsion,
  flight-control and airframe roles. They contain no answer. The trade study that makes the decision
  creates an Implement link from the winning kind (D-037, D-040).
- **`P01`, `P02` (physical).** Sufficient fuel tankage for the mission, and life-cycle cost. Life-cycle
  cost is a Measure of Merit with no upper limit, because no sourced target exists.

Eleven requirements have the `todo` keyword: D01–D09, 023 and 024. No other work is open.

## `023` / `024` — the gear-angle exercise

Both requirements are blank on purpose (D-046), because **the two angles in Brandt possibly do not
have the same meaning as in the specifications.**

`BrandtBalanceStabControl` computes `rollover_deg = atand(h_main_ft / d_axis)`, measured **from the
horizontal**. The standard overturn angle (Raymer §11.4, Currey) is measured **from the vertical**.
With the shipped inputs, `d_axis` = 1.497 ft. Thus the Brandt angle is **74.2°**, and its complement
is **15.8°**. Against the 63° limit, the standard angle passes easily and the Brandt angle fails.
**The same number supports opposite verdicts.**

`023` has a smaller version of this problem. The `tipback_deg` of Brandt is a tail-clearance angle
(≈ 21.5°). The Raymer tipback angle from the vertical, with the same inputs, is ≈ 65°.

Two more facts prevent a solution that only takes the complement:
- The gear load split in Brandt is inverted for a tricycle aircraft: 73% is on the nose gear. On
  the mains, 85–95% is normal.
- The Brandt wheelbase (15.7 ft) and track (12.0 ft) are not the same as those of the F-16A
  (≈ 13.3 and ≈ 7.75 ft, uncited approximations).

The quoted limits (USAF tipback 16–25°, overturn ≤ 63° USAF / 54° USN) have no document number. To
find the governing specification is part of the exercise. The name is also part of it: `024` is
still named *rollover*, because the name *overturn* would assume the answer.

## `025` — static margin

> **−6 %MAC ≤ SM < 0**, where `SM = (x_np − x_cg)/MAC`, at both ends of the operational CG range.

The strict zero is a definition: relaxed static stability *is* a negative margin. The −6 %MAC floor
limits the instability to the level that the flight controls are assumed to handle. It is an uncited
`Estimate` (D-030).

| Condition | Weight (lb) | `x_cg` (ft) | SM (%MAC) | Result |
|---|---|---|---|---|
| Takeoff | 31,377 | 26.1979 (aft end) | −0.2602 | met |
| Landing | 20,677.61 | 26.1451 (forward end) | **+0.2065** | **violated** |

The neutral point (26.1684 ft) is between the two. Thus the CG crosses it as the aircraft burns fuel
and releases stores. Both actions move the CG **forward**. Thus landing is the most stable end, and
this requirement is most difficult to meet there.

> **⚠ The landing violation comes from the reference model, not from the F-16A.** The Brandt neutral
> point is a simplified approximation, so the model becomes more *stable* as it burns fuel. The red
> shows that the requirement and its verification work. It is not a finding about the aeroplane.

## `026` and `022` — an objective and a constraint

`026` is a **Measure of Merit**. In conceptual design, cost is minimized and traded, not limited. P
computes it with DAPCA IV. `022` *is* a hard constraint. P **verifies** it with a test that rolls up
the composite fraction of the airframe.

Next: [Functions](02_functions.md).
