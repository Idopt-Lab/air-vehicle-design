# Chapter 7 — Class I Method for Verifying Clean Airplane C_Lmax and for Sizing High Lift Devices

**Source:** Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration of the Propulsion System*, Chapter 7 "Class I Method for Verifying Clean Airplane C_Lmax and for Sizing High Lift Devices," printed pp. 167–186 (PDF index 178–197).

The chapter gives a Class I procedure that does two things:
1. It shows if the wing planform from Chapter 6 can make the required clean airplane C_Lmax.
2. It gives the type and the size of the high lift devices that are necessary for C_LmaxTO and C_LmaxL.

The method is Step 7 of p.d. sequence I (Chapter 2). Section 7.1 gives the 8-step
procedure. Section 7.2 gives three example applications.

**IMPORTANT LIMIT (p. 167):** Do not use this method for wing sweep angles larger than
approximately +/- 35 degrees. For larger sweep angles use Part VI (Ref. 5).

---

## §7.1 A Procedure for Determining Clean Airplane C_Lmax and for Sizing High Lift Devices

### Step 7.1 — List the required maximum lift coefficients (p. 167)

List three values, all of which come from the preliminary sizing process of Part I:

| Condition | Symbol |
|---|---|
| Clean | C_Lmax |
| Take-off | C_LmaxTO |
| Landing | C_LmaxL |

### Step 7.2 — Verify that the wing planform can make the required C_Lmaxw (pp. 167–170)

Any total airplane C_Lmax must be a *trimmed* value. For most configurations
(conventional and canard) it is conservative in early preliminary design to assume:

```
C_Lmax_w = 1.05 to 1.1 C_Lmax                                    (7.1)   [p. 168]
```

The factor 1.05 to 1.1 accounts for the tail down-load to trim, or for the interference
of the canard up-load to trim on the wing.

| Coupling | Definition | Factor to use |
|---|---|---|
| 'short-coupled' | l_h / c̄ < 3.0 | 1.1 |
| 'long-coupled' | l_h / c̄ > 5.0 | 1.05 |

(`l_h` = horizontal tail arm, `c̄` = wing mean geometric chord.)

If the wing sweep angle is between 0 and 35 degrees, correct for sweep with the
'cosine-rule':

```
C_Lmax_w (unswept) = C_Lmax_w (swept) / cos Λ_c/4                 (7.2)   [p. 168]
```

To find out if the wing can make the required unswept C_Lmax_w, use:

```
C_Lmax_w = k_λ ( c_lmax_r + c_lmax_t ) / 2                        (7.3)   [p. 168]

where:  k_λ = 0.88 for λ = 1.0
        k_λ = 0.95 for λ = 0.4
```

`c_lmax_r` = airfoil section maximum lift coefficient at the root.
`c_lmax_t` = airfoil section maximum lift coefficient at the tip.
`λ` = wing taper ratio.

**NOTE (printed in the book): Eqn. (7.3) does not account for wing twist.**

Section maximum lift coefficients come from Ref. 20 and Ref. 23. If those references are
not available, take the root and tip values from **Figure 7.1**. Before Fig. 7.1 can be
used, compute the root and tip Reynolds numbers:

```
at the root:  R_n_r = ρ V c_r / μ                                 (7.4)   [p. 170]
at the tip:   R_n_t = ρ V c_t / μ                                 (7.5)   [p. 170]
```

(`ρ` = air density, `V` = speed, `c_r`/`c_t` = root/tip chord, `μ` = dynamic viscosity.
The worked examples use ρ = 0.002378 slug/ft³ and μ = 3.737 x 10^-7 lb-s/ft², i.e. sea
level standard.)

If the wing planform cannot meet the required C_Lmax within 5 percent, redesign the wing
planform and/or select different airfoils until it does. Roskam states it makes very
little sense to continue with a wing design that cannot deliver the required clean
maximum lift coefficient.

### Step 7.3 — Determine the increments that the high lift devices must produce (p. 170)

```
Take-off:  ΔC_LmaxTO = 1.05 ( C_LmaxTO - C_Lmax )                 (7.6)   [p. 170]
Landing:   ΔC_LmaxL  = 1.05 ( C_LmaxL  - C_Lmax )                 (7.7)   [p. 170]
```

The factor 1.05 accounts for the additional trim penalties that flaps cause. These
penalties exist for conventional and for canard configurations.

> **Book inconsistency:** the Selene example on p. 177 uses a factor of **1.07** in both
> Eqns. (7.6) and (7.7), not the 1.05 printed with the equations. The Ourania (p. 180)
> and Eris (p. 183) examples use 1.05. Record: the printed equation says 1.05.

### Step 7.4 — Compute the required incremental section maximum lift coefficient (p. 170)

```
Δc_lmax = ( ΔC_Lmax ) ( S / S_wf ) / ( K_Λ )                      (7.8)   [p. 170]
```

`S_wf` = flapped wing area, defined in Figure 7.2. `S` = wing reference area.
`K_Λ` = sweep factor for the flaps-down case:

```
K_Λ = ( 1 - 0.08 cos² Λ_c/4 ) cos^(3/4) Λ_c/4                     (7.9)   [p. 170]
```

Check values computed from Eq. (7.9): Λ_c/4 = 0 deg → K_Λ = 0.92; Λ_c/4 = 35 deg →
K_Λ = 0.82. Both agree with the printed example values.

For straight, tapered wings the ratio S_wf/S is:

```
S_wf/S = ( η_o - η_i ) { 2 - ( 1 - λ )( η_i + η_o ) } / ( 1 + λ ) (7.10)  [p. 170]
```

The span stations `η_i` (inboard) and `η_o` (outboard) are defined in Figure 7.2.
(`η = 2y/b`, non-dimensional semi-span station.)

### Step 7.5 — Relate Δc_l to flap type, flap angle and flap chord (pp. 171–175)

The incremental section lift coefficient Δc_l relates to Δc_lmax as shown in Figure 7.3.
In preliminary design it is conservative to use:

```
Δc_l = ( 1 / K ) Δc_lmax                                          (7.11)  [p. 171]
```

with K from Figure 7.4, where Figure 7.4 defines K = Δc_lmax / Δc_l.

> **Book inconsistency (worked examples disagree with each other):**
> - Ourania p. 181 and Eris p. 184 apply Eq. (7.11) as printed: Δc_l = Δc_lmax / K
>   (3.00 / 0.94 = 3.19; 4.00 / 0.94 = 4.25).
> - Selene p. 178 applies the inverse: Δc_lmax = K x Δc_l (0.93 x 0.82 = 0.76 and
>   0.93 x 2.26 = 2.10).
>   The Selene use is the one consistent with the Fig. 7.4 definition K = Δc_lmax/Δc_l.
>   Record both; do not silently pick one.

The magnitude of Δc_l due to flaps depends on:
1. the flap-to-chord ratio c_f/c of the flaps
2. the type of flaps used
3. the flap deflection angle used

Equations for four flap types:

**Plain flaps** (p. 171):
```
Δc_l = c_l_δf δ_f K'                                              (7.12)
```
`c_l_δf` from Figure 7.5, `K'` from Figure 7.6.

**Split flaps** (p. 171):
```
Δc_l = k_f ( Δc_l )_{c_f/c = 0.2}                                 (7.13)
```
`k_f` and `(Δc_l)_{c_f/c=0.2}` from Figure 7.7.

**Single slotted flaps** (p. 171):
```
Δc_l = c_l_αf α_δf δ_f                                            (7.14)
```
`α_δf` from Figure 7.8.

The flapped section lift curve slope (p. 175):
```
c_l_αf = c_l_α ( c' / c )                                         (7.15)
with:  c' / c = 1 + 2 ( z_fh / c ) tan( δ_f / 2 )                 (7.16)
```
Geometric definitions of `c'` and `z_fh` are given with Figure 7.8 (sketch at the top of
p. 174). The unflapped section lift curve slope `c_l_α` in Eqn. (7.14) may be found from
section data as in Ref. 20, or may be assumed to be 2π.

**Fowler flaps** (p. 175):
```
Δc_l = c_l_α α_δf δ_f                                             (7.17)
```
This applies to a fully aft translating Fowler flap.

> **Book note on Eq. (7.17):** the Eris example on p. 184 says "From Eqn. (7.17):
> c_l_αf = 2π x 1.3 = 8.17", i.e. it uses the Eq. (7.15) form with c'/c = 1.3, then
> computes Δc_l = 6.28 x 0.53 x (25/57.3). So the printed Eq. (7.17) uses c_l_α, but the
> example computes with 6.28 = 2π, not with 8.17. The Ourania example on p. 181 does the
> same. The 8.17 value is computed and then not used.

**Leading edge devices** (p. 175). Preferably use experimental data. If not available,
the following may be used in the early phase of preliminary design:

```
c_lmax (with l.e. flap) = c_lmax (no l.e. flap) ( c'' / c )       (7.18)  [p. 175]
```

`c''` is defined in Figure 7.9 for slats and for Krueger flaps.

References 20 and 23 contain a significant amount of maximum-lift data for a wide variety
of high lift devices.

With the methods of Step 7.5 it is possible to find the combination of items 1 through 4:
1. Flap angle δ_f
2. Flap chord ratio c_f/c
3. S_wf/S and thus flap span ratio b_f/b
4. Flap type (trailing and leading edge)

which satisfies the flaps-down lift coefficient requirements listed in Step 7.1.

### Step 7.6 — Draw the flap geometry (p. 176)

Draw the required flap geometries in the wing planform drawing of Step 6, Ch. 6. Make
sure the flaps are compatible with:
1. required lateral controls (Step 6.7, Chapter 6)
2. fuselage width at the inboard flap station
3. engine nacelles placed on the wing: hot exhaust gasses should not impinge on the flaps
   unless the flaps are made of steel or titanium

### Step 7.7 — Document (p. 176)

Document the decisions of Steps 7.1 to 7.6 in a brief, descriptive report with clear
dimensioned drawings.

### Step 7.8 — Return to Step 6.9 in Chapter 6 (p. 176)

---

## Figures of §7.1

### Figure 7.1 — Effect of Thickness Ratio and Reynolds Number on Section Maximum Lift Coefficient
*[Roskam Part II, Fig. 7.1, p. 169]*

Two hand-drawn plots, `c_lmax` (vertical) against `t/c` in percent (horizontal, 6 to 22).
Curve families are labelled by `R_N x 10^-6` = 3, 6 and 9. Line style: solid = NACA
4- and 5-digit series; dashed = NACA 6-digit series. The upper plot adds two curves for
the NASA MS(1) airfoil (R_N = 6 and 9), which sit far above all the NACA curves.

Upper plot: **CAMBERED AIRFOILS** (c_lmax axis 1.2 to 2.0).
Lower plot: **SYMMETRICAL AIRFOILS** (c_lmax axis 0.8 to 1.6).

Digitized anchor points **(read from plot; hand-drawn chart, accuracy about ±0.04)**:

**Cambered airfoils**

| Feature | Value |
|---|---|
| Peak of the 4&5-digit family | near t/c ≈ 12–13 % |
| MS(1), R_N = 9e6, peak | ≈ 1.97 |
| MS(1), R_N = 6e6, peak | ≈ 1.93 |
| 4&5-digit R_N = 9e6, peak | ≈ 1.80 |
| c_lmax at t/c = 6 % (all NACA curves bunched) | ≈ 1.10–1.15 |
| c_lmax at t/c = 22 %, R_N = 9e6 | ≈ 1.54 |
| c_lmax at t/c = 22 %, R_N = 6e6 | ≈ 1.44 |
| c_lmax at t/c = 22 %, R_N = 3e6 | ≈ 1.32 |

**Symmetrical airfoils**

| Feature | Value |
|---|---|
| 4&5-digit curves are drawn only to t/c ≈ 13 % | — |
| 4&5-digit end value, R_N = 9e6 | ≈ 1.62 |
| 4&5-digit end value, R_N = 6e6 | ≈ 1.56 |
| 4&5-digit end value, R_N = 3e6 | ≈ 1.52 |
| 6-digit family peak | near t/c ≈ 14–17 % |
| 6-digit at t/c = 22 %, R_N = 9e6 | ≈ 1.40 |
| 6-digit at t/c = 22 %, R_N = 6e6 | ≈ 1.33 |
| 6-digit at t/c = 22 %, R_N = 3e6 | ≈ 1.19 |
| c_lmax at t/c = 6 % (all curves bunched) | ≈ 0.85–0.95 |

The 4&5-digit and 6-digit families cross and overlap between t/c ≈ 10 and 16 %. In that
band the individual curves cannot be separated reliably at scan resolution. Do not read
single values from that band; use the trend.

**Anchor points that the book itself reads off Figure 7.1** (these are the most reliable
values, because Roskam printed them):

| Example | t/c | c_lmax read from Fig. 7.1 | Page |
|---|---|---|---|
| Ourania root (R_n = 26.9e6) | 0.13 | 1.9 | p. 180 |
| Ourania tip (R_n = 8.6e6) | 0.11 | 1.7 | p. 180 |
| Eris root (R_n = 15.3e6) | 0.10 | 1.65 | p. 183 |
| Eris tip (R_n = 7.7e6) | 0.08 | 1.55 | p. 183 |

Note that the Ourania and Eris root Reynolds numbers (26.9e6 and 15.3e6) are outside the
plotted R_N range of the figure (3e6 to 9e6). Roskam extrapolates without saying so.

### Figure 7.2 — Definition of Flapped Wing Area
*[Roskam Part II, Fig. 7.2, p. 169]* — Planform sketch of a tapered wing with the
centreline marked. Each half wing carries a hatched panel of area ½ S_wf between the
inboard span station η_i and the outboard span station η_o. The panel runs the full local
chord, not the flap chord. Sketch only, no plotted data. Key definitional point:
**S_wf is the full-chord wing area in front of and behind the flap span, both halves
combined, measured on the wing reference (full) planform.**

### Figure 7.3 — Relation Between Δc_l and Δc_lmax
*[Roskam Part II, Fig. 7.3, p. 172]* — Schematic c_l against α with a "FLAPS UP" and a
"FLAPS DOWN" lift curve. `Δc_l` is the vertical shift of the linear part of the curve at
constant α. `Δc_lmax` is the difference between the two peak values. Schematic, no
plotted data.

### Figure 7.4 — Effect of Flap Chord Ratio and Flap Type on K = Δc_lmax / Δc_l
*[Roskam Part II, Fig. 7.4, p. 172]* — Gridded plot, K (0 to 1.0) against c_f/c (0 to
1.0). Three curves: "FOWLER + DOUBLE SL. FL.", "SINGLE SL. FL.", "PLAIN + SPLIT FL."
All three start at K = 1.0 at c_f/c = 0 and fall to K = 0 at c_f/c = 1.0.

Digitized **(read from plot, ±0.03)**:

| c_f/c | Fowler + double slotted | Single slotted | Plain + split |
|---|---|---|---|
| 0.0 | 1.00 | 1.00 | 1.00 |
| 0.1 | 0.99 | 0.98 | 0.97 |
| 0.2 | 0.97 | 0.94 | 0.90 |
| 0.3 | 0.92 | 0.83 | 0.72 |
| 0.4 | 0.72 | 0.66 | 0.55 |
| 0.5 | 0.56 | 0.53 | 0.46 |
| 0.6 | 0.42 | 0.40 | 0.37 |
| 0.8 | 0.20 | 0.20 | 0.20 |
| 1.0 | 0.00 | 0.00 | 0.00 |

The three curves cross near c_f/c ≈ 0.65 and are effectively one curve above c_f/c ≈ 0.7.
The K values Roskam himself reads off this figure are **K = 0.93 at c_f/c = 0.25**
(single slotted, p. 178) and **K = 0.94 at c_f/c = 0.30** (Fowler, pp. 181 and 184).
Those two printed values sit above the curve set I digitized at those chord ratios;
prefer Roskam's printed values.

### Figure 7.5 — Effect of Thickness Ratio and Flap Chord Ratio on c_l_δf
*[Roskam Part II, Fig. 7.5, p. 172, "FROM REF. 24"]* — c_l_δf in rad^-1 (vertical, 2 to
6) against c_f/c (horizontal, 0 to 0.5). A family of curves for
t/c = 0, .02, .04, .06, .08, .10, .12, .15 (labelled at the right end, .15 highest).

Digitized **(read from plot, ±0.1 rad^-1)**:

| c_f/c | c_l_δf, t/c = 0 | c_l_δf, t/c = 0.15 |
|---|---|---|
| 0.05 | ≈ 1.8 | ≈ 1.8 |
| 0.10 | ≈ 2.6 | ≈ 2.7 |
| 0.15 | ≈ 3.1 | ≈ 3.2 |
| 0.20 | ≈ 3.7 | ≈ 3.9 |
| 0.30 | ≈ 4.5 | ≈ 4.8 |
| 0.40 | ≈ 5.0 | ≈ 5.5 |
| 0.50 | ≈ 5.2 | ≈ 5.9 |

The curves are bunched below c_f/c ≈ 0.2 and fan out above it. Intermediate t/c values
lie between the two columns in order.

### Figure 7.6 — Effect of Flap Chord Ratio and Flap Deflection on K'
*[Roskam Part II, Fig. 7.6, p. 173, "COPIED FROM REF. 24"]* — Gridded plot, K' (0 to
1.0) against flap deflection δ_f (0 to 80 deg). Seven curves labelled
c_f/c = .10, .15, .20, .25, .30, .40, .50 (.10 is the highest at large δ_f).
K' = 1.0 for δ_f up to about 10 deg for every curve. The curves are drawn to about
δ_f = 60–65 deg only.

Digitized **(read from plot, ±0.02)**:

| δ_f (deg) | c_f/c = .10 | .15 | .20 | .25 | .30 | .40 | .50 |
|---|---|---|---|---|---|---|---|
| 0–10 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| 20 | 0.94 | 0.93 | 0.92 | 0.91 | 0.90 | 0.89 | 0.88 |
| 30 | 0.75 | 0.74 | 0.73 | 0.72 | 0.71 | 0.70 | 0.68 |
| 40 | 0.68 | 0.66 | 0.65 | 0.64 | 0.63 | 0.62 | 0.61 |
| 50 | 0.63 | 0.61 | 0.59 | 0.57 | 0.56 | 0.54 | 0.54 |
| 60 | 0.58 | 0.55 | 0.53 | 0.50 | 0.48 | 0.45 | 0.42 |

The bundle is very tight between δ_f = 15 and 25 deg (all seven curves fall steeply and
overlap), so the 20 deg row is the least accurate.

### Figure 7.7 — Empirical Constants for Split Flap Analysis
*[Roskam Part II, Fig. 7.7, p. 173, "COPIED FROM REF. 24"]* — Two gridded plots plus an
airfoil sketch defining c, c_f and δ_f.

**Plot (a):** `(Δc_l)_{c_f/c = 0.2}` (vertical, 0 to 1.8) against δ_f (horizontal, 0 to
60 deg). A family of curves labelled by t/c = .10, .12, .14, .16, .18, .20, .22 at their
right ends (δ_f = 60 deg). Also drawn: an "UPPER LIMIT" envelope near the top curves, and
a straight "FLAT PLATE (THEORETICAL)" line from the origin.

Digitized end values at δ_f = 60 deg **(read from plot, ±0.03)**:

| t/c | (Δc_l)_{c_f/c=0.2} at δ_f = 60 deg |
|---|---|
| 0.10 | ≈ 1.09 |
| 0.12 | ≈ 1.19 |
| 0.14 | ≈ 1.29 |
| 0.16 | ≈ 1.40 |
| 0.18 | ≈ 1.49 |
| 0.20 | ≈ 1.60 |
| 0.22 | ≈ 1.69 |

All curves pass through the origin. They are bunched below δ_f ≈ 10 deg and fan out
above. The FLAT PLATE (THEORETICAL) line reaches ≈ 0.60 at δ_f = 60 deg, i.e. a slope of
about 0.010 per degree, and it lies below every t/c curve.

**Plot (b):** `k_f` (vertical, 0.6 to 1.4) against c_f/c (horizontal, 0.1 to 0.4). One
curve, monotonic increasing, slightly concave down.

Digitized **(read from plot, ±0.02)**:

| c_f/c | k_f |
|---|---|
| 0.10 | ≈ 0.75 |
| 0.15 | ≈ 0.86 |
| 0.20 | ≈ 0.95 |
| 0.25 | ≈ 1.03 |
| 0.30 | ≈ 1.11 |
| 0.35 | ≈ 1.23 |
| 0.40 | ≈ 1.35 |

### Figure 7.8 — Section Lift Effectiveness Parameter for Single Slotted Flaps
*[Roskam Part II, Fig. 7.8, p. 174, "COPIED FROM REF. 24"]* — `α_δf` (vertical, 0 to
0.6) against flap deflection δ_f (horizontal, 0 to 80 deg). Five curves labelled
c_f/c = .40, .30, .25, .20, .15 (.40 is highest everywhere). Above the plot is the
geometric sketch that defines `c`, `c'`, `c_f`, `δ_f` and `z_fh` for the single slotted
flap. The book's own axis caption prints "FLAP DELECTION" (a typographical error for
DEFLECTION).

All five curves are flat to about δ_f = 15 deg, fall steeply between 35 and 55 deg, then
flatten again above 60 deg.

Digitized **(read from plot, ±0.015)**:

| δ_f (deg) | c_f/c = .40 | .30 | .25 | .20 | .15 |
|---|---|---|---|---|---|
| 0 | 0.60 | 0.56 | 0.52 | 0.44 | 0.36 |
| 10 | 0.60 | 0.55 | 0.52 | 0.44 | 0.36 |
| 20 | 0.59 | 0.54 | 0.51 | 0.43 | 0.35 |
| 30 | 0.56 | 0.51 | 0.48 | 0.41 | 0.34 |
| 40 | 0.51 | 0.47 | 0.43 | 0.37 | 0.30 |
| 50 | 0.40 | 0.36 | 0.33 | 0.28 | 0.22 |
| 60 | 0.29 | 0.26 | 0.23 | 0.20 | 0.16 |
| 70 | 0.25 | 0.22 | 0.20 | 0.17 | 0.14 |
| 80 | 0.24 | 0.21 | 0.19 | 0.17 | 0.14 |

The values Roskam himself reads off this figure are: **α_δf = 0.5 at c_f/c = 0.25,
δ_f = 15 deg** (p. 178); **α_δf = 0.43 at c_f/c = 0.25, δ_f = 48 deg** (p. 178);
**α_δf = 0.53 at c_f/c = 0.30, δ_f = 35 deg** (p. 181) and **at δ_f = 25 deg** (p. 184).
Those printed values agree with the digitization within about 0.02 except at
δ_f = 48 deg, where the digitized c_f/c = .25 curve gives ≈ 0.35 against Roskam's 0.43.

### Figure 7.9 — Definition of Section Chords With Deployed Leading Edge Devices
*[Roskam Part II, Fig. 7.9, p. 174]* — Two airfoil sketches. Top: a Krueger flap
extended forward and down from the lower surface leading edge. Bottom: a slat extended
forward. Both mark the clean chord `c` and the extended chord `c''` (measured from the
forward tip of the deployed device to the trailing edge). Sketches only, no plotted data.

---

## §7.2 Example Applications (pp. 176–186)

Three examples: 7.2.1 twin engine propeller driven airplane "Selene"; 7.2.2 jet transport
"Ourania"; 7.2.3 fighter "Eris".

### §7.2.1 Twin Engine Propeller Driven Airplane: Selene (pp. 176–179)

**Step 7.1** (from Part I, p. 178):

| Quantity | Value |
|---|---|
| C_Lmax | 1.7 |
| C_LmaxTO | 1.85 |
| C_LmaxL | 2.3 |

**Step 7.2** wing planform (Chapter 6, §6.2.1):

| Quantity | Value |
|---|---|
| A | 8 |
| S | 172 ft² |
| b | 37.1 ft |
| Λ_c/4 | 0 deg |
| λ | 0.4 |
| c_r | 6.62 ft |
| c_t | 2.65 ft |

The Selene is a moderately short-coupled airplane (Fig. 4.2b), so Eqn. (7.1) gives
C_Lmax_w = 1.06 x 1.7 = 1.80. With no sweep, Eqn. (7.3) gives
(c_lmax_r + c_lmax_t) = 2 x 1.80 / 0.95 = 3.79.

Section maximum lift coefficients of the order of 2.0 are therefore required. Figure 7.1
shows that NACA airfoils cannot deliver them. Data in Ref. 22 on the NASA MS(1)-0317/0313
airfoils suggest that those airfoils can. Reynolds numbers:

```
R_n_r = (0.002378 x 151 x 6.62) / 3.737e-7 = 6.4e6
R_n_t = 0.4 x 6.4e6 = 2.5e6
```

From Figure 6 of Ref. 22: c_lmax_r + c_lmax_t = 2.0 + 1.7 = 3.7, close enough to the
required 3.79. So the wing gives the required clean C_Lmax if NASA MS(1)-0317/0313 are
used.

**Step 7.3** (uses 1.07, not the printed 1.05):

```
ΔC_LmaxTO = 1.07 ( 1.85 - 1.7 ) = 0.16
ΔC_LmaxL  = 1.07 ( 2.3  - 1.7 ) = 0.64
```

The required flap lift increments are not high, so a relatively small single slotted flap
is probably sufficient.

**Step 7.4** — K_Λ from Eqn. (7.9) is 0.92 (Λ_c/4 = 0). Trial values S_wf/S = 0.3 and 0.6:

| | Landing flaps | | Take-off flaps | |
|---|---|---|---|---|
| S_wf/S | 0.3 | 0.6 | 0.3 | 0.6 |
| Δc_lmax | 2.32 | 1.16 | 0.58 | 0.29 |

**Step 7.5** — 'educated' guesses for the flap geometry:

| Quantity | Value |
|---|---|
| z_fh / c | 0.1 |
| c_f / c | 0.25 |
| δ_f TO | 15 deg |
| δ_f L | 48 deg |

*Take-off:*
```
Eqn. (7.16): c'/c = 1.03
Eqn. (7.15): c_l_αf = 1.03 x 2 x 3.14 = 6.45
Eqn. (7.14) with Fig. 7.8:  Δc_l = 6.28 x (15/57.3) x 0.5 = 0.82
Fig. 7.4: K = 0.93
Eqn. (7.11): Δc_lmax = (0.93) x 0.82 = 0.76
```
This is much more than needed at the assumed S_wf/S values, so the take-off flaps are not
critical.

*Landing:*
```
Eqn. (7.16): c'/c = 1.06
Eqn. (7.15): c_l_αf = 1.06 x 2 x 3.14 = 6.66
Eqn. (7.14) with Fig. 7.8:  Δc_l = 6.28 x (48/57.3) x 0.43 = 2.26
Eqn. (7.11): Δc_lmax = (0.93) x 2.26 = 2.10
From Eqn. (7.8): S_wf/S = 0.33
```

> Note that both take-off and landing use 6.28 (= 2π) in the Δc_l product, not the 6.45 /
> 6.66 values that Eqn. (7.15) just produced. The c_l_αf values are computed and then not
> used. Record the printed arithmetic.

**Step 7.6** — flap geometry summary:

| Quantity | Value |
|---|---|
| S_wf/S | 0.33 |
| c_f/c | 0.25 |
| Flap type | single slotted, hinge at z_fh/c = 0.10 |
| Take-off δ_f | 10 deg (arbitrary choice at this point) |
| Landing δ_f | 48 deg |
| η_i | 4.5 / 37.1 = 0.12 (fuselage side; body width 4.5 ft) |
| η_o | 0.76 (from Eqn. 7.10) |

> Note: Step 7.5 used δ_f TO = 15 deg; Step 7.6 lists take-off δ_f = 10 deg and calls it
> arbitrary. The two do not agree. Record both.

Flap/spar geometry has no effect on the landing gear, because the gear retracts into the
fuselage (§3.6.1). The flaps are compatible with the lateral control size requirement of
§6.2.1. Step 7.7 is omitted in the book to save space.

### §7.2.2 Jet Transport: Ourania (pp. 179–182)

**Step 7.1** (from Part I, p. 184):

| Quantity | Value |
|---|---|
| C_Lmax | 1.4 * |
| C_LmaxTO | 2.8 |
| C_LmaxL | 3.2 |

\* This value was assumed for climb sizing calculations only. It is not essential that it
be met.

**Step 7.2** wing planform (§6.2.2):

| Quantity | Value |
|---|---|
| A | 10 |
| S | 1,296 ft² |
| b | 113.8 ft |
| Λ_c/4 | 35 deg |
| λ | 0.32 |
| c_r | 17.4 ft |
| c_t | 5.60 ft |

```
R_n_r = (0.002378 x 243 x 17.4) / 3.737e-7 = 26.9e6
R_n_t = 0.32 x 26.9e6 = 8.6e6
```
The speed of 243 fps was computed for the take-off weight and by assuming the clean
maximum lift coefficient to be 1.4.

From Figure 7.1: root t/c = 0.13 gives c_lmax = 1.9; tip t/c = 0.11 gives 1.7.
```
Eqn. (7.3): C_Lmax_w = 0.95 ( 1.9 + 1.7 ) / 2 = 1.71
Eqn. (7.2): C_Lmax_w = 1.71 cos 35 = 1.4
Eqn. (7.1): C_Lmax = 1.4 / 1.06 = 1.32
```
1.32 is judged close enough to the assumed 1.4. The 1.4 is used in the flap sizing.

**Step 7.3:**
```
ΔC_LmaxTO = 1.05 ( 2.8 - 1.4 ) = 1.47
ΔC_LmaxL  = 1.05 ( 3.2 - 1.4 ) = 1.89
```
The required increments are high, so Fowler flaps will be needed. This matches the flap
type used on existing Boeing transports.

**Step 7.4** — K_Λ from Eqn. (7.9) is 0.82 (Λ_c/4 = 35 deg). Trial S_wf/S = 0.6 and 0.8:

| | Take-off flaps | | Landing flaps | |
|---|---|---|---|---|
| S_wf/S | 0.6 | 0.8 | 0.6 | 0.8 |
| Δc_lmax | 3.00 | 2.24 | 3.84 | 2.88 |

**Step 7.5** — flap geometry guesses: c_f/c = 0.30, δ_f TO = 35 deg, δ_f L = 40 deg.
Values of Δc_l from Eqn. (7.11) with Figure 7.4 (K = 0.94):

| | Take-off flaps | | Landing flaps | |
|---|---|---|---|---|
| S_wf/S | 0.6 | 0.8 | 0.6 | 0.8 |
| Δc_l | 3.19 | 2.38 | 4.09 | 3.06 |

*Take-off:*
```
Eqn. (7.15): c_l_αf = 2π x 1.3 = 8.17
Eqn. (7.14) with Fig. 7.8:  Δc_l = 6.28 x 0.53 x (35/57.3) = 2.03
```
Leading edge devices will be needed to produce the required increments, or the flap span
must be carried all the way to the tip. Assuming the flaps run from the fuselage side
(η_i = 0.11) to the tip (η_o = 1.0), Eqn. (7.10) gives S_wf/S = 0.84.

The interruption of the flap span by the high speed aileron is ignored. That interruption
causes some loss in flap lift, but not as much as a linear analysis predicts. For
preliminary design, full span Fowler flaps with c_f/c = 0.30 are assumed. Instead of
outboard ailerons there will have to be outboard spoilers.

**Step 7.6** — flap geometry summary:

| Quantity | Value |
|---|---|
| S_wf/S | 0.84 |
| c_f/c | 0.30 |
| Flap type | Fowler |
| Take-off δ_f | 35 deg (arbitrary choice at this point) |
| Landing δ_f | 40 deg |
| Body width | 13.2 ft (§4.2.2) |

Flap/spar geometry has no effect on the landing gear (gear retracts into the fuselage,
§3.6.2). Step 7.7 omitted.

### §7.2.3 Fighter: Eris (pp. 182–186)

**Step 7.1** (from Part I, p. 184): C_Lmax and C_LmaxL are not critical; C_LmaxTO = 2.8.

**Step 7.2** wing planform (§6.2.3):

| Quantity | Value |
|---|---|
| A | 6 |
| S | 787 ft² |
| b | 68.7 ft |
| Λ_c/4 | 0 deg |
| λ_w | 0.50 |
| c_r | 15.3 ft |
| c_t | 7.6 ft |

```
R_n_r = (0.002378 x 157 x 15.3) / 3.737e-7 = 15.3e6
R_n_t = 0.50 x 15.3e6 = 7.7e6
```
The speed of 157 fps was computed for the take-off weight and by assuming the clean
maximum lift coefficient to be 2.8.

> **Suspected misprint (p. 183):** the text says the 157 fps came from assuming the clean
> maximum lift coefficient to be **2.8**, but 2.8 is C_LmaxTO, and eight lines later the
> same page says the result is "close enough to the assumed value of **1.4**", where 1.4
> was never stated for this example. Record both printed values.

From Figure 7.1: root t/c = 0.10 gives c_lmax = 1.65; tip t/c = 0.08 gives 1.55.
```
Eqn. (7.3): C_Lmax_w = 0.95 ( 1.65 + 1.55 ) / 2 = 1.52
Eqn. (7.2): C_Lmax_w = 1.52 cos 0 = 1.52
Eqn. (7.1): C_Lmax = 1.52 / 1.10 = 1.38     (Eris is short coupled, Fig. 4.7)
```
1.38 is judged close enough to the assumed value of 1.4, and 1.4 is used in the flap
sizing.

> Note: Eqn. (7.3) with λ = 0.50 uses k_λ = 0.95, which the book lists for λ = 0.4.

**Step 7.3:**
```
ΔC_LmaxTO = 1.05 ( 2.8 - 1.4 ) = 1.47
```

**Step 7.4** — K_Λ from Eqn. (7.9) is 0.92 (Λ_c/4 = 0). Trial S_wf/S = 0.4, 0.8 and 1.0:

| | Take-off flaps | | |
|---|---|---|---|
| S_wf/S | 0.4 | 0.8 | 1.0 |
| Δc_lmax | 4.00 | 2.00 | 1.60 |

**Step 7.5** — flap geometry guesses: c_f/c = 0.30, δ_f TO = 25 deg.
Values of Δc_l from Eqn. (7.11) with Figure 7.4 (K = 0.94):

| | Take-off flaps | | |
|---|---|---|---|
| S_wf/S | 0.4 | 0.8 | 1.0 |
| Δc_l | 4.25 | 2.12 | 1.70 |

```
Eqn. (7.17): c_l_αf = 2π x 1.3 = 8.17
Eqn. (7.14) with Fig. 7.8:  Δc_l = 6.28 x 0.53 x (25/57.3) = 1.45
```
A full span Fowler flap is required. That in turn makes it necessary to use spoilers for
lateral control. Since a fighter is operated without an autopilot, an aileron surface is
not really needed.

**Step 7.6** — flap geometry summary:

| Quantity | Value |
|---|---|
| S_wf/S | 1.0 |
| c_f/c | 0.30 |
| Flap type | Fowler |
| Take-off δ_f | 25 deg |
| Landing δ_f | 40 deg (arbitrary choice at this point) |
| Body width | 8 ft (§4.2.3) |

Flap/spar geometry has no effect on the landing gear (gear retracts into the fuselage,
§3.6.2). Step 7.7 omitted.

### Reference three-views printed in §7.2

*[p. 185]* **McDonnell Douglas F15C** — top, front and side views. Dimensions marked:
span 42.81 ft, length 63.75 ft, height 18.45 ft, horizontal tail span 28.25 ft.
Drawing only, no plotted data. It is printed as a reference fighter next to the Eris
example; the book gives it no figure number.

*[p. 186]* **McDonnell Douglas F/A 18** — top, side and front views. Dimensions marked:
length 56.0 ft, span 37.5 ft (40.4 ft over the wingtip missiles, 27.5 ft to an inner
station), height 15.3 ft, wheel track 10.2 ft, wheel base 17.8 ft, nose gear to nose
10.5 ft, horizontal tail span 21.6 ft. Drawing only, no plotted data. No figure number.

---

## Symbol list (as used in this chapter)

| Symbol | Meaning | Units |
|---|---|---|
| A | wing aspect ratio | — |
| b | wing span | ft |
| b_f | flap span | ft |
| c | airfoil chord (clean) | ft |
| c' | extended chord with a trailing edge flap deployed | ft |
| c'' | extended chord with a leading edge device deployed | ft |
| c_f | flap chord | ft |
| c_r, c_t | wing root chord, wing tip chord | ft |
| c̄ | wing mean geometric chord | ft |
| c_l | airfoil section lift coefficient | — |
| c_lmax | airfoil section maximum lift coefficient | — |
| c_lmax_r, c_lmax_t | section maximum lift coefficient, root and tip | — |
| c_l_α | unflapped section lift curve slope | rad^-1 |
| c_l_αf | flapped section lift curve slope | rad^-1 |
| c_l_δf | section lift coefficient per flap deflection | rad^-1 |
| C_Lmax | clean airplane maximum lift coefficient (trimmed) | — |
| C_Lmax_w | wing maximum lift coefficient | — |
| C_LmaxTO, C_LmaxL | airplane maximum lift coefficient, take-off and landing | — |
| K | Δc_lmax / Δc_l, Figure 7.4 | — |
| K' | plain flap deflection factor, Figure 7.6 | — |
| K_Λ | flaps-down sweep factor, Eqn. (7.9) | — |
| k_f | split flap constant, Figure 7.7 | — |
| k_λ | taper ratio factor in Eqn. (7.3) | — |
| l_h | horizontal tail arm | ft |
| R_n, R_N | Reynolds number | — |
| S | wing reference area | ft² |
| S_wf | flapped wing area, Figure 7.2 | ft² |
| t/c | airfoil thickness ratio | — or % |
| V | speed | ft/s |
| z_fh | flap hinge vertical offset below the chord line | ft |
| α | angle of attack | deg |
| α_δf | section lift effectiveness parameter, Figure 7.8 | — |
| δ_f | flap deflection angle | deg |
| η_i, η_o | inboard and outboard flap span station, 2y/b | — |
| λ | wing taper ratio | — |
| Λ_c/4 | quarter chord sweep angle | deg |
| μ | dynamic viscosity | lb-s/ft² |
| ρ | air density | slug/ft³ |
