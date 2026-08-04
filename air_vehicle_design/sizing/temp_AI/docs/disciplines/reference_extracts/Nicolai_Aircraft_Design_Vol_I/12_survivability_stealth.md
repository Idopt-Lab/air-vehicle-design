# Chapter 12 — Designing for Survivability (Stealth)

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 12 "Designing for Survivability (Stealth)," printed pp. 295–324.

Text-layer inventory (to confirm completeness): Figs 12.1–12.22, Eqs (12.1)–(12.9). No numbered
tables in this chapter.

---

## §12.1 Putting Things in Perspective
*[Nicolai & Carichner, p. 294]*

All aircraft should be designed with survivability in mind. Commercial/private aircraft can be at
risk to terrorists armed with inexpensive, easy-to-use surface-to-air missiles (SAMs) — man-portable
missiles with IR sensors, called **MANPADS**. Military aircraft often encounter enemy MANPAD units
and more sophisticated integrated air defenses (IADs) with large, expensive SAMs and air-to-air
interceptors.

When designing for survivability, consider a hierarchy of actions — hardening the aircraft or
reducing its signature is **not** the first action to consider. Hierarchy, in order:

- **Mission planning.** Plan the mission to avoid the threat — select time of day/conditions to
  minimize threat effectiveness.
- **Plan the mission profile.** Select speed, altitude, terrain following/terrain avoidance (TF/TA)
  conditions, etc.
- **Use electronic countermeasures (ECM).** Integrate onboard/off-board ECMs: flares, chaff, towed
  decoys, RF/IR missile warning systems, countermeasure electronics (spoofers, jammers, etc.).
- **Defeat the end game.** Using onboard RF/IR missile warning systems, a properly timed maneuver
  can cause the missile to miss.
- **Design-in survivability features.** These involve weight, vehicle shape, and cost — impose a
  lifetime performance penalty on the aircraft and should be considered a **last resort**.

> **Sidebar — F-117 Shoot Down:** During the 1999 Kosovo air campaign, Yugoslav air defenses were
> able to locate, track, and shoot down an F-117 by intercepting its electronic emissions. The
> technique was crude and involved a lot of luck, but it worked — the only F-117 ever shot down.
> Russia bought the F-117 remains from Yugoslavia and used component-testing data to design improved
> SAMs. Given the faceted design and 1970s coating technology, it's an open question how much useful
> information was actually obtained [1].

Survivability has two parts: susceptibility and vulnerability. **Susceptibility** is the probability
the aircraft will be detected, tracked, and fired upon:

*(unnumbered equation)* *[Nicolai & Carichner, p. 294]*:
```
P_KS = P_D · P_T · P_FIRE
```

**Vulnerability** is the probability that, once a missile/bullet is fired, it will fuse or hit the
aircraft, and if it hits, the probability it will kill the aircraft:

*(unnumbered equation)* *[Nicolai & Carichner, p. 295]*:
```
P_KV = P_F/H · P_H/K
```
Then probability of a kill is `P_K = P_KS · P_KV`, and probability of survival is `P_S = 1 - P_K`.

Reducing susceptibility and reducing vulnerability are two different strategies for high
survivability, shown in Fig. 12.1 for the A-10A and F-117A.

> **Sidebar — A-10A:** Nicknamed the Warthog, developed in the early 1970s as a close air support
> aircraft for low-intensity conflicts. Designed for low-speed maneuvering and killing tanks with
> its GAU-8 seven-barrel 30-mm cannon. Also carried a vast array of air-to-surface missiles.

## §12.2 Designing for Reduced Vulnerability
*[Nicolai & Carichner, p. 295]*

Designing for reduced vulnerability is the strategy of letting the aircraft "take a licking but keep
on ticking." Vulnerability reduction concepts:

- **Critical component redundancy with separation.** Redundancy (usually two) in critical
  components, separated so a missile warhead won't take both out. Examples: multiple engines,
  flight control computers, control surfaces, fuel pumps.
- **Critical component location.** Locate critical components so they aren't damaged by failure of
  another component (e.g., engine fire, thrown blade from a damaged compressor/turbine section).
- **Passive damage suppression.** Design critical structure to be damage tolerant or fail-safe.
  Filling fuel tanks with foam minimizes voids, limiting fuel-air mixture leading to explosion.
- **Active damage suppression.** Filling the fuel tank with inert gas (nitrogen, HALON) as fuel is
  consumed limits fuel-air mixture buildup, greatly reducing explosion probability. Fire detection/
  suppression systems (especially engine bay) have saved many aircraft.
- **Critical component shielding.** Shield critical components deliberately, or locate them so
  they're shielded by other components. Examples: titanium "bathtub" around the A-10 pilot; locating
  the two turbofan engines above the wing for ground-fire shielding.
- **Critical component elimination.** Eliminate critical components and replace their function
  another way — e.g., replacing the pilot on UAVs.

These vulnerability concepts shown in Fig. 12.2, discussed in detail in [2]. Fig. 12.3 shows the
concepts worked for the A-10A (but made the pilot nervous).

### Fig 12.1 — Different strategies for high survivability
*[Nicolai & Carichner, Fig. 12.1, p. 296]* — Four photographs, two per strategy: "Low Vulnerability
(A-10A)" (nose-on takeoff shot; side profile in flight showing twin tails/engines above wing);
"Low Susceptibility (F-117A)" (aerial view over coastline showing faceted planform; three-quarter
view showing weapon bay open). No plotted data (photographs).

## §12.3 Designing for Reduced Susceptibility
*[Nicolai & Carichner, p. 297]*

Reducing susceptibility starts with reducing an enemy defense-system sensor's ability to detect the
aircraft's presence. Enemy defense-system sensors are of five types:

- **RF/Radar.** Radar transmits RF energy, which reflects off the target aircraft back to an RF
  sensor (usually at the transmitter) — a radar cross section (RCS) return/signature. The only
  active defense system. RF frequencies of interest: 100 MHz–16 GHz (covers worldwide RF air-defense
  systems). Lower-frequency (VHF/UHF band) systems: long-range detection. Midrange frequencies (L,
  S, C bands): tracking radars. High-frequency X band (fine resolution): fire-control radars.
- **IR/Infrared.** Senses emitted or reflected IR energy from the target minus background IR energy.
  IR signature is a contrast relative to background — can be negative or positive. Passive system,
  thermal-sensitive sensor, 1–12 micron wavelength bands.
- **Visual.** Senses emitted or reflected visual energy minus background visual energy (e.g.,
  emitted: a head lamp). Signature is a contrast — can appear as a glint or a black hole. Passive
  system: electro-optical sensors and the human eyeball. Visible band: 0.37–0.75 micron.
- **Acoustic.** Senses emitted or reflected acoustic energy minus background acoustic energy (target
  acoustic energy rarely contains reflected energy). Signature is a contrast relative to background.
  Passive system: microphones or the human ear.
- **Electronic intelligence and signals intelligence (ELINT/SIGINT).** Aircraft often emit
  electronic signals that can be used to locate [continues next page].

### Fig 12.2 — Design for low vulnerability
*[Nicolai & Carichner, Fig. 12.2, p. 298]* — A-10 cutaway illustration, labeled callouts: Damage
Suppression (foam or inert-gas-filled fuel tanks, and separately, damage-tolerant fail-safe
structure), Component Location, Component Elimination, Component Separation, Redundancy, Shielding
(titanium "bathtub" around pilot). No plotted numeric data (labeled cutaway diagram).

### Fig 12.3 — A-10 can tolerate severe damage and still survive
*[Nicolai & Carichner, Fig. 12.3, p. 299]* — Six photographs of battle-damaged A-10 aircraft:
shattered wingtip/aileron in flight, damaged vertical tail under repair, belly gun-fire damage,
severely damaged engine nacelle ("Creek" nose art visible), torn wing skin/structure exposed,
ground crew inspecting an unexploded ordnance lodged in the aircraft. Caption: "A-10 can tolerate
severe damage and still survive. It has excellent vulnerability." No plotted data (photographs).

them. The intelligence community uses these electronic signals to locate ground targets and gather
electronic information on enemy weapon systems, in development and fielded. The U.S. uses airborne
platforms such as the EP-3, EC-130, and U-2 to gather this electronic intelligence.

This chapter discusses design features that reduce the RF, IR, visual, and acoustic signatures of
aircraft.

## §12.4 Radar Cross Section (RCS) Signatures
*[Nicolai & Carichner, p. 300]*

An aircraft's RCS is measured relative to the radar return from a metal sphere with a cross section
of one square meter. The common unit for RCS is decibels relative to a one-square-meter reference
cross section (dBsm):

**Eq (12.1)** *[Nicolai & Carichner, Eq. (12.1), p. 300]*:
```
RCS in dBsm = 10·log10(RCS in square meters)
```
Fig. 12.4 (from [3]) shows the RCS of typical aircraft.

### Fig 12.4 — Definition of RCS used to assess the level of stealth
*[Nicolai & Carichner, Fig. 12.4, p. 300]* (data from [3]) — Horizontal log-scale axis: square
meters (0.0001–10,000) with corresponding decibel-square-meters (dBsm) scale (-40 to 40). Aircraft/
object examples positioned along the scale (left to right, increasing RCS): Insects, F-117/B-2/F-22,
Birds/F-35, Humans, F/A-18E/F, Fighter Aircraft, Bombers/Transport Aircraft, B-52, Ships. *(read from
plot, approximate positions)*:

| Object/Aircraft | RCS (dBsm) | RCS (m²) |
|---|---|---|
| Insects | ~-30 | ~0.001 |
| F-117 | ~-28 | ~0.0016 |
| B-2, F-22 | ~-25 | ~0.003 |
| Birds | ~-20 | ~0.01 |
| F-35 | ~-18 | ~0.016 |
| Humans | ~-5 | ~0.3 |
| F/A-18E/F | ~0 | ~1.0 |
| Fighter Aircraft (conventional) | ~20 | ~100 |
| Bombers | ~28 | ~630 |
| Transport Aircraft | ~30 | ~1000 |
| B-52 | ~35 | ~3160 |
| Ships | ~40 | ~10,000 |

### §12.4.1 Radar Scattering Phenomena
*[Nicolai & Carichner, p. 300]*

As the electromagnetic (EM) field generated by a radar washes over a target, RF energy is
reflected; this reflected energy is received by RF sensors as the target RCS. Strategy for reducing
target RCS [4-6]:

- **Shaping.** If the target surface is properly shaped, reflected energy won't be received by the
  threat radar. Controls the direction of reflected energy; works well provided the threat RF sensor
  is collocated with the radar. If the RF sensor is elsewhere, target RCS could actually be enhanced
  (theory behind bistatic radar defense).
- **Absorption.** If EM energy interacts with high-resistance iron particles on the target surface,
  energy converts to thermal energy by ohmic heating (temperature rise in a conducting material with
  electrical resistance when current flows).
- **Cancellation.** If the target surface reflects part of the EM energy with a 180° phase change,
  the EM energy is canceled. Typically done passively with coatings of judiciously chosen thickness
  (thickness depends on frequency/wavelength of incident energy). Can also be done actively by an
  onboard electronic system sensing the time/direction of incident EM energy and transmitting energy
  of equal strength/opposite phase to cancel it.

> **Sidebar — Skunk Works Polaroid anecdote:** In the late 1970s, the Skunk Works was preparing for
> its first wind tunnel test of a stealth aircraft design, taking routine pictures of the model with
> a Polaroid camera. The photographer complained that all the pictures were out of focus. After a
> brief silence, someone realized the cameras used a sonar-focusing device depending on return
> reflections to adjust focus length — since stealth aircraft are designed to not directly return any
> impinging waves, the camera couldn't focus on it. It was clear that stealth from shaping was going
> to work. Have Blue and the F-117A designs followed, and the rest is history.

EM energy is reflected at the target vehicle by three scattering mechanisms shown in Fig. 12.5
[7,8]:

- **Specular reflections** result when a radar wave is directly reflected from an object, similar to
  a flashlight shining on a mirror. Specular reflection angle equals the radar wave's incidence
  angle. A normal surface reflects specular energy right back to the radar; an angled surface
  reflects energy away from the radar. Specular reflection has a main lobe and side lobes (Fig.
  12.6). Controlled by shaping the aircraft to reflect energy away from the radar.
- **Diffraction** occurs when EM energy encounters a sudden discontinuity in surface slope or a
  change in electrical impedance (material change). Everyday examples: rainbows, reflections from
  glass prisms. Reduced by avoiding surface discontinuities (Fig. 12.5), cancellation, and
  absorption.
- **Traveling waves** (or surface waves) occur as the EM field washes over the target and sets up
  electrical currents (induced by incident EM energy) in the aircraft's conducting surface.
  Traveling waves, like diffraction, scatter when they encounter surface discontinuities. Reduced
  the same ways as diffraction.

### Fig 12.5 — Electromagnetic (EM) scattering mechanisms
*[Nicolai & Carichner, Fig. 12.5, p. 302]* — Four schematic panels: (top-left) "Specular" — ellipse
with incident/reflected ray straight back along incidence for normal surface; (top-right) "Traveling
Wave" — ellipse with rays scattering off at an angle for an angled surface; (bottom-left)
"Diffraction" — wedge shape with radiating scatter pattern at the tip; (bottom-right) elongated
body labeled with discontinuity sources: Curvature Discontinuity, Slope Discontinuity, End of Body,
Cracks/Gaps, Material Change — each circled as a traveling-wave scattering point. No plotted
numeric data (schematic).

### Fig 12.6 — Electromagnetic wave backscatter geometry
*[Nicolai & Carichner, Fig. 12.6, p. 302]* — RCS lobe pattern vs Aspect Angle `θ` (deg): a tall main
spike at `θ=0` flanked by symmetric side lobes decreasing in height, labeled `~13 dB`, `~20 dB`,
`~26 dB` rolloff levels. Sidelobe rolloff defined as `[sin(kw·sinθ)/(kw·sinθ)]²`. Null locations:
`θ = 2·sin⁻¹(n·λ/2L)` for `-π/4 ≤ θ ≤ π/4`. Main spike width (null-to-null): `θ = 2·sin⁻¹(λ/L)`.

The RCS of an aircraft is the vector sum of all reflected energy from all scattering sources and
depends on aircraft orientation relative to the radar and on the EM wave's wavelength and
polarization. Wavelength is an important RCS-reduction parameter; wavelength (`λ`) depends on
frequency (`f`):

**Eq (12.2)** *[Nicolai & Carichner, Eq. (12.2), p. 303]*:
```
λ (in inches) = 11.8 / f
```
where frequency is in gigahertz. Example: the 170-MHz Tall King long-range detection radar has a
wavelength of 66 inches; the 10-GHz Flap Lid fire-control radar has a wavelength of just over one
inch. Every scattering source on the aircraft (wing LE length, vertical tail height, inlet lip
radius, outer mold line/OML, gaps and cracks, skin surface imperfections, etc.) has a characteristic
dimension `L` and a scattering size in wavelengths of `L/λ`. Primary scattering mechanisms
(specular, diffraction, traveling wave) vary with scattering-source size in wavelengths (Fig. 12.7)
— the reduction technique also varies with `L/λ`. From Fig. 12.6, the specular main-lobe width, null
locations, and sidelobe rolloff all depend on `L/λ`.

> **Sidebar — Father of Stealth Wins Big:** Ben Rich took over the Skunk Works from Kelly Johnson in
> early 1975 and maneuvered it, over Kelly Johnson's objection, into the DARPA XST program. By
> October, Lockheed and Northrop were locked in a "winner take all" competition on the USAF's radar
> test range at White Sands, New Mexico. Each company built an RCS model of their "Have Blue" design.
> Ben had ball bearings made with the same RCS as Lockheed's design. He then prowled the halls of the
> Pentagon, rolling a ball bearing across generals' desks and announcing "General, here's your new
> fighter airplane." The generals' eyes would bug out of their heads. Northrop yelled foul, and Ben
> stopped approaching anyone not cleared into the DARPA program. Thanks to the creative genius of
> several Skunk Works engineers and Ben's rapport with the customer, Skunk Works won the program with
> a design that later became the F-117A stealth fighter. Ben was chief Skunk until his retirement in
> 1991 — very different management style from Kelly's (Kelly ruled by bad temper; Ben ruled by bad
> jokes). Ben became the chief spokesman for pursuing stealth technology within the DOD and rightly
> earned the title "Father of Stealth."

### Fig 12.7 — Scattering for aircraft-size targets
*[Nicolai & Carichner, Fig. 12.7, p. 304]* — Table-style figure with columns `L/λ < 3` (HF, VHF,
UHF), `L/λ > 3` (Microwave), `L/λ >> 3` (MMW), and rows: **Primary Scattering Sources** — [HF/VHF/
UHF: Diffraction, Traveling Waves, Resonances] / [Microwave: Specular Reflection, Apertures,
Details] / [MMW: Details, Diffuse Scattering]; **Scattering Reduction Techniques** — [Radar
Absorbers, Nulling Techniques] / [Shaping, Radar Absorbers, Shielding] / [Radar Absorbers,
Tolerances]; **Design Approaches** — [High-Power Computation with Optimization, Experiment] /
[Simple Computer Models, Experiment] / [Experiment]. No plotted numeric data (matrix/table figure).

With this `L/λ` dependence, one expects a different polar RCS pattern for small `L/λ` vs large
`L/λ` — confirmed in Fig. 12.8 for a diamond-shaped metal (no-coatings) aircraft. For `L/λ < 3`,
shaping isn't very effective, though it does steer diffraction scattering; RCS pattern is a blob
with no distinct spikes — RCS reduction design would feature absorption and cancellation. For
`L/λ > 3`, the pattern is characterized by very distinct/narrow spikes and a "fuzz ball" (surface
detail scattering) — RCS reduction design would feature shaping as well as absorption.

History of current U.S. aircraft stealthy design shown in Fig. 12.9. Basics of stealth known since
the 1950s, but analytical techniques were experimental (lacking computer power). In the 1970s,
computer power increased enough to estimate RCS of faceted vehicles — this second-generation
stealth capability led to the DARPA XST (Experimental Stealth Technology)/USAF Have Blue
demonstrator program (Fig. 12.10). Even before Have Blue flight test completed, the USAF ordered 59
F-117As. In the 1980s the U.S. entered third-generation stealth, with computer power sufficient to
analyze curved-surface configurations — leading to the Northrop B-2 stealth bomber (very expensive,
only 21 produced), the AGM-129 Advanced Cruise Missile (over 400 produced with nuclear warheads),
the F-22, and the AGM-158 JASSM. The F-35 Joint Strike Fighter represents the fourth generation of
stealth. Fig. 12.11 shows a gallery of U.S. low-signature (stealthy) demonstrator vehicles and
production aircraft.

### Fig 12.8 — RCS pattern shaping and details for (a) VHF and UHF, and (b) microwave
*[Nicolai & Carichner, Fig. 12.8, p. 305]* — Two polar-plot panels: (a) `L/λ < 3` — irregular
jagged blob pattern labeled "Diffraction" and "Traveling Waves," caption "Shaping steers diffraction
effects"; (b) `L/λ > 3` — compact pattern with distinct narrow spikes labeled "Shaping Spikes" and a
small central lobe labeled "Detail - 'Fuzz Ball'," caption "Shaping steers specular reflection". No
tabulated numeric data (qualitative polar patterns).

### §12.4.2 Vehicle Shaping
*[Nicolai & Carichner, p. 305]*

RCS design starts by establishing a smooth conducting ground plane completely around the aircraft.
The ground plane keeps EM energy from penetrating the aircraft interior and reflecting off all
structure/subsystems. Silver paint is a popular treatment, with conductive films and fabrics used
over gaps, cracks, and fasteners. The glass canopy and sensor lenses are made conducting by painting
with a thin film of indium tin oxide (ITO).

**Fig. 12.9** — *Definition of stealth generations* *[Nicolai & Carichner, Fig. 12.9, p. 306]*. A
timeline chart (1950–2010) grouping low-observable aircraft/weapons into four generations, separated
by two prediction-method transitions ("Faceting RCS Prediction" and "Curved Surface RCS Prediction"):
- **Generation I** (~1955–1973): Hound Dog, U-2, A-12, SR-71, AQM-91A, BQM-34A.
- **Generation II** (~1973–1983): XST, Have Blue, F-117A.
- **Generation III** (~1983–2000): B-2, AGM-129, USN A-12, F-22, AGM-158.
- **Generation IV** (~2000–2010): F-35.

The RCS design continues by controlling the direction of the reflected energy through shaping, then
coatings are put on the surface to absorb and cancel the energy. Here it is assumed that there is
intelligence information on how and where the threat radar is deployed and how many. It is necessary
to know if the threat is above, below, co-altitude, in front, off to the side, or behind when it is
encountered so that the reflected energy can be deflected away from the receiver.

**Fig. 12.10** — *Have Blue low-observable technology demonstrator* *[Nicolai & Carichner, Fig. 12.10,
p. 306]*. Unclassified photo of the Lockheed Have Blue demonstrator with callouts: Treated Canopy,
Inlet Grids, Treated/Shielded Exhaust Nozzles, Radar-Absorbing Materials and Structure, Highly Swept
Faceted Surfaces, Fly-by-Wire Flight Controls. Dimensions: Length = 38 ft, Span = 22.5 ft,
Weight = 12,000 lb.

Vehicle shaping works best for the case of an $L/\lambda > 3$ target. This is because the reflected
energy spikes are narrow and well defined. The sweep of the wing and tail leading edge (LE) and
trailing edge (TE) establishes the basic spike structure for the target vehicle to defeat the threat.
Then the scattering spikes from all other sources are aligned with this basic spike structure. This
strategy is shown in Figs. 12.12 and 12.13. The F-117 and B-2 are termed four-spike designs, whereas
the YF-22 and YF-23 are six-spike designs due to the fuselage side spikes. Notice how the inlet and
nozzle apertures, and all the gaps and cracks from the bomb bay doors, landing gear doors, and control
surface hinge lines are swept to line up with the wing or tail spikes. Typically the wing and tails
are swept such that their

**Fig. 12.11** — *Gallery of low-observable aircraft* *[Nicolai & Carichner, Fig. 12.11, p. 307]*. A
photo gallery organized by Development vs. Production status: Development row — Ryan BQM-34,
Northrop AGM-137 TSSAM, Lockheed Have Blue, Northrop Tacit Blue, Boeing X-45A, Northrop YF-23,
Lockheed Tier 3 Darkstar, Boeing X-32, Lockheed Martin Polecat. Production row — Lockheed SR-71,
Convair AGM-129 ACM, Lockheed F-117, Lockheed AGM-158 JASSM, Ryan AQM-91, Lockheed F-22, Northrop B-2,
(one entry marked "Classified"), Lockheed Martin F-35.

**Fig. 12.12** — *Planform shaping for low observables* *[Nicolai & Carichner, Fig. 12.12, p. 308]*.
Three-view comparison of the Lockheed F-117A (Span 43 ft 4 in., Length 65 ft 11 in., Height 12 ft
5 in.) and Northrop B-2A (Span 172 ft 0 in., Length 69 ft 0 in., Height 17 ft 0 in.), showing how both
airframes align all leading/trailing edges, inlet/exhaust apertures, and door/access-panel edges to a
small number of common sweep angles to concentrate RCS spikes in a few known directions.

**Fig. 12.13** — *Planform shaping for low observables (YF-23 vs YF-22)* *[Nicolai & Carichner,
Fig. 12.13, p. 309]*. Top-view comparison of the Northrop YF-23 (Span 43 ft 7 in., Length 67 ft 5 in.,
Height 13 ft 11 in.) and Lockheed YF-22 (Span 43 ft 0 in., Length 64 ft 2 in., Height 17 ft 9 in.),
illustrating six-spike alignment (fuselage side spikes in addition to wing/tail LE/TE) versus the
four-spike F-117A/B-2 designs.

LE and TE spikes are away from a threat directly in front of the aircraft (the Tier 3-Minus Dark Star
was an exception). Careful attention must be paid to the shaping of the vehicle surface so that there
are not any surface discontinuities to trigger diffraction and travelling-wave scattering (see
Fig. 12.5). This means continuous second derivatives (slope change gradient) everywhere. Certainly
gaps, cracks, control surface hinge lines, and facet edges do not meet this criterion and must be
swept to align their scattering with the basic spike structure of the aircraft.

> **Sidebar (p. 309).** In 1975 the Lockheed Skunk Works was testing the Have Blue RCS model when
> range operators abruptly started to get large readings. Visual checks showed a small bird was now
> sitting on the model. After chasing the bird away, measurements were still not consistent with
> previous data. A closer check of the model revealed that the bird had left droppings on the model.
> Once these were removed, the new data agreed with the old. RCS measurements are very sensitive to
> many model irregularities.

### §12.4.3 Absorption and Cancellation
*[Nicolai & Carichner, p. 309]*

As mentioned earlier the EM energy can be absorbed by ohmic heating and in some cases cancelled.
This action all takes place in the coatings that are put on the surface of the aircraft. These
coatings are usually of three types: **radar absorbing structure (RAS**, sometimes called loaded
edge), **radar absorbing material (RAM)**, and **resistive sheet**. These coatings are shown in
Fig. 12.14 applied to a leading edge.

The RAS is the main treatment for low-frequency radars. It is an aerodynamic fairing made of a
material that is transparent to the RF energy but can take flight loads. The fairing is reinforced
with structural honeycomb core or foam that is impregnated with a resistive liquid (similar to
printer's ink) that absorbs the penetrating EM energy through ohmic heating. The depth of the RAS
edge should be $0.38\lambda$ for maximum cancellation.

RAM is primarily a treatment for high-frequency radars. It absorbs the EM energy and provides
cancellation when the thickness is one-quarter wavelength. RAM is very heavy and pretty much limited
to high-frequency application because of the quarter-wavelength thickness criterion. The RAM is an
iron powder held together in a binder. The iron powder is carbonyl iron (most common but oxidation is
a problem), FeSI (excellent corrosion resistance), and FeAl or FeCoV for high-temperature
applications. Binders for the iron particles:

- **Urethane.** The toughest, most common, lowest cost, fast curing, user friendly binder; adheres to
  most materials. Available commercially as a paste and a spray. Good temperature range of −65°F to
  250°F.
- **Silicone.** Over 40 years' industry experience. Available in sheet, paste, and spray forms. Very
  good temperature range of −65°F to 250°F. Disadvantage: nothing bonds to it except silicone.
- **Ceramic.** Excellent temperature range of 600°F to 2000°F; used in nozzle applications. Made by
  loading thin ceramic tiles with the iron powder; also used in brick form for RAS.

The resistive sheet absorbs the surface currents traveling along the target vehicle surface through
ohmic heating. Also known as edge card or R-card; available commercially as a thin decal or appliqué
(resistive ink), resistive mat (resistive fibers suspended in a resin soluble sheet), metalized film
(sputter or vapor deposit Nichrome or Nickel on Kapton film) or fabric (glass fabric with Nickel
treatment).

Weights of these treatments:
- High-frequency RAM (quarter-wavelength thick): 0.6 lb/ft²
- Resistive sheet: 0.05 lb/ft²
- Low-frequency edge RAS — carbon loaded foam/core:
  - VHF, 24-in. edge: 6 lb/ft
  - UHF, 12-in. edge: 2 lb/ft

**Fig. 12.14** — *Low-observable materials selection and implementation — radar absorbing structure
(RAS) edge construction* *[Nicolai & Carichner, Fig. 12.14, p. 310]*. Cross-section of a leading-edge
RAS assembly, labeled: Composite Skin (transparent to RF energy), Surface RAM (important for high
frequency RCS), Radar Absorbing Core (essential for low frequency RCS), Low-Dielectric Tip, Conductive
Treatment (smooth "ground plane" for RCS), Resistive Treatment (necessary for low-frequency RCS,
usually stepped or tapered, ohms/ft²). Caption note: skins/core sandwich provides structural integrity
and withstands flight loads; skins are typically thin glass or quartz composite bonded to core/foam.

### §12.4.4 Inlet and Nozzle RCS Design
*[Nicolai & Carichner, p. 311]*

If not properly designed, the inlet or nozzle can drive the RCS of the entire vehicle in the front or
rear sector. This is because the normal reflection from the compressor face or turbine blades bounces
right back to the radar. A popular design trick is to block the line of sight (LOS) into the inlet or
nozzle by giving the duct an "S" or serpentine shape. This causes the EM energy entering the duct to
bounce off the duct walls, reflect off the compressor or turbine face, and then bounce off the duct
walls again as it exits. If the duct walls are coated with RAM, each bounce reduces the reflected
energy back to the radar.

Another popular design trick is to block the energy entering the inlet or nozzle cavity by a physical
phenomenon called **aperture cutoff**. If the inlet or nozzle cavity dimension (normal to the
polarization) is less than $\lambda/2$ the EM wave cannot enter the cavity. This is why a car AM radio
(530–1600 kHz, $\lambda \sim 1000$ ft) will not work in a 60 ft diameter tunnel, but an FM radio
(88–108 MHz, $\lambda \sim 10$ ft) continues to work. The cavity appears as a black hole. The inlet or
nozzle aperture is then swept to reflect the energy away from the radar. This design trick was used on
the F-117A inlet by putting a grid into the inlet. The grid had a cell size of 0.6 in., which kept the
EM energy of all frequencies below 10 GHz from entering. The inlet
aperture was highly swept so that the inlet contributed very little to the F-117A overall RCS. The
disadvantage for the F-117 was a higher than normal inlet total pressure loss at cruise speed and ice
buildup on the grid. This latter problem was solved by having a wiper blade sweep the ice off of the
grid.

The F-117 flew at altitudes of 28,000 ft so that most threats were below it or co-altitude. The
F-117 nozzle featured a high-AR, two-dimensional nozzle that provided aperture cutoff for low and
middle frequencies. In addition the nozzle lower surface ramp blocked the LOS into the nozzle cavity
for all co-altitude threats and below. Ceramic tile RAM was applied to the duct, and ceramic brick was
used for the loaded edges.

Inlet and nozzle RCS design is summarized on Fig. 12.15. The front–rear frame referred to in
Fig. 12.15 is a device that looks like a potato chip that prevents a normal reflection off of the
compressor or turbine blades. Reference [9] is an excellent article on inlet design.

**Fig. 12.15** — *Inlet and nozzle design guidelines for low-RCS configuration* *[Nicolai & Carichner,
Fig. 12.15, p. 312]*. Bulleted design-guideline outline:
- **Line of Sight (LOS) blockage** — Low frequency–cutoff frequency (dimension < λ/2 normal to
  polarization); Serpentine ducts (need length/diameter L/D ~2.5–3.5 for nozzles, L/D ~4–6 for
  inlets); Front and Rear Frames (approx. one diameter in length); Nozzle ramp angle.
- **Absorb reflected energy** — MagRAM on duct walls; nozzle ducts need high-temperature RAM.
- **Sweep inlet and nozzle lips.**

### §12.4.5 RCS Design Summary
*[Nicolai & Carichner, p. 312]*

Figure 12.16 shows a typical RCS design. The overall configuration should have as few spikes as
possible (the minimum is a three-spike delta configuration) and their directions should be away from
the threat sensors (usually located at the radars). All the scattering sources should align their
individual spikes with the basic spike structure. Edges should be RAS for low-frequency threats and
RAM-coated for high-frequency threats. Resistive sheet should be applied to reduce the travelling-wave
scattering. All gaps, cracks, and hinge lines should be filled, treated, and swept. Inlets and nozzles
should have LOS blockage to the compressor and turbine blades either by aperture cutoff,
serpentine-shaped ducts, or front/rear frame. All ducts should be coated with RAM. The fuselage side
slopes should direct the reflected energy away from the threat and the side shape should have
continuous second derivatives.

**Fig. 12.16** — *Typical low-observable design features (planview)* *[Nicolai & Carichner, Fig.
12.16, p. 313]*. Schematic planview of a faceted LO aircraft nose/forebody with callouts: Parallel
edges with long lengths, Perimeter edge treatment, Canted vertical tail (or no tail), Swept inlet cowl,
LOS blockage to engine face, Engine face treatment (front frame), LOS blockage to turbine face, Swept
nozzle flap.

## §12.5 Infrared
*[Nicolai & Carichner, p. 313]*

Infrared and visual are contrast signatures. This means that they are observed relative to their
background:

**Eq (12.3)** *[Nicolai & Carichner, Eq. (12.3), p. 313]*:
```
Contrast = E_T + E_R - Background
```
where $E_T$ = target emissions; $E_R$ = emissions due to the reflections from the sun, earth, and sky
(clouds).

For Contrast > 0: the target is brighter than the background and appears as a glint (need to reduce
$E$). For Contrast < 0: the target is dimmer than background and appears as a black hole (need to add
$E$).

For Infrared:

**Eq (12.4)** *[Nicolai & Carichner, Eq. (12.4), p. 313]*:
```
I_Contrast = I_E + I_R - Background   (W/sr)
```

For Visual:

**Eq (12.5)** *[Nicolai & Carichner, Eq. (12.5), p. 313]*:
```
V_Contrast = V_E + V_R - Background   (lm/sr)
```

**Fig. 12.17** — *Combat aircraft losses (1972–2006)* *[Nicolai & Carichner, Fig. 12.17, p. 314]*.
Stacked-area chart, x-axis Year (1972–2008), y-axis Aircraft Losses (0–1600), three stacked bands from
bottom to top: AAA/RPG, RF Missile, IR Missile. *(read from plot, approximate cumulative totals)*:

| Year | AAA/RPG (cum.) | + RF Missile (cum.) | + IR Missile (cum., total) |
|---|---|---|---|
| 1972 | ~50 | ~150 | ~280 |
| 1976 | ~190 | ~280 | ~590 |
| 1980 | ~210 | ~330 | ~610 |
| 1984 | ~230 | ~370 | ~1020 |
| 1988 | ~250 | ~400 | ~1110 |
| 1992 | ~280 | ~430 | ~1210 |
| 1996 | ~350 | ~480 | ~1420 |
| 2000 | ~370 | ~510 | ~1450 |
| 2004 | ~390 | ~540 | ~1470 |
| 2008 | ~400 | ~560 | ~1480 |

IR signature reduction is a hard problem because the IR threats are passive (you do not know where a
threat is) and the background varies with time of day, orientation, and weather. In addition most
(over 60%) of the aircraft kills since 1972 have been from IR missiles (see Fig. 12.17). IR SAMs are
the weapon of choice for downing aircraft by terrorist elements because they are user friendly,
require minimum maintenance, and are much cheaper than RF SAMs.

### §12.5.1 Introduction to Infrared (IR 101)
*[Nicolai & Carichner, p. 314]*

The IR radiation sources are shown in Fig. 12.18. The IR signature is determined as follows:

**Eq (12.4)** (restated) *[Nicolai & Carichner, Eq. (12.4), p. 314]*:
```
I_Contrast = I_E + I_R - Background   (W/sr)
```

The aircraft emissions are

**Eq (12.6)** *[Nicolai & Carichner, Eq. (12.6), p. 314]*:
```
I_E = sigma * epsilon * f * T^4 * A_p
```
where:
- $\sigma$ = Stephan–Boltzmann constant = $0.481\times10^{-12}$ Btu/ft²·s·°R
- $\varepsilon$ = Emissivity of emitting surface
- $f$ = Distribution of IR energy in band of interest (i.e., SWIR, MWIR, or LWIR)
- $T$ = Absolute temperature of emitter in °R
- $A_p$ = Projected area

The

**Eq (12.7)** *[Nicolai & Carichner, Eq. (12.7), p. 315]*:
```
I_E = I_Hot_Parts + I_Plume + I_Airframe
```

Representative temperatures [10]:
- Turbine blades (usually cooled): 2300°F
- Nozzle exit (turbojet): 1800°F
- Nozzle exit (turbofan): 1100°F
- Plume (turbojet): 1000°F
- Plume (turbofan): 500°F
- Airframe aero heating at Mach 0.85: 122°F
- Airframe aero heating at Mach 3.2 — LE stagnation point: 800°F; Surface: 550°F

The reflected IR energy is

**Eq (12.8)** *[Nicolai & Carichner, Eq. (12.8), p. 315]*:
```
IR = [(1 - epsilon)/pi] * SUM( E_sun*F_sun + E_sky*F_sky + E_earth*F_earth )
```

Notice that the IR reflectance $= (1-\varepsilon)$, which poses a dilemma when the designer wants to
select an IR paint that will reduce emissions and reflections at the same time.

The IR sensor bands are shown in Fig. 12.18:
- Fire control: SWIR (near IR) 1–3 microns and MWIR (middle IR) 3–6 microns
- Detection, IRST (IR search and track): LWIR (far IR) 6–12 microns

**Fig. 12.18** — *Aircraft infrared radiation sources* *[Nicolai & Carichner, Fig. 12.18, p. 315]*.
Top: EM spectrum band chart (Gamma Rays, X Rays, Ultraviolet, Visible, Infrared, EHF, SHF, UHF, VHF,
HF, MF, LF, VLF) with the Infrared band expanded below into Visible Vector / Near Infrared (1–1.5–2
µm) / Middle Infrared (3–4–6 µm) / Far Infrared (8–10–15 µm) / Extreme Infrared (20–30 µm), with
corresponding wavenumber (cm⁻¹) scale. Bottom: photo of an aircraft in flight with callouts —
Emissions (Plume, Hot Parts, Airframe) and Scattered Reflections (Sunshine, Skyshine, Earthshine).

### §12.5.2 IR Design
*[Nicolai & Carichner, p. 316]*

The rule for reducing the hot-parts emissions is hide what you cannot cool and then coat it with
low-emissivity paint. Figure 12.19 shows some concepts for blocking the LOS to the aircraft hot parts.
The A-10A very carefully located the twin vertical tails so that they blocked the LOS into the engine
cavities at most tail-on angles. The 2-D nozzle and lower surface nozzle ramp on the F-117A
effectively shield the exhaust hot parts from co-altitude and below look angles. Changing from a
turbojet to a medium bypass ratio (i.e., 1–2) turbofan reduces the engine hot parts and plume
emissions significantly. Low-emittance (0.2) paints are available commercially.

The design rule for reducing the exhaust plume emissions is to use a high-bypass turbofan engine if
possible and then promote aggressive mixing of the plume with the ambient air. The exhaust mixers on
commercial transports to reduce noise do a very good job of reducing the plume temperature. Ejector
nozzles also promote plume mixing.

Airframe emissions due to aerodynamic heating can be controlled by flying slower and using
low-emissivity coatings. Most of the time the airframe emissions are small compared with the hot
parts.

Once the aircraft is deployed its IR emissions are pretty much fixed. However, the aircraft can be
repainted from time to time with different $\varepsilon$ paints. From then on it is managing the
reflections and background to drive the contrast to zero.

The strategy for managing the IR reflections is to tailor the mission in terms of time of day,
background, and weather and in some cases to change the reflectance by changing the emissivity.

**Fig. 12.19** — *Hot parts blocking — IR design guidelines* *[Nicolai & Carichner, Fig. 12.19,
p. 316]*. Five design-concept schematics: (1) "Effect of turbine LOS blockage" — plot of Signature
(watts/steradian) vs. Azimuth (Beam→Tail) showing a sharp MWIR peak near "Tail" for "No Blocker" vs.
a greatly suppressed curve "With Blocker"; (2) "(A) Plug Nozzle (B) Swirl Augmentor" duct schematic;
(3) "Curved and Flattened Duct" schematic; (4) "Serpentine Exhaust Duct" schematic; (5) "SERN"
(single expansion ramp nozzle) with "Shield restricts line of sight to hot tailpipe"; (6) "Curved
Inlet Duct" showing hidden Compressor Face.

## §12.6 Visual Signature
*[Nicolai & Carichner, p. 317]*

The visual signature is (restated from Eq. 12.5):

**Eq (12.5)** (restated) *[Nicolai & Carichner, Eq. (12.5), p. 317]*:
```
V_Contrast = V_E + V_R - Background   (lm/sr)
```

The $V_E$ is usually zero; however, sometimes illumination can be added (positive $V_E$ using a head
lamp, for example) but illumination can never be taken away (negative $V_E$).

The visual sensor is usually a human eyeball. Thus, the detection ranges are small — typically 5–8
n mile.

Once again the strategy needs to be to plan the mission and mission profile to avoid or minimize the
threat before designing-in performance penalty features. For example, the visual signature can be
eliminated by shielding the target from the sensor with terrain or by flying above 5 n mile and not
contrailing. The visual signature can be minimized by flying at night.

If the target needs to fly at low altitudes and within visual range of the human eyeball, then the
tradeoff between reflectance $(1-\varepsilon)$ and background must be considered. Figure 12.20 shows
how the target reflectance needs to vary with a daytime background to reduce the detection range for
a C-130-sized target. For a clear full-moon night background the same C-130 would need a reflectance
of about 0.85 to fill in the black hole contrast.

## §12.7 Acoustic Signature
*[Nicolai & Carichner, p. 317]*

The acoustic sensor is the human ear and sometimes a microphone. The acoustic signature is a contrast
between the emitted noise and the background:

For Acoustic:

**Eq (12.9)** *[Nicolai & Carichner, Eq. (12.9), p. 317]*:
```
A_Contrast = A_E + A_R - Background   (EPNdB)
```
where EPNdB is the effective perceived noise level in decibels and the reflected noise term $A_R$ is
usually zero.

**Fig. 12.20** — *Daytime visual detection ranges* *[Nicolai & Carichner, Fig. 12.20, p. 318]*.
Detection Range (km, 0–20) vs. Reflectance (0–1.0) for a C-130-sized aircraft, average growth
terrain, 100 ft altitude. Four curves *(read from plot, approximate)*:

| Reflectance | Clear Sunny Day, Sky Background | Clear Sunny Day, Terrain Background | Overcast Day, Sky Background | Overcast Sun, Terrain Background |
|---|---|---|---|---|
| 0.05 | ~16.3 | ~9.8 | ~6.6 | ~1.5 |
| 0.2 | ~14.3 | ~4.8 | ~6.5 | ~0.6 |
| 0.4 | ~12.7 | ~9.8 | ~6.4 | ~2.7 |
| 0.6 | ~11.0 | ~11.9 | ~6.2 | ~5.0 |
| 0.75 | ~9.8 | ~2.0 | ~6.1 | ~7.3 |
| 1.0 | ~7.9 | ~16.3 | ~5.9 | ~12.8 |

Here a negative contrast (the background is more noisy than the target) is a good thing. If you are a
special forces team, the best place to land your aircraft is in the middle of a noisy mall. The good
news is that the locals will never hear you. The bad news is that you will probably be seen, with the
result being the same as if they heard you.

Acoustic energy is absorbed by buildings, walls (e.g., the noise barriers between residential areas
and freeways), humidity, and trees.

Figure 12.21 shows the noise source characteristics for an aircraft. Notice that the main sources of
noise are the airframe (aircraft in a dirty configuration with gear and flaps down) and the jet
mixing. The reader is urged to return to Section 4.7 for more discussion of aircraft noise and its
suppression. Another aircraft noise source is the sonic boom at speeds greater than Mach 1.0 (see
Section 4.6). The main noise source for helicopters is the "slapping" of the rotor blades.

There are design features that can reduce the acoustic signature, such as nozzle noise suppressors,
but the most effective approach is mission planning and tactics:
- Avoid acoustic sensors (human ears)
- Power down or slow down when possible
- Carefully select the background and environment

**Fig. 12.21** — *Noise source characteristics* *[Nicolai & Carichner, Fig. 12.21, p. 318]*. Left:
aircraft silhouette with overlaid noise-source contours labeled Fan (aft), Turbine, Combustion, Fan &
Compressor, Jet Mixing, Shock Cell, Airframe, and Total Aircraft Noise (dashed envelope). Right:
1/3 Octave Band Level vs. 1/3 Octave Band Center Frequency, curves for Combustion, Turbine, Jet
Mixing, Airframe, Shock Cell, and Total Aircraft Noise (dashed envelope on top).

## §12.8 Case Study — AGM-129A Advanced Cruise Missile
*[Nicolai & Carichner, p. 319]*

In 1977 the U.S. Air Force was convinced (from the Have Blue program) that stealth could greatly
increase the survivability of their strategic cruise missile fleet and issued the requirements for the
Advanced Cruise Missile (ACM). The requirement was for a low-signature air-launched cruise missile
that could deliver a nuclear weapon (W-80) against a high-value strategic target from a distance of
1900 n mile. Industry went to work, with Lockheed pursuing a medium-altitude design and Boeing a
low-altitude design. Having started the Have Blue program with their XST program, DARPA was
emotionally involved with the stealth technology and started their own ACM program called Teal Dawn.
The first author was an Air Force colonel at DARPA and became the Teal Dawn program manager. Teal
Dawn was selected for the ACM and entered development by the U.S. Air Force, with GD Convair as the
contractor, in 1983. The ACM entered operation in 1991 with over 460 cruise missiles produced. The
AGM-129A ACM is shown in Fig. 12.22.

Example 5.3 (Low-Altitude, Subsonic Cruise Missile) in Chapter 5 is essentially the AGM-129A ACM. The
ACM requirement was pretty clear except for the mission profile: high altitude or low altitude. After
much discussion, including intense interaction with the Defense Science Board, it was decided that
Teal Dawn would fly a low-altitude TF/TA profile at Mach 0.7 similar to the AGM-86 ALCM and the
AGM-109 Tomahawk. This meant that the RCS design against the low-frequency detection radars (Tall
King and Spoon Rest) would be made easier because most of the flight would be below the radar
horizon. The threats would be the short-range, high-frequency SAMs defending the high-value targets
(located co-altitude and head-on) and the airborne interceptors (AIs, located above). The signature
requirements were as follows:

- Very low RCS in the ±20 deg front sector (X-band)
- No side or rear sector RCS requirement
- Low IR signature (top sector for the lookdown–shootdown AIs)

**Fig. 12.22** — *Three-view of Convair AGM-129A ACM* *[Nicolai & Carichner, Fig. 12.22, p. 320]*.
Three-view drawing with dimensions: overall length 250.0 in., wingspan 122.8 in., forward-fuselage
(nose) diameter 25.2 in., wings swept forward at 25°.

The TF/TA flight profile compounded the AI RF and IR detection problem because the ACM was operating
in ground clutter, and the dense air (and possible clouds) increased the IR transmission losses. It
was concluded that the TF/TA flight profile resulted in more relaxed signature requirements than a
medium-altitude profile.

The RCS design was a sharp chisel nose shape and a flush inlet on the bottom of the fuselage. The
wings were swept forward 25 deg for a more favorable packaging of the wing deployment mechanism. The
wing LE spikes reflected off the fuselage and outside of the ±20 deg front sector. The missile was
treated with high-frequency RAM. The IR design was to use a Williams F 112 turbofan (derivative of the
F107 turbofan) for a cool exhaust plume. The plume was cooled further using an aspect ratio 4, 2-D
nozzle that enhanced the plume mixing with the ambient air. The exhaust cavity was shielded from RF
and IR sensors by an upper surface nozzle ramp. Finally the missile was painted with a high-emissivity
paint to reduce the sunshine and cloudshine IR reflections (because the ground background is dark).

An AGM-129A has never been launched in anger!

### References
*[Nicolai & Carichner, Chapter 12, pp. 321]*

1. Rich, B. R., *Skunk Works*, Little, Brown, Toronto, 1994.
2. Ball, R. E., *The Fundamentals of Aircraft Combat Survivability Analysis and Design*, AIAA
   Education Series, AIAA, Reston, VA, 1985.
3. Fulghum, D. A., "Stealth Retains Value, but Its Monopoly Wanes," *Aviation Week and Space
   Technology*, 5 Feb. 2001, pp. 53–57.
4. Barrie, D., "LO and Behold," *Aviation Week and Space Technology*, 11 Aug. 2003, pp. 50–53.
5. Whitford, R., "Designing for Stealth in Fighter Aircraft (Stealth from the Aircraft Designer's
   Viewpoint)," Paper 965540, 1996 World Aviation Congress, 21–24 Oct., Los Angeles, CA (sponsored by
   AIAA and SAE).
6. Lynch, D., "How the Skunk Works Fielded Stealth," *Air Force Magazine*, Nov. 1992, pp. 22–28.
7. Piccirillo, A. C., "The Have Blue Technology Demonstrator and Radar Cross Section Reduction,"
   Paper 965538, 1996 World Aviation Congress, 21–24 Oct., Los Angeles, CA (sponsored by AIAA and
   SAE).
8. Aronstein, D. C., "The Development and Application of Aircraft RCS Prediction Methodology," Paper
   965539, 1996 World Aviation Congress, 21–24 Oct., Los Angeles, CA (sponsored by AIAA and SAE).
9. Fulghum, D. A., "Stealth Engine Advances Revealed in JSF Designs," *Aviation Week and Space
   Technology*, 19 March 2001, pp. 53–57.
10. Varney, G. E., "IR Signature Measurement Techniques and Simulation Methods for Aircraft
    Survivability." Paper 79-1186, AIAA–Society of Automotive Engineers–American Society of
    Mechanical Engineers 15th Joint Propulsion Conf., 18–20 June 1979, Las Vegas, NV.

---
**Chapter 12 extraction complete.** All Figs 12.1–12.22, Eqs (12.1)–(12.9), and References [1]–[10]
captured. No numbered tables in this chapter.
<!-- APPEND-HERE -->
