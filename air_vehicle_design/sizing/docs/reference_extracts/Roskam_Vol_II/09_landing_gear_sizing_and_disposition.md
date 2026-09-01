# Chapter 9 — Class I Method for Landing Gear Sizing and Disposition

**Source:** Jan Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration
of the Propulsion System*, Chapter 9 "Class I Method for Landing Gear Sizing and Disposition,"
printed pp. 217–236 (PDF index 228–247).

The chapter gives a rapid step-by-step method that finds four landing gear characteristics
[Roskam II, p. 217]:

1. Number, type and size of tires
2. Length and diameter of strut(s)
3. Preliminary disposition
4. Retraction feasibility

The method is Step 9 of preliminary-design sequence I of Chapter 2. Section 9.1 gives the
step-by-step method. Section 9.2 gives three worked examples.

The equation count is small: only Eqs. (9.1) and (9.2). The citable substance of the chapter is the
set of **geometric angle criteria** (Figs. 9.1a and 9.1b) and the two **static load** equations
plus their supporting tire tables (Tables 9.1 and 9.2).

---

## §9.1 Class I Method for Landing Gear Sizing and Disposition

### Step 9.1 — Select the landing gear system

Choices [Roskam II, p. 217]:

1. Fixed (non-retractable)
2. Retractable

Droppable gears and skid gears (example: the Me 163) are not examined. Air-cushion (ground effect)
gears are not examined.

**Rule of thumb:** if the cruise speed of the airplane is more than **150 kts**, a fixed landing
gear gives an unacceptably high drag penalty [Roskam II, p. 217].

### Step 9.2 — Select the overall landing gear configuration

Choices [Roskam II, p. 217]:

1. Tailwheel (taildragger)
2. Conventional (nosewheel, tricycle)
3. Tandem
4. Outrigger
5. Beaching gear (for flying boats)

Tandem and outrigger gears are frequently combined. The Boeing B-52 and the McDonnell Douglas
AV-8B are examples [Roskam II, p. 218].

Taildraggers give a small weight advantage for operation from soft or unprepared fields. The
nosewheel configuration is better for ground handling and for groundloop resistance. Most
airplanes today use nosewheel (tricycle) gear [Roskam II, p. 218].

> **IMPORTANT NOTE (the book's own emphasis):** before Step 9.4 and later steps you must know the
> c.g. range of the airplane [Roskam II, p. 218].

### Step 9.3 — Get a first weight and balance statement

Go to Chapter 10 and prepare a rough weight and balance statement for an assumed disposition of the
landing gear [Roskam II, p. 218].

### Step 9.4 — Select a preliminary strut disposition

Sketch the proposed strut disposition into the general arrangement drawing of Step 10.2,
Chapter 10 [Roskam II, p. 218].

Two geometric criteria control the disposition of the struts:

1. Tip-over criteria
2. Ground clearance criteria

---

#### 1. Tip-over criteria (Figure 9.1a)

**A) Longitudinal tip-over criterion**

*a. Tricycle gears:* the main landing gear must be **behind the aft c.g. location**. The **15 deg**
angle in Fig. 9.1a is the "usual" relation between the main gear and the aft c.g. [Roskam II,
p. 218].

*b. Taildraggers:* the main landing gear must be **forward of the fwd c.g. location**. The
**15 deg** angle in Fig. 9.1a is the "usual" relation between the main gear and the fwd c.g.
[Roskam II, p. 218].

In the figure the 15 deg angle is at the ground contact point of the main gear, between the
vertical through that point and the line from that point to the critical c.g. Roskam calls it the
"usual" relation. It is a rule of thumb. He does not cite a FAR paragraph for it.

**B) Lateral tip-over criterion**

Lateral tip-over is set by the angle `psi` in Fig. 9.1a. The criterion printed on the figure is:

```
psi <= 55 deg
```

Fig. 9.1a draws the lateral case for a tricycle gear and applies it at the **most fwd c.g.** The
figure carries this note: "FOR TAILDRAGGERS THIS APPLIES AT THE MOST AFT C.G." The criterion applies
to taildraggers in a similar way [Roskam II, pp. 218–219, 220].

Geometry of `psi`, read from Fig. 9.1a: in plan view, draw the line from the nose gear ground
contact point to one main gear ground contact point. Drop a perpendicular from the critical c.g.
onto that line. `psi` is the angle at the c.g., between the vertical through the c.g. and the line
from the c.g. to the foot of that perpendicular. The approximate fwd and aft c.g. locations come
from Step 9.3 [Roskam II, p. 220].

This 55 deg value is also a rule of thumb from the book. It is not cited to a FAR.

### Figure 9.1a — Tip-over Criteria for Landing Gear Placement
*[Roskam II, Fig. 9.1a, p. 219]* — Three hand-drawn panels:

| Panel | Content | Numeric data on the panel |
|---|---|---|
| Longitudinal Tip-over Criterion for Tricycle Gears | F-15-type fighter side view. MOST AFT C.G. marked. Main gear (M.G.) below and aft of it | `~15 deg` between the vertical at the M.G. contact point and the line to the aft c.g. |
| Longitudinal Tip-over Criterion for Taildraggers | Cessna-type high-wing side view. MOST FWD C.G. marked. M.G. below and forward of it | `~15 deg` between the vertical at the M.G. contact point and the line to the fwd c.g. The drawing also carries `3 deg 30'` (a thrust-line/incidence mark at the nose) and `12 deg` (tail-down angle at the M.G.). Those two come from the source three-view, not from the criterion |
| Lateral Tip-over Criterion | Perspective sketch. N.G. and two M.G. contact points. MOST FWD C.G. marked | `psi <= 55 deg` |

Hand sketch. No plotted curves, so nothing to digitize.

---

#### 2. Ground clearance criteria (Figure 9.1b)

Fig. 9.1b gives the required ground clearance angles [Roskam II, pp. 220–221]:

```
Longitudinal:  theta > theta_LOF ~= 15 deg     (tricycles only)
Lateral:       phi   > 5 deg                   (tricycles and taildraggers)
```

`theta` is the angle at the main gear ground contact point, between the ground line and the line
along the lower aft fuselage / tailcone, with the airplane in the static ground attitude.
`theta_LOF` is the lift-off attitude angle. `phi` is the angle at the main gear ground contact
point, between the ground line and the line out to the wing tip, seen from the front.

**Check both angles with tires and struts DEFLATED.** This note is printed on Fig. 9.1b
[Roskam II, p. 221].

The lateral angle applies to tricycles **and** taildraggers. The longitudinal angle applies to
tricycles **only** [Roskam II, p. 220].

### Figure 9.1b — Ground Clearance Criteria for Gear Placement
*[Roskam II, Fig. 9.1b, p. 221]* — Two hand-drawn panels:

| Panel | Content | Numeric data |
|---|---|---|
| Longitudinal Ground Clearance Criterion | Cessna-402-type twin side view. Wheel `BASE` dimensioned between the nose gear and the main gear | `theta > theta_LOF ~= 15 deg` |
| Lateral Ground Clearance Criterion | Four-engine transport front view. `TRACK` dimensioned between the main gear feet | `phi > 5 deg`, with the note "TIRES AND STRUTS DEFLATED" |

The same page carries an uncaptioned three-view of the McDonnell Douglas AV-8B with the note "NOTE
OUTRIGGER GEAR". It is the outrigger example referenced from p. 218. Drawing only. No plotted data.

---

#### Decisions that follow from the two criteria

With the geometric criteria in mind, make these decisions [Roskam II, p. 220]:

1. Number, location and length of **main** gear struts:
   a. under the wing
   b. under the fuselage
   c. both (as in the 747 and DC 10-30)
2. Number, location and length of **nose** gear struts. Usually only one strut, at the forward end
   of the fuselage.

Make the first decision by comparison with competitive concepts (the configurations of Chapter 3).

Strut length has a major effect on [Roskam II, p. 220]:

* the weight of the landing gear
* the ground clearance of the airplane with deflated tires and struts
* the tip-over characteristics
* overall airplane stability during ground operation

### Step 9.5 — Maximum static load per strut

Class I equations for the maximum static load per strut.

**1. Tricycle landing gears** [Roskam II, Eqs. (9.1) and (9.2), p. 222]:

Nose wheel strut:

```
P_n = (W_TO * l_m) / (l_m + l_n)                                  (9.1)
```

Main gear strut:

```
P_m = (W_TO * l_n) / (n_s * (l_m + l_n))                          (9.2)
```

**2. Taildragging landing gears:** replace the subscript `n` by `t` in Eqs. (9.1) and (9.2), and use
Fig. 9.2b [Roskam II, p. 222].

Symbols, defined by Figs. 9.2a and 9.2b, p. 223:

| Symbol | Meaning | Units |
|---|---|---|
| `W_TO` | take-off gross weight | lbs |
| `l_m` | horizontal distance from the **c.g.** to the **main gear** ground contact point | in. (any consistent length unit) |
| `l_n` | horizontal distance from the **nose gear** ground contact point to the **c.g.** | in. |
| `l_m + l_n` | wheel base, nose gear to main gear | in. |
| `n_s` | number of main gear **struts** | — |
| `P_n` | static load on the nose gear strut | lbs |
| `P_m` | static load on **one** main gear strut | lbs |

`P_n` is the load on the full nose gear. `P_m` is the load on one main strut only. The total main
gear load is `n_s * P_m`.

`l_m` is the SHORT arm (c.g. to main gear). `l_n` is the LONG arm (nose gear to c.g.). The worked
examples of §9.2 confirm this reading. Ourania has `W_TO = 127,000 lb`, `l_m = 60 in.`,
`l_n = 520 in.`, `n_s = 2`. Then `P_n = 127,000*60/580 = 13,138 lb` and
`P_m = 127,000*520/(2*580) = 56,931 lb`. Both agree exactly with the printed values on p. 231.

For the taildragger form, `l_t` is the distance from the c.g. back to the tailwheel, and `l_m` stays
the distance from the main gear to the c.g. Fig. 9.2b shows `l_m` short at the main gear and `l_n`
long back to the tailwheel.

### Figure 9.2a — Geometry for Static Load Calculation for Tricycle Gears
*[Roskam II, Fig. 9.2a, p. 223]* — DC-9 / F-28-type side view on the ground line. Reaction `P_n` up
at the nose gear, `P_m * n_s` up at the main gear, `W_TO` down at the c.g. Dimensions: `l_n` from
nose gear to c.g., `l_m` from c.g. to main gear, `l_m + l_n` from nose gear to main gear. Definition
sketch. No plotted data.

### Figure 9.2b — Geometry for Static Load Calculation for Taildraggers
*[Roskam II, Fig. 9.2b, p. 223]* — Cessna-type taildragger side view. `n_s P_m` up at the main gear,
`P_n` up at the tailwheel, `W_TO` down at the c.g. `l_m` from main gear to c.g., `l_n` from c.g. back
to the tailwheel, `l_m + l_n` from main gear to tailwheel. The drawing also carries `3 deg 30'` and
`12 deg` from the source three-view. Definition sketch. No plotted data.

### Step 9.6 — Decide the number of wheels

Usual numbers [Roskam II, p. 222]:

* tailwheels: **one**
* nosewheels: **one or two**
* main gears: the number depends on
  1. load per tire and the associated surface bearing strength
  2. consequences of a tire blow-out
  3. cost

Tables 9.1 and 9.2 give guidance.

### Step 9.7 — Compute the load ratios and select the tire size

Compute `P_n/W_TO` and `n_s*P_m/W_TO`. Then select the approximate tire size from Table 9.1 or
Table 9.2 [Roskam II, p. 222].

### Step 9.8 — Locate the tires

Draw the tires into the general arrangement of Step 10, Chapter 2. **Draw the tires to the proper
scale** (the book's own emphasis) [Roskam II, p. 222].

### Step 9.9 — Check retraction

Make sure the gear as configured can retract into the designated retraction volume(s). Verify the
retraction capability with a "stick diagram" (Fig. 9.3) [Roskam II, pp. 222, 225].

### Step 9.10 — Weight and balance loop

With the gear layout defined, go to Chapter 10, do the weight and balance calculation, and if
necessary iterate back to Step 9.3, until the gear location satisfies all criteria
[Roskam II, p. 225].

### Step 9.11 — Document

Document the decisions of Steps 9.1 through 9.10 in a brief descriptive report with clear
dimensioned drawings [Roskam II, p. 225].

---

### Table 9.1 — Typical Landing Gear Wheel Data (n_s = 2)
*[Roskam II, Table 9.1, p. 224]*

Column meanings. `W_TO` in lbs. `D_t x b_t` = tire outside diameter x tire width, in. x in.
`2P_m/W_TO` = the fraction of **take-off gross weight** carried by the **two main gear struts
together** (this is `n_s*P_m/W_TO` with `n_s = 2`). `PSI` = tire inflation pressure, lb/in^2.
`n_mt` = number of main gear tires **per strut**. `P_n/W_TO` = the fraction of **take-off gross
weight** carried by the **nose gear**. `n_nt` = number of nose gear tires.

| Type | W_TO (lbs) | Main D_t x b_t (in.) | Main 2P_m/W_TO | Main PSI | n_mt | Nose D_t x b_t (in.) | Nose P_n/W_TO | Nose PSI | n_nt |
|---|---|---|---|---|---|---|---|---|---|
| Homebuilts | 600 | 13x5 | 0.80 | 25 | 1 | 9x3.4 | 0.17 | 25 | 1 |
| | 1,200 | 12x5 | 0.78 | 45 | 1 | 12x5 | 0.22 | 45 | 1 |
| | 3,300 | 16x6 | 0.87 | 45 | 1 | 16x6 | 0.13 | 45 | 1 |
| Single Engine Prop. Driven | 1,600 | 15x6 | 0.80 | 18 | 1 | 15x5 | 0.20 | 28 | 1 |
| | 2,400 | 17x6 | 0.84 | 19 | 1 | 12.5x5 | 0.16 | 22 | 1 |
| | 3,800 | 16.5x6 | 0.84 | 55 | 1 | 14x5 | 0.16 | 49 | 1 |
| Twin Engine Prop. Driven | 5,000 | 16x6 | 0.83 | 55 | 1 | 16x6 | 0.17 | 40 | 1 |
| | 8,000 | 22x6.5 | 0.88 | 75 | 1 | 17x6 | 0.12 | 40 | 1 |
| | 12,000 | 26.6x7 | 0.84 | 82 | 1 | 19.3x6.6 | 0.16 | 82 | 1 |
| Agricultural | 3,000 | 22x8 | 0.95 | 35 | 1 | 9x3.5* | 0.05* | 55* | 1* |
| | 7,000 | 24x8.5 | 0.92 | 35 | 1 | 12.4x4.5* | 0.08* | 50* | 1* |
| | 10,000 | 29x7.5 | 0.85 | 35 | 1 | 25x7 | 0.15 | 35 | 1 |
| Regional Turbopropeller Driven Airplanes | 12,500 | 18x5.5 | 0.89 | 105 | 2 | 22x6.75 | 0.11 | 57 | 1 |
| | 21,000 | 24x7.25 | 0.90 | 85 | 2 | 18x5.5 | 0.10 | 65 | 2 |
| | 26,000 | 36x11 | 0.92 | 40 | 1 | 20x7.5 | 0.08 | 40 | 1 |
| | 44,000 | 30x9 | 0.93 | 107 | 2 | 23.4x6.5 | 0.07 | 77 | 2 |
| Business Jets | 12,000 | 22x6.3 | 0.93 | 90 | 1 | 18x5.7 | 0.07 | 120 | 1 |
| | 23,000 | 27.6x9.3 | 0.95 | 155 | 1 | 17x5.5 | 0.05 | 50 | 2 |
| | 39,000 | 26x6.6 | 0.92 | 208 | 2 | 14.5x5.5 | 0.08 | 130 | 2 |
| | 68,000 | 34x9.25 | 0.93 | 174 | 2 | 21x7.25 | 0.07 | 113 | 2 |

`*` A note is printed inside the table between the 7,000 lb and 10,000 lb Agricultural rows: "these
are tailwheel data". So for the two Agricultural rows marked `*`, the "Nose Gear" columns are
tailwheel columns.

### Table 9.2 — Typical Landing Gear Wheel Data (n_s = 2 unless otherwise noted)
*[Roskam II, Table 9.2, p. 224]*

Column meanings are the same as Table 9.1, but the main gear load column is printed as
`n_s*P_m/W_TO`: the fraction of **take-off gross weight** carried by **all** main gear struts
together.

| Type | W_TO (lbs) | Main D_t x b_t (in.) | Main n_s*P_m/W_TO | Main PSI | n_mt | Nose D_t x b_t (in.) | Nose P_n/W_TO | Nose PSI | n_nt |
|---|---|---|---|---|---|---|---|---|---|
| Transport Jets | 44,000 | 34x12 | 0.89 | 75 | 2 | 24x7.7 | 0.11 | 68 | 2 |
| | 73,000 | 40x14 | 0.92 | 77 | 2 | 29.5x6.75 | 0.08 | 68 | 2 |
| | 116,000 | 40x14 | 0.94 | 170 | 2 | 24x7.7 | 0.06 | 150 | 2 |
| | 220,000 | 40x14 | 0.94 | 180 | 4 | 29x7.7 | 0.06 | 180 | 2 |
| | 330,000 | 46x16 | 0.93 | 206 | 4 | 40x14 | 0.07 | 131 | 2 |
| | 572,000 | 52x20.5 | 0.93 | 200 | 4* | 40x15.5 | 0.07 | 190 | 2 |
| | 775,000 | 49x17 | 0.94 | 205 | 4** | 46x16 | 0.06 | 190 | 2 |
| Military Trainers | 2,500 | 17x6 | 0.82 | 36 | 1 | 13.5x5 | 0.18 | 28 | 1 |
| | 5,500 | 20.3x6.5 | 0.91 | 60 | 1 | 14x5 | 0.09 | 40 | 1 |
| | 7,500 | 20.25x6 | 0.92 | 65 | 1 | 17.2x5.0 | 0.08 | 45 | 1 |
| | 11,000 | 23.3x6.5 | 0.90 | 143 | 1 | 17x4.4 | 0.10 | 120 | 1 |
| Fighters | 9,000 | 20x5.25 | 0.86 | 135 | 1 | 17x3.25 | 0.14 | 82 | 1 |
| | 14,000 | 18.5x7 | 0.87 | 110 | 1 | 18x6 | 0.13 | 37 | 1 |
| | 25,000 | 24x8 | 0.91 | 210 | 1 | 18x6.5 | 0.09 | 120 | 1 |
| | 35,000 | 24x8 | 0.90 | 85 | 2 | 21.5x9.8 | 0.10 | 57 | 1 |
| | 60,000 | 35.3x9.3 | 0.88 | 210 | 1 | 21.6x7.5 | 0.12 | 120 | 2 |
| | 92,000 | 42x13 | 0.93 | 150 | 1 | 20x6.5 | 0.07 | 120 | 2 |

Notes printed under Table 9.2 [Roskam II, p. 224]:

* For Flying Boats, Amphibious and Float Airplanes, and also for Supersonic cruise airplanes, use
  jet transport data.
* `*` three main gear struts: `n_s = 3`
* `**` four main gear struts: `n_s = 4`
* All other airplanes have `n_s = 2`: two main gear struts.

**Load-fraction range that the two tables give.** In every category, the nose gear carries about
**0.05 to 0.22 of W_TO**, and the main gears together carry about **0.78 to 0.95 of W_TO**.
Transport jets and fighters group near `P_n/W_TO = 0.06 to 0.14`. These are fractions of
**take-off gross weight**, not of empty weight.

### Figure 9.3 — Typical Gear Retraction Stick Diagrams
*[Roskam II, Fig. 9.3, p. 225]* — Six kinematic stick diagrams of main gear retraction linkages:
strut, drag brace, actuator, wheel, dashed retracted position, and the swept path. Annotations on
the figure: "COPIED FROM: LANDING GEAR DESIGN HANDBOOK BY: N.S. CURREY" and "COURTESY OF: LOCKHEED
GEORGIA CO." Kinematic sketches only. No numeric or plotted data, so nothing was digitized.

---

## §9.2 Example Applications

Three examples [Roskam II, p. 226]:

* §9.2.1 Twin Engine Propeller Driven Airplane: **Selene**
* §9.2.2 Jet Transport: **Ourania**
* §9.2.3 Fighter: **Eris**

### §9.2.1 Twin Engine Propeller Driven Airplane (Selene)

* Step 9.1: the 250 kts cruise speed requirement of Table 2.17 (Part I) gives a **retractable** gear
  [Roskam II, p. 226].
* Step 9.2: a conventional **tricycle** gear.
* Step 9.3: see Sub-section 10.2.1, Chapter 10.
* Step 9.4: three main gear position options were laid out. Option 1 (Fig. 9.4) is wing/nacelle
  mounted. Options 2 and 3 (Figs. 9.5 and 9.6) are fuselage mounted. The wing/nacelle option gives
  long struts, retraction forward and under the wing into a lower wing/nacelle fairing, a wide
  track, and no lateral stability problem, but a fairly heavy gear. The fuselage-mounted options use
  a "fighter" type gear that retracts into the fuselage. Option 3 gives better lateral stability,
  and is very similar to the MiG-23 gear [Roskam II, p. 226].
* Step 9.5 [Roskam II, p. 230]:

```
l_m = 34 in.,  l_n = 171 in.,  n_s = 2
P_n = 1,310 lbs      P_m = 3,295 lbs
P_n/W_TO = 0.17      2P_m/W_TO = 0.83
```

  These agree with Eqs. (9.1) and (9.2) for `W_TO ~= 7,900 lb`. The page does not print `W_TO`.
* Step 9.6: Table 9.1 shows that **one** nose wheel tire and **one** main gear tire per strut are
  acceptable choices.
* Step 9.7 [Roskam II, p. 230]:

```
Nosewheel tire:  D_t x b_t = 17x6      with  40 psi
Main gear tire:  D_t x b_t = 22x6.5    with  85 psi
```

* Step 9.9: nose gear retraction does not conflict with primary structure. For Option 3, a blister
  fairing is necessary on the fuselage.
* Step 9.10: the gear configuration is satisfactory for weight and balance. Only the take-off
  rotation still needs verification, as part of Class II stability and control (Part VII).

### Figures 9.4 to 9.8 — Selene
*[Roskam II, pp. 227–229]*

| Figure | Caption | Content and data |
|---|---|---|
| 9.4 | Selene: Main Gear Arrangement: Option 1 | Wing/nacelle mounted gear, side view. `7.8 FT` from the wing/nacelle to the prop centreline. `16 deg` between the compressed and extended strut positions. Layout sketch |
| 9.5 | Selene: Main Gear Arrangement: Option 2 | Fuselage mounted. Front view plus plan view. Labels "TILTED PIVOT", "BLISTER FAIRING", "LEVEL GROUND", `F.S. 301.5`. Layout sketch |
| 9.6 | Selene: Main Gear Arrangement: Option 3 | Three-panel retraction sequence into the fuselage. Layout sketch. No dimensions |
| 9.7 | Selene: Nose Gear arrangement | Nose gear retraction into the nose. F.S. scale marked 80 / 100 / 120 / 140 in. Layout sketch |
| 9.8 | Selene: Tip-over Criteria | Plan view plus side view tip-over check. Shows `15 deg` (longitudinal), `psi` with `l_psi` the perpendicular distance, and `56 deg` at the c.g. F.S. scale 100 / 200 / 300 in. Labels "OPTION 3 O.K.", "OPTION 1 NOT O.K.", "MOST FWD", "MOST AFT" |

These are layout and check drawings. The only reusable numbers are the criterion angles already
captured above.

**Possible inconsistency.** Fig. 9.8 marks `56 deg` for the accepted Option 3, but Fig. 9.1a prints
`psi <= 55 deg`. The text on p. 226 says the Selene meets the tip-over criteria of Fig. 9.1a.
Recorded as printed. Not resolved here.

### §9.2.2 Jet Transport (Ourania)

* Step 9.1: the high cruise speed requirement of Table 2.18 (Part I) gives a **retractable** gear
  [Roskam II, p. 231].
* Step 9.2: a conventional **tricycle** gear.
* Step 9.4: only one option. The main gear goes under the rear spar and retracts into the fuselage,
  very similar to the B737. The nose gear retracts forward into the nose.
* Step 9.5 [Roskam II, p. 231]:

```
l_m = 60 in.,  l_n = 520 in.,  n_s = 2,  W_TO = 127,000 lbs
P_n = 13,138 lbs     P_m = 56,931 lbs
P_n/W_TO = 0.10      2P_m/W_TO = 0.90
```

* Step 9.6: Table 9.2 shows that **two** nose wheel tires and **two** main gear tires per strut are
  acceptable choices.
* Step 9.7 [Roskam II, p. 233]:

```
Nosewheel tire:  D_t x b_t = 24x7.7    with  180 psi
Main gear tire:  D_t x b_t = 40x14     with  180 psi
```

* Step 9.9: retraction does not conflict with primary structure or with the flaps. A "yehudi" was
  added to the wing planform to accommodate the main gear. The yehudi carries the inboard flaps.
  Boeing pioneered this arrangement on the 707 [Roskam II, p. 233].

### Figures 9.9 and 9.10 — Ourania
*[Roskam II, pp. 232–233]*

| Figure | Caption | Content and data |
|---|---|---|
| 9.9 | Ourania: Landing Gear Arrangement | Plan and side layout with component c.g. crosses (fixed eqpmt, pax + lug, fuel, powerplant inst., nacelle, M.G., N.G., wing / fuselage / vertical tail planform, TFO). Fuselage stations `F.S. 151`, `392`, `1,129`, `1,311`. `W.L. 78` is level ground. `13 deg` and `15 deg` clearance / tip-over angles. `YEHUDI` labelled. Layout drawing |
| 9.10 | Ourania: Tip-over Criteria | `12 deg` longitudinal at the M.G. relative to the c.g. at `W.L. 224`. `psi = 55 deg`. `146` in. perpendicular offset. `F.S. 315` (N.G.), `F.S. 893` (M.G.). Ground level `W.L. 78` |

Layout and check drawings. There is no plotted design chart to digitize.

**Note.** The longitudinal angle marked in Fig. 9.10 is `12 deg`, not the `~15 deg` value of
Fig. 9.1a. Roskam describes 15 deg as the "usual" relation, not as a minimum, so a smaller angle is
not by itself a violation. Recorded as printed.

### §9.2.3 Fighter (Eris)

* Step 9.1: the high cruise speed requirement of Table 2.19 (Part I) gives a **retractable** gear
  [Roskam II, p. 234].
* Step 9.2: a conventional **tricycle** gear.
* Step 9.4: only one option. The main gear goes under the fuselage and retracts into the fuselage
  below the engine bays. This is typical for modern jet fighters.
* Step 9.5 [Roskam II, p. 234]:

```
l_m = 20 in.,  l_n = 185 in.,  n_s = 2,  W_TO = 64,905 lbs
P_n = 6,332 lbs      P_m = 29,286 lbs
P_n/W_TO = 0.10      2P_m/W_TO = 0.90
```

* Step 9.6: Table 9.2 shows that **two** nose wheel tires and **one** main gear tire per strut are
  acceptable choices.
* Step 9.7 [Roskam II, p. 236]:

```
Nosewheel tire:  D_t x b_t = 21.6x7.5   with  120 psi
Main gear tire:  D_t x b_t = 35.3x9.3   with  210 psi
```

* Step 9.9: retraction does not conflict with primary structure.

### Figures 9.11 and 9.12 — Eris
*[Roskam II, pp. 235–236]*

| Figure | Caption | Content and data |
|---|---|---|
| 9.11 | Eris: Landing Gear Arrangement | Nose gear at `F.S. 141`, retracting forward. Main gear at `F.S. 346`. Ground level `W.L. 17`. Layout sketch |
| 9.12 | Eris: Tip-over Criteria | Plan-view lateral tip-over check. `82 IN.` perpendicular from the c.g. to each nose-gear-to-main-gear line. `56 deg` and `57 deg` at the c.g. `F.S. 141` (N.G.), `F.S. 346` (M.G.), `F.S. 326` is the `W_TO` c.g. Ground level `W.L. 17`. `W_TO` c.g. is at `W.L. 99` |

Layout and check drawings.

**Possible inconsistency.** Fig. 9.12 marks `56 deg` and `57 deg`, but Fig. 9.1a prints
`psi <= 55 deg`. The text on p. 234 says the Eris meets the tip-over criteria of Fig. 9.1a.
Recorded as printed. Not resolved here.

---

## Summary of citable criteria

| Quantity | Value | Applies to | Status |
|---|---|---|---|
| Fixed-gear drag cut-off cruise speed | 150 kts | all | rule of thumb [p. 217] |
| Longitudinal tip-over angle, main gear to critical c.g. | ~15 deg | tricycle (aft c.g.), taildragger (fwd c.g.) | "usual" relation, rule of thumb [pp. 218–219] |
| Lateral tip-over angle `psi` | `<= 55 deg` | tricycle (at the most fwd c.g.), taildragger (at the most aft c.g.) | rule of thumb [pp. 219, 220] |
| Longitudinal ground clearance `theta` | `> theta_LOF ~= 15 deg` | tricycles only | rule of thumb. Check with tires and struts deflated [pp. 220–221] |
| Lateral ground clearance `phi` | `> 5 deg` | tricycles and taildraggers | rule of thumb. Check with tires and struts deflated [pp. 220–221] |
| Nose gear static load fraction `P_n/W_TO` | ~0.05 to 0.22 (0.06 to 0.14 for jets and fighters) | all | data range from Tables 9.1 and 9.2. Fraction of **take-off gross weight** [p. 224] |
| Total main gear static load fraction `n_s*P_m/W_TO` | ~0.78 to 0.95 | all | data range from Tables 9.1 and 9.2. Fraction of **take-off gross weight** [p. 224] |

Chapter 9 does not cite a FAR paragraph anywhere. Every angle and every load fraction above is
Roskam's own design guidance, or a data range read from his statistical tables. None of them is a
certification requirement.
