# Chapter 11 — Class I Method for Stability and Control Analysis

**Source:** Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration of
the Propulsion System* (Roskam Aviation / DARcorporation), Chapter 11 "Class I Method for
Stability and Control Analysis," printed pp. 259–280.

This chapter gives the **X-plot** method. The X-plot sizes the horizontal tail (or canard) and the
vertical tail against static stability and control requirements. It replaces the tail-volume-
coefficient (V-bar) areas of Chapter 8 when the two disagree by more than 10 percent.

The method has 16 steps in three groups:

| Group | Steps | Section |
|---|---|---|
| Static longitudinal stability (longitudinal X-plot) | 11.1 – 11.7 | §11.1 |
| Static directional stability (directional X-plot) | 11.8 – 11.11 | §11.2 |
| Minimum control speed, one engine out | 11.12 – 11.16 | §11.3 |
| Example applications | — | §11.4 |

The method belongs to Step 11 of preliminary design sequence I (Chapter 2). It is limited in scope
and in accuracy. Use it only with p.d. sequence I. Take-off rotation, cross-wind control, trim
through the c.g. range and dynamic stability are **not** covered. Part VII (Ref. 6) covers those.

---

## §11.1 Static Longitudinal Stability (Longitudinal X-Plot)

### Step 11.1 — Prepare a longitudinal X-plot

The X-plot has two legs. Both are plotted against horizontal tail area `S_h` (or canard area
`S_c`):

1. **The c.g. leg** — the rate at which the c.g. moves aft (or forward) as the tail (canard) area
   grows.
2. **The a.c. leg** — the rate at which the airplane aerodynamic centre moves aft (or forward) as
   the tail (canard) area grows.

Both legs are non-dimensional, in fractions of the wing mean geometric chord `c̄_w`.

**c.g. leg.** Take it from the Class I weight and balance analysis of Step 10. That analysis gives
the horizontal tail (canard) weight **per ft²**. Assume that this weight per unit area does not
change with area. Then you can find the c.g. for any tail (canard) area.

**a.c. leg.** Compute it from Eqns. (11.1) and (11.2).

*[Roskam Part II, Eq. (11.1), p. 261]*

```
X̄_ac_A = [ X̄_ac_wf + { C_L_alpha_h (1 - de_h/dalpha)(S_h/S) X̄_ac_h
            - C_L_alpha_c (1 + de_c/dalpha) X̄_ac_c (S_c/S) } / C_L_alpha_wf ] / F      (11.1)
```

*[Roskam Part II, Eq. (11.2), p. 261]*

```
F = [ 1 + { C_L_alpha_h (1 - de_h/dalpha)(S_h/S)
          + C_L_alpha_c (1 + de_c/dalpha)(S_c/S) } / C_L_alpha_wf ]                    (11.2)
```

Notation (see Figure 11.2 for the geometry):

| Symbol | Meaning | Units |
|---|---|---|
| `X̄` | `X / c̄_w` — any station made non-dimensional on the wing m.g.c. | — |
| `X̄_ac_A` | a.c. of the complete airplane | fraction `c̄_w` |
| `X̄_ac_wf` | a.c. of the wing + fuselage combination | fraction `c̄_w` |
| `X̄_ac_h` | a.c. of the horizontal tail, `x_ac_h / c̄_w` | fraction `c̄_w` |
| `X̄_ac_c` | a.c. of the canard, `x_ac_c / c̄_w` | fraction `c̄_w` |
| `C_L_alpha_wf` | lift-curve slope of wing + fuselage | 1/deg (or 1/rad) |
| `C_L_alpha_h` | lift-curve slope of the horizontal tail | 1/deg (or 1/rad) |
| `C_L_alpha_c` | lift-curve slope of the canard | 1/deg (or 1/rad) |
| `de_h/dalpha` | downwash gradient at the horizontal tail | — |
| `de_c/dalpha` | upwash gradient at the canard | — |
| `S` | wing reference area | ft² |
| `S_h`, `S_c` | horizontal tail area, canard area | ft² |

**Reference-area note:** `S_h/S` and `S_c/S` are ratios to the **wing** reference area `S`. All
`X̄` values are ratios to the **wing** mean geometric chord `c̄_w`. The tail term carries
`(1 - de_h/dalpha)`; the canard term carries `(1 + de_c/dalpha)`, because the canard sees upwash.
The dynamic-pressure ratios `q_h/q` and `q_c/q` do not appear in the printed equations.

Compute the aerodynamic quantities with the methods of Part VI (Ref. 5).

How to use Eqns. (11.1) and (11.2) for each configuration type:

| Configuration | Set | Independent variable |
|---|---|---|
| Tail-aft airplane | `S_c = 0` | `S_h` |
| Canard airplane | `S_h = 0` | `S_c` |
| Three-surface airplane | freeze the ratio `S_h/S_c` | `S_h` |

For a three-surface airplane, make the X-plot for several values of `S_h/S_c`.

Plot both legs against area. That completes the longitudinal X-plot.

#### Figure 11.1 — Examples of Longitudinal X-Plots
*[Roskam Part II, Fig. 11.1, p. 260]*

Three conceptual (schematic, unscaled) X-plots. Ordinate: `X̄_ac_A` and `X̄_cg` ~ fraction `c̄_w`.
Abscissa: horizontal tail area `S_h` ~ ft² (or canard area `S_c` ~ ft²). No numeric scales are
printed, so **no data points can be digitized**. The shapes are:

- **Conventional (tail-aft) configurations:** `X̄_ac_A` rises steeply with `S_h` from a low
  intercept. `X̄_cg_AFT` rises slowly from a higher intercept. The two lines cross. To the right of
  the crossing, the vertical gap `X̄_ac_A − X̄_cg_AFT` is the static margin. The required `S_h` is
  where that gap is equal to the desired S.M.
- **Canard configurations:** `X̄_ac_A` falls with `S_c` from a high intercept. `X̄_cg_AFT` falls
  slowly. The gap `X̄_ac_A − X̄_cg_AFT` closes as `S_c` grows, so the allowable `S_c` is bounded
  from **above**.
- **Three-surface configurations:** a family of `X̄_ac_A` and `X̄_cg` lines, one pair for each value
  of `S_h/S_c` (curves labelled 1, 2, 3). All lines start from a common point at `S_h = 0`.

#### Figure 11.2 — Geometric Quantities for A.C. Calculations
*[Roskam Part II, Fig. 11.2, p. 262]*

Three plan-view sketches (conventional twin turboprop, canard twin pusher, three-surface twin).
Each labels `x_ac_h` and/or `x_ac_c` as the distance from the airplane a.c. (`a.c._A`, near the aft
c.g. on the wing m.g.c.) to the tail or canard a.c. It also labels `c̄_w`, `c̄_h`, `c̄_c` and the
AFT C.G. The note on the figure gives `X̄ = X / c̄_w`. Layout sketch, no plotted data.

### Step 11.2 — Decide: inherently stable or de-facto stable

- **Inherent stability** is required of every airplane that does **not** use a feedback
  augmentation system for its stability. Go to Step 11.3.
- **De-facto stability** is required of every airplane that is stable **only** with a feedback
  augmentation system in place. Go to Step 11.6.

### Step 11.3 — Find the airplane category

Use the twelve categories listed on p. 28 of Chapter 2.

- Categories 1–4: go to Step 11.4.
- Categories 5–12: go to Step 11.5.

### Step 11.4 — Empennage area for a minimum static margin of 10 percent

Applies to categories 1–4. Reference 9 (Chapter 5) shows that for a 10 percent static margin:

*[Roskam Part II, Eq. (11.3), p. 263]*

```
dC_m/dC_L = X̄_cg - X̄_ac = -0.10                                                        (11.3)
```

Read the required empennage area off the 'aft' c.g. leg of Figure 11.1. Record it.

### Step 11.5 — Empennage area for a minimum static margin of 5 percent

Applies to categories 5–12.

*[Roskam Part II, Eq. (11.4), p. 263]*

```
dC_m/dC_L = X̄_cg - X̄_ac = -0.05                                                        (11.4)
```

Read the required empennage area off the 'aft' c.g. leg of Figure 11.1. Record it.

### Step 11.6 — SAS feedback gain for a de-facto stable airplane

Use the 'aft' c.g. leg of Figure 11.1. Find the SAS feedback gain as a function of negative static
margin.

*[Roskam Part II, Eq. (11.5), p. 264]*

```
k_alpha = (DeltaSM) C_L_alpha / C_m_delta_e                                             (11.5)
```

*[Roskam Part II, Eq. (11.6), p. 264]*

```
C_L_alpha = C_L_alpha_wf + C_L_alpha_h (1 - de/dalpha)(S_h/S)
                         + C_L_alpha_c (1 + de/dalpha) S_c/S                            (11.6)
```

*[Roskam Part II, Eq. (11.7), p. 264]*

```
DeltaSM = | X̄_ac - X̄_cg - 0.05 |                                                       (11.7)
```

| Symbol | Meaning | Units |
|---|---|---|
| `k_alpha` | angle-of-attack to elevator feedback gain | deg elevator per deg alpha |
| `C_m_delta_e` | elevator control power derivative | 1/deg |
| `DeltaSM` | incremental static margin | fraction `c̄_w` |

**Limit:** `k_alpha` must not be more than **5 deg of elevator per degree of angle of attack**.
Eqn. (11.5) is written for angle-of-attack feedback to the elevator. If angle of attack is fed back
to the stabilizer (some fighters) or to the canard (as on the X-29), the same 5 deg/deg limit
applies.

Take `X̄_cg` and `X̄_ac` from the X-plot of Figure 11.1 at any empennage area. The highest level of
static instability that is practical is the level that drives `k_alpha` above 5 deg/deg. The
matching empennage area is the smallest area that is allowed. Record it.

**Note on Eqn. (11.6):** the printed equation uses one symbol `de/dalpha` in both the tail term and
the canard term. The signs `(1 - de/dalpha)` and `(1 + de/dalpha)` show that the first is the
downwash gradient at the tail and the second is the upwash gradient at the canard — the same
quantities written `de_h/dalpha` and `de_c/dalpha` in Eqn. (11.1).

### Step 11.7 — Compare with the V-bar method

The empennage area from Eqn. (11.4), (11.5) or (11.6) replaces the area from the tail-volume (`V̄`)
method, Eqn. (8.3).

If the two empennage areas differ by more than **10 percent**, review the airplane weight and
balance calculation of Chapter 10 and make the adjustments that are needed.

**Suspected misprint (p. 264):** Step 11.7 says the area comes from "Eqn. (11.4), (11.5) or
(11.6)". Equations (11.5) and (11.6) are the SAS gain and the airplane lift-curve slope, not areas.
The intended list is most probably Eqn. (11.3), (11.4) or the Step 11.6 result.

---

## §11.2 Static Directional Stability (Directional X-Plot)

### Step 11.8 — Prepare a directional X-plot

Figure 11.3 shows an example. Get the c.g. leg again from the Class I weight analysis of Step 10.
That analysis gives the vertical tail weight **per ft²**.

The `C_n_beta` leg comes from:

*[Roskam Part II, Eq. (11.8), p. 265]*

```
C_n_beta = C_n_beta_wf + C_L_alpha_v (S_v/S)(x_v/b)                                     (11.8)
```

| Symbol | Meaning | Units |
|---|---|---|
| `C_n_beta` | directional stability of the airplane | 1/deg |
| `C_n_beta_wf` | directional stability of wing + fuselage (negative, destabilizing) | 1/deg |
| `C_L_alpha_v` | lift-curve slope of the vertical tail | 1/deg |
| `S_v` | vertical tail area | ft² |
| `S` | wing reference area | ft² |
| `x_v` | distance from the aft c.g. to the vertical tail a.c. | ft |
| `b` | wing span | ft |

**Reference note:** `C_n_beta` is referenced to wing area `S` and wing span `b`. The tail moment
arm `x_v` is made non-dimensional on the **span**, not on the chord. Figure 11.4 defines `x_v`,
`S_v`, `c̄_v` and `a.c._v`. Compute the aerodynamic terms with the methods of Part VI (Ref. 5).

#### Figure 11.3 — Example of Directional X-Plot
*[Roskam Part II, Fig. 11.3, p. 266]*

Schematic plot. Ordinate: directional stability `C_n_beta` ~ deg⁻¹, with the single printed level
`+0.0010`. Abscissa: vertical tail area `S_v` ~ ft², no numeric scale printed. One straight line
rises from a negative intercept marked `C_n_beta_f(wf)` at `S_v = 0`, crosses zero, and meets the
`0.0010` level. The required `S_v` is read at that crossing. Only the `0.0010` level is a numeric
value; **the abscissa has no scale, so no further points can be digitized.**

#### Figure 11.4 — Geometric Quantities for Directional X-Plot
*[Roskam Part II, Fig. 11.4, p. 266]*

Side-view sketch of a jet with a swept vertical tail. Labels: AFT C.G.; `x_v` from the aft c.g. to
`a.c._v`; the hatched vertical tail area `S_v`; `c̄_v`. Layout sketch, no plotted data.

### Step 11.9 — Decide: inherent or de-facto directional stability

- Inherent directional stability: go to Step 11.10.
- De-facto directional stability: go to Step 11.11.

### Step 11.10 — Required inherent directional stability level

*[Roskam Part II, Eq. (11.9), p. 265]*

```
C_n_beta = 0.0010 per deg                                                               (11.9)
```

Go to the X-plot of Figure 11.3 and find the `S_v` that gives this level.

### Step 11.11 — Sideslip to rudder feedback gain

*[Roskam Part II, Eq. (11.10), p. 265]*

```
k_beta = (DeltaC_n_beta) / C_n_delta_r                                                  (11.10)
```

*[Roskam Part II, Eq. (11.11), p. 267]*

```
DeltaC_n_beta = 0.0010 - C_n_beta                                                       (11.11)
```

| Symbol | Meaning | Units |
|---|---|---|
| `k_beta` | sideslip to rudder feedback gain | deg rudder per deg sideslip |
| `C_n_delta_r` | rudder control power derivative | 1/deg |

**Limit:** `k_beta` must not be more than **5 deg/deg**.

The vertical tail area that gives the lowest inherent `C_n_beta` that still satisfies Eqn. (11.11)
is the smallest vertical tail area that is allowed. Record it.

---

## §11.3 Minimum Control Speed with One Engine Inoperative

### Step 11.12 — Critical engine-out yawing moment

*[Roskam Part II, Eq. (11.12), p. 267]*

```
N_t_crit = T_TO_e * y_t                                                                 (11.12)
```

| Symbol | Meaning | Units |
|---|---|---|
| `N_t_crit` | yawing moment from the thrust of the operating engine | ft·lb |
| `T_TO_e` | take-off thrust **per engine** | lb |
| `y_t` | lateral thrust moment arm of the most critical engine | ft |

Figure 11.5 shows `y_t`. For a propeller driven airplane, change the known `P_TO` to the matching
`T_TO`. Figure 3.8 of Part I (p. 100) does this.

### Step 11.13 — Drag-induced yawing moment of the dead engine

*[Roskam Part II, Eqs. (11.13)–(11.16), pp. 267–268]*

| Airplane / engine type | Equation | Number |
|---|---|---|
| Propeller driven, **fixed** pitch propellers | `N_D = 0.25 N_t_crit` | (11.13) |
| Propeller driven, **variable** pitch propellers | `N_D = 0.10 N_t_crit` | (11.14) |
| Jet driven, windmilling engine, **low** b.p.r. | `N_D = 0.15 N_t_crit` | (11.15) |
| Jet driven, windmilling engine, **high** b.p.r. | `N_D = 0.25 N_t_crit` | (11.16) |

`N_D` is the yawing moment from the drag of the inoperative engine, in ft·lb.

### Step 11.14 — Maximum allowable minimum control speed

*[Roskam Part II, Eq. (11.17), p. 268]*

```
V_mc = 1.2 V_s                                                                          (11.17)
```

`V_s` is the **lowest** stall speed of the airplane. This is usually the landing stall speed.

### Step 11.15 — Rudder deflection needed at V_mc

*[Roskam Part II, Eq. (11.18), p. 268]*

```
delta_r = (N_D + N_t_crit) / (q̄_mc * S * b * C_n_delta_r)                               (11.18)
```

| Symbol | Meaning | Units |
|---|---|---|
| `delta_r` | rudder deflection needed to hold the engine-out condition | deg |
| `q̄_mc` | dynamic pressure at `V_mc` | lb/ft² |
| `S` | wing reference area | ft² |
| `b` | wing span | ft |
| `C_n_delta_r` | rudder control power derivative | 1/deg |

Compute `C_n_delta_r` with the methods of Part VI (Ref. 5).

**Limit:** `delta_r` from Eqn. (11.18) must be **no more than 25 degrees**. If it is more, change
the rudder size and/or the vertical tail size until the limit is met. Record that vertical tail
area.

#### Figure 11.5 — Geometry for Engine-out V_mc Calculation
*[Roskam Part II, Fig. 11.5, p. 266]*

Plan-view sketch of a four-engine turboprop. Labels: STOPPED PROP. DRAG on the failed engine;
`T_TO/4` on an operating engine; `y_t` measured from the fuselage centreline to that engine.
Layout sketch, no plotted data.

### Step 11.16 — Choose the vertical tail area

The **largest** vertical tail area from Steps 11.10, 11.11 or 11.15 is the vertical tail area that
the airplane needs.

If that area differs by more than **10 percent** from the area computed with the `V̄` method of
Eqn. (8.4), adjust the weight and balance calculations of Chapter 10.

---

## §11.4 Example Applications

Three examples:

- §11.4.1 Twin engine propeller driven airplane: **Selene**
- §11.4.2 Jet transport: **Ourania**
- §11.4.3 Fighter: **Eris**

### §11.4.1 Twin Engine Propeller Driven Airplane (Selene)

**Step 11.1.** Figure 11.6 gives the longitudinal X-plot. For the airplane to be 0.10 stable at its
operating weight empty, it needs a horizontal tail area of **58 ft²**. That is an increase of
`58 − 37 = 21 ft²`. The larger tail moves the aft c.g. to `0.9 c̄_w`. That is still forward of the
main landing gear. However, the main gear may have to move a little aft for the longitudinal
tip-over criterion of Chapter 9.

The X-plot also shows that the Selene must not fly at `W_OE` plus two aft passengers plus aft
luggage. The airplane becomes unstable in that condition. This occurs often in this type of
airplane.

With power on, the stability is much better. That is typical of pusher-propeller airplanes.

**Step 11.2.** The Selene must be inherently stable. Full time stability augmentation is probably
not affordable in this type of airplane.

**Step 11.3.** The Selene is category 3: twin engine propeller driven airplanes.

**Step 11.4.** The horizontal tail area must grow from 37 to 58 ft² (decided in Step 11.1).

**Steps 11.5 – 11.7.** Not applicable.

#### Figure 11.6 — Selene: Longitudinal X-Plot
*[Roskam Part II, Fig. 11.6, p. 270]*

Ordinate: `X̄_ac_A` or `X̄_cg` ~ fraction `c̄_w`, scaled 0.2 to 1.2. Abscissa: horizontal tail area
`S_h` ~ ft², scaled 0 to 100.

Digitized (read from plot), all values in fraction `c̄_w`:

| Line | Value at `S_h = 0` | Value at `S_h = 100` |
|---|---|---|
| `X̄_ac_A` (T.O. PWR) — the figure marks this line "*GUESSED!" | 0.20 | ≈1.28 |
| `X̄_ac_A` (NO POWER) | 0.20 | ≈1.20 |
| `X̄_cg_AFT` (NOT FLIGHT) | ≈0.63 | ≈1.19 |
| `X̄_cg` (`W_OE` + aft pax + aft luggage) | ≈0.60 | ≈1.15 |
| `X̄_cg` (`W_E`) | ≈0.57 | ≈1.06 |
| `X̄_cg` (`W_OE`) | ≈0.55 | ≈1.01 |
| `X̄_cg` (`W_TO`) | ≈0.52 | ≈0.96 |

Two construction ordinates are labelled on the abscissa: **37** (the V̄-method tail area) and **74**.
A third construction ordinate is drawn at approximately 58 ft² but is not labelled with a number on
the plot. The text uses 58 ft² as the area for a 10 percent static margin at `W_OE`. The
"*GUESSED!" note on the figure applies to the take-off-power a.c. line: the book itself marks that
line as an estimate.

#### Figure 11.7 — Selene: Directional X-Plot
*[Roskam Part II, Fig. 11.7, p. 270]*

Ordinate: directional stability `C_n_beta` ~ deg⁻¹, scaled −0.0040 to +0.0020. Abscissa: vertical
tail area `S_v` ~ ft², ticks at 20 and 40.

Digitized (read from plot):

| Point | `S_v` (ft²) | `C_n_beta` (1/deg) |
|---|---|---|
| Wing + fuselage only (intercept, labelled `C_n_beta_WE`) | 0 | ≈ −0.0035 |
| Zero directional stability | ≈ 25 | 0 |
| Required level (labelled `+0.001`) | **38** | +0.0010 |

The line is straight. This agrees with Eqn. (11.8). Slope from the two end points:
`(0.0010 − (−0.0035)) / 38 ≈ 1.2e-4 per deg per ft²` (read from plot).

**Step 11.8.** Figure 11.7 gives the directional X-plot for the Selene.

**Step 11.9.** The Selene needs inherent directional stability. Full time stability augmentation in
this type of airplane is probably not affordable.

**Step 11.10.** Figure 11.7 shows that the vertical tail of the Selene is a little too large. An
area of **36 ft²** is sufficient for directional stability.

**Step 11.11.** Not applicable.

**Step 11.12.** From the general arrangement drawing (Fig. 10.3), `y_t = 6.3 ft`. The maximum
take-off power `P_TO` from Chapter 5 (p. 135) is 449 hp per engine. Figure 3.8 of Part I (p. 100)
gives `T_TO = 1,200 lb` per engine. Therefore:

```
N_t_crit = 1,200 x 6.3 = 7,560 ft-lb
```

**Step 11.13.** The Selene has variable pitch propellers. The book computes:

```
N_D = 0.25 x 7,560 = 1,890 ft-lb
```

**Suspected misprint (p. 271):** Eqn. (11.14) gives `N_D = 0.10 N_t_crit` for **variable** pitch
propellers. 0.25 is the **fixed** pitch factor of Eqn. (11.13). The worked example uses 0.25 with a
variable pitch propeller. The printed numbers (0.25 x 7,560 = 1,890) agree with each other, but they
do not agree with the equation the text names.

**Step 11.14.** The landing stall speed is the lowest stall speed: `V_s = 99.3 kt`. Therefore
`V_mc = 1.2 x 99.3 = 119 kt`.

**Step 11.15.** From the vertical tail and rudder geometry of Chapter 8 (pp. 210–211) and the
methods of Part VI:

```
C_n_delta_r = -0.0027 per deg
```

Eqn. (11.18) then gives `delta_r = 16.4 deg` at `V_mc`. That is well inside the 25 deg limit.

**Step 11.16.** The vertical tail size of the Selene is 'critical' from a directional stability
viewpoint. The existing tail size of **38 ft²** is sufficient.

**Internal inconsistency note:** Step 11.10 (p. 271) gives 36 ft² as sufficient. Step 11.16 (p. 272)
says "the existing tail size of 38 ft²". Figure 11.7 marks 38 ft² at `C_n_beta = +0.0010`. The two
numbers are the required area (36) and the area already on the airplane (38).

### §11.4.2 Jet Transport (Ourania)

**Step 11.1.** Figure 11.8 gives the longitudinal X-plot. The Ourania is longitudinally stable with
**no** horizontal tail. The cause is a wing position that is too far forward on the fuselage. Move
the wing, and the main landing gear with it, **200 inches aft**. Then, at the nominal tail area of
**254 ft²**, the Ourania has an instability level of `0.085 c̄_w`. The Ourania is a 'relaxed'
stability airplane.

Figure 11.9 shows how the 'wing + main gear' movement changes the c.g. position on `c̄_w`.

**Step 11.2.** The Ourania must be a 'relaxed stability' airplane. The instability level at aft c.g.
should get a detailed study of the benefit in trimmed lift-to-drag ratio. For this p.d. study,
`0.085 c̄_w` instability is selected arbitrarily.

**Step 11.3.** Category 7: jet transports. (The printed text says "The Selene fits into category 7",
but the subject of §11.4.2 is the Ourania. This is a name misprint.)

**Steps 11.4 and 11.5.** Not applicable.

**Step 11.6.** With the aft c.g. leg for the 200 in. aft wing shift (Figure 11.8), the longitudinal
stability augmentation system must generate an incremental static margin of:

```
DeltaSM = 0.085 + 0.05 = 0.135
```

Airplane values: `C_L_alpha = 0.081 per deg`; `C_m_delta_e = -0.0251 per deg`. Eqn. (11.5) then
gives `k_alpha = 0.44`. That is an acceptable feedback gain.
(Check: 0.135 x 0.081 / 0.0251 = 0.436.)

From this viewpoint the horizontal tail could be smaller. It is prudent not to make it smaller yet.
Class II methods may show that take-off rotation and trim at forward c.g. with the flaps down are
more restrictive for the tailplane.

**Step 11.7.** Keep the horizontal tail area at **254 ft²**.

**Step 11.8.** Figure 11.10 gives the directional X-plot.

**Step 11.9.** The Ourania is a 'relaxed' stability airplane.

**Step 11.10.** Not applicable.

**Step 11.11.** Figure 11.10 shows `C_n_beta = -0.0016` for the existing vertical tail. The de-facto
level wanted is 0.0010. The sideslip feedback system must supply the difference of 0.0026. With
`C_n_delta_r = -0.0012 per deg`, Eqn. (11.10) gives:

```
k_beta = 0.0026 / 0.0012 = 2.2 deg/deg
```

That is acceptable. From this viewpoint the vertical tail of the Ourania is not critical.

**Step 11.12.** From the general arrangement drawing (Fig. 10.4), `y_t = 16.7 ft`. `T_TO` from
Chapter 5 (p. 138) is 24,000 lb per engine. Therefore:

```
N_t_crit = 24,000 x 16.7 = 400,800 ft-lb
```

**Step 11.13.** The Ourania has high b.p.r. engines, so Eqn. (11.16) applies. The total yawing
moment to hold at `V_mc` is:

```
N_D + N_t_crit = 1.25 x 400,800 = 501,000 ft-lb
```

**Step 11.14.** `V_s_L = 87 kt`, so `V_mc = 105 kt`.

**Step 11.15.** From Chapter 8 (pp. 210–211) and Part VI: `C_n_delta_r = -0.0012 per deg`. Eqn.
(11.18) gives `delta_r = -76 deg`. That is much too much, so the vertical tail of the Ourania is too
small.

A satisfactory solution is found if all of these changes are made together:

| Change | From | To |
|---|---|---|
| Vertical tail area `S_v` | 164 ft² | **200 ft²** |
| Rudder area ratio `S_r/S_v` | 0.35 | **0.45** |
| Maximum rudder deflection (double hinge line, variable camber) | 25 deg | **40 deg** |

More detailed analysis, and possibly a wind tunnel test, must confirm this before the final decision
on vertical tail size. For p.d. purposes, take `S_v = 200 ft²`.

**Step 11.16.** Increase the vertical tail from 164 to **200 ft²**.

#### Figure 11.8 — Ourania: Longitudinal X-Plot
*[Roskam Part II, Fig. 11.8, p. 273]*

Ordinate: `X̄_ac_A` and `X̄_cg` ~ fraction `c̄_w`, scaled 0 to 0.6. Abscissa: horizontal tail area
`S_h` ~ ft², scaled 0 to 300.

Digitized (read from plot), fraction `c̄_w`:

| Line | at `S_h = 0` | at `S_h = 254` | at `S_h = 300` |
|---|---|---|---|
| `X̄_cg_AFT`, wing + m.g. 200 in. moved aft | ≈0.415 | **0.567** (printed) | ≈0.59 |
| `X̄_ac_A`, nominal config. | ≈0.048 | ≈0.49 | ≈0.57 |
| `X̄_ac_A`, wing + m.g. 200 in. moved aft | ≈0.038 | **0.482** (= 0.567 − 0.085) | ≈0.555 |
| `X̄_cg_AFT`, nominal config. | ≈0.008 | ≈0.115 | ≈0.135 |

Printed callouts: `0.567` on the ordinate; `.085 c̄` as the gap between the aft-c.g. line and the
a.c. line at `S_h = 254`; `254` on the abscissa. The two `X̄_ac_A` lines almost overlap. Moving the
wing aft changes the a.c. leg very little, but it changes the c.g. leg a lot.

#### Figure 11.9 — Ourania: Effect of 'Wing + Main Gear' Aft Movement on Airplane Center of Gravity
*[Roskam Part II, Fig. 11.9, p. 273]*

Ordinate: `X̄_cg` ~ fraction `c̄_w`, scaled 0 to 1.0. Abscissa: aft movement of (wing + m.g.) ~ in.,
ticks at 100 and 200.

Digitized (read from plot): a straight line through the origin. At 200 in. of aft movement,
`X̄_cg = 0.567` (printed). Slope ≈ `0.567 / 200 = 2.8e-3 per inch` (read from plot).

#### Figure 11.10 — Ourania: Directional X-Plot
*[Roskam Part II, Fig. 11.10, p. 275]*

Ordinate: `C_n_beta` ~ deg⁻¹, scaled −0.0040 to +0.0020. Abscissa: vertical tail area `S_v` ~ ft²,
scaled 0 to 300.

Digitized (read from plot):

| Point | `S_v` (ft²) | `C_n_beta` (1/deg) |
|---|---|---|
| Wing + fuselage only (labelled `C_n_beta_WE`) | 0 | −0.0040 (on the printed axis value) |
| Existing tail | **164** (printed) | **−0.0016** (printed) |
| Zero directional stability | ≈280 | 0 |

Straight line. Slope from the two printed points: `(−0.0016 − (−0.0040)) / 164 ≈ 1.5e-5 per deg per
ft²` (read from plot). The `+0.0010` de-facto level is drawn as a horizontal reference. The line
does not reach it inside the plotted `S_v` range.

Page 275 also carries a cutaway drawing of the **F/A-18A Hornet** (courtesy of McDonnell Douglas).
Illustration only, no plotted data.

### §11.4.3 Fighter (Eris)

**Step 11.1.** Figure 11.11 gives the longitudinal X-plot. The Eris is longitudinally unstable with
no horizontal tail. At the horizontal tail area of **93 ft²** (from the V̄-method of Chapter 8), the
instability level is `0.133 c̄_w`. For comparison, the X-29 was designed to `0.350 c̄_w` instability
at its aft c.g.

**Step 11.2.** The Eris must be a negative stability airplane. The instability level at aft c.g. and
at forward c.g. should get a detailed study of the benefits in trimmed lift-to-drag ratio and in
manoeuvre performance. For this p.d. study, `0.133 c̄_w` is selected arbitrarily.

**Step 11.3.** Category 9: fighters. (The printed text says "The Selene fits into category 9". This
is a name misprint; the subject is the Eris.)

**Steps 11.4 and 11.5.** Not applicable.

**Step 11.6.** From the aft c.g. leg of Figure 11.11:

```
DeltaSM = 0.133 + 0.05 = 0.185
```

Airplane values: `C_L_alpha = 0.078 per deg`; `C_m_delta_e = -0.0182 per deg`. Eqn. (11.5) gives
`k_alpha = 0.80`. That is acceptable. (Check: 0.185 x 0.078 / 0.0182 = 0.793.)

The horizontal tail could be smaller from this viewpoint, but it is prudent not to make it smaller
yet. Class II methods may show that take-off rotation and trim at forward c.g. with flaps down are
more restrictive.

**Step 11.7.** Keep the horizontal tail area at **93 ft²**.

**Step 11.8.** Figure 11.12 gives the directional X-plot.

**Step 11.9.** The Eris is a 'negative' stability airplane.

**Step 11.10.** Not applicable.

**Step 11.11.** Figure 11.12 shows that the vertical tail of the Eris leaves the airplane
directionally unstable at `C_n_beta = -0.0005`. The de-facto level wanted is 0.0010, so the sideslip
feedback system must supply 0.0015. With `C_n_delta_r = -0.0007 per deg`:

```
k_beta = 0.0015 / 0.0007 = 2.1 deg/deg
```

That is acceptable. From this viewpoint the vertical tail of the Eris is not critical.

**Step 11.12.** From the general arrangement drawing (Fig. 10.5), `y_t = 1.7 ft`. `T_TO` from
Chapter 5 (p. 140) is 16,000 lb per engine. The book then computes:

```
N_t_crit = 12,000 x 1.7 = 20,400 ft-lb
```

**Suspected misprint (p. 279):** the text gives `T_TO = 16,000 lb` per engine but multiplies by
12,000. With 16,000 lb the result would be 27,200 ft-lb, not 20,400 ft-lb. The rest of the example
(Steps 11.13 and 11.15) carries the 20,400 value forward, so the arithmetic agrees with itself from
that point on. Which of the two thrust values is the intended one cannot be told from this chapter.

**Step 11.13.** The Eris has low b.p.r. engines. The total yawing moment to hold at `V_mc` is:

```
N_D + N_t_crit = 1.15 x 20,400 = 23,460 ft-lb
```

**Suspected misprint (p. 279):** the text names Eqn. (11.16) but then uses the factor 0.15, which is
Eqn. (11.15) — the correct equation for a **low** b.p.r. windmilling engine. The number used (1.15)
is right for a low b.p.r. engine; the equation number printed is wrong.

**Step 11.14.** The landing stall speed is the lowest: 131 kt. Therefore `V_mc = 158 kt`
(1.2 x 131 = 157.2).

**Step 11.15.** From the vertical tail and rudder geometry of Chapter 8 (pp. 214–215) and Part VI:

```
C_n_delta_r = -0.00074 per deg
```

Eqn. (11.18) gives `delta_r = 9.3 deg` at `V_mc`. That is acceptable, so the vertical tail of the
Eris is not critical for engine-out control.

**Step 11.16.** Keep the vertical tail size at **147 ft²**.

#### Figure 11.11 — Eris: Longitudinal X-Plot
*[Roskam Part II, Fig. 11.11, p. 278]*

Ordinate: `X̄_ac_A` and `X̄_cg` ~ fraction `c̄_w`, scaled 0 to 1.0. Abscissa: horizontal tail area
`S_h` ~ ft², ticks at 100 and 200.

Digitized (read from plot), fraction `c̄_w`:

| Line | at `S_h = 0` | at `S_h = 93` | at `S_h = 200` |
|---|---|---|---|
| `X̄_cg_AFT` | ≈0.44 | **0.490** (printed) | ≈0.55 |
| `X̄_ac_A` | ≈0.23 | **0.357** (printed) | ≈0.49 |

The printed gap is labelled `Delta S.M. = 0.133`, which is `0.490 − 0.357`. The construction
ordinate is labelled `93 FT²`. The two lines cross near `S_h ≈ 190 ft²`. That is the tail area for
neutral stability (read from plot).

#### Figure 11.12 — Eris: Directional X-Plot
*[Roskam Part II, Fig. 11.12, p. 278]*

Ordinate: `C_n_beta` ~ deg⁻¹, scaled −0.0020 to +0.0020. Abscissa: vertical tail area `S_v` ~ ft²,
ticks at 100 and 200.

Two nearly parallel lines are drawn, labelled "NO C.G. CORR." and "WITH C.G. CORR.". They separate
only above about 150 ft².

Digitized (read from plot):

| Point | `S_v` (ft²) | `C_n_beta` (1/deg) |
|---|---|---|
| Wing + fuselage only (labelled `C_n_beta_wf`) | 0 | ≈ −0.0026 |
| Existing tail | **147** (printed) | **−0.0005** (printed) |
| Zero directional stability, "with c.g. corr." line | ≈180 | 0 |
| Zero directional stability, "no c.g. corr." line | ≈190 | 0 |

Slope of the main line from the two printed points: `(−0.0005 − (−0.0026)) / 147 ≈ 1.4e-5 per deg
per ft²` (read from plot). The `+0.0010` de-facto level is drawn as a horizontal reference.

Page 280 also carries a cutaway drawing of the **F-15 Eagle** (courtesy of McDonnell Douglas).
Illustration only, no plotted data.

---

## Summary of chapter constants (for implementation)

| Quantity | Value | Where |
|---|---|---|
| Static margin, airplane categories 1–4 | 0.10 (`dC_m/dC_L = -0.10`) | Eq. (11.3) |
| Static margin, airplane categories 5–12 | 0.05 (`dC_m/dC_L = -0.05`) | Eq. (11.4) |
| Reference static margin inside `DeltaSM` | 0.05 | Eq. (11.7) |
| Maximum alpha-to-elevator feedback gain `k_alpha` | 5 deg/deg | p. 264 |
| Required directional stability `C_n_beta` | +0.0010 per deg | Eq. (11.9) |
| Maximum sideslip-to-rudder feedback gain `k_beta` | 5 deg/deg | p. 267 |
| `N_D` factor, fixed pitch propeller | 0.25 | Eq. (11.13) |
| `N_D` factor, variable pitch propeller | 0.10 | Eq. (11.14) |
| `N_D` factor, low b.p.r. jet, windmilling | 0.15 | Eq. (11.15) |
| `N_D` factor, high b.p.r. jet, windmilling | 0.25 | Eq. (11.16) |
| `V_mc` limit | `1.2 V_s` (lowest stall speed) | Eq. (11.17) |
| Maximum rudder deflection at `V_mc` | 25 deg | p. 268 |
| Trigger to redo the Chapter 10 weight and balance | more than 10 percent area difference against the V̄-method | pp. 264, 268 |
