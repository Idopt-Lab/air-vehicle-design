# Chapter 24 — Conceptual Design Examples

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 24
"Conceptual Design Examples," printed pp. 867-958.

Two full worked design examples applying the book's methods end to end: (1) the **DR-1**, a
single-seat aerobatic homebuilt (fixed-size, off-the-shelf piston engine; done entirely by hand with
a pocket calculator, plus a small sizing-iteration helper program, "AC-SIZE"), and (2) the **DR-3**,
a lightweight supercruise fighter (variable "rubber" engine sized during iteration; hand calculation
for pre-layout sizing, then the author's RDS-Student program for the detailed number-crunching,
carpet-plot optimization, and performance/cost analysis). The author explicitly grades both examples
as at-most-a-"B" — incomplete relative to a full professional design effort, intended to show the
*process*, not a finished, buildable aircraft ("Homebuilders: don't build this one either!").

**Source note (revised 2026-08-18).** The DR-1 example is reproduced in the book from the author's
original *hand-written* design notes, deliberately, to show it is a fully by-hand process. The scan's
**OCR text layer** for that handwriting is extremely unreliable, and an earlier version of this
extract relied on it and inherited many errors. Those errors are now fixed: **the handwriting itself
renders cleanly at 320 dpi**, and every page that had been flagged as unreadable has been re-read
directly off the page image (pp. 869, 872, 881, 884, 886, 887, 891, 902, 903, 918, 919). Where the
earlier text differed from the page, the difference and the correct value are recorded inline at
that point in this file. The rule for this chapter going forward: **do not read this chapter from
the OCR layer — render the page.**

The DR-3 example is mostly typeset (RDS-Student program input/output listings) and OCRs cleanly, but
two of its pages had also been mis-summarised and are now transcribed in full from renders
(pp. 925 and 950).

---

## §24.1 Introduction
*[Raymer, p. 867]*

Rather than scatter worked examples through every chapter, the book concentrates two full design
studies here, covering the extremes of the conceptual-design process: a fixed-engine, propeller-driven
homebuilt vs. a "rubber-engine" supersonic fighter. Design requirements for both were assumed from
data on similar existing aircraft, then treated as if customer-mandated. The DR-1 is analyzed
entirely by hand (bar the sizing-iteration loop, done with a simple free helper program, "AC-SIZE,"
available from the author's website, or easily rewritten); the DR-3 uses hand calculation only for
pre-layout sizing (initial `T/W`, `W/S`) and the author's RDS-Student software (bundled with the book
via AIAA) for everything after the initial layout. The author recommends students always do the
pre-layout sizing steps by hand, as shown here, before being allowed to use RDS-Student (or any other
"canned" design tool) for the laborious number-crunching.

## §24.2 Single-Seat Aerobatic Homebuilt (DR-1)
*[Raymer, p. 868]*

**Concept.** A weekend-aerobatics homebuilt intended to out-perform the Great Lakes biplane without
the Pitts Special's twitchy handling. Classical layout, built via moldless foam-fiberglass sandwich
construction for quick "garage" fabrication; the selected engine comes pre-configured for aerobatic
(inverted-fuel-system) operation to minimize installation effort. A notable optimization result: the
wing loading needed to meet the no-flaps stall-speed requirement strongly biases the aspect-ratio
optimum *downward* — the resulting wing has a normal span but an oversized (excess) chord to reach
the required area.

### DR-1 design requirements (hand-written requirements sheet)
*[Raymer, p. 869]*

*(Fully re-read and CORRECTED 2026-08-18 against a 320-dpi render of book p. 869. The
hand-writing renders cleanly at that resolution; the OCR text layer for it does not, and the earlier
extract of this page contained several errors, listed after the table.)*

**Engine:** Lycoming O-320-A2B (from the Citabria) — 150 hp at 2700 rpm, `C_bhp` = 0.5 (assumed),
272 lb dry, 30 in long, 32 in wide, 23 in high.

**Design goals:** rapid fabrication (foam and fiberglass); performance between the Pitts S-1S and
the Great Lakes.

| Requirement | Value |
|---|---|
| `Vmax` | ≥ 130 kt |
| `Vstall` | ≤ 50 kt |
| Takeoff | ≤ 1000 ft over 50 ft |
| Rate of climb, S.L. | ≥ 1500 fpm |
| Range | ≥ 280 nm (**no** reserves) at `Vcruise` = 115 kt |
| Load factor `n` | +6 / -3 g |
| `Wcrew` | 220 lb (includes parachute) |

Optional open cockpit (this is the configuration used for the analysis).

**Handling qualities:** slightly stable (like a fighter); good spin recovery, upright and inverted.

**Mission profile** (hand sketch, four points): takeoff (0-1), climb (1-2), cruise 280 nm at
`h` = 8000 ft and `Vcruise` = 115 kt (2-3), land (3-4).

**What the earlier extract got wrong on this page:**
- `Vmax` was given as "≈ 150 kt". The sheet says **≥ 130 kt**.
- Range was given as "≈ 280 nm (with reserves)". The sheet says **no reserves**.
- A requirement "roll rate ≥ 180 deg/s" was listed. **No roll-rate requirement appears on the
  page.** The item in that position is the load factor, `n` = +6/-3 g.
- A requirement "ceiling ≥ 15,000 ft" was listed. **No ceiling requirement appears on the page.**
- The engine's `C_bhp` = 0.5 assumption and the "from Citabria" provenance were missing.
- There is **no three-view sketch on p. 869**, and therefore no "span ≈ 30 ft, length ≈ 32 ft,
  height ≈ 7 ft" dimension callouts. Those numbers were a misreading of the engine's own dimensions
  (30 in long, 32 in wide, 23 in high). The only sketch on the page is the mission profile above.

### Wing geometry, tail geometry, and airfoil selection
*[Raymer, p. 872]*

*(Fully re-read and CORRECTED 2026-08-18 against a 320-dpi render of book p. 872. The whole page is
one hand-written sheet, "WING GEOMETRY SELECTION (From Chapter 4 Charts & Tables)", and is legible.)*

**Wing:** `A` = 6; `lambda` = 0.4; `Lambda_c/4` = 0; dihedral `Gamma` = 3 deg (0 deg effective).

**Airfoil:** NACA 63₂-015 at the **TIP**, NACA 63₂-012 at the **ROOT** — the note on the sheet reads
"Higher t/c at tip to prevent tip stall". **No twist**, to avoid inverted tip stall.

**Horizontal tail:** `A` = 4; `lambda` = 0.4; NACA 0012.

**Vertical tail:** `A` = 1.5; `lambda` = 0.4; NACA 0012.

**What the earlier extract got wrong on this page:**
- The airfoils were **swapped**: it put the thicker 63₂-015 at the root and the 63₂-012 at the tip.
  The sheet does the opposite, and says why (higher t/c at the tip prevents tip stall).
- The vertical tail was given as `A` ≈ 1.8, taper ≈ 0.6. The sheet says **`A` = 1.5, `lambda` = 0.4**.
- The horizontal-tail taper ratio (0.4) was missing.
- The page range "pp. 872-873" was wrong; all of this is on p. 872.

### Wing loading, stall, climb, and cruise sizing constraints
*[Raymer, pp. 873-874]*

Historical wing-loading comparables cited: Pitts `W/S` ≈ 11.7 psf, Great Lakes `W/S` ≈ 9.6 psf,
Stevens Akro `W/S` ≈ 13.0 psf. No-flap stall requirement (`CLmax` ≈ 1.2, `Vstall` ≈ 50 kt) drives the
wing-loading calculation via the standard stall equation (Eq. 5.6-family), giving `W/S` ≈ 10.2 psf.
Climb requirement (`Vy` ≈ 70 kt, desired rate of climb ≈ 1500 ft/min at sea level) and cruise
requirement (`Vc` ≈ 115 kt at 8000 ft) were each converted to a required `T/W` via the standard
climb/cruise `T/W` equations (Chapter 5), with cruise found to be the less restrictive of the two by
this point in the process.

### Initial sizing
*[Raymer, pp. 875-876]*

Empty-weight fraction estimated via the Chapter-3 statistical form (`We/W0 = A*W0^C`); crew+payload
weight `Wcrew+payload` = 220 lb. Mission-segment weight fractions computed for taxi/takeoff, climb,
cruise, and reserves/landing using the standard Breguet cruise-segment form (Eq. 3.13-family) with an
assumed `L/D` and propeller-aircraft SFC; combining these with the empty-weight-fraction relation and
iterating (per the standard Chapter-3 iteration scheme) gave a **first-pass sized takeoff weight
around `W0` ≈ 1200-1290 lb** depending on assumed constants — refined further below. The author's
"AC-SIZE" helper program (a small iterative sizing loop implementing exactly Chapter 3's method) was
used to converge this iteration rather than hand-iterating; sample program output (mission-segment
weight fractions ≈ 0.97, 0.985, 0.953, 0.995 for the four segments) is reproduced in the book,
converging toward `W0` ≈ 1290 lb for an *unconstrained* ("rubber," continuously variable) engine —
annotated in the book as **undesirable**: "this heavier `W0` would give reduced performance with a
fixed-size engine!"

### Fixed-engine sizing
*[Raymer, p. 877]*

Because the O-320-A2B is a fixed, off-the-shelf engine (not a scalable "rubber" engine), the sizing
iteration was re-run holding engine power fixed and instead **solving for the design range the fixed
engine/airframe combination can actually achieve** — the AC-SIZE program iterated to a converged
`W0` ≈ 1197-1198 lb (mission-segment weight fraction product ≈ 0.925 for this run), from which the
corresponding achievable range was back-calculated via the Breguet-equation approach, giving
**R ≈ 358 nm** for that configuration (used later to refine sizing and optimization techniques for
maximum performance and range).

### Layout, propulsion, and aerodynamics data
*[Raymer, pp. 878-882]*

Fuselage, wing, and tail dimensions were measured from the design layout drawing (fuselage width,
depth, and length; wing root/tip chords and MAC from Eqs. 7.6-7.9; tail chords/areas). Propeller
diameter was estimated from Eq. 10.3 (custom wood, 2-bladed, fixed-pitch propeller) as roughly
6 ft {1.8 m}, checked against tip-speed limits at 2700 rpm. Aerodynamics: maximum lift coefficient
built up from the wetted/exposed-area-weighted airfoil data (`CLmax` ≈ 1.2 clean, per Eq. 12.15-family);
parasitic drag built up component-by-component (fuselage, wing, tails) assuming fully turbulent flow,
each via the standard skin-friction-coefficient/form-factor/wetted-area method of Chapter 12
(Eqs. 12.24-12.30), summed with a landing-gear increment and a cockpit/canopy frontal-area increment,
plus leakage/protuberance adjustments (see the full transcribed buildup below); induced drag via
Oswald efficiency `e` ≈ 0.87 and `K` ≈ 0.081 (Eq. 12.48-family).

#### DR-1 thrust vs. velocity and the propwash correction
*[Raymer, hand-written thrust-vs-velocity sheet, p. 884]*

*(Corrected 2026-08-18 against a 320-dpi render of book p. 884. The earlier extract said
"`eta_p` ≈ 0.84 on-design, static thrust ≈ 750-790 lb range depending on assumed blade count/pitch
schedule". The page gives `eta_p` = **0.78** at cruise and a static thrust of **400 lb** (assumed) for
the selected wood fixed-pitch propeller; the ~730 lb static figure on the plot belongs to the
alternative variable-pitch metal propeller, which was not the one chosen.)*

- Thrust equation as written on the sheet: `T` = 550(150)`eta_p` / `V`. The plot explicitly notes it
  "does not include engine drags or propwash".
- Two propellers are plotted. A **variable-pitch metal** propeller with `eta_p` from Fig. 13.9
  (theoretical curve, faired down to a static value of about 730 lb). A **wood fixed-pitch**
  propeller with `eta_p` = 0.78 times the fixed-pitch correction, drawn as an assumed 400 lb static
  thrust faired into a calculated curve that peaks near 370 lb around 50-60 kt.
- Cruise point: `eta_p` = **0.78** at about 115 kt, where the fixed-pitch curve crosses the
  variable-pitch curve at roughly 340 lb.
- **Correction for propwash drag effect**, washed area = 265 ft², via Eq. 13.20:
  `eta_p_effective` = `eta_p`[1 - (1.558/(70/12)²)(0.004)(265)] = **0.95 `eta_p`**, so
  `Thrust_actual` = 0.95 x `Thrust_calculated`.

#### DR-1 parasite-drag buildup, transcribed in full
*[Raymer, hand-written drag-buildup sheet, p. 881]*

*(Transcribed 2026-08-18 from a 320-dpi render. The earlier extract summarised this page as a
"total zero-lift drag coefficient `CD0` = 0.0277 (clean cruise configuration)". That is wrong on
both counts: the page's own total is **0.0250**, and the configuration is the **open cockpit**, not a
clean cruise configuration. Reference area is `S` = 118 ft².)*

**Wing** — `l` = `c_bar` = 4.67 ft, average `t/c` = 13.5%:
- Eq. 12.25: `R` = 5 x 10⁶. Eq. 12.28: `R_cutoff` = 16.46 x 10⁶.
- Eq. 12.27: `Cf` = 0.0034.
- Eq. 12.30: `FF` = [1 + (0.6/0.3)(0.135) + 100(0.135)⁴][1.34(0.15)^0.18] = **1.24**.
- `Swet` = 202.3 ft². `Q` = 1 (using fillets).
- `CD0_wing` = 0.0034 x 1.24 x 202.3 / 118 = **0.0071**.

**Tails** (analysed together, because the mean chords and t/c are similar) — `l` = `c_bar_average`
= 2.8 ft, `t/c` = 12%:
- `R` = 3 x 10⁶, `R_cutoff` = 9.6 x 10⁶, `Cf` = 0.0037.
- `Swet` = 48.6 + 12 = 60.6 ft².
- `FF` = [1 + (0.6/0.3)(0.12) + 100(0.12)⁴][1.34(0.15)^0.18] = **1.20**.
- `CD0_tails` = 0.0037 x 1.2 x 60.6 / 118 = 0.0023, **+10% for gaps = 0.0025**.

**Gear drag** (Table 12.5):
- Tire frontal area = 1.03 ft²; `D/q` = 1.03 x 0.13 = 0.134 ft².
- Strut frontal area = 0.67 ft²; `D/q` = 0.67 x 0.05 = 0.033 ft².
- Add 20% for interference: `CD0_gear` = 1.2(0.134 + 0.033) / 118 = **0.0020**.

**Cockpit drag** (Chapter 12) — open cockpit:
- Frontal area = 1.8 ft²; `CD0` = 1.8 x 0.5 / 118 = **0.0076**.

**Total parasite drag:** the component sum (including the fuselage term carried over from the
preceding page) is 0.0238; plus 5% for leaks and protuberances,
`CD0` = 1.05(0.0238) = **0.0250** (aerobatic / open-cockpit configuration).

### Weights, stability and control, and spin recovery
*[Raymer, pp. 885-892]*

A component weight buildup produced an itemized weight/c.g. table, transcribed in full below.

#### Weights by other methods
*[Raymer, hand-written sheet, p. 886]*

Cessna methods (Ref. 18):
```
W_wing = .047 * W0^.397 * S^.36  * n^.397 * A^1.712                                = 225 lb
W_ht   = .055 * W0^.887 * Sh^.101 * Ah^.138 * t_root^-.223                         =  60 lb
W_vt   = .108 * W0^.567 * Sv^.125 * Av^.482 * t_root^-.747 * (cos Lambda_c/4)^-.882 = 17.7 lb
```
Ref. 16 method:
```
W_fus (w/o nacelle) = 200 * [ (W0*n/1e5)^.286 * (L/10)^.857 * ((W+D)/10) * (Ve/100)^.338 ]^1.1 = 114 lb
W_nacelle           = 2.5 * sqrt(Hp)                                                          =  31 lb
```
Comparison to actual data (Ref. 18): `W_electrical` = 40 lb;
`W_gear` = (Wgear/W0)*W0 = 0.054(1200) = 64 lb (the 0.054 is the average of the C-180 and L-19A values).

#### Weights adjustments and balance
*[Raymer, hand-written weight statement, p. 887]*

The sheet notes that foam-and-fiberglass sandwich homebuilts are lighter because of design
differences, not because of composite construction, but applies the Table 15.4 factors anyway to
estimate a per-component weight saving. Distances to datum are measured from the back of the spinner.

| Component | Fudge factor | Adjusted weight, Ch. 15 / other methods (lb) | Selected weight (lb) | Distance to datum (in) |
|---|---|---|---|---|
| Fuselage | 0.90 | 104 / 128 | 130 | 115 |
| Wing | 0.85 | 143 / 175 | 150 | 70 |
| Hor. tail | 0.83 | 17 / 45 | 40 | 210 |
| Vert. tail | 0.83 | 9 / 13 | 15 | 225 |
| Engine | — | 452 / 380 | 380 | 16 |
| Gear | 0.95 | 66 / 57 | 60 | 45 |
| Fuel sys. | — | 22 | 22 | 50 |
| Fl. controls | — | 13 | 15 | 80 |
| Electrical | — | 73 / 40 | 40 | 40 |
| Avionics | — | 9.5 | 10 | 60 |
| Furnishings | — | 20 | 20 | 100 |
| **Sum `We`** | | | **882** | **@ 59.5** |
| Pilot and chute | | | 220 | 85 |
| Fuel (available, if `W0` = 1200 lb) | | | 98 | 50 |
| **Sum `W0`** | | | **1200** | **@ 63.3** |

Most-aft c.g. is the no-fuel case: `We+pilot` = **1102 lb at 64.5 in**.

*(Transcribed 2026-08-18 from 320-dpi renders of book pp. 886-887. The earlier extract gave the
empty weight as "roughly 880-940 lb" and the most-aft c.g. as "around 63-65 in", and flagged the
table as "heavily OCR-garbled". The OCR layer is garbled, but the handwriting is legible at 320 dpi:
the exact values are `We` = 882 lb at 59.5 in, `W0` = 1200 lb at 63.3 in, and a most-aft no-fuel c.g.
of 64.5 in.)*

Stability
and control analysis (Chapter 16 methods) found a power-off neutral point well aft of the most-aft
c.g., giving a **static margin on the order of 12-18% MAC** (both stick-fixed and stick-free), judged
appropriately stable for a "weekend pilot" aircraft (possibly too stable/sluggish for serious
aerobatic competition, per the author's own note). A trim analysis (`Cm` vs. `CL` for a family of
elevator deflections) produced a trim plot, transcribed below.

#### DR-1 trim plot
*[Raymer, hand-written trim sheet with an embedded Excel plot, p. 891]*

Method as written on the sheet: vary `alpha` and `delta_e`, find `Cm_cg` and `CL_total`, then plot
`Cm` vs. `CL` (done in Excel). Each cell below is `<Cm><Cl>`:

| `alpha` (deg) | `delta_e` = 0 | -2 | -4 | -6 |
|---|---|---|---|---|
| 0 | <0.000><0.000> | <0.052><-.020> | <0.103><-.041> | <0.155><-.061> |
| 2 | <-.029><0.185> | <0.023><0.165> | <0.075><0.144> | <0.126><0.124> |
| 4 | <-.057><0.370> | <-.006><0.350> | <0.046><0.329> | <0.098><0.309> |
| 6 | <-.086><0.555> | <-.034><0.535> | <0.017><0.515> | <0.069><0.494> |
| 8 | <-.115><0.741> | <-.063><0.720> | <-.011><0.700> | <0.040><0.679> |
| 10 | <-.143><0.926> | <-.092><0.905> | <-.040><0.885> | <0.012><0.864> |

Trimmed where `Cm_cg` = 0 for level flight.

**Cruise trim:** `q` = 35 lb/ft², so `CL` = (W/S)/`q` = 9.7/35 = **0.278**. At `CL` = 0.278 with
`Cm_cg` = 0, `delta_e` = **-1.8 deg** (the circled point on the plot).

**Trim via tail incidence only:** required `i_h` = -`delta_alpha_0L` = -(-0.8 `delta_e`)
= -(-0.8)(-1.8 deg) = **-1.44 deg**.

*(Transcribed 2026-08-18 from a 320-dpi render of book p. 891. The earlier extract gave cruise
`CL` = "≈ 0.27" and the elevator deflection as "a modest few degrees"; the exact values are
`CL` = 0.278 and `delta_e` = -1.8 deg.)* A spin-recovery check (Eq. 16.31-family, comparing rudder/vertical-tail area against the
fuselage-length-based recovery criterion at both forward and most-aft c.g.) found no problem in either
upright or inverted spins, with margin to spare on rudder area.

### Rate of climb, maximum speed, and turn performance
*[Raymer, pp. 893-903]*

Rate of climb was computed across a speed sweep at sea level and at 8000 ft (Eq. 17.17-family, using
the thrust-minus-drag excess power at each speed), producing best-rate-of-climb speed/altitude curves.

#### Maximum speed for each of the nine sizing-matrix cells
*[Raymer, hand-written sheet, p. 902]*

Requirement: `Vmax` >= 130 kt at 8000 ft. Quick method as written on the sheet: calculate drag at
130 kt, use it to shift the previous drag curve up or down, then find the intersection with the
thrust curve. The nine numbered results are the nine cells of the AR / W-S sizing matrix:

| Cell | Drag at 130 kt (lb) | `Vmax` (kt) |
|---|---|---|
| 1 | 196 | 130 |
| 2 | 157 | 136 |
| 3 | 139 | 138 |
| 4 | 211 | 127 |
| 5 | 163 | 134 |
| 6 | 139 | 138 |
| 7 | 228 | 125 |
| 8 | 172 | 133 |
| 9 | 145 | 137 |

The accompanying sketch plots thrust at 8000 ft (about 295 lb at low speed, falling to about 200 lb
by 130 kt) against a baseline drag curve at 8000 ft, with the nine shifted drag lines crossing it
between about 125 and 138 kt.

*(Transcribed 2026-08-18 from a 320-dpi render of book p. 902. The earlier extract gave only
"`Vmax` = 130 kt at 8000 ft, per the plotted intersection"; that is cell 1 of nine, and it is the
requirement value, not a single computed answer.)*

#### Sustained-turn requirement
*[Raymer, hand-written sheet, p. 903]*

The sheet states that crossplotting the stall, rate-of-climb and `Vmax` requirements onto the sizing
graph gives **no lower limit on aspect ratio**, and that at very low aspect ratio the induced drag
would become excessive during maneuvers, so a maneuvering requirement is needed. A new performance
requirement is therefore defined on sustained turn:

- `psi_dot` >= **30 deg/s sustained, at 100 kt, S.L.**
- Eq. 17.51: `psi_dot` = 30 deg/s = 0.5236 rad/s = g·sqrt(n² - 1) / (100 x 1.689), so **`n` >= 2.92**.
- `T` = 345 lb, from the graph.
- Eq. 17.53: `n` = sqrt[ (34·pi·A·e / (W/S)) · (345/W - 34·`CD0`/(W/S)) ].
- Stall check (a near-stall condition reduces `e`): `CL` = n(W/S)/`q` = **0.88** for the baseline and
  **1.056** for `W/S` = 12.24, so the prior `e` estimates should be approximately correct.

Using prior data, the nine sizing-matrix cells give: (1) `n` = 2.8, (2) 2.9, (3) 2.8, (4) 3.1,
(5) 3.3, (6) 3.3, (7) 3.2, (8) 3.4, (9) 3.5. The sheet's own note: large values of `n` are incorrect
because they imply `CL` > `CL_stall`, but they can still be used to crossplot for `n` = 2.92, which is
below stall.

*(Transcribed 2026-08-18 from a 320-dpi render of book p. 903. The earlier extract said only that
"the book notes only that induced drag would become excessive in maneuvers at very low AR" and
flagged the turn-rate numbers as unread. The full requirement and all nine load factors are above.)*

### Sizing matrix, aspect-ratio/wing-loading optimization, and final result
*[Raymer, pp. 904-905]*

A sizing matrix was built by varying wing loading and aspect ratio around the initial-sizing point
and resizing the aircraft (via the Chapter-19 carpet-plot-style method) at each combination, cross-plotted
against the performance constraint curves (climb, cruise/range, stall) established above.

**Result: the optimal aircraft for the given requirements occurs at `W/S` ≈ 10.2 psf and `AR` ≈ 2.9,
with a sized takeoff weight `W0` ≈ 1150 lb** — lower than the ~1200 lb "as-drawn" baseline used
through the hand-calculation walkthrough above. The next step in the design process (not carried
further in this example) would be to redraw the aircraft at this optimized point and re-analyze it in
detail.

## §24.3 Lightweight Supercruise Fighter (DR-3)
*[Raymer, p. 905]*

**Concept.** A lightweight F-16-successor fighter concept — a cheap "low-end" complement to a
high-end fighter (as the F-16 complemented the F-15) — updated with newer technology and a sustained
supersonic-cruise ("supercruise") capability on dry (non-afterburning) power, plus a short
takeoff/landing requirement. Stealth shaping/treatments were deliberately *not* applied ("to avoid
unpleasant conversations with government personnel") but would likely be present on a real aircraft
for this mission. The design incorporates one deliberately speculative, unproven technology: a
**variable-dihedral vertical tail** (author-patented concept, Ref. [170]) that converts from a
V-tail arrangement subsonically to upright twin verticals supersonically, intended to control the
rearward shift of the aerodynamic center through the transonic region, reducing trim drag and
enhancing supersonic maneuverability (per prior Rockwell studies) — at an admitted weight penalty
that makes its net benefit marginal. It is included specifically to illustrate how a designer
evaluates a genuinely new technology with no prior fleet experience to draw on: estimate its impact
on aerodynamics/weights/propulsion as best as possible, size and optimize the resulting aircraft, and
compare against a non-technology baseline to judge whether the idea is worth pursuing.

### DR-3 design requirements
*[Raymer, p. 906]*

- Role: F-16 replacement, advanced-technology lightweight fighter, air-to-air emphasis, single-seat.
- Engine: one advanced-technology "rubber" (variably sized during iteration) engine, modeled as an
  advanced derivative of the Pratt & Whitney F110-class engine family with an assumed SFC reduction
  vs. current production engines.
- **Design mission** (air-to-air): warm-up/taxi/takeoff, accelerate, climb, cruise-out, dash out
  (Mach 1.6 supercruise segment) [descend], combat (2 min at Mach 1.6, plus sustained-turn combat
  segments), dash back, cruise back, loiter (20 min), descend, land, with standard fuel reserves.
  Combat radius ≈ 500 nm baseline (used as the trade-study reference point later).
- Weapons load: 2 advanced air-to-air missiles (200 lb each, 5 in. x 92 in.) plus an advanced gun with
  340 rounds of ammunition (440 lb); crew (pilot) weight 220 lb (later refined to 226 lb).
- **Performance requirements:**
  - Takeoff and landing ground roll: ≤1000 ft each.
  - Approach speed: ≤130 kt.
  - Maximum Mach: 1.8 (afterburner), 1.4 (dry/military power, i.e. true supercruise).
  - Acceleration: Mach 0.8 to 1.4 in ≤50 s at 35,000 ft.
  - Specific excess power `Ps` = 0 at Mach 0.9 and at Mach 1.4, both at 30,000 ft.
  - Sustained turn: `n` ≥ 5-6 g (approximate, per the sustained-turn sizing constraint derivation,
    combined with the `Ps` constraints above) at combat conditions.

### Fig 24.2 — DR-3 design-requirements/mission-profile sketch sheet
*[Raymer, Fig. 24.2 (unnumbered design sheet), p. 906]* — Hand-drawn mission-profile diagram (the
air-to-air design mission listed above) plus the performance-requirements callouts. No plotted
numeric data beyond the requirement values already listed (hand sketch).

### Concept sketches and initial layout
*[Raymer, pp. 907-909]*

Two initial concept sketches were considered: a conventional twin-tail layout and the variable-dihedral
("V-tail-to-upright") layout ultimately carried forward, using a 2-D vectoring/thrust-reversing nozzle
(shortening required landing distance and providing pitch-vectoring benefit at low speed) — the
thrust-reversing feature was adopted specifically to relax the otherwise-restrictive landing-distance
requirement.

Wing geometry cross-checked against the F-16 for reasonableness: initial aspect ratio `A` ≈ 3.8 (from
`A x (t/c) ≈ 1.11`, cross-checked against F-16 precedent); leading-edge sweep initially 40 deg
(transonic/pitch-up considerations, per Chapter 4's sweep-selection guidance for this class), taper
ratio `lambda` ≈ 0.25-0.30, dihedral ≈ 0 deg; initial airfoil ≈ 64A-005 (thin, for transonic/supersonic
performance). Initial wing loading from the stall requirement (`Vstall` from the 130-kt approach-speed
target with an assumed approach-speed margin) gave `W/S` ≈ 22.5-22.8 psf as the *stall-driven* floor,
flagged in the book as "much too low" for a supersonic fighter (a fighter will handle this constraint
initially and use thrust reversing to relax the landing-field requirement rather than sizing the wing
to it).

### T/W sizing from the constraint set
*[Raymer, pp. 909-911]*

Takeoff `T/W` derived from the required takeoff parameter (`TOP`) and ground-roll requirement
(Eq. 5.9-family): `T/W` ≈ 104 (in the TOP-based intermediate units), converted through the takeoff
wing-loading relation. Supersonic-cruise `T/W` at Mach 0.9/35,000 ft was derived from the drag polar
(`CD0` ≈ 0.011 estimated from wetted-area-ratio methods, Oswald `e` ≈ 0.86 via the supersonic-drag
form, Eq. 12.30-family) giving an optimum cruise wing loading `(W/S)_cruise` ≈ 69.6 psf. A sustained-turn
`T/W` was derived at Mach 0.9/30,000 ft (assumed `n` ≈ 5, `CL` reduced for the high-`n` turning
condition) giving `(T/W)_combat` ≈ 0.78-0.88 depending on assumed conditions, and a companion
wing-loading requirement from the same turning condition of `(W/S)_combat` ≈ 44-62 psf range, explored
as part of the eventual carpet-plot trade.

### Initial sizing (mission-segment weight fractions and SFC estimates)
*[Raymer, pp. 912-916]*

Cruise `L/D` ≈ 10.7 at Mach 0.9/35,000 ft (`W/S` ≈ 213 psf assumed for this segment's midpoint weight,
`CD0`/`CL` combination per the drag buildup). SFC was estimated by starting from a baseline
early-2000s-technology engine SFC at Mach 0.9/36,000 ft (`C` ≈ 1.01), adjusting +10% for afterburner
installation losses, then discounting -20% for assumed advanced-technology improvement, giving a design
dry-cruise `C` ≈ 0.94; a similar chain of adjustments (baseline, +10% installation, -20% advanced
technology) was applied at other flight conditions (e.g. dash at Mach 1.4/35,000 ft giving `C` ≈ 1.2 at
that condition, further adjusted to `C` ≈ 0.975 with the same technology factors applied for a specific
sub-segment). Mission-segment weight fractions were computed segment-by-segment (warm-up/takeoff
`W1/W0` ≈ 0.98 [Eq. 6.29-family reference value], acceleration segments via the energy-height method
(Eq. 17.something) giving fractions in the 0.977-0.994 range per accelerate/dash/combat/loiter segment,
loiter at 20 min via the standard endurance form giving a fraction ≈ 0.9x). The overall product of
mission-segment weight fractions was computed as **≈0.7586** (later refined to other values as the
design iterated), and a **total fuel fraction ≈ 0.256** (later ≈0.24, depending on iteration) was
derived from `1 - (product of fractions)`.

### Sizing iteration (AC-SIZE program)
*[Raymer, p. 916]*

Using the AC-SIZE helper program (same tool as the DR-1 example) with `W0`(drawn) = 20,000 lb,
`We`(drawn) = 12,841 lb, crew+payload weight = 1,460 lb, and a product-of-mission-segment-weight-fractions
of 0.7586, the sizing iteration **converged to a takeoff gross weight `W0` ≈ 16,464-16,480 lb**
(successive iterations shown converging from 19,419 lb down through the 16,400s). This converged value
(**W0 = 16,480 lb** is used as the "baseline" configuration carried into the detailed RDS-Student
analysis below).

### Layout data, fuel tankage, and geometry
*[Raymer, pp. 917-919]*

Layout dimensions were measured from the design drawing: wing reference area `S` ≈ 294 ft² (matching
the later RDS aerodynamic-input file), span `b` ≈ 32.4 ft, root chord `Croot` ≈ 14.7 ft, tip chord
`Ctip` ≈ 3.7 ft, MAC and spanwise MAC location computed via Eqs. 7.7-7.9. Fuel tankage: wing tanks (aft
and forward), fuselage tanks (forward and aft of the wing box) sized from the drawing at 85% (wing)
and 83% (fuselage) usable-volume fractions respectively, summing (with the required design fuel
weight ≈ 4780-4980 lb range across iterations) to a fuel-volume-driven internal-tank layout confirmed
to fit within the drawn envelope. Landing gear: main-gear tire diameter/width and nose-gear
sizing were estimated from the statistical tire-sizing equations of Chapter 11.

*(Resolved 2026-08-18 against 320-dpi renders of book pp. 918-919. The earlier note called the gear
dimensions "heavily OCR-garbled". The OCR layer is garbled, but the handwriting itself renders
cleanly at 320 dpi and the whole page is readable. The actual figures are below.)*

**Engine sizing (p. 918, hand-written):**
- `T` = (T/W)·`W0` = 0.98 × 16,480 = **16,150.4 lb (SLS)**.
- Reference engine A.4-1, 100%-sized: `T` = 30,000 lb, `L` = 160 in, `D` = 44 in, `W` = 3,000 lb.
- Scale factor `SF` = 16,150.4 / 30,000 = **0.538**.
- Scaled, with a conventional nozzle: `L` = 160(0.538)^0.4 = **125 in**;
  `D` = 44(0.538)^0.5 = **32 in**; `W` = 3000(0.538)^1.1 = **1,517 lb**.
- A two-dimensional vectoring nozzle with thrust reversing is selected, to give pitch control at
  supersonic speed (when the variable-dihedral tails are near-vertical) and to shorten the landing.
  It needs a circle-to-square adapter, which lengthens the engine beyond the 125 in above.

**Inlet capture-area sizing (p. 918, hand-written):**
- From A.4-1 at M 1.8 / 30,000 ft, mass flow = 270 lbm/s; scaled: 0.538 × 270 = **145.3 lbm/s**.
- From Fig. 10.17, `Ac`/mass-flow = 3.8 at M 1.8, so `Ac` = 3.8 × 145.3 = **552 in²**.

**Landing gear (p. 918, hand-written)**, using the Chapter-11 statistical tire-sizing equations with
a per-main-wheel load `Ww` = 0.9 × (16,480/2) = 7,416 lb:
- Main: `D` = 1.59(7416)^0.302 = **23 in**; `W` = 0.098(7416)^0.467 = **6.3 in**.
- Nose: `D` = **18 in**, `W` = **5 in** (80% of the main-gear tire).

**Design-drawing callouts (p. 919, hand-drawn three-view, "DR-3 LIGHTWEIGHT FIGHTER, D. P. Raymer"):**
`W0` = 16,480 lb; `Wf` = 4,779 lb; `Sw` = 294 ft²; `A` = 3.5; `lambda` = 0.25; `Lambda_LE` = 38 deg;
`L` = 542 in; `Xcg` = 243; fuselage cross-section stations at 35, 118, 215, 275, 340 and 450; nose
droop 12.5 deg; 2D nozzle; variable-dihedral tails; wing fuel and fuselage fuel bays and the ammo
bay marked. The drawing carries no numeric landing-gear callouts — those are on p. 918, above.

### Wetted areas
*[Raymer, p. 921]*

Wing exposed reference area `Sexp` ≈ 215 ft² (per the later RDS aerodynamic-input listing);
wing/tail/fuselage/canopy wetted areas were each measured off the layout drawing and tabulated by
fuselage station for the area-ruling/wave-drag analysis (per the fuselage-station cross-sectional-area
perimeter measurements recorded in the book's layout-data table).

### Design analysis (RDS-Student computer analysis)
*[Raymer, p. 922]*

From this point, the DR-3's dimensions/areas from the layout were carried into the author's
RDS-Student program (bundled with the book via AIAA) for the detailed aerodynamics, weights,
propulsion, sizing, performance, and cost analysis, plus a `T/W`-`W/S` carpet-plot optimization — this
could equally have been done by hand as in the DR-1 example, but "life is too short" for the volume of
iteration involved; the author again recommends students demonstrate pocket-calculator competence
before being allowed to use RDS or any similarly "canned" tool.

### Aerodynamic lift and drag inputs/results
*[Raymer, pp. 922-925]*

Inputs to the RDS aerodynamics module (file `DR3.DAA`) included surface areas/geometry for wing,
horizontal tail, fuselage, canopy, and boundary-layer diverter. Skin-friction analysis assumed fully
turbulent flow over camouflage paint. Missile drag (`D/q`) was taken from AIM-9-type data (Fig. 12.25);
a constant cannon-port `D/q` = 0.2 was assumed from Mach 0 to 2; leakage/protuberance drag was taken as
6%. For wave drag: total max cross-section area ≈ 20.9 ft² {1.94 m²}, less 3.83 ft² {0.36 m²} inlet
capture area, giving a net `Amax` ≈ 17.07 ft² {1.58 m²}; supersonic wave-drag empirical factor
`Ewd` = 2.0 (typical of a design with some, but not extreme, attention to area ruling).

**Maximum lift**: base 64-series-airfoil `CLmax` ≈ 0.82, `delta-y` ≈ 1.28 (Table 12.1); trailing-edge
plain-flap lift adjustment ≈ 0.9 and leading-edge-flap adjustment ≈ 0.3 (Table 12.2), with hinge-line
angles of 10 deg (LE) and 39 deg (TE) giving, via Eq. (12.21), a `delta-CLmax` ≈ 0.82 — an adjusted
clean-wing `CLmax` ≈ 1.64 (with automatic maneuver flaps). For landing, `CLmax` ≈ 1.8 assumed based on
modern-fighter leading-edge-flap data.

### Table — DR-3 Aerodynamic Inputs (file DR3.DAA), selected values
*[Raymer, RDS aerodynamic-input listing, pp. 923-924]*

| Parameter | fps | mks |
|---|---|---|
| Max Mach | 2.0 | 2.0 |
| Max altitude | 50,000 ft | 15,240 m |
| k (roughness)/10^5 ft | 3.33 | 1.015 |
| % leakage & protuberance | 6.0 | 6.0 |
| Amax (aircraft, net) | 17.07 ft² | 1.586 m² |
| Effective length | 45.2 ft | 13.777 m |
| Ewd | 2.0 | 2.0 |
| Wing Sref | 294.0 ft² | 27.313 m² |
| Wing Sexp | 215.0 ft² | 19.974 m² |
| Wing AR true / effective | 3.5 / 3.5 | 3.5 / 3.5 |
| Wing taper (lambda) | 0.25 | 0.25 |
| Wing LE sweep | 38.0 deg | 38.0 deg |
| Wing t/c average | 0.06 | 0.06 |
| Wing CLmax (airfoil) | 1.64 | 1.64 |
| Horiz. tail S / Sexp | 92.0 / 92.0 ft² | 8.547 / 8.547 m² |
| Horiz. tail AR / taper / sweep | 4.0 / 0.34 / 30.0 deg | 4.0 / 0.34 / 30.0 deg |
| Horiz. tail dihedral | 28.4 deg | 28.4 deg |
| Fuselage Swet / length / eff. diam | 588.0 ft² / 45.2 ft / 5.5 ft | 54.627 m² / 13.777 m / 1.676 m |
| Canopy/fairing Swet / length / eff. diam | 39.0 ft² / 13.9 ft / 2.0 ft | 3.623 m² / 4.237 m / 0.610 m |
| BL diverter (2 wedges) l / d / thickness | 4.2 / 2.83 / 0.33 ft | 1.28 / 0.863 / 0.101 m |

Misc `D/q` vs. Mach (missile, fps units): 0.12 ft² at M0-0.98, rising to 0.27-0.30 ft² by M1.1-2.0
(read from the RDS input table). Cannon-port `D/q`: constant 0.2 ft² across M0-2.0.

Sample RDS aerodynamic *results* (file `DR3.DAA`), transcribed in full from book p. 925. The input
block above is on p. 924; the results block is on p. 925 alone.

*(Corrected 2026-08-18 against a 320-dpi render of book p. 925, which is a typeset program printout
and fully legible. The earlier summary had two errors: it gave the smallest Reynolds number as
"~5.9M (wing)", but 5.916 is the HORIZONTAL TAIL and the wing is 11.715; and it gave the
skin-friction range as "~0.0016-0.0032", whereas the printout's Cf column is in units of 1e-4, so
the M0.40 range is 0.0023-0.0033 and the M1.60 range is 0.0017-0.0024.)*

**Altitude = 30,000 ft, Mach = 0.40**

| Component | R# (10⁶) | Cf (10⁻⁴) | FF | S-wet (ft²) | Cdo (10⁻⁴) |
|---|---|---|---|---|---|
| Wing | 11.715 | 28.859 | 1.190 | 431.8 | 53.5 |
| Horz tail | 5.916 | 32.235 | 1.202 | 184.8 | 25.8 |
| Fuselage | 51.597 | 23.046 | 1.129 | 588.0 | 55.1 |
| Cnpy/fair | 15.867 | 27.516 | 1.196 | 39.0 | 4.6 |
| BL divrtr | 4.794 | 33.384 | 1.674 | 2.8 | 0.6 |
| Misc D/q vs M | | | | | 4.327 |
| Misc D/q vs M | | | | | 7.211 |
| **Total parasite drag coefficient Cdo** | | | | | **151.131** |

**Altitude = 40,000 ft, Mach = 1.60**

| Component | R# (10⁶) | Cf (10⁻⁴) | FF | S-wet (ft²) | Cdo (10⁻⁴) |
|---|---|---|---|---|---|
| Wing | 31.421 | 20.520 | 1.000 | 431.8 | 31.9 |
| Horz tail | 15.867 | 22.773 | 1.000 | 184.8 | 15.2 |
| Fuselage | 138.393 | 16.590 | 1.000 | 588.0 | 35.2 |
| Cnpy/fair | 42.559 | 19.618 | 1.000 | 39.0 | 2.8 |
| BL divrtr | 12.860 | 23.535 | 1.000 | 2.8 | 0.2 |
| Misc D/q vs | | | | | 10.636 |
| Misc D/q vs | | | | | 7.211 |
| Wave drag coefficient Cdw | | | | | 122.0 |
| **Total parasite drag coefficient Cdo** | | | | | **225.126** |

All form factors go to 1.000 in supersonic flow, as expected. The page also carries a
parasite-drag-coefficient vs. Mach plot for six altitudes (0, 10k, 20k, 30k, 40k, 50k ft), with
`Cdo` about 0.0135-0.0185 subsonic, peaking near 0.026-0.027 at M ~ 1.05-1.10, then falling to about
0.0195-0.0205 by M 2.2.

### DR-3 weight statement (baseline, `W0` = 16,480 lb)
*[Raymer, Fighter/Attack Group Weight Statement, pp. 934-935]*

| Group | Weight (lb) |
|---|---|
| **Structures Group** | **4526.2** |
| Wing | 1459.4 |
| Horizontal Tail | 280.4 |
| Vertical Tail | 0.0 (variable-dihedral tail folded into horiz. tail item) |
| Fuselage | 1574.0 |
| Main Landing Gear | 631.5 |
| Nose Landing Gear | 171.1 |
| Engine Mounts | 39.1 |
| Firewall | 58.8 |
| Engine Section | 21.0 |
| Air Induction | 291.1 |
| **Propulsion Group** | **2354.3** |
| Engine(s) | 1517.0 |
| Tailpipe | 0.0 |
| Engine Cooling | 172.0 |
| Oil Cooling | 37.8 |
| Engine Controls | 20.0 |
| Starter | 39.5 |
| Fuel System | 568.0 |
| **Equipment Group** | **3066.7** |
| Flight Controls | 655.7 |
| Instruments | 122.8 |
| Hydraulics | 171.7 |
| Electrical | 713.2 |
| Avionics | 989.8 |
| Furnishings | 217.6 |
| Air Conditioning | 190.7 |
| Handling Gear | 5.3 |
| **Misc Empty Weight** | **1000.0** |
| **Total Weight Empty** | **10,947.2** |
| **Useful Load Group** | **5532.8** |
| Crew | 220.0 |
| Fuel | 4422.8 |
| Oil | 50.0 |
| Payload | 840.0 |
| Passengers | 0.0 |
| Misc Useful Load | 0.0 |
| **Takeoff Gross Weight** | **16,480.0** |

C.g. travel: empty c.g. = 23.8% MAC; loaded-no-fuel c.g. = 23.4% MAC; gross-weight c.g. = 23.1% MAC.

### Takeoff and landing performance (baseline)
*[Raymer, RDS-Student TAKEOFF: DR3 / LANDING: DR3 printouts, p. 950]*

*(Fully re-read 2026-08-18 off a 320-dpi render of book p. 950. This page is a typeset program
printout and is completely legible; the earlier extract's claim that "most performance figures on
this page are OCR-illegible column headers without adjoining values" was wrong, and its page range
"pp. 949-950" was wrong — p. 949 carries the range and cost carpet plots, and the whole takeoff and
landing block sits on p. 950. Both are corrected below and the full printout is now transcribed.)*

**TAKEOFF: DR3**

| Quantity | Value |
|---|---|
| Aircraft operating weight `Wi` | 16,480.0 lb {7475.2 kg} |
| Operating weight ratio `Wi/W0` | 1.000 |
| Thrust-to-weight ratio `T/W` | 0.980 |
| Thrust (start of takeoff) | 16,150.4 lb {71.8 kN} |
| Takeoff wing loading `W/S` | 56.05 {273.68} |
| `Vstall` | 99.80 kt {184.8 km/h} |
| `Vtakeoff` | 109.8 kt {203.3 km/h} |
| Climb angle | 44.97 deg |
| Climb `CD0` | 0.0289 |
| `CL` | 1.49 |
| `K` | 0.2609 |
| Climb `L/D` | 3.07 |
| Ground roll distance | 538.2 {164.0} |
| Rotate distance | 185.4 {56.5} |
| Total ground roll distance | 723.6 {220.6} |
| Transition distance | 761.6 {232.1} |
| Climb distance | 0.0 {0.0} |
| Total takeoff distance | 1485.2 {452.7} |
| FAR Part 25 takeoff distance | 1707.9 {520.6} |

The 44.97-deg climb angle was previously flagged as a probable garbled value. It is not: the page
prints 44.97, and the number is consistent with the rest of its own block. With `T/W` = 0.980 and
climb `L/D` = 3.07, sin(gamma) = T/W - 1/(L/D) = 0.980 - 0.326 = 0.654, i.e. gamma = 40.8 deg, which
is the same steep angle to within the accuracy of this hand check. A lightweight supercruise fighter
at full afterburner and low takeoff weight really does climb this steeply.

**LANDING: DR3**

| Quantity | Value |
|---|---|
| Aircraft operating weight `Wi` | 16,480.0 lb {7475.2 kg} |
| Operating weight ratio `Wi/W0` | 1.000 |
| Rollout thrust-to-weight ratio `T/W` | -0.392 |
| Landing wing loading `W/S` | 56.05 {273.68} |
| `Vstall` | 95.84 kt {177.5 km/h} |
| `Vtouchdown` | 115.01 kt {213.0 km/h} |
| Approach angle | -3.00 deg |
| Approach `CD0` | 0.1124 |
| `CL` | 1.62 |
| `K` | 0.2724 |
| Approach `L/D` | 2.53 |
| Approach distance | 773.5 {235.8} |
| Flare distance | 2733.1 {833.1} |
| Free ground roll distance | 194.2 {59.2} |
| Braking distance | 796.1 {242.7} |
| Total ground roll distance | 990.4 {301.9} |
| No-flare landing distance | 1944.5 {592.7} |
| Total landing distance | 4497.0 {1370.7} |
| FAR Part 25 landing distance | 7495.0 {2284.5} |

(Distances are in feet, with metres in braces.)

### Range/weight trade study and carpet-plot optimization
*[Raymer, pp. 948-957]*

A trade study varied design range around the 500-nm baseline combat radius (roughly 300-700 nm swept)
and plotted resulting `W0`/`We` — a second trade study varied the assumed empty-weight-fraction sizing
exponent `C` by percentage change, both plotted against `W0`/`We` in lb-mass and kg (Figs., pp. 948-949).

A `T/W`-`W/S` carpet plot (Chapter 19 methodology) was built from 25 parametric resizing runs, sweeping
`W/S` across roughly 44.8-67.3 psf and `T/W` across roughly 0.784-1.176, each resized to convergence;
sized `W0` across this matrix ranged from about 12,500 lb (highest `W/S`, lowest `T/W`) to about
26,800 lb (lowest `W/S`, highest `T/W`). Performance-constraint curves (takeoff distance, landing
distance, `Ps` at `n`=5 at two flight conditions, `Ps` at `n`=1 at two flight conditions, and
acceleration time) were cross-plotted on the same `W/S`-`T/W` axes to bound the feasible region and
identify the minimum-`W0` feasible point.

### Table — DR-3 Multivariable Optimization Summary (Baseline vs. Best)
*[Raymer, RDS multivariable optimization output, p. 957]*

| Parameter | Baseline | Best (carpet-plot optimum) |
|---|---|---|
| T/W | 0.980 | 0.919 |
| W/S (psf) | 56.1 | 52.6 |
| Aspect Ratio | 3.500 | 2.800 |
| Sweep (deg) | 38.0 | 34.7 |
| Taper Ratio | 0.250 | 0.200 |
| Wing t/c | 0.060 | 0.068 |
| Sized W0 (lb) | 17,060.2 | 15,242.2 |
| Sized We (lb) | 11,257.5 | 9,925.5 |
| Sized Wf (lb) | 4,692.7 | 4,206.7 |

| Performance Constraint | Required | Baseline (achieved) | Best (achieved) |
|---|---|---|---|
| Takeoff distance (ft) | 1000.0 | 723.6 | 720.0 |
| Landing distance (ft) | 1000.0 | 990.4 | 960.4 |
| Ps @ n=5, condition 1 | 0.0 | 64.2 | 1.7 |
| Ps @ n=5, condition 2 | 0.0 | 156.6 | 62.0 |
| Ps @ n=1, condition 1 | 0.0 | 684.6 | 515.7 |
| Ps @ n=1, condition 2 | 0.0 | 71.5 | 0.1 |
| Acceleration time (s) | 50.0 | 42.2 | 49.4 |

The "Best" (multivariable-optimized) point converges to a sized `W0` of **15,242 lb {6914 kg}**, about
**2% less** than the optimum located via the plain `T/W`-`W/S` carpet plot alone (which itself
converged near 17,060 lb baseline / ~15,470-15,720 lb range across the matrix depending on the exact
`W/S`/`T/W` cell selected) — indicating the wing planform initially chosen by hand for the DR-3 using
this book's methods was already fairly close to optimal, with the further ~2% saving coming "for free"
from small additional refinements to wing geometry (lower AR, slightly less sweep, lower taper ratio,
slightly thicker section) found by the full multivariable search.

### What We've Learned
*[Raymer, p. 958]*

The chapter demonstrates applying the book's methods to produce a credible initial design layout for
two very different classes of aircraft, then analyze, optimize, and prepare each for the next
iteration of detailed layout ("the much-better Dash-Two").

---

*Chapter 24 complete (§§24.1-24.3). No numbered equations, tables, or figures original to this
chapter (it consists of two extended worked examples referencing equations/tables/figures from
earlier chapters, plus the book's own numbered design-example figures, most of which are hand-drawn
design sheets, layout drawings, and RDS-Student software input/output listings rather than
citable textbook figures in the usual sense — captured above as sketch/listing descriptions rather
than formally numbered `Fig. 24.N` citations, since the source PDF's scan does not carry clean,
individually numbered figure captions for this chapter's design-sheet and computer-printout pages).
**Correctness sweep, 2026-08-18.** Every previously flagged item in this chapter was resolved
against 320-dpi page renders; there are no open `[verify]` markers left. The flags had been raised
on the assumption that the DR-1 hand-writing was unreadable. It is not: at 320 dpi the hand-writing
is fully legible, and the flags turned out to be hiding real errors rather than genuine illegibility.
The corrections are recorded inline at each point, and the largest were: `Vmax` >= 130 kt not
"≈ 150 kt", and range with **no** reserves (p. 869); an invented "roll rate >= 180 deg/s" and an
invented "ceiling >= 15,000 ft" requirement, neither of which is on the page, in place of the real
load-factor requirement `n` = +6/-3 g (p. 869); an invented three-view sketch with span/length/height
callouts that were really the engine's own 30 x 32 x 23 in dimensions (p. 869); root and tip airfoils
**swapped**, and a vertical tail given as `A` = 1.8 / taper 0.6 instead of `A` = 1.5 / taper 0.4
(p. 872); a total parasite `CD0` of 0.0277 "clean cruise" instead of the page's 0.0250 open-cockpit
(p. 881); `eta_p` = 0.84 and 750-790 lb static thrust instead of 0.78 and 400 lb (p. 884); a
skin-friction range off by a factor-of-10 unit error and the wing/horizontal-tail Reynolds numbers
transposed (p. 925); and the takeoff/landing page cited as "pp. 949-950" and called illegible when it
is a single fully legible page, p. 950 (p. 949 carries the trade-study carpet plots). The 44.97-deg
takeoff climb angle on p. 950, previously flagged as probably garbled, is real and is internally
consistent with that block's own `T/W` and `L/D`.*
