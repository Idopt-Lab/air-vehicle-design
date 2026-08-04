# Chapter 11 — Preliminary Sizing of the Vertical and Horizontal Tails

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 11 "Preliminary Sizing of the Vertical and Horizontal Tails," printed pp. 283–294.

Text-layer inventory (to confirm completeness): Fig 11.1, Tables 11.1–11.8, Eqs (11.1)–(11.3).

---

## §11.1 Tail Volume Coefficient Approach
*[Nicolai & Carichner, p. 284]*

At this point the aircraft has been sized (TOGW estimated) and has a wing-body configuration. Tails
are now added and their aerodynamics determined. Before tail aerodynamics can be incorporated, the
tail's location (front, back, or none), shape, and size must be known.

Tail appearance/location is a design decision: determine their mean aerodynamic chord (mac), decide
location, then estimate the distance from the initial c.g. location (Chapter 8) to the macs of the
vertical and horizontal tails (`c̄_h`, `c̄_v`) — the moment-arm length of pitch/yaw stability and
control devices (Fig. 11.1).

Sizing tail surfaces requires precise knowledge of c.g. location (subject of Chapters 21–23), but
c.g. location depends on knowing tail-surface weight (size) — a circular dependency. Thus tail
surfaces are sized here via a shortcut: the **tail volume coefficient** approach, based on the
observation that these volume coefficients are similar for like classes of existing aircraft [1-3].

## §11.2 Sizing the Vertical Tail
*[Nicolai & Carichner, p. 284]*

Vertical tail provides directional control/stability (motion about the Z axis). May be sized by one
or more criteria (discussed in Chapter 23) [1,2]:

1. **Landing and takeoff.** Low-speed one-engine-out or severe crosswind conditions.
2. **Maneuverability.** Required maneuverability for a fighter aircraft may size the vertical tail.
3. **Subsonic cruise directional stability.** MIL-HDBK-1797 and FAR Parts 23/25 require directional
   static stability derivative `C_nβ > 0` for normal cruise. Typical `C_nβ` for business jets and
   commercial transports: 0.08–0.17 per radian at Mach = 0.8.
4. **High-speed directional stability.** For high speed (`M > 2.0`), `C_nβ` decreases so the
   vertical tail might be sized to give a minimum `C_nβ = 0.08` at high speed.

At this design point there's insufficient information to size the vertical tail by any of these
four criteria — tail size and c.g. location have to be realistic so total aircraft drag can be
determined. Historical trends determine `S_VT` at this point.

A convenient parameter to compare across aircraft classes is the vertical tail volume coefficient:

### Fig 11.1 — Illustration of reference geometry for tail sizing (inset is a T-45)
*[Nicolai & Carichner, Fig. 11.1, p. 285]* — Three-view line drawings of a T-45 Goshawk trainer:
(top) top view labeling wing span `b`, `S_ref`, mac `c̄`, horizontal tail `S_HT`, `c̄_H`, `ℓ_HT`
(distance from c.g. to horizontal-tail mac quarter-chord), c.g. location and c/4 location markers;
(bottom) side view labeling vertical tail `S_VT`, `c̄_V`, `ℓ_VT` (distance from c.g. to vertical-tail
mac quarter-chord), main-gear tip-back angle `θ_MG`. Inset photo: T-45 in flight. No plotted numeric
data (labeled reference diagram).

**Eq (11.1)** *[Nicolai & Carichner, Eq. (11.1), p. 286]*:
```
C_VT = (ℓ_VT · S_VT) / (b · S_ref)
```
where `b` = wing span, `S_ref` = reference wing area, `ℓ_VT` = distance between initial c.g. estimate
and quarter-chord of vertical tail mac; `S_VT` = exposed side-view area of the vertical tail
(Fig. 11.1).

Tables 11.1–11.7 show `C_VT` for classes of existing aircraft. Table 11.8 lists typical volume
coefficient values for preliminary tail sizing. Designer selects an appropriate `C_VT` for a similar
aircraft class and solves Eq. (11.1) for `S_VT`.

## §11.3 Sizing the Horizontal Tail (Aft Tailplane)
*[Nicolai & Carichner, p. 286]*

Horizontal tail provides longitudinal stability and control. The horizontal tail (aft tailplane and
canard) may be sized by one or more of the following conditions (discussed in Chapter 23) [1,2]:

1. **Static longitudinal stability.** Static longitudinal stability derivative `C_mα` should be
   negative at all flight speeds (represents tendency to resist moving away from equilibrium
   flight). However, it cannot be too negative, as lift on the tail to trim the aircraft would
   [continues next page].

### Table 11.1 — Tail Volume Coefficients for Light Reciprocating-Propeller Aircraft
*[Nicolai & Carichner, Table 11.1, p. 286]*

| Aircraft | No. Engines | C_HT | C_VT |
|---|---|---|---|
| Cessna Skywagon 207 | 1 | 0.92 | 0.046 |
| Cessna Cardinal | 1 | 0.60 | 0.038 |
| Cessna Skylane | 1 | 0.71 | 0.047 |
| Piper Cherokee | 1 | 0.61 | 0.037 |
| Bellanca Skyrocket | 1 | 0.61 | 0.037 |
| Grumman Tiger | 1 | 0.76 | 0.024 |
| Cessna 310 | 2 | 0.95 | 0.063 |
| Cessna 402 | 2 | 1.07 | 0.08 |
| Cessna 414 | 2 | 0.93 | 0.071 |
| Piper PA-31 | 2 | 0.84 | 0.056 |
| Piper Chieftain | 2 | 0.72 | 0.055 |
| Piper Cheyenne I | 2 | 0.85 | 0.045 |
| Beech Duchess | 2 | 0.67 | 0.053 |
| Beech Duke B60 | 2 | 0.64 | 0.060 |

### Table 11.2 — Tail Volume Coefficients for Turbofan (TF) and Turboprop (TP) Business Aircraft
*[Nicolai & Carichner, Table 11.2, p. 287]*

| Aircraft | Engines | C_HT | C_VT |
|---|---|---|---|
| Beech 1900 | Turboprop | 1.33 | 0.076 |
| Beech B200 | Turboprop | 0.91 | 0.065 |
| Cessna Conquest | Turboprop | 0.91 | 0.071 |
| DeHavilland DHC-6 | Turboprop | 0.91 | 0.077 |
| DeHavilland DHC-7 | Turboprop | 1.11 | 0.076 |
| DeHavilland DHC-8 | Turboprop | 1.47 | 0.121 |
| BAE 31 | Turboprop | 1.22 | 0.120 |
| Dassault Falcon 10/20/50 | Turbofan | 0.68 | 0.063 |
| Cessna Citation 500 | Turbofan | 0.73 | 0.081 |
| Cessna Citation II | Turbofan | 0.64 | 0.062 |
| Cessna Citation III | Turbofan | 0.99 | 0.086 |
| Learjet 24 | Turbofan | 0.67 | 0.077 |
| Learjet 35 | Turbofan | 0.65 | 0.066 |
| Learjet 55 | Turbofan | 0.76 | 0.086 |
| BAE 125 | Turbofan | 0.72 | 0.061 |

### Table 11.3 — Tail Volume Coefficients for TF and TP Transports
*[Nicolai & Carichner, Table 11.3, p. 287]*

| Aircraft | Engines | C_HT | C_VT |
|---|---|---|---|
| Lockheed C-130E | Turboprop | 0.94 | 0.053 |
| Lockheed C-5A | Turbofan | 0.62 | 0.079 |
| Lockheed L-1011 | Turbofan | 0.83 | 0.055 |
| Boeing 727-200 | Turbofan | 0.82 | 0.11 |
| Boeing 737-200 | Turbofan | 1.28 | 0.10 |
| Boeing 737-300 | Turbofan | 1.35 | 0.10 |
| Boeing 747-200 | Turbofan | 0.74 | 0.079 |
| Boeing 757-200 | Turbofan | 1.15 | 0.086 |
| Boeing 767-200 | Turbofan | 0.94 | 0.067 |
| DC-9/S 80 | Turbofan | 0.96 | 0.062 |
| DC-10-30 | Turbofan | 0.90 | 0.060 |
| Airbus A-300 | Turbofan | 1.12 | 0.094 |
| Airbus A-310 | Turbofan | 1.09 | 0.098 |
| BAE 146-200 | Turbofan | 1.48 | 0.12 |

### Table 11.4 — Tail Volume Coefficients TF and TP Military Trainers
*[Nicolai & Carichner, Table 11.4, p. 288]*

| Aircraft | Engines | C_HT | C_VT |
|---|---|---|---|
| T-34 | Turboprop | 0.76 | 0.048 |
| Aero L-39 | Turbojet | 0.58 | 0.083 |
| Alphajet | Turbojet | 0.43 | 0.084 |
| Aermacchi MB-339 | Turbojet | 0.52 | 0.043 |
| BAE Hawk/T-45 | Turbojet | 0.61 | 0.059 |
| Cessna T-37 | Turbojet | 0.68 | 0.041 |

produce a large trim drag. Business jets and commercial transports have `C_mα` values of -0.7 to
-1.5 per radian.

2. **Maneuverability.** Fighter aircraft have to *maneuver* (move away from an equilibrium
   condition), so their `C_mα` values would be closer to 0 (neutral stability) or even positive
   (unstable — requires a stability augmentation system, Chapter 23), which makes them maneuverable.
3. **Landing and takeoff.** The horizontal tail must be powerful enough (large enough) to rotate the
   aircraft about the main gear at `V_TO` to `α_TO` for takeoff. Also must be large enough to rotate
   the aircraft and trim it at low speed to `C_L = 0.8·C_Lmax` for landing approach.
4. **Low trim drag.** Horizontal tail size should be such that drag due to trim load on the tail at
   cruise is less than 10% of total aircraft drag. Otherwise trim loads are too large and associated
   trim drag degrades aircraft performance.

### Table 11.5 — Tail Volume Coefficients for Supersonic Transport and Bomber Aircraft
*[Nicolai & Carichner, Table 11.5, p. 288]*

| Aircraft | C_HT | C_VT | C_C |
|---|---|---|---|
| Rockwell XB-70 | 0 | 0.034 | 0.10 |
| Tu-144 | 0 | 0.081 | 0 |
| Tu-22M | 1.11 | 0.087 | 0 |
| Tu-22 | 0.44 | 0.059 | 0 |
| Concorde | 0 | 0.08 | 0 |
| Rockwell B-1B | 0.8 | 0.039 | 0 |
| Convair B-58A | 0 | 0.057 | 0 |
| North American F-108 | 0 | 0.045 | 0.11 |

*`C_C` = canard volume coefficient (nonzero for canard-configured aircraft: XB-70, F-108; zero for
conventional aft-tail configurations).*

### Table 11.6 — Tail Volume Coefficients for Fighter Aircraft
*[Nicolai & Carichner, Table 11.6, p. 289]*

| Aircraft | C_HT | C_VT |
|---|---|---|
| Convair F-106 | 0 | 0.075 |
| Grumman A-6A | 0.41 | 0.069 |
| Grumman F-14A | 0.46 | 0.06 |
| North American F-86 | 0.203 | 0.0475 |
| North American F-100 | 0.36 | 0.0584 |
| Northrop F-5E | 0.4 | 0.098 |
| McDonnell Douglas F-4E | 0.26 | 0.054 |
| McDonnell Douglas F-15 | 0.2 | 0.098 |
| General Dynamics F-111A | 1.28 | 0.064 |
| General Dynamics FB-111 | 0.75 | 0.054 |
| **General Dynamics F-16** | **0.3** | **0.094** |
| Cessna A-37B | 0.68 | 0.041 |
| MIG-21 | 0.214 | 0.08 |
| MIG-23 | — | 0.06 |
| MIG-25 | 0.36 | 0.1 |
| SU-7 | 0.4 | 0.1 |
| Viggen | 0 | 0.0834 |

*Note: F-16 row (`C_HT = 0.3`, `C_VT = 0.094`) is directly relevant to this repo's F-16A Brandt
baseline — useful as an independent cross-check for tail-sizing/volume-coefficient assumptions
against `F16Baseline()`.*

Later the horizontal tail (aft tailplane or canard) will be sized to the preceding criteria. For
now, use historical trends of horizontal tail volume coefficients, defined as:

**Eq (11.2)** *[Nicolai & Carichner, Eq. (11.2), p. 289]*:
```
C_HT = (ℓ_HT · S_HT) / (c̄ · S_ref)
```
where `c̄` = wing mean aerodynamic chord; `ℓ_HT` = distance from initial c.g. estimate to
quarter-chord of the horizontal tail mac; `S_ref` = wing reference area; `S_HT` = total planform
area of the horizontal tail (includes aft fuselage carryover, Fig. 11.1).

### Table 11.7 — Tail Volume Coefficients for Intelligence, Surveillance, and Reconnaissance Aircraft
*[Nicolai & Carichner, Table 11.7, p. 289]*

| Aircraft | C_HT | C_VT |
|---|---|---|
| Lockheed Martin U-2S | 0.34 | 0.014 |
| Northrop Global Hawk | 0.32 | 0.0186 |
| Boeing Condor | 0.53 | 0.012 |

Tables 11.1–11.7 show `C_HT` for various classes of existing aircraft. Table 11.8 lists typical
volume coefficient values for preliminary tail sizing. Designer selects an appropriate `C_HT` for a
similar aircraft class and solves Eq. (11.2) for `S_HT`.

### Table 11.8 — Typical Values of Volume Coefficients for Preliminary Tail Sizing
*[Nicolai & Carichner, Table 11.8, p. 290]*

| Aircraft | C_HT | C_VT |
|---|---|---|
| Sailplane [3] | 0.53 | 0.022 |
| ISR | 0.34 | 0.014 |
| General aviation (one-engine propeller) | 0.7 | 0.032 |
| General aviation (two-engine propeller) | 0.76 | 0.06 |
| Business aircraft (two-engine) | 0.91 | 0.09 |
| Commercial jet transports | 1.0 | 0.083 |
| Military jet trainer | 0.6 | 0.06 |
| Jet fighter (all speeds) | 0.5 | 0.076 |

## §11.4 Horizontal Tail (Canard)
*[Nicolai & Carichner, p. 290]*

For the canard configuration, the wing aerodynamic center (a.c.) is behind the aircraft center of
gravity, so the wing is stabilizing (contributes a negative `C_mα`). The canard "pulls" the
configuration a.c. (neutral point) forward — because the canard is destabilizing, it is not for
stability but for **control**. The canard's contribution is statically destabilizing. However, the
destabilizing nature of the canard can be helpful for supersonic speeds, offsetting the aft
movement of the a.c. from the wing. Canard `S_C` sized by the same criteria discussed for the aft
tailplane in §11.3.

Canard volume coefficient:

**Eq (11.3)** *[Nicolai & Carichner, Eq. (11.3), p. 290]*:
```
C_C = (ℓ_C · S_C) / (c̄ · S_ref)
```
where `ℓ_C` = distance from c.g. to the mac of the canard; `S_C` = exposed top-view area of the
canard. A value of `C_C = 0.10–0.11` is suggested for preliminary canard sizing.

## §11.5 Tailless
*[Nicolai & Carichner, p. 291]*

For aircraft without a horizontal tail (e.g., F-106, B-58), `C_HT = 0`. Previously suggested `C_VT`
values are appropriate for sizing the vertical tail. Here the wing a.c. is behind the c.g., so the
wing is stabilizing.

Longitudinal control must come from the wing. The wing has TE surfaces (positive and negative
deflection flaps) that give the wing positive or negative camber to control the pitching moment.

## §11.6 Vertical Location of the Aft Horizontal Tail
*[Nicolai & Carichner, p. 291]*

The aft horizontal tail is initially located along the X axis based on an initial fuselage-length
estimate; then sized using historical tail volume coefficients. Final horizontal location is
established once propulsion-system length is known (Chapters 15/16); a refined weight estimate
(Chapter 20) is performed along with stability/control analysis (Chapter 21). However, the vertical
location of the horizontal tail is unknown at this stage — not essential to know unless the
designer is anxious to close out the design.

Horizontal tails are located vertically for several reasons: (1) to reduce being blanked by wing
wake as it stalls (loss of pitch control, §21.7, Fig. 21.15); (2) to move out of hot gas exhaust from
aft-fuselage-mounted engines (Fig. 8.7); (3) overall aircraft appearance.

## §11.7 Horizontal Location of the Vertical Tail
*[Nicolai & Carichner, p. 291]*

A spin is rotation about the Z axis with the aircraft in a 30–60° nose-down attitude from the
horizontal. The rudder on the vertical tail is the main spin-recovery surface — procedure: stop the
spin with opposite rudder, then recover from the steep dive using the horizontal tail. For
high-maneuvering aircraft (fighters, trainers) it's important the rudder not be blanked by the
horizontal tail. Analysis is graphical: draw two lines, one at 30° from the horizontal-tail trailing
edge and one at 60° from the leading edge, and position the rudder outside this region. **The F-15,
F-16, F-18, and T-46 are good spin-recovery aircraft.**

## References
*[Nicolai & Carichner, Chapter 11 References, p. 292]*

1. Roskam, J., *Airplane Design*, Pt. II, Roskam Aviation and Engineering Co., Ottawa, KS 66067,
   1989. [Available via www.darcorp.com (accessed 31 Oct. 2009).]
2. McCormick, B., *Aerodynamics, Aeronautics, and Flight Mechanics*, Wiley, New York, 1995.
3. Thomas, F., *Fundamentals of Sailplane Design*, College Park Press, College Park, MD, 1999.

---

*Chapter 11 complete (§§11.1–11.7, Tables 11.1–11.8, Fig 11.1, Eqs 11.1–11.3, References [1]–[3]).
Next: Chapter 12 — Designing for Survivability (Stealth).*
