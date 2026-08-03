# Chapter 8 — Preliminary Fuselage Sizing and Design

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 8 "Preliminary Fuselage Sizing and Design," printed pp. 195–220.

Mostly design guidance and reference-data tables (crew station/passenger/cargo dimensions);
few numbered equations. All tables and data figures captured; pure cutaway/photo figures noted.

---

## §8.1 Fuselage Volume

Focus of this chapter: initial fuselage length and c.g. location. Reference [1, Vols. 3–4] is
recommended for fuselage design detail.

> **Sidebar — Going Supersonic with Area Rule Theory:** the Convair F-102 Delta Dagger
> (1950s USAF interceptor) prototype YF-102 (1954) had dismal performance — couldn't reach Mach 1
> due to excessive transonic drag. Convair engineers applied Richard Whitcomb's (NASA) emerging
> **area-rule** theory (§8.4): cross-sectional area distribution from nose to tail should be smooth
> and continuous for low wave drag, so fuselage cross-section near the wing must be reduced to
> accommodate the wing's added area — giving the "Coke bottle" pinched-waist shape. After this
> redesign, the YF-102 reached Mach 1.22 at 53,000 ft; Convair built 1000 Delta Daggers.

### §8.1.1 Passengers

Coach seating is driven by max passengers per ft³ while maintaining comfort (volume per Table 8.1
/ Fig 8.1a). Each passenger assumed 180 lb (incl. carry-on); checked baggage ~40 lb (~15 ft³)
domestic, ~65 lb (~25 ft³) international. Number of seats across depends on aircraft size and
single/double aisle (Table 8.2). Passenger section usually round cross-section (most structurally
efficient for metal); most volumetrically efficient is oval (Boeing 787 composite fuselage).
Passengers occupy the upper half of the cross-section; baggage/cargo the lower half. Passenger/cargo
sections pressurized to 6500-ft cabin altitude — the pressure differential vs 35,000–40,000 ft
cruise is a major structural/fatigue design driver.

### Table 8.1 — Passenger Compartment Requirements
*[Nicolai & Carichner, Table 8.1, p. 197]*

| Parameter | Long Range | Short Range |
|---|---|---|
| Seat width (in.) | 17–22 | 16–18 |
| Seat pitch (in.) | 34–36 | 30–32 |
| Headroom (in.) | >65 | >65 |
| Aisle width (in.) | 18–20 | >12 |
| Aisle height (in.) | >76 | >60 |
| Passengers per attendant | 31–36 | <50 |

### Fig 8.1 — Commercial transport seating arrangement
*[Nicolai & Carichner, Fig. 8.1, p. 198]* — (a) Schematic: circular cross-section with aisle
height/width, seat width, headroom labels, cargo & luggage in lower half; seat-pitch diagram
(minimum 26" knee clearance callout). (b) Photographs: empty cabin shell vs fully outfitted
interior. Diagram/photos, no plotted data.

### Table 8.2 — Aisle and Passenger Distributions for Various Commercial Transports
*[Nicolai & Carichner, Table 8.2, p. 198]*

| Aircraft | Aisle | No. Passengers on Sides | No. Passengers in Middle |
|---|---|---|---|
| Boeing 727 | Single | 3 and 3 | 0 |
| Boeing 737 | Single | 3 and 3 | 0 |
| Airbus 300 | Double | 2 and 2 | 4 |
| Boeing 747 | Double | 3 and 3 | 4 |
| Boeing 757 | Single | 3 and 3 | 0 |
| Boeing 767 | Double | 2 and 2 | 3 |
| Boeing 777 | Double | 2 and 2 | 5 |
| Lockheed L-1011 | Double | 2 and 2 | 4 |
| DC-10 | Double | 2 and 2 | 5 |
| Boeing 787 | Double | 2 and 2 | 5 |

Each row of seats should have as large a window as possible; typical window spacing 40 in. for
14×10 in. windows. Ref [1, Vol. 3] has extensive commercial passenger-section layout guidance.

### §8.1.2 Lavatories, Galleys, and Emergency Exits
One lavatory per ~20 passengers. Emergency exit number/type defined by FAR Part 25.807 [2].

### §8.1.3 Passenger Cargo
Luggage/revenue cargo preloaded into standard containers, carried beneath passengers (dimensions
in Table 8.3). Smaller/short-range aircraft skip containers, using bulk cargo space sized at
**6–8 ft³ per passenger**.

### Table 8.3 — Cargo Container Specifications
*[Nicolai & Carichner, Table 8.3, p. 199]*

| Type | Height (in.) | Width (in.) | Depth (in.) | Weight (lb) |
|---|---|---|---|---|
| LD-2ᵃ | 64 | 61.5 | 60.4 | 2700 |
| LD-3ᵃ | 64 | 79 | 60.4 | 3500 |
| LD-4 | 64 | 96 | 60.4 | 5400 |
| LD-5 | 64 | 125 | 60.4 | 5400 |
| LD-8ᵇ | 64 | 125 | 60.4 | 5400 |

ᵃ Lower corner chamfered 30°. ᵇ Both lower corners chamfered 30°.

### §8.1.4 Military Cargo and Equipment
Preloaded on flat pallets, tied down, tarp-covered. Most common: **463L pallet**, 108×88 in.
MIL-STD-1791 requires 6-in. clearance all directions between cargo and aircraft interior. Military
transport cargo floor ≈4–5 ft off ground for direct truck-bed loading. Cargo-bay dimensions sized
by the equipment carried (jeeps, HMMWVs, APCs, SOF boats, 463L pallets):

| Aircraft | Cargo Bay Width | Cargo Bay Height | Cargo Bay Length |
|---|---|---|---|
| C-130 | 10 ft 3 in. | 9 ft 2 in. | 41 ft 5 in. |
| C-5 | 19 ft | 13 ft 6 in. | 121 ft |

C-5 and C-17 developed to carry "outsize" cargo (M-60 tanks, helicopters, large trucks); these need
a rear ramp for load/unload.

### §8.1.5 Crew Compartment
Long-range military/commercial transport crew compartment length: **≈150 in.** (crew of 4),
**≈130 in.** (crew of 3), **≈100 in.** (crew of 2) — room to stand/stretch + stow map cases/flight bags.

Fighter cockpit size depends on crew count and tandem vs side-by-side seating. Typical seatback
angle 13° (up to 30° for better g-tolerance, e.g. F-16). Typical single-seat fighter crew-station
envelope: **30 in. wide × 50 in. to canopy top × 60 in. pedals-to-seatback**. Ejection seat required
above `q = 230 psf` (≈260 kt at SL); near Mach 1 at SL (`q = 1480 psf`) even an ejection seat is
unsafe — needs an encapsulated seat/crew capsule (FB-111, B-1A used separable crew capsules: heavy
and complex, but survivable at high-q ejection). Ref [3] has a full fighter-crew-station chapter.

MIL-STD-850B defines over-nose/over-side vision angle requirements by aircraft class — important
for low-altitude maneuvering and seeing the runway threshold on approach. Over-nose analysis:
aircraft at α for `0.8·C_Lmax`, approach angle 3° (commercial/USAF), 4° (Navy/Marine carrier
approach), 7° (STOL). Concorde and Tu-144 drooped the entire nose (Fig 8.2) for landing visibility.

### Table 8.4 — Typical Minimum Over-Nose and Over-Side Pilot Viewing Angles
*[Nicolai & Carichner, Table 8.4, p. 201]*

| Aircraft | Over-Nose | Over-Side |
|---|---|---|
| Military transports and bombers | 17° | 35° |
| Commercial transport | 11–20° | 35° |
| Fighter | 11–15° | 40° |
| General aviation | 5–10° | 35° |

### Fig 8.2 — Concorde with nose drooped for landing
*[Nicolai & Carichner, Fig. 8.2, p. 201]* — Photograph, nose-on view, gear down, nose visibly
drooped. No plotted data.

### §8.1.6 Armament
Bomb/missile number and size must be determined and located in/on the aircraft. Guns/cannon:
external gun pods (lower fuselage volume, higher drag) vs internal mounting. Ref [1, Vol. 4] covers
armament integration and air-to-air/air-to-ground weapon size/weight data.

### §8.1.7 Landing Gear
Size/location varies by aircraft; first estimate from existing aircraft in the same weight class.
Refs [1, 4] cover landing-gear design in detail.

Main gear location relative to c.g. driven by two considerations: (1) aircraft must not fall on
its nose or tail at any loading condition; (2) moment to rotate about the main gear to `0.8·C_Lmax`
at V_TO, worst c.g., should not size the horizontal tail/canard/flaps. Main gear (strut depressed)
sits behind the most-forward c.g. (tricycle) or ahead of the most-aft c.g. (tail dragger), by the
angles in Table 8.5; carrier Navy aircraft need 15° behind c.g. for a 5° pitching-deck margin
(geometry in Figs 8.3, 11.1).

### Table 8.5 — Angles for Location of Main Landing Gear
*[Nicolai & Carichner, Table 8.5, p. 202]*

| Gear Type | Aircraft | Angle for Main Gear |
|---|---|---|
| Tail dragger | All | 15° forward of c.g. |
| Tricycle | All | 10° behind c.g. |
| Tricycle | Carrier suitable | 15° behind c.g. |

Nose gear rule of thumb: **20% of TOGW** on the nose wheel for good steering; located to avoid
tip-over during high-speed taxi turns (geometry/typical angles in Fig 8.3).

**Tip-back angle:** angle between extended-strut main gear and aft fuselage such that the aft
fuselage doesn't strike the ground during rotation. Determined by rotating to α for `0.9·C_Lmax`
about the main gear (extended strut) and checking ground clearance (0.9 used, vs the normal
`0.8·C_Lmax` rotation, to allow margin for pilot overshoot).

Typical approach: 3° glide slope + flare → ~10 ft/s sink rate at touchdown (flare is imprecise →
large landing-distance dispersion between pilots). Carrier Navy/Marine aircraft approach at ~4°,
**no flare** at touchdown (less dispersion) → 24 ft/s sink rate → much heavier gear. UAV autonomous
landing systems give a highly consistent, low ~5 ft/s sink rate → can use lighter gear.

### Fig 8.3 — Aircraft turnover and tip-back angle definitions
*[Nicolai & Carichner, Fig. 8.3, p. 203]* — Top view: ground-track turnover geometry,
`θ_TO` = turnover angle, not to exceed **54° carrier-based / 63° land-based**. Side view: forward
c.g., `θ_MG` (main-gear angle), extended strut/tire position, `θ_TB` = tip-back angle, callout
"fuselage must not contact ground at 0.9 C_Lmax." (F-16-style airframe used as the illustration.)

### §8.1.8 Wing Carry-Through
Volume must be reserved for the wing carry-through (root-chord-thickest region) — a considerable
fuselage-volume contributor. May be a straight carry-through of the wing center section or a
ring-type structure following the fuselage outer contour (Figs 8.4–8.10, 19.1, 19.2).

### §8.1.9 Propulsion Integration
Engines may be internal (F-15, Fig 8.4; F-18, Fig 8.5), partially embedded (F-4, Fig 8.6), or fully
external (DC-9, Fig 8.7). Internal/partial arrangements are hard to assess early (engine size/count
not yet known) — reserve fuselage volume as a placeholder if internal mounting is likely.

### Fig 8.4 — Boeing F-15A Eagle internal arrangement
*[Nicolai & Carichner, Fig. 8.4, p. 204]* — Cutaway illustration. Key data: `W_TO = 40,000 lb`,
`AR = 3`, `W/S_TO = 66 psf`, two P&W F-100 engines. No plotted data (reference cutaway).

### Fig 8.5 — Boeing F-18C Hornet internal arrangement
*[Nicolai & Carichner, Fig. 8.5, p. 205]* — Cutaway illustration. Key data: `W_TO = 56,000 lb`,
`AR = 3.5`, `W/S_TO = 140 psf`, two GE F404-400 turbofans. No plotted data (reference cutaway).

### Fig 8.6 — F-4 Phantom II internal arrangement
*[Nicolai & Carichner, Fig. 8.6, p. 206]* — Cutaway illustration, high-performance fighter-bomber.
Key data: `W_TO = 54,000 lb`, `length = 58 ft`, `wing span = 38.5 ft`, `Mach_max = 2.1`. No plotted
data (reference cutaway). Text notes engines partially embedded in fuselage (§8.1.9).

### Fig 8.7 — DC-9 internal arrangement
*[Nicolai & Carichner, Fig. 8.7, p. 206]* — Cutaway illustration, subsonic short/medium-range jet
transport. Key data: `W_TO = 114,000 lb`, 70–125 passengers, two JT8D turbofans (fully external
podded mounting). No plotted data (reference cutaway).

If jet engines are mounted in or partially within the fuselage, inlet volume must be reserved. First
estimate of inlet volume: use the engine compressor-face diameter as the cross-section and a length
equal to six-tenths of the engine length.

### Fig 8.8 — Boeing B-1B Lancer internal arrangement
*[Nicolai & Carichner, Fig. 8.8, p. 207]* — Cutaway illustration. Key data: `W_TO = 477,000 lb`,
`AR(ext) = 9.6`, `AR(swept) = 3.1`, four GE F-101-102 turbofans. No plotted data (reference cutaway).

### Fig 8.9 — Lockheed Martin F-16A Fighting Falcon internal arrangement
*[Nicolai & Carichner, Fig. 8.9, p. 208]* — Cutaway illustration. Key data: `W_TO = 33,000 lb`,
`wing span = 32.8 ft`, `length = 49.3 ft`, one P&W F-100-100 turbofan. No plotted data (reference
cutaway). **Directly relevant to this repo's F-16A Brandt baseline** — cross-check overall
span/length against `F16Baseline()` geometry fields.

### Fig 8.10 — Piper Comanche internal arrangement
*[Nicolai & Carichner, Fig. 8.10, p. 209]* — Cutaway illustration, four-place general aviation
aircraft. Key data: `W_TO = 2800 lb`, `W_empty = 1600 lb`, `length = 24.9 ft`, `wing span = 36 ft`.
No plotted data (reference cutaway).

### §8.1.10 Fuel
*[Nicolai & Carichner, p. 209]*

Fuel carried in fuselage, wing structure, or both. Final placement depends on weight/balance and
vulnerability to enemy fire (locate fuel around c.g. to keep c.g. envelope small during burn-off —
wing is a good location since it's always near the c.g.). Fuel tank volume required:

```
Tank volume = (fuel volume) / (packaging factor)
```
*[Nicolai & Carichner, p. 210]* — packaging factor accounts for structure, pumps, baffles, fuel
lines, and general tank inefficiency.

### Table 8.6 — Fuel Densities
*[Nicolai & Carichner, Table 8.6, p. 210]*

| Fuel | Gallon Weighs (lb) | Cubic Foot Weighs (lb) |
|---|---|---|
| JP-4 | 6.5 | 48.6 |
| JP-5 | 6.8 | 51.1 |
| JP-8 | 6.7 | 50 |
| Aviation gas | 6.0 | 44.9 |

### Table — Fuel Tank Packaging Factors
*[Nicolai & Carichner, p. 210, unnumbered table]*

| Tank Type and Location | Packaging Factor |
|---|---|
| Integral tank — shallow fuselage | 0.8 |
| Integral tank — deep fuselage | 0.85 |
| Integral tank — wing | 0.75 |
| Bladder tank — fuselage | 0.75 |
| Bladder tank — wing | 0.65 |

### §8.1.11 Avionics
*[Nicolai & Carichner, p. 210]*

Avionics = comms/nav gear, radar, fire control, penetration aids, autopilot, instrumentation. May be
specified in mission requirements or left to designer. If avionics weight is known, volume estimated
assuming an avionics equipment density of **45 lb/ft³**. Must be located for ground-crew access
(not stacked — the F-4 stacked avionics under the rear ejection seat, and USAF maintenance records
mistakenly flagged the seat itself as "high maintenance" [5]); must provide cooling (cooling
plates, air-circulation separation).

### Table 8.7 — Weights and Volumes for Common Avionics Equipment
*[Nicolai & Carichner, Table 8.7, p. 211]*

| Item | Model | Volume (ft³) | Weight (lb) |
|---|---|---|---|
| Intercom system | AIC-25 | — | 19.2 |
| UHF communications | ARC-109 | — | 51.0 |
| UHF communications | ARC-150 | 0.21 | 11.0 |
| UHF DF horning | 705CA | — | 5.0 |
| Air-to-ground IFF | APX-64 | — | 53.0 |
| Air-to-ground IFF | APX-92 | 0.11 | 13.0 |
| TACAN | ARN-52 | — | 61.0 |
| TACAN | ARN-100 | 1.1 | 46.0 |
| ILS-VOR | ARN-584 | — | 27.0 |
| ILS-VOR | RCS-AVN-220 | 0.05 | 3.5 |
| Gyrocompass | ASN-89 | 0.21 | 8.4 |
| Inertial navigation system | AJQ-20 | — | 207.0 |
| Inertial navigation system | LN-30 | 1.08 | 44.0 |
| High-frequency radio | ARC-123 | — | 78.4 |
| Autopilot system | — | — | 168.5 |
| Air data computer | AXC-710 | 0.5 | 14.0 |
| Radar warning and horning | APS-109 | — | 182.0 |
| Radar warning and horning | APR-41 | 0.17 | 22.0 |
| ECM equipment | ALQ-103 | — | 637.0 |
| Countermeasures dispensing set I | ALE-28 | — | 117.0 |
| Countermeasures receiving set | ALR-23 | — | 94.0 |
| Radar altimeter | APN-167 | — | 38.2 |
| Attack radar | APQ-113 | — | 387.2 |
| Range-only radar | SSR-1 (GE) | 0.55 | 25.0 |
| Terrain-following radar | APQ-110 | — | 249.0 |
| Head-up display | TSP-2199 | 1.6 | 37.0 |
| Gun camera | 16-mm Telford | 0.03 | 2.0 |
| Lead computing optical sight | ASG-23 | — | 5.0 |
| Flight data recorder | — | 0.3 | 15.6 |

Abbreviations: UHF ultrahigh frequency; DF direction finder; IFF identification friend or foe;
TACAN tactical air navigation; ILS-VOR instrument landing system/VHF omnidirectional radio; ECM
electronic countermeasures.

### Table 8.8 — Statistical Methods for Estimating Avionics Weight Given Volume or Power
*[Nicolai & Carichner, Table 8.8, p. 212]*

| System | Wt from Power | Wt from Volume | Units |
|---|---|---|---|
| Radar systems | `Wt = 0.431·Power^0.777` | `Wt = 38.21·Vol^0.873` | lb, W, ft³ |
| Doppler navigation | `Wt = 0.408·Power^0.868` | `Wt = 29.67·Vol^0.662` | lb, W, ft³ |
| Inertial navigation | `Wt = 0.465·Power^0.848` | `Wt = 51.85·Vol^0.738` | lb, W, ft³ |
| TACAN systems | `Wt = 13.61 + 0.104·Power` | `Wt = 0.311·Vol^0.704` | lb, W, in³ |
| Receiver systems | `Wt = 6.3 + 0.17·Power` | `Wt = 44.5·Vol^0.737` | lb, W, ft³ |
| Transmitter systems | `Wt = 0.73·Power^0.610` | `Wt = 6.4 + 40.2·Vol` | lb, W, ft³ |
| Identification systems | `Wt = 0.607·Power^0.724` | `Wt = 0.069·Vol^0.868` | lb, W, in³ |
| Computers | `Wt = 2.246·Power^0.630` | `Wt = 0.123·Vol^0.817` | lb, W, in³ |
| Electronic countermeasures (ECM) | `Wt = 0.429·Power^0.771` | `Wt = 0.055·Vol^0.912` | lb, W, in³ |

### §8.1.12 Wrap It Up
*[Nicolai & Carichner, p. 212]*

Once required volume is determined for each fuselage section, "package" the fuselage (locate all
internal items) and determine initial length. Design-for-maintainability rules:
- Place equipment one deep — do not stack or hide.
- Place equipment chest high — minimize need for stands/ladders on the flight line.
- Make all replaceable equipment <40 lb (to avoid needing more than one person or special
  equipment to remove/replace it) — engines exempt.

### Table 8.9 — Initial Estimation of Empennage Weight
*[Nicolai & Carichner, Table 8.9, p. 213]*

| Aircraft Type | Empennage Area per Wing Area | Empennage Weight per Area |
|---|---|---|
| Jet transports | 0.44 | 5.0 |
| Business jets | 0.43 | 4.3 |
| General aviation — single engine | 0.3 | 1.1 |
| General aviation — twin engine | 0.45 | 1.44 |
| Intelligence, surveillance, and reconnaissance | 0.2 | 3.0 |
| Supersonic fighters — land based | 0.39 | 7.0 |
| Supersonic fighters — carrier based | 0.48 | 6.0 |

Consider the fuselage a cone-cylinder shape, assume a diameter, determine the length required for
each section — gives initial fuselage sizing requirement; length/diameter then juggled for desired
fineness ratio (§8.2). Locate tail at aft end; estimate empennage weight from Table 8.9 (data from
Appendix I). Determine initial c.g.: assign a weight to every item except fuselage, wing, and
wing-mounted items (fuel, engines, weapons), find the c.g. of that ensemble (fuselage c.g. ≈
aircraft c.g., so it's excluded; wing will be placed at the c.g.). Locate the wing so the c.g. is at
~30% of the wing mean aerodynamic chord (refined later). Draw the complete airplane, locate landing
gear per §8.1.7 guidelines, and check tip-back/tip-over angles.

## §8.2 Fuselage Fineness Ratio
*[Nicolai & Carichner, p. 213]*

Fuselage fineness ratio = fuselage length / diameter, `l/d`. Optimum `l/d` differs for subsonic vs
supersonic flow:

- **Subsonic flight**: subsonic `C_D0` is a compromise between skin-friction drag `C_F` and
  pressure drag due to viscous separation `C_DPmin`. Variation of subsonic `C_D0` (based on max
  cross-sectional area) with `d/l` shown in Fig. 8.11 [6]. `d/l = 1` is a sphere; `C_D0` minimum at
  `d/l ≈ 0.33` → **fineness ratio of 3** gives near-minimum subsonic `C_D0`.
- **Supersonic flight**: supersonic `C_D0` on a streamlined (non-blunt-base) body is a compromise
  between skin friction `C_F` and wave drag `C_Dw`. Minimum `C_D0` occurs at **fineness ratio ≈ 14**.
- **Mixed subsonic/supersonic**: use the fineness ratio matching whichever regime dominates flight
  time (e.g., an SST should use fineness ratio 14). If flight is split evenly, compromise between
  the two criteria — e.g., the F-15 and other fighters should use **fineness ratio 8–10** for
  minimum fuselage `C_D0`.

### Fig 8.11 — Subsonic and supersonic zero-lift drag for various fineness ratios
*[Nicolai & Carichner, Fig. 8.11, p. 215]*

**Subsonic** panel — `C_D0` and `C_F` vs `d/l` (0 to 1.0), *(read from plot)*:

| d/l | C_F (skin friction) | C_D0 (total) |
|---|---|---|
| 0.1 | ~0.110 | ~0.108 (≈ C_F, viscous-dominated) |
| 0.2 | ~0.038 | ~0.062 |
| 0.33 | ~0.020 | ~0.053 (minimum C_D0) |
| 0.4 | ~0.016 | ~0.055 |
| 0.6 | ~0.009 | ~0.075 |
| 0.8 | ~0.005 | ~0.095 |
| 1.0 | ~0.003 | ~0.113 |

**Supersonic** panel — `C_D0`, `C_F`, `C_Dw` vs `d/l` (0 to 0.20), *(read from plot)*:

| d/l | C_F | C_D0 (total) |
|---|---|---|
| 0.03 | ~0.095 | ~0.195 |
| 0.05 | ~0.065 | ~0.140 |
| 0.075 | ~0.050 | ~0.130 (minimum C_D0, ≈ fineness ratio 13) |
| 0.10 | ~0.040 | ~0.155 |
| 0.15 | ~0.028 | ~0.230 |
| 0.20 | ~0.022 | ~0.325 |

## §8.3 Fuselage Shapes
*[Nicolai & Carichner, p. 215]*

Fuselage should be streamlined with a tapered aft end — a blunt aft end causes flow separation with
large `C_D0` increase from afterbody separation drag (called "base drag" in supersonic flow).

### §8.3.1 Cone-cylinder
*[Nicolai & Carichner, p. 215]*
`C_D0` easy to determine: subsonically primarily skin friction; supersonically `C_Dw = Cp`.
Pressure coefficient `Cp` obtained from conical-shock charts in Appendix D.

### §8.3.2 Ogive-cylinder
*[Nicolai & Carichner, p. 215]*
Similar to a cone but shaped by arc segments rather than straight lines — better volume for a given
base diameter and length.

### §8.3.3 Power Series-cylinder
*[Nicolai & Carichner, p. 215]*

**Eq (8.1)** *[Nicolai & Carichner, Eq. (8.1), p. 215]*:
```
(R / (d/2)) = (x / l)^n
```
where `R` = radius at station `x`, `d` = base diameter, `l` = length from nose to end of forebody.
`n = 3/4` gives minimum wave drag for this family; `n = 1` gives a cone.

### §8.3.4 Von Kármán Ogive
*[Nicolai & Carichner, p. 216]*

Half-body of given length and diameter, from [7]. **Eq (8.2)** *(unlabeled in text, second
equation of §8.3.4)*:
```
(R/R_max)^2 = (1/π)·[ (2x/l)·sqrt(1-(2x/l)^2) + cos⁻¹(-2x/l) ]     for -l/2 ≤ x ≤ l/2
```
Volume = `(1/2)·l·S_max`, and:
```
C_Dw = 4·S_max / (π·l²)
```

### §8.3.5 Sears–Haack Body
*[Nicolai & Carichner, p. 216]*

Complete body of given length and volume, from [7,8]. Area distribution shown in Fig. 8.12:
```
(R/R_max)^2 = [1 - (2x/l)^2]^(3/2)     for -l/2 ≤ x ≤ l/2
```

### Fig 8.12 — Sears–Haack body geometric characteristics
*[Nicolai & Carichner, Fig. 8.12, p. 216]* — Three stacked panels vs `x/l` (0 to 1.00): (top)
planform outline (pointed ellipse, max width at midlength); (middle) `S/S_max` vs `x/l` — smooth
bump peaking at 1.0 at `x/l=0.5`, zero at both ends; (bottom) `dS/dx` vs `x/l` — starts positive,
crosses zero at `x/l=0.5`, ends negative (symmetric derivative of the S/S_max curve). *(read from
plot, S/S_max and dS/dx are qualitative/smooth curves — no fine-grained tabulation given, as the
closed-form equation above fully determines the curve.)*

Sears–Haack body volume is `(3/16)·l·S_max`, and:
*[Nicolai & Carichner, p. 217]*
```
C_Dw = (9/2)·(π/l²)·S_max
```
where `C_Dw` is referenced to max cross-sectional area `S_max`. Wetted area = `1.8667·(length ×
volume)^(1/2)`.

The designer should not worry too much about entire fuselage shape at this stage — supersonic wave
drag depends on the cross-sectional area distribution of fuselage **plus wing** together, so the
fuselage is often indented or bulged to give a smooth wing-body area distribution. This practice is
**area-ruling** (§8.4).

## §8.4 Transonic and Supersonic Area-Ruling
*[Nicolai & Carichner, p. 217]*

Wave-drag interference effects are greater in transonic/supersonic range than subsonic (higher
local velocities, greater perturbation propagation). The area-rule concept is the most successful
and systematic method for predicting transonic/supersonic wave drag.

Area-rule method is based on supersonic slender-body theory [7,9]: at large distances from the
body, disturbances are independent of component arrangement and are only a function of
cross-sectional area distribution — so a wing-body combination's drag can be calculated as though
it were an equivalent body of revolution with the same cross-sectional areas (Fig. 8.13, for
`M=1`).

For `M∞ ≥ 1.0`, cross-sectional areas `S(x)` are taken along planes inclined at angle
`μ = arcsin(1/M∞)` to the x-axis; there is a different `S(x)` for each roll angle `φ` (Fig. 8.14).

Once `S(x)` is determined (one per `φ` angle, for `M∞ > 1`), wave drag from supersonic slender-body
(linear) theory [9]:

**Eq (8.1)** *[Nicolai & Carichner, Eq. (8.1), p. 217]*:
```
C_Dw = (-1 / (2π·S_ref)) · ∫₀ˡ ∫₀ˡ (d²S/dx²)(d²S/dξ²)·ln(x-ξ) dx dξ
```
For `M∞ > 1`, `C_Dw` is determined for each roll angle `φ` and averaged. Application usually
requires automatic computing equipment.

Eq. (8.1) shows it's desirable to have a smooth `dS/dx` distribution, since any discontinuity gives
large `d²S/dx²` or `d²S/dξ²` values. Most common practice: indent or "Coke-bottle" the fuselage
enough to permit adding the wing without a sharp `S(x)` discontinuity. If a wing-body combination's
cross-sectional area distribution at a given `M∞` matches a Sears–Haack distribution (Fig. 8.12),
the configuration has near-minimum wave drag for that length/volume.

### Fig 8.13 — Equivalent body for a wing–body–tail combination at M∞ = 1
*[Nicolai & Carichner, Fig. 8.13, p. 218]* — Three panels: (a) wing-body-tail planform sketch with
overall length `l` labeled; (b) `S(x)` vs `x` — cross-sectional area distribution showing bumps
where wing/tail cross the body; (c) equivalent body of revolution — smooth fuselage-like shape
with local bulges corresponding to the wing/tail area contributions. No plotted numeric data
(schematic).

### Fig 8.14 — Area distribution given by intersection of Mach planes for M∞ > 1
*[Nicolai & Carichner, Fig. 8.14, p. 218]* — Two 3D schematic panels showing Mach-angle-inclined
cutting planes (angle `μ` left panel, roll angle `φ` right panel) intersecting a wing-body model,
each with a corresponding `S(x)`-like area-distribution curve shown below it (asymmetric bump
shapes differing between the two roll/cut angles). No plotted numeric data (schematic).

If the cross-sectional area distribution of a wing-body combination at a particular `M∞` matches a
Sears–Haack distribution, that configuration gives minimum wave drag at that `M∞` — but a wing-body
configured for minimum wave drag at one Mach number usually aggravates wave drag at other Mach
numbers (Fig. 8.15, data from [10]).

### Fig 8.15 — Wave drag of bodies with elliptic wings, with/without area-ruling
*[Nicolai & Carichner, Fig. 8.15, p. 219]* — `C_D0` vs `M∞` (0.8–1.4) for three configurations:
Unmodified, Modified for M=1.0, Modified for M=1.2. *(read from plot)*:

| M∞ | Unmodified C_D0 | Modified-for-M=1.0 C_D0 | Modified-for-M=1.2 C_D0 |
|---|---|---|---|
| 0.8 | 0.010 | 0.012 | 0.011 |
| 0.9 | 0.010 | 0.012 | 0.011 |
| 0.95 | 0.011 | 0.013 | 0.012 |
| 1.0 | 0.021 | 0.012 | 0.015 |
| 1.05 | 0.021 | 0.016 | 0.017 |
| 1.1 | 0.023 | 0.019 | 0.019 |
| 1.2 | 0.021 | 0.021 | 0.019 |
| 1.3 | 0.020 | 0.021 | 0.019 |
| 1.4 | 0.019 | 0.022 | 0.019 |

Unmodified shows a sharp `C_D0` rise starting near `M∞≈0.95` and peaking near `M∞≈1.0–1.1`; both
area-ruled ("modified") curves show a lower, delayed, more gradual rise — the M=1.0-tailored curve
is lowest right at M=1.0, the M=1.2-tailored curve is lowest right at M=1.2, each aggravating drag
somewhat away from its design Mach.

Aircraft before area-ruling might have the cross-sectional area distribution shown in Fig. 8.16.
Aircraft are usually area-ruled for `M∞ = 1` because of the tendency for a "thrust pinch" at
`M∞ = 1`; however, if the aircraft spends a major mission portion at `M > 1` (e.g., Concorde), it
should be area-ruled along Mach-angle-inclined planes (Fig. 8.14) instead. Cross-sectional area
does **not** include the area of airflow through the engine. The designer takes the raw area
distribution (Fig. 8.16) and massages it until free of discontinuities, resembling a Sears–Haack
body more closely than it originally did.

### Fig 8.16 — Typical cross-sectional area distribution for an aircraft before area-ruling
*[Nicolai & Carichner, Fig. 8.16, p. 219]* — Cross-Sectional Area vs `x/l` (0 to 1), stacked/layered
area contributions labeled: Canard (small early bump), Canopy (small bump), Fuselage (labeled "less
airflow through inlet and engine" — broad base hump), Wing (large central peak, largest
contributor), Nacelles (labeled "less airflow area" — peak overlapping/exceeding the wing peak
near the aft-center), Vertical Tail (small bump near the tail). Qualitative composite-area
schematic; no numeric axis values given (relative area shape only).

## References
*[Nicolai & Carichner, Chapter 8 References, p. 220]*

1. Roskam, J., "Airplane Design," Roskam Aviation and Engineering Corp., Ottawa, KS, 1989.
   [Available via www.darcorp.com (accessed 31 Oct. 2009).]
2. "Airworthiness Standards: Part 25—Transport Category Airplanes," Federal Aviation Regulation,
   Vol. 3, U.S. Department of Transportation, U.S. Government Printing Office, Washington, DC, 2009.
3. Whitford, R., *Design for Air Combat*, Jane's Publ., New York, 1987.
4. Wood, K. D., *Aircraft Design*, Vol. 1, Johnson, Boulder, CO, 1966.
5. *Aerospace Daily*, Vol. 135, No. 15, Sep. 1985, p. 113.
6. Miele, A., *Flight Mechanics*, Vol. 1, Addison Wesley, Reading, MA, 1962.
7. Ashley, H., and Landahl, M., *Aerodynamics of Wings and Bodies*, Addison Wesley, Reading, MA,
   1965.
8. Sears, W. R., "On Projectiles of Minimum Drag," *Quarterly Mathematics Series*, Vol. 4, No. 4,
   1947, p. 361.
9. Liepmann, H. W., and Roshko, A., *Elements of Gasdynamics*, Wiley, New York, 1957.
10. Nelson, R. L., and Walsh, C. J., "Some Examples of the Application of the Transonic and
    Supersonic Area Rules to the Prediction of Wave Drag," NASA TN-D-446, Sept. 1960.

---

*Chapter 8 complete (§§8.1–8.4, Tables 8.1–8.9, Figs 8.1–8.16, Eq. 8.1, References [1]–[10]).
Next: Chapter 9 — High-Lift Devices.*