# Chapter 12 — Class I Method for Drag Polar Determination

**Source:** Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration of
the Propulsion System* (Roskam Aviation / DARcorporation), Chapter 12 "Class I Method for Drag
Polar Determination," printed pp. 281–294.

This chapter gives the **equivalent-parasite-area / wetted-area** drag polar method. It is Step 12
of preliminary design sequence I (Chapter 2). §12.1 gives the method in 8 steps. §12.2 gives three
worked examples.

**Important scope note for implementation.** The numeric correlation data this method needs are
**not printed in this chapter**. They live in Part I and are only referenced here:

| Data | Where the chapter sends you |
|---|---|
| Skin friction coefficient `c_f` vs. airplane type ("equivalent parasite area" chart) | Part I, Figure 3.21, pp. 119–120 |
| Wetted area vs. take-off weight correlation | Part I, Figure 3.22 (a = twins, b = jet transports, c = fighters) |
| Flap drag increments `Delta C_D_flap` | Part I, Table 3.6, p. 127 |
| Landing gear drag increment `Delta C_D_gear` | Part I, Table 3.6, p. 127 |
| Propeller power to thrust conversion | Part I, Figure 3.8, p. 100 |

So this chapter contains **no `c_f` table and no flap/gear drag-increment table of its own**. The
only `c_f` values that appear are the two used in the examples (`c_f = 0.0030` for an advanced jet
transport, and `c_f = 0.0030` for a fighter, both read from Part I Figure 3.21b, p. 120). Do not
invent the tables; cite Part I for them.

---

## §12.1 Step-by-Step Method for Drag Polar Determination

### Step 12.1 — List every component that adds wetted area, and sum to `S_wet`

The method assumes that a threeview with cross sections is available (see Figure 12.1). The wetted
area of the airplane is the integral of airplane perimeter against distance from nose to tail.

Split the airplane into components:

1. fuselage and/or tailbooms
2. wing(s)
3. empennage
4. nacelles
5. other components that add wetted area

For fuselages, booms and nacelles, the **perimeter method** is usually the most efficient. Figure
12.2 shows an example perimeter plot. You only need the perimeter at selected fuselage stations. Put
a station wherever the perimeter (or the cross section) changes much.

At each fuselage, boom or nacelle station, find the local perimeter by:

1. a CAD program
2. calculation, if the cross section has a simple geometry
3. a planimeter trace, if a planimeter is available
4. the 'pin/string' method: put pins along the outside of each cross section and measure the length
   of a string wrapped around the outside of the pins

#### Wetted areas for planforms

For straight tapered planforms (wing, tail, canard, fin and pylon):

*[Roskam Part II, Eq. (12.1), p. 284]*

```
S_wet_plf = 2 S_exp.plf { 1 + 0.25 (t/c)_r (1 + tau*lambda) / (1 + lambda) }             (12.1)
```

where:

```
tau = (t/c)_r / (t/c)_t          and          lambda = c_t / c_r
```

| Symbol | Meaning | Units |
|---|---|---|
| `S_wet_plf` | wetted area of the planform | ft² |
| `S_exp.plf` | **exposed** planform area (see Figure 12.3) | ft² |
| `(t/c)_r` | thickness ratio at the root | — |
| `(t/c)_t` | thickness ratio at the tip | — |
| `tau` | root-to-tip thickness ratio ratio | — |
| `lambda` | taper ratio `c_t/c_r` | — |

**Reference-area note:** Eqn. (12.1) uses the **exposed** planform area, not the reference
(trapezoidal, to-centreline) area. Figure 12.6 states directly: subtract the fuselage-covered part
"only if using `S_plf` instead of `S_exp.plf` in Eqn. 12.1".

If a planform has broken or curved leading and/or trailing edges, get the wetted area from a
spanwise integration of the planform perimeter at each planform station. Estimate that perimeter
from:

*[Roskam Part II, Eq. (12.2), p. 284]*

```
P_plf = 2 c (1 + 0.25 t/c)                                                               (12.2)
```

where `c` is the local chord (ft) and `t/c` the local thickness ratio.

#### Wetted areas for fuselages

For fuselages with a cylindrical mid-section:

*[Roskam Part II, Eq. (12.3), p. 284]*

```
S_wet_fus = pi * D_f * l_f * (1 - 2/lambda_f)^(2/3) * (1 + 1/lambda_f^2)                 (12.3)
```

For streamlined fuselages **without** a cylindrical mid-section:

*[Roskam Part II, Eq. (12.4), p. 284]*

```
S_wet_fus = pi * D_f * l_f * (0.50 + 0.135 l_n/l_f)^(2/3) * (1.015 + 0.3/lambda_f^1.5)   (12.4)
```

| Symbol | Meaning | Units |
|---|---|---|
| `D_f` | fuselage equivalent diameter, from perimeter `P = pi D_f` | ft |
| `l_f` | fuselage length | ft |
| `l_n` | fuselage nose length | ft |
| `lambda_f` | fuselage fineness ratio, `l_f / D_f` | — |

Figure 12.4 defines `D_f`, `l_n` and `l_f`.

#### Wetted areas for externally mounted nacelles

Figure 12.5 shows the geometry. Three parts add wetted area: fan cowling, gas generator cowling and
the plug. Reference 17, p. 449 gives:

*[Roskam Part II, Eq. (12.5), p. 285]*

```
S_wet_fan cowl. = l_n D_n { 2 + 0.35 l_1/l_n + 0.8 l_1 D_hl / (l_n D_n)
                            + 1.15 (1 - l_1/l_n) D_ef/D_n }                              (12.5)
```

*[Roskam Part II, Eq. (12.6), p. 285]*

```
S_wet_gas gen. = pi * l_g * D_g * [ 1 - (1/3)(1 - D_eg/D_g){ 1 - 0.18 (D_g/l_g)^(5/3) } ] (12.6)
```

*[Roskam Part II, Eq. (12.7), p. 285]*

```
S_wet_plug = 0.7 * pi * l_p * D_p                                                        (12.7)
```

| Symbol | Meaning (see Figure 12.5) | Units |
|---|---|---|
| `l_n` | fan cowling length | ft |
| `l_1` | length from the nacelle nose to the fan cowling maximum-diameter station | ft |
| `D_n` | nacelle (fan cowling) maximum diameter | ft |
| `D_hl` | highlight (inlet lip) diameter | ft |
| `D_ef` | fan exit diameter | ft |
| `l_g` | gas generator cowling length | ft |
| `D_g` | gas generator cowling diameter | ft |
| `D_eg` | gas generator exit diameter | ft |
| `l_p` | plug length | ft |
| `D_p` | plug diameter | ft |

Wings, empennage and nacelle pylons usually cut into a fuselage or a nacelle, so the intersection
areas must be **subtracted** from the fuselage or nacelle wetted area. Figure 12.6 gives examples.

Make a list of every wetted-area contribution and find the total. Compare the total with the
statistical correlation of Figure 3.22 in Part I. The difference should be **not more than 10
percent**. If it is larger, look for the reason.

#### Figure 12.1 — Example Threeview with Cross Sections
*[Roskam Part II, Fig. 12.1, p. 282]*

Manufacturer threeview of the **Cessna Citation 500** (courtesy Cessna), rotated on the page. It
carries the fuselage cross sections at 23 numbered stations, the pylon cross section, the ventral
fin section, and an airfoil/incidence/dihedral data box. Printed overall dimensions: span
43 ft 8.6 in (front view); length 43 ft 6.1 in (side view); height 15 ft 8.3 in; horizontal tail
span 18 ft 10.0 in; wheel track 12 ft 7.6 in. Airfoil box: wing root NACA 23014 modified, wing
W.S. 247.95 NACA 23012; vertical tail root NACA 0012, tip NACA 0008; horizontal tail root NACA
0010, tip NACA 0008. Incidence: wing centreline +2 deg 30 min, wing W.S. 247.95 −0 deg 30 min,
horizontal tail −0 deg 7 min. Dihedral: wing 4 deg, horizontal tail 9 deg, engine pylons 2 deg.
Manufacturer drawing, no plotted trend data.

#### Figure 12.2 — Example of a Perimeter Plot
*[Roskam Part II, Fig. 12.2, p. 283]*

Schematic. Ordinate: fuselage perimeter ~ ft. Abscissa: fuselage station F.S. ~ ft. The curve
starts at zero at the nose, rises through the NOSE and COCKPIT bands, is flat over the CABIN band,
and falls to zero over the TAILCONE band. **No numeric scales are printed**, so no points can be
digitized. The area under the curve is the fuselage wetted area.

#### Figure 12.3 — Definition of Exposed Planform
*[Roskam Part II, Fig. 12.3, p. 283]*

Plan-view sketch. The hatched area outboard of the fuselage side is `S_exposed`. The dashed lines
inside the fuselage show the part of the trapezoidal planform that is **not** exposed. Definition
sketch, no plotted data.

#### Figure 12.4 — Definition of Fuselage Quantities Used in Equation (12.4)
*[Roskam Part II, Fig. 12.4, p. 283]*

Sketch of a fuselage side view with a triangular-with-rounded-corners cross section. It gives the
perimeter `P` of that cross section and the relation `P = pi D_f`, so `D_f` is the **equivalent**
diameter. It also labels the nose length `l_n` and the total length `l_f`. Definition sketch, no
plotted data.

#### Figure 12.5 — Nacelle Geometry for Use in Eqns. (12.5–12.7)
*[Roskam Part II, Fig. 12.5, p. 286]*

Side-view sketch of a separate-flow turbofan nacelle. It labels `l_1`, `l_n`, `l_g`, `l_p` along
the axis, and `D_n`, `D_hl`, `D_p`, `D_eg`, `D_g`, `D_ef` as diameters, with the FAN COWLING, GAS
GEN. COWLING and PLUG regions named. Definition sketch, no plotted data.

#### Figure 12.6 — Examples of 'Areas to be Subtracted' in a Wetted Area Calculation
*[Roskam Part II, Fig. 12.6, p. 286]*

Two sketches. Left: the airfoil-shaped intersection of a vertical tail with a fuselage, marked
SUBTRACT. Right: the fuselage-side band covered by a wing, with the note "SUBTRACT ONLY IF USING
`S_PLF` INSTEAD OF `S_EXP.PLF` IN EQN. 12.1". Definition sketch, no plotted data.

### Step 12.2 — Find the equivalent parasite area `f`

Use Figures 3.21 of Part I (pp. 119 and 120). Those charts give `c_f` (or `f` directly) against
wetted area for each airplane type. In the worked examples the chapter uses `f = c_f * S_wet`.

### Step 12.3 — Find the 'clean' zero lift drag coefficient at low speed

*[Roskam Part II, Eq. printed as "(12.3)", p. 285]*

```
C_D_0 = f / S                                                                     ("(12.3)")
```

| Symbol | Meaning | Units |
|---|---|---|
| `f` | equivalent parasite area | ft² |
| `S` | **wing reference area** | ft² |
| `C_D_0` | clean zero-lift drag coefficient at low speed | — |

**Reference-area note:** `C_D_0` is defined on the **wing reference area** `S`, not on the wetted
area. The examples confirm this (`25/1,296` for the Ourania; `10.7/787` for the Eris).

**Suspected misprint (p. 285):** this equation is printed with the number **(12.3)**, which is
already used by the fuselage wetted-area equation on p. 284. In sequence it should be (12.8). The
text on pp. 290 and 292 also calls it "Eqn. (12.3)" when it means `C_D_0 = f/S`. Cite it carefully.

### Step 12.4 — Find the compressibility drag increment

Read it from Figure 12.7.

- **Important note 1:** the data of Figure 12.7 do **not** apply to airplanes with cruise Mach
  numbers above 0.90.
- **Important note 2:** for airplanes with cruise Mach numbers above 0.90 (this includes supersonic
  cruise airplanes) a cross-sectional area plot is needed. That plot decides the area-ruling
  requirements. Part VI (Ref. 5) describes the area ruling process.

#### Figure 12.7 — Typical Compressibility Drag Behavior
*[Roskam Part II, Fig. 12.7, p. 286]*

Ordinate: zero-lift drag rise ~ counts (the figure states **1 count (ct) = 0.0001**), scaled 0 to
40. Abscissa: Mach number, scaled 0.4 to about 1.05. Four labelled curves: **C-130H**, **C-5A**,
**727**, **F-106**.

Digitized (read from plot, 500 dpi zoom; abscissa values ±0.01, ordinate ±1 count):

| Drag rise (counts) | C-130H | C-5A | 727 | F-106 |
|---|---|---|---|---|
| 0 (curve leaves the axis) | M ≈ 0.50 | M ≈ 0.60 | M ≈ 0.70 | M ≈ 0.90 |
| 5 | ≈0.60 | ≈0.71 | ≈0.80 | ≈0.96 |
| 10 | ≈0.645 | ≈0.745 | ≈0.83 | ≈0.985 |
| 20 | ≈0.695 | ≈0.775 | ≈0.865 | ≈1.01 |
| 30 | ≈0.715 | ≈0.79 | (curve ends near 22 cts at M ≈ 0.875) | ≈1.025 |
| 40 | ≈0.735 | (curve ends near 33 cts at M ≈ 0.80) | — | (curve ends near 36 cts at M ≈ 1.03) |

Every curve has the same shape: near zero drag rise up to a break Mach number, then a steep, almost
vertical rise. The curve order left to right follows wing sweep and thickness: the straight-wing
C-130H breaks first, the delta-wing F-106 last.

### Step 12.5 — Find the flap drag increment(s)

Take them from Table 3.6, p. 127, Part I. **That table is not reprinted in this chapter.**

### Step 12.6 — Find the landing gear drag increment

Take it from Table 3.6, p. 127, Part I. **That table is not reprinted in this chapter.**

### Step 12.7 — Construct the cruise, take-off and landing drag polars

The example polars are written in the standard parabolic form:

```
C_D = C_D_0 + C_L^2 / (pi * A * e)
```

with `C_D_0` from Steps 12.3 to 12.6 for the matching configuration, `A` the wing aspect ratio and
`e` the Oswald efficiency factor.

### Step 12.8 — Find the critical L/D values

Take the L/D values defined by Step 14 in Chapter 2 from these polars, then proceed to Step 14 in
Chapter 2.

The examples use the standard maximum lift-to-drag relation for a parabolic polar:

*[Roskam Part II, worked form on p. 290]*

```
(L/D)_max = ( pi * A * e / (4 * C_D_0) )^(1/2)
```

`A` is the wing aspect ratio and `e` the Oswald efficiency factor. Both are referenced to the wing
reference area `S`.

---

## §12.2 Example Applications

Three examples:

- §12.2.1 Twin engine propeller driven airplane: **Selene**
- §12.2.2 Jet transport: **Ourania**
- §12.2.3 Fighter: **Eris**

### §12.2.1 Twin Engine Propeller Driven Airplane (Selene)

**Step 12.1.** Wetted area buildup:

*[Roskam Part II, tabulation on p. 288]*

| Component | Equation and inputs | Wetted area (ft²) |
|---|---|---|
| Wing | (12.1) with `S = 172 ft²`, `(t/c)_r = 0.17`, `(t/c)_t = 0.13`, `tau = 1.3`, `lambda = 0.4` | 360 |
| Subtract wing/fuselage intersection | `−6.62 x 4.5 =` | −30 |
| Vertical tail | (12.1) with `S_v = 38 ft²`, `t/c = 0.15`, `lambda = 0.56` | 79 |
| Horizontal tail* | (12.1) with `S_h = 58 ft²`, `t/c = 0.12`, `lambda = 0.4` | 119 |
| Nacelles | perimeter method | 105 |
| Fuselage | (12.3) with `D_f = 0.5 x (4.5 + 5.5) = 5 ft`, `l_f = 38.3 ft` | 500 |
| Increment for blister fairings | — | 20 |
| **Total wetted area** | | **1,153** |

\* horizontal tail increased; see p. 269, Ch. 11.

Comparison with Figure 3.22a (Part I): for twins with a take-off gross weight of 7,900 lb the
predicted wetted area is 1,130 ft². That agrees very well with the 1,153 ft² computed from the
actual configuration.

Note: `−6.62 x 4.5 = −29.8`, printed as −30. `360 − 30 + 79 + 119 + 105 + 500 + 20 = 1,153`. The
tabulation is self-consistent.

**Steps 12.2 – 12.8.** Because the wetted areas agree so well, the Selene drag polars do not need
to be recomputed. Those of Part I, sub-section 3.7.2 are still valid.

### §12.2.2 Jet Transport (Ourania)

**Step 12.1.** Wetted area buildup:

*[Roskam Part II, tabulation on p. 289]*

| Component | Equation and inputs | Wetted area (ft²) |
|---|---|---|
| Wing | (12.1) with `S = 1,296 ft²`, `(t/c)_r = 0.13`, `(t/c)_t = 0.11`, `tau = 1.18`, `lambda = 0.32` | 2,795 |
| Subtract wing/fuselage intersection | `−12.9 x 17.5 =` | −226 |
| Vertical tail* | (12.1) with `S_v = 200 ft²`, `t/c = 0.15`, `lambda = 0.32` | 415 |
| Horizontal tail | (12.1) with `S_h = 254 ft²`, `t/c = 0.12`, `lambda = 0.32` | 523 |
| Nacelles | perimeter method | 455 |
| Fuselage | (12.3) with `D_f = 12.9 ft`, `l_f = 123.3 ft` | 4,320 |
| **Total wetted area** | | **8,282** |

\* vertical tail increased; the printed note says "see p. 276, Ch. 8". Page 276 is in **Chapter 11**
(Step 11.15/11.16, where `S_v` goes from 164 to 200 ft²). The chapter number in that footnote looks
like a misprint for Ch. 11.

Comparison with Figure 3.22b (Part I): for transport jets with `W_TO = 127,000 lb` the predicted
wetted area is 7,400 ft². The computed 8,282 ft² is inside the 10 percent expected from the wetted
area correlations. The increase is significant, so the effect on cruise L/D must be checked.

Note: `−12.9 x 17.5 = −225.75`, printed as −226.
`2,795 − 226 + 415 + 523 + 455 + 4,320 = 8,282`. Self-consistent.

**Step 12.2.** From Figure 3.21b, p. 120, Part I: for an advanced jet transport `c_f = 0.0030`
should be attainable. With `S_wet = 8,282 ft²` this gives `f = 25 ft²`.
(Check: 0.0030 x 8,282 = 24.8.)

**Step 12.3.** `C_D_0 = 25 / 1,296 = 0.0193` at low subsonic speed.

**Step 12.4.** The compressibility drag increment from Figure 12.7 is roughly **0.0005**.

**Steps 12.5 – 12.6.** The small change in cruise drag has a negligible effect on the take-off and
landing polars, so those are not re-evaluated.

**Steps 12.7 and 12.8.** Cruise zero-lift drag coefficient:

```
C_D_0 = 0.0005 + 0.0193 = 0.0198
```

Part I, p. 182 had:

```
C_D_0 = 0.0005 + 0.0184 = 0.0189
```

`(L/D)_max` is the critical measure of cruise fuel consumption in a comparative study of jet
transports, if everything else stays the same. With `A = 10` and `e = 0.85`:

| Case | Calculation | `(L/D)_max` |
|---|---|---|
| Before | `(pi x 10 x 0.85 / (4 x 0.0189))^(1/2)` | 18.8 |
| Now | `(pi x 10 x 0.85 / (4 x 0.0198))^(1/2)` | 18.4 |

From the sensitivity data of Part I, p. 78:

```
dW_TO / d(L/D) = -2,287 lb
```

So the L/D drop from 18.8 to 18.4 raises the take-off weight by `2,287 x 0.4 = 915 lb`.

That is only 2.8 percent of the Ourania structural weight (`W_struct = 33,183 lb` from Table 10.5,
Ch. 10). Structural weight savings of up to 10 percent are probably attainable with more advanced
materials. The Ourania design is 'ready' for preliminary design sequence II.

### §12.2.3 Fighter (Eris)

**Step 12.1.** Wetted area buildup:

*[Roskam Part II, tabulation on p. 291]*

| Component | Equation and inputs | Wetted area (ft²) |
|---|---|---|
| Wing | (12.1) with `S = 787 ft²`, `(t/c)_r = 0.10`, `(t/c)_t = 0.08`, `tau = 1.25`, `lambda = 0.50` | 1,617 |
| Subtract wing/fuselage intersection | `−15 x 7.7 =` | −115 |
| Vertical tail | (12.1) with `S_v = 147 ft²`, `t/c = 0.15`, `lambda = 0.55` | 305 |
| Horizontal tail | (12.1) with `S_h = 93 ft²`, `t/c = 0.10`, `lambda = 1.0` | 191 |
| Penalty for inlet bulges | perimeter method | 50 |
| Fuselage | (12.3) with `D_f = 5.5 ft`, `l_f = 38.3 ft` | 540 |
| Tail booms | assume cylinder shape | 229 |
| **Total wetted area** | | **2,817** |

Note: `−15 x 7.7 = −115.5`, printed as −115.
`1,617 − 115 + 305 + 191 + 50 + 540 + 229 = 2,817`. Self-consistent.

Comparison with Figure 3.22c (Part I): for fighters with a take-off gross weight of 64,905 lb the
predicted wetted area is 3,500 ft². That number is read from Fig. 3.22c allowing for the fact that
several high-weight fighters lie above the correlation line.

The Eris wetted area looks much lower than that of fighters of similar gross weight. That does not
seem reasonable. One reason is that the 'base drag' of the Eris engine installation is not counted
by this wetted-area method. From the general arrangement drawing of Figure 10.7 (Ch. 10) the base
drag is estimated as an extra parasite area of **2 ft²**.

**Step 12.2.** From Figure 3.21b, p. 120, Part I: for a fighter `c_f = 0.0030` should be attainable.
With `S_wet = 2,817 ft²` this gives `f = 8.7 ft²`. (Check: 0.0030 x 2,817 = 8.45; the book prints
8.7.) Add the estimated base drag of 2 ft², giving a total `f = 10.7 ft²`.

**Step 12.3.** `C_D_0 = 10.7 / 787 = 0.0135` at low subsonic speed. (Check: 10.7/787 = 0.01360.)

**Step 12.4.** From Figure 12.7 the compressibility drag increment is roughly **0.0020 at M = 0.80**
and **0.0030 at M = 0.85**.

**Steps 12.5 – 12.6.** The change in cruise drag has a negligible effect on the take-off and landing
polars, so those are not re-evaluated.

**Step 12.7.** Drag polars of the Eris, against the very rough Part I estimates (Part I, pp. 188 and
189):

*[Roskam Part II, tabulation on p. 292]*

| Flight condition | Part I (`A = 4`, `e = 0.8`) | Part II (`A = 5`, `e = 0.75`) |
|---|---|---|
| Low speed, clean | `0.0096 + 0.0995 C_L²` | `0.0135 + 0.0707 C_L²` |
| Low speed, stores | `0.0126 + 0.0995 C_L²` | `0.0165 + 0.0707 C_L²` |
| M = 0.8, stores | `0.0146 + 0.0995 C_L²` | `0.0185 + 0.0707 C_L²` |
| M = 0.85, clean | `0.0126 + 0.0995 C_L²` | `0.0165 + 0.0707 C_L²` |

(The book prints the induced-drag term once per column and repeats it with ditto marks.)

Implied increments, consistent in both columns: stores `+0.0030`; compressibility `+0.0020` at
M = 0.80 and `+0.0030` at M = 0.85.

**Suspected misprint (p. 292):** the Part II induced-drag factor is printed as **0.0707** with the
header `A = 5, e = 0.75`. But `1/(pi A e) = 1/(pi x 5 x 0.75) = 0.0849`, not 0.0707. The value
0.0707 matches `e = 0.90` at `A = 5` (`1/(pi x 5 x 0.90) = 0.0707`). The Part I column is
self-consistent: `1/(pi x 4 x 0.8) = 0.0995`. So either the printed `e = 0.75` or the printed
0.0707 is wrong. Do not use this pair as a citable `e` value without checking Part I.

**Step 12.8.** Lift and drag coefficients on the critical mission legs, for both polars:

*[Roskam Part II, tabulation on p. 293]*

| Mission leg | Part I `W` (lb) | Part I `C_L` | Part I `C_D` | Part I L/D | Part II `W` (lb) | Part II `C_L` | Part II `C_D` | Part II L/D |
|---|---|---|---|---|---|---|---|---|
| Sea level, 400 kt, stores | 64,500 | 0.101 | 0.0136 | 7.4 | 64,905 | 0.152 | 0.0181 | 8.4 |
| Sea level, 450 kt, clean | 54,500 | 0.068 | 0.0101 | 6.7 | 54,905 | 0.102 | 0.0142 | 7.2 |
| 40,000 ft, M = 0.8, stores | 64,500 | 0.312 | 0.0243 | 12.8 | 64,905 | 0.469 | 0.0341 | 13.8 |
| 40,000 ft, M = 0.85, clean | 54,500 | 0.235 | 0.0181 | 13.0 | 54,905 | 0.352 | 0.0253 | 13.9 |

The Eris has slightly better L/D values than the Part I performance sizing predicted. Against the
**preliminary weight sizing** of Part I sub-section 2.6.3 the differences are much larger:

*[Roskam Part II, tabulation on p. 293]*

| Mission leg | L/D, preliminary weight sizing (Part I §2.6.3) | L/D, p.d. sequence I Step 12.8 (Part II) |
|---|---|---|
| s.l., 400 kt, stores | 4.5 | 8.4 |
| s.l., 450 kt, clean | 5.5 | 7.2 |
| 40,000 ft, M = 0.8, stores | 7.0 | 13.8 |
| 40,000 ft, M = 0.85, clean | 7.5 | 13.9 |

This means that the weight sizing process should be repeated at this point, with actual engine sfc
data. Preliminary data show that the engine sfc values are much higher than the Part I assumption,
so the overall effect on the weight of the Eris should be minor.

> **Caution (p. 294):** do **not** use the 'sensitivity slopes' of Part I, p. 84 here. Those slopes
> are valid only for weight extrapolations from **small** changes in the independent parameters. The
> L/D changes seen here are too large for the sensitivity slopes to be valid.

After the weight resizing, the Eris should come out relatively unchanged. It can then go into p.d.
sequence II.

Page 287 carries a cutaway drawing of the **SAAB Fairchild 340** (courtesy SAAB Fairchild) and
page 294 a threeview of the **DHC-6 Twin Otter floatplane** (courtesy de Havilland Canada).
Illustrations only, no plotted data used by the method.

---

## Summary for implementation

| Quantity | Form | Where |
|---|---|---|
| Planform wetted area | `2 S_exp {1 + 0.25 (t/c)_r (1 + tau lambda)/(1 + lambda)}` | Eq. (12.1) |
| Planform local perimeter | `2 c (1 + 0.25 t/c)` | Eq. (12.2) |
| Fuselage wetted area, cylindrical mid-body | `pi D_f l_f (1 - 2/lambda_f)^(2/3)(1 + 1/lambda_f²)` | Eq. (12.3) |
| Fuselage wetted area, streamlined, no mid-body | `pi D_f l_f (0.50 + 0.135 l_n/l_f)^(2/3)(1.015 + 0.3/lambda_f^1.5)` | Eq. (12.4) |
| Fan cowl wetted area | Eq. (12.5) | p. 285 |
| Gas generator cowl wetted area | Eq. (12.6) | p. 285 |
| Plug wetted area | `0.7 pi l_p D_p` | Eq. (12.7) |
| Equivalent parasite area | `f = c_f * S_wet` | Step 12.2 / Part I Fig. 3.21 |
| Clean low-speed zero-lift drag | `C_D_0 = f / S` (on **wing** reference area) | printed "(12.3)", p. 285 |
| Compressibility increment | Fig. 12.7, valid only for cruise Mach ≤ 0.90 | Step 12.4 |
| Flap and gear increments | Part I Table 3.6, p. 127 (not printed here) | Steps 12.5, 12.6 |
| Drag polar | `C_D = C_D_0 + C_L²/(pi A e)` | Step 12.7 |
| Maximum lift-to-drag ratio | `(L/D)_max = (pi A e / (4 C_D_0))^(1/2)` | p. 290 |
| Wetted-area sanity check | within 10 percent of Part I Fig. 3.22 | p. 285 |
| Example `c_f`, advanced jet transport | 0.0030 | p. 290, from Part I Fig. 3.21b |
| Example `c_f`, fighter | 0.0030 | p. 292, from Part I Fig. 3.21b |
| Drag count definition | 1 count = 0.0001 | Fig. 12.7 |
