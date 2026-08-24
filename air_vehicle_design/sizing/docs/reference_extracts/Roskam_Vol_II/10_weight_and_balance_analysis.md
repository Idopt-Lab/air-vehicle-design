# Chapter 10 — Class I Weight and Balance Analysis

**Source:** J. Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration
of the Propulsion System*, Chapter 10 "Class I Weight and Balance Analysis," printed pp. 237–258
(PDF idx 248–269).

The chapter has **no numbered equations**. All equations are printed inside Table 10.1a and
Table 10.1b as summation definitions. This extract reproduces them with a local `(10-x)` tag so
that code can cite them; the tag is **this extract's**, not the book's. Every table is captured
cell by cell. Every weight-fraction and c.g. figure states what it is a fraction OF.

**Method scope:** a rapid check that the centre of gravity of the proposed airplane is "in the
right place" for the different loading scenarios. It is Step 10 of p.d. sequence I (Chapter 2).
Section 10.1 gives a 9-step procedure. Section 10.2 gives three worked examples.

---

## Notation and sign conventions

| Symbol | Meaning | Units |
|---|---|---|
| `W_i` | weight of component `i` | lbs |
| `x_i`, `y_i`, `z_i` | c.g. coordinates of component `i` | in. |
| `W_i·x_i`, `W_i·y_i`, `W_i·z_i` | component moments | in.lbs |
| `W_E` | empty weight | lbs |
| `W_OE` | operating weight empty | lbs |
| `W_TO` | take-off weight | lbs |
| `x_cg`, `y_cg`, `z_cg` | airplane c.g. coordinates | in. |
| `c̄_w`, `c̄_h`, `c̄_v` | wing / horizontal tail / vertical tail mean geometric chord | in. |
| `l` | length of the item named (nacelle length, fuselage length) | in. |
| F.S. | fuselage station = the **x** coordinate | in. |
| B.L. or W.B.L. | wing buttock line = the **y** coordinate | in. |
| W.L. | water line = the **z** coordinate (term carried over from ship building) | in. |

**Zero reference point (p. 238, CAUTION).** Pick the zero reference point so that ALL coordinates
are positive, and keep them positive for future growth versions of the airplane. Put the zero
reference point well to the left of, and well below, the nose. Roskam states that sign errors from
a badly chosen origin are a common industry and student mistake.

Some airplanes have a strong asymmetry in the weight distribution. For those airplanes you must
also find the **y** locations of the component c.g.'s (p. 238; the Eris example, Table 10.6, has a
gun at y = −20 in. and a nose gear at y = +16 in.).

---

## §10.1 Class I Weight and Balance Method

The method is a 9-step procedure.

### Step 10.1 — Component weight breakdown

Use a Class I component weight prediction method (Part V, Chapter 2) to get the initial component
weight breakdown. Table 10.1a lists the components that a Class I breakdown normally has.

### Table 10.1a — Typical Class I Component Weight Breakdown
*[Roskam Part II, Table 10.1a, p. 237]*

| No. | Component | No. | Component |
|---|---|---|---|
| 1 | Fuselage group | 9 | Fuel |
| 2 | Wing group | 10 | Passengers |
| 3 | Empennage group | 11 | Baggage |
| 4 | Engine group | 12 | Cargo |
| 5 | Landing gear group | 13 | Military load |
| 6 | Fixed equipm't group | | |
| 7 | Trapped fuel and oil | | |
| 8 | Crew | | |

Weight roll-ups printed with the table (p. 237). The index ranges are the row numbers above.

    Empty weight:                W_E  = Sum W_i , i = 1 to 6                          (10-1)

    Operating weight empty:      W_OE = Sum W_i , i = 1 to 8                          (10-2)

    Take-off weight:             W_TO = Sum W_i , i = 1 to 13                         (10-3)

So, by this book's definition: `W_E` **excludes** trapped fuel and oil (TFO) and crew;
`W_OE` = `W_E` + TFO + crew; `W_TO` = `W_OE` + fuel + payload (passengers, baggage, cargo,
military load).

### Step 10.2 — Preliminary arrangement drawing

Make the preliminary arrangement drawing from the drawings of Chapters 5–9. Draw a three-view if
the configuration is asymmetric. A side view alone is enough for many symmetric airplanes.

### Fig. 10.1 — Preliminary Configuration Arrangement
*[Roskam Part II, Fig. 10.1, p. 239]* — Three-view (top, front, side) of a twin-boom
push-pull light twin, of Cessna Skymaster type. Each component c.g. is marked with an `X` and the
Table 10.1a item number: 1) fuselage, 2) wing, 3) empennage, 4) engine, 5a) nose gear, 5b) main
gear, 6) fixed equipment, 7) trapped fuel and oil, 8) crew, 9) fuel, 10) passengers, 13) military
load (a wing store). The axes are drawn as x (F.S.) with the origin ahead of the nose, ±y (B.L.)
about the centreline, and z (W.L.) with the origin below the airplane. A 13°0' tail-down angle is
dimensioned in the side view. Layout drawing — no plotted data.

### Step 10.3 — Locate the component c.g.'s

Mark the c.g. of every Class I weight component on Figure 10.1. At this point the drawing is also
called a **'c.g. three-view'**.

### Step 10.4 — Tabulate the coordinates

Enter the x, y and z coordinates of each component c.g. in a table like Table 10.1b. Table 10.2
gives guidance for the c.g. location of the major weight groups.

### Table 10.1b — Class I Weight and Balance Calculation
*[Roskam Part II, Table 10.1b, p. 240]*

| No. | Type of Component | W_i (lbs) | x_i (in.) | W_i·x_i (in.lbs) | y_i (in.) | W_i·y_i (in.lbs) | z_i (in.) | W_i·z_i (in.lbs) |
|---|---|---|---|---|---|---|---|---|
| 1 | Fuselage group | W_1 | x_1 | W_1·x_1 | y_1 | W_1·y_1 | z_1 | W_1·z_1 |
| 2 | Wing group | | | | | | | |
| 3 | Empennage group | | | | | | | |
| 4 | Engine group | | | | | | | |
| 5 | Landing gear group | | | | | | | |
| 6 | Fixed equipm't group | | | | | | | |
| — | **Empty weight:** `W_E = Sum W_i , i = 1 to 6` | | | | | | | |
| 7 | Trapped fuel and oil | | | | | | | |
| 8 | Crew | | | | | | | |
| — | **Operating weight empty:** `W_OE = Sum W_i , i = 1 to 8` | | | | | | | |
| 9 | Fuel | | | | | | | |
| 10 | Passengers | | | | | | | |
| 11 | Baggage | | | | | | | |
| 12 | Cargo | | | | | | | |
| 13 | Military load | | | | | | | |
| — | **Take-off weight:** `W_TO = Sum W_i , i = 1 to 13` | | | | | | | |

The c.g. equations printed in the right of Table 10.1b (p. 240):

    x_cg|W_E  = (Sum W_i·x_i , i = 1 to 6 ) / W_E                                     (10-4)

    x_cg|W_OE = (Sum W_i·x_i , i = 1 to 8 ) / W_OE                                    (10-5)

    x_cg|W_TO = (Sum W_i·x_i , i = 1 to 13) / W_TO                                    (10-6)

**Note printed under the table:** the locations for `y_cg` and for `z_cg` are found from similar
equations (that is, replace `x_i` by `y_i` or `z_i`, and keep the same divisor weight).

The divisor of each c.g. equation is the SAME weight that its numerator sums to. `x_cg|W_E` is a
fraction of nothing — it is an absolute fuselage station in inches, measured from the zero
reference point of Fig. 10.1. It is **not** a fraction of fuselage length and **not** a fraction
of MAC. Conversion to a MAC fraction only happens in Step 10.6, in the excursion diagram.

### Table 10.2 — Location of C.G.'s of Major Components
*[Roskam Part II, Table 10.2, p. 241]*

This table is drawn, not typeset. Each entry is a dimensioned sketch. Reference datum and
direction are given here explicitly because they decide whether an implementation is right.

| Component | c.g. location | Measured from | Measured along |
|---|---|---|---|
| Wings | 0.37 – 0.42 `c̄_w` | leading edge of the wing mean geometric chord `c̄_w` | aft, parallel to the chord |
| Horizontal stabilizer | 0.30 `c̄_h` | leading edge of the horizontal tail mean geometric chord `c̄_h` | aft |
| Vertical stabilizer | 0.30 `c̄_v` | leading edge of the vertical tail mean geometric chord `c̄_v` | aft |
| Nacelles | 0.4 `l` | forward end (nose) of the nacelle, `l` = nacelle length | aft |
| Fuselage — canopy type | 0.26 `l` | nose of the fuselage, `l` = fuselage length | aft |
| Fuselage — cabin type | 0.39 `l` | nose of the fuselage, `l` = fuselage length | aft |
| Fuselage — airliners | 0.45 – 0.50 `l` | nose of the fuselage, `l` = fuselage length | aft |

Reading of the sketches:
- **WINGS.** Trapezoidal half-planform with the root chord on the centreline and FWD up. `c̄_w` is
  dimensioned as a full chord. The dimension `0.37 – 0.42 c̄_w` starts at the LEADING EDGE end of
  `c̄_w` and ends at the `X`. So the wing group c.g. is 37 % to 42 % of `c̄_w` aft of the MAC
  leading edge.
- **STABILIZERS.** The horizontal sketch has the root chord on the centreline, FWD up; the
  vertical sketch is a side view with FWD to the left. Both put the `X` at 0.30 of the surface MAC
  aft of that MAC's leading edge.
- **NACELLES.** Side view of a nacelle plus wing section, FWD to the left. `l` is the whole
  nacelle length; the `X` is at 0.4 `l` aft of the nacelle nose.
- **FUSELAGES.** Two side-view outlines. "CANOPY TYPE" (fighter/trainer, blister canopy) puts the
  `X` at 0.26 `l`. "CABIN TYPE" (cabin nose, upswept aft body) puts the `X` at 0.39 `l`. A written
  note beside the cabin sketch reads `AIRLINERS: 0.45 – 0.50 l`. In all three, `l` is measured
  from the nose to the aft end of the fuselage, and the c.g. is measured aft from the nose.

Further guidance on component c.g. location is in Part V (Ref. 4), Chapter 2.

### Step 10.5 — Compute the airplane c.g. for every loading scenario

Compute `x_cg`, `y_cg` and `z_cg` with Table 10.1b. Do this for **all** feasible loading
scenarios. The scenarios depend on the mission.

Typical loading **combinations** (p. 242):

| # | Loading combination |
|---|---|
| 1 | Empty weight |
| 2 | Empty weight + crew |
| 3 | Empty weight + crew + fuel |
| 4 | Empty weight + crew + fuel + payload = Take-off weight |

Those four combinations give six loading **sequences** — that is, six different orders in which
the loads can be put on or taken off (p. 242, printed exactly as below):

| | | |
|---|---|---|
| 1 2 3 4 | 1 3 2 4 | 1 4 2 3 |
| 1 2 4 3 | 1 3 4 2 | 1 4 3 2 |

In practice there can be many more. The number depends on:
1. the type of payload and how it can be stowed (for example, passengers boarding a Boeing 747);
2. how the fuel tankage is arranged and how the fuel can be sequenced in and out.

### Step 10.6 — Construct the weight–c.g. excursion diagram

Figure 10.2 is the example. The diagram must identify the loading sequences and the critical
weights `W_E` and `W_TO`. The c.g. locations are plotted **twice**, on two parallel horizontal
scales:
1. in terms of fuselage station (F.S.), in inches; **and**
2. in terms of a fraction of the wing mean geometric chord, `c̄_w`.

The main landing gear location is also marked on the diagram. That mark shows whether there is a
longitudinal 'tip-over' problem (p. 244).

For some airplanes it is also useful to draw c.g. excursion diagrams for the vertical and the
lateral c.g. Those can change the landing gear disposition because of lateral tip-over.

### Fig. 10.2 — Weight–C.G. Excursion Diagram (generic)
*[Roskam Part II, Fig. 10.2, p. 243]*

Construction, as drawn:
- **Vertical axis:** WEIGHT ~ LBS. Two horizontal reference lines are drawn, at `W_E` (low) and at
  `W_TO` (top). A third line, `OWE`, sits just above `W_E`.
- **Horizontal axes:** two scales, one above the other. The upper scale is `FR. c̄_w` and is
  labelled `0` at the leading edge of `c̄` (`L.E. c̄`) and `1.0` at the trailing edge (`T.E. c̄`).
  The lower scale is `X (F.S.) ~ IN.` The caption under the axis reads
  "C.G. LOCATION ~ IN. AND FR. c̄_w".
- **Start point:** the `W_E` point, plotted at the `x_cg|W_E` station.
- **Order of adding loads.** From `W_E`, the first small step is `CREW + TFO`, which gives the
  `OWE` point. From `OWE` the diagram splits into TWO branches, so a closed loop (a diamond) is
  drawn:
  - **Left branch (forward-most):** add `FUEL` first (arrow up and to the left), then
    `PAX + BAG` (arrow up and to the left) to reach `W_TO`.
  - **Right branch (aft-most):** add `PAX + BAG` first (arrow up and to the right), then `FUEL`
    (arrow up and to the left) to reach `W_TO`.
  Both branches end at the same `W_TO` point, because the total loaded weight and total moment do
  not depend on the order. Only the intermediate c.g. positions depend on the order.
- **How the limits fall out.** Drop a vertical line from the LEFT-most point of the whole loop:
  that is the `MOST FWD` c.g. Drop a vertical line from the RIGHT-most point: that is the
  `MOST AFT` c.g. Both are labelled with arrows on the diagram. The main gear station `M.G.` is
  marked with an open triangle on the same axis, to the right of the aft limit.

The forward and aft limits are therefore the envelope of ALL loading sequences, not the c.g. of
any single weight condition. This is why Step 10.5 says every feasible scenario must be computed.

### Step 10.7 — Determine the most forward and most aft c.g., and compare

Read the most forward and most aft c.g. from the excursion diagram. Compare the resulting c.g.
range with the c.g. ranges of other airplanes in the same category, using Table 10.3.

### Table 10.3 — Examples of Center of Gravity Ranges
*[Roskam Part II, Table 10.3, p. 243]*

"C.G. Range" is the **total travel** of the c.g. — the aft limit minus the forward limit. The
first column is that travel in **inches** (an absolute length along the fuselage station axis).
The second column is the same travel as a **fraction of the wing mean geometric chord `c̄_w`**.
It is not a fraction of take-off weight, empty weight or fuselage length.

| Type | C.G. Range (in.) | C.G. Range (fr. c̄_w) |
|---|---|---|
| Homebuilts | 5 | 0.10 |
| Single Engine Prop. Driven | 7–18 | 0.06–0.27 |
| Twin Engine Prop. Driven | 9–15 | 0.12–0.22 |
| Ag. Airpl. | 5 | 0.10 |
| Business Jets | 8–17 | 0.10–0.21 |
| Regional TBP | 12–20 | 0.14–0.27 |
| Jet Transp. | 26–91 | 0.12–0.32 |
| Military Trainers | 8 | 0.10 |
| Fighters | 15 | 0.20 |
| Mil.Patr. Bomb and Transp. | 26–90 | 0.30 |
| Fl.Boats, Amph. and Float / Amph. and | 7–28 | 0.25 |
| Supersonic Cruise | 20–100 | 0.30 |

**Printing anomaly.** In the right-hand half of the table the row label is printed over four lines
as `Fl.Boats,` / `Amph. and` / `Float` / `Amph. and`, but only one pair of numbers (`7–28`,
`0.25`) is printed, on the `Fl.Boats,` line. The trailing `Amph. and` (which sits alongside the
`Regional TBP` row of the left half) appears to be a typesetting overrun of the category name
"Flying Boats, Amphibious and Float Airplanes". Verified at 500 dpi. Treat it as ONE row.

### Step 10.8 — Judge the feasibility of the arrangement, and change it if necessary

Four principles (pp. 244–245):

**Principle 1.** Where possible, the ideal c.g. arrangement is one where the OWE c.g., the fuel
c.g. and the payload c.g. are at the same vertical location — that is, at the same fuselage
station. Most designs cannot reach this ideal. Get as close as you can. (When the three c.g.'s
coincide, the excursion loop collapses to a vertical line and the c.g. range goes to zero.)

**Principle 2.** Put the landing gear where no major structural cutouts are needed to retract the
gear. Make sure there is enough volume to retract the gear into.

**Principle 3.** The airplane must also meet basic stability and control requirements (Step 12 of
p.d. sequence I). There are two types of airplane:
1. Airplanes that MUST have inherent static longitudinal and static directional stability. Use the
   X-plot method of Step 12 together with the Class I weight and balance analysis. Without the
   minimum static stability levels the proposed design is **invalid**.
2. Airplanes that CAN have inherent static longitudinal and/or static directional instability.
   These need a flight control system whose feedback loops drive the control surface actuators so
   that 'de-facto' stability is achieved. This links the design level of inherent instability to
   control power, feedback gains and actuator rate requirements. Chapter 11 gives a Class I method
   for this.

**Principle 4.** If the design has major balance problems, it is often possible to fix them by
moving the wing. If the gear attaches to the wing, the whole wing/gear combination must move.

### Step 10.9 — Document

Record the decisions of Steps 10.1–10.8 in a short descriptive report with clear, dimensioned
drawings.

---

## §10.2 Example Applications

Three examples:
- 10.2.1 Twin Engine Propeller Driven Airplane: **Selene**
- 10.2.2 Jet Transport: **Ourania**
- 10.2.3 Fighter: **Eris**

All three worked tables below were checked by re-multiplying every `W·x`, `W·y`, `W·z` product and
re-summing every column. All printed products, all column sums and all printed c.g.'s reproduce
exactly (c.g.'s to the printed integer inch). No arithmetic misprint was found in Tables 10.4,
10.5 or 10.6.

### §10.2.1 Twin Engine Propeller Driven Airplane — Selene

### Table 10.4 — Component Weight and Coordinate Data: Selene
*[Roskam Part II, Table 10.4, p. 247]*

All weights in lbs; all coordinates in in.; all moments in in.lbs. Coordinates are absolute
fuselage station / buttock line / water line values from the zero reference point, not fractions.

| Component | Weight (lbs) | x (in.) | Wx (in.lbs) | y (in.) | Wy (in.lbs) | z (in.) | Wz (in.lbs) |
|---|---|---|---|---|---|---|---|
| Wing | 738 | 269 | 198,522 | 0 | 0 | 118 | 87,084 |
| Empennage H.T. | 120 | 559 | 67,080 | 0 | 0 | 189 | 22,680 |
| Empennage V.T. | 59 | 504 | 29,736 | 0 | 0 | 146 | 8,614 |
| Fuselage | 621 | 220 | 136,620 | 0 | 0 | 76 | 47,196 |
| Nacelles | 249 | 315 | 78,435 | 0 | 0 | 126 | 31,374 |
| Landing Gear N.G. | 76 | 110 | 8,360 | 0 | 0 | 47 | 3,572 |
| Landing Gear M.G. | 304 | 315 | 95,760 | 0 | 0 | 55 | 16,720 |
| Engines + inst. | 1,508 | 331 | 499,148 | 0 | 0 | 126 | 190,008 |
| Propellers | 200 | 362 | 72,400 | 0 | 0 | 129 | 25,800 |
| Fixed Equipment | 1,025 | 220 | 225,500 | 0 | 0 | 76 | 77,900 |
| **Empty weight, W_E** | **4,900** | **288** | **1,411,561** | **0** | **0** | **104** | **510,948** |
| TFO | 44 | 315 | 13,860 | 0 | 0 | 118 | 5,192 |
| Fuel | 1,706 | 276 | 470,856 | 0 | 0 | 118 | 201,308 |
| 2 Pax. | 350 | 184 | 64,400 | 0 | 0 | 76 | 26,600 |
| 2 Pax. | 350 | 282 | 98,700 | 0 | 0 | 76 | 26,600 |
| 2 Pax. | 350 | 337 | 117,950 | 0 | 0 | 76 | 26,600 |
| Baggage | 200 | 220 | 44,000 | 14 | 2,800 | 76 | 15,200 |
| **Take-off wht, W_TO** | **7,900** | **281** | **2,221,327** | **0** | **2,800** | **103** | **812,448** |

Note printed under the table: other loading conditions are shown in Figure 10.4.

Derived (this extract, from the printed sums):
`x_cg|W_E` = 1,411,561 / 4,900 = 288.07 in.; `z_cg|W_E` = 510,948 / 4,900 = 104.27 in.
`x_cg|W_TO` = 2,221,327 / 7,900 = 281.18 in.; `z_cg|W_TO` = 812,448 / 7,900 = 102.84 in.
`y_cg|W_TO` = 2,800 / 7,900 = 0.35 in. (printed as 0).

Points to note for a reimplementation:
- Table 10.4 gives **no crew row.** Figure 10.4 labels the 350-lb group at x = 184 in. as
  `CREW (2)`, so that "2 Pax." row is in fact the two crew. The remaining two "2 Pax." rows
  (x = 282 and x = 337) plus the 200-lb Baggage are the 4-pax + luggage payload.
- The 200-lb Baggage row is the **forward** baggage bay (Fig. 10.3 marks it `BAG. FWD` at
  x = 220 in.). Fig. 10.4 also uses an "AFT LUG." loading; that aft station is NOT listed in
  Table 10.4. See the note under Fig. 10.4.

### Fig. 10.3 — Selene: General Arrangement
*[Roskam Part II, Fig. 10.3, p. 248]* — Side view (plus a separate main-gear detail
"GEAR OPTION 3"), drawn on an `x ~ F.S. ~ IN.` axis marked 100, 200, 300, 400, 500 and a `z (W.L.)`
axis marked 50, 100, 150, 200. Component c.g.'s marked `X`: FUSELAGE + FIXED EQPM'T, BAG. FWD,
CREW, PAX (three groups), WING, FUEL, TFO, NACELLES, ENGINES, PROPS, V.T., H.T., N.G. Two
alternative main gear positions are dimensioned: "GEAR LOCATION FROM FIG. 4.2b" and "GEAR LOCATION
IN TABLE 10.3". Tail-down / tip-over angles of 15°, 15° and 12° are dimensioned. Layout drawing —
no plotted data.

**Suspected misprint:** the callout "GEAR LOCATION IN TABLE 10.3" should read Table 10.4. Table
10.3 is the c.g.-range comparison table and holds no gear stations; Table 10.4 is the one that
lists `Landing Gear M.G.` at x = 315 in.

### Fig. 10.4 — Selene: Weight–C.G. Excursion Diagram
*[Roskam Part II, Fig. 10.4, p. 249]*

Axes: vertical `WEIGHT × 10⁻³ ~ LBS`, gridded, ticks at 5, 6, 7, 8; reference lines drawn at
`W_E` and `W_TO`. Two horizontal scales: `c̄_w` (0.6, 0.7, 0.8, 0.9, 1.0) above `F.S. (IN.)`
(280, 290, 300). Vertical drop lines labelled `MOST FWD`, `W_TO`, `W_E`, `MOST AFT` and
`MAIN GEAR` (open triangle).

Vertices, digitized from the plot and then confirmed against Table 10.4 arithmetic. Weights and
stations that reproduce exactly from Table 10.4 are marked "computed"; the rest are
"(read from plot)".

**Forward-most branch** (load fuel before payload):

| Node | Label on figure | W (lbs) | F.S. (in.) | Source |
|---|---|---|---|---|
| 0 | `W_E` | 4,900 | 288.1 | computed |
| 1 | `TFO` | 4,944 | 288.3 | computed |
| 2 | `FUEL` | 6,650 | 285.2 | computed |
| 3 | `CREW (2)` | 7,000 | 280.1 | computed — **most forward c.g.** |
| 4 | `4 PAX + LUG. FWD` | 7,900 = `W_TO` | 281.2 | computed |

**Aft-most branch** (load aft payload before fuel):

| Node | Label on figure | W (lbs) | F.S. (in.) | Source |
|---|---|---|---|---|
| 0 | `W_E` | 4,900 | 288.1 | computed |
| 1 | `TFO` | 4,944 | 288.3 | computed |
| 2 | `AFT PAX + AFT LUG.` | ≈5,470 | ≈295.2 | (read from plot) — **most aft c.g.** |
| 3 | `FUEL` | ≈7,180 | ≈290 | (read from plot) |
| 4 | — (line closes) | 7,900 = `W_TO` | 281.2 | computed |

A third, short arrow labelled `PILOT` leaves the `TFO` node up and to the left and ends at about
(F.S. 285, W ≈ 5,130) (read from plot). It is a separate light-loading case, not part of either
envelope branch.

Reference lines read from the plot: `MOST FWD` at F.S. 280.0 / 0.62 `c̄_w`; `W_TO` at F.S. 281.0;
`W_E` at F.S. 288.2 / ≈0.756 `c̄_w`; `MOST AFT` at F.S. 295.1; `MAIN GEAR` (open triangle) at
F.S. ≈302 / ≈0.98 `c̄_w`.

**Discrepancy — aft loading station.** The aft branch node 2 needs 550 lb (350 lb of aft pax at
x = 337 in. plus the 200-lb bag) to sit at F.S. ≈ 295. That requires the bag at x ≈ 390 in.
Table 10.4 lists Baggage at x = 220 in. (the forward bay). Fig. 10.4's "AFT LUG." station is
therefore an extra loading case that Table 10.4 does not tabulate. Do not try to reproduce the
aft branch from Table 10.4 alone.

**Discrepancy — main gear station.** The `MAIN GEAR` triangle on Fig. 10.4 reads F.S. ≈ 302 in.,
but Table 10.4 lists `Landing Gear M.G.` at x = 315 in. Fig. 10.3 shows two alternative gear
positions, which is the likely reason. Recorded as read; not resolved by the text.

### Step 10.7 result — Selene (p. 246)

> most forward c.g. occurs at W = 7,000 lbs, F.S. = 280 in. and 0.62 `c̄_w`
> most aft c.g. occurs at W = 5,500 lbs, F.S. = 295 in. and 0.78 `c̄_w`
> The c.g. range of the Selene is 15 inches or 0.16 `c̄_w`.
> Note that this compares favorably with the data of Table 10.3.

Both stations agree with the plot (280 and 295 in.). `0.62 c̄_w` agrees with the plot.

**Suspected misprint — the two `c̄_w` figures for the Selene.** The `c̄_w` scale of Fig. 10.4 is
tied to its own F.S. scale: 0.1 `c̄_w` measures ≈ 6.0 in., so `c̄_w` ≈ 60 in. On that scale
F.S. 295 falls at ≈ 0.87 `c̄_w`, and a 15-in. range is ≈ 0.25 `c̄_w`, not 0.16. The printed value
0.78 is exactly 0.62 + 0.16, so the aft figure looks to have been made by adding the range figure
to the forward figure. The range figure 0.16 `c̄_w` implies `c̄_w` = 15/0.16 = 93.75 in., which
does not match the figure's own axis. Note also that the Ourania example on p. 250 also quotes
0.16 `c̄_w`, where it IS self-consistent. Record the printed values, but treat 0.78 `c̄_w` and
0.16 `c̄_w` for the Selene as unreliable. The two F.S. values (280, 295) and the 15-in. range are
sound. `[verify p. 246]` — I re-rendered p. 249 at 600 dpi over the axis strip and re-measured
both scales twice; both measurements give ≈ 0.87 `c̄_w` at F.S. 295, so I cannot reconcile 0.78.

**Weight-scenario note.** The most forward c.g. occurs at W = 7,000 lb, not at `W_TO` = 7,900 lb,
and the most aft c.g. occurs at about W = 5,500 lb, not at `W_E` = 4,900 lb. The c.g. limits are
the envelope of the loading paths, so they generally occur at intermediate weights.

### Step 10.8 result — Selene (p. 250)

The most aft c.g. is well forward of the main landing gear contact point. Overall gear disposition
relative to the c.g. range is discussed in Chapter 9, §9.2.1. The suitability of the aft c.g. from
a static longitudinal and static directional stability viewpoint is discussed in Chapter 11,
§11.2.1. Step 10.9 was omitted to save space.

---

### §10.2.2 Jet Transport — Ourania

### Table 10.5 — Component Weight and Coordinate Data: Ourania
*[Roskam Part II, Table 10.5, p. 251]*

| Component | Weight (lbs) | x (in.) | Wx (in.lbs) | y (in.) | Wy (in.lbs) | z (in.) | Wz (in.lbs) |
|---|---|---|---|---|---|---|---|
| Wing | 13,664 | 913 | 12,475,232 | 0 | 0 | 213 | 2,910,432 |
| Empennage | 3,253 | 1,535 | 4,993,355 | 0 | 0 | 343 | 1,115,779 |
| Fuselage | 14,184 | 866 | 12,283,344 | 0 | 0 | 248 | 3,517,632 |
| Nacelles | 2,082 | 728 | 1,515,696 | 0 | 0 | 150 | 312,300 |
| Landing Gear N.G. | 573 | 307 | 175,911 | 0 | 0 | 122 | 69,906 |
| Landing Gear M.G. | 4,632 | 894 | 4,141,008 | 0 | 0 | 146 | 676,272 |
| Powerplant inst. | 9,891 | 705 | 6,973,155 | 0 | 0 | 157 | 1,552,887 |
| Fixed Equipment | 20,171 | 846 | 17,064,666 | 0 | 0 | 248 | 5,002,408 |
| **Empty weight, W_E** | **68,450** | **871** | **59,622,367** | **0** | **0** | **221** | **15,157,616** |
| TFO | 925 | 882 | 815,850 | 0 | 0 | 173 | 160,025 |
| Fuel | 25,850 | 882 | 22,799,700 | 0 | 0 | 205 | 5,299,250 |
| Crew flight deck | 410 | 260 | 106,600 | 0 | 0 | 248 | 101,680 |
| Crew cabin att. | 205 | 1,339 | 274,495 | 0 | 0 | 248 | 50,840 |
| Crew cabin att. | 410 | 354 | 145,140 | 0 | 0 | 248 | 101,680 |
| Pax + luggage | 30,750 | 846 | 26,014,500 | 0 | 0 | 248 | 7,626,000 |
| **Take-off wht, W_TO** | **127,000** | **864** | **109,778,652** | **0** | **0** | **224** | **28,497,091** |

Note printed under the table: other loading conditions are shown in Figure 10.6.

Derived (this extract): `x_cg|W_E` = 59,622,367 / 68,450 = 871.0 in.;
`z_cg|W_E` = 15,157,616 / 68,450 = 221.4 in.; `x_cg|W_TO` = 109,778,652 / 127,000 = 864.4 in.;
`z_cg|W_TO` = 28,497,091 / 127,000 = 224.4 in.

Ourania weight fractions implied by the table (this extract; all as fractions of `W_TO` = 127,000
lbs): `W_E`/`W_TO` = 0.539; fuel/`W_TO` = 0.204; pax + luggage/`W_TO` = 0.242; TFO/`W_TO` = 0.0073;
crew (3 rows, 1,025 lbs)/`W_TO` = 0.0081.

### Fig. 10.5 — Ourania: General Arrangement
*[Roskam Part II, Fig. 10.5, p. 252]* — Top view, side view and a main-gear/tail-down side
detail. Fuselage stations are dimensioned on the drawing: **FS 151** (nose), **FS 392**, **FS
1,129**, **FS 1,311**, **FS 1,655** (aft end). The `z (W.L.)` axis is marked 100, 200, 300, 400,
with the fuselage floor near **W.L. 78** and gear ground line **W.L. 78 / W.L. 88**. Component
c.g.'s marked `X`: FIXED EQPM'T, PAX + LUG, M.G., FUEL, FUSELAGE, WING, VERT., TFO, POWERPLT.
INST., NACELLE, CREW, CABIN ATT. (two locations), N.G., EMP. `c̄_w` and the "YEHUDI" (inboard wing
trailing-edge extension) are labelled. Tail-down / tip-over angles 15°, 12°, 12.5° and 11° are
dimensioned. Layout drawing — no plotted data.

### Fig. 10.6 — Ourania: Weight–C.G. Excursion Diagram
*[Roskam Part II, Fig. 10.6, p. 253]*

Axes: vertical `WEIGHT × 10⁻³ ~ LBS`, ticks 60, 80, 100, 120, 140, gridded; reference lines at
`W_E` and `W_TO`. Two horizontal scales: `c̄_w` (marked `0` and `0.5`, so **negative** `c̄_w`
values are possible when the c.g. is ahead of the MAC leading edge) above `F.S. (IN.)`
(800, 850, 900). Vertical drop lines labelled `MOST FWD`, `W_TO`, `W_E`, `MOST AFT`, `MAIN GEAR`
(open triangle) and, drawn at the same station as the main gear, `STATIC TIP-OVER LIMIT`.

The diagram is a fan of many loading branches out of the single `W_E` node. Branch end points,
read from the plot:

| Branch label on figure | End W (lbs, read) | End F.S. (in., read) |
|---|---|---|
| `TFO + PAX + LUG` | ≈99,100 | ≈859 |
| `TFO + FUEL + FWD WINDOW PAX + LUG` | ≈100,200 | ≈861 |
| `TFO + FUEL` | ≈95,200 | ≈874 |
| `TFO + FUEL + AFT WINDOW PAX + LUG` | ≈100,000 | ≈880 |
| `TFO + ½(PAX + LUG) AFT` | ≈85,300 | ≈908 |
| `PAX + LUG + CREW` (from the fwd node up to `W_TO`) | 127,000 | 864 |

Cross-check against Table 10.5: `W_E` + TFO + fuel = 68,450 + 925 + 25,850 = 95,225 lbs, which
matches the `TFO + FUEL` node read of ≈95,200. `W_E` + TFO + pax&lug = 68,450 + 925 + 30,750 =
100,125, which matches the `TFO + PAX + LUG` / window-pax nodes read of ≈99,000–100,000.

Reference-line stations read from the plot: `MOST FWD` F.S. ≈861; `W_TO` F.S. ≈865 (Table: 864);
`W_E` F.S. ≈870 (Table: 871); `MOST AFT` F.S. ≈884; `MAIN GEAR` and `STATIC TIP-OVER LIMIT` both
at F.S. ≈894 (Table: M.G. x = 894). The `MAIN GEAR` station and the `STATIC TIP-OVER LIMIT` are
drawn as the SAME vertical line.

Implied `c̄_w` geometry (this extract, from the figure's two scales plus the printed limits):
`c̄_w` ≈ 143.75 in., with the LEADING EDGE of `c̄_w` (the `0` mark) at F.S. ≈ 866 in. That makes
the forward limit sit AHEAD of the MAC leading edge, hence the printed negative value.

### Step 10.7 result — Ourania (p. 250)

> most forward c.g. occurs at W = 100,000 lbs, F.S. = 861 in. and −0.04 `c̄_w`.
> most aft c.g. occurs at W = 100,000 lbs, F.S. = 884 in. and 0.12 `c̄_w`.
> The c.g. range of the Ourania is seen to be 23 in. This is equivalent to 0.16 `c̄_w`.

This set is internally consistent: 884 − 861 = 23 in.; 0.12 − (−0.04) = 0.16 `c̄_w`;
23 / 0.16 = 143.75 in. = `c̄_w`. It also agrees with Table 10.3, "Jet Transp." (26–91 in.,
0.12–0.32 `c̄_w`), on the fraction, and is slightly below that table's inch range.

Note that BOTH limits occur at the same weight, W = 100,000 lbs, which is neither `W_E`
(68,450 lbs) nor `W_TO` (127,000 lbs). It is the `W_E` + TFO + one-load-group condition.

### Step 10.8 result — Ourania (p. 254)

The most aft c.g. is well forward of the main gear contact point. Gear disposition is discussed in
Chapter 9, §9.2.2; the suitability of the aft c.g. for static longitudinal and static directional
stability in Chapter 11, §11.2.2. Step 10.9 was omitted to save space.

---

### §10.2.3 Fighter — Eris

A front view and a top view are included in Fig. 10.7 because of the asymmetry of the gun and nose
gear placement.

### Table 10.6 — Component Weight and Coordinate Data: Eris
*[Roskam Part II, Table 10.6, p. 255]*

| Component | Weight (lbs) | x (in.) | Wx (in.lbs) | y (in.) | Wy (in.lbs) | z (in.) | Wz (in.lbs) |
|---|---|---|---|---|---|---|---|
| Wing | 6,762 | 331 | 2,238,222 | 0 | 0 | 118 | 797,916 |
| Empennage | 1,597 | 614 | 980,558 | 0 | 0 | 173 | 276,281 |
| Fuselage + booms | 7,347 | 323 | 2,373,081 | 0 | 0 | 94 | 690,618 |
| Engine section | 160 | 417 | 66,720 | 0 | 0 | 91 | 14,560 |
| Landing Gear N.G. | 554 | 137 | 75,898 | +16 | 8,864 | 44 | 24,376 |
| Landing Gear M.G. | 2,214 | 350 | 774,900 | 0 | 0 | 58 | 128,412 |
| Engines | 6,000 | 417 | 2,502,000 | 0 | 0 | 91 | 546,000 |
| Engine inst. | 2,834 | 370 | 1,048,580 | 0 | 0 | 102 | 289,068 |
| GAU-8A Gun | 2,014 | 180 | 362,520 | −20 | −40,280 | 60 | 120,840 |
| Fixed Eq. (− gun) | 4,018 | 189 | 759,402 | 0 | 0 | 85 | 341,530 |
| **Empty weight, W_E** | **33,500** | **334** | **11,181,881** | **−1** | **−31,416** | **96** | **3,229,601** |
| TFO | 300 | 370 | 111,000 | 0 | 0 | 85 | 25,500 |
| Fuel | 18,500 | 331 | 6,123,500 | 0 | 0 | 118 | 2,183,000 |
| Pilot | 200 | 209 | 41,800 | 0 | 0 | 91 | 18,200 |
| Ammunition | 1,785 | 283 | 505,155 | 0 | 0 | 73 | 130,305 |
| Bombs (fuselage) | 4,248 | 277 | 1,176,696 | 0 | 0 | 44 | 186,912 |
| Bombs (wings) | 6,372 | 315 | 2,007,180 | 0 | 0 | 100 | 637,200 |
| **Take-off wht, W_TO** | **64,905** | **326** | **21,147,212** | **0** | **−31,416** | **99** | **6,410,718** |

Note printed under the table: other loading conditions are shown in Figure 10.8.

Derived (this extract): `x_cg|W_E` = 11,181,881 / 33,500 = 333.8 in.;
`y_cg|W_E` = −31,416 / 33,500 = −0.94 in. (printed −1);
`z_cg|W_E` = 3,229,601 / 33,500 = 96.4 in.; `x_cg|W_TO` = 21,147,212 / 64,905 = 325.8 in.;
`y_cg|W_TO` = −31,416 / 64,905 = −0.48 in. (printed 0);
`z_cg|W_TO` = 6,410,718 / 64,905 = 98.8 in.

Eris weight fractions implied by the table (this extract; all as fractions of `W_TO` = 64,905
lbs): `W_E`/`W_TO` = 0.516; fuel/`W_TO` = 0.285; total ordnance (ammo + both bomb groups,
12,405 lbs)/`W_TO` = 0.191; pilot/`W_TO` = 0.0031; TFO/`W_TO` = 0.0046.

This is the only example that carries a lateral offset: the GAU-8A gun sits at y = −20 in.,
partly balanced by the nose gear at y = +16 in.

### Fig. 10.7 — Eris: General Arrangement
*[Roskam Part II, Fig. 10.7, p. 256]* — Top view, front view and side view. Side view is
drawn on an `x ~ F.S. ~ IN.` axis marked 100 … 600 and a `z ~ W.L. ~ IN.` axis marked 100.
Component c.g.'s marked `X`: FUSELAGE + BOOMS, WING + FUEL, TFO, ENGINES + ENG. SECT., ENG. INST.,
M.G., N.G., BOMBS (WINGS), BOMBS (FUS.), AMMO, PILOT, FIXED EQ, GAU-8A, EMP. Also labelled: an
`F.404 ENVELOPE`, the AMMO DRUM, the boom centreline, the GUN (top view), the GAS DEFLECTOR STRAKE
and `W.L. 24 / W.L. 17`. Tail-down / tip-over angles 13°, 19° and 14° are dimensioned. Layout
drawing — no plotted data.

### Fig. 10.8 — Eris: Weight C.G. Excursion Diagram
*[Roskam Part II, Fig. 10.8, p. 257]*

Axes: vertical `WEIGHT × 10⁻³ ~ LBS`, ticks 30, 40, 50, 60, gridded; reference lines at `W_E`
(33,500) and `W_TO` (64,905). Two horizontal scales: `c̄_w` (0.40, 0.45, 0.50, 0.55, .60) above
`F.S. (IN.)` (320, 330, 340). Vertical drop lines labelled `MOST FWD`, `W_TO`, `MOST AFT` and
`MAIN GEAR` (open triangle).

This figure shows both an **unloading** path (from `W_TO` down, with minus signs) and a **loading**
path (from `W_E` up), so the loop closes. Every node reproduces exactly from Table 10.6.

**Unloading path** (left / forward side), starting at `W_TO`:

| Node | Label on figure | W (lbs) | F.S. (in.) | Source |
|---|---|---|---|---|
| 0 | `W_TO` (with `+ PILOT`, `+ AMMO` marked at the top) | 64,905 | 325.8 | computed |
| 1 | `− FUEL` | 46,405 | 323.8 | computed — **most forward c.g.** |
| 2 | `− BOMBS (F)` | 42,157 | 328.5 | computed |
| 3 | `− BOMBS (w)` | 35,785 | 330.9 | computed |

**Loading path** (right / aft side), starting at `W_E`:

| Node | Label on figure | W (lbs) | F.S. (in.) | Source |
|---|---|---|---|---|
| 0 | `W_E` | 33,500 | 333.8 | computed — **most aft c.g.** |
| 1 | `TFO + PILOT` | 34,000 | 333.4 | computed |
| 2 | `TFO + BOMBS (WING)` | 40,172 | 331.1 | computed |
| 3 | `TFO + FUEL` | 52,300 | 333.0 | computed |
| 4 | `+ BOMBS (WING)` | ≈57,600 | ≈331.3 | (read from plot) |
| 5 | `+ BOMBS (FUSELAGE)` | ≈63,100 | ≈329.4 | (read from plot) |
| 6 | `+ PILOT + AMMO` | 64,905 = `W_TO` | 325.8 | computed |

Reference-line stations read from the plot: `MOST FWD` F.S. ≈324; `W_TO` F.S. ≈326;
`MOST AFT` F.S. ≈334; `MAIN GEAR` (open triangle) F.S. ≈346–350 (Table 10.6: M.G. x = 350).

### Step 10.7 result — Eris (pp. 254, 258)

> most forward c.g. occurs at W = 46,400 lbs, F.S. = 324 in. and 0.43 `c̄_w`.
> most aft c.g. occurs at W = 33,500 lbs, F.S. = 334 in. and 0.50 `c̄_w`.
> The c.g. range of the Eris is 10 inches or 0.07 `c̄_w`.
> Note that this compares favorably with the data of Table 10.3.

Internally consistent: 334 − 324 = 10 in.; 0.50 − 0.43 = 0.07 `c̄_w`; 10 / 0.07 = 143 in. = `c̄_w`.
Both stations reproduce exactly from Table 10.6 (`W_TO` minus fuel = 64,905 − 18,500 = 46,405 lbs
at F.S. 323.8; `W_E` = 33,500 lbs at F.S. 333.8).

Note the pattern: for this fighter, the most AFT c.g. is the **empty** airplane and the most
FORWARD c.g. is the **fuel-out, fully-armed** airplane. That is the opposite of the Selene case
and shows why every scenario must be checked.

Table 10.3 gives "Fighters" a c.g. range of 15 in. / 0.20 `c̄_w`; the Eris at 10 in. / 0.07 `c̄_w`
is inside that.

### Step 10.8 result — Eris (p. 258)

The most aft c.g. is well forward of the main landing gear. Gear disposition relative to the c.g.
range is discussed in Chapter 9, §9.2.3; the suitability of the aft c.g. for static longitudinal
and static directional stability in Chapter 11, §11.2.3. Step 10.9 was omitted to save space.

### Fig. (unnumbered) — AV-8B cutaway
*[Roskam Part II, p. 258]* — Isometric cutaway line drawing of the McDonnell Douglas AV-8B
Harrier II, captioned `AV-8B` and `COURTESY OF: McDONNELL DOUGLAS`. Decorative — no plotted data,
no caption number.

---

## Summary of the three worked examples

All quantities below are from the printed tables and text. "Range fraction" is a fraction of
`c̄_w`, not of `W_TO` or of fuselage length.

| | Selene (twin prop) | Ourania (jet transport) | Eris (fighter) |
|---|---|---|---|
| `W_E` (lbs) | 4,900 | 68,450 | 33,500 |
| `W_TO` (lbs) | 7,900 | 127,000 | 64,905 |
| `W_E` / `W_TO` | 0.620 | 0.539 | 0.516 |
| `x_cg` at `W_E` (F.S., in.) | 288 | 871 | 334 |
| `x_cg` at `W_TO` (F.S., in.) | 281 | 864 | 326 |
| `z_cg` at `W_E` (W.L., in.) | 104 | 221 | 96 |
| `z_cg` at `W_TO` (W.L., in.) | 103 | 224 | 99 |
| Most fwd c.g. — W (lbs) | 7,000 | 100,000 | 46,400 |
| Most fwd c.g. — F.S. (in.) | 280 | 861 | 324 |
| Most fwd c.g. — fr. `c̄_w` | 0.62 | −0.04 | 0.43 |
| Most aft c.g. — W (lbs) | 5,500 | 100,000 | 33,500 |
| Most aft c.g. — F.S. (in.) | 295 | 884 | 334 |
| Most aft c.g. — fr. `c̄_w` | 0.78 (see misprint note) | 0.12 | 0.50 |
| c.g. range (in.) | 15 | 23 | 10 |
| c.g. range (fr. `c̄_w`) | 0.16 (see misprint note) | 0.16 | 0.07 |
| Implied `c̄_w` (in.) | ≈60 from the figure axis; 93.75 from the printed range | 143.75 | 143 |
| Table 10.3 comparison row | Twin Engine Prop. Driven (9–15 in., 0.12–0.22) | Jet Transp. (26–91 in., 0.12–0.32) | Fighters (15 in., 0.20) |

---

## Implementation checklist (this extract, not the book)

1. Build the component list from Table 10.1a. Keep the item numbers — the three weight roll-ups
   (10-1) to (10-3) are defined by index ranges over that list.
2. Store an absolute `(x, y, z)` in INCHES for every component, measured from one zero reference
   point that keeps all coordinates positive. Do not store fractions.
3. Get first-guess component c.g.'s from Table 10.2. Each entry is a fraction of a DIFFERENT
   reference length: `c̄_w`, `c̄_h`, `c̄_v`, nacelle length, or fuselage length. Convert every one
   to an absolute station before summing moments.
4. Compute `x_cg`, `y_cg`, `z_cg` with (10-4) to (10-6). The divisor is always the same weight the
   numerator sums to.
5. Enumerate the loading sequences (four combinations → six sequences as a minimum), and compute
   the c.g. after every incremental load. That gives the excursion diagram vertices.
6. The forward c.g. limit is the minimum `x_cg` over ALL sequence vertices; the aft limit is the
   maximum. They usually occur at intermediate weights, not at `W_E` or `W_TO`.
7. Convert the two limits to a fraction of `c̄_w` only for reporting and for the Table 10.3
   comparison: `fr. c̄_w = (x_cg − x_LE,c̄w) / c̄_w`. The result can be negative (Ourania).
8. Check the aft limit against the main gear station for longitudinal tip-over, and check the
   lateral c.g. against the gear track if the design is asymmetric (Eris).
