# Chapter 11 — Landing Gear and Subsystems

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 11
"Landing Gear and Subsystems," printed pp. 337-378.

Mix of design-guidance prose, a few statistical sizing equations/tables for tires, brakes, shock
struts, and seaplane hulls, and a subsystems overview (hydraulics, electrical, pneumatic/ECS,
auxiliary power, accessory drives, avionics). All equations and tables captured; photo/schematic
figures noted with "no plotted data."

---

## §11.0 Introduction

Landing-gear design is often the most troublesome part of a configuration layout: tires and shock
struts must be sized correctly (and grow if the aircraft gets heavier), wheels must sit correctly in
the down position, and a retractable gear must fold away without cutting up structure, fuel tankage,
or bulging into the airflow. Fig. 11.1 (typical multiwheel main gear, B-70) illustrates the assembly
this chapter designs around: retraction linkage, axle-beam fold/compensating actuator, brake
assembly, tires/wheels, downlock and drag brace.

### Fig 11.1 — Typical multiwheel main landing gear
*[Raymer, Fig. 11.1, p. 338]* — Labeled assembly drawing (B-70 main gear): retraction linkage,
axle-beam fold and compensating actuator, brake assembly, tires and wheels, downlock and drag-brace
installation. No plotted data (reference diagram).

## §11.1 Landing-Gear Arrangements

Six common arrangements (Fig. 11.2): **single main** (sailplanes, wheel forward or aft of c.g. with a
skid); **bicycle** (two main wheels fore/aft of c.g. plus wing outriggers — forces a flat takeoff/
landing attitude, seen on B-47, Harrier); **taildragger/"conventional"** (two main wheels forward of
c.g. plus tailwheel — less drag/weight, better rough-field lift, but directionally unstable, prone to
ground-loop, requires careful rudder work at touchdown); **tricycle** (two main wheels aft of c.g.
plus nosewheel — stable on the ground, tolerates crab-angle landings, gives forward visibility and a
flat cabin floor, the most common arrangement today); **quadricycle** (like bicycle but wheels at the
fuselage sides — flat attitude required, used on B-52 for a low cargo floor); **multi-bogey** (2/4/6+
wheels per strut sharing load as aircraft weight grows).

### Fig 11.2 — Landing-gear arrangements
*[Raymer, Fig. 11.2, p. 339]* — Six schematic plan/side views: single main, bicycle, taildragger,
tricycle, quadricycle, multi-bogey. No plotted data (reference diagram).

Wheel-count guidance by aircraft weight: single main wheel per strut typical under ~50,000 lb
{22,680 kg} (though two per strut is always safer against a flat tire); two wheels per strut typical
50,000-150,000 lb {22,680-68,040 kg} (sometimes up to ~250,000 lb {113,400 kg}); four-wheel bogey
typical 200,000-400,000 lb {90,720-181,440 kg}; over 400,000 lb {181,440 kg}, four bogeys of 4-6
wheels each. Twin nosewheels are standard except on light aircraft/some fighters (redundancy against
a flat nose tire); carrier aircraft need twin nosewheels ≥19 in. {483 cm} diameter to straddle the
catapult shuttle; the C-5 uses four nosewheels to spread load on soft fields.

### Fig 11.3 — Bicycle landing gear
*[Raymer, Fig. 11.3, p. 341]* — Side-view geometry: wheel base labeled, c.g. must fall aft of the
midpoint between the two wheels ("> l/2" callout). No further plotted data.

### Fig 11.4 — Taildragger landing gear
*[Raymer, Fig. 11.4, p. 341]* — Side view: tail-down angle 10-15 deg (static position), 9-in.
{23-cm} minimum propeller ground clearance at takeoff attitude; c.g. envelope 16-25 deg back from
vertical measured from the main-wheel location; lateral wheel separation to prevent overturn must
exceed 25 deg off the c.g. measured from the rear in tail-down attitude.

### Fig 11.5 — Tricycle landing-gear geometry
*[Raymer, Fig. 11.5, p. 342]* — Side view showing: rotation to 90% CLmax angle of attack (~10-15 deg
for most types, checked against tailstrike/tip-back and a 5 deg wingtip roll clearance check);
tipback angle (max nose-up attitude, tail touching, strut fully extended — vertical-from-main-wheel
angle to the c.g. must exceed the tipback angle or 15 deg, whichever is larger; carrier aircraft
often exceed 25 deg, forcing the c.g. well forward of the main wheels); overturn angle (c.g.-to-main
-wheel angle seen from the rear with main wheel aligned to nosewheel — must not exceed 63 deg, 54 deg
for carrier aircraft); optimum strut-travel angle ~7 deg (acceptable range: vertical to 10 deg aft of
vertical). Tricycle-gear aircraft need 7-in. {18-cm} propeller ground clearance, checked with the
nose strut compressed and main struts fully extended (worst case for panic braking/wheelbarrowing).

Nosewheel load guidance: optimum nosewheel share of aircraft weight is about 8-15% (over most-fwd/
most-aft c.g. range) — above 20% implies the main gear sits too far aft, below 5% gives inadequate
steering traction; tipback angle much over 25 deg risks nose-up "porpoising" on takeoff.

## §11.2 Tire Sizing

The "wheel" is the metal rim; the "tire" is the rubber; "brake" is inside the wheel; "wheel" often
colloquially means the whole assembly. Main tires typically carry ~90% of aircraft weight, nose
tires ~10% statically but higher dynamic loads (braking pitches weight onto the nose, as on a
motorcycle).

### Table 11.1 — Statistical Tire Sizing
*[Raymer, Table 11.1, p. 344]* — `Main-wheel diameter or width (in.) = A · W_w^B`, English units
(`W_w` = weight on wheel, lb); metric form uses (in.)→(cm) with a different `A`.

| Aircraft Type | Diameter A | Diameter B | Width A | Width B |
|---|---|---|---|---|
| General aviation | 1.51 | 0.349 | 0.7150 | 0.312 |
| Business twin | 2.69 | 0.251 | 1.170 | 0.216 |
| Transport/bomber | 1.63 | 0.315 | 0.1043 | 0.480 |
| Jet fighter/trainer | 1.59 | 0.302 | 0.0980 | 0.467 |

Metric form, `Main wheel diameter or width (cm) = A · W_w^B` (`W_w` in appropriate metric weight
unit): General aviation `A=5.1, B=0.349` (diam.), `A=2.3, B=0.216` (width); Business twin `A=8.3,
B=0.251` (diam.), `A=3.5, B=0.480` (width); Transport/bomber `A=5.3, B=0.315` (diam.), `A=0.39,
B=0.467` (width, `[verify p. 344]` — OCR gives a value that looks anomalously small relative to the
other rows' width-A entries; digit legibility is poor at this position in the scan); Jet fighter/
trainer `A=5.1, B=0.302` (diam.), `A=0.36, B=0.216` (width, `[verify p. 344]` — same legibility
caveat).

These estimate main tire size (main tires ≈90% of aircraft weight); increase diameter/width ~30% for
rough/unpaved-runway operation. Nose tires ≈60-100% of main-tire size (bicycle/quadricycle front
tires match main size; taildragger aft/tailwheel tires ≈1/4 to 1/3 of main size). Final tire
selection for a real layout comes from a manufacturer's catalog, sized to the smallest tire rated for
the calculated static+dynamic loads.

### Fig 11.6 — Wheel load geometry
*[Raymer, Fig. 11.6, p. 344]* — Side-view free-body sketch defining `N_a` (aft-gear reaction), `N_f`
(fwd/nose-gear reaction), wheelbase `B`, c.g. (most-fwd and most-aft), height `H` — the geometry
behind Eqs. (11.1)-(11.4). No plotted data (schematic).

Static/dynamic wheel-load equations (`W` = aircraft weight, `B` = wheelbase, `M` = distance from
nose gear to aft c.g., other symbols per Fig. 11.6):

```
(Max Static Load)_main = W · Na/B                                    (11.1)
(Max Static Load)_nose = W · Nf/B                                     (11.2)
(Min Static Load)_nose = W · M/B                                      (11.3)
(Dynamic Braking Load)_nose = 10·H·W / (g·B)                          (11.4)
```
*[Raymer, Eqs. (11.1)-(11.4), p. 344]* — loads are divided by the number of main or nose tires to
get the per-tire load `W_w` used for tire selection. Eq. (11.4) assumes braking friction coefficient
`µ = 0.3` (typical hard runway), i.e. a 10 ft/s² {3 m/s²} deceleration.

Nose-gear load-fraction checks: `Ma/B` (min-static fraction) should be **> 0.05**; `Mf/B` (max-static
fraction) should be **< 0.20** (0.08 and 0.15 preferred) *[Raymer, p. 345]*. For FAR 25 aircraft add a
7% margin to all wheel loads; add a further ~25% for design growth allowance.

### Table 11.2 — Tire Data
*[Raymer, Table 11.2, pp. 345-347]* — Manufacturer statistical tire-book data by tire designation
(Type III — low-pressure, piston aircraft; Type VII — higher-pressure, most jets; Three-part-name —
newest/highest-pressure, designated by outside diameter × width-rim diameter), each row giving rated
static load (lb), inflation pressure (psi), max speed (kt or mph), tire width (in.), outside diameter
(in.), rolling radius (in.), wheel (rim) diameter (in.), and number of plies. OCR of this table is
badly fragmented by column-reflow in the scan (values and row labels separated across many
disjoint lines); representative entries recovered cleanly enough to cite:

| Designation | Max Load (lb) | Max Pressure (psi) | Max Speed | Width (in.) | Outside Diam. (in.) | Rolling Radius (in.) | Wheel Diam. (in.) | Plies |
|---|---|---|---|---|---|---|---|---|
| 5.00-4 (Type III) | 1200 | 55 | 120 | 5.05 | 13.25 | 5.2 | 4.0 | 6 |
| 7.00-8 (Type III) | 2400 | 46 | 120 | 7.30 | 20.85 | 8.3 | 8.0 | 6 |
| 8.50-10 (Type III) | 3250 | 41 | 120 | 9.05 | 26.30 | 10.4 | 10.0 | 6 |
| 9.50-16 (Type III) | 9250 | 90 | 160 | 9.70 | 33.35 | 13.9 | 16.0 | 10 |
| 12.50-16 (Type III) | 12,800 | 75 | 160 | 12.75 | 38.45 | 15.6 | 16.0 | 12 |
| 20.00-20 (Type III) | 46,500 | 125 | 174 kt | 20.10 | 56.00 | 22.1 | 20.0 | 26 |
| 16×4.4 (Type VII) | 1100 | 55 | 210 | 4.45 | 16.00 | 6.9 | 8.0 | 4 |
| 18×4.4 (Type VII) | 2100 | 100 | 174 kt | 4.45 | 17.90 | 7.9 | 10.0 | 6 |
| 18×4.4 (Type VII, hi-pres.) | 4350 | 225 | 217 kt | 4.45 | 17.90 | 7.9 | 10.0 | 12 |
| 24×5.5 (Type VII) | 11,500 | 355 | 174 kt | 5.75 | 24.15 | 10.6 | 14.0 | 16 |
| 30×7.7 (Type VII) | 16,500 | 270 | 230 | 7.85 | 29.40 | 12.7 | 16.0 | 18 |
| 36×11 (Type VII) | 26,000 | 235 | 217 kt | 11.50 | 35.10 | 14.7 | 16.0 | 24 |
| 40×14 (Type VII) | 33,500 | 200 | 174 kt | 14.00 | 39.80 | 16.5 | 16.0 | 28 |
| 46×16 (Type VII) | 48,000 | 245 | 225 | 16.00 | 45.25 | 19.0 | 20.0 | 32 |
| 50×18 (Type VII) | 41,770 | 155 | 225 | 17.50 | 49.50 | 20.4 | 20.0 | 26 |
| 18×4.25-10 (Three-part) | 2300 | 100 | 210 | 4.70 | 18.25 | 7.9 | 10.0 | 6 |
| 21×7.25-10 (Three-part) | 5150 | 135 | 210 | 7.20 | 21.25 | 9.0 | 10.0 | 10 |
| 28×9.00-12 (Three-part) | 16,650 | 235 | 156 kt | 8.85 | 27.60 | 11.6 | 12.0 | 22 |
| 37×14.0-14 (Three-part) | 25,000 | 160 | 225 | 14.0 | 37.0 | 15.1 | 14.0 | 24 |
| 47×18-18 (Three-part) | 43,700 | 175 | 195 kt | 17.9 | 46.9 | 19.2 | 18.0 | 30 |
| 52×20.5-23 (Three-part) | 63,700 | 195 | 235 | 20.5 | 52.0 | 21.3 | 23.0 | 30 |

`[verify p. 345-347]` — table transcription is representative, not necessarily row-complete; the
scanned page's multi-column layout defeats a clean linear OCR extraction. Use directly against a
current tire manufacturer's "tire book" (as the text itself recommends) for any load-critical
sizing.

Selection rule: pick the smallest catalog tire whose rated static/dynamic load exceeds the
calculated `W_w`. Dynamic overload allowance: **Type III tires** permitted 1.4× static rated load;
**Type VII / new-design tires** permitted 1.3× static rated load. Nose tire: divide total (static +
dynamic) load by 1.4 or 1.3 as appropriate, size against both the static-only and the
dynamic-derated criteria, and take the larger resulting tire.

A tire's load capacity is essentially internal pressure × footprint (contact) area (Fig. 11.7):

```
W_w = P · A_p                                                          (11.5)
A_p = 2.3 · sqrt(w·d) · (d/2 - R_r)                                    (11.6)
```
*[Raymer, Eqs. (11.5)-(11.6), p. 348]* — where `P` = inflation pressure, `A_p` = pavement contact
("footprint") area, `w` = tire width, `d` = tire outside diameter, `R_r` = rolling radius (tire
radius under load, typically ⅔ of unloaded tire radius). Eq. (11.6) is cited to Ref. [62].

### Fig 11.7 — Tire contact area
*[Raymer, Fig. 11.7, p. 348]* — Side-view sketch of tire footprint, width `w` and diameter `d`
labeled, contact patch shaded. No plotted data (schematic supporting Eq. 11.6).

Operating a tire below its rated load/pressure extends life sharply (roughly a 6× landing-count
increase at half the rated load/pressure) but requires a larger tire (more drag/weight/wheel-well
volume). Soft/rough-field operation similarly calls for lower pressure (larger tires); Table 11.3
gives rough sizing guidance by surface.

### Table 11.3 — Recommended Tire Pressures
*[Raymer, Table 11.3, p. 349]*

| Surface | Max Pressure (psi) | Max Pressure (kPa) |
|---|---|---|
| Aircraft carrier | 200+ | 1380+ |
| Major military airfield | 200 | 1380 |
| Major civil airfield | 120 | 828 |
| Tarmac runway, good foundation | 70-90 | 480-620 |
| Tarmac runway, poor foundation | 50-70 | 345-480 |
| Temporary metal runway | 50-70 | 345-480 |
| Dry grass on hard soil | 45-60 | 310-415 |
| Wet grass on soft soil | 30-45 | 210-310 |
| Hard packed sand | 40-60 | 275-415 |
| Soft sand | 25-35 | 170-240 |

Wheel rim diameter is typically about half the tire's outside diameter (see Table 11.2). Brakes must
absorb touchdown kinetic energy (ignoring aerodynamic drag/thrust reversal, and assuming braking
starts at stall speed):

```
KE_braking = (1/2) · (W_landing / g) · V_stall²                       (11.7)
```
*[Raymer, Eq. (11.7), p. 349]* — divide by the number of braked wheels to get energy-per-brake.
Landing weight for this purpose ≈ 80-100% of takeoff weight (covers an early-abort emergency
landing). Western practice brakes only the main wheels; several former Soviet-bloc designs also
brake the nosewheel.

### Fig 11.8 — Wheel diameter for braking
*[Raymer, Fig. 11.8, p. 350]* — Statistical chart: required wheel rim diameter (in./cm) vs kinetic
energy per braked wheel (10^6 ft-lb/s, 10^6 N-m/s), two curve families labeled "General aviation and
small jets" and a heavier-aircraft curve. *(read from plot)*, approximate digitized points for the
general-aviation/small-jet curve:

| KE per wheel (10^6 ft-lb) | Wheel rim diameter (in.) |
|---|---|
| 5 | ~9 |
| 10 | ~12 |
| 20 | ~15 |
| 40 | ~19 |
| 60 | ~22 |
| 80 | ~24 |

If the Fig. 11.8-derived rim diameter exceeds the selected tire's rim diameter, use a larger tire (or
a brake protruding laterally, needing a larger wheel well). Practical tire clearance: never let a
tire sit tangent to the outer mold line; allow ~3-5% of tire width as running clearance all around,
plus 1-2 in. {3-5 cm} for structure to the OML; a tire also grows ~2-3% in diameter and ~4% in width
as it ages, which must be allowed for in wheel-well/retraction geometry.

## §11.3 Shock Absorbers

### §11.3.1 Shock-Absorber Types

A shock absorber must provide both spring (force ∝ displacement) and damping (force ∝ velocity)
function (Fig. 11.9): **rigid axle** (tires alone absorb shock — sailplanes, some homebuilts, WWI
fighters with bungee-cushioned rigid axles); **solid spring** (simple, common on Cessnas, but
deflects with some lateral scrubbing motion that wears tires and provides no damping beyond that
scrubbing); **levered bungee-cord** (Piper Cub-era light aircraft — light but high-drag, also causes
scrubbing); **oleopneumatic shock strut ("oleo")** — the dominant modern type, combining an air/
nitrogen spring with an oil-metered-orifice damper in one cylindrical unit (patented 1915 as a gun
recoil device); **triangulated / trailing-link / leading-link** — "articulated" gear using a lever
principle so the oleo itself can stroke less than the wheel travel required, at a typical weight
penalty but valuable for carrier aircraft needing large wheel travel (A-7 triangulated; F-18 trailing
-link) and for rough-field wheel-aft-travel behavior (OV-10, PZL-104 Wilga trailing-link).

### Fig 11.9 — Gear/shock arrangements
*[Raymer, Fig. 11.9, p. 352]* — Six schematic side-view sketches: rigid axle, solid spring, rubber
bungee, levered bungee, oleo shock-strut, triangulated, hinge/trailing-link (levered). No plotted
data (reference diagram).

### Fig 11.10 — Oleo shock absorber (most simple type)
*[Raymer, Fig. 11.10, p. 353]* — Cutaway cross-section: compressed air/nitrogen chamber, oil,
metering orifice, labeled stroke `s`, static deflection (typically ≈2/3 `s`), fully-compressed/
static/fully-extended wheel positions marked. No further plotted data (schematic supporting the
stroke definitions used in §11.3.2).

An oleo mounted so the cylinder itself is the structural gear leg is called a "cantilevered"
oleopneumatic shock strut — usually the lightest arrangement, but the strut must carry lateral and
braking loads concentrated at its single attachment point, and gear height is set by roughly double
the required stroke. Levered/articulated gear trades this weight advantage for a shorter oleo,
reduced wheel-well height need, and (for the levered arrangement generally) easier oleo maintenance
(replace at the linkage without pulling the whole gear/wheel/brake assembly) — but the oleo cantilever
weight advantage usually still wins absent a specific driving requirement.

### §11.3.2 Stroke Determination

Rule of thumb: required stroke (in.) ≈ vertical touchdown velocity (ft/s). Typical required sink-
speed capability: most aircraft 10 ft/s {3 m/s}; USAF trainers 13 ft/s {4 m/s}; STOL aircraft 15 ft/s
{4.6 m/s} per Ref. [63]; carrier naval aircraft ≥20 ft/s {6 m/s} (hence the preference for triangulated
/levered gear on carrier types, for their longer strokes). For initial estimates the wing may be
assumed to still support the full aircraft weight during shock-absorber deflection (detailed FAR-23
calculations instead assume only 2/3 weight on the wing at touchdown).

Vertical kinetic energy to be absorbed:
```
KE_vertical = (1/2) · (W_landing / g) · V_vertical²                    (11.8)
```
*[Raymer, Eq. (11.8), p. 355]* — `W` = total aircraft weight.

Energy absorbed by deflection, with shock-absorber efficiency `η` (Table 11.4 gives typical values,
0.5-0.9):
```
KE_absorbed = η · L · S                                                (11.9)
```
*[Raymer, Eq. (11.9), p. 355]* — `η` = shock-absorbing efficiency, `L` = average total load during
deflection (not lift), `S` = stroke. Tires deflect only to their rolling radius, so tire stroke
`S_T = d/2 - R_r`.

### Table 11.4 — Shock-Absorber Efficiency
*[Raymer, Table 11.4, p. 356]*

| Type | Efficiency η |
|---|---|
| Steel leaf spring | 0.50 |
| Steel coil spring | 0.62 |
| Air spring | 0.45 |
| Rubber block | 0.60 |
| Rubber bungee | 0.58 |
| Oleopneumatic, fixed orifice | 0.65-0.80 |
| Oleopneumatic, metered orifice | 0.75-0.90 |
| Tire | 0.47 |

Combining Eqs. (11.8)-(11.9), assuming both shock absorber and tire deflect together:
```
(1/2)·(W_landing/g)·V_vertical² = η·L·S_(shock absorber) + η_T·L·S_T (tire)     (11.10)
```
*[Raymer, Eq. (11.10), p. 356]* — note the number of shock absorbers does not appear; `L` is the
average total load summed over all absorbers. Gear load factor `N_gear` (typically ≈3):
```
N_gear = L / W_landing                                                (11.11)
```
*[Raymer, Eq. (11.11), p. 356]* — the average total gear load (all struts) divided by landing weight,
assumed constant during touchdown; it governs how much load passes into the airframe (hence
structural weight and ride comfort). Table 11.5 gives typical permitted values by aircraft class.

### Table 11.5 — Gear Load Factors
*[Raymer, Table 11.5, p. 356]*

| Aircraft Type | N_gear |
|---|---|
| Large bomber | 2.0-3 |
| Commercial | 2.7-3 |
| General aviation | 3 |
| Air Force fighter | 3.0-4 |
| Navy fighter | 5.0-6 |

Substituting Eq. (11.11) into Eq. (11.10) gives the stroke equation — notably independent of aircraft
weight (an airliner and an ultralight need the same stroke for the same sink speed and `N_gear`):
```
S = V_vertical² / (2·g·η·N_gear) − (η_T/η)·S_T                        (11.12)
```
*[Raymer, Eq. (11.12), p. 357]* — add ~1 in. {3 cm} safety margin; practical minimum stroke ~8 in.
{20 cm}, 10-12 in. {25-30 cm} desirable for most aircraft. Nosewheel stroke is set equal to or
slightly larger than main-wheel stroke for ride smoothness while taxiing. If levered/triangulated
gear is used, the oleo/bungee/rubber-block stroke is the total stroke divided by the mechanical
advantage (and its load is correspondingly multiplied by that mechanical advantage).

### §11.3.3 Oleo Sizing

Static position is typically ≈66% of the extended-to-compressed travel for most aircraft types (≈84%
for large transports, ≈60% for general aviation). Total oleo length (stroke + fixed portion) ≈2.5×
the stroke — a short-strut-height requirement may force a levered-gear layout instead. Main-wheel
oleo load = static load from Eq. (11.1) divided by the number of main-wheel oleos (usually two);
nose-wheel oleo load = static + dynamic loads from Eqs. (11.2) and (11.4); both multiplied by
mechanical advantage if levered/triangulated. Typical internal oleo pressure `P ≈ 1800 psi {12,415
kPa}`. External oleo diameter (piston diameter ×1.3 to account for the cylinder wall):

```
D_oleo = 1.3 · sqrt( 4·L_oleo / (π·P) )                                (11.13)
```
*[Raymer, Eq. (11.13), p. 358]* — `L_oleo` = load on the oleo. (Form reconstructed from the stated
"force = pressure × area, external diameter 30% greater than piston diameter" derivation; the OCR of
the printed equation itself is garbled — `[verify p. 358]`, confirm exact bracketed form against the
page image before hard-coding.)

### §11.3.4 Solid-Spring Gear Sizing

Fig. 11.11 shows the deflection geometry: total stroke from Eq. (11.12) is the *vertical* component
of the gear-leg tip deflection; the wheel is mounted vertical at the *static* deflected position for
even tire wear.

### Fig 11.11 — Solid spring gear deflection
*[Raymer, Fig. 11.11, p. 358]* — Side-view sketch: gear leg from fully-extended, through static, to
fully-compressed length; deflection angle `θ`, reaction force `F_s` along the gear leg, its
perpendicular component `F`, and vertical deflection `y`. No further plotted data (schematic
supporting Eqs. 11.14-11.19).

Treating the leg as a constant-section bending beam (average width `w`, thickness `t`), for two gear
legs:
```
F_s = W·N_gear / 2                                                     (11.14)
F = F_s · sin(θ)                                                       (11.15)
S = y · sin(θ)                                                         (11.16)
y = F·l³ / (3·E·I)                                                     (11.17)
S = F_s·(sin²θ)·l³ / (3·E·I)                                           (11.18)
I = w·t³ / 12   (rectangular cross-section)                            (11.19)
```
*[Raymer, Eqs. (11.14)-(11.19), pp. 358-359]* — `I` = beam moment of inertia, `E` = material modulus
of elasticity, `l` = beam length, `θ` = deflection angle. Static deflection uses Eq. (11.18) with the
static wheel load in place of `F_s`. Stress verification uses Chapter 14 methods.

## §11.4 Castoring-Wheel Geometry

Free-castoring nose/tail wheels can develop "wheel shimmy" (rapid lateral oscillation that can tear
the gear off). Prevented by rake angle and trail selection (Fig. 11.12), sometimes aided by a
frictional shimmy damper. Free-swivel wheels: small negative rake (4-6 deg) and trail = 0.2-1.2×
tire radius (also typical for tailwheels); free-swivel steering means the pilot must steer only with
differential braking (increased brake wear, dangerous on single-brake failure). Steerable
nosewheels: minimize trail via a *positive* rake angle (large aircraft: ~7 deg positive rake, trail
≥16% of tire radius; smaller aircraft: rake up to 15 deg, trail ~20%) — positive rake makes the gear
statically unstable ("flop over" tendency), which the steering linkage must resist.

### Fig 11.12 — Castoring wheel geometry
*[Raymer, Fig. 11.12, p. 360]* — Two side-view sketches: free-swivel (negative rake, trail shown) and
steerable (positive rake, trail shown), rake angle labeled on both. No plotted data (schematic).

## §11.5 Gear Retraction Geometry

Options for the retracted main-gear "home" (Fig. 11.13): in the wing, in the fuselage, in the
wing-fuselage junction (all lowest drag, but structurally disruptive — wing stowage shrinks the wing
box, fuselage/junction stowage can interfere with longerons; civil jet transports nearly always use
the wing-fuselage junction; low-wing fighters use wing or junction, mid/high-wing fighters use the
fuselage); wing-podded (A-10 in the West; more common in former Soviet-bloc jets/transports/bombers,
placed at the trailing edge for some area-ruling benefit); fuselage-podded (common on high-wing
military transports, avoiding a cargo-bay floor bump, at a drag cost); in the nacelle (typical for
propeller aircraft; for jets it widens the nacelle alongside the engine, adding drag).

### Fig 11.13 — "A home for the gear"
*[Raymer, Fig. 11.13, p. 361]* — Six schematic cross-sections: in the wing, in the fuselage, wing/
fuselage junction, wing-podded, fuselage-podded, in the nacelle. No plotted data (reference diagram).

Most retraction mechanisms use a four-bar linkage (three rigid members plus the airframe as the
fourth "bar"), connected by pivots — simple, light, load path through rigid members/simple pivots.
Fig. 11.14 shows four variants: (a) vertical gear member on parallel arms pivoting up/inward (1930s
style, seen modified on MiG-23); (b) typical nosewheel arrangement with a breaking "drag brace"
(diagonal member carrying air/braking loads) — forward-of-wheel drag braces with rearward retraction
are preferred because air loads then blow the gear down on hydraulic failure; (c) the vertical gear
member itself breaks for retraction (shorter retracted length, usually heavier — DC-3, WWII bombers);
(d) sliding-pivot retraction, often a wormscrew-driven mechanism (heavier — full wormscrew length
must carry gear loads — but simple/compact). For inward/outward-retracting main gear the same
concepts apply as front views, with "drag brace" renamed "sway brace" (lateral support role).

### Fig 11.14 — Landing-gear retraction
*[Raymer, Fig. 11.14, p. 362]* — Four labeled front/side-view schematics (a)-(d) per the mechanism
descriptions above. No plotted data (reference diagram).

The gear pivot point ("trunnion") lies on the perpendicular bisector between the wheel's up and down
positions (Fig. 11.15); it is roughly horizontal to the ground for most aircraft.

### Fig 11.15 — Pivot point determination
*[Raymer, Fig. 11.15, p. 363]* — Side-view construction: down position, up position, strut-extended
perpendicular bisector, pivot point marked at their intersection. No plotted data (geometric
construction diagram).

A **double-canted** trunnion (angled in both side and top view) rotates the retracted wheel to a
flatter, flusher stowed attitude (Swedish Gripen). A **"strut compressor"** retracts the gear already
compressed (used only when fully-extended stowage space is unavailable). A **"rotator link"**
rotates the oleo strut ~90 deg for a flat stowed wheel without the sideways motion of double-canting,
at some added complexity (F4U Corsair, F-14, F-35). A **"planing link"** changes the gear-leg-to
-wheel-axis angle so wheels can tuck into the fuselage side when retracting inward from the wing
(MiG-23). All add cost, weight, and failure points, and are avoided unless necessary.

## §11.6 Seaplanes

Historically important for early long-range/high-speed flight (water takeoff runs permitted high
wing loading); today largely restricted to sport/bush/search-and-rescue aircraft, with recurring
interest in "sea-sitter" bombers and ground-effect cargo seaplanes. Hulls/floats use a planing-hull
concept: a flat-ish bottom to skim (plane) at speed, with a "step" (vertical discontinuity, straight
or elliptical in planview to cut drag) breaking suction on the afterbody (Fig. 11.16).

### Fig 11.16 — Seaplane geometry
*[Raymer, Fig. 11.16, p. 365]* — Side-view float/hull geometry: dead-rise height/angle, chine, step
(straight for ≈1.5× beam forward of it), static waterline, tip float waterline, sternpost angle 7-9
deg, spray-strip angle 1-4 deg. No further plotted data beyond the values called out in text/Eq. (11.20).

Most hulls use a V-bottom (reduces water-impact loads) with deadrise angle increasing with landing
speed:
```
θ_deadrise ≈ V/2 − 10 deg                                              (11.20)
```
*[Raymer, Eq. (11.20), p. 365]* — `V` = stall speed, mph. Deadrise increases toward the nose (to
~30-40 deg) to better cut through waves. Spray strips (to reduce spray) sit ~30 deg below the
horizon. Length-to-beam ratio ranges ~6 (small seaplane) to ~15 (large). Step height ≈5% of beam,
located ~10-20 deg behind the c.g.; hull bottom must stay uncurved for ≈1.5× beam forward of the step
(anti-porpoising); the sternpost aft of the step angles upward ~8 deg. True flying boats add
wing-mounted stabilizing pontoons, positioned to touch the water at ~1 deg of sideways tip.

Static waterline is found by the fuselage-volume-plot method applied only to submerged cross-section:
assume a waterline, integrate submerged cross-sectional area to get displaced volume, multiply by
water density (62.4 lb/ft³ {1000 kg/m³}) to get supportable weight, and check that the area centroid
(center of buoyancy) coincides with the c.g. — iterate the assumed waterline if not.

Seaplanes need extra forward buoyancy because the thrust line sits well above the (vertically
offset) water-resistance drag line, producing nose-down pitching moment at the start of the takeoff
run (a problem reportedly seen on Burt Rutan's SkiGull in early water taxi tests) — hence seaplanes
typically float slightly nose-up at rest. Water-resistance drag is hard to predict analytically (best
estimated against published hull-shape test data, e.g. early NACA reports, or facilities such as the
Naval Ship Research and Development Center); very roughly, peak "hump speed" water resistance can
reach ≥20% of aircraft weight, and a rough takeoff-distance estimate can use an equivalent rolling
-friction coefficient µ ≈ 0.10-0.15 in the Chapter 17 takeoff equations.

## §11.7 Subsystems

Subsystems (hydraulic, electrical, pneumatic/ECS, auxiliary/emergency power, avionics) rarely drive
the earliest design layout but must be accommodated as the design matures. Refs. [65] and [18] are
recommended overviews.

### §11.7.1 Hydraulics

A simplified system (Fig. 11.17): fluid pumped to pressure, stored in an accumulator; opening a valve
admits fluid to an actuator piston, moving a control surface (a second valve admits fluid to the
piston's other side for reverse motion); fluid returns to the pump via a return line. The valve must
sit close to the actuator for fast response (so it is mounted at the actuator, not the cockpit).
Pilot inputs reach the valve mechanically (cables), electronically ("fly-by-wire"), or via fiber
optics ("fly-by-light"). Hydraulics actuate flight controls, flaps, gear, spoilers, speed brakes, and
weapon bays; flight-control hydraulics must also synthesize proper control "feel" (stiffer at higher
speed/g) via springs, bobweights, dashpots, air bellows. Conceptual-design impact is mostly reserving
space for engine-driven hydraulic pumps (copy from a similar aircraft absent better data).

### Fig 11.17 — Simplified hydraulic system
*[Raymer, Fig. 11.17, p. 367]* — Schematic: accumulator, control stick, control cables, valve,
actuator/control-surface piston, return line. No plotted data (schematic).

The **electrohydrostatic actuator (EHA)** (F-35, A-380) distributes a miniature hydraulic system
(small electric-motor-driven pump + accumulator) to each actuator location instead of one central
system with pressure lines throughout the aircraft (~80 kW electrical power needed for an F-16-size
aircraft); likely slightly heavier than a next-gen conventional system but the whole unit is
swappable with just electrical/signal disconnects, cutting maintenance time/cost.

### §11.7.2 Electrical System

Provides power to avionics, hydraulics, ECS, lighting, etc.; consists of batteries, generators
(usually AC, engine-mounted), transformer-rectifiers (AC→DC), controls, breakers, cables. Example
systems: Eurofighter Typhoon — two engine-driven 30-kVA generators, 115/200-V 400-Hz 3-phase AC, TR
units to 28-V DC, battery-started APU which starts the engines. Boeing 767 — two engine-driven
90-kVA generators (115/200 V, 400 Hz, 3-phase AC) plus a third 90-kVA APU-driven generator for
ground/emergency power.

**Electrical actuators** (direct electric-motor/gearbox control-surface drive, long used in R/C
models) are emerging as a hydraulics-free alternative, sharing the EHA's swap-for-maintenance
advantage at a probable weight penalty; **electric brakes** (flight-tested on an F-16) use
ballscrew-driven electric motors, roughly 2× the response speed of hydraulic brakes (potential
antiskid benefit) at comparable weight, and eliminate flex/rotating brake hydraulic lines.

Aircraft wiring itself is a major, under-appreciated weight/complexity item: a typical large airliner
carries ~200 nmi {370 km} of wiring at ~4,000 lb {~1800 kg} (excluding cabin/entertainment wiring,
which can double these figures). Weight-reduction paths include shortened runs (distributed power
sources), aluminum vs copper conductors, lighter insulation, and (long-term) superconductivity;
signal wiring is a candidate for wireless "Wireless Avionics Intra-Communications (WAIC)" systems
analogous to Internet-of-Things networking, though safety-critical (primary flight control)
application awaits sufficient reliability.

### §11.7.3 Pneumatic/ECS System

Provides compressed air (usually bled from engine compressors) for pressurization, environmental
control, anti-icing, and sometimes engine starting. Bleed air is cooled via a heat exchanger using
ram air (drawn from a flush inlet in the inlet duct, or a separate fuselage/diverter-front inlet) for
cockpit pressurization and avionics cooling (this cooled-air loop is the "ECS"); anti-icing instead
uses uncooled bleed air ducted to the wing leading edge, inlet cowls, windshield. Compressed air can
also cross-start other engines after one is battery-started, or come from a ground cart.

### §11.7.4 Auxiliary/Emergency Power

Large/high-speed aircraft depend entirely on hydraulics for flight control, so loss of hydraulic
pressure (e.g. engine flame-out driving the pumps) requires backup. Three forms: **ram-air turbine
(RAT)** — a windmill extended into (or an inlet duct opened to) the slipstream; **monopropellant EPU**
— drives a turbine from a toxic/caustic monopropellant (e.g. hydrazine); no inlet duct needed, works
at any altitude/velocity/attitude, but the fuel must be routed so leaks cannot puddle against
structure; **jet-fuel EPU** — a small jet engine driving a turbine (can double as a main-engine
starter), needs its own inlet duct but avoids a dangerous separate fuel. Most commercial and a
growing share of military aircraft instead carry a continuously-operable jet-fuel **auxiliary power
unit (APU)** for ground power (AC, lighting, engine start) as well as in-flight emergency/continuous
hydraulic-electrical power. APU installation (Fig. 11.18) needs its own inlet/exhaust ducts and a
firewalled bay; inlet/exhaust should point upward (noise), the inlet should sit in a high-pressure
region and exhaust in a low-pressure region for in-flight operation, and neither inlet should ingest
main-engine or APU exhaust. Typical placement: transports — tail (Fig. 11.18, away from the cabin,
small firewall, work-stand accessible); military transports with fuselage gear pods — in the pod
(ground-level access, larger firewall); fighters — in the fuselage near hydraulic pumps/generators
(full-enclosure firewall). Ref. [66] covers APU installation in detail.

### Fig 11.18 — APU installation
*[Raymer, Fig. 11.18, p. 371]* — Side-view sketch, APU in the tail with exhaust routed aft/upward
through the fuselage. No plotted data (schematic).

### §11.7.5 Accessory Drives

Many high-performance aircraft use an **airframe-mounted accessory drive (AMAD)** — a gearbox
collecting all engine-driven accessories (hydraulic pumps, generators, starters, etc.), itself
connected to the engine by a single disconnectable driveshaft (Fig. 11.19), replacing the older
practice of mounting each accessory (or an oversized accessory fairing) directly on the engine, which
required separately disconnecting every accessory for engine removal.

### Fig 11.19 — Airframe-mounted accessory drive
*[Raymer, Fig. 11.19, p. 372]* — Cutaway/schematic of an AMAD gearbox with accessory mounting pads
and driveshaft connection to the engine. No plotted data (schematic).

### §11.7.6 Avionics

Avionics ("aviation electronics") — radios, instruments, nav aids, flight computers, radar, IR
sensors, etc. — has grown from a minor "bolt-on" afterthought to (for some military types) nearly a
third of total aircraft cost, and is now integral to the design process. Raymer groups avionics into
three functional classes: **com/nav** (radios, navigation aids, weather radar, transponders, GPS,
autopilots, cockpit displays); **mission equipment** (air-to-air/ground radar, ECM, IR sensors/
countermeasures, IFF, weapon aiming, terrain-following, stealth systems — historically traced to WWII
night-fighter radar and ASW aircraft like the P-2V Neptune); **vehicle management** (flight-critical
systems, e.g. fly-by-wire stabilization of an aerodynamically unstable airframe — the X-31 crash from
an iced air-data sensor is cited as a vehicle-management-avionics failure). Com/nav and mission
equipment are (in principle) "add-ons" the aircraft could fly without; vehicle management avionics
are flight-critical. Modern fighters/bombers/transports are effectively flown by the flight-control
computer, which arbitrates pilot "suggestions" against stability/structural limits; extreme extensions
include altitude/turn-rate or waypoint-only piloting (the unmanned Global Hawk has no onboard stick
at all) and active structural-mode control (L-1011 gust-load-alleviation ailerons; B-1B structural
mode-control vanes damping fuselage bending at low altitude/high Mach). This drives an ever-growing
onboard-software burden, itself a major cost and reliability risk ("when these computers crash, so do
you").

For simple GA aircraft, avionics selection is mostly catalog shopping against FAR-mandated equipment;
for advanced aircraft it is a system-integration problem comparable in scope to the airframe design
itself, often specified by dedicated avionics engineers working from statistical/analytical weight
estimates before hardware exists (may take 6-12 months to firm up). Early layout only needs
sufficient avionics-bay *volume*, estimated from weight via an assumed avionics density of ~30-45
lb/ft³ {480-720 kg/m³}. A persistent trend/paradox: avionics technology keeps shrinking per function,
yet total avionics weight per aircraft *class* has stayed roughly flat, because designers keep adding
capability to fill the historically-expected weight allowance — hence the recommended practice of
sizing avionics weight from historical weight *fractions* rather than assuming technology-driven
weight reduction (Table 11.6).

### Table 11.6 — Avionics Weights
*[Raymer, Table 11.6, p. 375]* — `W_avionics / W_empty`, typical values:

| Aircraft Type | W_avionics / W_empty |
|---|---|
| General aviation, single engine | 0.01-0.03 |
| Light twin | 0.02-0.04 |
| Turboprop transport | 0.02-0.04 |
| Business jet | 0.04-0.05 |
| Jet transport | 0.01-0.02 |
| Fighters | 0.03-0.08 |
| Bombers | 0.06-0.08 |
| Jet trainers | 0.03-0.04 |

Avionics bay placement must balance vibration/shock/heat sensitivity, short wiring runs to the crew
station, adequate power/cooling, and maintenance access — most aircraft place bays just ahead of or
below the cockpit (or, on some bombers/transports, inside it); many fighters run radome → radar →
first bulkhead → avionics bay → cockpit in a straight line. GA aircraft mount most avionics directly
in the instrument panel, with conceptual-design volume allowance made forward of the panel for the
largest anticipated box plus wiring/cable/access space. Radar sizing (drives nose shape) can, absent
a detailed radar-range-equation estimate from avionics engineers, use rough historical guidance:
bomber ≈40 in. {100 cm} dish, large fighter ≈35 in. {90 cm}, small fighter ≈22 in. {56 cm}; transport
weather radars are comparatively small. Other military apertures (ECM, IRST, IR jammers) must be
positioned for the required field of view, checkable with a Chapter 9 vision plot.

## What We've Learned

*[Raymer, p. 377]* Landing gear looks like straightforward mechanical engineering but can wreck a
design layout: the down position is almost fully constrained by geometry/stability rules, and a "home
for the gear" in the retracted position is often hard to find. Plan the gear early.

---

*Chapter 11 complete (Introduction, §§11.1-11.7 [Arrangements, Tire Sizing, Shock Absorbers,
Castoring-Wheel Geometry, Retraction Geometry, Seaplanes, Subsystems], Tables 11.1-11.6, Figs
11.1-11.19, Eqs. 11.1-11.20, "What We've Learned" summary). PDF index span used: 366-407 (printed
pp. 337-378); the "Intermission" section beginning at PDF index 408 (printed p. 379) belongs to the
book's cross-chapter design-process interlude, not Chapter 11, and is excluded. Two `[verify]` items
remain: Table 11.1's width coefficients for Transport/bomber and Jet fighter/trainer, and Eq. (11.13)'s
exact bracketed form — both flagged inline above pending a cleaner scan pass. Next: Chapter 12 —
Aerodynamics.*
