# Chapter 9 — High-Lift Devices

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 9 "High-Lift Devices," printed pp. 221–256.

Text-layer inventory (to confirm completeness): Figs 9.1–9.33 (incl. 9.29a), Tables 9.1–9.3,
Eqs (9.1)–(9.13) (incl. 9.4a/9.4b).

---

## §9.1 Introduction
*[Nicolai & Carichner, p. 222]*

To increase wing lift, suction on the upper surface must increase relative to the lower surface
(Fig. 2.3) and separation must be delayed/prevented. Suction is increased by raising angle of
attack and by making the airfoil camber more positive near the trailing edge (TE). A TE flap (and,
to a small extent, a leading-edge/LE flap) effectively increases camber and upper-surface flow
acceleration (and circulation), increasing `C_L` — observed as an increase in the magnitude of the
zero-lift angle `α_0L`. Separation is prevented by reducing the adverse pressure gradient or by
stabilizing the boundary layer via suction or blowing.

High-lift devices fall into two categories: **unpowered/mechanical** and **powered-lift**.
Mechanical devices are (1) TE flaps (increase camber) and (2) separation-delay devices (LE flaps,
slats, slots, plus boundary-layer control). This chapter covers mechanical devices in detail.
Powered-lift concepts (briefly discussed at chapter end, for V/STOL): internal/external blown
flaps, deflected slipstream, upper surface blowing, jet flap, lift-fan, tilt wing, direct jet lift,
augmentor wing.

## §9.2 Mechanical High-Lift Devices: Trailing Edge Flaps
*[Nicolai & Carichner, p. 222]*

TE flaps operate by changing airfoil-section camber (Fig. 9.1); camber made more positive near the
TE has a powerful influence making `α_0L` more negative [1–3] (a camber change near the LE has only
a small influence on `α_0L`). Section lift coefficient:

**Eq (9.1)** *[Nicolai & Carichner, Eq. (9.1), p. 222]*:
```
C_l = (dC_l/dα)·(α - α_0L) = C_lα·(α - α_0L)
```
where `α` is the angle between the unflapped section chord line and freestream velocity.

### Fig 9.1 — Typical TE high-lift devices
*[Nicolai & Carichner, Fig. 9.1, p. 223]* — Five airfoil-section schematics: Plain Flap or Aileron,
Split Flap, External Airfoil Flap (Fowler), Slotted Flap, Double-Slotted Flap. Plus photo: Boeing
747 with triple-slotted flaps extended. Note: an aileron is nothing more than a plain flap operated
with both positive and negative deflections. Fowler/double-slotted flaps increase effective wing
area slightly, but `C_Lmax` is referenced to the baseline unflapped wing reference area. No
plotted numeric data (schematic + photo).

TE flaps do not prevent flow separation — they slightly aggravate it (decrease `α_stall` slightly,
Fig. 9.2), due to increased leading-edge upwash from increased circulation. Wing sweep promotes
stall (Ch. 2); TE flaps become less effective as sweep increases (correction shown in Fig. 9.23).
TE flaps are very effective on wings swept up to about 35°.

### Fig 9.2 — Characteristics of TE flaps
*[Nicolai & Carichner, Fig. 9.2, p. 223]* — Three qualitative panels comparing "no flaps" vs "with
flaps": (a) `C_L` vs `α` — flapped curve shifted left/up by `Δα_0L`, slightly lower `α_stall`; (b)
`C_L` vs `C_D` — flapped curve shows higher `C_L` at a given `C_D` (drag polar shifted up); (c)
`C_L` vs `C_Mac` — flapped curve shows a more negative (further into "-" direction) `C_Mac`. All
qualitative trend curves, no plotted values (read from plot not applicable — schematic-style
trend figure).

## §9.3 Mechanical High-Lift Devices: Separation Delay Devices
*[Nicolai & Carichner, p. 223]*

Flow separation (stall) results from loss of kinetic energy in the boundary layer due to viscous
shear and an adverse pressure gradient [4]. A turbulent boundary layer delays separation better
than laminar (higher energy from turbulence) — better to have a turbulent boundary layer over the
airfoil for lift at high alpha. Vortex generators are placed on the wing top surface to force early
laminar-to-turbulent transition. Boundary layer usually transitions at `Re` of one million.

### Fig 9.3 — Variation of maximum section lift coefficient with Reynolds number
*[Nicolai & Carichner, Fig. 9.3, p. 224]* — `C_lmax` vs Reynolds number (log scale, 10⁵–10⁷) for
four NACA sections: 0018, 0015, 0012, 0009. *(read from plot)*:

| Re | NACA 0018 | NACA 0015 | NACA 0012 | NACA 0009 |
|---|---|---|---|---|
| 1×10⁵ | 0.80 | 0.80 | 0.80 | 0.72 |
| 2×10⁵ | 0.87 | 0.83 | 0.80 | 0.80 |
| 4×10⁵ | 0.97 | 0.93 | 0.82 | 0.82 |
| 8×10⁵ | 1.05 | 1.10 | 0.83 | 0.82 |
| 2×10⁶ | 1.22 | 1.22 | 1.20 | 0.83 |
| 4×10⁶ | 1.38 | 1.45 | 1.32 | 0.90 |
| 6×10⁶ | 1.46 | 1.55 | 1.42 | 1.22 |
| 8×10⁶ | 1.46 | 1.60 | 1.46 | 1.33 |

### §9.3.1 Boundary Layer Control
*[Nicolai & Carichner, p. 224]*

Boundary layer control (BLC) energizes the boundary layer via suction or blowing so it can better
fight the adverse pressure gradient and delay separation. Not discussed further here because: (1)
numerous papers on the subject already exist; (2) significant operational issues dominate the
system — large pump power requirements, heavy maintenance to keep suction holes/slots clear, and
suction holes/slots causing rough surface / large drag at high speed if inoperative.

### §9.3.2 Slots and Slats
*[Nicolai & Carichner, p. 225]*

A slot or slat (movable slot) operates as in Fig. 9.4: the LE shape in the slot/slat is more blunt,
accelerating the through-flow air so it moves farther toward the airfoil's rear before slowing and
separating. Slat operation is manual or automatic (automatic slats deploy at high `C_L` via suction
near the LE — the Douglas A-4 Skyhawk's automatic slats worked well in high-`C_L` maneuvering [5],
though occasionally in a tight turn one wing's slat would pop out asymmetrically, causing a rapid
roll and a surprised pilot; A-4 slats could be manually locked in/out for landing/takeoff).

Principal disadvantage of slots/slats: high `α` required for `C_lmax`; hard to fit on very thin
wings. Best used full-span; main advantage is protecting the outboard wing by reducing tip stall.
Slots/slats continue to give benefit above 45° sweep because they reduce separation (and thus tip
stall) near the tip.

### Fig 9.4 — Characteristics of slots and slats
*[Nicolai & Carichner, Fig. 9.4, p. 225]* — Three panels: (top) airfoil-with-slot schematic showing
accelerated flow through the slot and "Separated Regions" downstream on the main-element upper
surface; (bottom-left) photo, "A300 Leading Edge Slats Extended"; (bottom-right) `C_L` vs Alpha
(deg), −5 to 25°, two curves "Slot Closed" (peaks ~12° then drops) vs "Slot Open" (continues rising
to ~20–22° before dropping) *(read from plot)*:

| Alpha (deg) | C_L, Slot Closed | C_L, Slot Open |
|---|---|---|
| -5 | ~-0.35 | ~-0.35 |
| 0 | 0.15 | 0.15 |
| 5 | 0.65 | 0.65 |
| 10 | 1.10 | 1.10 |
| 12 | 1.20 (peak, closed) | 1.25 |
| 15 | 0.95 (post-stall) | 1.45 |
| 20 | — | 1.65 (near peak) |
| 22 | — | 1.68 (peak) |
| 25 | — | 1.55 (post-stall) |

### §9.3.3 Leading Edge Flaps
*[Nicolai & Carichner, p. 226]*

LE flaps make the leading edge more rounded; work well on sharp-nosed airfoil sections (Fig. 7.6).
Because they change section camber, there's a slight change in `α_0L` (Fig. 9.6). LE flaps are more
effective than slots on highly swept wings [6]; usually employed over the outer half-span to reduce
tip stall. Typical optimum flap deflections: 30–40°.

### Fig 9.5 — Various LE flap devices
*[Nicolai & Carichner, Fig. 9.5, p. 226]* — Five schematics: (a) Drooped Leading Edge; (b) Upper
Surface Leading Edge Flap; (c) Lower Surface Leading Edge Flap; (d) Flap Hinged About Leading Edge
Radius; (e) 747 Variable Camber Leading Edge Krueger Flap — three-stage illustration (Krueger flap
in Stored Position for Cruise Flight; During Extension, showing Fiberglass Skin Panel; Fully
Extended Position, "Operate Below 250 KEAS," Minimum Radius of Curvature 12 in.). No plotted
numeric data (schematic).

### Fig 9.6 — Characteristics of LE flaps
*[Nicolai & Carichner, Fig. 9.6, p. 226]* — `C_L` vs Alpha (deg), two curves "LE Flap Retracted"
(lower, earlier stall) vs "LE Flap Extended" (shifted up/right, higher stall angle and higher
`C_Lmax`) — both nearly coincident at low alpha, diverging near stall. Plus photo: "Boeing 737-200
Kruegers Extended." *(read from plot — qualitative trend curves only, no gridded axis values
given.)*

### §9.3.4 Practical Mechanical High-Lift Systems
*[Nicolai & Carichner, p. 227]*

Mechanical high-lift devices integrate into practical systems meeting takeoff/landing/maneuvering
requirements. Low-speed `C_Lmax` usually driven by runway-length requirements at airports of
interest — but `C_Lmax` must be **usable**: available within the limits of over-nose vision angle
and tip-back angle (Table 8.4, Fig. 8.3). A `C_Lmax` of 3.0 at `α=30°` is of little value if the aft
fuselage strikes the ground at `α=16°`. Typical takeoff/landing angle-of-attack limits (due to
tip-back angle and over-nose vision): **12–16° fighters**, **10–14° transports**, **8–12° general
aviation**.

Fighters usually have high `T/W` (typically >0.5) so takeoff isn't a problem — landing distance
sets `C_Lmax`. Transports have lower `T/W` (typically <0.35); either takeoff or landing can set
`C_Lmax`. GA aircraft with low wing loadings don't need much `C_Lmax` for 3000-ft-field operation.

Typical measured slot/slat/LE-flap/TE-flap data: Tables 9.1–9.3. Fig. 9.7 shows practical low-speed
`C_Lmax` limits for mechanical high-lift systems (reference area stays the original wing area, not
increased for extended LE/TE flap area). Increasing wing sweep and decreasing AR both decrease
high-lift-system efficiency.

Notable examples: Airbus A321-200 (double-slotted TE Fowler flaps + full-span LE slats) sets the
transport-community standard with `C_Lmax = 3.2`, designed for shorter regional-hub runways.
Transport aircraft typically have thick airfoils (~10%+), accommodating sophisticated internal
high-lift machinery. Fighters (Fig. 9.7) have thinner airfoils, simpler devices (split/plain TE
flaps, drooped LE flaps). GA aircraft (Piper PA-30, Cessna 177 Cardinal) have takeoff wing loadings
<20 psf, short-field operation, simple plain-flap systems. **U-2S**: takeoff `T/W > 0.35`,
`W/S < 40 psf`, doesn't need high `C_Lmax` — partial-span simple hinged plain flap gives
`C_Lmax = 1.2` at 15° flap deflection; unique bicycle landing gear, does not rotate for takeoff
(same as B-52 and B-47).

### Fig 9.7 — Practical low-speed C_Lmax limits for mechanical high-lift systems
*[Nicolai & Carichner, Fig. 9.7, p. 228]* — `C_Lmax` (0.8–3.2) vs Aspect Ratio (0–12), data points
labeled by aircraft, grouped/color-coded by high-lift device family (icons along bottom: Plain
flap; Plain flap+LE flap; Single-slotted flap+LE slat; Single-slotted flap+LE slot; Simple blown
flap+LE slat; Double-slotted flap; Double-slotted+LE Krueger; Double-slotted+LE slats;
Triple-slotted+LE Krueger; Triple-slotted+LE plain flap; Triple-slotted+LE slat). Data from [7].
*(read from plot, approximate (AR, C_Lmax) pairs)*:

| Aircraft | AR | C_Lmax (approx.) |
|---|---|---|
| A321-200 | 9.5 | 3.2 |
| 737-200 | 8.83 | 3.0 |
| DC-9 | 8.5 | 2.9 |
| 777-200 | 8.7 | 2.8 |
| DHC-4 Caribou | 9.9 | 2.6 |
| 767-200 | 7.9 | 2.75 |
| C-5A | 8.0 | 2.6 |
| 757-200 | 7.77 | 2.8 |
| 747-200 | 7.7 | 2.5 |
| L-1011 | 6.95 | 2.65 |
| 727-200 | 7.1 | 2.6 |
| F-14A | 7.25 | 2.35 |
| S-3A | 7.8 | 2.36 |
| A-6A | 5.3 | 2.05 |
| 707-320 | 7.0 | 2.0 |
| A-3D | 6.75 | 1.9 |
| F-111A | 6.0 | 2.45 |
| B-47 | 9.42 | 2.05 |
| B-52 | 8.56 | 2.0 |
| Piper PA-30 | 7.3 | 1.6 |
| Cessna 177 | 7.4 | 1.55 |
| U-2S | 10.6 | 1.21 |
| EA-6B | 5.5 | 2.0 |
| T-45A | 5.0 | 2.0 |
| RA-5C | 4.0 | 1.9 |
| F11F-1 | 3.95 | 1.75 |
| FA-18A | 3.5 | 1.62 |
| F-16C | 3.2 | 1.7 |
| F-4B | 2.78 | 1.4 |
| A-4E | 2.9 | 1.42 |
| F-5E | 3.7 | 1.4 |
| A-5A | 4.0 | 1.2 |
| F-105D | 3.18 | 1.38 |
| F-8E | 3.5 | 1.2 |
| F-22A | 2.36 | 1.48 |
| F-104G | 2.45 | 1.12 |
| F-117A | 1.65 | 0.95 |

### Table 9.1 — Mechanical High-Lift Systems and Maximum Lift Summary of Current Aircraft
*[Nicolai & Carichner, Table 9.1, p. 229]*

| Aircraft | AR | C_Lmax | Leading Edge | Trailing Edge |
|---|---|---|---|---|
| 707-320 | 7.0 | 2.0 | Full-span plain flap | Triple-slotted Fowler |
| E-6A | 7.0 | 2.16 | Improved 707-320 system | — |
| 727-200 | 7.1 | 2.62 | 1/3 Krueger, 2/3 span slats | Triple-slotted Fowler |
| 737-200 | 8.83 | 3.05 | Krueger IB, slats OB | Triple-slotted Fowler |
| 747-400 | 7.7 | 2.5 | Krueger IB, slats OB | Triple-slotted Fowler |
| 757-200 | 7.77 | 2.8 | Full-span slats | Double-slotted Fowler |
| 767-200 | 7.9 | 2.75 | Full-span slats | Double slot IB, single slot OB |
| 777-200 | 8.7 | 2.8 | Full-span slats | Double slot IB, single slot OB |
| 787 | Var. | NA | Krueger IB, slats OB | Triple-slotted Fowler + variable camber |
| A321-200 | 9.5 | 3.2 | Full span slats | Double slotted Fowler + drooped ailerons |
| L-1011 | 6.95 | 2.65 | Full-span slats | Double-slotted Fowler |
| S-3A | 7.8 | 2.36 | Slats OB of engine | Single-slotted Fowler |
| DC-9 | 8.5 | 2.96 | Full-span slats | Full-span double-slotted flap |
| DHC-4 | 9.9 | 2.63 | None | Full-span double-slotted flap |
| C-5A | 8.0 | 2.64 | Slots IB + slotted slats OB | Partial-span single-slotted Fowler |
| U-2S | 10.6 | 1.21 | None | Partial-span simple hinge flap |
| PA-30 | 7.3 | 1.6 | None | Half-span plain flap |
| Cessna 177 | 7.4 | 1.55 | None | Half-span plain flap |
| B-47 | 9.42 | 2.05 | Full-span slat | Partial-span Fowler |
| B-52G | 8.56 | 2.0 | None | Partial-span Fowler |
| F-16C | 3.2 | 1.7 | Full-span maneuver flap | Half-span plain flap |
| F-22A | 2.36 | 1.48 | Full-span maneuver flap | Full flaperon + drooped aileron |
| A-3D | 6.75 | 1.9 | Full-span slats | Partial-span single-slotted flap |
| F-4B | 2.78 | 1.4 | Full plain flap (blown) | Partial-span blown plain flap |
| A-4E | 2.9 | 1.42 | Automatic LE slats | 1/2 split flap + drooped ailerons |
| RA-5C | 4.0 | 1.9 | Full-span plain flap | Partial-span plain flap (blown OB) |
| F-5E | 3.7 | 1.4 | Full-span plain flap | Partial-span single-slotted flap |
| A-6A | 5.3 | 2.05 | Full-span plain flaps | Partial-span Fowler flap |
| F-14A | 7.25 | 2.35 | Full-span LE slats | Full-span slotted flaps |
| F-111A | 6.0 | 2.45 | Full-span LE slats | Partial-span blown plain flap |
| F-117 | 1.65 | 0.95 | None | None |
| F-18A | 3.5 | 1.62 | Full-span plain flap | Half-span single-slotted TE flap |
| F-105D | 3.18 | 1.38 | Full-span plain flap | Partial-span single-slotted flap |
| F-104G | 2.45 | 1.12 | Full-span plain flap | Blown flap + drooped aileron |
| T-45A | 5.0 | 2.0 | Full-span plain flap | 2/3 span double-slotted flaps |
| F-8E | 3.5 | 1.2 | Full-span plain flap | 2/3 plain flap + variable-incidence wing |
| F-11F | 3.95 | 1.75 | Full-span slats | Full-span plain flaps |

*Note: F-16C row (`AR=3.2, C_Lmax=1.7`, full-span maneuver flap LE + half-span plain flap TE) is
directly relevant to this repo's F-16A Brandt baseline — cross-check against `F16Baseline()`
aerodynamics/geometry fields (F-16C differs slightly from the Block 10/15 F-16A used elsewhere in
this repo, so treat as an approximate cross-check only, not a substitute for Brandt's own numbers).*

### Table 9.2 — Summary of Maximum Lift Coefficient Obtained with Various Types of High-Lift Devices
*[Nicolai & Carichner, Table 9.2, p. 230]* (data from [5,8,9]) — presented as a scatter chart:
`C_Lmax` vs 11 wing-planform cases (each with `Δ_c/4` sweep, AR, taper `λ`, airfoil section labeled
below), plotted per device-combination symbol: Plain Airfoil, Leading Edge Slot, Slat+Split Flap,
Slat+Extended Split Flap, Slat+Double-Slotted Flap, Slat+Plain Flap. Small wing-planform icons along
the bottom show each case's sweep/taper shape.

Per-case parameters and approximate `C_Lmax` range (plain airfoil to best device), *(read from
plot)*:

| Case | Δc/4 | AR | λ | Airfoil | Plain Airfoil C_Lmax | Best-device C_Lmax |
|---|---|---|---|---|---|---|
| 1 | 35° | 6.0 | 0.50 | 64₁-212 | 1.3 | 2.05 (Slat+Plain, "with fuselage on" ~2.0) |
| 2 | 40° | 4.0 | 0.62 | 64₁-112 | 1.05 | 1.75 (Slat+Split flap) |
| 3 | 40° | 3.0 | 0.62 | CIR.ARC | 0.85 | 1.5 (Leading Edge Slot) |
| 4 | 45° | 3.4 | 0.51 | 64₁-A112 | 1.05 | 1.2 (Slat+Split flap) |
| 5 | 45° | 3.5 | 0.50 | 64₁-A112 | 0.95 | 1.2 (20% full-span LE flap analog) |
| 6 | 45° | 3.5 | 0.50 | CIR.ARC | 0.85 | 1.15 (LE droop = LE flap, filled marker) |
| 7 | 45° | 4.0 | 0.60 | 65A006 | 1.05 | 1.15 |
| 8 | 45° | 5.1 | 0.38 | 64-210 | 1.2 | 1.75 (Slat+Double-Slotted, "with fuselage on") |
| 9 | 45° | 8.0 | 0.45 | 63₁-A012 | 1.05 | 1.45 (Slat+Split Flap) |
| 10 | 50° | 2.9 | 0.62 | 64₁-112 | 1.15 | 1.6 (Slat+Extended Split Flap) |
| 11 | 50° | 2.9 | 0.52 | CIR.ARC | 1.05 | 1.3 |
| 12 | 60° | 3.5 | 0.25 | 65A008 | 1.35 | 1.75 (Slat+Extended Split Flap) |

Fig. 9.7 shows increasing `C_Lmax` trend with increasing AR and flap-system sophistication; the
A321-200 represents the current practical limit in mechanical high-lift sophistication.

## §9.4 Methods for Determining Maximum Subsonic C_L of Mechanical Lift Devices
*[Nicolai & Carichner, p. 230]*

Method presented is empirical, gives satisfactory results for the first design-loop iteration [10].
Determine `C_L` vs `α` curve for the basic wing, then correct for mechanical high-lift device
effects.

### Table 9.3 — Typical High-Lift Device Data
*[Nicolai & Carichner, Table 9.3, p. 231]*

**Case 1**: `Δ = 35°`, `AR = 5.76`, `λ = 0.54`, airfoil 10% symmetrical:

| Arrangement | C_Lmax | α_stall (deg) |
|---|---|---|
| Plain wing | 0.90 | 16 |
| 20% full-span split flap, δf=60° | 1.45 | 10.6 |
| 20% full-span slat | 1.38 | 23.6 |
| 20% full-span LE flap | 1.49 | 26.5 |
| 20% full-span split flap + 20% full-span LE flap | 2.01 | 19.7 |

**Case 2**: `Δ = 0°`, `AR = 4.0`, `λ = 1.0`, `Re = 10⁵`, airfoil NACA 0010:

| Arrangement | C_Lmax | α_stall (deg) |
|---|---|---|
| Plain wing | 0.80 | 13 |
| 30% full-span split flap, δf=40° | 1.52 | 10 |
| 20% full-span slat | 1.36 | 24 |

Airfoil section behavior with TE flaps is determined first; construction of `C_l` vs `α` curve
shown in Fig. 9.8. Values of `Δα_0L`, `ΔC_lmax`, and `~Δα_stall` needed to complete the
construction. First step: obtain section `α_0L`, `C_lα`, and `α_stall` from experimental data
(Appendix F or [2,11,12]).

### Fig 9.8 — Construction of section lift curves for TE flaps
*[Nicolai & Carichner, Fig. 9.8, p. 231]* — `C_l` vs alpha: two curves, `δf=0` (baseline, solid)
and `δf>0` (flapped, dashed, shifted left/up), with `α_0L`, `Δα_0L`, `C_lmax`, `ΔC_lmax`,
`α_stall`, `TE Flap Δα_stall` all labeled as the geometric construction quantities. Plus photo:
"Boeing 737 Triple-Slotted Fowler Flaps." No plotted numeric data (construction schematic).

If experimental data on the selected airfoil section cannot be found, use `C_lα = 2π` per radian
and compute `α_0L` using Eq. (2.4) of Chapter 2. Estimate `C_lmax` from Figs. 7.2 or 9.3, then use
Eq. (9.1) to determine `α_stall`.

Decide upon TE flap type, flap-to-chord `cf/c` ratio (Fig. 9.9), and flap deflection `δf` (positive
downward). `Δα_0L` determined per method below (from [10]):

**1. Plain TE flaps.** Change in `α_0L` for flap deflection `δf`:

**Eq (9.2)** *[Nicolai & Carichner, Eq. (9.2), p. 232]*:
```
Δα_0L = -(dC_l/dδf)·(1/C_lα)·δf·K'f
```
where `C_lα` = section lift-curve slope (per radian) from Appendix F; `K'f` = correction for
nonlinear effects (Fig. 9.9); `dC_l/dδf` = change in `C_l` per change in `δf` (Fig. 9.10).

**2. Single-slotted flaps.**

**Eq (9.3)** *[Nicolai & Carichner, Eq. (9.3), p. 232]*:
```
Δα_0L = -(dα/dδf)·δf
```
where `dα/dδf` obtained from Fig. 9.11.

**3. Fowler flaps.** Use the single-slotted-flap method.

**4. Split flap.** *(equation continues top of p. 233)*

### Fig 9.9 — Nonlinear correction for plain TE flaps
*[Nicolai & Carichner, Fig. 9.9, p. 232]* (adapted [10]) — `K'f` vs Flap Deflection `δf` (deg, 0–80)
for `cf/c` = 0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50 — family of curves all starting at `K'f=1.0`
near `δf≈10°`, then decreasing, more steeply for larger `cf/c`. *(read from plot, approximate
values at δf=60°)*:

| cf/c | K'f at δf=60° |
|---|---|
| 0.10 | 0.80 |
| 0.15 | 0.72 |
| 0.20 | 0.66 |
| 0.25 | 0.62 |
| 0.30 | 0.58 |
| 0.40 | 0.52 |
| 0.50 | 0.47 |

### Fig 9.10 — Variation of dC_l/dδf with flap chord ratio
*[Nicolai & Carichner, Fig. 9.10, p. 233]* (adapted [10]) — `dC_l/dδf` (per radian, 2–6) vs `cf/c`
(0–0.5), family of curves by `t/c` = 0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.15 (curves closely
bunched, increasing slightly with `t/c`). Inset shows flap geometry (`c`, `cf`, deflection `δ`).
*(read from plot, approximate mid-t/c curve)*:

| cf/c | dC_l/dδf (per rad) |
|---|---|
| 0.1 | 2.9 |
| 0.2 | 4.0 |
| 0.3 | 4.7 |
| 0.4 | 5.1 |
| 0.5 | 5.4 |

**Eq (9.4)** *[Nicolai & Carichner, Eq. (9.4), p. 233]* — for split flaps (continuing item 4):
```
Δα_0L = (k/C_lα)·(ΔC_l)_(cf/c=0.2)
```
where `k` and `(ΔC_l)_(cf/c=0.2)` are obtained from Fig. 9.12.

### Fig 9.11 — Section lift effectiveness parameter for single-slotted flaps
*[Nicolai & Carichner, Fig. 9.11, p. 233]* (adapted [10]) — `dα_0L/dδf` vs Flap Deflection (deg,
0–80) for `cf/c` = 0.15, 0.20, 0.25, 0.30, 0.40 — all curves start near 0 at `δf=0`, become more
negative, flattening out past `δf≈50-60°`. Inset shows slotted-flap geometry. *(read from plot,
approximate asymptotic values at δf=80°)*:

| cf/c | dα_0L/dδf at δf=80° |
|---|---|
| 0.15 | -0.10 |
| 0.20 | -0.15 |
| 0.25 | -0.18 |
| 0.30 | -0.20 |
| 0.40 | -0.22 |

### Fig 9.12 — Empirical constants for split flap analysis
*[Nicolai & Carichner, Fig. 9.12, p. 234]* (adapted [10]) — Two panels: (left) `(ΔC_l)_(cf/c=0.2)`
vs Flap Deflection `δf` (deg, 0–60) for `t/c` = 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, bounded by
an "Upper Limit" curve above and a "Flat Plate (Theoretical)" dashed line below; (right) `K` vs
`cf/c` (0.1–0.4), single monotonically increasing curve from ~0.75 to ~1.35. Inset shows split-flap
geometry (`c`, `cf`, `δf`). *(read from plot, approximate t/c=0.16 curve, left panel)*:

| δf (deg) | (ΔC_l)_(cf/c=0.2), t/c=0.16 |
|---|---|
| 0 | 0 |
| 20 | 0.75 |
| 40 | 1.15 |
| 60 | 1.45 |

*(read from plot, right panel)*:

| cf/c | K |
|---|---|
| 0.1 | 0.75 |
| 0.2 | 1.00 |
| 0.3 | 1.15 |
| 0.4 | 1.35 |

Now construct the `C_l` vs `α` curve (Fig. 9.8). TE flaps aggravate separation slightly and section
`α_stall` decreases — obtained from Fig. 9.13. Estimate `ΔC_lmax` from the completed curve.

At subsonic speeds, distinguish low-AR vs high-AR wings — two different parameter sets describe
wing characteristics in each regime. High-AR wing `C_Lmax` is determined by airfoil-section
properties; low-AR wing `C_Lmax` is primarily dependent on planform shape. High-AR wing defined by:

**Eq (9.4a)** *[Nicolai & Carichner, Eq. (9.4a), p. 235]*:
```
AR > 4 / [(C1+1)·cos(Δ_LE)]
```
Low-AR wing defined by:

**Eq (9.4b)** *[Nicolai & Carichner, Eq. (9.4b), p. 235]*:
```
AR < 4 / [(C1+1)·cos(Δ_LE)]
```
where `C1` is a function of taper ratio, obtained from Fig. 9.14.

For high-AR wings, basic-wing `C_Lmax` and `α_stall`:

**Eq (9.5)** *[Nicolai & Carichner, Eq. (9.5), p. 235]*:
```
C_Lmax = (C_Lmax/C_lmax)·C_lmax
```

**Eq (9.6)** *[Nicolai & Carichner, Eq. (9.6), p. 235]*:
```
α_stall = (C_Lmax/C_lα) + α_0L + Δα_CLmax
```
where `(C_Lmax/C_lmax)` obtained from Fig. 9.15; `C_lα` = wing lift-curve slope from Eq. (2.13)
(Chapter 2); `α_0L` = section angle for zero lift; `Δα_CLmax` obtained from Fig. 9.16; `C_lmax` =
unflapped section max lift coefficient from the Fig. 9.8 construction.

### Fig 9.13 — Decrease in stall angle with flap deflection
*[Nicolai & Carichner, Fig. 9.13, p. 235]* (data from [2]) — `Δα_stall` (deg, 0 to -6) vs `δf` (deg,
0–60), single curve, monotonically decreasing (more negative) with increasing `δf`, mild slope at
low `δf` steepening past ~40°. *(read from plot)*:

| δf (deg) | Δα_stall (deg) |
|---|---|
| 0 | 0 |
| 20 | -1.0 |
| 40 | -2.6 |
| 50 | -3.8 |
| 60 | -5.9 |

### Fig 9.14 — Taper ratio correction factors
*[Nicolai & Carichner, Fig. 9.14, p. 236]* (adapted [10]) — `C1, C2` vs taper ratio `λ` (0–1.0):
`C1` peaks near `λ≈0.25` (~0.78) then decays to ~0 by `λ=0.9`; `C2` peaks near `λ≈0.4` (~1.1) then
decays gently to ~0.8 at `λ=1.0`. *(read from plot)*:

| λ | C1 | C2 |
|---|---|---|
| 0 | 0 | 0 |
| 0.1 | 0.55 | 0.55 |
| 0.2 | 0.75 | 0.90 |
| 0.25 | 0.78 | 1.00 |
| 0.4 | 0.65 | 1.10 |
| 0.6 | 0.40 | 1.02 |
| 0.8 | 0.15 | 0.90 |
| 1.0 | 0.02 | 0.82 |

Figs. 9.15 and 9.16 use `Δy` — a leading-edge sharpness parameter presented in Fig. 9.17.

For low-AR wings, basic-wing `C_Lmax` and `α_stall`:

**Eq (9.7)** *[Nicolai & Carichner, Eq. (9.7), p. 236]*:
```
C_Lmax = (C_Lmax)_base + ΔC_Lmax
```

**Eq (9.8)** *[Nicolai & Carichner, Eq. (9.8), p. 236]*:
```
α_stall = (α_CLmax)_base + Δα_CLmax
```
where `(C_Lmax)_base` from Fig. 9.18; `ΔC_Lmax` from Fig. 9.19; `(α_CLmax)_base` from Fig. 9.20;
`Δα_CLmax` from Fig. 9.21.

### Fig 9.15 — Subsonic maximum lift of high-AR wings
*[Nicolai & Carichner, Fig. 9.15, p. 236]* (adapted [10]) — `C_Lmax/C_lmax` vs Wing Sweep `Λ_LE`
(deg, 0–60), Mach≈0.2, family of curves by `Δy` = ≤1.4, 1.6, 1.8, 2.0, 2.2, 2.4, ≥2.5 — all
converge near 0.9 at `Λ_LE=0`, then fan out: smaller `Δy` curves rise with sweep (up to ~1.3 at
60°), larger `Δy` curves fall (down to ~0.5 at 60°). *(read from plot, endpoints at Λ_LE=60°)*:

| Δy | C_Lmax/C_lmax at Λ_LE=60° |
|---|---|
| ≤1.4 | 1.30 |
| 1.6 | 1.18 |
| 1.8 | 1.02 |
| 2.0 | 0.88 |
| 2.2 | 0.75 |
| 2.4 | 0.62 |
| ≥2.5 | 0.52 |

### Fig 9.16 — Angle-of-attack increment for subsonic maximum lift of high-AR wings
*[Nicolai & Carichner, Fig. 9.16, p. 237]* (adapted [10]) — `Δα_CLmax` (deg, 0–12) vs Wing Sweep
`Λ_LE` (deg, 0–60), `0.2 ≤ Mach ≤ 0.6`, family of curves by `Δy` category: ≤1.2, 2, 3, 4 — curve
"≤1.2" rises steeply to ~12° at 60° sweep; curve "4" stays nearly flat (~1→3°). Inset shows
`C_L` vs `α` schematic defining `Δα_CLmax` as the angle from linear-extrapolation crossing to
actual `C_Lmax`. *(read from plot, endpoints at Λ_LE=60°)*:

| Δy category | Δα_CLmax (deg) at Λ_LE=60° |
|---|---|
| ≤1.2 | 12.0 |
| 2 | 10.0 |
| 3 | 6.7 |
| 4 | 3.2 |

### Fig 9.17 — Variation of LE sharpness parameter with airfoil thickness ratio
*[Nicolai & Carichner, Fig. 9.17, p. 237]* (adapted [10]) — `Δy` (% chord, 0–5) vs Thickness Ratio
`t/c` (0–0.20), lines for: NACA 4-digit & 5-digit Series Airfoils (steepest), NACA 63-Series, 64,
65, 66-Series, Biconvex, Double Wedge (shallowest). Inset defines `Δy` geometrically as the
difference in surface ordinate between 0.15%c and 6.0%c stations. *(read from plot, values at
t/c=0.12)*:

| Airfoil family | Δy (% chord) at t/c=0.12 |
|---|---|
| NACA 4-/5-digit | 3.0 |
| NACA 63-series | 2.15 |
| NACA 64 | 2.05 |
| NACA 65 | 1.95 |
| NACA 66 | 1.85 |
| Biconvex | 1.4 |
| Double Wedge | 0.7 |

### Fig 9.18 — Subsonic maximum lift of low-AR wings
*[Nicolai & Carichner, Fig. 9.18, p. 238]* (adapted [10]) — `(C_Lmax)_base` vs
`(C1+1)·(AR/β)·cos(Λ_LE)` (0–3.6), family of curves by `Δy` = 0, 0.25, 0.50, 0.75, ≥1.0 (left
cluster, peaking near abscissa≈0.7–0.8) continuing into a second labeled cluster (`Δy` = 0.5, 1.0,
≥1.35) past the peak, declining toward an asymptote. Region left of abscissa≈3.0 labeled "Low
Aspect Ratio"; vertical hatched band at ≈3.0 labeled "Upper Limit of Low-Aspect-Ratio Range" /
"Borderline Aspect Ratio". *(read from plot, Δy=0 curve)*:

| Abscissa | (C_Lmax)_base, Δy=0 |
|---|---|
| 0 | 0.50 |
| 0.4 | 1.20 |
| 0.8 | 1.45 (peak) |
| 1.2 | 1.13 |
| 2.0 | 0.98 |
| 3.0 | 0.87 |
| 3.6 | 0.85 |

### Fig 9.19 — Subsonic maximum-lift increment for low-AR wings
*[Nicolai & Carichner, Fig. 9.19, p. 238]* (adapted [10]) — `ΔC_Lmax` (-0.2 to 0.4) vs
`(C2+1)·AR·tan(Λ_LE)` (0–14), three curves by Mach: ≤0.2, 0.4, 0.6. All start negative near
abscissa=0, cross zero near abscissa≈4, peak near abscissa≈10-11, then decline. *(read from plot)*:

| Abscissa | ΔC_Lmax, M≤0.2 | ΔC_Lmax, M=0.4 | ΔC_Lmax, M=0.6 |
|---|---|---|---|
| 0 | -0.10 | -0.10 | -0.10 |
| 4 | 0.02 | 0.02 | 0.00 |
| 8 | 0.25 | 0.22 | 0.15 |
| 11 | 0.36 | 0.32 | 0.23 |
| 14 | 0.25 | 0.22 | 0.10 |

### Fig 9.20 — Angle-of-attack for subsonic maximum lift of low-AR wings
*[Nicolai & Carichner, Fig. 9.20, p. 239]* (adapted [10]) — `(α_CLmax)_base` (deg, 0–50) vs
`(C1+1)·(AR/β)·cos(Λ_LE)` (0–3.6), single curve: flat ~35° up to abscissa≈0.9, then decreasing to
~22° by abscissa≈3.0, flattening thereafter. Region left of ≈3.0 labeled "Low Aspect Ratio"; hatched
band at ≈3.0 labeled "Upper Limit of Low-Aspect-Ratio Range"/"Borderline Aspect Ratio". *(read from
plot)*:

| Abscissa | (α_CLmax)_base (deg) |
|---|---|
| 0 | 35 |
| 0.8 | 35 |
| 1.2 | 32 |
| 2.0 | 26 |
| 2.8 | 22.5 |
| 3.6 | 21.5 |

### Fig 9.21 — Angle-of-attack increment for subsonic maximum lift of low-AR wings
*[Nicolai & Carichner, Fig. 9.21, p. 239]* — `Δα_CLmax` (deg, -10 to 20) vs `(C2+1)·AR·tan(Λ_LE)`
(0–14). Left family of curves (black) parameterized by `AR·cos(Δ_LE)·[1+4λ²]` = 0, 2, 3, 4, 5, 6,
7, 8, 9, 30 — all converge to 0 near abscissa≈4, with more-negative excursions (down to -9 to -10)
at abscissa=0 for higher parameter values. Right family (blue) parameterized by Mach ≤0.2, 0.4, 0.6
— all rise from 0 at abscissa≈4 up to 9–15° by abscissa=14. *(read from plot, right family only)*:

| Abscissa | Δα_CLmax, M≤0.2 | Δα_CLmax, M=0.4 | Δα_CLmax, M=0.6 |
|---|---|---|---|
| 4 | 0 | 0 | 0 |
| 8 | 5.5 | 5.0 | 3.0 |
| 11 | 9.5 | 8.5 | 5.5 |
| 14 | 15.0 | 13.5 | 8.7 |

Now construct the basic-wing `C_L` vs `α` chart (Fig. 9.22). `α_0L` for the wing equals `α_0L` for
the airfoil section. Finite-wing increase in `C_Lmax` due to a TE flap:

**Eq (9.9)** *[Nicolai & Carichner, Eq. (9.9), p. 240]*:
```
ΔC_Lmax = ΔC_lmax · (S_WF/S_W) · K_Δ
```
where `K_Δ` = empirical sweep correction (Fig. 9.23); `ΔC_lmax` from the Fig. 9.8 construction;
`S_WF` defined in Fig. 9.24. `ΔC_Lmax` is added to the basic (unflapped) wing `C_Lmax`, and the
final flapped-wing curve is drawn (Fig. 9.22). `Δα_0L` for the flapped wing equals `Δα_0L` for the
flapped airfoil section determined earlier. TE flaps are not particularly effective on highly swept
wings.

No method exists to predict `ΔC_Lmax` for a wing with LE devices — designer should use experimental
data (Tables 9.1/9.2 or Fig. 9.7). Example: for the wing in Table 9.1, a 20% full-span slat gives
`ΔC_Lmax = 0.48`, a 20% full-span LE flap gives `ΔC_Lmax = 0.59` — added to the `C_Lmax` of similar
wing shapes to get `C_Lmax` for a wing with LE flaps/slats. `Δα_stall` determined similarly.

### Fig 9.22 — Construction of wing lift curves for mechanical high-lift devices
*[Nicolai & Carichner, Fig. 9.22, p. 240]* — `C_L` vs `α`: two curves, "Basic Wing" (solid) and
"Flapped Wing" (dashed, shifted left/up by `Δα_0L`), with `C_LG` intercepts at `α=0` for each,
`Basic Wing C_Lmax` and flapped `C_Lmax` marked with `ΔC_Lmax` bracket between them, and
"LE Flap or Slot Δα_stall" bracket shown between the two curves' stall angles. Construction
schematic, no plotted numeric data.

### Fig 9.23 — Planform correction factors for TE flaps
*[Nicolai & Carichner, Fig. 9.23, p. 241]* (adapted [10]) — `K_Δ` vs `Λ_c/4` (deg, 0–60), single
curve decreasing from ~0.92 at 0° to ~0.58 at 60°, given by the closed-form formula printed on the
chart:

```
K_Δ = (1 - 0.08·cos²(Λ_c/4)) · cos^(3/4)(Λ_c/4)
```
*(read from plot, matches the printed formula)*:

| Λc/4 (deg) | K_Δ |
|---|---|
| 0 | 0.92 |
| 20 | 0.89 |
| 40 | 0.78 |
| 60 | 0.58 |

### Fig 9.24 — Schematic showing flapped wing area
*[Nicolai & Carichner, Fig. 9.24, p. 241]* — Planform sketch (swept wing + fuselage), `S_WF` shaded
region = flapped wing area (spanning from fuselage side to flap outboard station, both sides), with
"Flap" labeled at each wing's TE flap location, `S_W` labeled "Total Wing Area." No plotted numeric
data (schematic definition figure).

## §9.5 Subsonic Drag Due to Flap Deflection
*[Nicolai & Carichner, p. 242]*

Deflected-flap drag must be considered in landing/takeoff analysis. First-order estimate for a
slotted or plain flap: Fig. 9.25. More refined split/plain/slotted-flap drag-coefficient estimate
given in [13]:

**Eq (9.10)** *[Nicolai & Carichner, Eq. (9.10), p. 242]*:
```
ΔC_Dflap = k1·k2·(S_WF/S_W)
```
where `k1` = function of `cf/c` (Fig. 9.26); `k2` = function of `δf` (Fig. 9.27); `S_WF/S_W` = ratio
of flapped wing area to total wing area (Fig. 9.24).

### Fig 9.25 — Trailing edge flap drag coefficient increment (referenced to wing area)
*[Nicolai & Carichner, Fig. 9.25, p. 242]* — `ΔC_Dflap` vs Flap Deflection `δf` (deg, 0–60), three
labeled trend curves ("Plain", "Single-Slotted Fowler", "Double-Slotted Fowler") with individual
aircraft data points overlaid: L-1011, C-141A, Gulfstream II, Fokker F-27, Piper PA-30, Cessna 177,
S-3A. *(read from plot, approximate values)*:

| δf (deg) | Plain ΔC_Dflap | Single-Slotted Fowler | Double-Slotted Fowler |
|---|---|---|---|
| 10 | 0.005 | — | — |
| 20 | 0.010 | 0.015 | 0.020 |
| 30 | 0.022 | 0.033 | 0.060 |
| 40 | — | 0.062 | — |
| 45 | — | — | 0.085 |
| 50 | — | 0.098 | — |
| 45 (double) | — | — | 0.110 |

### §9.6 Powered High-Lift Devices for STOL
*[Nicolai & Carichner, p. 242]*

Short takeoff and landing (STOL) is not well defined at present; generally agreed lower limit for
STOL: landing/takeoff distance over a 50-ft obstacle of **1000 ft** (air distance + ground roll).

The 1000-ft landing restriction implies a steep 7° descent over the obstacle (shortens air
distance) and low touchdown speed with high braking coefficients (shortens ground run). Air
distance over 50 ft at a 7° glide slope is ~400 ft, leaving only ~500 ft for ground roll. Touchdown
speed defined as `1.15·V_stall`; approach speed over 50 ft as `1.3·V_stall`. For takeoff, aircraft
must accelerate to takeoff speed = `1.2·V_stall`. Thus stall speed is the primary takeoff
performance parameter for STOL aircraft.

### Fig 9.26 — Factor k1 to calculate drag increment due to flaps
*[Nicolai & Carichner, Fig. 9.26, p. 243]* (data from [13]) — Two panels vs `cf/c` (0–0.4): (left)
"Split and Plain Flaps," `k1` (0–2.5) for `t/c` = 0.3, 0.12, 0.21 (curves nearly coincident below
cf/c≈0.25, diverging above); (right) "Slotted Flaps," `k1` (0–3.0) for `t/c` = 0.12, and
0.21/0.30 combined (curves also nearly coincident, diverging above cf/c≈0.35). *(read from plot,
t/c=0.12 curve each panel, at cf/c=0.4)*:

| Panel | k1 at cf/c=0.4 |
|---|---|
| Split/Plain, t/c=0.3 | 2.5 |
| Split/Plain, t/c=0.12/0.21 | 2.05 |
| Slotted, t/c=0.12 | 2.9 |
| Slotted, t/c=0.21/0.30 | 2.7 |

### Fig 9.27 — Factor k2 to calculate drag increment due to flaps
*[Nicolai & Carichner, Fig. 9.27, p. 243]* — Two panels vs flap deflection `δ` (deg, 0–100): (left)
`k2` (0–0.25) for Split Flaps (`t/c` = 0.12, 0.21, 0.30) and Plain Flaps (all t/c, dashed, lower
curve); (right) `k2` (0–0.15) for Slotted Flaps (`t/c` = 0.30, 0.12, 0.21, nearly coincident).
*(read from plot, at δ=80°)*:

| Panel | k2 at δ=80° |
|---|---|
| Split flaps, t/c=0.12 | 0.20 |
| Split flaps, t/c=0.21 | 0.18 |
| Split flaps, t/c=0.30 | 0.15 |
| Plain flaps (all t/c) | 0.12 |
| Slotted flaps (all t/c) | 0.09 |

### Example 9.1 — Wing Loadings for STOL Aircraft
*[Nicolai & Carichner, Example 9.1, p. 244]*

Fig. 6.5 (from [14]) indicates routine landing in a 1000-ft field requires approach speed of 50 kt
(84.5 ft/s). Using the FAA requirement approach speed = `1.3·V_stall` (Chapter 10), stall speed is
approximately 65 ft/s, from the one-g lift expression at sea level:

**Eq (9.11)** *[Nicolai & Carichner, Eq. (9.11), p. 244]*:
```
(W/S)·(1/C_Lmax) = 5.0
```
Using the practical upper limit of `C_Lmax` for mechanical lift devices of 4.0 (Fig. 9.7), Eq.
(9.11) gives wing loading = **20 psf** — appropriate for light utility aircraft but not commercial
short-haul STOL transports (poor cruise efficiency at such low wing loading; bumpy ride for
passengers). The Breguet 941 (STOL commercial short-haul transport, `W_TO = 48,000 lb`) lands in
1000 ft with wing loading ~45 psf, using deflected slipstream, thrust reversers, and oversize
brakes. Commercial STOL operation at 1000-ft field distances must use powered-lift devices as well
as aerodynamic high-lift devices.

### §9.6.1 Deflected Slipstream
*[Nicolai & Carichner, p. 244]*

In a deflected slipstream system, lift is produced at low speed by deflecting propeller slipstream
or jet exhaust downward via a wing-flap arrangement (used on the Breguet 941 — slipstream of four
propellers blows over the entire span, deflected by TE slotted flaps). A derivative is **upper
surface blowing (USB)**, used on the Boeing AMST YC-14 demonstrator (1970s). USB flap
effectiveness in turning jet exhaust flow depends on the **Coanda effect**: a high-velocity jet
adheres to an adjacent convex surface provided jet depth isn't large compared to the turn radius
(first systematically investigated by Henri Coanda pre-WWII; blowing BLC at a flap knee is a
practical application). The YC-14 (Fig. 9.29a) locates CF6-50 turbofans on top of the wing, bathing
the inboard upper surface in jet exhaust [continues next page].

### Fig 9.28 — Powered-lift STOL concepts
*[Nicolai & Carichner, Fig. 9.28, p. 245]* — Five schematic airfoil/engine cutaways illustrating
powered-lift STOL concepts: Internally Blown Flap (IBF), Externally Blown Flap (EBF), Upper Surface
Blowing (USB), Augmentor Wing, Vectored Thrust. Each shows engine/nozzle position and exhaust flow
path (arrows) relative to the wing/flap. No plotted numeric data (schematic).

Performance of the YC-14 USB arrangement (Fig. 9.30) depends on the jet coefficient:

**Eq (9.12)** *[Nicolai & Carichner, Eq. (9.12), p. 246]*:
```
Cj = Thrust / (q·S_ref)
```
The YC-14 also employs LE flap blowing, expressed by the blowing coefficient:

**Eq (9.13)** *[Nicolai & Carichner, Eq. (9.13), p. 246]*:
```
Cμ = (ṁ_B·Ve) / (q·S_ref)
```
where `ṁ_B` = mass flow rate of the blowing device; `Ve` = exhaust velocity of the blowing jet.

### Fig 9.29 — Prototype advanced medium STOL transports, AMST
*[Nicolai & Carichner, Fig. 9.29, p. 246]* (data from [13,14]) — Three-view drawings: (a) Boeing
YC-14 (USB-AMST); (b) Douglas YC-15 (EBF-AMST). Comparison table:

| Aircraft | YC-14 | YC-15 |
|---|---|---|
| TOGW | 160,000 | 150,000 |
| W/S | 91 | 86 |
| AR | 9.44 | 7.0 |
| Engine | CF6-500 | JT8D-15 |
| T/W at TO | 0.63 | 0.42 |

### §9.6.2 Externally or Internally Blown Flap
*[Nicolai & Carichner, p. 246]*

In IBF and EBF, high-energy jet exhaust is blown over a slotted TE flap arrangement, providing both
thrust vectoring and boundary layer control. **IBF**: jet exhaust (all or part) ducted from the
engine, through the wing, and exhausted over the TE flap (Fig. 9.28) — usually with cross-over
ducting so one engine can feed flaps on both sides (heavy/complicated ducting, but solves the
one-engine-out problem). IBF performance shown in Fig. 9.30.

**EBF** (Fig. 9.28): principal advantage is light and simple — no internal ducting or thrust
deflection mechanisms beyond the flap system itself. However, the flap system faces severe
temperature/load environments, and one-engine-out is a major design problem. Despite drawbacks, EBF
is popular — used on the YC-15 (Fig. 9.29b) and more recent USAF [continues next page].

### Fig 9.30 — Low-speed drag polars for various powered-lift concepts
*[Nicolai & Carichner, Fig. 9.30, p. 247]* — `C_L` (0–9) vs `C_D` (-2.0 to 3.0), Boeing Vertol wind
tunnel data, four-engine configuration, `Cj=0`, leading-edge BLC `Cμ=0.08`. Curves for IBF (δF=40°),
Augmentor Wing (δF=35°), USB (δF=60°), EBF (δF=40°/60°), Vectored Thrust (δF=40°/60°, 30°), plus a
baseline `Cj=0` curve (δF=40°/60°, no powered lift). Two reference lines: "100% Efficiency, Cj=2.0"
(dashed, upper) and "100% Efficiency, Cj=0" following `C_D = C_D0 + C_L²/(π·AR·e)` (labeled,
lower-right). *(read from plot, approximate peak C_L and corresponding C_D for each concept)*:

| Concept | δF | Peak C_L | C_D at peak C_L |
|---|---|---|---|
| IBF | 40° | 8.8 | 1.9 |
| Augmentor Wing | 35° | 8.5 | 2.3 |
| USB | 60° | 7.8 | 2.1 |
| EBF | 40°/60° | 6.9 | 1.0 |
| Vectored Thrust | 40°/60°, 30° | 4.5 | -0.5 |
| Baseline (Cj=0) | 40°/60° | 3.2 | 0.6 |

C-17 transport. Performance of a typical EBF arrangement shown in Fig. 9.30.

> **Sidebar:** In 1972 the USAF started an AMST program calling for operating a 27,000-lb payload
> into a 2000-ft semi-prepared field. Boeing's YC-14 (USB) competed with McDonnell Douglas's YC-15
> (EBF). Both prototypes met AMST requirements but neither saw production. McDonnell Douglas later
> incorporated the YC-15 EBF into their winning C-17 design.

### §9.6.3 Jet Flap
*[Nicolai & Carichner, p. 248]*

The jet flap is a sheet of air blown downward from the wing TE, providing increased circulation and
a vectored thrust component. Unlike a usual TE flap, there's no solid surface in the jet sheet to
support a pressure distribution — hence no drag from the device. Drag is desirable during landing
(reduces air/ground distance), so this jet-flap feature is not an advantage for landing. The jet
flap does have an advantage over TE flaps during transonic maneuvering flight: absence of flap drag,
plus the jet flap extends the low-pressure region on the wing upper surface in the TE region, moving
the upper-surface normal shock aft and delaying flow separation.

### §9.6.4 Augmentor Wing
*[Nicolai & Carichner, p. 248]*

The augmentor wing is similar to the IBF except ducted engine air exhausts between two TE flap
sections forming a diffuser section (Fig. 9.28). High-velocity engine air mixes with stagnant
secondary air in the diffuser, increasing mixture momentum and decreasing pressure — the decreased
pressure entrains more secondary air from the wing upper surface into the diffuser. Result: thrust
augmentation from the primary engine exhaust by as much as a **factor of 2**.

## §9.7 Powered High-Lift Devices for V/STOL
*[Nicolai & Carichner, p. 248]*

First thing to understand about V/STOL: high lift during vertical ascent/descent does **not** come
from air flowing over a wing (the "V" means zero airspeed) — it comes from directing propulsion-unit
force downward. Rule of thumb: need a downward force of **~1.2× aircraft weight** to achieve VTOL
(extra 20% for three-axis control and to overcome "suck down" — suction usually present beneath a
VTOL aircraft). Beyond three-axis control, must also provide for fore/aft translation during hover.

Candidate V/STOL concepts shown in Figs. 9.31 and 9.32. Fig. 9.31 generated by McDonnell Aircraft
Company in 1968, showing state of the art at that time.

### Fig 9.31 — V/STOL aircraft summary (1970s)
*[Nicolai & Carichner, Fig. 9.31, p. 249]* — Large circular taxonomy "wheel" diagram (often called
the "Wheel of Misfortune") classifying V/STOL concepts by concentric rings: innermost — Augmented
Powerplant for Hover / Same Propulsion System for Hover and Forward Flight / Separate Powerplant for
Hover / Special Types and Helicopters; middle rings subdivide into Combined Powerplants for Hover,
Lift Engines, Tip Jets, Rotor (Tip Turbine Fan, Mech Fan, Pneumatic Drive, Shaft Drive, Static,
Dynamic), Fixed/Tiltable Power Plant, Propeller/Ducted Propeller/Prop-Rotor, Free Slipstream, Ducted
Slipstream, Prop Fan, Exhaust and Bleed, Mass Flow Generator and Deflection, Mass Flow Deflection;
outer ring shows individual aircraft examples with small illustrations (McDonnell Fighter, Hoop
(Russian), Lockheed Stowed Rotor, Sikorsky Stowed Rotor, Curtiss-Wright X-19/300, Boeing Vertol-76
VZ-2, Boeing Vertol, Bell X-22A, Nord Cadet 500, Douglas Doak X-16 (V2-4A), Canadair CL-84, Vought
Ryan Hiller XC-142, Hiller X-18, VFW VC-400, Lockheed CL-379, Fairchild 224, Ryan-82 V23-RY,
Robertson VTOL, Chance-Vought Adam, Collins Aerodyne, Hawker P-1127/XV-6A, Mikoyan V/STOL, Bell
X-14, STOL Aircraft McDonnell 188/Breguet 941, Helicopters, Tail Sitters, Ground Effect Machines,
Flying Platforms, One-Man-Lifts, Flying Jeeps, Flying Saucers, Lockheed XV-4B, Fiat G35-4, British
VTOL P.D. 16, Short PD 49/SC-1, Lockheed VTOL F-104, French Mirage III-V, British P-146, German
VJ-101C, Dornier DO31, EWR Republic US/ERG, VFW VAK 1918, McDonnell Model 177, Fairey Rotodyne-Y,
Hughes Stopped Rotor, McDonnell XV-1, Sikorsky S-57 (XV-2), Lockheed Hummingbird XV-4A, GE/Ryan
XV-5A, Boeing Fan-in-Wing Transport, NAA Fan-in-Wing Transport, McDonnell Lift/Lift Cruise
Transport, Vanguard 2-C Omniplane, Lockheed AAFSS, Piasecki Compound, Bell XV-3, Curtiss-Wright
X-100). Purely taxonomic/illustrative — no plotted numeric data.

Not every aircraft shown was actually built and flown; many crashed during testing; only the
P-1127/XV-6A saw production (as the Harrier). Fig. 9.32 shows more successful V/STOL aircraft up to
the present — only the Yak-38 (lift + lift/cruise), V-22 (tilt rotor), AV-8 Harrier (vectored
thrust), and F-35B (fuselage fan + vectored thrust) from Fig. 9.32 have gone into production. A
derivative of the XV-15 may be produced commercially as the Bell/Boeing 609 and for the Coast Guard
as the Bell Eagle Eye UAV.

The augmentor (ejector) wing can be used as a VTOL device — e.g., Rockwell International XFV-12A
(see [7]) for the U.S. Navy, using all engine air, or as a STOL device using only part of the engine
air. The ejector concept was first used in the Lockheed Hummingbird XV-4A in the early 1960s, with
limited success — the XV-4A had two 3300-lb thrust PW JT12A-3 turbojets, exhausted rearward for
forward flight or diverted to feed the fuselage ejector system. The fuselage ejector was replaced
with lift engines in the XV-4B to demonstrate the lift-plus-lift-cruise concept — four J85-19
turbojets in the fuselage for vertical lift only, plus two J85s in external pods vectorable for lift
or forward thrust.

Tilt-wing concepts (e.g., XC-142) have propellers mounted on the wing; the entire wing rotates up
to 90° while the fuselage stays horizontal. Most of the wing is immersed in propeller slipstream and
doesn't stall during rotation. Several tilt-wing prototypes shown in Fig. 9.32. In the
tilt-rotor/propeller concept, the wing is fixed and only the propeller/rotor tilts. The XV-15 was
one of the more successful tilt-rotor prototypes (mainly due to Bell's 40 years of persistence) — it
will see military service as the V-22 and likely commercial service.

### Fig 9.32 — V/STOL aircraft summary (2008)
*[Nicolai & Carichner, Fig. 9.32, p. 250]* — Similar circular taxonomy wheel to Fig. 9.31 but
updated to 2008: rings for Augmented Powerplant for Hover (Ejector, Lift Fan, Tilt Prop, Tilt Duct),
Same Propulsion System for Hover and Forward Flight (Tilt Wing, Tilt Rotor, Deflected Slipstream,
Vectored Thrust), Separate Powerplant for Hover (Lift+Lift/Cruise, Lift+Cruise, Tail Sitters).
Aircraft examples with boxed "Production Vehicles" flag: Lockheed Martin F-35B, Rockwell XFV-12A,
Lockheed XV-4A, Yakolev Yak-141, **Yakolev Yak-38 (production)**, VFW VAK 191B, Lockheed XV-4B,
Dornier Do 31, EWR VJ101C, Dassault Mirage III-V, Dassault Balzac V, Short SC-1, Ryan X-13, Convair
XFY-1 Pogo, Lockheed XFV-1, Boeing X-32, MDA/Bae Harrier, Yak-36, Hawker P.1127/Kestrel, Fairchild
VZ-5, Ryan 92 VZ-3, **Bell 609 Tiltrotor (production)**, **Bell-Boeing V-22 (production)**, Bell
XV-15, Boeing X-50A, Canadair CL-84, LTV-Ryan XC-142, Hiller X-18, Vertol 76 VZ-2, Nord 500 Cadet,
Bell X-22A, Curtiss Wright X-19, Curtiss Wright X-100, Doak 16 VZ-4, Vanguard Omniplane, GE-Ryan
XV-5A, Lockheed Martin F-35B (Lift Fan panel). Credit line: "Grant Carichner © All Rights Reserved."
Purely taxonomic/illustrative — no plotted numeric data.

Some V/STOL designs use direct engine thrust for additional lift during takeoff/landing — from
dedicated lift engines (Lockheed XV-4B), cruise engines vectoring thrust (AV-8B Harrier), or a
combination ("lift plus lift-cruise": German VAK-191B, Russian Yak-38). Lift-engine/vectored-thrust
concepts are mature, straightforward, low-risk, but produce a field of very hot gas beneath the
aircraft that can be ingested by the engine, reducing thrust.

Energy can be extracted from the cruise engine to power a **lift fan** — shaft power or hot exhaust
gas driving a tip-driven lift fan; lift fan exhausts downward with lift force greater than the
cruise engine's vectored thrust (augments cruise-engine thrust). Demonstrated on the Ryan XV-5A in
the 1960s: two gas-driven lift fans in the wings, one in the nose. Three-axis control: modulate
nose-fan thrust for pitch, modulate wing-fan thrust for roll, deflect nose-fan lift sideways for
yaw; fore/aft translation via deflecting wing-fan thrust fore/aft. Two J85-GE-5 turbojets (2650 lb
static thrust each) drove the three lift fans, generating **13,886 lb vertical thrust** — an
**augmentation ratio of 2.62**. Disadvantage: volume required for hot-gas ducting, and ducting
vulnerability to small-arms ground fire.

In 1996 the U.S. government awarded Boeing and Lockheed Martin contracts to build two Joint Strike
Fighter (JSF) prototypes each, demonstrating three variants: conventional takeoff/landing (USAF),
carrier-suitable (USN), and short takeoff vertical landing/STOVL (USMC) — the STOVL variant was the
discriminating factor. JSF engine: PWF119 afterburning turbofan, ~32,000 lb vectored thrust
available for VTOL. Boeing selected the low-risk vectored-thrust concept for its X-32B demonstrator
(Fig. 1.11). Lockheed Martin selected the higher-risk but more capable **shaft-driven lift fan
(SDLF)** plus vectored thrust concept (Fig. 9.33) for its X-35B. Most risk was in the gearbox
driving the SDLF, a clutch, and a functional lightweight fan; SDLF located behind the cockpit.
Three-axis control: modulate lift-fan thrust for pitch, deflect lift-fan thrust sideways for yaw,
wingtip-mounted reaction control jets for roll. At sea level, 75°F day, the X-35B generated
**39,100 lb vertical lift** distributed as follows: 16,411 lb from the three-bearing swivel nozzle,
3,607 lb from wingtip roll-control jets, 19,082 lb from the lift fan. Lift fan achieved augmentation
ratio of about **1.6**. The SDLF-plus-vectored-thrust concept had considerable margin over the X-32B
vectored-thrust concept and won the JSF competition; the aircraft is now in production and will see
Air Force/Navy/Marine Corps service as the F-35. F-35 Case Study in Volume 2 recommended reading.

### Fig 9.33 — X-35B showing shaft-driven lift-fan (SDLF) and auxiliary inlet
*[Nicolai & Carichner, Fig. 9.33, p. 252]* — Photograph of X-35B on ramp showing open lift-fan bay
behind cockpit; inset photo "Hover Testing" showing aircraft in hover near a runway. No plotted
numeric data (photograph).

> **Sidebar — F-35 and the Joint Strike Fighter Program:** The F-35 has three variants: F-35A
> (conventional TO/landing, USAF), F-35B (STOVL, USMC), F-35C (carrier suitable, USN). Single PWA
> F135 turbofan, 43,000 lb TSLS in afterburner.
>
> | | F-35A | F-35B | F-35C |
> |---|---|---|---|
> | Wing area (ft²) | 460 | 460 | 668 |
> | Empty weight (lb) | 29,300 | 32,000 | 34,800 |
> | Max TOGW (lb) | 70,000 | 60,000 | 70,000 |
> | Range (nm) | 1200 | 900 | 1400 |
> | Combat radius (nm) | 610 | 500 | 640 |
> | Max speed (Mach) | 1.67 | 1.67 | 1.67 |
>
> Program joined by eight international partners: United Kingdom, Italy, Netherlands, Canada,
> Turkey, Australia, Norway, Denmark.

Several excellent references on V/STOL aerodynamics/technology recommended: [15] good theoretical
text on high-lift devices with supporting experimental data; [16] excellent STOL aerodynamic
technology summary report; [17] summary of the USAF Advanced Medium STOL Transport Program; [18]
excellent V/STOL aircraft design text; [7] superb historical account of VTOL military research
aircraft.

## References
*[Nicolai & Carichner, Chapter 9 References, p. 253]*

1. Kuethe, A. M., and Schetzer, J. D., *Foundations of Aerodynamics*, Wiley, New York, 1959.
2. Abbott, I. H., and von Doenhoff, A. E., *Theory of Wing Sections*, Dover, New York, 1959.
3. Furlong, G. C., and McHugh, J. G., "A Summary and Analysis of the Low-Speed Longitudinal
   Characteristics of Swept Wings at High Reynolds Number," NACA TR-1339, 1957.
4. Thomson, L. P., "A Review of Leading Edge High Lift Devices," Dept. of Supply, Army Research
   Laboratory Rept. A-77, 1951.
5. Gambucci, B. J., "Section Characteristics of the NACA 0006 Airfoil with Leading-Edge and
   Trailing-Edge Flaps," NACA TN-3797, 1956.
6. Menees, G. P., "Lift, Drag and Pitching Moment of an Aspect-Ratio-2 Triangular Wing with
   Leading-Edge Flaps Designed to Simulate Conical Camber," NASA Memo 10-5-58A, Dec. 1958.
7. Rogers, M. J., *VTOL Military Research Aircraft*, Orion Books, New York, 1989.
8. Nonweiler, T., "Flaps, Slots and Other High Lift Aids," *Aircraft Engineering*, Vol. 6, Sept.
   1955, pp. 19–23.
9. Cahill, J. F., et al., "Aerodynamic Forces on a Symmetrical Circular Arc Airfoil with Plain LE
   and TE Flaps," NACA TR-1146, 1953.
10. Ellison, D. E., "USAF Stability and Control Handbook (DATCOM)," U.S. Air Force Flight Dynamics
    Laboratory, AFFDL/FDCC, Wright–Patterson AFB, OH, June 1969.
11. Abbott, I. H., Von Doenhoff, A. E., and Stivers, L., Jr., "Summary of Airfoil Data," NACA
    TR-824, 1945.
12. Riegels, F. W., *Aerofoil Section*, Butterworth, London, 1961.
13. Young, A. D., "The Aerodynamic Characteristics of Flaps," NACA Ames Research Center ARC R&M
    2622, 1953.
14. Kuhn, R. E., "Takeoff and Landing Distance and Power Requirements of Propeller Driven STOL
    Aircraft," IAS Preprint 690, presented at 25th Annual Meeting, New York, 28–31 Jan. 1957.
15. McCormick, B. W., *Aerodynamics of V/STOL Flight*, Academic Press, New York, 1967.
16. May, F., and Widdison, C. A., "STOL High-Lift Design Study, Vol. 1, State-of-the-Art Review of
    STOL Aerodynamic Technology," U.S. Air Force Flight Dynamics Laboratory Rept. AFFDL-TR-71-26,
    Wright–Patterson AFB, OH, April 1971.
17. Oates, G. S., Brown, S., and Nicolai, L., "STOL Tactical Aircraft Investigation, Executive
    Summary," U.S. Air Force Flight Dynamics Laboratory, AFFDL TR-74-l25, PTC, Wright–Patterson
    AFB, OH, July 1975.
18. Kohlman, D. L., "Introduction to V/STOL Airplanes," Iowa State Univ. Press, Ames, IA, 1981.

---

*Chapter 9 complete (§§9.1–9.7, Tables 9.1–9.3, Figs 9.1–9.33 incl. 9.29a note, Eqs 9.1–9.13 incl.
9.4a/9.4b, References [1]–[18]). Next: Chapter 10 — Takeoff and Landing Analysis.*
