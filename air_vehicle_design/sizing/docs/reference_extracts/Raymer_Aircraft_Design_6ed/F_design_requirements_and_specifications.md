# Appendix F — Design Requirements and Specifications

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Appendix F
"Design Requirements and Specifications," printed pp. 995–998.

Five reference tables of regulatory/military design requirements: FAR category applicability,
takeoff and landing speed/climb/field-length definitions (military vs. FAR Part 23 vs. FAR Part
25), FAR multi-engine climb-gradient requirements (turbine and reciprocating), and U.S. Navy
carrier-suitability requirements. No narrative prose beyond table footnotes; no figures. All
tables reproduced faithfully below (read from the rendered page images, not the OCR text layer,
since the OCR badly transposed these multi-column tables).

---

## Table F.1 — Federal Aviation Regulations (FAR) — Applicability

*[Raymer, Table F.1, p. 995, after E. Torenbeck [40]]*

| Category | Various† | Normal | Transport |
|---|---|---|---|
| **A) Characteristics** | | | |
| Maximum takeoff weight, lb | ≤12,500 | ≤12,500 | — |
| Number of engines | One or more | Two or more | Two or more |
| Type of engine | All | Propeller engines only | All |
| Minimum crew — Flight crew | One or more | Two | Two or more |
| Minimum crew — Cabin attendants | None | <20 Pass.: None; ≥20 Pass.: One | <10 Pass.: None; ≥10 pass.: One or more |
| Maximum number of occupants | 10 | 11–23 | Not restricted |
| Maximum operating altitude, ft | 25,000 | 25,000 | Not restricted |
| **B) FAR Applicability** | | | |
| Airworthiness standards airplanes | Part 23 | Part 23 | Part 25 |
| Airworthiness standards engines | Part 33 | Part 33 | Part 33 |
| Airworthiness standards propellers | Part 35 | Part 35 | Part 35 |
| Noise standards | Part 36: Prop-Driven, Appendix F | Part 36 | Part 36 |
| General operating and flight rules | Part 91 | Part 91 | Part 91 |
| Operations — Domestic, flag, and supplemental comm. operators of large aircraft | — | — | Part 121 |
| Operations — Air travel clubs using large aircraft | — | — | Part 123 |
| Operations — Air taxi and comm. operators | — | Part 135 | — |
| Operations — Agricultural aircraft | Part 137 | — | — |

† Normal, utility, aerobatic, and agricultural.

## Table F.2 — Takeoff Specifications

*[Raymer, Table F.2, p. 996, after L. Nicolai [16]]*

| Item | Military MIL-C-5011A | FAR Part 23 (Civil) | FAR Part 25 (Commercial) |
|---|---|---|---|
| Velocity | V_TO ≥ 1.1 V_s; V_CL ≥ 1.2 V_s | V_TO ≥ 1.1 V_s; V_CL ≥ 1.2 V_s | V_TO ≥ 1.1 V_s; V_CL ≥ 1.2 V_s |
| Climb | Gear up: 500 fpm @ S.L. (AEO)†; 100 fpm @ S.L. (OEI)‡ | Gear up: 300 fpm @ S.L. (AEO) | Gear down: 1/2% @ V_TO; Gear up: 3% @ V_CL (OEI)§ |
| Field-length definition | Takeoff distance over 50-ft obstacle | Takeoff distance over 50-ft obstacle | 115% of takeoff distance with AEO over 35 ft, or balanced field length |
| Rolling coefficient | μ = 0.025 | Not defined | Not defined |

† AEO = all engines operating. ‡ OEI = one engine inoperative. § 4-engine aircraft; for 2- or
3-engine aircraft, see Table F.4.

## Table F.3 — Landing Specifications

*[Raymer, Table F.3, p. 996, after L. Nicolai [16]]*

| Item | MIL-C-5011A | FAR Part 23 | FAR Part 25 |
|---|---|---|---|
| Velocity | V_A ≥ 1.2 V_s; V_TD ≥ 1.1 V_s | V_A ≥ 1.3 V_s; V_TD ≥ 1.15 V_s | V_A ≥ 1.3 V_s; V_TD ≥ 1.15 V_s |
| Field-length definition | Landing distance over 50-ft obstacle | Landing distance over 50-ft obstacle | Landing distance over 50-ft obstacle, divided by 0.6 |
| Braking coefficient | μ = 0.30 | Not defined | Not defined |

## Table F.4 — FAR Climb Requirements for Multi-Engine Aircraft

*[Raymer, Table F.4, pp. 997–998]*

**Turbine-Engine Aircraft: FAR 25.** All segments flown with one engine stopped, except go-around
in landing configuration (all engines operating, AEO). Engine power/thrust at "maximum rated,"
except "maximum continuous" for the third-segment climb. Maximum thrust attained 8 s after flight
idle for go-around. First-segment climb runs to 35 ft; second segment to 400 ft AGL.

| Operation | Speed | Flaps | Landing Gear | Min. Climb Gradient, n=2 | n=3 | n=4 |
|---|---|---|---|---|---|---|
| Takeoff climb — First-segment | LOF* | Takeoff | Down | ≥0 | 0.3 | 0.5 |
| Takeoff climb — Second-segment | V₂† | Takeoff | Up | 2.4 | 2.7 | 3.0 |
| Third-segment (Transition/Acceleration) | — | — | — | positive climb gradient only (FAA requirement) | | |
| Fourth-segment | ≥1.25 V_S‡ | Up | Up | 1.2 | 1.5 | 1.7 |
| Landing — Go-around, approach config. | ≤1.4 V_SR‡ | Approach | Up | 2.1 | 2.4 | 2.7 |
| Landing — Go-around, landing config. (AEO) | ≤1.23 V_SR0‡ | Landing | Down | 3.2 | 3.2 | 3.2 |

\* LOF = liftoff. † Climb-out speed over 35-ft obstacle. ‡ Stall speed in the pertinent condition.

**Reciprocating-Engine Aircraft: FAR 25.** Power/thrust for operating engines set for takeoff on
first and second segments and go-around, and for "maximum continuous" during cruise and the third
segment. One engine has a windmilling propeller for the first and second segments (or is assumed
feathered if the aircraft has automatic feathering); one engine is stopped (may be feathered) for
the third segment and go-around.

| Operation | Speed | Flap Setting | Landing Gear | Minimum Steady-Climb Rate |
|---|---|---|---|---|
| Takeoff climb — First-segment | V₂* | Takeoff | Down | ≥50 ft/min |
| Takeoff climb — Second-segment | V₂* | Takeoff | Up | ≥0.046 V²_s1† |
| Takeoff climb — Third-segment | Best | Up‡ | Up | ≥(0.079 − 0.106/n) V²_S0¶,** |
| Landing go-around — Approach config. | ≤1.5 V_s1† | Approach§ | Up | ≥0.053 V²_s1¶ |

\* V₂ = climb-out speed over 35-ft obstacle, out-of-ground effect. † V_s1 = stall speed in a
specified configuration for reciprocating-engine-powered airplanes, in knots. ‡ Or most favorable.
§ But V_s1 ≤ 1.1 V_S0. ¶ V_S0 = stall speed in landing configuration for reciprocating-engine-
powered airplanes, in knots. ** At 5000-ft altitude.

**FAR 23 (Turbine or Reciprocating).** Multi-engine power at maximum continuous except for W <
6000 lb.

| Aircraft Status | Speed | Flaps | Landing Gear | Minimum Steady-Climb Rate, ft/min |
|---|---|---|---|---|
| One engine out (prop feathered)* | Most favorable | Most favorable | Up | ≥0.027 V²_S0‡ |
| AEO†, W > 6000 lb | Most favorable | Takeoff | Up | ≥300-ft/min climb gradient; ≥0.0833 land plane; ≥0.0667 seaplane |
| AEO†, W < 6000 lb | Most favorable | Takeoff | Down | ≥300 ft/min and ≥11.5 V_S0§ |

\* If W < 6000 lb and V_S0 < 61 kt, there is no engine-out climb requirement. † AEO = all engines
operating. ‡ V_S0 = stall speed in landing configuration for reciprocating-engine-powered
airplanes, in knots, at 5000 ft. § V_s1 = stall speed in a specified configuration for
reciprocating-engine-powered airplanes, in knots.

## Table F.5 — Special Carrier Suitability Requirements (U.S. Navy)

*[Raymer, Table F.5, p. 998]*

1. Minimum rate of climb (at design landing weight and approach speed) of 500 ft/min at
   intermediate thrust (non-AB) with one engine inoperative.
2. Minimum longitudinal acceleration at end of catapult stroke of 0.065 g (at maximum catapult
   weight; all engines operating).
3. Aircraft to fit on 70- by 52-ft aircraft elevator.
4. Landing gear width not to exceed 22 ft.
5. Folded height of the aircraft not to exceed 18 ft 6 in.; height while folding not to exceed 24
   ft 6 in. (18 ft 6 in. desirable).
6. Aircraft maximum weight (loaded and fueled) not to exceed 80,000 lb (elevator limit).
7. Wing span not to exceed 82 ft (64 ft desired).
8. Design landing weight to include high-value stores, empty external fuel tanks, and associated
   suspension equipment (pylons, ejectors, etc.).

---

*Appendix F complete (Tables F.1–F.5, no figures). This is the last appendix in the book's
front/back-matter sequence cited by this repo — Questions, References, and the Index follow at
book p. 999 onward and are not extracted (no citable equations/data).*
