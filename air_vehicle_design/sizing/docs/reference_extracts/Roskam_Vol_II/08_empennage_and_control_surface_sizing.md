# Chapter 8 — Class I Method for Empennage Sizing and Disposition and for Control Surface Sizing and Disposition

**Source:** J. Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration of the Propulsion System*, Chapter 8 "Class I Method for Empennage Sizing and Disposition and for Control Surface Sizing and Disposition," printed pp. 187–216.

This chapter gives the tail-volume-coefficient (V-bar) method for a first cut at horizontal and
vertical tail area, plus twelve tables of statistical volume coefficients and control surface
ratios for twelve airplane categories. It is Step 8 of preliminary design sequence I (Chapter 2).
Section 8.1 is the method; Section 8.2 gives three worked examples.

**Definitional note (read before you implement anything):** all quantities in Eqs. (8.1)–(8.4) are
defined by Figure 8.1 (p. 189). In that figure the hatched areas that carry the symbols S, S_h
and S_v extend across the fuselage centerline. They are **full (gross) planform** areas, not
exposed areas. See the "How the volume coefficients are defined" subsection below for the full
list of definitions, because the tables are only usable if you match Roskam's definitions exactly.

---

## 8.1 Step-by-Step Method for Empennage Sizing and Disposition and for Control Surface Sizing and Disposition

### Step 8.1: Decide on the overall empennage configuration to be used

Roskam refers the reader to sub-section 3.3.5 for the possible empennage arrangements.

General rule: do **not** put the horizontal tail directly in the propeller slipstream. Many
airplanes in Section 3.1 do have the tail in the slipstream. The reasons against it are:

a. The slipstream usually makes the tail buffet. This gives structure-borne cabin noise. Tail
   buffet can also give early structural fatigue.
b. Fast power increases or decreases by the pilot can give undesirably large trim changes.

The same comments apply to canards. A vertical tail in the slipstream at the aft end of a
fuselage is not usually a problem.

**Note (p. 187):** single-engine propeller-driven airplanes usually do have the empennage in the
slipstream. This increases elevator and rudder effectiveness during the take-off roll. It also
causes much tail buffet during the take-off roll on some airplanes.

### Step 8.2: Determine the disposition of the empennage

Decide where the empennage components go on the airplane. This means deciding the empennage
moment arms x_h, x_v and x_c as defined in Figure 8.1. Get the moment arms from the general
arrangement drawing of the fuselage prepared in Chapter 4.

**Tail-arm vs. tail-area trade (p. 188).** To keep airplane weight and drag as low as possible,
keep the empennage area as small as possible. To do this, put the empennage components at as
large a moment arm as possible, measured from the **critical center of gravity**:

- conventional layouts: the **aft** c.g. is critical;
- canard: the **forward** c.g. is critical.

**Note (p. 188):** some airplanes (carrier-based airplanes are one example) have severe limits on
allowable length, height and width. This limits how large the moment arm can be.

*(Roskam gives no numeric "tail arm as a fraction of fuselage length" rule of thumb in this
chapter. The moment arms come from the Chapter 4 fuselage arrangement drawing, and the x_h and
x_v columns of Tables 8.1–8.12 are the statistical data that stand in for such a rule.)*

### Step 8.3: Determine the size of the empennage

Four configuration types are treated:

a. Conventional configurations
b. Canard configurations
c. Three-surface configurations
d. Butterfly (V) empennage configurations

*(The book prints "Three types of configurations will be considered:" and then lists four items
a.–d. This is a printed inconsistency, p. 188.)*

---

### a. Conventional configurations

Sizing the empennage of a conventional configuration means deciding the magnitude of S_h and S_v.
For a first cut at either the vertical or the horizontal tail, the so-called **V-bar method** is
often used. The tail volume coefficients are defined as follows.

#### Figure 8.1 — Definition of Volume Coefficient Quantities
*[Roskam Part II, Fig. 8.1, p. 189]* — Sketches (a twin-turboprop transport in plan and side view,
and a single-engine light airplane in side view) with the volume-coefficient quantities called
out. No plotted data. Symbols shown: b (wing span), c-bar (wing mean geometric chord), S (wing
area, hatched, full planform through the fuselage), S_h (horizontal tail area, hatched, full
planform through the fuselage), c-bar_h (horizontal tail m.g.c.), S_v (vertical tail area,
hatched), c-bar_v (vertical tail m.g.c.), x_h and x_v (the moment arms), plus the c.g. symbol
(filled circle) and the a.c. symbol (cross).

**How the volume coefficients are defined (read from Fig. 8.1):**

| Symbol | Definition in Fig. 8.1 |
|---|---|
| S | Wing **reference (full/gross) planform** area. The hatching runs across the fuselage, so the carry-through is included. Not the exposed area. |
| c-bar | Wing **mean geometric chord** (labelled "mgc" in every table). It is the reference length for the horizontal tail volume coefficient. |
| b | Wing **span**, tip to tip. It is the reference length for the vertical tail volume coefficient. |
| S_h | Horizontal tail **full/gross planform** area. The hatching again runs across the fuselage centerline. |
| S_v | Vertical tail area (fin planform). |
| c-bar_h | Horizontal tail mean geometric chord. Not used in Eq. (8.1); shown to locate the tail a.c. |
| c-bar_v | Vertical tail mean geometric chord. Not used in Eq. (8.2); shown to locate the tail a.c. |
| x_h | Horizontal tail moment arm, measured **from the airplane c.g.** to the **a.c. of the horizontal tail**. In Fig. 8.1 the a.c. cross sits on c-bar_h at about the quarter-chord point. The dimension arrow runs from the c.g. mark at the wing back to the tail a.c. station. |
| x_v | Vertical tail moment arm, measured **from the airplane c.g.** to the **a.c. of the vertical tail** (the cross on c-bar_v). |
| x_c | Canard moment arm (named in Step 8.2; the canard case is item b below). |

Because the moment arm starts at the c.g., and the c.g. moves, Step 8.2 tells you to use the
**critical** c.g.: aft c.g. for a conventional layout, forward c.g. for a canard.

#### Equations (8.1)–(8.2) — tail volume coefficient definitions
*[Roskam Part II, p. 190]*

```
V-bar_h = x_h * S_h / (S * c-bar)                                   (8.1)

V-bar_v = x_v * S_v / (S * b)                                       (8.2)
```

Note the different reference lengths: the **horizontal** tail volume coefficient is
non-dimensionalized on the wing **mean geometric chord**; the **vertical** on the wing **span**.
Both use the **same** wing reference area S.

#### Equations (8.3)–(8.4) — tail areas from selected volume coefficients
*[Roskam Part II, p. 190]*

```
S_h = V-bar_h * S * c-bar / x_h                                     (8.3)

S_v = V-bar_v * S * b / x_v                                         (8.4)
```

Method text (p. 190), paraphrased:

- Tables 8.1 through 8.12 give tail volume coefficients for twelve types of airplanes.
- Decide which type best fits the airplane being designed. Then select values for V-bar_h and
  V-bar_v. Do this by averaging the table, or by comparison with one specific type.
- When you select V-bar_v, make sure the lateral position of the engines of the comparison
  airplanes is not too different from yours.
- Vertical tail size is often set by the engine-out (V_mc) condition, not by the volume
  coefficient. Section 11.3 of Part II gives a vertical tail sizing procedure for V_mc.
- Then take x_h and x_v from the Step 8.2 fuselage arrangement sketches and compute S_h and S_v
  from Eqs. (8.3) and (8.4).

**Twin vertical tails (p. 190).** Supersonic fighter configurations (Figures 3.25a and 3.27b of
Part II) sometimes use twin vertical tails. This avoids one very large fin. The lateral position
of twin verticals is a critical problem because of vortex shedding from the fuselage. The vortices
can cause structural fatigue and can reduce tail effectiveness.

---

## Tables 8.1–8.12 — Tail volume coefficients and control surface data

**Column definitions common to all twelve tables** (printed in each table header):

| Column | Symbol | Units / basis |
|---|---|---|
| Wing Area | S | ft² (full planform) |
| Wing mgc | c-bar | ft |
| Wing Span | b | ft |
| Wing Airfoil | — | NACA designation unless otherwise indicated; root/tip |
| Hor. Tail Area | S_h | ft² |
| Vert. Tail Area | S_v | ft² |
| S_e/S_h | — | elevator area as a **fraction of horizontal tail area** |
| S_r/S_v | — | rudder area as a **fraction of vertical tail area** |
| x_h, x_v | — | ft (moment arms, c.g. to tail a.c., per Fig. 8.1) |
| V-bar_h, V-bar_v | — | dimensionless, per Eqs. (8.1) and (8.2) |
| Elevator Chord | c_e | root/tip, as a **fraction of the horizontal tail chord c_h** ("fr.c_h") |
| Rudder Chord | c_r | root/tip, as a **fraction of the vertical tail chord c_v** ("fr.c_v") |
| S_a/S | — | **total aileron area** as a fraction of the **wing area S** (not of the exposed wing) |
| Ail. Span Loc. | — | inboard/outboard end of the aileron as a fraction of the **wing semi-span, b/2** ("fr.b/2") |
| Ail. Chord | c_a | inboard/outboard, as a fraction of the **local wing chord c_w** ("fr.c_w") |

In the "Type" column Roskam prints the manufacturer on its own line, then the model(s) of that
manufacturer on the following data line(s). The transcriptions below keep that structure by
prefixing the model with its manufacturer.

### Table 8.1a) Homebuilt Airplanes: Horizontal Tail Volume and Elevator Data
*[Roskam Part II, Table 8.1a, p. 191]*

| Type | S (ft²) | c-bar (ft) | Wing Airfoil root/tip (NACA*) | S_h (ft²) | S_e/S_h | x_h (ft) | V-bar_h | Elevator Chord root/tip (fr.c_h) |
|---|---|---|---|---|---|---|---|---|
| PIK-21 | 76.4 | 4.50 | 64212 | 10.4 | 0.45 | 10.1 | 0.30 | 0.45 |
| Duruble RD-03C | 119 | 4.30 | 23018/23012 | 22.2 | 0.33 | 11.3 | 0.49 | .47/.32 |
| Piel CP-750 | 118 | 3.82 | 23012 | 23.5 | 0.51 | 12.6 | 0.66 | .55/.47 |
| Piel CP-90 | 104 | 3.81 | NA | 22.3 | 0.50 | 11.8 | 0.66 | .56/.38 |
| Pottier P-50R | 80.7 | 3.74 | 23015/23012 | 13.4 | 0.52 | 10.6 | 0.47 | .50/.55 |
| Pottier P-70S | 77.5 | 4.10 | 4415 | 14.5 | 0.60 | 9.68 | 0.44 | 0.60 |
| O-O Aerosport | 80.7 | 3.77 | 23012 | 15.4 | 0.48 | 10.6 | 0.54 | 0.48 |
| Aerocar Micro-Imp | 81.0 | 3.00 | GA(Pc)-1 | 11.7 | 0.25 | 6.27 | 0.30 | .28/.33 |
| Coats SA-III | 112 | 4.50 | 63415 | 16.5 | 0.46 | 10.9 | 0.36 | 0.46 |
| Sequoia 300 | 130 | 4.37 | 64₂A215/64A210 | 25.5 | 0.43 | 13.2 | 0.59 | 0.43 |
| Ord-Hume OH-4B | 125 | 5.25 | RAF48 | 25.4 | 0.49 | 11.1 | 0.43 | 0.49 |
| Procter Petrel | 135 | 4.54 | 3415 | 26.0 | 0.52 | 12.2 | 0.52 | 0.52 |
| Bede BD-8 | 96.7 | 5.0 | 63₂015 | 19.4 | 0.14 | 7.64 | 0.31 | 0.17 |

\* Unless otherwise indicated.

Note: the manufacturer line printed above the "Aerosport" row reads **`O-O`** in the scan. It was
checked at 1000 dpi and it is unambiguously two capital letters O with a hyphen between them. The
chapter does not say what company it stands for.

### Table 8.1b) Homebuilt Airplanes: Vertical Tail Volume, Rudder and Aileron Data
*[Roskam Part II, Table 8.1b, p. 191]*

| Type | S (ft²) | b (ft) | S_v (ft²) | S_r/S_v | x_v (ft) | V-bar_v | Rudder Chord root/tip (fr.c_v) | S_a/S | Ail. Span Loc. in/out (fr.b/2) | Ail. Chord in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|---|---|
| PIK-21 | 76.4 | 17.0 | 3.49 | 0.33 | 10.5 | 0.028 | .24/.49 | 0.130 | 0/1.0 | 0.13 |
| Duruble RD-03C | 119 | 28.7 | 8.35 | 0.30 | 12.5 | 0.031 | .38/.32 | 0.063 | .63/.93 | .22/.24 |
| Piel CP-750 | 118 | 26.4 | 9.49 | 0.55 | 12.9 | 0.039 | .50/.64 | 0.077 | .44/.96 | .19/.14 |
| Piel CP-90 | 104 | 23.6 | 7.64 | 0.50 | 11.9 | 0.037 | .47/.54 | 0.092 | .42/.91 | .22/.18 |
| Pottier P-50R | 80.7 | 20.3 | 11.3 | 0.42 | 10.4 | 0.072 | .34/.61 | 0.067 | .60/.98 | .24/.22 |
| Pottier P-70S | 77.5 | 19.4 | 4.36 | 0.67 | 10.5 | 0.031 | .59/.76 | 0.082 | .52/.88 | 0.20 |
| O-O Aerosport | 80.7 | 21.3 | 6.86 | 0.38 | 10.0 | 0.040 | .34/.44 | 0.080 | .54/.97 | 0.19 |
| Aerocar Micro-Imp | 81.0 | 27.0 | 7.15 | 0.31 | 6.27 | 0.020 | .33/.43 | 0.140 | .07/.95 | 0.16 |
| Coats SA-III | 112 | 25.0 | 7.53 | 0.44 | 10.6 | 0.028 | .35/.68 | 0.130 | .55/1.0 | 0.26 |
| Sequoia 300 | 130 | 30.0 | 16.5 | 0.31 | 13.2 | 0.055 | .27/.43 | 0.085 | .60/.95 | 0.29 |
| Ord-Hume OH-4B | 125 | 25.0 | 6.73 | 0.71 | 12.5 | 0.027 | .57/1.0 | 0.110 | .35/.91 | 0.20 |
| Procter Petrel | 135 | 30.0 | 11.7 | 0.35 | 11.4 | 0.033 | .31/.57 | 0.097 | .62/.98 | 0.26 |
| Bede BD-8 | 96.7 | 19.3 | 6.89 | 0.24 | 8.65 | 0.032 | .20/.34 | 0.083 | .53/.92 | 0.22 |

### Table 8.2a) Single Engine Propeller Driven Airplanes: Horizontal Tail Volume and Elevator Data
*[Roskam Part II, Table 8.2a, p. 192]*

| Type | S (ft²) | c-bar (ft) | Wing Airfoil root/tip (NACA*) | S_h (ft²) | S_e/S_h | x_h (ft) | V-bar_h | Elevator Chord root/tip (fr.c_h) |
|---|---|---|---|---|---|---|---|---|
| Cessna Skywagon 207 | 174 | 4.55 | 2412 | 44.9 | 0.45 | 16.2 | 0.92 | .48/.47 |
| Cessna Cardinal RG | 174 | 4.79 | 64A215/64A412 | 35.0 | 1.00 | 14.3 | 0.60 | stabilator |
| Cessna Skylane RG | 174 | 4.52 | 2412 | 38.8 | 0.41 | 14.3 | 0.71 | .47/.39 |
| Piper Cherokee Lance | 175 | 5.25 | 65₂415 | 34.6 | 1.00 | 16.1 | 0.61 | stabilator |
| Piper Warrior | 170 | 4.44 | 65₂415 | 26.5 | 1.00 | 13.5 | 0.48 | stabilator |
| Piper Turbo Saratoga SP | 178 | 4.71 | NA | 36.2 | 1.00 | 16.2 | 0.70 | stabilator |
| Bellanca Skyrocket | 183 | 5.30 | 63₂215 | 42.6 | 0.38 | 13.8 | 0.61 | .36/.42 |
| Grumman Tiger | 140 | 4.44 | NA | 37.6 | 0.28 | 12.6 | 0.76 | 0.39 |
| Rockwell Commander | 152 | 4.58 | 63415 | 31.2 | 0.34 | 10.9 | 0.49 | .33/.44 |
| Trago Mills SAH-1 | 120 | 3.94 | 2413.6 | 22.0 | 0.46 | 17.8 | 0.83 | 0.46 |
| Scottish Aviation Bullfinch | 129 | 3.97 | 63₂615 | 27.5 | 0.58 | 11.9 | 0.63 | 0.45 |

\* Unless otherwise indicated.

### Table 8.2b) Single Engine Propeller Driven Airplanes: Vertical Tail Volume, Rudder and Aileron Data
*[Roskam Part II, Table 8.2b, p. 192]*

| Type | S (ft²) | b (ft) | S_v (ft²) | S_r/S_v | x_v (ft) | V-bar_v | Rudder Chord root/tip (fr.c_v) | S_a/S | Ail. Span Loc. in/out (fr.b/2) | Ail. Chord in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|---|---|
| Cessna Skywagon 207 | 174 | 35.8 | 16.0 | 0.44 | 18.0 | 0.046 | .46/.46 | 0.10 | .61/.94 | .25/.22 |
| Cessna Cardinal RG | 174 | 35.5 | 17.4 | 0.37 | 13.5 | 0.038 | .35/.43 | 0.11 | .65/.97 | .38/.37 |
| Cessna Skylane RG | 174 | 35.8 | 18.6 | 0.37 | 15.8 | 0.047 | .41/.42 | 0.11 | .47/.96 | .17/.24 |
| Piper Cherokee Lance | 175 | 32.8 | 13.8 | 0.31 | 15.3 | 0.037 | .26/.50 | 0.064 | .56/.88 | 0.20 |
| Piper Warrior | 170 | 35.0 | 11.5 | 0.36 | 13.2 | 0.026 | .29/.52 | 0.078 | .48/.96 | .27/.24 |
| Piper Turbo Saratoga SP | 178 | 36.2 | 15.9 | 0.29 | 15.2 | 0.038 | .23/.58 | 0.057 | .52/.84 | 0.19 |
| Bellanca Skyrocket | 183 | 35.0 | 18.1 | 0.33 | 13.2 | 0.037 | .28/.40 | 0.076 | .60/1.0 | .25/.22 |
| Grumman Tiger | 140 | 31.5 | 8.4 | 0.43 | 12.6 | 0.024 | .36/.46 | 0.055 | .56/.92 | 0.24 |
| Rockwell Commander | 152 | 32.8 | 17.0 | 0.28 | 11.4 | 0.039 | .30/.46 | 0.072 | .64/.97 | .27/.36 |
| Trago Mills SAH-1 | 120 | 30.7 | 17.1 | 0.40 | 18.6 | 0.086 | .35/.54 | 0.080 | .58/.97 | .25/.29 |
| Scottish Aviation Bullfinch | 129 | 33.8 | 22.7 | 0.39 | 11.9 | 0.062 | .35/.56 | 0.073 | .61/.95 | .23/.30 |

### Table 8.3a) Twin Engine Propeller Driven Airplanes: Horizontal Tail Volume and Elevator Data
*[Roskam Part II, Table 8.3a, p. 193]*

| Type | S (ft²) | c-bar (ft) | Wing Airfoil root/tip (NACA*) | S_h (ft²) | S_e/S_h | x_h (ft) | V-bar_h | Elevator Chord root/tip (fr.c_h) |
|---|---|---|---|---|---|---|---|---|
| Cessna 310R | 179 | 4.77 | 23018/23009 | 54.3 | 0.41 | 14.9 | 0.95 | .42/.39 |
| Cessna 402B | 196 | 4.77 | 23018/23009 | 60.7 | 0.29 | 16.5 | 1.07 | .41/.39 |
| Cessna 414A | 226 | 4.73 | 23018/23009 | 60.7 | 0.27 | 16.4 | 0.93 | .37/.38 |
| Cessna T303 | 189 | 4.9 | 23017/23012 | 48.1 | 0.42 | 14.9 | 0.78 | .41/.44 |
| Piper PA-31P | 229 | 5.79 | 63₂415/63₁212 | 68.7 | 0.44 | 16.2 | 0.84 | .41/.51 |
| Piper PA-44-180T | 184 | 4.34 | NA | 23.4 | 1.0 | 15.7 | 0.46 | stabilator |
| Piper Chieftain | 229 | 6.00 | 63₂A415/63₁A212 | 61.4 | 0.38 | 16.1 | 0.72 | 0.38 |
| Piper Cheyenne I | 229 | 5.69 | 63₂A415/63₁A212 | 70.5 | 0.40 | 15.7 | 0.85 | .40/.41 |
| Piper Cheyen. III | 293 | 7.33 | 63₂A415/63₁A212 | 61.8 | 0.39 | 23.7 | 0.68 | .35/.44 |
| Beech Duchess | 181 | 5.08 | 63₂A415 | 39.4 | 0.35 | 15.6 | 0.67 | 0.40 |
| Beech Duke B60 | 213 | 6.60 | 23016.5/23010.5 | 62.0 | 0.27 | 14.5 | 0.64 | 0.39 |
| Lear Fan 2100 | 163 | 4.36 | NA | 55.0 | 0.23 | 13.1 | 1.01 | .36/.31 |
| Rockwell Comdr 700 | 200 | 5.28 | NA | 55.4 | 0.37 | 19.7 | 1.03 | 0.37 |
| Piaggio P166-DL3 | 286 | 6.06 | 230 series | 51.6 | 0.27 | 17.2 | 0.51 | .40/.50 |
| EMB-121 | 296 | 6.62 | NA | 62.9 | 0.43 | 20.3 | 0.65 | .39/.46 |

\* Unless otherwise indicated.

Note: Table 8.3a has no "Conquest I" row, but Table 8.3b does (below). This is a printed
inconsistency between the two halves of Table 8.3. Also, "EMB-121" prints under the "Piaggio"
manufacturer line, but the EMB-121 Xingu is an Embraer product.

### Table 8.3b) Twin Engine Propeller Driven Airplanes: Vertical Tail, Rudder and Aileron Data
*[Roskam Part II, Table 8.3b, p. 193]*

| Type | S (ft²) | b (ft) | S_v (ft²) | S_r/S_v | x_v (ft) | V-bar_v | Rudder Chord root/tip (fr.c_v) | S_a/S | Ail. Span Loc. in/out (fr.b/2) | Ail. Chord in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|---|---|
| Cessna 310R | 179 | 36.9 | 26.1 | 0.45 | 15.9 | 0.063 | .48/.41 | 0.064 | .60/.90 | .30/.29 |
| Cessna 402B | 196 | 39.9 | 37.9 | 0.47 | 16.5 | 0.080 | .48/.40 | 0.058 | .64/.91 | .29/.27 |
| Cessna 414A | 226 | 44.1 | 41.3 | 0.38 | 17.0 | 0.071 | .49/.37 | 0.061 | .62/.87 | .30/.28 |
| Cessna T303 | 189 | 39.0 | 23.2 | 0.44 | 16.5 | 0.052 | .46/.39 | 0.087 | .64/.97 | .31/.30 |
| Cessna Conquest I | 225 | 44.1 | 41.3 | 0.38 | 17.1 | 0.071 | .47/.34 | 0.060 | .61/.86 | 0.29 |
| Piper PA-31P | 229 | 40.7 | 30.1 | 0.38 | 17.2 | 0.056 | .37/.40 | 0.056 | .59/.97 | .24/.29 |
| Piper PA44-180T | 184 | 38.6 | 21.5 | 0.37 | 14.4 | 0.044 | .30/.50 | 0.077 | .45/.90 | .19/.18 |
| Piper Chieftain | 229 | 40.7 | 29.5 | 0.40 | 17.3 | 0.055 | .40/.38 | 0.060 | .66/.98 | .24/.30 |
| Piper Cheyen. I | 229 | 42.7 | 26.5 | 0.40 | 16.5 | 0.045 | .37/.42 | 0.057 | .62/.93 | .24/.29 |
| Piper Cheye. III | 293 | 47.7 | 43.6 | 0.46 | 20.8 | 0.065 | 0.33 | 0.046 | .66/.94 | .23/.26 |
| Beech Duchess | 181 | 38.0 | 25.6 | 0.29 | 14.2 | 0.053 | .34/.42 | 0.059 | .67/.97 | 0.28 |
| Beech Duke B60 | 213 | 39.3 | 28.8 | 0.43 | 17.4 | 0.060 | .44/.46 | 0.054 | .50/.84 | .24/.26 |
| Lear Fan 2100 | 163 | 39.3 | 44.4 | 0.17 | 14.0 | 0.097 | .32/.34 | 0.044 | .72/.98 | .31/.24 |
| Rockwell Comdr 700 | 200 | 42.5 | 39.9 | 0.38 | 20.5 | 0.096 | .37/.38 | 0.087 | .58/.99 | .28/.24 |
| Piaggio P166-DL3 | 286 | 48.2 | 30.7 | 0.43 | 18.3 | 0.041 | .38/.43 | 0.073 | .61/.94 | .19/.22 |
| EMB-121 | 296 | 46.4 | 42.6 | 0.45 | 17.8 | 0.055 | .42/.41 | 0.052 | .71/.97 | 0.22 |

### Table 8.4a) Agricultural Airplanes: Horizontal Tail Volume and Elevator Data
*[Roskam Part II, Table 8.4a, p. 194]*

| Type | S (ft²) | c-bar (ft) | Wing Airfoil root/tip (NACA*) | S_h (ft²) | S_e/S_h | x_h (ft) | V-bar_h | Elevator Chord root/tip (fr.c_h) |
|---|---|---|---|---|---|---|---|---|
| PZL-104 | 167 | 4.60 | 2415 | 34.0 | 0.60 | 17.3 | 0.77 | 0.51 |
| PZL-106A | 306 | 6.23 | Clark Y | 81.4 | 0.56 | 18.6 | 0.79 | .30/.50 |
| PZL-M18 | 431 | 7.50 | 4416/4412 | 70.0 | 0.49 | 17.4 | 0.38 | 0.49 |
| NDN-6 | 338 | 6.71 | NA | 60.4 | 0.36 | 17.4 | 0.46 | 0.36 |
| EMB201A | 215 | 5.63 | 23015 | 50.3 | 0.32 | 13.6 | 0.56 | 0.56 |
| Cessna Ag Husky | 205 | 4.55 | 2412 | 40.7 | 0.41 | 15.6 | 0.68 | .43/.37 |
| Schweizer Ag-Cat B | 392 | 4.83 | 4412 | 45.0 | 0.49 | 12.9 | 0.31 | .38/.60 |
| Aero Boero 260Ag | 189 | 5.29 | 23012 | 25.5 | 0.41 | 14.1 | 0.36 | 0.44 |
| Let Z-37A | 256 | 5.91 | 33015/43012A | 54.1 | 0.41 | 16.8 | 0.60 | .44/.42 |
| Hal HA-31 | 251 | 6.54 | USA35B | 45.6 | 0.43 | 17.9 | 0.50 | 0.46 |
| IAR-822 | 280 | 6.90 | 23014 | 48.4 | 0.44 | 17.4 | 0.44 | 0.46 |
| Piper PA-36 | 226 | 6.22 | 63₆18 | 43.3 | 0.48 | 15.0 | 0.46 | .38/.62 |

\* Unless otherwise indicated.

Note: the PA-36 airfoil prints as a 6-series designation with a subscript (`63,618` in the scan).
It is read here as NACA 63₆18.

### Table 8.4b) Agricultural Airplanes: Vertical Tail Volume, Rudder and Aileron Data
*[Roskam Part II, Table 8.4b, p. 194]*

| Type | S (ft²) | b (ft) | S_v (ft²) | S_r/S_v | x_v (ft) | V-bar_v | Rudder Chord root/tip (fr.c_v) | S_a/S | Ail. Span Loc. in/out (fr.b/2) | Ail. Chord in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|---|---|
| PZL-104 | 167 | 36.5 | 20.3 | 0.49 | 16.1 | 0.054 | .41/.50 | 0.10 | .58/.94 | 0.25 |
| PZL-106A | 306 | 48.5 | 31.0 | 0.56 | 17.1 | 0.036 | .45/.51 | 0.087 | .53/.96 | 0.22 |
| PZL-M18 | 431 | 58.1 | 28.5 | 0.65 | 18.5 | 0.021 | .50/.46 | 0.11 | .59/.92 | 0.32 |
| NDN-6 | 338 | 50.3 | 31.0 | 0.54 | 18.4 | 0.034 | .50/.64 | 0.047 | .73/1.0 | .19/.14 |
| EMB201A | 215 | 38.4 | 13.0 | 0.52 | 14.1 | 0.022 | .39/.36 | 0.08 | .57/.90 | 0.19 |
| Cessna Ag Husky | 205 | 41.7 | 18.0 | 0.38 | 16.2 | 0.034 | .32/.39 | 0.11 | .53/.94 | .27/.28 |
| Schweizer Ag-Cat B | 392 | 42.3 | 30.0 | 0.40 | 13.5 | 0.024 | .25/.31 | 0.08 | .53/.86 | 0.29 |
| Aero Boero 260Ag | 189 | 35.8 | 9.94 | 0.39 | 15.1 | 0.022 | .32/.51 | 0.11 | .52/.94 | .20/.19 |
| Let Z-37A | 256 | 40.1 | 22.1 | 0.52 | 15.3 | 0.033 | .59/.65 | 0.086 | .64/1.0 | 0.32 |
| HAL HA-31 | 251 | 39.4 | 20.7 | 0.45 | 16.6 | 0.035 | .50/.46 | 0.092 | .55/.89 | 0.28 |
| IAR-822 | 280 | 42.0 | 22.9 | 0.69 | 17.9 | 0.035 | .56/.64 | 0.11 | .63/.98 | 0.27 |
| Piper PA-36 | 226 | 38.8 | 19.9 | 0.49 | 16.5 | 0.038 | .59/.21 | 0.096 | .52/.92 | 0.28 |

### Table 8.5a) Business Jets: Horizontal Tail Volume and Elevator Data
*[Roskam Part II, Table 8.5a, p. 195]*

| Type | S (ft²) | c-bar (ft) | Wing Airfoil root/tip (NACA*) | S_h (ft²) | S_e/S_h | x_h (ft) | V-bar_h | Elevator Chord root/tip (fr.c_h) |
|---|---|---|---|---|---|---|---|---|
| Dassault-Breguet Falcon 10 | 259 | 6.71 | NA | 72.7 | 0.20 | 16.5 | 0.69 | .31/.29 |
| Dassault-Breguet Falcon 20 | 440 | 9.33 | NA | 122 | 0.22 | 21.9 | 0.65 | .28/.31 |
| Dassault-Breguet Falcon 50 | 495 | 9.31 | NA | 144 | 0.23 | 21.7 | 0.68 | .31/.34 |
| Cessna Citation 500 | 260 | 6.44 | 23014/23012 | 70.6 | 0.29 | 17.3 | 0.73 | .32/.23 |
| Cessna Citation II | 323 | 6.77 | NA | 73.1 | 0.36 | 19.2 | 0.64 | .37/.35 |
| Cessna Citation III | 312 | 6.07 | NASA Sprcrt | 69.6 | 0.34 | 26.9 | 0.99 | .39/.42 |
| Gates Learjet 24 | 232 | 7.03 | 64A109 | 54.0 | 0.26 | 20.2 | 0.67 | .36/.26 |
| Gates Learjet 35A | 253 | 7.22 | 64A109 | 54.0 | 0.33 | 21.9 | 0.65 | .33 |
| Gates Learjet 55 | 265 | 6.88 | NA | 57.8 | 0.32 | 23.8 | 0.76 | .31/.35 |
| Canadair Challenger CL-601 | 450 | 11.3 | NA | 105 | 0.28 | 32.2 | 0.67 | .30/.31 |
| Aerospatiale SN-601 | 237 | 5.60 | NA | 58.9 | 0.42 | 16.7 | 0.74 | .40/.44 |
| Israel Aircraft Ind. Astra | 317 | 5.62 | Sigma 2 | 77.1 | 0.25 | 22.8 | 0.99 | .30/.32 |
| Israel Aircraft Ind. Westwind | 308 | 7.58 | 64A212 | 70.1 | 0.25 | 19.8 | 0.59 | .29/.26 |
| British Aerospace HS 125-700 | 353 | 7.52 | NA | 100 | 0.48 | 19.1 | 0.72 | .37/.67 |
| G.A.-III | 935 | 13.8 | NA | 184 | 0.33 | 35.6 | 0.51 | 0.33 |
| MU Diam. I | 241 | 6.23 | NA | 57.2 | 0.37 | 22.4 | 0.85 | 0.37 |

\* Unless otherwise indicated.

### Table 8.5b) Business Jets: Vertical Tail Volume, Rudder and Aileron Data
*[Roskam Part II, Table 8.5b, p. 195]*

| Type | S (ft²) | b (ft) | S_v (ft²) | S_r/S_v | x_v (ft) | V-bar_v | Rudder Chord root/tip (fr.c_v) | S_a/S | Ail. Span Loc. in/out (fr.b/2) | Ail. Chord in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|---|---|
| Dassault Breguet Falcon 10 | 259 | 42.9 | 48.9 | 0.32 | 14.4 | 0.063 | .34/.49 | 0.051 | .67/.95 | .27/.31 |
| Dassault Breguet Falcon 20 | 440 | 53.5 | 81.8 | 0.23 | 18.1 | 0.063 | .25/.39 | 0.057 | .62/.92 | 0.25 |
| Dassault Breguet Falcon 50 | 495 | 61.9 | 106 | 0.12 | 18.7 | 0.064 | .21/.32 | 0.049 | .68/.97 | 0.27 |
| Cessna Citation 500 | 260 | 43.9 | 50.9 | 0.36 | 18.2 | 0.081 | 0.36 | 0.096 | .55/.94 | .32/.30 |
| Cessna Citation II | 323 | 51.7 | 53.0 | 0.34 | 19.36 | 0.062 | .35/.31 | 0.078 | .56/.89 | .32/.30 |
| Cessna Citation III | 312 | 53.5 | 70.2 | 0.30 | 20.5 | 0.086 | .37/.38 | NA* | .70/.86 | .21/.17 |
| Gates Learjet 24 | 232 | 35.6 | 38.4 | 0.17 | 16.6 | 0.077 | .23/.22 | 0.050 | .63/.89 | .25/.23 |
| Gates Learjet 35A | 253 | 38.1 | 38.4 | 0.17 | 16.6 | 0.066 | .26/.25 | 0.066 | .55/.79 | .30/.27 |
| Gates Learjet 55 | 265 | 43.8 | 52.4 | 0.17 | 19.2 | 0.086 | .26/.25 | 0.062 | .49/.71 | 0.30 |
| Can. CL601 | 450 | 64.3 | 96.0 | 0.26 | 24.9 | 0.083 | .29/.31 | 0.033 | .73/.91 | .23/.26 |
| Aerospatiale SN-601 | 237 | 42.2 | 45.4 | 0.30 | 15.7 | 0.071 | .36/.32 | 0.033 | .68/.91 | .22/.20 |
| Israel Aircraft Ind. Astra | 317 | 52.7 | 48.3 | 0.21 | 22.0 | 0.064 | .33/.32 | 0.040 | .67/.95 | .26/.25 |
| Israel Aircraft Ind. Westwind | 308 | 44.8 | 59.7 | 0.18 | 20.1 | 0.087 | .34/.44 | 0.050 | .59/.90 | .21/.31 |
| British Aerospace HS 125-700 | 353 | 47.0 | 63.8 | 0.22 | 15.9 | 0.061 | .31/.37 | 0.084 | .66/1.0 | .33/.46 |
| G.A. III | 935 | 77.8 | 159 | 0.24 | 26.9 | 0.059 | 0.28 | 0.038 | .66/.86 | .24/.27 |
| MU Diam. I | 241 | 43.4 | 55.9 | 0.25 | 17.4 | 0.093 | .33/.28 | 0.012 | .86/.94 | .20/.22 |

\* Also uses spoilers for lateral control.

### Table 8.6a) Regional Turboprop Airplanes: Horizontal Tail Volume and Elevator Data
*[Roskam Part II, Table 8.6a, p. 196]*

| Type | S (ft²) | c-bar (ft) | Wing Airfoil root/tip (NACA*) | S_h (ft²) | S_e/S_h | x_h (ft) | V-bar_h | Elevator Chord root/tip (fr.c_h) |
|---|---|---|---|---|---|---|---|---|
| CASA C-212-200 | 431 | 6.68 | 653-218 | 135 | 0.35 | 24.9 | 1.17 | .49/.53 |
| Shorts 330 | 453 | 6.06 | NA | 83.6 | 0.33 | 27.3 | 0.83 | 0.50 |
| Shorts 360 | 453 | 6.06 | NA | 106 | 0.39 | 33.0 | 1.28 | 0.48 |
| Beech 1900 | 303 | 5.35 | 23018/23015 | 71.3 | 0.43 | 30.3 | 1.33** | .43/.48 |
| Beech B200 | 303 | 5.35 | 23018.5/23011.3 | 68.0 | 0.28 | 24.6 | 0.91 | 0.42 |
| Cessna Conquest I*** | 225 | 4.73 | 23018/23009 | 62.0 | 0.33 | 16.4 | 0.95 | .36/.43 |
| Cessna Conquest II | 254 | 4.98 | 23018/23009 | 63.4 | 0.29 | 18.0 | 0.90 | .43/.40 |
| GA Ic | 610 | 8.28 | NA | 134 | 0.26 | 36.5 | 0.97 | .29/.32 |
| GAF N22B | 324 | 5.94 | 23018 | 78.0 | 1.00 | 20.6 | 0.83 | stabilator |
| Fokker F27-200 | 754 | 8.43 | 64-421/64-415 | 172 | 0.27 | 36.0 | 0.98 | .29/.34 |
| DeHavilland Canada DHC-6-300 | 420 | 6.50 | NA | 100 | 0.35 | 24.8 | 0.91 | 0.47 |
| DeHavilland Canada DHC-7 | 860 | 9.45 | 63A418/63A415 | 217 | 0.46 | 41.6 | 1.11 | .42/.47 |
| DeHavilland Canada DHC-8 | 585 | 6.51 | NA | 154 | 0.42 | 36.3 | 1.47 | .41/.43 |
| EMB-120 | 409 | 6.57 | 23018/23012 | 108 | 0.39 | 31.7 | 1.27 | .38/.44 |
| BAe 31 | 270 | 5.27 | 63A418/63A412 | 84.0 | 0.46 | 20.7 | 1.22 | .43/.48 |
| Metro III | 309 | 6.03 | 65₂A215/64₂A415 | 76.0 | 0.28 | 26.1 | 1.07 | .31/.48 |

\* Unless otherwise indicated. \*\* 1900 also has a small fixed stabilizer.
\*\*\* Conquest I airfoils carry a -63 mod.

### Table 8.6b) Regional Turboprop Airplanes: Vertical Tail Volume, Rudder and Aileron Data
*[Roskam Part II, Table 8.6b, p. 196]*

| Type | S (ft²) | b (ft) | S_v (ft²) | S_r/S_v | x_v (ft) | V-bar_v | Rudder Chord root/tip (fr.c_v) | S_a/S | Ail. Span Loc. in/out (fr.b/2) | Ail. Chord in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|---|---|
| CASA C-212-200 | 431 | 62.3 | 77.5 | 0.41 | 24.8 | 0.072 | 0.41 | 0.061 | .69/1.0 | .24/.26 |
| Shorts 330 | 453 | 74.7 | 93.1 | 0.26 | 27.3 | 0.075 | 0.41 | 0.061 | .70/.95 | 0.27 |
| Shorts 360 | 453 | 74.7 | 91.4 | 0.37 | 33.9 | 0.091 | .39/.36 | 0.074 | .69/.98 | 0.27 |
| Beech 1900* | 303 | 54.5 | 47.5 | 0.35 | 26.5 | 0.076 | .40/.38 | 0.064 | .60/1.0 | 0.21 |
| Beech B200 | 303 | 54.5 | 52.3 | 0.29 | 20.5 | 0.065 | .47/.41 | 0.059 | .60/1.0 | 0.21 |
| Cessna Conquest I | 225 | 44.1 | 41.3 | 0.38 | 17.1 | 0.071 | .46/.38 | 0.060 | .61/.86 | .29/.28 |
| Cessna Conquest II | 254 | 49.3 | 43.5 | 0.37 | 18.7 | 0.065 | .48/.33 | 0.058 | .62/.89 | .30/.32 |
| GA Ic | 610 | 78.3 | 117 | 0.25 | 35.4 | 0.087 | .29/.33 | 0.061 | .65/.98 | .27/.22 |
| GAF N22B | 324 | 54.2 | 70.2 | 0.44 | 21.6 | 0.086 | .49/.43 | 0.085 | .54/1.0 | 0.24 |
| Fokker F27-200 | 754 | 95.2 | 153 | 0.30 | 36.0 | 0.077 | .33/.29 | 0.050 | .69/.98 | .31/.29 |
| DeHavilland Canada DHC-6-300 | 420 | 65.0 | 82.0 | 0.42 | 25.7 | 0.077 | .35/.44 | 0.079 | .44/.97 | 0.20 |
| DeHavilland Canada DHC-7 | 860 | 93.0 | 170 | 0.28 | 35.7 | 0.076 | .25/.30 | 0.027 | .81/1.0 | .27/.31 |
| DeHavilland Canada DHC-8 | 585 | 84.0 | 190 | 0.26 | 31.4 | 0.121 | .27/.35 | 0.031 | .80/1.0 | .23/.22 |
| EMB-120 | 409 | 64.9 | 74.3 | 0.38 | 27.3 | 0.076 | .32/.31 | 0.084 | .63/.97 | 0.24 |
| BAe 31 | 270 | 52.0 | 83.1 | 0.26 | 20.7 | 0.120 | .34/.39 | 0.061 | .59/.97 | .28/.30 |
| Metro III | 309 | 57.0 | 56.0 | 0.35 | 27.9 | 0.089 | .37/.56 | 0.046 | .61/.98 | .31/.36 |

\* 1900 also has taillets on horizontal tail.

### Table 8.7a) Jet Transports: Horizontal Tail Volume and Elevator Data
*[Roskam Part II, Table 8.7a, p. 197]*

| Type | S (ft²) | c-bar (ft) | Wing Airfoil root/tip | S_h (ft²) | S_e/S_h | x_h (ft) | V-bar_h | Elevator Chord root/tip (fr.c_h) |
|---|---|---|---|---|---|---|---|---|
| Boeing 727-200 | 1,700 | 18.0 | BAC | 376 | 0.25 | 67.0 | 0.82 | .29/.31 |
| Boeing 737-200 | 980 | 11.2 | BAC | 321 | 0.27 | 43.8 | 1.28 | .30/.32 |
| Boeing 737-300 | 1,117 | 10.9 | BAC | 330 | 0.24 | 49.7 | 1.35 | .24/.34 |
| Boeing 747-200B | 5,500 | 38.0 | BAC | 1,470 | 0.24 | 104.5 | 0.74 | 0.29 |
| Boeing 747SP | 5,500 | 38.0 | BAC | 1,534 | 0.21 | 72.9 | 0.54 | .32/.20 |
| Boeing 757-200 | 1,951 | 14.9 | BAC | 585 | 0.25 | 56.9 | 1.15 | .29/.38 |
| Boeing 767-200 | 3,050 | 19.8 | BAC | 836 | 0.23 | 67.6 | 0.94 | .30/.25 |
| McDonnell-Douglas DC-9 S80 | 1,270 | 15.7 | N.A. | 314 | 0.34 | 61.4 | 0.96 | .39/.38 |
| McDonnell-Douglas DC-9-50 | 1,001 | 11.8 | N.A. | 276 | 0.38 | 56.8 | 1.32 | .41/.47 |
| McDonnell-Douglas DC-10-30 | 3,958 | 24.7 | N.A. | 1,338 | 0.22 | 65.9 | 0.90 | .25/.30 |
| Airbus A300-B4 | 2,799 | 19.2 | N.A. | 748 | 0.26 | 80.4 | 1.12 | 0.35 |
| Airbus A310 | 2,357 | 19.3 | N.A. | 689 | 0.26 | 72.0 | 1.09 | .33/.30 |
| Lockheed L1011-500 (geared elevator) | 3,541 | 24.5 | N.A. | 1,282 | 0.19 | 55.9 | 0.83 | stabilator |
| Fokker F-28-4000 | 850 | 10.9 | N.A. | 210 | 0.20 | 47.2 | 1.07 | .34/.33 |
| Rombac/British Aerospace 1-11 495 | 1,031 | 11.8 | N.A. | 258 | 0.27 | 40.7 | 0.86 | .41/.35 |
| British Aerospace 146-200 | 832 | 10.2 | N.A. | 276 | 0.39 | 45.3 | 1.48 | .42/.44 |
| Tu-154 | 2,169 | 16.8 | N.A. | 436 | 0.18 | 58.9 | 0.71 | .27/.25 |

"BAC" in the airfoil column is a proprietary Boeing section designation, not a NACA number.
"N.A." = not available.

### Table 8.7b) Jet Transports: Vert. Tail Volume, Rudder, Aileron and Spoiler Data
*[Roskam Part II, Table 8.7b, p. 197]*

The aileron columns in Table 8.7b are for the **inboard** aileron only. The outboard aileron and
the spoilers are in Table 8.7c.

| Type | S (ft²) | b (ft) | S_v (ft²) | S_r/S_v | x_v (ft) | V-bar_v | Rudder Chord root/tip (fr.c_v) | S_a/S | Inb'd Ail. Span in/out (fr.b/2) | Inb'd Ail. Chord in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|---|---|
| Boeing 727-200 | 1,700 | 108 | 422 | 0.16 | 47.4 | 0.110 | .29/.28 | 0.034 | .38/.46 | .17/.24 |
| Boeing 737-200 | 980 | 93.0 | 233 | 0.24 | 40.7 | 0.100 | .25/.22 | 0.024 | none | none |
| Boeing 737-300 | 1,117 | 94.8 | 239 | 0.31 | 45.7 | 0.100 | .26/.50 | 0.021 | none | none |
| Boeing 747-200B | 5,500 | 196 | 830 | 0.30 | 102 | 0.079 | 0.30 | 0.040 | .38/.44 | .17/.25 |
| Boeing 747-SP | 5,500 | 196 | 885 | 0.27 | 69.5 | 0.057 | .31/.34 | 0.040 | .38/.44 | .17/.25 |
| Boeing 757-200 | 1,951 | 125 | 384 | 0.34 | 54.2 | 0.086 | .35/.33 | 0.027 | none | none |
| Boeing 767-200 | 3,050 | 156 | 497 | 0.35 | 64.6 | 0.067 | .33/.36 | 0.041 | .31/.40 | .23/.20 |
| McDonnell-Douglas DC-9 S80 | 1,270 | 108 | 168 | 0.39 | 50.5 | 0.062 | .49/.46 | 0.030 | none | none |
| McDonnell-Douglas DC-9-50 | 1,001 | 93.4 | 161 | 0.41 | 46.2 | 0.079 | .45/.44 | 0.038 | none | none |
| McDonnell-Douglas DC-10-30 | 3,958 | 165 | 605 | 0.18 | 64.6 | 0.060 | 0.35 | 0.047 | .32/.39 | .20/.25 |
| Airbus A300-B4 | 2,799 | 147 | 487 | 0.30 | 79.5 | 0.094 | .35/.36 | 0.049 | .29/.39 | .23/.27 |
| Airbus A310 | 2,357 | 144 | 487 | 0.35 | 68.5 | 0.098 | .33/.35 | 0.027 | .32/.40 | .23/.27 |
| Lockheed L1011-500 | 3,541 | 164 | 550 | 0.23 | 58.2 | 0.055 | .29/.26 | 0.051 | .40/.49 | .22/.23 |
| Fokker F-28-4000 | 850 | 82.3 | 157 | 0.16 | 37.9 | 0.085 | .29/.31 | 0.034 | none | none |
| Rombac/British Aerospace 1-11 495 | 1,031 | 93.5 | 117 | 0.28 | 31.6 | 0.038 | .39/.37 | 0.030 | none | none |
| British Aerospace 146-200 | 832 | 86.4 | 224 | 0.44 | 38.9 | 0.12 | 0.29 | 0.046 | none | none |
| Tu-154 | 2,169 | 123 | 341 | 0.27 | 43.3 | 0.055 | 0.37 | 0.036 | none | none |

### Table 8.7c) Jet Transports: Vert. Tail Volume, Rudder, Aileron and Spoiler Data
*[Roskam Part II, Table 8.7c, p. 198]*

Column basis: aileron/spoiler **span** locations are fractions of the wing semi-span (fr.b/2);
aileron/spoiler **chord** and **hinge line** locations are fractions of the local wing chord
(fr.c_w). Each entry is inboard-end/outboard-end.

| Type | Outb'd Ail. Span in/out (fr.b/2) | Outb'd Ail. Chord in/out (fr.c_w) | Inb'd Spoiler Span Loc. in/out (fr.b/2) | Inb'd Spoiler Chord in/out (fr.c_w) | Inb'd Spoiler Hinge Loc. in/out (fr.c_w) | Outb'd Spoiler Span Loc. in/out (fr.c_w) | Outb'd Spoiler Chord in/out (fr.c_w) | Outb'd Spoiler Hinge Loc. in/out (fr.c_w) |
|---|---|---|---|---|---|---|---|---|
| Boeing 727-200 | .76/.93 | .23/.30 | .14/.37 | .09/.14 | .79/.69 | .48/.72 | .16/.20 | .65/.63 |
| Boeing 737-200 | .74/.94 | .20/.28 | .40/.66 | .14/.18 | .66/.67 | none | none | none |
| Boeing 737-300 | .72/.91 | .23/.30 | .38/.64 | 0.14 | .64/.70 | none | none | none |
| Boeing 747-200B | .70/.95 | .11/.17 | .46/.67 | .12/.16 | 0.71 | none | none | none |
| Boeing 747-SP | .70/.95 | .11/.17 | .46/.67 | .12/.16 | 0.71 | none | none | none |
| Boeing 757-200 | .76/.97 | .22/.36 | .41/.74 | .12/.13 | .73/.69 | none | none | none |
| Boeing 767-200 | .76/.98 | .16/.15 | .16/.31 | .09/.11 | .85/.78 | .44/.67 | .12/.17 | .74/.71 |
| McDonnell-Douglas DC-9 S80 | .64/.85 | .31/.36 | .35/.60 | .10/.08 | .69/.65 | none | none | none |
| McDonnell-Douglas DC-9-50 | .78/.95 | .30/.35 | .35/.60 | .10/.08 | .69/.65 | none | none | none |
| McDonnell-Douglas DC-10-30 | .75/.93 | .29/.27 | .17/.30 | .05/.06 | .78/.74 | .43/.72 | .11/.16 | .75/.70 |
| Airbus A300-B4 | .83/.99 | .32/.30 | .57/.79 | .16/.22 | .73/.72 | none | none | none |
| Airbus A310 | none | none | .62/.83 | .16/.22 | .69/.66 | none | none | none |
| Lockheed L1011-500 | .77/.98 | .26/.22 | .13/.39 | .08/.12 | .82/.73 | .50/.74 | .14/.14 | .67/.67 |
| Fokker F-28-4000 | .66/.91 | .29/.28 | *no lateral control spoilers* | | | | | |
| Rombac/British Aerospace 1-11 495 | .72/.92 | 0.26 | .37/.68 | .06/.11 | .68/.63 | none | none | none |
| British Aerospace 146-200 | .78/1.0 | .33/.31 | .14/.70 | .22/.27 | .76/.68 | none | none | none |
| Tu-154 | .76/.98 | .34/.27 | .43/.70 | .14/.20 | .62/.60 | none | none | none |

Suspected misprint: the "Outb'd Spoiler Span Loc." column header prints its unit as `fr.c_w`.
Every other span-location column in the chapter uses `fr.b/2`. The values in that column
(.48/.72, .44/.67, .43/.72, .50/.74) are consistent with span fractions, not chord fractions.

**Figure (unnumbered), p. 198:** cutaway line drawing of the BAC 111 (caption on the drawing reads
"BAC III"). Illustration only, no plotted data.
