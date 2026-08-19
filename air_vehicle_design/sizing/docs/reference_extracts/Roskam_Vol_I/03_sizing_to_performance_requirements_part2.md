# Chapter 3 (cont'd) — Sizing to Performance Requirements, and Chapter 4 — A User's Guide to Preliminary Airplane Sizing

**Source:** Jan Roskam, *Airplane Design, Part I: Preliminary Sizing of Airplanes* (Roskam Aviation
and Engineering Corp.), §3.5–§3.8 and Chapter 4, printed pp. 160–195.

This file covers the second half of Chapter 3 (maneuvering sizing, cruise-speed sizing, and the
matching of all sizing requirements for three worked example airplanes) plus Chapter 4, the
step-by-step user's guide that ties the whole Part I method together.

---

## §3.5 Sizing to Maneuvering Requirements

Mission specifications for utility, agricultural, aerobatic, and military airplanes often set a
sustained-maneuvering requirement. The requirement is usually a sustained load factor (`n`, in g)
at a stated speed and altitude, sometimes stated instead as a turn rate.

Sustained maneuver capability depends strongly on maximum lift coefficient and on installed thrust.
For force balance perpendicular to the flight path:

```
nW = C_L·q·S = 1.4825·M²·δ·C_L·S
```
**[Roskam, Eq. (3.42), p. 160]**

where `n` is load factor, `W` is weight, `q` is dynamic pressure, `M` is Mach number, and `δ` is the
pressure ratio at the flight altitude. The maximum sustainable load factor follows:

```
n_max = (1.4825·C_Lmax·δ·M²) / (W/S)
```
**[Roskam, Eq. (3.43), p. 160]**

This load factor can be sustained only as long as thrust is sufficient. Required thrust is the sum
of the parasite-drag term and the induced-drag term at load factor `n`:

```
T = C_D0·q·S + (C_L²/(π·A·e))·q·S
```
**[Roskam, Eq. (3.44), p. 160]**

Dividing by weight and rearranging in terms of `n_max`:

```
(T/W) = q·C_D0/(W/S) + (n_max²/(q·π·A·e))·(W/S)
```
**[Roskam, Eq. (3.45), p. 160]**

Given a target `n_max` at a stated Mach number and altitude, and a `C_D0` estimate from the drag-polar
method of §3.4.1, Eq. (3.45) gives the relation between `T/W` and `W/S` needed to meet the maneuver
requirement.

If the requirement is stated instead as a turn rate, `ψ̇` (rad/s), the two are linked by:

```
ψ̇ = (g/V)·(n² − 1)^(1/2)
```
**[Roskam, Eq. (3.46), p. 160–161]** — derived in Ref. 14, p. 493.

If a turn rate is specified at a given speed, the load factor needed to fly it is:

```
n_reqd = [(ψ̇·V/g)² + 1]^(1/2)
```
**[Roskam, Eq. (3.47), p. 161]**

Eq. (3.45) then converts that `n_reqd` into the matching `T/W` vs `W/S` relation.

### §3.5.1 Example of Sizing to a Maneuvering Requirement

The fighter from Table 2.19's mission specification must also sustain a 3.5g turn at sea level,
450 kt, clean weight 54,500 lb. At `M = 450/661.2 = 0.68`, sea level, the clean `C_D0` is taken as
0.0096. With `A = 4` and `e = 0.8`, Eq. (3.45) becomes:

```
(T/W)_reqd = 6.6/(W/S) + 0.00178·(W/S)
```

Roskam tabulates the two `(T/W)` terms and their sum at several wing loadings, then scales the
sea-level `M = 0.68` result up to static (`M = 0:` ×1.6, a typical installed-thrust lapse ratio for
this engine class) **[Roskam, p. 161]**:

| (W/S) actual (psf) | (W/S) max (psf) | 1st term | 2nd term | (T/W) clean, M=0.68 | (T/W) max clean (×1.18 scaling shown in table) | (T/W) static (×1.6 from M=0.68) |
|---|---|---|---|---|---|---|
| 40 | 47 | 0.165 | 0.071 | 0.236 | 0.200 | 0.320 |
| 60 | 71 | 0.110 | 0.107 | 0.217 | 0.184 | 0.294 |
| 80 | 95 | 0.083 | 0.142 | 0.225 | 0.191 | 0.305 |
| 100 | 118 | 0.066 | 0.178 | 0.244 | 0.207 | 0.331 |

**[Roskam, p. 161]** — the "×1.18" and "×1.6" column factors are the printed scale notes translating
the clean actual-weight result to a max-weight result and to the static thrust rating, respectively.

### Figure 3.27 — Maneuvering-requirement region

*[Roskam, Fig. 3.27, p. 161]* — a `T/W` vs `W/S` plot with hatched boundary curves marking the
region of `(W/S)_TO` and `(T/W)_TO` combinations for which the maneuvering requirement is met; the
figure is referenced again in §3.7.4.3 as "requirements 1) and 2)." No further reading needed here
beyond the tabulated values above, which define the plotted curve.

---

## §3.6 Sizing to Cruise Speed Requirements

### §3.6.1 Cruise Speed Sizing for Propeller-Driven Airplanes

Power required to fly level at a given speed and altitude:

```
P_reqd = T·V = C_D·q·S·V
```
**[Roskam, Eq. (3.48), p. 162]**

Restated using shaft horsepower and propeller efficiency `η_p`:

```
550·η_p·HP = 0.5·ρ·V³·S·C_D
```
**[Roskam, Eq. (3.49), p. 162]**

Propeller cruise speed is usually flown at 75-80% power, where induced drag is small next to profile
drag, so Roskam assumes:

```
C_Di = 0.1·C_D0
```
**[Roskam, Eq. (3.50), p. 162]**

Loftin (Ref. 11) showed that under this assumption cruise speed is proportional to:

```
V_cr ∝ [((W/S)/(W/P))·(η_p/(σ·C_D0))]^(1/3)
```
**[Roskam, Eq. (3.51), p. 162]**

Loftin then defines a single correlating parameter, the **power index** `I_p`:

```
V_cr ∝ I_p,   where   I_p = [(W/S)/(σ·(W/P))]^(1/3)
```
**[Roskam, Eqs. (3.52)–(3.53), p. 162]**

Figures 3.28-3.30 plot `V_cr` against `I_p` for families of real airplanes; a desired cruise speed
gives a first-estimate `I_p`, and Eq. (3.53) converts that into the matching `(W/S)` vs `(W/P)`
relation. The same correlation can run backward, reconstructing `C_D0` from measured speed and power
data — covered next.

### Figure 3.28 — Speed vs power index, retractable-gear cantilever-wing airplanes
*[Roskam, Fig. 3.28, p. 163]* — Scatter plot, `V` (mph, 0-500) vs `I_p` (0-3.2), symbols for modern
general-aviation, WWII fighter, and other aircraft (solid = multiengine); a single correlating line
runs from the origin through the data, roughly `V ≈ 175·I_p` at the low end curving to `V ≈ 165·I_p`
at the high end. Empirical correlation (trend line only), not a constraint boundary with a design
point — not digitized point-by-point.

### Figure 3.29 — Speed vs power index, fixed-gear cantilever-wing airplanes
*[Roskam, Fig. 3.29, p. 163]* — Same axes as Fig. 3.28, general-aviation and "other" symbols only,
correlating line roughly `V ≈ 145·I_p` through most of the range, curving upward above `I_p ≈ 1.6`.
Empirical correlation only, not digitized point-by-point.

### Figure 3.30 — Speed vs power index, biplanes and strut-braced fixed-gear monoplanes
*[Roskam, Fig. 3.30, p. 164]* — Same axes, biplane and multi-strut-monoplane symbols (flagged =
retractable gear), correlating line roughly `V ≈ 115·I_p` in the tested range (`I_p` up to ~1.4)
extrapolated upward to ~500 mph at `I_p ≈ 3.0`. Empirical correlation only, not digitized
point-by-point.

### §3.6.2 A Method for Finding `C_D0` from Speed and Power Data

Loftin (Ref. 11, Eq. 6.3) derives:

```
V = 17.3·[η_p·(σ/(σ_std))/(C_D0·(W/P))]^(1/3)
```
**[Roskam, Eq. (3.54), p. 165]**

Rewritten with the power-index definition:

```
C_D0 = 71.3·(I_p/V)³/η_p
```
**[Roskam, Eq. (3.55), p. 165]**

Assuming a typical high-speed-cruise propeller efficiency `η_p = 0.85`, this simplifies to:

```
C_D0 = 1.114×10⁵·(I_p/V)³
```
**[Roskam, Eq. (3.56), p. 165]** — note `V` must be in mph in this form.

Given a real airplane's maximum power and speed at some altitude, Eq. (3.56) backs out an estimate
of `C_D0`. Table 3.9 (below) lists Loftin's results for a set of historical aircraft.

### Table 3.9 — Typical Values for Zero-Lift Drag Coefficient and Maximum Lift-to-Drag Ratio
*[Roskam, Table 3.9, p. 164]* — data copied from Ref. 11, Table 5.1.

| Airplane Type | C_D0 | A | e | (L/D)_max |
|---|---|---|---|---|
| Boeing 247D | 0.0212 | 6.55 | 0.75 | 13.5 |
| Douglas DC-3 | 0.0249 | 9.14 | 0.75 | 14.7 |
| Boeing B-17G | 0.0236 | 7.58 | 0.75 | 13.8 |
| Seversky P-35 | 0.0251 | 5.89 | 0.62 | 10.7 |
| Piper J-3 Cub | 0.0373 | 5.81 | 0.75 | 9.6 |
| Beechcraft D17S | 0.0348 | 6.84 | 0.76 | 10.8 |
| Consolidated B-24J | 0.0406 | 11.55 | 0.74 | 12.9 |
| Martin B-26F | 0.0314 | 7.66 | 0.75 | 12.0 |
| North American P-51D | 0.0161 | 5.86 | 0.69 | 14.0 |
| Lockheed L.1049G | 0.0211 | 9.17 | 0.75 | 16.0 |
| Piper Cherokee | 0.0358 | 6.02 | 0.76 | 10.0 |
| Cessna Skyhawk | 0.0319 | 7.32 | 0.75 | 11.6 |
| Beech Bonanza V-35 | 0.0192 | 6.20 | 0.75 | 13.8 |
| Cessna Cardinal RG | 0.0223 | 7.66 | 0.63 | 13.0 |

### §3.6.3 Example of Cruise Speed Sizing for a Propeller-Driven Airplane

The Table 2.17 airplane must cruise at 250 kt (= 288 mph) at 85% power, 10,000 ft, take-off weight.
Figure 3.28 gives `I_p = 1.7` for that speed. At 10,000 ft, `σ = 0.7386`. Eq. (3.53) then gives:

```
(W/S) = 3.63·(W/P)
```
**[Roskam, p. 165]**

Figure 3.31 shows the resulting allowable `(W/S)`-`(W/P)` band; the `(W/P)` value found is at
10,000 ft and must be scaled to sea level by the ratio of cruise power at altitude to sea-level
power — typically 0.7 for a non-supercharged reciprocating engine.

### Figure 3.31 — Allowable wing loading and power loading for a given cruise speed
*[Roskam, Fig. 3.31, p. 166]* — `W/P` (lb/hp, 0-50) vs `W/S` (psf, 0-100+). Two straight lines rise
from near the origin: a lower-slope line labeled REQUIREMENT (met above it, not met below — split
into "MET"/"NOT MET" halves by the hatch marks), and a steeper CRUISE-then-TAKE-OFF-labeled line
pair converging near `(W/S)≈110, W/P≈32)` (cruise) and `(W/S)≈110, W/P≈22)` (take-off). The
"requirement met" region is the wedge above the shallow line and, implicitly, bounded by whichever
of the cruise/take-off lines is lower at a given `W/S`. Read from plot: requirement line passes
roughly through `(10, 3)` and `(75, 38)`; cruise line through `(15, 5)` and `(110, 32)`; take-off
line through `(15, 3)` and `(110, 22)`.

### Figure 3.32 — Rapid method for estimating drag rise
*[Roskam, Fig. 3.32, p. 166]* — Zero-lift drag rise `ΔC_D0` (counts, 1 count = 0.0001) vs Mach
number (0.4-1.05) for four real aircraft: C-130H, C-5A, 727, F-106. Each curve is flat near zero
until a knee, then rises steeply — *(read from plot)*, approximate drag-rise onset Mach and the
Mach at 10-count rise:

| Aircraft | Drag-rise onset M (ΔC_D0 leaves 0) | M at ΔC_D0 ≈ 10 counts |
|---|---|---|
| C-130H | ≈0.55 | ≈0.68 |
| C-5A | ≈0.68 | ≈0.78 |
| 727 | ≈0.78 | ≈0.87 |
| F-106 | ≈0.88 | ≈0.97 |

This figure supplies the compressibility drag increment `ΔC_D0` referenced in §3.6.4 for jet cruise
speed sizing above `M ≈ 0.5`.

### §3.6.4 Cruise Speed Sizing for Jet Airplanes

At maximum level speed, thrust and lift balance simultaneously:

```
T_reqd = D,      W = C_L·q·S
```
**[Roskam, Eqs. (3.57)-(3.58), p. 167]**

With a parabolic drag polar, Eq. (3.57) expands to:

```
T_reqd = C_D0·q·S + C_L²·q·S/(π·A·e)
```
**[Roskam, Eq. (3.59), p. 167]**

Dividing by weight:

```
(T/W)_reqd = C_D0·q·S/W + W/(q·S·π·A·e)
```
**[Roskam, Eq. (3.60), p. 167]**

Given `q` from the specified Mach number and altitude, and `C_D0` from the drag-polar method, Eq.
(3.60) gives the `T/W` vs `W/S` relation meeting the speed requirement. Because maximum speed is
often specified below take-off weight, at `W = k·W_TO` (`0 < k < 1`), the take-off wing loading
implied is:

```
(W/S)_TO = k⁻¹·(W/S)_[from Eq. 3.60]
```
**[Roskam, Eq. (3.62), p. 167]**

and the corresponding take-off `T/W` must be reconstructed from installed-thrust lapse data (how
thrust varies with Mach and altitude). Above `M ≈ 0.5`, compressibility raises `C_D0` — Fig. 3.32
gives the increment `ΔC_D0` to add.

### §3.6.5 Example of Sizing to Maximum Speed for a Jet

Size an airplane, `W_TO = 10,000 lb`, for `M = 0.9` at sea level. From Fig. 3.22b (wetted-area vs
weight chart from earlier in Chapter 3), wetted area is estimated at `S_wet = 1,050 ft²`; assuming
`C_fe = 0.0030` (Fig. 3.21b) gives equivalent parasite area `f = 3.2 ft²`. At a typical wing loading
of 60 psf, `S = 167 ft²`, so `C_D0 = 0.0192`. The compressibility drag increment at M=0.9 is assumed
to be 0.0030. With `A = 5`, `e = 0.8`, Eq. (3.60) becomes:

```
T/W = 26.6/(W/S) + (W/S)/15,080
```

Roskam's tabulation **[Roskam, p. 168]**:

| (W/S)_TO (psf) | Profile-drag term | Induced-drag term | (T/W) at M=0.9 | (T/W)_TO static |
|---|---|---|---|---|
| 40 | 0.665 | 0.003 | 0.668 | 1.07 |
| 60 | 0.443 | 0.004 | 0.447 | 0.72 |
| 80 | 0.333 | 0.005 | 0.338 | 0.54 |
| 100 | 0.266 | 0.007 | 0.273 | 0.44 |

Higher wing loading clearly helps at high speed and sea level.

### Figure 3.33 — Allowable wing loading and thrust-to-weight ratio for a given max speed at sea level
*[Roskam, Fig. 3.33, p. 169]* — `(T/W)_TO` (0-1.2) vs `(W/S)_TO` (psf, 0-110+), condition callout
`M=0.9 at sea level, W=10,000 lb, C_D0=0.0192`. One hatched boundary curve, "requirement met" above
it (region toward high `T/W`/low `W/S`): *(read from plot)* passes approximately through
`(35, 1.15)`, `(50, 0.75)`, `(75, 0.45)`, `(100, 0.35)` — matching the tabulation above.

---

## §3.7 Matching of All Sizing Requirements and the Application to Three Example Airplanes

### §3.7.1 Matching of All Sizing Requirements

Having built separate relations for take-off `T/W` (or `W/P`), take-off `W/S`, required maximum lift
coefficients, and aspect ratio, the designer now finds the "best" combination — Roskam uses "best"
rather than "optimum" since no strict mathematical optimum is implied. The usual approach: overlay
every requirement on one `T/W` (or `W/P`) vs `W/S` chart, then pick the **lowest thrust-to-weight (or
power loading) and highest wing loading point still inside every requirement's allowed region**.
This is the **matching process**. Sub-sections 3.7.2-3.7.4 work it for three example airplanes.

### §3.7.2 Example 1: Twin-Engine Propeller-Driven Airplane

Mission specification: Table 2.17.

#### §3.7.2.1 Take-off distance sizing
Requirement: `s_TOFL = 1,500 ft`, FAR 23, sea level, standard day. From Eq. (3.4):

```
1,500 = 4.9·TOP_23 + 0.009·TOP_23²   →   TOP_23 = 218 hp/ft²
```

With `c_TO = 1.0`, Eq. (3.2) gives:

```
(W/S)_TO·(W/P)_TO = 218·C_Lmax,TO
```

Table 3.1 gives `C_Lmax,TO` in the 1.4-2.0 range for this class; Roskam tabulates 1.4, 1.7, and 2.0
**[Roskam, p. 170-171]**:

| (W/S)_TO (psf) | (W/P)_TO at C_Lmax=1.4 | at 1.7 | at 2.0 |
|---|---|---|---|
| 20 | 15.3 | 18.5 | 21.8 |
| 30 | 10.2 | 12.4 | 14.5 |
| 40 | 7.6 | 9.3 | 10.9 |
| 50 | 6.1 | 7.4 | 8.7 |
| 60 | 5.1 | 6.2 | 7.3 |

#### §3.7.2.2 Landing distance sizing
Requirement: `s_FL = 1,500 ft`, FAR 23, sea level, standard day. Eq. (3.12) gives
`V_SL² = 1,500/0.265 = 5,660 kt²`, so `V_SL = 75.2 kt = 127 fps`. Eq. (3.1) then gives
`(W/S)_L = 19.2·C_Lmax,L`. Table 2.17's landing-weight fraction `W_L = 0.95·W_TO` converts this to
take-off wing loading: `(W/S)_TO = 20.2·C_Lmax,L` **[Roskam, p. 171]**. Table 3.1 gives a typical
`C_Lmax,L` range of 1.6-2.5 for this airplane type; Roskam checks 1.7, 2.0, 2.3, giving allowable
`(W/S)_TO` ceilings of 34.3, 40.4, and 46.5 psf respectively **[Roskam, p. 172]**.

### Figure 3.34 — Matching results, twin-engine propeller-driven airplane
*[Roskam, Fig. 3.34, p. 172]* — `(W/P)_TO` (lb/hp, 0-30) vs `(W/S)_TO` (psf, 0-70). Plotted
boundaries: a vertical FAR 23.65 (AEO) line pair (`A=8`, `C_Lmax,TO=1.4`) stepping at low `W/S`; a
steep FAR 23.67 (OEI, flaps-up, `A=8`) hatched curve; three near-vertical landing-distance lines at
`C_Lmax,L = 1.7, 2.0, 2.3`; a family of three cruise-speed curves (labeled `C_Lmax,TO` values 1.4,
1.7, 2.0, all requiring high `W/P` at low `W/S` and converging near `W/S≈65, W/P≈12`); and three
time-to-climb lines fanning from upper-left (labeled 10, 8, and A[approx]). The match point **P**
sits near `(W/S)≈46, W/P≈8.8)`, at the intersection of the `C_Lmax,TO=1.7` landing line, the
cruise-speed curve, and just inside the climb/take-off boundaries.

#### §3.7.2.3 FAR 23 climb sizing
Per §3.4.4's earlier finding for this airplane class, FAR 23.65 (AEO) and FAR 23.67 (OEI) dominate;
only these two are checked here (Roskam explicitly warns not to assume this holds for every design —
check all climb requirements when in doubt).

**FAR 23.65 (AEO):** the climb-gradient term (Eq. 3.30) is more critical than climb rate (as shown in
§3.4.4). Using `W_TO = 7,900 lb` (from p. 53), Fig. 3.22a gives `S_wet ≈ 1,400 ft²`; Fig. 3.21a gives
`f ≈ 7 ft²`; at an average wing loading of 30 psf, `S = 263 ft²`, so `C_D0 = 0.0266` clean. Take-off
flaps add `ΔC_D0 = 0.0134`. Drag polars used:

```
Clean: C_D = 0.0266 + C_L²/(π·A·e), e = 0.8
Take-off, gear up: C_D = 0.0400 + C_L²/(π·A·e), e = 0.8
```
**[Roskam, p. 173-174]**

For `A = 8` and `A = 10`, and `C_Lmax,TO = 1.4, 1.7, 2.0` (with an assumed 0.2 stall margin giving
safe `C_L` values of 1.2, 1.5, 1.8), Roskam tabulates `(L/D)` and the climb-gradient coefficient
`(C_D/C_L^1.5)`, then `(W/P)_TO` at several `(W/S)_TO` **[Roskam, p. 174]** — higher aspect ratio and
higher `C_Lmax,TO` both reduce required power.

**FAR 23.67 (OEI):** flaps may be in the most favorable position — found to be flaps-up here, so
`C_Lmax = 1.7` (with 1.4 and 1.6 checked as compatible bracket values). Drag polars for flaps-up vs
take-off-flap, one engine feathered, are built by adding a windmilling-propeller increment
(`ΔC_D0 = 0.0034`) to the clean/take-off polars **[Roskam, p. 175]**. Stall speed `V_S1` at 5,000 ft
gives `V_S1 = 23.96·(W/S)^(1/2)`; the required rate-of-climb parameter `RCP` is tabulated vs `(W/S)`,
then converted to `(W/P)_TO` at sea level for `A = 8` and `A = 10` via Eq. (3.24) **[Roskam,
p. 175-176]**. The AEO requirement (23.65) is found to be the more critical of the two — Roskam
flags this as sensitive to the drag-polar accuracy and worth re-checking once a real three-view
exists.

#### §3.7.2.4 Cruise speed sizing
The 250-kt-at-10,000-ft requirement from §3.6.3 (Fig. 3.31) is superimposed directly onto Fig. 3.34;
it turns out to be a fairly critical (binding) requirement here.

#### §3.7.2.5 Time-to-climb sizing
Requirement: 10 min to 10,000 ft. Assuming `h_abs = 25,000 ft` (typical for a normally-aspirated
piston installation), Eq. (3.33) gives `RC_avg = 1,277 fpm`, clean; Eq. (3.23) gives
`RCP = 0.0387`. With `C_D0 = 0.0266`, Eq. (3.27) gives the climb-gradient coefficient `13.4` for
`A=8` and `15.8` for `A=10`. Eq. (3.24) then converts `RCP` into `(W/P)_TO` vs `(W/S)_TO` for both
aspect ratios **[Roskam, p. 177-178]**; these curves are also plotted on Fig. 3.34.

#### §3.7.2.6 Summary of matching results
Point **P** on Fig. 3.34 is the chosen match. Resulting design:

- Take-off weight: 7,900 lb; Empty weight: 4,900 lb; Fuel weight: 1,706 lb (already known, p. 53)
- `C_Lmax` clean = 1.7; `C_Lmax,TO` = 1.85; `C_Lmax,L` = 2.3
- Aspect ratio: `A = 8` is sufficient
- `(W/S)_TO` = 46 psf; wing area = 172 ft²
- `(W/P)_TO` = 8.8 lb/hp; take-off power = 898 hp

**[Roskam, p. 178]**

### §3.7.3 Example 2: Jet Transport

Mission specification: Table 2.18 (field length 5,000 ft at 5,000 ft altitude, 95°F day).

#### §3.7.3.1 Take-off distance sizing
Table 3.1 gives take-off `C_Lmax,TO` range 1.6-2.2 for this class; Roskam checks 1.6, 2.0, 2.4. At
5,000 ft, `δ = 0.8320`; at 95°F, `θ = (95+459.7)/518.7 = 1.0694`, so `σ = δ/θ = 0.7780`. Eq. (3.8)
gives:

```
5,000 = 37.5·(W/S)_TO/(0.7780·C_Lmax,TO·(T/W)_TO)
   →   (T/W)_TO = 0.009640·(W/S)_TO/C_Lmax,TO
```

Roskam tabulates `(T/W)_TO` at the hot-day 5,000-ft condition and scales it to a sea-level, standard-
day value by a factor of 1.17 (typical turbofan lapse for this aircraft class) **[Roskam, p. 179]**:

| (W/S)_TO (psf) | (T/W) at C_Lmax=1.6, 2.0, 2.4 — 5,000 ft hot | (T/W) at C_Lmax=1.6, 2.0, 2.4 — SL std |
|---|---|---|
| 60 | 0.36, 0.29, 0.24 | 0.42, 0.34, 0.28 |
| 80 | 0.48, 0.39, 0.32 | 0.56, 0.45, 0.37 |
| 100 | 0.60, 0.48, 0.40 | 0.70, 0.56, 0.47 |
| 120 | 0.72, 0.58, 0.48 | 0.84, 0.67, 0.56 |

#### §3.7.3.2 Landing distance sizing
Eqs. (3.15)-(3.16) give `V_SL² = 9,862 kt²`, so `V_SL = 99.3 kt`. Eq. (3.1) at the hot-and-high
condition gives `(W/S)_L = 26.0·C_Lmax,L`. Table 3.1's landing `C_Lmax` range for this class is
1.8-2.8; Roskam checks 1.8, 2.2, 2.6, 3.0, scaling `(W/S)_L` to `(W/S)_TO` by the Table 2.18 landing-
weight fraction `W_L = 0.85·W_TO` **[Roskam, p. 180]**:

| C_Lmax,L | (W/S)_L (psf) | (W/S)_TO (psf) |
|---|---|---|
| 1.8 | 46.8 | 55.1 |
| 2.2 | 57.2 | 67.3 |
| 2.6 | 67.6 | 79.5 |
| 3.0 | 78.0 | 91.8 |

#### §3.7.3.3 FAR 25 climb sizing
Following §3.4.8's finding for a similar transport, only FAR 25.121 (OEI) is checked. That earlier
example (`W_TO = 125,000 lb`) is close enough to this airplane (`W_TO = 127,000 lb`) that its Fig.
3.25 numerical result is reused directly as the FAR 25.121 (OEI) boundary on Fig. 3.35.

#### §3.7.3.4 Cruise speed sizing
Requirement: `M = 0.82` at 35,000 ft. Low-speed clean drag polar (from p. 145):
`C_D = 0.0184 + C_L²/(26.7)` for `A=10`, `e=0.85`. Fig. 3.32 gives a compressibility increment of
0.0005 at `M=0.82`. At 35,000 ft, `q = 1,482·0.2353·M² = 234 psf`. Eq. (3.60) gives:

```
(T/W)_reqd = 4.42/(W/S) + (W/S)/6,249
```

scaled from cruise to take-off thrust by a factor of 1/0.23 (the ratio of thrust at M=0.82/35,000 ft
to sea-level static for a typical turbofan of this class) **[Roskam, p. 182]**.

#### §3.7.3.5 Direct climb sizing
Requirement: direct climb to a 35,000-ft service ceiling at take-off weight, i.e. 500 fpm at
35,000 ft and `M = 0.82` (per Table 3.8's ceiling-rate convention). Using Eq. (3.34) with
`RC = 8.33 fps`, `V = 198 fps`, `S = 1,270 ft²`, `q = 234 psf`, `C_L = 0.43`, `C_D = 0.0257`,
`L/D = 16.7`:

```
(T/W)_reqd = 8.33/198 + 1/16.7 = 0.07  at 35,000 ft, M=0.82
```

Scaled to sea-level static by the same 1/0.23 lapse factor: `(T/W)_TO = 0.31` **[Roskam, p. 183]**.

#### §3.7.3.6 Summary of matching results

### Figure 3.35 — Matching results, jet transport
*[Roskam, Fig. 3.35, p. 181]* — `(T/W)_TO` (0-0.7) vs `(W/S)_TO` (psf, 40-110). Plotted boundaries:
a landing-distance line family (`C_Lmax,L` = 1.8, 2.2, 2.6, 3.0, near-vertical); a take-off-distance
line family (`C_Lmax,TO` = 1.6, 2.0, 2.4, rising diagonally to upper-right); a FAR 25.121 (OEI) line
(nearly flat, ≈0.3); and a direct-climb line (nearly flat, ≈0.3, close to but distinct from the OEI
line). Match point **P** sits at approximately `(W/S)≈98, T/W≈0.375)`. Roskam notes the short-field,
hot-day take-off requirement dominates `T/W`, driving the need for a low-drag, high-lift take-off
system; realistic trimmed `C_Lmax,TO` with mechanical flaps tops out near 2.4-2.8 (canard/three-
surface layouts can reach 2.8), with a matching landing `C_Lmax,L ≈ 3.2`.

Point P design summary **[Roskam, p. 183-184]**:
- Take-off weight: 127,000 lb; Empty weight: 68,450 lb; Fuel weight: 25,850 lb (already known, p. 59)
- `C_Lmax` clean = 1.4 (p. 145); `C_Lmax,TO` = 2.8; `C_Lmax,L` = 3.2
- Aspect ratio: 10 (Roskam suggests investigating a higher value for benefit)
- `(W/S)_TO` = 98 psf; wing area = 127,000/98 = 1,296 ft²
- `(T/W)_TO` = 0.375; take-off thrust = 47,625 lb

### §3.7.4 Example 3: Fighter

Mission specification: Table 2.19.

#### §3.7.4.1 Take-off distance sizing
Requirement: 2,000-ft groundrun, sea level, 95°F day, hard surface (`μ = 0.025`). Air density at
95°F: `ρ = 0.002224 slug/ft³`. Eq. (3.9):

```
                        0.0447 (W/S)_TO
2,000 = ------------------------------------------------------
        0.002224 [ C_Lmax,TO { k_2 (T/W)_TO - 0.025 } - 0.72 C_D0 ]
```

With an assumed bypass ratio `lambda = 3:1`, `k_2 = 0.75 x 8/7 = 0.857` (from p. 102); clean `C_D0`
(no stores) = `0.0096 + 0.0030 = 0.0126` (from pp. 154-155). The take-off distance requirement then
reduces to [Roskam, p. 185]:

```
C_Lmax,TO { 85.3 (T/W)_TO - 2.49 } - 0.905 = (W/S)_TO
```

Roskam tabulates this as follows [Roskam, p. 185]. A factor of 1.18 translates the hot-day (95°F)
thrust into standard-day thrust; this factor comes from typical turbofan data for this class of
airplane [Roskam, p. 186]:

| `(T/W)_TO` @ 95°F | `(W/S)_TO`, `C_Lmax,TO`=1.6 | 1.8 | 2.0 | `(T/W)_TO` std. day |
|---|---|---|---|---|
| 0.4 | 50 | 56 | 62 | 0.47 |
| 0.6 | 77 | 87 | 96 | 0.71 |
| 0.8 | 104 | 117 | 131 | 0.94 |
| 1.0 | 132 | 148 | 165 | 1.18 |

Figure 3.36 shows the graphical results.

#### §3.7.4.2 Landing distance sizing
Per §3.3.5.1's FAR 25 method with an approach-speed correction. Groundrun requirement 2,000 ft;
ratio of groundrun to total landing distance ≈1.9 without special retardation, so total distance
`s_FL = 3,800 ft`. Fig. 3.16 gives `s_FL ≈ 6,333 ft`(equivalent conversion); Fig. 3.17 gives
`V_A² = 21,200 kt²`. For a fighter, `V_A = 1.2·V_S` (not the FAR-25-transport 1.3), so
`V_A = 158 kt`, `V_S = 132 kt = 222 fps`. Eq. (3.1): `(W/S)_L = 54.8·C_Lmax,L`. Assuming
`W_L = 0.85·W_TO` (not stated in Table 2.19), Roskam tabulates **[Roskam, p. 186]**:

| C_Lmax,L | (W/S)_L (psf) | (W/S)_TO (psf) |
|---|---|---|
| 1.8 | 98.6 | 116 |
| 2.0 | 109.6 | 129 |
| 2.2 | 120.6 | 142 |

Figure 3.36 shows this requirement is not critical for wing-loading selection — a 2,000-ft groundrun
is a liberal allowance for this fighter class.

#### §3.7.4.3 Climb sizing
Per Table 2.19's climb specifications, already computed in §3.4.12 and shown as requirements 1) and
2) on Fig. 3.27; those two lines are simply repeated on Fig. 3.36. (Fig. 3.27's requirement 3) is
dropped here — it wasn't part of the Table 2.19 requirement list.)

#### §3.7.4.4 Cruise speed sizing
Table 2.19 specifies four speed points: 450 kt clean and 400 kt with external stores at sea level
(`M = 0.68`, `0.60`); `M = 0.85` clean and `M = 0.80` with stores at 40,000 ft. Sea-level drag polars
(from §3.4.12, assumed no compressibility at these Mach numbers):

```
Low speed, clean:      C_D = 0.0096 + 0.0995·C_L²
Low speed, with stores: C_D = 0.0126 + 0.0995·C_L²
```

Using Eq. (3.60), the 450-kt-clean case gives `(T/W)_reqd = 6.58/(W/S) + (W/S)/6,886`; the 400-kt-
with-stores case gives `(T/W)_reqd = 6.73/(W/S) + (W/S)/5,368` **[Roskam, p. 188-189]**. Both are
tabulated at `(W/S)_TO` = 40, 60, 80, 100 psf and scaled to static thrust (×1.65 for the clean case,
×1.54 for the stores case) and to a stores-carrying take-off weight (×0.85).

At 40,000 ft, the compressibility increment at `M=0.80` is 0.0020 (from p. 152) and at `M=0.85` is
assumed 0.0030 (store compressibility drag is neglected — slender stores show no drag rise until
`M≈0.9`). Drag polars used:

```
M=0.85, clean:        C_D = 0.0126 + 0.0995·C_L²
M=0.80, with stores:   C_D = 0.0146 + 0.0995·C_L²
```

Eq. (3.60) gives `(T/W)_reqd = 2.5/(W/S) + (W/S)/1,991` (M=0.85 clean) and
`(T/W)_reqd = 2.5/(W/S) + (W/S)/1,769` (M=0.80 with stores), each tabulated and scaled to static
thrust (×0.23 lapse factor, typical for this engine class) and stores weight (×0.85) **[Roskam,
p. 189-190]**.

#### §3.7.4.5 Summary of matching results

### Figure 3.36 — Matching results, fighter
*[Roskam, Fig. 3.36, p. 187]* — `(T/W)_TO` (0-1.2) vs `(W/S)_TO` (psf, 0-100+). Plotted boundaries:
a take-off-distance line family (`C_Lmax,TO` = 1.6, 1.8, 2.0, steep diagonal rise to upper-right); a
40,000-ft `M=0.8`+stores line (shallow, roughly flat ≈0.4 dropping slightly); a sea-level 450-kt
-stores line (shallow, dropping from ≈0.4 to ≈0.15 across the plotted range); a time-to-climb curve
(gently falling from ≈0.5 toward ≈0.35 as `W/S` increases); and an engine-out landing boundary
(`C_Lmax,L` = 1.8, 2.0, near-vertical at high `W/S`, confirming §3.7.4.2's non-critical finding).
Match point **P** sits at approximately `(W/S)≈55, T/W≈0.46)`, at the intersection of the take-off-
distance family (`C_Lmax,TO≈1.8`) with the time-to-climb curve.

Point P design summary, with `(T/W)_TO = 0.46` and `C_Lmax,TO = 1.8` meeting every requirement (the
landing `C_Lmax` is confirmed not critical, so a separate landing-flap setting is unnecessary)
**[Roskam, p. 190-191]**:

- Take-off weight with stores: 64,500 lb; take-off weight clean: 54,500 lb
- Empty weight: 33,500 lb; Fuel weight: 18,500 lb (already known, p. 67)
- `C_Lmax` clean: not determined; `C_Lmax,TO` = 1.8; `C_Lmax,L`: not critical
- Aspect ratio: `A = 4` (Roskam suggests also checking 3.5 and 4.5)
- Wing area: `64,500/55 = 1,173 ft²`
- Take-off thrust: `T_TO = 64,500 × 0.46 = 29,670 lb`

---

## §3.8 Problems

*[Roskam, p. 192]* — problem statements only, not solved here:

1. Do FAR 25 take-off/climb/landing sizing for the regional transport of §2.8, problem 2.
2. Do FAR 25 take-off/climb/landing sizing for the high-altitude loiter/reconnaissance airplane of
   §2.8, problem 3.
3. Do FAR 23 take-off/climb/landing sizing for the homebuilt airplane of §2.8, problem 4.
4. Do FAR 25 take-off/climb/landing sizing for the supersonic-cruise airplane of §2.8, problem 5.
5. Do FAR 23 sizing for an agricultural airplane: 4,000-lb spray/dust load; 10-mi ferry distance;
   160-mph ferry speed; <20-s swath turn-around; 45 lb/acre dispersal rate; 80-ft swath width;
   100-mph spray speed; <1,500-ft take-off distance over a 50-ft obstacle; 20-min fuel reserve at
   160 mph after emptying the hopper.
6. Do FAR 25 sizing for a 90-passenger twin turboprop: 1,500-n.mi. range at `M=0.7`/30,000 ft; crew
   of 2 pilots + 3 attendants at 200 lb/person incl. baggage; 7,000-ft field length, standard day,
   9,000-ft altitude; 16,000-ft engine-out service ceiling; max approach speed <130 kt; FAR Part 121
   fuel reserves.
7. For the Table 2.19 fighter, find the `T/W`-`W/S` relation at take-off for sustained level turns at
   load factors 4, 6, and 8 g, trading `C_Lmax` = 1.0, 1.2, 1.4, at sea level and `M = 0.8`.

---

## Chapter 4 — A User's Guide to Preliminary Airplane Sizing

Chapters 2 and 3 covered preliminary sizing to a range of mission and certification requirements in
detail. Chapter 4 collects that material into one step-by-step procedure.

**Step 1.** Get a mission specification and build a mission profile from it (Tables 2.17-2.19 are
worked examples).

**Step 2.** Number the mission phases in order, as in the Table 2.17-2.19 examples.

**Step 3.** Estimate a fuel fraction for each mission phase — some phases come directly from Table
2.1; for the rest, estimate `L/D` and `sfc` (Table 2.2 is a guide) and compute the fraction from
those.

**Step 4.** Combine the phase fuel fractions into the overall mission fuel fraction `M_ff` with the
method of §2.4, Eq. (2.13).

**Step 5.** From the mission specification, determine the fuel reserves `W_res` or reserve fraction
`M_res`.

**Step 6.** Follow the step-by-step procedure of §2's steps 1-7 (p. 7) to get take-off weight `W_TO`,
empty weight `W_E`, and fuel weight `W_F`; payload and crew weight follow directly from the mission
spec. **Note:** if the mission drops weight in flight (many military missions), some fuel fractions
need correcting for this — the procedure is in §2.6.3.

**Step 7.** Identify the certification base from the mission spec: homebuilt, FAR 23, FAR 25, or
military. A homebuilt design should default to FAR 23 for further sizing.

**Step 8.** List the performance parameters the airplane must be sized to, drawn from the mission
spec and the certification base. Chapter 3 covers six such sizing cases: (1) stall speed, (2)
take-off distance, (3) landing distance, (4) climb, (5) maneuvering, (6) cruise speed.

**Step 9.** Run the sizing calculations per §3.1-3.6. This step needs a drag-polar estimate, which
can be produced quickly with the method of §3.4.1.

**Step 10.** Build a matching graph overlaying every performance requirement — §3.7 gives three
full worked examples of this construction.

**Step 11.** Read the following six design parameters off the matching graph:
1. Take-off power loading `(W/P)_TO` or thrust-to-weight ratio `(T/W)_TO`
2. Take-off wing loading `(W/S)_TO`
3. Maximum clean lift coefficient `C_Lmax`
4. Maximum take-off lift coefficient `C_Lmax,TO`
5. Maximum landing lift coefficient `C_Lmax,L`
6. Wing aspect ratio `A`

**Step 12.** Compute take-off power or thrust from the selected loading:

```
P_TO = W_TO/(W/P)_TO      or      T_TO = W_TO·(T/W)_TO
```
**[Roskam, p. 194]**

**Step 13** *(printed as a second "Step 11" in the source — renumbered here for clarity)*. Compute
wing area:

```
S = W_TO/(W/S)_TO
```
**[Roskam, p. 195]**

At this point every parameter needed to start a preliminary configuration layout is defined. Part II
of the Roskam series covers configuration selection and layout from this starting point.

---

*Second half of Chapter 3 (§§3.5-3.8) and Chapter 4 complete. Figures 3.27-3.36 described/digitized
where they carry a matching design point or tabulated boundary; purely-illustrative aircraft
three-view/cutaway figures interleaved on the same pages (Gates Piaggio GP180, Boeing 757, Northrop
F5E, Gates Learjet 25/Model 55) are not reproduced — captioned only where mentioned, since they carry
no design data. Next: Chapter 5 (References) and beyond — out of scope for this extract.*
