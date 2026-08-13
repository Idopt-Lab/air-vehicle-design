# Chapter 9 — Crew Station, Passengers, and Payload

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 9 "Crew Station, Passengers, and Payload," printed pp. 261–274.

Reference-dimension and rule-of-thumb chapter for cockpit, cabin, cargo, and weapons-carriage
layout. Only one numbered equation (overnose vision angle); the rest is tabulated dimensional
guidance and descriptive figures.

---

## §9.1 Introduction

At the initial ("Dash-One") layout stage, crew-station/passenger/payload design doesn't need full
detail (control/instrument arrangement, exact passenger amenity layout) — but basic geometry (head
room, leg room, exits, galleys, toilets for a passenger aircraft; bomb/gun fit for a fighter; pilot
vision, room, and instrument-panel space for any manned type) must be right so later detailed design
doesn't force an overall-geometry revision.

## §9.2 Crew Station

Vision requirements are the primary conceptual-design driver — they can set both cockpit location and
nearby fuselage shape (e.g. the nose must slope away from the pilot's eye enough to see the runway on
final approach, even at a drag cost; over-side vision needs can preclude placing the cockpit directly
over the wing).

**Pilot-size accommodation range**: most military aircraft target the 5th–95th percentile male pilot
(height 65.2–73.1 in {1.66–1.86 m}); smaller/larger candidates are excluded from training rather than
accommodated. Growing numbers of women in military flying now also require accommodating
approximately the 20th-percentile female (≈98 lb, 59 in tall {44 kg, 1.5 m}) — mainly affects detailed
control/display layout, little impact on conceptual cockpit geometry. GA cockpits are sized to
whatever range marketing wants, typically comfortable only up to ≈72 in {1.83 m}; airliner cockpits
follow military-like sizing.

### Fig 9.1 — Average 95th-percentile pilot figure
*[Raymer, Fig. 9.1, p. 263]* — Standing figure (dimensions from Ref. [39], includes boots/helmet
allowance) with called-out shoulder width **26 in {66 cm}** and a **30 in {76 cm}** clearance
allowance. Used historically as a 1:20-scale cardboard cutout manikin, pinned at the joints and
traced onto the layout (or as a built-in CAD manikin, Ref. [21]); a cockpit sized for the 95th-
percentile figure usually has enough adjustment range (seat/controls) to also fit the 5th percentile.

### Fig 9.2 — Typical fighter cockpit dimensions
*[Raymer, Fig. 9.2, p. 264]* — Side-view diagram with called-out dimensions: head clearance radius
10 in {25 cm}; overside-vision-related depth 15 in {38 cm}; 40° over-the-side vision angle; 3 in
{8 cm} allowance "for longeron"; 17 in {43 cm} and 73 in {33 cm — likely an OCR-garbled value,
`[verify p. 264]`}; 50 in {1.3 m}; 32 in {81 cm}; 8 in {20 cm}. Two key reference points: the **seat
reference point** (where seat pan meets seat back — references floor height/leg room) and the
**pilot's eye point** (references overnose angle, transparency grazing angle, and the 10-in head
clearance radius). Typical seatback angle in this figure is 13°; up to 30° is flown (F-16) and up to
70° has been studied for advanced fighters — reclining trades outside vision for higher g-tolerance
and a lower (lower-drag) cockpit. For a reclined-seat layout, rotate both the seat and the pilot's eye
point about the seat reference point, then re-check overnose vision from the new eye position.

**Overnose vision** angle requirements (military spec, typical): 17° for transports/bombers; 11–15°
for fighter/attack aircraft; trainers with tandem seating need 5° vision for the rear-seat instructor
over the front seat. GA aircraft (level landing attitude) need only ≈5–10° — some older GA designs
have so little overnose vision that the pilot loses the runway from flare to touchdown. Civil
transports often have much more (L-1011: 21°); civil overnose angle must be calculated per-aircraft
from the pilot's need to see/react to approach lights at decision height (100 ft {30.5 m}) under
minimum-weather conditions (1200-ft {366-m} runway visual range) — higher approach speed demands a
larger angle. A full graphical method (Ref. [40]) needs the completed layout (exact eye position and
main-gear location); for initial layout, an approximation:

**Eq (9.1)** *[Raymer, Eq. (9.1), p. 265]*:
`α_overnose ≈ α_approach + 0.07·V_approach` (`V` in kt) `= α_approach + 0.04·V_approach` (`V` in km/hr)

**Over-the-side vision**: 40° (from the pilot's eye, on centerline) is typical for fighters/attack
aircraft (as drawn in Fig. 9.2). For bombers/transports: 35° without head movement, up to 70° with the
head pressed against the cockpit glass — also reasonable for GA aircraft, though many GA designs have
a low wing blocking the downward view. **Upward vision**: transports/bombers want unobstructed
forward-upward vision to ≥20° above the horizon; fighters want completely unobstructed vision above
and all the way to the tail (canopy structure members ≤2 in {5 cm} wide to avoid blocking view).

**Transparency grazing angle** (smallest angle between the pilot's line of sight and the windscreen,
Fig. 9.2): too shallow an angle degrades apparent transparency (in bad lighting the pilot may see only
an instrument-panel reflection instead of the outside world) — minimum recommended grazing angle
**30°**.

**Transport cockpit length** (2–4 crew, plus radio/instrument/stowage provisions, per Ref. [40]):
≈150 in {3.8 m} (4 crew), ≈130 in {3.3 m} (3 crew), ≈100 in {2.5 m} (2 crew).

**Escape systems**: Fig. 9.2's dimensions accommodate most military ejection seats. An ejection seat
is required above `q ≈ 230 psf {11 kN/m²}` (≈260 kt {481 km/h} at sea level); near Mach 1 at sea level
(`q > 1200 psf {58 kN/m²}` — note this is Raymer's own figure; the parallel Nicolai extract in this
repo's reference set quotes `q ≈ 1480 psf` for the same "even an ejection seat is unsafe" threshold —
treat both as order-of-magnitude citations from their respective sources, not identical values,
`[verify p. 265]` if an exact cross-check is needed) even an ejection seat is unsafe, requiring an
encapsulated seat or separable crew capsule (heavy/complex — e.g. FB-111, prototype B-1A; the B-1A's
four-seat capsule with instruments/some avionics weighed ≈9,000 lb {4,082 kg}).

## §9.3 Passenger Compartment

Commercial cabin arrangement is marketing-driven more than regulation-driven.

### Fig 9.3 — Commercial passenger allowance definitions
*[Raymer, Fig. 9.3, p. 266]* — Diagram defining head room (floor to roof over the seats — sidewall
curvature may cut off some of the outer seat's head room; outer-passenger eye position still needs a
10-in {25-cm} clearance radius in that case), aisle width/height, seat width, and seat **pitch**
(back-of-seat to back-of-next-seat, i.e. fore-aft seat length + leg room). No plotted numeric data
beyond the definitions (numbers given in Table 9.1).

### Table 9.1 — Typical Passenger Compartment Data
*[Raymer, Table 9.1, p. 267]*

| Parameter | First Class | Economy | High-Density/Small Aircraft |
|---|---|---|---|
| Seat pitch, in {cm} | 38–40 {97–102} | 34–36 {86–91} | 30–32 {76–81} |
| Seat width, in {cm} | 20–28 {51–71} | 17–22 {43–56} | 16–18 {41–46} |
| Head room, in {cm} | >65 {165} | >65 {165} | ≈12 {30} — likely OCR-garbled, expect `>60 {152}`-scale `[verify p. 267]` |
| Aisle width, in {cm} | 20–28 {51–71} | 18–20 {46–51} | >60 {152} — column alignment uncertain, `[verify p. 267]` |
| Aisle height, in {cm} | >76 {193} | >76 {193} | ≤50 |
| Passengers per cabin staff (intl/domestic) | 16–20 | 31–36 | 40–60 |
| Passengers per lavatory (40×40 in {1×1 m}) | 10–20 | 40–60 | 0–1 {0–0.03} |
| Galley volume/passenger, ft³ {m³} | 5–8 {0.14–0.23} | 1–2 {0.03–0.06} | (n/a — see previous row's value, likely mis-split by OCR) |

(The High-Density/Small-Aircraft column's row-to-row alignment came through visibly scrambled in this
OCR pass — the seat pitch/width figures are confident matches to the printed table, but the head
room/aisle/staffing/lavatory/galley values in that column should be treated as `[verify p. 267]`
pending a direct page-image check.) Real-world seating has drifted below even Table 9.1's economy
numbers — actual measured airline economy seats run ≈31 in pitch × 17 in width {79×43 cm}; Raymer
recommends designing to the table's larger figures anyway so airlines "can cram in more rows after
they've bought the plane."

Layout rules: no more than 3 seats accessed from one aisle (>6-abreast needs 2 aisles); doors/entry
aisles (with closet space) every ≈10–20 rows, each occupying 40–60 in {1–1.5 m} of cabin length.
Passenger weight assumption: 180 lb {82 kg} average (dressed + carry-on) plus 40–60 lb {18–27 kg}
checked luggage (note: a rising carry-on/falling checked-bag trend has been overflowing overhead-bin
capacity on real aircraft). Fuselage sizing: cabin cross-section + cargo-bay dimensions set internal
diameter; external diameter adds structural thickness — ≈1 in {2.5 cm} for a small business/utility
transport up to ≈4 in {10 cm} for a jumbo jet.

## §9.4 Cargo Provisions

Civil transports use standard preloaded containers where possible (reusing an existing standard
avoids buying a new container inventory).

### Fig 9.4 — Cargo containers (727 vs. LD-3)
*[Raymer, Fig. 9.4, p. 268]* — Two container diagrams with dimensions: 727-200 "C" container, 78 ft³
{2.2 m³}; LD-3 ("Lower Deck") container, 158 ft³ {4.5 m³}, used by all widebody transports. Capacity
examples: B-747 carries 30 LD-3s + 1,000 ft³ {28.3 m³} bulk; L-1011 carries 16 LD-3s + 700 ft³
{19.8 m³} bulk; DC-10 and A-300 each carry 14 LD-3s + 805 ft³ {22.8 m³} and 565 ft³ {16 m³} bulk,
respectively. Belly cargo doors sized for these containers run ≈70 in {1.8 m} per side; low-wing
transports typically split belly cargo into forward-of-wing-box and aft-of-wing-box compartments.

Cargo volume per passenger (civil transport, Ref. [41]): ≈8.6 ft³ {0.24 m³} (small short-haul, e.g.
DC-9) up to ≈15.6 ft³ {0.44 m³} (transcontinental, e.g. B-747); DC-10/L-1011/Airbus/B-767 all cluster
around ≈11 ft³ {0.31 m³}. Includes both paid cargo and passenger luggage. Smaller, non-containerized
(hand-loaded) transports: ≈6–8 ft³ {0.17–0.23 m³} per passenger is reasonable.

Military transports use flat pallets (most common: 88×108 in {2.2×2.7 m}), tied down and tarp-
covered. Cargo-floor height needs to be ≈4–5 ft {1.4 m} off the ground for direct truck-bed
loading/unloading at austere bases (major airlift bases can instead use pallet loaders reaching a
13-ft {4 m} floor). Cross-section matters most for the largest transports: C-5/C-17 are sized for
"outsized" cargo (M-60 tanks, helicopters, large trucks) — C-5 cargo bay 19×13.5×121 ft
{5.8×4.1×36.9 m}, payload capacity 263,000 lb {119,295 kg}. The C-130 (front-line troop/supply
delivery, no outsized-cargo capability) has a 10.3×9.2×41.5 ft {3.1×2.8×12.7 m} bay.

## §9.5 Weapons Carriage

Weapons are a large fraction of total aircraft weight and must sit near the c.g. to avoid a pitch
change on release. Missiles (powered, today almost always guided) differ from bombs (often unguided/
"dumb," released via bombsight/computer timing for freefall to target; "smart bombs" home on a laser
spot or GPS coordinate).

**Launch methods**: rail-launch (smaller missiles, e.g. AIM-9/AIM-120 — mounting lugs slide onto a
wingtip or pylon rail, missile motor powers it clear); ejector-launch (larger missiles — quick-release
hooks + explosive-charge-driven pistons shove the missile clear before its motor lights; newer
designs use pneumatic ejectors, e.g. F-35, for lower maintenance/logistics burden vs. explosive
charges). Bombs may be ejected the same way or simply released to fall free.

### Fig 9.5 — Missile carriage/launch (rail and ejector methods)
*[Raymer, Fig. 9.5, p. 270]* — Diagram of a wingtip/pylon rail launcher and an explosive-charge
ejector-release mechanism. No plotted data.

### Fig 9.6 — Weapons carriage options
*[Raymer, Fig. 9.6, p. 270]* — Diagram: external (pylon), semi-submerged, and conformal carriage
cross-sections. No plotted data.

Four carriage options, trade-offs:
- **External** (pylon/hardpoint) — lightest, simplest, most flexible for varying loadouts; removable
  for max dogfight performance when "clean." Also typically carries external fuel (150/600-gal sizes
  {568/2,271 L}, dropped entering a dogfight but retained on long ferry flights). Highest drag —
  external bombs near-sonic can out-drag the rest of the aircraft combined; supersonic flight with
  pylon stores is essentially impossible (buffeting/drag), though small wingtip-mounted missiles are
  a low-drag exception.
- **Semi-submerged** (partial recess, e.g. F-4 AAM stations) — big drag reduction vs. external, but
  less loadout flexibility and a structural weight penalty from the recess.
- **Conformal** (flush-mounted, no structural intrusion) — slightly higher drag than semi-submerged
  but no structural penalty.
- **Internal** (weapons bay) — lowest drag; standard on bombers for 50+ years, rare on fighters
  (F-106, FB-111, F-22) due to weight/door penalties and the traditional priority on dogfight
  performance — but it's the only option that fully removes weapons' RCS contribution, so may become
  more common on fighters too.

Practical carriage-layout considerations: loading-crew workspace (missiles must be physically
attached/slid on, locked, wired to guidance, fuze safety-wire pulled, and — for ejector types — the
explosive charge inserted, often at night/bad weather/on a moving carrier deck — tight weapon-to-
airframe clearance for drag reasons can make this physically impossible, so adequate crew room must
be preserved); ground/attitude clearance (≥3 in {8 cm} to the ground in the worst-case attitude — one
flat tire/strut, max tail-down attitude often ≥15°, 5° roll; double the minimum for rough-runway
operation); inter-weapon clearance (≈3 in {8 cm}); prop-disk clearance (≥1 ft {30 cm}).

### Fig 9.7 — Weapon release clearance
*[Raymer, Fig. 9.7, p. 271]* — Diagram: rail-launched missiles need ≥10° cone clearance between the
aircraft and the launch direction (plus consideration of motor exhaust blast on structure);
ejector-launched or free-fall weapons need a ≥10°-off-vertical fall-line clearance to any part of the
aircraft or other carried weapons.

### Fig 9.8 — Rotary weapons bay
*[Raymer, Fig. 9.8, p. 272]* — Diagram of a rotary internal launcher, allowing all stores to launch
through one smaller door. Benefits: a smaller single door reduces the supersonic buffeting/airload
tendency to push a weapon back into the bay during release; simplifies multi-weapon bay installation;
can be preloaded externally and installed as a complete unit.

## §9.6 Gun Installation

The gun remains the fighter's baseline air-to-air weapon (some 1950s designs, e.g. early F-4/F-104,
omitted it in favor of missiles — history showed missile-only reliance was a mistake, and all new
fighters carry guns again).

### Fig 9.9 — M61 Vulcan gun installation
*[Raymer, Fig. 9.9, p. 273]* — Diagram, top and side views, overall length **74 in**, ammunition drum
located near the gun's aft end, feed chutes to the gun, ground-accessible loading-chute door. Used on
F-15/F-16/F-18/others.

Recoil force: M61A1-class ≈2 tons {18 kN}; a large anti-tank gun (GAU-8, A-10) ≈5× that. To avoid
yaw upset on firing, guns should sit as close to the aircraft centerline as possible (the A-10 offsets
its nose gear to one side specifically to let the GAU-8 sit exactly on centerline — not normally
needed for smaller air-to-air guns). Muzzle placement must avoid obscuring pilot vision with
flash/smoke, and should sit away from the cockpit (noise); gun smoke can also stall a jet engine if
ingested by an inlet — a consideration for gun placement. A smoke-collection-chamber gun mount can
avoid both the visibility and inlet-ingestion problems, at a weight/volume cost.

---

*Chapter 9 complete (Eq. 9.1, Table 9.1, Figs 9.1–9.9). OCR garbling flagged: two dimension values on
Fig. 9.2 (`[verify p. 264]`) and the High-Density/Small-Aircraft column of Table 9.1
(`[verify p. 267]`) — both are minor scanned-table alignment issues, not equation-coefficient risks.
Next: Chapter 10 — Propulsion and Fuel System Integration.*
