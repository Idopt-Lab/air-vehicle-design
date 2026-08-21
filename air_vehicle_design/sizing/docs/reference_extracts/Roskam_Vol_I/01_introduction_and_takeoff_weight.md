# Roskam, Airplane Design Part I — Introduction and Take-off Weight Estimation

**Source:** Jan Roskam, *Airplane Design, Part I: Preliminary Sizing of Airplanes*, Chapter 1
(Introduction, book pp. 1-3) and Chapter 2 (Estimating Take-off Gross Weight, Empty Weight, and
Mission Fuel Weight, book pp. 5-88).

## Chapter 1 — Introduction

### Purpose of the book series

Roskam's series of books teaches the methods and decisions that go into airplane design. Design
work needs a mission specification. A mission specification describes what the airplane must do:
payload, range or loiter, cruise speed and altitude, take-off and landing field length, fuel
reserves, climb, maneuvering, and the certification basis (Experimental, FAR 23, FAR 25, or
Military) [Roskam, p. 2].

A mission specification can start from many sources: a commercial market need, a specific
customer request, or a military operational requirement. [Roskam, Fig. 1.1, p. 3] shows this as a
flow diagram — no plotted data, purely illustrative — tracing how a request or a perceived need
leads to a mission specification, then to preliminary sizing and preliminary design. If the
preliminary design study finds a real market or military need, full-scale development follows. If
the study instead finds a technology gap or missing data, a research and development program comes
first; only when that program closes the gap does a final mission specification emerge and lead to
full-scale development. If the problems cannot be solved at reasonable cost or in a reasonable
time, the project is dropped or changed [Roskam, p. 1].

Most airplane concepts never go past the preliminary design phase.

### Roadmap of the series (Parts I-VIII)

The series covers preliminary sizing through cost estimation in eight parts [Roskam, p. 1]:

- **Part I** — Preliminary Sizing of Airplanes.
- **Part II** — Preliminary Configuration Design and Integration of the Propulsion System.
- **Part III** — Layout Design of Cockpit, Fuselage, Wing and Empennage: Cutaways and Inboard
  Profiles.
- **Part IV** — Layout Design of Landing Gear and Systems.
- **Part V** — Component Weight Estimation.
- **Part VI** — Preliminary Calculation of Aerodynamic, Thrust and Power Characteristics.
- **Part VII** — Determination of Stability, Control and Performance Characteristics: FAR and
  Military Requirements.
- **Part VIII** — Airplane Cost Estimation: Design, Development, Manufacturing and Operating.

[Roskam, Fig. 1.2, p. 4] lays out the preliminary design process this series covers as a flow
diagram (no plotted data): mission specification feeds Part I preliminary sizing (producing
take-off weight, maximum lift coefficients clean/take-off/landing), which feeds Part II preliminary
configuration layout and propulsion integration, leading to one or more configuration candidates
for further study. Refinement loops (sensitivity studies, R&D needs, sizing refinement) run in
parallel with initial wing/fuselage layout, Class I tail sizing/weight-and-balance/drag polar
estimates, and landing gear disposition. Once the preliminary configuration is finished, Parts III,
IV, and V refine the layout (wing, fuselage, empennage; landing gear disposition and retraction
check; preliminary structural layout) together with Class II weight, balance, drag polar, flap
effect, stability and control estimates, performance verification, and cost calculations.

### What "preliminary sizing" produces

Part I defines preliminary sizing as the process that gives numeric values for [Roskam, p. 2]:

- Gross take-off weight, `W_TO`
- Empty weight, `W_E`
- Mission fuel weight, `W_F`
- Maximum required take-off thrust, `T_TO` (or take-off power, `P_TO`)
- Wing area, `S`, and wing aspect ratio, `A`
- Maximum required lift coefficient, clean, `CL_max`
- Maximum required lift coefficient for take-off, `CL_max,TO`
- Maximum required lift coefficient for landing, `CL_max,L`

Chapter 2 covers the first three (`W_TO`, `W_E`, `W_F`). Chapter 3 covers the rest (wing area,
aspect ratio, take-off thrust/power, and the three lift coefficients) [Roskam, p. 3]. Chapter 4 (not
extracted here) is a user's guide through the whole preliminary sizing process.

## Chapter 2 — Estimating Take-off Gross Weight, Empty Weight, and Mission Fuel Weight

### §2.1 General Outline of the Method

Airplanes must meet range, endurance, speed, and cruise-speed goals while carrying a given payload.
This chapter gives a fast method for estimating take-off gross weight `W_TO`, empty weight `W_E`,
and mission fuel weight `W_F`, for twelve categories of airplane: homebuilt propeller, single-engine
propeller, twin-engine propeller, agricultural, business jet, regional turboprop, transport jet,
military trainer, fighter, military patrol/bomb/transport, flying boat/amphibious/float, and
supersonic cruise [Roskam, p. 5].

Take-off weight breaks down as [Roskam, Eq. (2.1), p. 5]:

```
W_TO = W_OE + W_F + W_PL
```

where `W_OE` is the operating empty weight (OWE), `W_F` is mission fuel weight, and `W_PL` is
payload weight.

Operating empty weight in turn is [Roskam, Eq. (2.2), p. 6]:

```
W_OE = W_E + W_tfo + W_crew
```

where `W_E` is empty weight, `W_tfo` is trapped (unusable) fuel and oil weight, and `W_crew` is crew
weight needed to operate the airplane.

Empty weight is sometimes split further [Roskam, Eq. (2.3), p. 6]:

```
W_E = W_ME + W_FEQ
```

where `W_ME` is manufacturer's empty weight (the "green weight") and `W_FEQ` is fixed equipment
weight (avionics, air conditioning, radar, APU, furnishings, and other gear needed to fly the
mission).

Two facts make a fast estimate possible [Roskam, p. 6]:

1. Mission fuel weight `W_F` can be found from simple physical reasoning (the fuel-fraction method,
   §2.4).
2. `log10(W_E)` plots linearly against `log10(W_TO)` for each of the twelve airplane categories
   (§2.5).

The estimating process is seven steps [Roskam, Eqs. (2.4)-(2.5), p. 7]:

1. Find the mission payload weight, `W_PL` (§2.2).
2. Guess a likely take-off weight, `W_TO,guess` (§2.3).
3. Find the mission fuel weight, `W_F` (§2.4).
4. Compute a tentative operating empty weight:
   `W_OE,tent = W_TO,guess - W_F - W_PL` [Eq. (2.4)]
5. Compute a tentative empty weight:
   `W_E,tent = W_OE,tent - W_tfo - W_crew` [Eq. (2.5)]
   (`W_tfo` can be as much as 0.5% or more of `W_TO`, but is often neglected at this stage.)
6. Find the allowable value of `W_E` from §2.5.
7. Compare `W_E,tent` (Step 5) with the allowable `W_E` (Step 6). Adjust `W_TO,guess` and repeat
   Steps 3-6 until the two values agree within about 0.5%.

§2.6 applies this seven-step method to three worked examples; §2.7 covers sensitivity/growth-factor
equations.

### §2.2 Determination of Mission Payload Weight, W_PL, and Crew Weight, W_crew

Mission payload weight `W_PL` is normally given in the mission specification. It usually consists of
passengers and baggage, cargo, or military loads (ammunition, bombs, missiles, external stores) —
external military stores also add drag [Roskam, p. 8].

Weight assumptions for people [Roskam, p. 8]:

- Commercial passengers, short/medium flights: 175 lb per person + 30 lb baggage.
- Commercial passengers, long flights: 175 lb per person + 40 lb baggage.
- Crew members: 175 lb per person + 30 lb baggage.
- Military crew members: 200 lb per person (extra gear).

Crew size (cockpit + cabin) depends on the airplane, its mission, and passenger count; FAR 91.215
sets the minimum cabin crew. For owner-flown FAR 23 airplanes, it is common to fold crew weight into
payload instead of treating it separately [Roskam, p. 8].

### §2.3 Guessing a Likely Value of Take-off Weight, W_TO,guess

The initial guess for `W_TO` comes from comparing the new airplane's mission with similar existing
airplanes (data compiled in Roskam's Reference 9). If no comparable airplane exists, an arbitrary
guess is used instead [Roskam, p. 8].

### §2.4 Determination of Mission Fuel Weight, W_F

Mission fuel weight splits into fuel actually burned plus reserves [Roskam, Eq. (2.6), p. 9]:

```
W_F = W_Fused + W_Fres
```

Fuel reserves are set by the mission specification or by FAR rules, and are usually given as a
fraction of `W_Fused`, as extra range to reach an alternate airport, or as extra loiter time.

`W_Fused` is found with the **fuel-fraction method**: split the mission into phases, each with a
begin weight and an end weight [Roskam, p. 9]. [Roskam, Fig. 2.1, p. 10] shows a representative
mission profile (numbered phases: engine start/warmup, taxi, take-off, climb/accelerate, cruise,
loiter, descent, landing/taxi/shutdown) — a schematic diagram, no plotted data.

**Fuel-fraction**, by definition, is the ratio of end weight to begin weight for a phase [Roskam,
p. 11].

Phase-by-phase method [Roskam, pp. 11-16]:

- **Phase 1, engine start/warmup** (`W_TO` → `W1`): fraction `W1/W_TO` from Table 2.1.
- **Phase 2, taxi** (`W1` → `W2`): fraction `W2/W1` from Table 2.1.
- **Phase 3, take-off** (`W2` → `W3`): fraction `W3/W2` from Table 2.1.
- **Phase 4, climb + accelerate to cruise** (`W3` → `W4`): fraction `W4/W3` from Fig. 2.2, or
  computed with Breguet's endurance equation:
  - Propeller-driven [Roskam, Eq. (2.7), p. 12]:
    `E_cl = 375 (1/V_cl) (η_p/c_p)_cl (L/D)_cl ln(W3/W4)` (`V_cl` in mph)
  - Jet [Roskam, Eq. (2.8), p. 12]:
    `E_cl = (1/c_j)_cl (L/D)_cl ln(W3/W4)` (`E_cl` = time to climb, hours)
  - `(η_p/c_p)`, `c_j`, `(L/D)` for the climb come from Table 2.2.
- **Phase 5, cruise** (`W4` → `W5`): from Breguet's range equation:
  - Propeller-driven [Roskam, Eq. (2.9), p. 13]:
    `R_cr = 375 (η_p/c_p)_cr (L/D)_cr ln(W4/W5)` (`R_cr` in statute miles)
  - Jet [Roskam, Eq. (2.10), p. 13]:
    `R_cr = (V/c_j)_cr (L/D)_cr ln(W4/W5)` (`R_cr` usually in n.m.)
  - `R_cr` and `V_cr` normally come from the mission specification; `(η_p/c_p)`, `c_j`, `(L/D)`
    from Table 2.2.
- **Phase 6, loiter** (`W5` → `W6`): from Breguet's endurance equation:
  - Propeller-driven [Roskam, Eq. (2.11), p. 15]:
    `E_ltr = 375 (1/V_ltr) (η_p/c_p)_ltr (L/D)_ltr ln(W5/W6)` (`V_ltr` in mph)
  - Jet [Roskam, Eq. (2.12), p. 15]:
    `E_ltr = (1/c_j)_ltr (L/D)_ltr ln(W5/W6)` (`E_ltr` usually in hours)
  - `V_ltr` and `E_ltr` normally from the mission specification; `(η_p/c_p)`, `c_j`, `(L/D)` from
    Table 2.2.
- **Phase 7, descent** (`W6` → `W7`): fraction `W7/W6` from Table 2.1.
- **Phase 8, landing/taxi/shutdown** (`W7` → `W8`): fraction `W8/W7` from Table 2.1.

Overall mission fuel-fraction [Roskam, Eq. (2.13), p. 16]:

```
W_ff = ∏(i=1..7) (W_(i+1)/W_i)
```

Fuel actually used [Roskam, Eq. (2.14), p. 16]:

```
W_Fused = (1 - W_ff) W_TO
```

Mission fuel weight [Roskam, Eq. (2.15), p. 16]:

```
W_F = (1 - W_ff) W_TO + W_Fres
```

**Table 2.1 — Suggested fuel-fractions for several mission phases** [Roskam, Table 2.1, p. 12].
Columns are mission phase 1 (engine start/warmup), 2 (taxi), 3 (take-off), 4 (climb), 7 (descent),
8 (landing/taxi/shutdown); rows are the twelve airplane categories.

| Airplane type | 1 | 2 | 3 | 4 | 7 | 8 |
|---|---|---|---|---|---|---|
| Homebuilt | 0.998 | 0.998 | 0.998 | 0.995 | 0.995 | 0.995 |
| Single engine | 0.995 | 0.997 | 0.998 | 0.992 | 0.993 | 0.993 |
| Twin engine | 0.992 | 0.996 | 0.996 | 0.990 | 0.992 | 0.992 |
| Agricultural | 0.996 | 0.995 | 0.996 | 0.998 | 0.999 | 0.998 |
| Business jets | 0.990 | 0.995 | 0.995 | 0.980 | 0.990 | 0.992 |
| Regional TBP's | 0.990 | 0.995 | 0.995 | 0.985 | 0.985 | 0.995 |
| Transport jets | 0.990 | 0.990 | 0.995 | 0.980 | 0.990 | 0.992 |
| Military trainers | 0.990 | 0.990 | 0.990 | 0.980 | 0.990 | 0.995 |
| Fighters | 0.990 | 0.990 | 0.990 | 0.96-0.90 | 0.990 | 0.995 |
| Mil. patrol, bomb, transport | 0.990 | 0.990 | 0.995 | 0.980 | 0.990 | 0.992 |
| Flying boats, amphibious, float | 0.992 | 0.990 | 0.996 | 0.985 | 0.990 | 0.990 |
| Supersonic cruise | 0.990 | 0.995 | 0.995 | 0.92-0.87 | 0.985 | 0.992 |

Notes on Table 2.1: the numbers are based on experience or judgment; there is no substitute for
common sense, and the reader should substitute other values when actual data are available
[Roskam, p. 12].

**Table 2.2 — Suggested values for L/D, c_j, η_p, and c_p for several mission phases** [Roskam,
Table 2.2, p. 14]. Columns: cruise `L/D`, cruise `c_j` (lb/lb/hr), cruise `c_p` (lb/hp/hr), cruise
`η_p`; loiter `L/D`, loiter `c_j`, loiter `c_p`, loiter `η_p`.

| Airplane type | Cruise L/D | Cruise c_j | Cruise c_p | Cruise η_p | Loiter L/D | Loiter c_j | Loiter c_p | Loiter η_p |
|---|---|---|---|---|---|---|---|---|
| Homebuilt | 8-10* | — | 0.6-0.8 | 0.7 | — | — | 0.5-0.7 | 0.6 |
| Single engine | 8-10 | — | 0.5-0.7 | 0.8 | — | — | 0.5-0.7 | 0.7 |
| Twin engine | 8-10 | — | 0.5-0.7 | 0.82 | — | — | 0.5-0.7 | 0.72 |
| Agricultural | 5-7 | — | 0.5-0.7 | 0.82 | — | — | 0.5-0.7 | 0.72 |
| Business jets | 10-12 | 0.5-0.9 | 0.4-0.6 | 0.85 | 12-14 | 0.4-0.6 | 0.5-0.7 | 0.77 |
| Regional TBP's | 11-13 | 0.5-0.9 | 0.4-0.6 | 0.85 | 14-16 | 0.4-0.6 | 0.5-0.7 | 0.77 |
| Transport jets | 13-15 | 0.5-0.9 | — | — | 14-18 | 0.4-0.6 | — | — |
| Military | 8-10 | 0.5-1.0 | 0.4-0.6 | 0.82 | 10-14 | 0.4-0.6 | 0.5-0.7 | 0.77 |
| Fighters | 4-7 | 0.6-1.4 | 0.5-0.7 | 0.82 | 6-9 | 0.6-0.8 | 0.5-0.7 | 0.77 |
| Mil. patrol/transport | 13-15 | 0.5-0.9 | 0.4-0.7 | 0.82 | 14-18 | 0.4-0.6 | 0.5-0.7 | 0.77 |
| Flying boats/amphibious/float | 10-12 | 0.5-0.9 | 0.5-0.7 | 0.82 | 13-15 | 0.4-0.6 | 0.5-0.7 | 0.77 |
| Supersonic cruise | 4-6 | 0.7-1.5 | — | — | 7-9 | 0.6-0.8 | — | — |

Notes on Table 2.2: the numbers represent ranges based on existing engines; there is no substitute
for common sense; good `L/D` estimates can be made with the drag-polar method of Sub-section 3.4.1;
homebuilts with smooth exteriors and/or high wing loadings can have considerably higher `L/D` than
shown [Roskam, p. 14].

### §2.5 Finding the Allowable Value for W_E

The linear relationship between `log10(W_E)` and `log10(W_TO)` (§2.1, Point 2) is shown by
regression analysis across Reference 9 / manufacturer data for the twelve categories [Roskam,
p. 17]. The resulting trend lines are Figures 2.3 through 2.14 (one per category, `W_E` vs. `W_TO`
log-log axes; underlying data in Tables 2.3 through 2.14). Since a manufacturer tries to minimize
`W_E` for a given `W_TO`, the trend line gives the "minimum allowable" `W_E` at the current
state-of-the-art [Roskam, p. 17].

Three ways to find `W_E` from `W_TO` [Roskam, p. 17-18]:

1. Read `W_E` directly off Figures 2.3-2.14 for the given `W_TO`.
2. Interpolate `W_E` from the data in Tables 2.3-2.14.
3. Compute `W_E` from the closed-form regression [Roskam, Eq. (2.16), p. 18]:

```
W_E = invlog10[(log10(W_TO) - A)/B]
```

with `A` and `B` from Table 2.15 (below). Composite-construction correction: multiply the
regression `W_E` by `W_comp/W_metal` from Table 2.16 for the fraction of structure that is
composite; non-primary composite structure (floors, fairings, flaps, controls, interiors) has been
common for years, so claims of large weight savings should be treated with caution [Roskam, p. 18].

**Figures 2.3-2.14 (weight trend charts)**: each is a log-log scatter plot of `W_E` vs. `W_TO` for
one airplane category, with a fitted regression line, spanning book pp. 19-46 [Roskam, Figs.
2.3-2.14, pp. 19-46]. The scan for these pages is dominated by hand-drawn/typeset log-log grids that
OCR cannot recover as text, and every one of these plots is, by the book's own construction, nothing
but a graphical rendering of Eq. (2.16) with the `A`,`B` pair from Table 2.15 for that category — so
rather than hand-read tick marks off a noisy scan, the equivalent (and more accurate) numeric
readout is Eq. (2.16) evaluated at representative `W_TO` values. Representative points, computed
this way, for the three categories used in the worked examples of §2.6:

- Twin-engine propeller driven (Fig. 2.5, category 3, composites-corrected line uses the
  "Composites" A/B row; the plain metal line is A=0.0966, B=1.0298):
  at `W_TO`=7,000 lb, `W_E` ≈ 4,297 lb (read from Eq. 2.16, equivalent to plot); at `W_TO`=7,900 lb,
  `W_E` ≈ 4,868 lb (matches the ≈4,900 lb Roskam reads off Fig. 2.5 in §2.6.1).
- Transport jets (Fig. 2.9, category 7, A=0.0833, B=1.0383):
  at `W_TO`=130,000 lb, `W_E` ≈ 72,400 lb (read from Eq. 2.16); at `W_TO`=127,000 lb, `W_E` ≈
  70,600 lb (matches the 70,000 lb Roskam reads off Fig. 2.9 in §2.6.2).
- Fighters, clean (Fig. 2.11, category 9, A=-0.1440, B=1.1162):
  at `W_TO`=60,000 lb, `W_E` ≈ 30,700 lb (read from Eq. 2.16); at `W_TO`=64,500 lb, `W_E` ≈
  33,500 lb (matches the 31,000-33,500 lb range Roskam reads off Fig. 2.11 in §2.6.3).

The other nine category plots (Figs. 2.3, 2.4, 2.6, 2.7, 2.8, 2.10, 2.12, 2.13, 2.14 — homebuilt,
single engine, agricultural, business jet, regional TBP, mil. trainer, mil. patrol/bomb/transport,
flying boat/amphibious/float, supersonic cruise) are the same construction (a log-log `W_E` vs.
`W_TO` scatter with the Table 2.15 regression line) and are not separately digitized here for the
same reason — Table 2.15 plus Eq. (2.16) already is the point-generating function for each of
them; captions only:

- [Roskam, Fig. 2.3, p. 19] — Weight trends for homebuilt propeller-driven airplanes.
- [Roskam, Fig. 2.4, p. 20] — Weight trends for single-engine propeller-driven airplanes.
- [Roskam, Fig. 2.6, p. 22] — Weight trends for agricultural airplanes.
- [Roskam, Fig. 2.7, p. 24] — Weight trends for business jets.
- [Roskam, Fig. 2.8, p. 25] — Weight trends for regional turbopropeller-driven airplanes.
- [Roskam, Fig. 2.10, p. 26] — Weight trends for military trainers.
- [Roskam, Fig. 2.12, p. 27] — Weight trends for military patrol, bomb, and transport airplanes.
- [Roskam, Fig. 2.13, p. 29] — Weight trends for flying boats, amphibious, and float airplanes.
- [Roskam, Fig. 2.14, p. 28] — Weight trends for supersonic cruise airplanes.

**Table 2.15 — Regression line constants A and B of Equation (2.16)** [Roskam, Table 2.15, p. 47].

| Airplane type | A | B |
|---|---|---|
| 1. Homebuilts — Pers. fun and transportation | 0.3411 | 0.9519 |
| 1. Homebuilts — Scaled Fighters | 0.5542 | 0.8654 |
| 1. Homebuilts — Composites | 0.8222 | 0.8050 |
| 2. Single Engine Propeller Driven | -0.1440 | 1.1162 |
| 2. Single Engine Propeller Driven — Composites | — | — |
| 3. Twin Engine Propeller Driven | 0.0966 | 1.0298 |
| 3. Twin Engine Propeller Driven — Composites | 0.1130 | 1.0403 |
| 4. Agricultural | -0.4398 | 1.1946 |
| 5. Business Jets | 0.2678 | 0.9979 |
| 6. Regional TBP | 0.3774 | 0.9647 |
| 7. Transport Jets | 0.0833 | 1.0383 |
| 8. Military Trainers — Jets | 0.6632 | 0.8640 |
| 8. Military Trainers — Turboprops | -1.4041 | 1.4660 |
| 8. Military Trainers — Turboprops without No. 2 | 0.1677 | 0.9978 |
| 8. Military Trainers — Piston/Props | 0.5627 | 0.8761 |
| 9. Fighters — Jets (+ ext. load) | 0.5091 | 0.9505 |
| 9. Fighters — Jets (clean) | -0.1440 | 1.1162 |
| 9. Fighters — Turboprops (+ ext. load) | 0.1362 | 1.0116 |
| 9. Fighters — Turboprops (+ ext. load), alt. | 0.2705 | 0.9830 |
| 10. Mil. Patrol, Bomb and Transport — Jets | -0.2009 | 1.1037 |
| 10. Mil. Patrol, Bomb and Transport — Turboprops | -0.4179 | 1.1446 |
| 11. Flying Boats, Amphibious and Float Airplanes | 0.1703 | 1.0083 |
| 12. Supersonic Cruise | 0.4221 | 0.9876 |

Note: the category-1 (Homebuilts) row/column pairing is confirmed — Pers. fun and transportation
gets A=0.3411, B=0.9519; Scaled Fighters gets A=0.5542, B=0.8654; Composites gets A=0.8222,
B=0.8050. Category 2 (Single Engine Propeller Driven) has no "Composites" sub-row value — the
printed table gives no A/B pair for it, confirmed against the source page (not an OCR gap).
Equation (2.16) is repeated at the bottom of the table for convenience [Roskam, Eq. (2.16)
repeated, p. 47].

**Table 2.16 — Weight reduction data for composite construction** [Roskam, Table 2.16, p. 48]:

| Structural component | W_comp/W_metal |
|---|---|
| Fuselage | 0.85 |
| Wing, Vertical Tail, Canard or Horizontal Tail | 0.75 |
| Landing Gear | 0.88 |
| Secondary Structure (flaps, slats, access panels, fairings) | 0.60 |
| Interior Furnishings | 0.50 |
| Air Induction System | 0.70-0.80 |

Notes: these factors should be used with caution — they assume a change from 100% conventional
aluminum alloy to 100% composite construction. For lithium-aluminum alloys in fuselage, wing, or
empennage structure, claim only a 5-10% weight reduction relative to conventional aluminum
[Roskam, p. 48].

### §2.6 Three Example Applications

#### §2.6.1 Example 1: Twin Engine Propeller Driven Airplane

Mission specification [Roskam, Table 2.17, p. 50]: six passengers at 175 lb each (pilot included)
plus 200 lb baggage; range 1,000 sm at max payload, reserves = 25% of mission fuel; altitude
10,000 ft; cruise 250 kt at 75% power at 10,000 ft; climb 10 min to 10,000 ft at max `W_TO`;
take-off/landing 1,500 ft groundrun sea level std. day, landing at `W_L = 0.95 W_TO`; piston/
propeller power; no pressurization; FAR 23.

Step 1 — payload [Roskam, p. 49]: `W_PL = 6×175 + 200 = 1,250 lb`.

Step 2 — guess, from comparable airplanes (Beech Duke B60, Beech Baron 58, Cessna T303, Piper
PA-44-180): `W_TO,guess = 7,000 lb`.

Step 3 — fuel fractions, phase by phase [Roskam, pp. 51-53]:

- Phase 1 (start/warmup): 0.992 (Table 2.1).
- Phase 2 (taxi): 0.996 (Table 2.1).
- Phase 3 (take-off): 0.996 (Table 2.1).
- Phase 4 (climb): 0.990 (Table 2.1).
- Phase 5 (cruise): Breguet range, Eq. (2.9), `R=1,000` nm, `c_p=0.5`, `η_p=0.82`, `L/D=11` →
  `W5/W4 = 0.863`.
- Phase 6 (descent): 0.992 (Table 2.1).
- Phase 7 (landing/taxi/shutdown): 0.992 (Table 2.1).

Overall `W_ff = (0.992)(0.992)(0.863)(0.990)(0.996)(0.996)(0.992) = 0.827`.

`W_Fused = (1-0.827)W_TO = 0.173 W_TO`. Reserve = 25% of that, so
`W_F = 0.173×1.25×W_TO = 0.216 W_TO`.

Step 4: `W_OE,tent = 7,000 - 0.216×7,000 - 1,250 = 4,238 lb`.

Step 5: `W_E,tent = 4,238 - 0.005×7,000 = 4,203 lb`.

Step 6: allowable `W_E` from Fig. 2.5 ≈ 4,300 lb.

Step 7: difference is 97 lb — too large, so iterate. After iteration at `W_TO = 7,900 lb`:
`W_E,tent = 4,904 lb`, allowable `W_E = 4,900 lb` — within 0.5%.

Result [Roskam, p. 53]: `W_TO = 7,900 lb`, `W_E = 4,900 lb`, `W_F = 1,706 lb`.

#### §2.6.2 Example 2: Jet Transport

Mission specification [Roskam, Table 2.18, p. 55]: 150 passengers at 175 lb + 30 lb baggage each;
crew of 2 pilots + 3 attendants at 175 lb + 30 lb baggage each; range 1,500 nm + 1 hr loiter + 100 nm
to alternate; altitude 35,000 ft; cruise Mach 0.82; direct climb to 35,000 ft at max `W_TO`;
take-off/landing FAR 25, 5,000 ft field at 5,000 ft altitude and 95°F; landing at `W_L = 0.85 W_TO`;
two turbofans; cabin pressurized to 5,000 ft at 35,000 ft; FAR 25.

Step 1 [Roskam, p. 54]: `W_PL = 150×(175+30) = 30,750 lb`.

Step 2, from Boeing 737-300 / DC9-80 / A320 comparables: `W_TO,guess = 130,000 lb`.

Step 3, fuel fractions [Roskam, pp. 54-58]:

- Phase 1 (start/warmup): 0.990. Phase 2 (taxi): 0.990. Phase 3 (take-off): 0.995 (Table 2.1).
- Phase 4 (climb + accelerate): 0.980 (Table 2.1); climb takes range credit — 14 min at 275 kt
  average → 64 nm covered.
- Phase 5 (cruise): Breguet range, Eq. (2.10), jet form; `L/D=16`, `c_j=0.5`, cruise speed 473 kt
  (M0.82 @ 35,000 ft), `R = 1,500 - 64 = 1,436` nm → `W5/W4 = 0.909`.
- Phase 6 (loiter): Breguet endurance, Eq. (2.12); `L/D=18`, `c_j=0.6`, `E=1` hr, no range credit →
  `W6/W5 = 0.967`.
- Phase 7 (descent): 0.990 (Table 2.1), no range credit.
- Phase 8 (fly to alternate + descend): Eq. (2.10), `L/D=10`, `c_j=0.9`, `V ≤ 250` kt (FAA limit
  below 10,000 ft) → `W8/W7 = 0.965`.
- Phase 9 (landing/taxi/shutdown): 0.992 (Table 2.1).

Overall `W_ff = (0.992)(0.965)(0.990)(0.967)(0.909)(0.980)(0.995)(0.990)(0.990) = 0.796`.

`W_Fused = (1-0.796)W_TO = 0.204 W_TO`; reserves already accounted for in the profile, so
`W_F = 0.204 W_TO`.

Step 4: `W_OE,tent = 130,000 - 0.204×130,000 - 30,750 = 72,730 lb`.

Step 5: crew weight `W_crew = 1,025 lb` (from Table 2.18); `W_E,tent = 72,730 - 0.005×130,000 -
1,025 = 71,055 lb`.

Step 6: allowable `W_E` from Fig. 2.9 (or Eq. (2.16)) ≈ 70,000 lb.

Step 7: difference 1,055 lb — too large; iteration drives the estimate down. Iterating gives
`W_TO = 127,000 lb`.

Result [Roskam, p. 59]: `W_TO = 127,000 lb`, `W_E = 68,450 lb`, `W_F = 25,850 lb`.

#### §2.6.3 Example 3: Fighter (ground attack)

Mission specification [Roskam, Table 2.19, p. 62]: 20×500 lb bombs carried externally + 2,000 lb of
ammunition for a multi-barrel cannon (cannon weight of 4,000 lb counted in `W_E`); one 200 lb pilot;
range/altitude per mission profile, no reserves; cruise 400 kt sea level with external load, 450 kt
clean, M0.80 @ 40,000 ft loaded, M0.85 @ 40,000 ft clean; climb to 40,000 ft in 8 min, one-engine
climb rate > 500 fpm at 95°F; take-off groundrun < 2,000 ft, sea level, 95°F; two turbofans; cabin
pressurized to 5,000 ft at 50,000 ft; Military certification basis. The mission profile is a 15-phase
lo-lo-hi dash/strafe/return profile (climb-out, cruise-out, loiter, descent, dash-out, bomb drop,
strafe, dash-in, climb, cruise-in, descent, landing) [Roskam, Fig. under Table 2.19, p. 62].

Step 1 [Roskam, p. 61]: `W_PL = 2,000 + 20×500 = 12,000 lb`.

Step 2, from F.R. A10A / Grumman A6 / Tornado F.Mk2 comparables: `W_TO,guess = 60,000 lb`.

Step 3, fuel fractions through all 15 phases [Roskam, pp. 61-65]. Highlights:

- Phases 1-3 (start/taxi/take-off): 0.990 each (Table 2.1).
- Phase 4 (climb+accelerate to M0.80 @ 40,000 ft): from Fig. 2.2, `W4/W3 = 0.971`; 8 min climb at
  350 kt average gives 47 nm range credit.
- Phase 5 (cruise-out, 253 nm, `L/D=7.0`, `c_j=0.6`): Eq. (2.10) → `W5/W4 = 0.954`.
- Phase 6 (loiter, 30 min, `L/D=9.0`, `c_j=0.6`): Eq. (2.12) → `W6/W5 = 0.967`.
- Phase 7 (descent): `W7/W6 = 0.99` (Table 2.1), no range credit.
- Phase 8 (dash-out, 100 nm at 400 kt, `L/D=4.5`, `c_j=0.9`): Eq. (2.10) → `W8/W7 = 0.951`.
- Phase 9 (bomb drop, 10,000 lb dropped): no fuel/range effect on the ratio itself
  (`W9/W8 = 1.0`), but the bomb weight step (49,080 lb → 39,080 lb) requires correcting every
  downstream ratio derived before the drop by the weight-ratio factor `39,080/49,080 = 0.796`.
- Phase 10 (strafe, 5 min, `L/D=4.5`, `c_j=0.9`): Eq. (2.12) gives raw `W10/W9 = 0.983`, corrected
  for the bomb-drop weight change to `0.986`; 2,000 lb of ammunition is also expended during this
  phase and subtracted directly from weight (not as a fuel fraction).
- Phase 11 (dash-in, 100 nm at 450 kt, `L/D=5.5`, `c_j=0.9`): Eq. (2.10) gives raw
  `W11/W10 = 0.964`, corrected for the ammo-firing weight change to `0.966`.
- Phase 12 (climb+accelerate to M0.85): same method as Phase 4, `W12/W11 = 0.969`, 47 nm credit.
- Phase 13 (cruise-in, 253 nm, `L/D=7.5`, `c_j=0.6`, lighter/cleaner aircraft): Eq. (2.10) →
  `W13/W12 = 0.959`.
- Phase 14 (descent): `W14/W13 = 0.99` (Table 2.1).
- Phase 15 (landing/taxi/shutdown): `W15/W14 = 0.995` (Table 2.1).

Overall corrected `W_ff = 0.713`. Mission fuel:
`W_F = (1-0.713)×60,000 = 17,220 lb`.

Step 4: `W_OE,tent = 60,000 - 17,220 - 12,000 = 30,780 lb`.

Step 5: `W_E,tent = 30,780 - 0.005×60,000 - 200 = 30,280 lb`.

Step 6: allowable `W_E` from Fig. 2.11 ≈ 31,000 lb.

Step 7: difference 720 lb — too large; iterating gives `W_TO = 64,500 lb`.

Result [Roskam, p. 66]: `W_TO = 64,500 lb` (with external stores), `W_TO = 54,500 lb` (clean,
without stores), `W_E = 33,500 lb`, `W_F = 18,500 lb`. [Roskam, p. 67] illustrates this example with
a General Dynamics F-16A/F-16B three-view — purely illustrative, no plotted data.

### §2.7 Sensitivity Studies and Growth Factors

After preliminary sizing, it is important to check how sensitive `W_TO` is to each mission/
performance parameter: payload `W_PL`, empty weight `W_E`, range `R`, endurance `E`,
lift-to-drag ratio `L/D`, specific fuel consumption `c_p`/`c_j`, and propeller efficiency `η_p`
[Roskam, p. 68]. These studies show which parameters drive the design, where R&D effort should
focus, and what a too-optimistic (or pessimistic) technology assumption costs the design.

#### §2.7.1 Analytical method for take-off weight sensitivity

Combining Eqs. (2.4)-(2.6): [Roskam, Eq. (2.17)-(2.18), p. 68]

```
W_E = W_TO - W_F - W_PL - W_tfo - W_crew
W_F = (1 - W_ff) W_TO + W_Fres
```

With reserve fuel written as a fraction of mission fuel used, `W_Fres = M_res W_F` [Roskam, Eq.
(2.19), p. 69], and trapped fuel/oil as a fraction of `W_TO`, `M_tfo`, this reduces to
[Roskam, Eqs. (2.20)-(2.23), p. 69]:

```
W_E = C·W_TO - D
C = 1 - (1 + M_res)(1 - W_ff) - M_tfo
D = W_PL + W_crew
```

Eliminating `W_E` between this and Eq. (2.16) gives [Roskam, Eq. (2.24), p. 69]:

```
log10(C·W_TO - D) = A + B·log10(W_TO)
```

`A`, `B` are the Table 2.15 regression constants; `C`, `D` come from the mission. This equation both
gives a direct numerical solution for `W_TO` (replacing the iterative Steps 3-7) and is the basis
for the sensitivity derivatives below. Differentiating Eq. (2.24) with respect to any parameter `y`
[Roskam, Eqs. (2.25)-(2.26), pp. 69-70]:

```
∂W_TO/∂y = [B·W_TO²·(∂C/∂y) - B·W_TO·(∂D/∂y)] / [C(1-B)W_TO - D]
```

(`A`, `B` depend only on airplane category, so `∂A/∂y = ∂B/∂y = 0`.)

#### §2.7.2 Sensitivity of W_TO to payload weight

For `y = W_PL`: `∂D/∂W_PL = 1`, `∂C/∂W_PL = 0`, so [Roskam, Eq. (2.27), p. 70]:

```
∂W_TO/∂W_PL = -B / [C(1-B)W_TO - D]
```

This is the airplane's **growth factor due to payload**. Worked values [Roskam, pp. 70-72]:

- Twin (Example 1): `A=0.0966`, `B=1.0298` (Table 2.15), `C`, `D` from §2.6.1; Eq. (2.24) gives
  `W_TO ≈ 7,935 lb` (matches the iterative result). Growth factor
  `∂W_TO/∂W_PL ≈ 5.7 lb/lb`.
- Jet transport (Example 2): `A=0.0833`, `B=1.0383`, `C=0.791`, `D=31,775` lb; Eq. (2.24) gives
  `W_TO ≈ 126,100 lb`. Growth factor `∂W_TO/∂W_PL ≈ 3.7 lb/lb`.
- Fighter (Example 3): `A=0.5091`, `B=0.9505`, `C=0.708`, `D=12,200` lb; Eq. (2.24) gives
  `W_TO ≈ 64,000 lb`. Growth factor `∂W_TO/∂W_PL ≈ 6.1 lb/lb`.

#### §2.7.3 Sensitivity of W_TO to empty weight

From Eq. (2.16), differentiating with respect to `W_E` [Roskam, Eqs. (2.28)-(2.29), p. 72]:

```
∂W_TO/∂W_E = W_TO / [B·invlog10((log10(W_E)-A)/B)]
```

Worked growth factors [Roskam, pp. 72-73]: twin `∂W_TO/∂W_E ≈ 1.66`; jet transport
`∂W_TO/∂W_E ≈ 1.93`; fighter `∂W_TO/∂W_E ≈ 1.83`. Each says: for every pound the empty weight grows,
take-off weight must grow by that many pounds to hold mission performance fixed.

#### §2.7.4-2.7.6 Sensitivity to range, endurance, speed, SFC, propeller efficiency, and L/D

For any parameter `y` other than payload, [Roskam, Eq. (2.30), p. 74]:

```
∂W_TO/∂y = -B·W_TO²·(∂C/∂y) / [C(1-B)W_TO - D]
```

with `C` written as [Roskam, Eqs. (2.31)-(2.33), p. 74]:

```
C = 1 - (1 + M_res)(1 - W_ff) - M_tfo
∂C/∂y = (1 + M_res)·∂W_ff/∂y
∂W_ff/∂y = W_ff · Σᵢ [∂(W_(i+1)/Wᵢ)/∂y] / (W_(i+1)/Wᵢ)
```

Breguet's range/endurance relations are generalized as [Roskam, Eqs. (2.34)-(2.39), pp. 74-75]:

```
R = ln(Wᵢ/W_(i+1))          (range case)
E = ln(Wᵢ/W_(i+1))          (endurance case)
Propeller: R = R_cp(375 η_p L/D)⁻¹,  E = E V c_p (375 η_p L/D)⁻¹
Jet:       R = R c_j (V L/D)⁻¹,      E = E c_j (L/D)⁻¹
```

Differentiating the weight-ratio terms and substituting gives [Roskam, Eqs. (2.40)-(2.44), pp. 75]:

```
∂W_TO/∂y = F · ∂R/∂y     (range-dependent ratio)
∂W_TO/∂y = F · ∂E/∂y     (endurance-dependent ratio)
F = B·c_j⁻¹·[C(1-B)W_TO² - D·W_TO]⁻¹·(1+M_res)   [general form, Eq. (2.44)]
```

The specific partials `∂R/∂y` and `∂E/∂y` (for `y = R, E, V, c_p, η_p, L/D`) are tabulated below.

**Table 2.20 — Breguet partials for propeller driven and for jet airplanes** [Roskam, Table 2.20,
p. 77]:

| y | Case | Propeller: ∂R̄/∂y or ∂Ē/∂y | Jet: ∂R̄/∂y or ∂Ē/∂y |
|---|---|---|---|
| R | Range | `c_p(375 η_p L/D)⁻¹` | `c_j(V L/D)⁻¹` |
| E | Endurance | `V c_p(375 η_p L/D)⁻¹` | `c_j(L/D)⁻¹` |
| c_p (prop) / c_j (jet) | Range | `R(375 η_p L/D)⁻¹` | `R(V L/D)⁻¹` |
| c_p (prop) / c_j (jet) | Endurance | `E V(375 η_p L/D)⁻¹` | `E(L/D)⁻¹` |
| η_p | Range | `-Rc_p(375 η_p² L/D)⁻¹` | Not Applicable |
| η_p | Endurance | `-EVc_p(375 η_p² L/D)⁻¹` | Not Applicable |
| V | Range | Not Applicable | `-Rc_j(V² L/D)⁻¹` |
| V | Endurance | `Ec_p(375 η_p L/D)⁻¹` | Not Applicable |
| L/D | Range | `-Rc_p(375 η_p (L/D)²)⁻¹` | `-Rc_j(V(L/D)²)⁻¹` |
| L/D | Endurance | `-EVc_p(375 η_p (L/D)²)⁻¹` | `-Ec_j(L/D)⁻²` |

Units, exactly as printed on the source page [Roskam, Table 2.20 note, p. 77]: on the propeller
side, `R` is in statute miles (sm) and `V` is in mph; on the jet side, `R` is in nautical miles
(nm) or statute miles (sm) and `V` is in knots (kt) or mph. **This mixed-unit convention is a real
hazard for anyone implementing these partials in code** — `c_p`/`c_j` (specific fuel consumption)
and the `375` conversion constant are calibrated to those specific unit choices, so mixing SI
speed/range with these formulas silently corrupts the result; convert everything to the units
above before evaluating any row of this table, or re-derive the constant for the unit system in
use.

#### §2.7.5 Sensitivity to range, endurance, and speed — worked examples

**Twin (Example 1)** [Roskam, p. 76]: no endurance leg, so only `∂W_TO/∂R` matters:
[Roskam, Eq. (2.45), p. 76]

```
∂W_TO/∂R = F c_p⁻¹(375 η_p L/D)⁻¹
```

With `F = 46,736 lb` (from the twin's `C`, `D`, `W_ff`, `W_TO`), `∂W_TO/∂R ≈ 6.9 lb/nm` [Roskam,
p. 78]. Increasing range from 1,000 nm to 1,100 nm costs about `100×6.9 = 690 lb` of `W_TO`.

**Jet transport (Example 2)** [Roskam, pp. 78-79]: `F = 369,211 lb`.

```
∂W_TO/∂R = F c_j⁻¹(V L/D)⁻¹     [Eq. (2.46)]
∂W_TO/∂E = F c_j⁻¹(L/D)⁻¹        [Eq. (2.47)]
∂W_TO/∂V = -F c_j(V² L/D)⁻¹      [Eq. (2.48)]
```

Numerically: `∂W_TO/∂R ≈ 24.4 lb/nm`, `∂W_TO/∂E ≈ 12,307 lb/hr`, `∂W_TO/∂V ≈ -74.1 lb/kt`. Reducing
design range 1,500→1,400 nm saves ≈2,440 lb; extending loiter 1.0→1.5 hr costs ≈6,154 lb. The
negative speed sensitivity is mathematically correct (higher cruise speed at fixed `L/D`, `c_j`
reduces `W_TO`) but not physically realistic in isolation — raising cruise speed usually lowers the
cruise `C_L`, which usually lowers `L/D` and changes engine `c_j`, both of which push `W_TO` back
up; there is also an Mach-number drag-rise effect on `L/D` at higher speed [Roskam, p. 79].

**Fighter (Example 3)** [Roskam, pp. 79-80]: `F = 278,786 lb`. Because the mission has four range
legs and one endurance (loiter) leg, each with its own `c_j`, `V`, `L/D`, sensitivities are computed
per-phase:

| Phase | c_j | V (kt) | L/D | ∂W_TO/∂R (lb/nm) or ∂W_TO/∂E (lb/hr) |
|---|---|---|---|---|
| Cruise-out | 0.6 | 459 | 7.0 | 52.1 |
| Dash-out | 0.9 | 400 | 4.5 | 139 |
| Dash-in | 0.9 | 450 | 5.5 | 101 |
| Cruise-in | 0.6 | 488 | 7.5 | 45.7 |
| Loiter | 0.6 | N.A. | 9.0 | 18,586 (per hr) |

The dash-out leg is the most range-sensitive: doubling dash-out range from 100 to 200 nm costs
`100×139 = 13,900 lb` of `W_TO` — at an assumed unit cost of $500/lb, that is a $7.0M-per-airplane
cost increase [Roskam, p. 80]. Cutting loiter time in half (30→15 min) saves
`0.25×18,586 = 4,645 lb`, or about $2.3M/airplane. Military requirements and affordability must be
traded against each other when writing the mission specification.

#### §2.7.6 Sensitivity to specific fuel consumption, propeller efficiency, and L/D

These are technology-controllable parameters — engine SFC, propeller efficiency, and aerodynamic
`L/D` all depend on the state of the art the designer chooses to draw on [Roskam, p. 81]. Sizing
sensitivity to them is used to (1) flag when a different configuration approach is forced, and
(2) set improvement targets for a directed R&D program.

**Twin (Example 1)** [Roskam, p. 81-82]:

```
∂W_TO/∂c_p = F R (375 η_p L/D)⁻¹     [Eq. (2.49)]
∂W_TO/∂η_p = -F R c_p(375 η_p² L/D)⁻¹  [Eq. (2.50)]
∂W_TO/∂(L/D) = -F R c_p(375 η_p (L/D)²)⁻¹  [Eq. (2.51)]
```

Numerically: an engine improvement from `c_p=0.50` to `0.45` saves `0.05×13,817 ≈ 691 lb`; a
propeller efficiency gain from 0.82 to 0.84 saves `0.02×8,425 ≈ 168 lb`; an `L/D` gain from 11 to 12
saves ≈628 lb — a range-dominated airplane like this twin is very `L/D`-sensitive.

**Jet transport (Example 2)** [Roskam, pp. 82-84]: `F = 369,211 lb`. Range-leg sensitivities
[Eqs. (2.52)-(2.53)]: `∂W_TO/∂c_j ≈ 70,056 lb/(lb/lb/hr)`, `∂W_TO/∂(L/D) ≈ -2,189 lb`. Loiter-leg
sensitivities [Eqs. (2.54)-(2.55)]: `∂W_TO/∂c_j ≈ 20,512 lb/(lb/lb/hr)`,
`∂W_TO/∂(L/D) ≈ -684 lb`. A cruise SFC error of 0.5 assumed vs. 0.8 actual costs `0.3×70,056 ≈
21,017 lb`; a loiter SFC improvement 0.6→0.5 saves `0.1×20,512 ≈ 2,051 lb`; a loiter `L/D`
improvement 18→19 saves 684 lb.

**Fighter (Example 3)** [Roskam, p. 84]: `F = 278,786 lb`; sensitivities per phase:

| Phase | ∂W_TO/∂c_j (lb per lb/lb/hr) | ∂W_TO/∂(L/D) (lb) |
|---|---|---|
| Cruise-out | 21,952 | -1,882 |
| Dash-out | 15,488 | -3,098 |
| Dash-in | 11,264 | -1,843 |
| Cruise-in | 19,271 | -1,542 |
| Loiter | 15,488 | -1,033 |

An SFC improvement of 0.1 during dash-out saves `0.1×15,488 ≈ 1,549 lb`; an `L/D` improvement of
0.5 during cruise-out saves `0.5×1,882 ≈ 941 lb`.

### §2.8 Problems

Six end-of-chapter problems ask the reader to apply the same fuel-fraction / regression-line method
to: (1) a re-worked jet-transport cruise split into five equal-distance sub-phases with a stated
drag polar `C_D = 0.0200 + 0.0333 C_L²`; (2) a 34-passenger regional transport with a 4-leg,
250-nm-per-leg mission; (3) a high-altitude loiter/reconnaissance airplane (48-hr loiter on
station at 45,000 ft); (4) a single-engine composite homebuilt; (5) a Mach-2.7 supersonic-cruise
transport; and (6) a high-altitude, unmanned, 168-hour-endurance communications airplane [Roskam,
pp. 85-88]. Each problem also asks for the `W_TO` sensitivity to the driving mission/technology
parameters, using the methods of §2.7.
