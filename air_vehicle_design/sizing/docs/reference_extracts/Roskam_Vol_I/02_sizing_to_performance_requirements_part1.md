# Roskam, Airplane Design Part I — Sizing to Performance Requirements (Part 1: Stall, Take-off, Landing, Climb)

**Source:** Jan Roskam, *Airplane Design, Part I: Preliminary Sizing of Airplanes*, Chapter 3
(Estimating Wing Area `S`, Take-off Thrust `T_TO` or Take-off Power `P_TO`, and Maximum Lift
Coefficient, Clean/Take-off/Landing), §3.1 through §3.4, book pp. 89-159.

## Chapter 3 introduction

Chapter 2 gave a first estimate of take-off gross weight, `W_TO`. This chapter finds the other
airplane design parameters that fix performance: wing area `S`, take-off thrust `T_TO` (or take-off
power `P_TO`), and the maximum lift coefficients for the clean, take-off, and landing
configurations (`CL_max`, `CL_max,TO`, `CL_max,L`) [Roskam, p. 89].

Airplanes must meet performance goals in several categories: stall speed, take-off field length,
landing field length, cruise/maximum speed, climb rate (all engines operating AEO, and one engine
inoperative OEI), time to climb to an altitude, and maneuvering. This chapter's methods size the
airplane against every one of these goals except cruise speed (covered elsewhere) and maneuvering
(covered in §3.5, outside this extract) [Roskam, p. 89].

Each requirement produces an allowable range of wing loading `W/S`, thrust loading `T/W` (or power
loading `W/P`), and maximum lift coefficient `CL_max`. The combination of the highest wing loading
and lowest thrust (or power) loading that still meets every requirement gives the lightest, cheapest
airplane. Because `W_TO` is already known from Chapter 2, this step also fixes `S` and `T_TO` (or
`P_TO`) in absolute terms [Roskam, p. 90].

## §3.1 Sizing to Stall Speed Requirements

Some mission specifications set a maximum allowable stall speed. FAR 23 single-engine airplanes
must not stall above 61 kts at `W_TO`. FAR 23 multiengine airplanes under 6,000 lbs must also meet
this 61-kt limit unless they satisfy certain climb-gradient rules [Roskam, Ref. 8, Par. 23.49, p.
90]. The designer may choose to meet the requirement flaps-up or flaps-down. FAR 25 airplanes have
no minimum stall speed requirement [Roskam, p. 90].

The power-off stall speed is [Roskam, Eq. (3.1), p. 90]:

```
V_S = [2(W/S) / (rho * CL_max)]^(1/2)
```

where `rho` is air density at the altitude of interest and `CL_max` is the maximum lift coefficient
in the configuration being checked. A maximum allowable stall speed, together with Eq. (3.1), sets a
maximum allowable wing loading `W/S` for a chosen `CL_max`.

[Roskam, Table 3.1, p. 91] lists typical `CL_max` (clean), `CL_max,TO` (take-off), and `CL_max,L`
(landing) ranges for twelve airplane categories (homebuilts; single-engine and twin-engine
propeller; agricultural; regional turboprop; transport jets; military trainers; fighters; military
patrol/bomber/transport; flying boats/amphibians/floatplanes; supersonic cruise airplanes).
Representative rows: fighters 1.2-1.8 / 1.4-2.0 / 1.6-2.6; transport jets 1.2-1.8 / 1.6-2.2 /
1.8-2.8; single-engine propeller 1.3-1.9 / 1.3-1.9 / 1.6-2.3. The table reflects 1984 flap design
practice; more advanced flaps or circulation control can give higher values. `CL_max` depends
strongly on wing and airfoil design, flap type and size, and center-of-gravity location [Roskam,
Table 3.1 notes, p. 91]. Reference 5 gives detailed `CL_max` estimation methods that account for
these factors; during preliminary sizing it is enough to pick a `CL_max` consistent with the mission
and the chosen flap type [Roskam, p. 92].

### §3.1.1 Example of Stall Speed Sizing

A propeller airplane must stall at no more than 50 kts at sea level with landing flaps, and no more
than 60 kts flaps-up, both at `W_TO`. Table 3.1 gives `CL_max,L` = 1.60 and `CL_max` = 2.00 as
reasonable values. Eq. (3.1) then gives:

- Flaps-down requirement: `(W/S)_TO` <= 17.0 psf.
- Flaps-up requirement: `(W/S)_TO` <= 19.5 psf.

The flaps-down case is tighter, so `(W/S)_TO` must stay below 17.0 psf. [Roskam, Fig. 3.1, p. 93]
illustrates this: a simple bar chart with a single vertical line at `W/S` = 17.0 splitting the
`T/W`-or-`W/P` axis into a "requirement met" region to the left and a "requirement not met" region
to the right — no additional plotted trend data beyond the one boundary value already given by the
equation above. Because this was a power-off requirement, neither thrust loading nor power loading
enters the result [Roskam, p. 92].

## §3.2 Sizing to Take-off Distance Requirements

Take-off distance depends on take-off weight `W_TO`, take-off (lift-off) speed `V_TO`,
thrust-to-weight ratio `(T/W)_TO` (or power-to-weight ratio `(W/P)_TO` and propeller
characteristics), aerodynamic drag coefficient `C_D` and ground friction coefficient `mu_G`, and
pilot technique. This section assumes take-off from a hardened (concrete or asphalt) runway unless
stated otherwise [Roskam, p. 94].

Civil airplanes must meet FAR 23 or FAR 25 take-off field length rules; homebuilts need not follow
either. Military take-off requirements come from the Request for Proposal (RFP) and must be
calculated per Reference 15's definitions, often as a minimum ground run plus a minimum climb
capability. Navy carrier airplanes must also respect the shipboard catapult's limits. Sub-sections
3.2.1-3.2.6 cover airplanes with ordinary mechanical flaps; augmented-flap or vectored-thrust
airplanes need Refs. 12 and 13 instead [Roskam, p. 94].

### §3.2.1 Sizing to FAR 23 Take-off Distance Requirements

[Roskam, Fig. 3.2, p. 93] defines the FAR 23 take-off distances: the take-off ground run `S_TOG`
(from brake release to lift-off) and the total take-off distance `S_TO` (ground run plus the climb
to a 50-ft obstacle) — an illustrative sketch, no plotted data. FAR 23 airplanes are usually
propeller-driven.

Reference 11 shows `S_TOG` is proportional to take-off wing loading `(W/S)_TO`, take-off power
loading `(W/P)_TO`, and maximum take-off lift coefficient `CL_max,TO` [Roskam, Eq. (3.2), p. 95]:

```
S_TOG ~ (W/S)_TO * (W/P)_TO / CL_max,TO = TOP_23
```

`TOP_23` is the FAR 23 take-off parameter, with dimension lbs^2/(ft^2*hp). The lift-off lift
coefficient `CL_TO` relates to the maximum take-off lift coefficient by [Roskam, Eq. (3.3), p. 95]:

```
CL_TO = CL_max,TO / 1.21
```

[Roskam, Fig. 3.3, p. 93] plots `S_TOG` and `S_TO` against `TOP_23` for a set of FAR 23 single- and
twin-engine airplanes (data from Ref. 11); there is real scatter because take-off procedure,
propeller characteristics, and pilot rotation technique all vary. Even so, the correlation lines
drawn through the data are useful for sizing. Read from the plot, the correlation lines pass
through approximately (`TOP_23` = 100, `S_TOG` ~ 900 ft, `S_TO` ~ 1,500 ft) and (`TOP_23` = 200,
`S_TOG` ~ 2,000 ft, `S_TO` ~ 3,300 ft). The correlation lines give [Roskam, Eq. (3.4), p. 95]:

```
S_TOG = 4.9*TOP_23 + 0.009*TOP_23^2
```

[Roskam, Fig. 3.4, p. 96] cross-plots `S_TO` against `S_TOG` for 23 airplanes (single-engine circle
markers, twin-engine square markers); the data cluster tightly about a straight line through the
origin, giving [Roskam, Eq. (3.5), p. 95]:

```
S_TO = 1.66 * S_TOG
```

Combining Eqs. (3.4) and (3.5) gives the take-off distance directly in terms of `TOP_23` [Roskam,
Eq. (3.6), p. 96]:

```
S_TO = 8.134*TOP_23 + 0.0149*TOP_23^2
```

These equations assume a propeller-driven FAR 23 airplane. For a FAR 23 jet, replace `W/P` with
`W/T` in Eq. (3.2), or better, use the FAR 25 method of §3.2.3 [Roskam, p. 97].

### §3.2.2 Example of FAR 23 Take-off Sizing

Size a propeller airplane so that `S_TOG` <= 1,000 ft and `S_TO` <= 1,500 ft at 5,000 ft altitude,
standard atmosphere. Eq. (3.5) shows the ground-run requirement alone implies `S_TO` <= 1,660 ft,
which is looser than the 1,500-ft total-distance requirement — so the total-distance requirement
governs. Solving Eq. (3.6) for `TOP_23` at `S_TO` = 1,500 ft gives `TOP_23` = 145.6 lbs^2/(ft^2*hp).
At 5,000 ft, `sigma` = 0.8616, so from Eq. (3.2):

```
(W/S)_TO * (W/P)_TO / CL_max,TO <= 145.6 * 0.8616 = 125.4 lbs^2/(ft^2*hp)
```

This produces the following table of allowable `(W/P)_TO` [lbs/hp] versus `(W/S)_TO` [psf] and
`CL_max,TO`:

| `(W/S)_TO` [psf] | `CL_max,TO` = 1.2 | 1.6 | 2.0 | 2.4 |
|---|---|---|---|---|
| 10 | 15.0 | 20.1 | 25.1 | 30.1 |
| 30 | 5.0 | 6.7 | 8.4 | 10.0 |
| 50 | 3.0 | 4.0 | 5.0 | 6.0 |

[Roskam, Fig. 3.5, p. 96] turns this table into a chart of power loading `(W/P)_TO` versus wing
loading `(W/S)_TO`, with one curve per `CL_max,TO` value (1.2, 1.6, 2.0, 2.4) sweeping from about
(`W/S`=10, `W/P`=15-30 depending on `CL_max,TO`) down to (`W/S`=50, `W/P`=3-6); points on or below a
curve meet the requirement, points above do not. The curve values match the table above exactly, so
no further digitization is needed.

### §3.2.3 Sizing to FAR 25 Take-off Distance Requirements

[Roskam, Fig. 3.6, p. 99] defines the FAR 25 take-off field length `S_TOFL`: from brake release,
through the lift-off distance (with an engine failure marked partway along the ground roll) and the
climb to a 35-ft obstacle, ending at the stop distance available on the stopway — an illustrative
sketch, no plotted data.

Reference 11 shows the FAR 25 take-off field length is proportional to take-off wing loading, take-off
thrust-to-weight ratio, and maximum take-off lift coefficient [Roskam, Eq. (3.7), p. 98]:

```
S_TOFL ~ (W/S)_TO / (sigma * CL_max,TO * (T/W)_TO) = TOP_25
```

`TOP_25` is the FAR 25 take-off parameter, dimension lbs/ft^2. [Roskam, Fig. 3.7, p. 99] plots
`S_TOFL` against `TOP_25` for twin-, three-, and four-engine jets (data from Ref. 11; solid markers
are wide-bodies). Read from the plot, the correlation line runs through about (`TOP_25`=100,
`S_TOFL`~3,800 ft) and (`TOP_25`=300, `S_TOFL`~11,500 ft), i.e. very nearly a straight line through
the origin, giving [Roskam, Eq. (3.8), p. 98]:

```
S_TOFL = 37.5 * (W/S)_TO / (sigma * CL_max,TO * (T/W)_TO) = 37.5 * TOP_25
```

Typical `CL_max,TO` values are in Table 3.1. FAR 25 airplanes may be jet- or propeller-driven
(including prop-fans and turboprops); for propeller-driven types, [Roskam, Fig. 3.8, p. 100]
converts the required `(T/W)_TO` to the corresponding `(W/P)_TO`, for a chosen propeller blade
count/diameter combination (curves labeled `x/y` where `x` = number of blades, `y` = propeller
diameter in ft, e.g. 2/7, 3/8.5, 4/9.1, 4/11, 5/9.5, 4/10.5, 4/14). The chart also carries the
assumptions `T_100kts` ~= 0.63*`T_static` and `T_static` ~= 2.9*`P_TO` (thrust-horsepower
conversion); the plotted line runs from the origin up through about (`P_TO`=500 hp, `T_TO`~1,450
lbs) to (`P_TO`=2,500 hp, `T_TO`~7,250 lbs), consistent with `T_static` ~= 2.9*`P_TO`.

### §3.2.4 Example of FAR 25 Take-off Sizing

Size a passenger jet so `S_TOFL` <= 5,000 ft at 8,000 ft, standard atmosphere. From Eq. (3.8),
`TOP_25` = 5,000/37.5 = 133.3 lbs/ft^2. At 8,000 ft, `sigma` = 0.786, so from Eq. (3.7):

```
(W/S)_TO / (CL_max,TO * (T/W)_TO) = 133.3 * 0.786 = 104.8 lbs/ft^2
```

This gives the following table of required `(T/W)_TO` versus `(W/S)_TO` [psf] and `CL_max,TO`:

| `(W/S)_TO` [psf] | `CL_max,TO` = 1.2 | 1.6 | 2.0 | 2.4 |
|---|---|---|---|---|
| 40 | 0.32 | 0.24 | 0.19 | 0.16 |
| 60 | 0.48 | 0.36 | 0.29 | 0.24 |
| 80 | 0.64 | 0.48 | 0.38 | 0.32 |
| 100 | 0.80 | 0.60 | 0.48 | 0.40 |

[Roskam, Fig. 3.9, p. 100] plots `(T/W)_TO` versus `(W/S)_TO` with one curve per `CL_max,TO` value
(1.6, 2.0, 2.4), each running from the origin up to about (`W/S`=100, `T/W`~0.4-0.8 depending on
`CL_max,TO`), matching the table values above; the region left of/below each curve meets the
requirement. No further digitization needed beyond the table.

### §3.2.5 Sizing to Military Take-off Distance Requirements

#### §3.2.5.1 Land-based airplanes

Reference 15 defines the military take-off field length the same way as Fig. 3.6, except the
obstacle height is 50 ft instead of 35 ft. Military requirements are often stated as a maximum
allowable ground run `S_TOG`, estimated from [Roskam, Eq. (3.9), p. 101-102]:

```
                        k_1 (W/S)_TO
S_TOG = ---------------------------------------------------
        rho [ C_Lmax_TO { k_2 (X/W)_TO - mu_G } - 0.72 C_D0 ]
```

Roskam states this equation is a variation of Eq. (5-75) in Ref. 16. It assumes two conditions:
(a) no wind, and (b) a level runway.

The quantities `k_1`, `k_2`, and `X` are defined separately for jets and for propeller airplanes
[Roskam, p. 102]:

| Quantity | For jets | For props |
|---|---|---|
| `X` | `T` (thrust) | `P` (power) |
| `k_1` | 0.0447 | 0.0376 |
| `k_2` | `0.75 (5 + lambda)/(4 + lambda)` | `l_p (sigma N D_p^2 / P_TO)^(1/3)` |

`lambda` is the engine bypass ratio. `l_p` = 5.75 for constant-speed propellers and 4.60 for
fixed-pitch propellers. The term `P_TO / (N D_p^2)` is the propeller disk loading. `P_TO` is the
total take-off power with all engines operating, and `N` is the number of engines.

**Typical propeller disk loadings, hp/ft²** [Roskam, p. 102]:

| Singles | Light Twins | Heavy Twins | Turboprops |
|---|---|---|---|
| 3–8 | 6–10 | 8–14 | 10–30 |

Typical propeller disk-loading values can also be taken from Reference 9 data.
Eq. (3.9) applies whenever power or thrust effects on lift can be neglected; where that is not
true, use Refs. 12 and 13 instead [Roskam, p. 102].

[Roskam, Table 3.2, p. 102] gives typical ground friction coefficients `mu_G`: concrete 0.02-0.03
(0.025 per Ref. 15), asphalt 0.02-0.03, hard turf 0.05, short grass 0.05, long grass 0.10, soft
ground 0.10-0.30.

#### §3.2.5.2 Carrier-based airplanes

Carrier take-offs must respect the catapult's launch-speed-versus-weight envelope. [Roskam, Fig.
3.10, p. 104] plots this for the U.S. Navy's catapult systems (data illustrative — a family of
weight/catapult-speed curves; no single trend equation is given). At the end of the catapult stroke
the following must hold [Roskam, Eq. (3.10), p. 105]:

```
0.5 * rho * (V_cat^2 + V_wind^2) * CL_max,TO / 1.21 = W_TO / S
```

From this, Eq. (3.10) gives allowable ranges of `W/S`, `T/W`, and `CL_max,TO` that keep the airplane
within catapult capability.

### §3.2.6 Example of Military Take-off Sizing (Land and Carrier)

Size a Navy attack airplane so that: (a) land-based `S_TOG` <= 2,500 ft at sea level, standard
atmosphere, concrete runway; (b) carrier take-off is compatible with the C13 catapult at `V_wind` =
25 kts. [Roskam, Fig. 3.11, p. 104] plots the resulting range of `(T/W)_TO` versus `(W/S)_TO` that
satisfies the land-based ground-run requirement for `mu_G` = 0.025, assumed bypass ratio `lambda` =
1.5, and assumed `CD_0` = 0.0130 — the same style of "requirement met / not met" region chart as
Figs. 3.5 and 3.9, built directly from Eq. (3.9); no separate numeric readout beyond the equation
inputs already stated.

The C13 catapult data (Fig. 3.10) show `W_TO` <= 100,000 lbs must always hold. Below that weight,
Fig. 3.10 gives the following weight-versus-catapult-speed table (read from the plot):

| `W_TO` [lbs] | `V_cat` [kts] |
|---|---|
| 100,000 | 120 |
| 72,000 | 130 |
| 53,000 | 140 |
| 39,000 | 150 |

Eq. (3.10) then converts each `(W_TO, V_cat)` pair, for a chosen `CL_max,TO`, into an allowable
take-off wing loading `(W/S)_TO`.

## §3.3 Sizing to Landing Distance Requirements

Landing distance depends on landing weight `W_L`, approach speed `V_A`, the deceleration method used
(brakes, thrust reversers, parachutes, arresting gear, or crash barriers), the airplane's flying
qualities, and pilot technique. Landing requirements are always stated at the design landing weight
`W_L`, not `W_TO`. [Roskam, Table 3.3, p. 107] gives typical `W_L/W_TO` ratios for twelve airplane
categories (based on Tables 2.3-2.14): e.g. fighters (jets) 0.78-1.0, transport jets 0.65-1.0
(average 0.84), military trainers 0.87-1.1, supersonic cruise airplanes 0.63-0.88. Because kinetic
energy scales with speed squared, approach speed has a squared effect on landing distance [Roskam,
p. 106].

Civil airplanes follow FAR 23 or FAR 25; homebuilts need not. Military landing requirements are set
in the RFP, sometimes as ground run alone, without the accompanying air distance. Navy airplanes
must also respect the shipboard arresting system's limits. Sub-sections 3.3.1-3.3.6 cover
conventional mechanical-flap airplanes; augmented-flap/vectored-thrust types need Refs. 12 and 13
[Roskam, p. 107].

### §3.3.1 Sizing to FAR 23 Landing Distance Requirements

[Roskam, Fig. 3.12, p. 109] defines the FAR 23 landing distances (illustrative sketch, no plotted
data): landing ground run `S_LG` and total landing distance `S_L` (ground run plus air distance from
a 50-ft obstacle). The approach speed is defined as [Roskam, Eq. (3.11), p. 108]:

```
V_A = 1.3 * V_S_L
```

where `V_S_L` is the power-off stall speed in the landing configuration (gear down, landing flaps).
[Roskam, Fig. 3.13, p. 109] plots `S_LG` against `V_S_L^2` for FAR 23 airplanes (data from Ref. 11),
giving [Roskam, Eq. (3.12), p. 108]:

```
S_LG = 0.265 * V_S_L^2      (S_LG in ft, V_S_L in kts)
```

[Roskam, Fig. 3.14, p. 110] cross-plots total landing distance `S_L` against `S_LG` for the same
data set; the correlation line runs from the origin through about (`S_LG`=1,000 ft, `S_L`~1,950 ft)
and (`S_LG`=2,000 ft, `S_L`~3,900 ft), i.e. very nearly a straight proportional line, giving [Roskam,
Eq. (3.13), p. 108]:

```
S_L = 1.938 * S_LG
```

Given a maximum allowable `S_L`, Eqs. (3.12)-(3.13) back out the allowable `V_S_L`, which §3.1's
Eq. (3.1) then converts into a `(W/S)_L`-versus-`CL_max,L` relation. Combining Eqs. (3.12) and (3.13)
directly gives [Roskam, Eq. (3.14), p. 108]:

```
S_L = 0.5136 * V_S_L^2      (S_L in ft, V_S_L in kts)
```

### §3.3.2 Example of FAR 23 Landing Distance Sizing

Size a propeller twin for `S_L` = 2,500 ft at 5,000 ft altitude, with `W_L` = 0.95*`W_TO`. From
Eq. (3.14): `V_S_L` = (2,500/0.5136)^(1/2) = 69.8 kts. With Eq. (3.1):

```
2*(W/S)_L / (0.002049 * CL_max,L) = (69.8*1.688)^2 = 13,869 ft^2/sec^2
```

so `(W/S)_L` = 14.2*`CL_max,L`. With `W_L` = 0.95*`W_TO`, this becomes `(W/S)_TO` = 14.9*`CL_max,L`.
[Roskam, Fig. 3.15, p. 110] plots the resulting `(T/W)_TO`-vs-`(W/S)_TO` "requirement met / not
met" chart for `CL_max,L` values of 1.6, 2.0, 2.4, 2.8 (same style as Figs. 3.5/3.9), with the
vertical boundary lines landing at `(W/S)_TO` ~= 23.8, 29.8, 35.8, 41.7 psf respectively, consistent
with `(W/S)_TO` = 14.9*`CL_max,L`.

### §3.3.3 Sizing to FAR 25 Landing Distance Requirements

[Roskam, Fig. 3.16, p. 112] defines the FAR 25 landing field length quantities (illustrative
sketch). The FAR landing field length is the actual total landing distance divided by 0.6, a safety
factor covering pilot-technique and other variation beyond FAA control. The FAR 25 approach speed is
always [Roskam, Eq. (3.15), p. 111]:

```
V_A = 1.3 * V_S_L
```

[Roskam, Fig. 3.17, p. 112] relates the FAR field length `S_FL` to the square of approach speed
(data read from plot runs roughly from (`V_A^2`=2.0x10^4 kts^2, `S_FL`~6,000 ft) to (`V_A^2`=2.8x10^4
kts^2, `S_FL`~8,400 ft)), giving [Roskam, Eq. (3.16), p. 111]:

```
S_FL = 0.3 * V_A^2      (S_FL in ft, V_A in kts)
```

Eq. (3.1) then relates `(W/S)_L` (and so `(W/S)_TO`) to `CL_max,L`. Note that FAR 23 field length
correlates with stall speed `V_S_L`, while FAR 25 field length correlates with approach speed `V_A`
— simply because the source data (Ref. 9) happened to be reported that way, not because of a
physical difference [Roskam, p. 112].

### §3.3.4 Example of FAR 25 Landing Distance Sizing

Size a jet transport for `S_FL` = 5,000 ft at sea level, standard day, with `W_L` = 0.85*`W_TO`.
From Eq. (3.16): `V_A` = (5,000/0.3)^(1/2) = 129.1 kts. From Eq. (3.15): `V_S_L` = 129.1/1.3 = 99.3
kts. From Eq. (3.1):

```
2*(W/S)_L / (0.002378 * CL_max,L) = (99.3*1.688)^2 = 28,100 ft^2/sec^2
```

so `(W/S)_L` = 33.4*`CL_max,L`, and `(W/S)_TO` = (33.4/0.85)*`CL_max,L` = 39.3*`CL_max,L`. [Roskam,
Fig. 3.18, p. 113] plots the resulting `(T/W)_TO`-versus-`(W/S)_TO` chart for `CL_max,L` = 1.7,
2.5, and 3.4, with vertical "requirement met/not met" boundaries at `(W/S)_TO` ~= 67, 98, and 134
psf respectively — consistent with `(W/S)_TO` = 39.3*`CL_max,L`.

### §3.3.5 Sizing to Military Landing Distance Requirements

#### §3.3.5.1 Land-based airplanes

Military landing requirements are normally set in the RFP. The FAR 25 sizing method applies, with
one difference: military approach speeds are usually lower than commercial ones. From Reference 15
[Roskam, Eq. (3.17), p. 115]:

```
V_A = 1.2 * V_S_L
```

Because landing distance scales with the square of approach speed, this lower multiplier directly
shortens the required landing distance relative to the FAR 25 case.

#### §3.3.5.2 Carrier-based airplanes

For carrier landings, approach speed is [Roskam, Eq. (3.18), p. 115]:

```
V_PA = 1.15 * V_A
```

and the shipboard arresting system's limits must also be respected. [Roskam, Fig. 3.19, p. 114]
plots landing weight `W_L` against airplane engaging speed `V_A` for three arresting-gear types
(Mark 7 Mod 1, Mod 2, Mod 3), each shown as a curve with a "hardware limit" boundary and a shaded
"not OK" region to its right. Read from the plot: Mod 1 limits `V_A` to about 130 kts up to `W_L`
~25,000 lbs, dropping to ~113 kts by `W_L` = 40,000 lbs; Mod 2 allows about 140 kts up to `W_L`
~30,000 lbs, dropping to ~120 kts by `W_L` = 55,000 lbs; Mark 7 Mod 3 allows about 145 kts up to
`W_L` ~40,000 lbs, dropping toward ~120 kts by `W_L` = 50,000 lbs.

### §3.3.6 Example of Sizing to Military Landing Distance Requirements

For the same Navy attack airplane as §3.2.6: (a) shore-based `S_FL` = 3,500 ft at sea level, standard
atmosphere, concrete runway; (b) carrier landing compatible with the Mark 7 Mod 3 arresting gear; (c)
`W_L` = 0.80*`W_TO`.

For (a): Fig. 3.17's FAR 25 data give an approach speed of (11,800)^(1/2) = 108.6 kts for `S_FL` =
3,500 ft. For a military airplane, Eq. (3.17) converts this to a stall speed of 108.6/1.2 = 90.5
kts. With Eq. (3.1):

```
2*(W/S)_L*0.002378*CL_max,L = (90.5*1.688)^2 = 23,337 ft^2/sec^2
```

so `(W/S)_L` = 27.7*`CL_max,L`, and with `W_L` = 0.80*`W_TO`: `(W/S)_TO` = 34.7*`CL_max,L`.

For (b): Fig. 3.19 shows the Mark 7 Mod 3 gear allows `V_A` = 145 kts as long as `W_L` < 40,000 lbs
(implying `W_TO` < 50,000 lbs). Eq. (3.18) gives `V_PA` = 145/1.15 = 126.1 kts. With Eq. (3.1):

```
(W/S)_L = 0.5*0.002378*(126.1*1.688)^2*CL_max,L = 53.9*CL_max,L
```

so `(W/S)_TO` = (53.9/0.8)*`CL_max,L` = 67.3*`CL_max,L`. [Roskam, Fig. 3.20, p. 117] plots both
results as `(T/W)_TO`-versus-`(W/S)_TO` boundary lines (for `CL_max,L` = 1.5, 2.0, 2.5, and a
separate carrier-limit line at `CL_max,PA` = 1.5 with the `W_L` < 40,000 lb / `W_TO` < 50,000 lb
caveat noted on the chart), with vertical boundaries at `(W/S)_TO` ~= 52, 69, 87 psf for the
shore-based case and ~= 101 psf for the carrier case; the shore-based field-length requirement is the
more critical of the two in this example.

## §3.4 Sizing to Climb Requirements

Every airplane must meet climb-rate or climb-gradient requirements. Sizing to these requirements
needs an estimated drag polar; §3.4.1 gives a rapid drag-polar estimation method, applied to an
example airplane in §3.4.2. §3.4.3-3.4.5 cover FAR 23 climb requirements and sizing; §3.4.6-3.4.8
cover FAR 25. §3.4.9 summarizes military climb requirements (also sizeable with the FAR 23/25
methods for low-speed climb). §3.4.10 covers time-to-climb and ceiling sizing; §3.4.11 covers
specific-excess-power sizing; §3.4.12 works a combined military climb example [Roskam, p. 118].

### §3.4.1 A Method for Estimating Drag Polars at Low Speed

Assuming a parabolic drag polar [Roskam, Eq. (3.19), p. 118]:

```
CD = CD_0 + CL^2 / (pi * A * e)
```

The zero-lift drag coefficient is [Roskam, Eq. (3.20), p. 118]:

```
CD_0 = f / S
```

where `f` is the equivalent parasite area and `S` is wing area. [Roskam, Fig. 3.21, p. 119-120]
relates `f` to wetted area `S_wet`, for a family of equivalent skin-friction coefficients `Cf`
(illustrative log-log correlation lines, no additional numeric readout beyond the regression below),
giving [Roskam, Eq. (3.21), p. 122]:

```
log10(f) = a + b*log10(S_wet)
```

`a` and `b` are correlation coefficients that depend on `Cf`. [Roskam, Table 3.4, p. 122] tabulates
them (`b` = 1.0000 in every row):

| `Cf` | `a` | `b` |
|---|---|---|
| 0.0090 | -2.0458 | 1.0000 |
| 0.0080 | -2.0969 | 1.0000 |
| 0.0070 | -2.1549 | 1.0000 |
| 0.0060 | -2.2218 | 1.0000 |
| 0.0050 | -2.3010 | 1.0000 |
| 0.0040 | -2.3979 | 1.0000 |
| 0.0030 | -2.5229 | 1.0000 |
| 0.0020 | -2.6990 | 1.0000 |

The method reduces to estimating a realistic wetted area `S_wet`. [Roskam, Fig. 3.22a-d, pp.
123-126] show that `S_wet` correlates well with `W_TO` across a wide range of airplanes (four
log-log scatter plots, one panel per group of airplane categories; most airplanes fall within a
+-10% band of the fitted line; scatter mainly reflects differences in wing loading, cabin size, and
nacelle design) — no further point-by-point digitization needed beyond the regression it implies
[Roskam, Eq. (3.22), p. 122]:

```
log10(S_wet) = c + d*log10(W_TO)
```

`c` and `d` are regression coefficients fit from 230 airplanes across the same twelve categories used
in Chapter 2. [Roskam, Table 3.5, p. 122]:

| Airplane type | `c` | `d` |
|---|---|---|
| Homebuilts | 1.2362 | 0.4319 |
| Single-engine propeller | 1.0892 | 0.5147 |
| Twin-engine propeller | 0.8635 | 0.5632 |
| Agricultural | 1.0447 | 0.5326 |
| Business jets | 0.2263 | 0.6977 |
| Regional turboprops | -0.0866 | 0.8099 |
| Transport jets | 0.0199 | 0.7531 |
| Military trainers* | 0.8565 | 0.5423 |
| Fighters* | -0.1289 | 0.7506 |
| Military patrol/bomber/transport | 0.1628 | 0.7316 |
| Flying boats/amphibians/floatplanes | 0.6295 | 0.6708 |
| Supersonic cruise airplanes | -1.1868 | 0.9609 |

*For military trainers and fighters, wetted area was correlated with clean maximum take-off weight
(no external stores) [Roskam, Table 3.5 note, p. 122].

For take-off and landing configurations, flap and landing-gear drag increments must be added.
[Roskam, Table 3.6, p. 126] gives typical increments:

| Configuration | `delta_CD_0` | `e` |
|---|---|---|
| Clean | 0 | 0.80-0.85 |
| Take-off flaps | 0.010-0.020 | 0.75-0.80 |
| Landing flaps | 0.055-0.075 | 0.70-0.75 |
| Landing gear | 0.015-0.025 | no effect |

The actual value picked depends on flap and gear type: split flaps are draggier than Fowler flaps,
full-span flaps draggier than partial-span, and wing-mounted gear on high-wing airplanes draggier
than on low-wing airplanes. Reference 5 has detailed drag-item estimation methods [Roskam, p. 126].

### §3.4.2 Example of Drag Polar Determination

Find the clean, take-off, and landing drag polars for a jet with `W_TO` = 10,000 lbs. From Fig. 3.22
(or Eq. 3.22), `S_wet` = 1,050 ft^2. Taking `Cf` = 0.0030 (Fig. 3.21), `f` = 3.15 ft^2. Assuming an
average wing loading of 75 psf (typical range for this weight class is 50-100 psf) gives `S` = 133
ft^2 and `CD_0` = 3.15/133 = 0.0237. With `A` = 10 and `e` = 0.85 (clean):

```
Clean:               CD = 0.0237 + 0.0374*CL^2
Take-off, gear up:   CD = 0.0387 + 0.0398*CL^2   (delta_CD_0 = 0.015, e = 0.80)
Take-off, gear down: CD = 0.0557 + 0.0398*CL^2   (+0.017 for gear)
Landing, gear up:    CD = 0.0837 + 0.0424*CL^2   (delta_CD_0 = 0.060, e = 0.75)
Landing, gear down:  CD = 0.1007 + 0.0424*CL^2   (+0.017 for gear)
```

The reader is reminded that if wing area is varied at constant weight, wetted area (and hence
`CD_0`) also changes — the drag polar is not independent of the `W/S` chosen [Roskam, p. 127].

### §3.4.3 Summary of FAR 23 Climb Requirements

FAR 23 climb requirements (Ref. 8) cover two flight conditions: take-off and balked landing. They
must be met with power/thrust reduced for installation losses and accessory operation; reciprocating
engines are rated at 80% humidity at or below standard temperature, turbines at 34% humidity and
standard temperature + 50 F (FAR 23.45) [Roskam, p. 129].

**§3.4.3.1 FAR 23.65 (AEO):** All airplanes need a minimum sea-level climb rate of 300 fpm and a
climb angle of at least 1:12 (landplanes) or 1:15 (seaplanes), with: not more than maximum
continuous power, gear retracted, take-off flaps, cowl flaps as required (FAR 23.1041-1047). Turbine
airplanes must also show a 4% climb gradient at 5,000 ft pressure altitude and 81 F, same
configuration [Roskam, p. 129].

**§3.4.3.2 FAR 23.67 (OEI):** For reciprocating-engine multiengine airplanes over 6,000 lbs, steady
climb rate at 5,000 ft must be at least `0.027*V_S0^2` fpm (`V_S0` in kts), with: critical engine
inoperative and feathered, remaining engines at max continuous power, gear retracted, flaps most
favorable, cowl flaps as required. The same rule applies under 6,000 lbs if `V_S0` > 61 kts;
otherwise only a determination of the (possibly negative) climb rate is required. Turbine airplanes
must meet, regardless of weight: (a) 1.2% gradient or `0.027*V_S0^2` fpm at 5,000 ft standard, or
(b) 0.6% gradient or `0.014*V_S0^2` fpm at 5,000 ft and 81 F — whichever is more critical [Roskam,
pp. 129-130].

**§3.4.3.3 FAR 23.77 (balked landing):** Steady climb angle >= 1:30, with: take-off power on all
engines, gear down, landing flaps (unless retractable within 2 sec without altitude loss or unusual
pilot skill). Turbine airplanes must also show zero climb rate at 5,000 ft and 81 F in this
configuration [Roskam, pp. 130-131].

### §3.4.4 Sizing to FAR 23 Climb Requirements

Reference 11 (Eqs. 6.15/6.16) gives the sizing relations.

**§3.4.4.1 Rate-of-climb sizing.** [Roskam, Eq. (3.23), p. 131]:

```
RC = dh/dt = 33,000 * RCP      (RC in fpm)
```

where the rate-of-climb parameter is [Roskam, Eq. (3.24), p. 131]:

```
RCP = eta_p/(W/P) - [(W/S)^(1/2) / (19*(CL^3/2/CD)*sigma^(1/2))]
```

To maximize `RC`, maximize `CL^(3/2)/CD`, achieved when [Roskam, Eqs. (3.25)-(3.26), p. 131]:

```
CL = (3*CD_0*pi*A*e)^(1/2)
CD = 4*CD_0
```

which gives [Roskam, Eq. (3.27), p. 132]:

```
(CL^3/2 / CD)_max = 1.345 * (A*e)^(3/4) / CD_0^(1/4)
```

[Roskam, Fig. 3.23, p. 133] plots `(CL^3/2/CD)_max` against the lift coefficient at which it occurs,
for a family of aspect ratios `A` (6, 8, 10, 12, 14) and zero-lift drag coefficients `CD_0` (0.01
through 0.06), at `e` = 0.7. Read from the plot: at `A` = 10, `CD_0` = 0.02, `(CL^3/2/CD)_max` ~= 15
at `CL` ~= 1.1; at `A` = 6, `CD_0` = 0.02, `(CL^3/2/CD)_max` ~= 11 at `CL` ~= 0.9; at `A` = 14, `CD_0`
= 0.01, `(CL^3/2/CD)_max` ~= 24 at `CL` ~= 0.9. Higher aspect ratio and lower `CD_0` both raise the
achievable value.

**§3.4.4.2 Climb-gradient sizing.** [Roskam, Eq. (3.28), p. 132]:

```
CGR = (dh/dt)/V
```

with the climb-gradient parameter [Roskam, Eqs. (3.29)-(3.30), p. 132]:

```
CGRP = {CGR + 1/(L/D)} * CL^(1/2)
CGRP = 18.97 * sigma^(1/2) / [(W/P) * (W/S)^(1/2)] * eta_p
```

The best climb gradient occurs near `CL_max`, so FAR 23 requires the manufacturer to publish the
best-rate-of-climb speed (there is no requirement to publish the best-climb-gradient speed). Roskam
suggests keeping a margin `delta_CL` = 0.2 between `CL_max` and the climb `CL` [Roskam, p. 132].

### §3.4.5 Example of FAR 23 Climb Sizing

Size a twin-engine propeller airplane, `W_TO` = `W_L` = 7,000 lbs, against: FAR 23.65 AEO (`RC` >=
300 fpm, `CGR` >= 1/12, gear up/take-off flaps/max continuous power); FAR 23.67 OEI (`RC` >=
`0.027*V_S0^2` fpm at 5,000 ft, gear up/flaps most favorable/feathered prop/take-off power on the
live engine); FAR 23.77 (`CGR` >= 1/30, gear down/landing flaps/take-off power, all engines)
[Roskam, p. 134].

**Rate of climb.** From Eq. (3.23), FAR 23.65 needs `RCP` = 300/33,000 = 0.0091 hp/lbs. For FAR
23.67, `V_S0` at 5,000 ft (`rho` = 0.002049 slug/ft^3, `CL_max` = 1.7 flaps-up) gives, for `W/S` =
20/30/40/50 psf: `V_S0` = 107/131/152/169 fps (63/78/90/100 kts), `RC` = 107/164/219/210 fpm, `RCP` =
0.0032/0.0050/0.0066/0.0082 hp/lbs [Roskam, p. 134-135].

The drag polar assumed: `S_wet` ~1,060 ft^2 (Fig. 3.22), `Cf` = 0.0050 giving `f` = 5 ft^2 (Fig.
3.21), average `W/S` = 35 psf giving `CD_0` = 0.0250; `e` = 0.80, `A` = 8; `delta_CD_0` = 0.0150
(take-off flaps), 0.0600 (landing flaps), 0.0200 (gear).

For FAR 23.65: `CD` = 0.0400 + `CL^2`/20.1, `(CL^3/2/CD)_max` = 12.1, `eta_p` = 0.8, giving the
`(W/S)_TO`-vs-`(W/P)_TO,continuous` table: 20/28.1, 30/24.3, 40/21.9, 50/20.1 (take-off `W/P` = these
x1.1, a typical piston-engine max-takeoff/max-continuous power ratio) [Roskam, p. 135-136].

For FAR 23.67 (stopped-propeller drag polar `CD` = 0.0300 + `CL^2`/20.1 for the live-engine
climb, `(CL^3/2/CD)_max` = 13.0, at 5,000 ft): `(W/S)_TO`-vs-`(W/P)_TO,one-engine,5000ft` table:
20/35.2, 30/27.7, 40/23.4, 50/20.5; two-engine sea-level equivalent (x2, then x0.85 for the 5,000-ft
power lapse) gives `(W/P)_TO,two-engine,sls` = 15.0, 11.8, 9.9, 8.8. [Roskam, Fig. 3.24, p. 137]
plots all three requirements (23.65, 23.67, 23.77) as `(W/P)_TO`-versus-`(W/S)_TO` curves; the OEI
(23.67) requirement is the tightest for this airplane [Roskam, p. 136, 139].

**Climb gradient.** For FAR 23.65: `CGR` = 1/12 = 0.0833, take-off `CL_max` = 1.8, climb margin
`delta_CL` = 0.2 gives climb `CL` = 1.6, `L/D` = 9.6, `CGRP` = 0.1482, `(W/P)*(W/S)^0.5` = 102.4,
giving `(W/S)_TO`-vs-`(W/P)_TO,max continuous` (and max take-off, x1.1) table: 20/22.9(20.8),
30/18.7(17.0), 40/16.2(14.7), 50/14.5(13.2) [Roskam, p. 138].

For FAR 23.77: `CGR` = 1/30 = 0.0333, landing `CL_max` = 2.0, climb `CL` = 1.8, `L/D` = 6.8, `CGRP` =
0.1345, `(W/P)*(W/S)^0.5` = 113, giving `(W/S)_TO`-vs-`(W/P)_TO,take-off` table: 20/25.3, 30/20.6,
40/17.9, 50/16.0. Fig. 3.24 compares all four sizing lines; FAR 23.67 (OEI) remains the most critical
[Roskam, p. 139].

### §3.4.6 Summary of FAR 25 Climb Requirements

FAR 25 climb requirements (Ref. 8) also cover take-off and balked landing, with turbine thrust/power
rated at 34% humidity, standard temperature + 50 F, and reciprocating engines at 80% humidity at or
below standard temperature (FAR 25.101) [Roskam, p. 140].

**§3.4.6.1 FAR 25.111 (OEI), first take-off segment:** climb gradient with the critical engine out
must be >= 1.2% (two engines), 1.5% (three), or 1.7% (four), at: take-off flaps, gear retracted,
`V2` = 1.2*`V_S1_TO`, remaining engines at take-off thrust/power, between 35 ft and 400 ft (ground
effect matters), ambient conditions, maximum take-off weight [Roskam, p. 140].

**§3.4.6.2 FAR 25.121 (OEI), second segment:** gradient must be positive (two engines), >= 0.3%
(three), or >= 0.5% (four), at: take-off flaps, gear down, remaining engines at take-off
thrust/power, between `V_LOF` and `V2`, in ground effect, ambient conditions, maximum take-off
weight. The final take-off segment ("en-route climb, OEI") demands gradient >= 1.2%/1.5%/1.7% (two/
three/four engines) at: flaps retracted, gear retracted, remaining engines at maximum continuous
thrust/power, `1.25*V_S1`, ambient conditions, maximum take-off weight [Roskam, pp. 140-141]. There
is no AEO take-off climb requirement in FAR 25 — the OEI requirements are already severe enough that
AEO climb is not limiting [Roskam, p. 142].

**§3.4.6.3 FAR 25.119 (AEO, balked landing):** gradient >= 3.2% at the thrust/power level reached 8
seconds after moving the throttles from flight idle to take-off, with: landing flaps, gear down,
`1.3*V_S0`, ambient conditions, maximum design landing weight [Roskam, p. 142].

**§3.4.6.4 FAR 25.121 (OEI, balked landing/approach climb):** gradient >= 2.1% (two engines), 2.4%
(three), 2.7% (four), with: approach flaps, gear per normal AEO procedure, no more than `1.5*V_S0`
(and `V_S0` no more than `1.1*V_S1_A`), remaining engines at take-off thrust/power, ambient
conditions, maximum design landing weight [Roskam, p. 142].

### §3.4.7 Sizing to FAR 25 Climb Requirements

For propeller airplanes, use Eqs. (3.23) and (3.28) as in §3.4.3. For jets, with one engine
inoperative [Roskam, Eq. (3.31a), p. 143]:

```
(T/W) = N/(N-1) * [1/(L/D) + CGR]
```

or all engines operating [Roskam, Eq. (3.31b), p. 143]:

```
(T/W) = 1/(L/D) + CGR
```

where `CGR` is the required climb gradient (equal to the flight-path angle for small angles), `N` is
the number of engines, and `L/D` is evaluated at the flight condition and configuration the
requirement specifies. `T/W` and `L/D` must both correspond to the same take-off or landing
condition being checked [Roskam, p. 143].

### §3.4.8 Example of FAR 25 Climb Sizing

Size a twin-engine jet transport, `W_TO` = 125,000 lbs, `W_L` = 115,000 lbs, against the FAR 25
climb set (§3.4.6): 25.111 OEI (`CGR` >= 0.012, gear up/t.o. flaps/take-off thrust/ground effect/
1.2*`V_S1_TO`); 25.121 OEI second segment (`CGR` >= 0, gear down/t.o. flaps/take-off thrust/ground
effect/between `V_LOF` and 1.2*`V_S1_TO`); 25.121 OEI en-route (`CGR` >= 0.024, gear up/t.o.
flaps/no ground effect/take-off thrust/1.2*`V_S1_TO`); 25.121 OEI en-route clean (`CGR` >= 0.012,
gear up/flaps up/max continuous thrust/1.25*`V_S1`); 25.119 AEO balked landing (`CGR` >= 0.032, gear
down/landing flaps/take-off thrust, all engines/max design landing weight/1.3*`V_S0`); 25.121 OEI
approach climb (`CGR` >= 0.021, gear down/approach flaps/take-off thrust/1.5*`V_S0`) [Roskam, pp.
144-147].

Drag polar: from Fig. 3.22b, `S_wet` ~= 8,000 ft^2 at `W_TO` = 125,000 lbs; `Cf` = 0.0030 gives `f` =
23 ft^2; average `W/S` = 100 psf gives `S` = 1,250 ft^2, `CD_0` = 0.0184. Assumed polars:

| Configuration | `CD_0` | `A` | `e` | `CD` | `CL_max` |
|---|---|---|---|---|---|
| Clean | 0.0184 | 10 | 0.85 | `CD_0`+`CL^2`/26.7 | 1.4 |
| Take-off flaps | 0.0334 | 10 | 0.80 | `CD_0`+`CL^2`/25.1 | 2.0 |
| Landing flaps | 0.0784 | 10 | 0.75 | `CD_0`+`CL^2`/23.6 | 2.8 |
| Gear down | +0.0150 increment | — | no effect | — | — |

Working through each requirement (each `(T/W)_TO` corrected for the 50 F temperature effect,
factor 0.80 relative to standard-day maximum thrust, and where noted for max-continuous-vs-max-
takeoff thrust, factor 0.94, and for the landing-to-takeoff weight ratio):

- FAR 25.111 OEI: `CL` = 1.4, `L/D` = 12.6, `(T/W)_TO` = 2*(1/12.6+0.012) = 0.182, corrected to
  0.182/0.8 = 0.23.
- FAR 25.121 OEI 2nd segment: `CL_LOF` = 1.65, `L/D` = 10.5 at `V_LOF` (governing case, more
  critical than at `V2` where `L/D` = 11.1); `(T/W)_TO` = 2*(1/10.5) = 0.19, corrected to
  0.19/0.8 = 0.24.
- FAR 25.121 OEI en-route (t.o. flaps): `CL` = 1.4, `L/D` = 12.6, `(T/W)_TO` = 2*(1/12.6+0.024) =
  0.21, corrected to 0.21/0.8 = 0.26.
- FAR 25.121 OEI en-route (clean): `CL` = 0.9, `L/D` = 18.5, `(T/W)_TO` = 2*(1/18.5+0.012) = 0.136,
  corrected for max-continuous-to-max-takeoff-thrust (0.94) and temperature (0.8):
  0.136/0.94/0.8 = 0.18.
- FAR 25.119 AEO balked landing: `CL` = 1.66, `L/D` = 7.9, `(T/W)_L` = 1/7.9+0.032 = 0.16, converted
  to take-off weight and temperature: 0.16*(115,000/125,000)/0.8 = 0.19.
- FAR 25.121 OEI approach climb: `CL_PA` = 1.07, drag increment halfway between take-off and
  landing flaps giving `CD` = 0.0709+`CL^2`/23.6, `L/D` = 9.0, `(T/W)_L` = 2*(1/9.0+0.021) = 0.26,
  converted: 0.26*(115,000/125,000)/0.8 = 0.30 — the most critical of the six requirements for this
  airplane.

[Roskam, Fig. 3.25, p. 148] plots all six `(T/W)_TO` sizing lines against `(W/S)_TO` (each shown as
a horizontal boundary line at its respective `(T/W)_TO` value: 0.23 for 25.111 OEI, 0.24 and 0.26 for
the two 25.121 OEI take-off-configuration cases, 0.18 for 25.121 OEI en-route clean, 0.19 for 25.119
AEO balked landing, 0.30 for 25.121 OEI approach climb — matching the values derived above), with the
approach-climb line the governing (highest) requirement. A note on the chart flags that the data are
valid only for the specific aerodynamic assumptions tabulated above.

### §3.4.9 Summary of Military Climb Requirements

Military climb-rate/gradient minima usually come from the RFP; MIL-C-005011B (Reference 15) gives
generic single-engine requirements, applicable at `W_TO` with external stores fitted [Roskam, p.
149]:

1. **Take-off climb:** (a) Ref. 15 par. 3.4.2.4.1: at `V_TO` = 1.1*`V_S1_TO`, climb gradient >= 0.005,
   gear down/take-off flaps/maximum power. (b) Ref. 15 par. 3.4.2.5: at the 50-ft obstacle and
   1.15*`V_S1_TO`, climb gradient >= 0.025, gear up/take-off flaps/maximum power.
2. **Landing climb:** Ref. 15 par. 3.4.2.11: at the 50-ft obstacle and 1.2*`V_PA`, climb gradient >=
   0.025, gear up/approach flaps/maximum dry power.

These can be sized with the §3.4.7 method. Military airplanes frequently also carry time-to-climb
and ceiling requirements (§3.4.10) and, for fighters, specific-excess-power requirements (§3.4.11)
[Roskam, p. 149-150].

### §3.4.10 Sizing to Time-to-Climb and Ceiling Requirements

**§3.4.10.1 Time-to-climb.** [Roskam, Fig. 3.26, p. 151] shows the assumed linear relationship
between rate of climb `RC` and altitude, running from `RC_0` (sea-level rate of climb) down to zero
at the absolute ceiling `h_abs` — an idealization; whether it holds depends on the engine, airplane,
and climb speed used. This gives [Roskam, Eq. (3.32), p. 150]:

```
RC = RC_0 * (1 - h/h_abs)
```

[Roskam, Table 3.7, p. 151] gives typical `h_abs` [x1,000 ft] by propulsion type: piston-propeller
normally aspirated 12-18, supercharged 15-25; turbojet/turbofan commercial 40-50, military 40-55,
fighters 55-75, military trainers 35-45; turboprop/propfan commercial 30-45, military 30-50;
supersonic cruise (jets) 55-80.

Given a required time-to-climb `t_cl` to altitude `h`, and an assumed `h_abs` (from Table 3.7 or the
mission spec), the required sea-level rate of climb is [Roskam, Eq. (3.33), p. 150]:

```
RC_0 = (h_abs / t_cl) * ln[1 / (1 - h/h_abs)]
```

`RC_0` then sets the required power or thrust loading:

- Propeller airplanes: use Eqs. (3.23)-(3.24) as before.
- Jet airplanes, best-climb-rate case: [Roskam, Eq. (3.34), p. 152]:

```
RC = V * [(T/W) - 1/(L/D)]
```

Maximizing `RC` means maximizing `L/D`, achieved at [Roskam, Eqs. (3.35)-(3.36), p. 152]:

```
V = [2*(W/S) / (rho * (CD_0*pi*A*e)^(1/2))]^(1/2)
(L/D)_max = 0.5 * (pi*A*e/CD_0)^(1/2)
```

For steep climbs (fighters), use the flight-path-angle form instead [Roskam, Eqs. (3.37)-(3.39), p.
152]:

```
RC = V * sin(gamma)                                                              (3.37)

sin(gamma) = (T/W) * [ P_dl - [ P_dl^2 - P_dl + {1 + (L/D)^2}^(-1) ]^(1/2) ]     (3.38)

P_dl = (L/D)^2 / {1 + (L/D)^2}                                                   (3.39)
```

`P_dl` is the parameter in `sin(gamma)` defined by Eqs. (3.38) and (3.39) [Roskam, Table of
Symbols, p. vi]. For best climb performance, `L/D` in Eq. (3.39) is taken as `(L/D)_max`.
This steep-climb case applies to fighter-type airplanes only.

**§3.4.10.2 Ceiling requirements.** A required minimum rate of climb is specified at the ceiling
altitude. [Roskam, Table 3.8, p. 153] defines ceiling types and their minimum climb rates: absolute
ceiling 0 fpm; service ceiling (commercial piston-prop) 100 fpm, (commercial jet) 100 fpm, (military
max power) 500 fpm; combat ceiling (military subsonic max power) 500 fpm at M<1 / 1,000 fpm at M>1;
cruise ceiling (military subsonic max continuous power) 300 fpm at M<1 / 1,000 fpm at M>1. The same
Eqs. (3.23)-(3.24) (propeller) or (3.34)-(3.36) (jet) then give the `(T/W)_TO`-`(W/S)_TO` region
meeting the ceiling requirement [Roskam, p. 152-154].

### §3.4.11 Sizing to Specific Excess Power Requirements

Specific excess power is [Roskam, Eqs. (3.40)-(3.41), p. 154]:

```
Ps = dh_e/dt = (T - D)*V / W
h_e = specific energy = V^2/(2g) + h
```

Fighter airplanes may need a specified `Ps` at a given Mach, weight, and altitude, to guarantee
combat superiority. Eq. (3.40) shows `Ps` is maximized by high `T/W` and high `L/D`. For preliminary
sizing, assume a realistic range of `L/D` values, then use Eq. (3.40) to back out the required
`T/W`; convert this flight-condition `T/W` to `(T/W)_TO` using engine lapse-rate data [Roskam, p.
154].

### §3.4.12 Example of Sizing to Military Climb Requirements

An attack fighter (mission spec of Table 2.19) must meet: (1) `RC` >= 500 fpm, one engine out, sea
level, 95 F, maximum take-off weight including external stores; (2) time-to-climb `t_cl` = 8 min to
40,000 ft, clean, maximum clean take-off weight; (3) `Ps` >= 80 fps at 40,000 ft and M = 0.8, clean,
maximum clean take-off weight [Roskam, p. 155].

Drag polar: `W_TO` = 64,500 lbs with stores (from Chapter 2, p. 67); clean `W_TO` = 64,500-10,000 =
54,500 lbs. Fig. 3.22c gives clean `S_wet` = 3,500 ft^2; `Cf` = 0.0030 gives `f` = 10.5 ft^2. Average
`W/S` = 50 psf gives `S` = 1,090 ft^2, `CD_0` = 10.5/1,090 = 0.0096. External stores add `delta_f` =
3.2 ft^2, i.e. `delta_CD_0` = 3.2/1,090 = 0.0030. Assumed: `A` = 4; `e` = 0.8 clean, 0.7 take-off
flaps; take-off-flaps `delta_CD_0` = 0.0200; compressibility drag increment at M = 0.8, clean,
`delta_CD_0` = 0.0020. Resulting polars [Roskam, p. 156]:

```
Clean, low speed:      CD = 0.0096 + 0.0995*CL^2
Clean, M = 0.8:        CD = 0.0116 + 0.0995*CL^2
Take-off, gear up:     CD = 0.0296 + 0.1137*CL^2
```

**Requirement 1 (OEI rate of climb, with stores).** Best climb at `(L/D)_max` = 8.6 (from Eq. 3.36).
At 95 F, temperature ratio 554.7/518.7 = 1.069, `sigma` = 1/1.069 = 0.935, `rho` = 0.002224
slug/ft^3. Table (from Eqs. 3.34-3.35), for `(W/S)_TO` = 40/60/80/100 psf: `V` = 265/325/375/420 fps;
`RC/V` = 0.031/0.026/0.022/0.020; one-engine `(T/W)_TO` (Eq. 3.35 form) = 0.147/0.142/0.138/0.136;
two-engine sea-level-standard equivalent (x2) = 0.294/0.284/0.276/0.272; two-engine 95F-day (further
x0.85 for the thrust lapse at 95 F relative to standard sea level) = 0.346/0.334/0.325/0.320.
[Roskam, Fig. 3.27, p. 159] plots this "engine-out" boundary along with the other two requirements
below [Roskam, pp. 156-157].

**Requirement 2 (time-to-climb, clean).** Assumed absolute ceiling 45,000 ft; Eq. (3.33) gives `RC_0`
= (45,000/8)*ln(1-40/45) = 12,359 fpm = 206 fps. Because this is a steep-climbing fighter, Eqs.
(3.37)-(3.39) are used rather than Eq. (3.34). With `CD_0` = 0.0096, Eq. (3.36) gives `(L/D)_max` =
16.2; Eq. (3.39) gives `P_av` = 0.996; combining with Eqs. (3.37)-(3.38): `RC_0` = 0.996*V*(T/W)^(1/2)
[reduced form as stated in text]. Table for `(W/S)_TO` clean/with-stores (x1.18, the ratio of
64,500/54,500 lbs) = 40/47, 60/71, 80/95, 100/118 psf; `V` (Eq. 3.35) = 329/403/465/520 fps; `(T/W)_TO`
clean (with-stores, /1.18) = 0.629(0.531), 0.514(0.434), 0.445(0.376), 0.398(0.336) [Roskam, pp.
157-158].

**Requirement 3 (Ps at 40,000 ft, M=0.8, clean).** Rearranged Eq. (3.40): `(T/W)` = 80/V +
1/(L/D). At 40,000 ft, M=0.8: `q` = 1,482*0.1851*M^2 = 176 psf. Clean drag polar at M=0.8, clean
max weight 54,500 lbs. Table for `(W/S)_TO` clean = 40/60/80/100 psf: `CL` = 0.23/0.34/0.45/0.57;
`CD` = 0.0169/0.0231/0.0317/0.0439; `L/D` = 13.6/14.7/14.2/13.0; `V` = 774 fps (all rows); `(T/W)` at
40K/M=0.8 = 0.177/0.171/0.173/0.180; converted to `(T/W)_TO` at sea-level-standard by the altitude
pressure ratio (x5.4, approximating the thrust ratio between the two conditions since high-altitude
subsonic thrust changes little between M=0 and M=0.8) = 0.96/0.92/0.93/0.97 (using the
with-stores `(W/S)_TO` values 47/71/95/118 psf) [Roskam, pp. 158-159].

[Roskam, Fig. 3.27, p. 159] plots all three requirements as `(T/W)_TO`-versus-`(W/S)_TO` boundary
curves labeled "engine-out," "time-to-climb," and "`Ps` = 80 fps at 40,000 ft" (the last essentially
flat near `(T/W)_TO` ~= 0.92-0.97 across the plotted range), together with the maneuvering
requirement of Sub-section 3.5.1 (outside this extract) for reference; the `Ps` requirement is by far
the most critical of the three for this airplane, sitting far above the engine-out and time-to-climb
boundaries.

## Notes on figures not separately digitized

Figures 3.10 (catapult weight-vs-speed families) and 3.21/3.22 (parasite-area and wetted-area
correlation plots) are purely the graphical form of numeric relations already captured above as
tables/equations (Table in the C13 catapult example, Eq. (3.21)/Table 3.4, and Eq. (3.22)/Table
3.5) — the correlation-line coefficients given are what the plots exist to convey, so no additional
point-reading was needed. Figures 3.2, 3.6, 3.12, and 3.16 (take-off/landing distance definition
sketches) and the British Aerospace Hawk and SAAB-Fairchild 340 illustrations on pp. 117 and 133
are purely illustrative, with no plotted trend data.
