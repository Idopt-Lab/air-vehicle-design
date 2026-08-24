# Chapter 5 — Selection and Integration of the Propulsion System

**Source:** J. Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration of the Propulsion System*, Chapter 5 "Selection and Integration of the Propulsion System," printed pp. 123–140 (PDF indices 134–151).

The chapter is Step 5 of preliminary-design sequence I of Chapter 2. It has one numbered
equation (Eq. 5.1, propeller diameter) plus a defining relation for blade power loading.
Its citable data are Table 5.1 (engine-failure probability), Tables 5.2–5.4 (propeller
diameter, blade count and blade power loading for six airplane classes), Figure 5.1
(engine type vs. speed-altitude envelope), and the propeller-tip clearance rule.

Chapter 5 covers three decisions:

1. Selection of the propulsion system type or types.
2. Number of engines, and the power (or thrust) level of each.
3. Disposition of the engines: integration into the configuration.

---

## 5.1 Selection of Propulsion System Type

Factors that control the choice of propulsion system type (p. 123):

1. Required cruise speed and/or maximum speed
2. Required maximum operating altitude
3. Required range and range economy
4. FAR 36 noise regulations (civil airplanes only)
5. Installed weight
6. Reliability and maintainability
7. Fuel amount needed
8. Fuel cost
9. Fuel availability
10. Specific customer or market demands
11. Timely certification

Overall fuel efficiency and installed weight usually control the decision. Figure 5.1
shows which propulsion type suits which flight envelope (1985+ technology).

From a certification point of view (civil and military) only these types are viable
during the next 5–10 years (p. 125):

1. Piston/propeller, with or without supercharging
2. Turbo/propeller
3. Propfan
4. Unducted fan
5. Turbojet
6. Turbofan
7. Rocket
8. Ramjet

Types 1–4 can be offered with single or contra-rotating propellers and/or fans.
References 16–18 discuss the characteristics of these systems.

### Step 5.1
Check the mission specification for a definition of the powerplant type. The type is
often specified. If it is, go to Step 5.4. If it is not, go to Step 5.2.

### Step 5.2
Draw a preliminary speed (or Mach) versus altitude envelope for the airplane. The
preliminary sizing work of Part I (Ref. 1) usually gives this.

### Step 5.3
Compare the airplane speed-altitude envelope with the envelopes of Figure 5.1. Select
the powerplant type with the best overall match.

Do not mix different powerplant types in one airplane: different types need different
operating procedures, which increases crew workload, and maintenance cost increases.
Successful exceptions (p. 126):

1. Convair B36 bomber: six piston/propeller engines and four turbojets.
2. DeHavilland Comet: rockets in addition to four turbojets, to improve field
   performance at hot-and-high airports.
3. Lockheed P2V Neptune: two piston/propeller engines and two turbojets.

### Figure 5.1 — Engine Types Used in Relation to the Speed-Altitude Envelope of Airplanes
*[Roskam Part II, Fig. 5.1, p. 124]* — Hand-drawn chart. Ordinate: altitude, ft × 10⁻³,
0 to 60. Abscissa: Mach number, 0 to 3.0 (labelled ticks at 1.0, 2.0, 3.0). Each airplane
class is a closed dashed envelope. The following are approximate envelope apex points
**(read from plot; the chart is hand drawn and has no grid, so treat these as ±0.05 in
Mach and ±2,000 ft in altitude)**:

| Labelled class | Engine type on the label | Approx. ceiling (ft) | Approx. Mach at the ceiling |
|---|---|---|---|
| Homebuilts | piston/prop | 10,000 | 0.25 |
| Single Eng. | piston/prop | 15,000 | 0.30 |
| Twins | piston/prop | 25,000 | 0.45 |
| Regional and Twin Turboprops | turboprop | 35,000 | 0.60 |
| Jet Transp. | turbofan | 44,000 | 0.90 |
| Business Jets | turbojet/fan | 51,000 | 0.90 |
| Fighters | turbojet/fan with A/B | (see note) | (see note) |
| Ramjets / Rockets | ramjet, rocket | beyond the fighter boundary | above about M 2.8 |

Note on the fighter and ramjet/rocket regions: they are not closed envelopes. The
fighter region is bounded by a single long dashed line that runs from about
(M 1.6, 55,000 ft) down to about (M 2.8, 30,000 ft), with an arrow that carries the
"FIGHTERS TURBOJET/FAN WITH A/B" label to it. A short vertical bar near M 2.8 divides
"RAMJETS" (above) from "ROCKETS" (below), with an arrow pointing to higher Mach. The
chart does not close the fighter region on its low-speed side, so no single ceiling/Mach
pair describes it. [verify p. 124 — read at 220 dpi and again at 500 dpi zoom of the
lower half; the ramjet/rocket divider is legible but the numbers on the fighter boundary
are inferred from the axis ticks, not printed.]

---

## 5.2 Selection of the Number of Engines and the Power or Thrust Level per Engine

The total take-off power or thrust is already known from Section 3.7 of Part I (Ref. 1).
The type was decided in Section 5.1 Step 5.3. Only the number of engines remains.

Two possibilities:

1. **A new engine will be developed.** The engine can be tailored to the design, but
   development and certification are expensive and slow. Typical lead time for a new jet
   engine: **7–10 years**.
2. **An existing engine must be used.** Reference 8 gives data on existing engines.
   Because the power or thrust of an existing engine is frozen, the number of engines
   comes from dividing the necessary take-off power or thrust by an integer: usually 1,
   2, 3 or 4. Beyond four engines, maintenance, rigging and failure probability become
   unacceptable. For very large airplanes, Lockheed and Boeing design studies show that
   more than four engines is again reasonable.

### Table 5.1 — Relation Between Engine Failure Probability and the Number of Engines Used
*[Roskam Part II, Table 5.1, p. 127]*

`P_ef` = failure probability of one engine.

| Airplane with: | Failure of 1 Engine | Failure of 2 Engines | Failure of 3 Engines |
|---|---|---|---|
| two engines | 2·P_ef | P_ef² | not appl. |
| three engines | 3·P_ef | 3·P_ef² | P_ef³ |
| four engines | 4·P_ef | 6·P_ef² | 4·P_ef³ |

(These are the binomial coefficients C(n,k)·P_ef^k.)

Do not use engines of different power or thrust level in one airplane, for the same
reasons given in Section 5.1. Successful exceptions (p. 127):

1. DeHavilland 121 Trident IIIE: four jet engines, three large and one small. The fourth
   smaller engine allowed higher take-off weights at minimum development and production
   cost.
2. Rutan's Voyager: two piston/propeller engines of different power output, to match
   best fuel consumption to power required for an extreme range requirement.

### Step 5.4
Determine the maximum power `P_TO` (or thrust `T_TO`) requirement for the airplane. This
comes from Section 3.7 of Part I (Ref. 1).

### Step 5.5
Decide the number of engines and the specific engine model. If the mission specification
does not give the number, list candidate engines available on the market (Ref. 8 or
manufacturer brochures). The power or thrust level of the candidate must be as close as
possible to the take-off power or thrust divided by an integer. **A ±10 percent error is
acceptable**: the Part I sizing calculations have the same accuracy.

### Step 5.6 — Class I propeller sizing
For a propeller driven airplane, find the necessary propeller diameter and the number of
blades. Tables 5.2, 5.3 and 5.4 give typical take-off power and propeller data for six
airplane classes. The blade power loading `P_bl` stays inside a limited range for each
class. Select `P_bl` and the number of blades `n_p`, then find the propeller diameter:

> **D_p = { 4·P_max / (π·n_p·P_bl) }^(1/2)**    (5.1)

with the defining relation printed under Tables 5.2–5.4:

> **P_bl = 4·P_max / (π·n_p·D_p²)**

Symbols and units:

| Symbol | Meaning | Units |
|---|---|---|
| D_p | propeller diameter | ft |
| P_max | maximum (take-off) power per engine | hp |
| n_p | number of propeller blades | – |
| P_bl | power loading per blade | hp/ft² |

Note on the printed text of p. 128: it says "Tables 5.2, 5.3 and 5.4 list typical
take-off power and propeller data for six types of airplanes", then in the next sentence
"is within a certain range for these four types of airplanes". The three tables cover six
classes (homebuilts, single engine FAR23, agricultural, military prop trainers, twin
engine FAR23, regional turboprops). "Four" appears to be a misprint for "six".

### Table 5.2 — Max. Engine Power, Propeller Diameter and Number of Propeller Blades for Homebuilts and for Single Engine FAR23 Certified Airplanes
*[Roskam Part II, Table 5.2, p. 129]*

**Homebuilts**

| Airplane Type | Prop. Pitch | P_max (hp) | D_p (ft) | n_p | P_bl (hp/ft²) |
|---|---|---|---|---|---|
| Jurca MJ5 | Fixed | 115 | 6.1 | 2 | 2.0 |
| Piel CP1320 | Fixed | 160 | 5.9 | 2 | 2.9 |
| Piel CP80 | Fixed | 90 | 5.0 | 2 | 2.3 |
| Pottier P70S | Fixed | 60 | 4.3 | 2 | 2.1 |
| Pazmany PL4A | Fixed | 50 | 5.7 | 2 | 1.0 |
| Variviggen | Fixed | 150 | 5.8 | 2 | 2.8 |
| Rand/R KR-1 | 2-pos. | 90 | 4.4 | 2 | 3.0 |
| Van's RV-3 | Fixed | 125 | 5.7 | 2 | 2.5 |
| Sequoia F8L | Fixed | 135 | 6.2 | 2 | 2.2 |
| Per. Osprey II | Fixed | 150 | 5.5 | 2 | 3.2 |

**P_bl range: 1.0 – 3.2**

**Single Engine FAR23 Certified**

| Airplane Type | Prop. Pitch | P_max (hp) | D_p (ft) | n_p | P_bl (hp/ft²) |
|---|---|---|---|---|---|
| CESSNA 152 | Fixed | 108 | 5.8 | 2 | 2.0 |
| CESSNA Skyhawk | Fixed | 160 | 6.3 | 2 | 2.6 |
| CESSNA Skylane | C.Spd | 230 | 6.8 | 2 | 3.2 |
| CESSNA Skywagon (185) | C.Spd | 300 | 6.7 | 3 | 2.8 |
| CESSNA Caravan I | C.Spd | 600 | 8.3 | 3 | 3.7 |
| BEECH V35B Bonanza | C.Spd | 285 | 7.0 | 2 | 3.7 |
| BEECH 38P Lightning | C.Spd | 550 | 7.7 | 3 | 3.9 |
| PIPER PA28 Warrior II | Fixed | 160 | 6.2 | 2 | 2.6 |
| Mooney 201 | C.Spd | 200 | 6.2 | 2 | 3.3 |
| Mooney 301 | C.Spd | 360 | 6.5 | 3 | 3.6 |

**P_bl range: 2.0 – 3.9**

Note printed under the table: `P_bl = 4·P_max / π·n_p·D_p²`.

### Table 5.3 — Max. Engine Power, Propeller Diameter and Number of Propeller Blades for Agricultural Airplanes and for Military Propeller Driven Trainers
*[Roskam Part II, Table 5.3, p. 130]*

**Agricultural Airplanes**

| Airplane Type | Prop. Pitch | P_max (hp) | D_p (ft) | n_p | P_bl (hp/ft²) |
|---|---|---|---|---|---|
| Schweiz. AgCat | C.Spd | 750 | 9.0 | 2 | 5.9 |
| Airtruk PL12 | C.Spd | 300 | 7.3 | 2 | 3.6 |
| EMB 201A | C.Spd | 300 | 7.0 | 2 | 3.9 |
| PZL-104 | C.Spd | 260 | 8.7 | 2 | 2.2 |
| PZL-106A | C.Spd | 592 | 8.6 | 4 | 2.5 |
| PZL-M18A | C.Spd | 1,000 | 10.8 | 4 | 2.7 |
| NDN Fieldmaster | C.Spd | 750 | 8.8 | 3 | 4.1 |
| Cessna AgTruck | C.Spd | 300 | 7.2 | 2 | 3.7 |
| Air Tr. AT-301A | C.Spd | 600 | 9.1 | 2 | 4.6 |
| Ayr. Thrush S2R | C.Spd | 600 | 9.0 | 2 | 4.7 |

**P_bl range: 2.2 – 5.9**

**Military Propeller Driven Trainers**

| Airplane Type | Prop. Pitch | P_max (hp) | D_p (ft) | n_p | P_bl (hp/ft²) |
|---|---|---|---|---|---|
| EMB 312 Tucano | C.Spd | 750 | 7.8 | 3 | 5.2 |
| Indaer Pillan | C.Spd | 300 | 6.3 | 3 | 3.2 |
| Aerosp. Epsilon | C.Spd | 300 | 6.5 | 2 | 4.5 |
| RFB 600 Fantr. | C.Spd | 420 | 4.0 | 5 * | 6.7 |
| SM SF-260 | C.Spd | 260 | 6.3 | 2 | 4.2 |
| FFA AS32T | C.Spd | 420 | 7.2 | 3 | 3.4 |
| Pilatus PC-7 | C.Spd | 650 | 7.8 | 3 | 4.5 |
| NDN-1 Firecr. | C.Spd | 260 | 6.3 | 3 | 2.8 |
| NDN-1T Firecr. | C.Spd | 715 | 7.0 | 3 | 6.2 |
| Beech T34C | C.Spd | 715 | 7.5 | 3 | 5.4 |

**P_bl range: 2.8 – 6.7**

Footnote as printed: `*` This airplane has a ducted fan instead of a propeller.
Note printed under the table: `P_bl = 4·P_max / π·n_p·D_p²`.

### Table 5.4 — Max. Engine Power, Propeller Diameter and Number of Propeller Blades for Twin Engine FAR23 and for Regional Turbopropeller Driven Airplanes
*[Roskam Part II, Table 5.4, p. 131]*

**Twin Engine FAR23 Certified Airplanes**

| Airplane Type | Prop. Pitch | P_max (hp) | D_p (ft) | n_p | P_bl (hp/ft²) |
|---|---|---|---|---|---|
| PIPER PA-31 Navajo | C.Spd | 325 | 6.7 | 3 | 3.1 |
| PIPER PA-31T Chey. II | C.Spd | 620 | 7.8 | 3 | 4.3 |
| CESSNA T303 | C.Spd | 250 | 6.2 | 3 | 2.8 |
| CESSNA 340A | C.Spd | 310 | 6.4 | 3 | 3.2 |
| CESSNA Conquest I | C.Spd | 450 | 7.8 | 3 | 3.1 |
| CESSNA Conquest II | C.Spd | 636 | 7.5 | 3 | 4.8 |
| BEECH Baron 95-B55 | C.Spd | 260 | 6.5 | 2 | 3.9 |
| BEECH Duke B60 | C.Spd | 380 | 6.2 | 3 | 4.2 |
| BEECH King Air C90-1 | C.Spd | 550 | 7.8 | 3 | 3.8 |
| BN2B Islander | C.Spd | 260 | 6.5 | 2 | 3.9 |

**P_bl range: 2.8 – 4.8**

**Regional Turbopropeller Driven Airplanes**

| Airplane Type | Prop. Pitch | P_max (hp) | D_p (ft) | n_p | P_bl (hp/ft²) |
|---|---|---|---|---|---|
| EMB-110 Bandar. | C.Spd | 750 | 7.8 | 3 | 5.2 |
| EMB-120 Brasil. | C.Spd | 1,500 | 10.5 | 4 | 4.3 |
| SF-340 | C.Spd | 1,630 | 10.5 | 4 | 4.7 |
| Fokker F27-200 | C.Spd | 2,140 | 11.5 | 4 | 5.2 |
| Brit.Aer. 748 | C.Spd | 2,280 | 12.0 | 4 | 5.0 |
| Casa Nurt. 235 | C.Spd | 1,700 | 10.8 | 4 | 4.6 |
| Beech C99 | C.Spd | 715 | 7.8 | 3 | 5.0 |
| Beech 1900 | C.Spd | 1,100 | 9.1 | 4 | 4.2 |
| ATR-42 | C.Spd | 1,800 | 13.0 | 4 | 3.4 |
| IAI Arava 201 | C.Spd | 750 | 8.5 | 3 | 4.4 |

**P_bl range: 3.4 – 5.2**

Note printed under the table: `P_bl = 4·P_max / π·n_p·D_p²`.

---

## 5.3 Integration of the Propulsion System

Factors that control engine disposition (p. 132):

1. Effect of power changes or power failures on longitudinal, lateral and directional
   stability and control. The vertical and/or lateral position of the thrustline is
   critically important.
2. Drag of the proposed installation.
3. Weight and balance consequences of the proposed installation.
4. Inlet requirements, and the resulting effect on installed power and efficiency.
5. Accessibility and maintainability.

### Step 5.7
Decide on a pusher, a tractor or a mixed installation.

General rule: if the propeller plane or the inlet plane is forward of the c.g., the
installation is a **tractor**. If it is behind the c.g., the installation is a **pusher**.

Tractor installations tend to be destabilizing. Pusher installations tend to be
stabilizing, in both static longitudinal and static directional stability. A pusher can
therefore save empennage area. Methods to compute these effects are in Parts VI and VII
(Refs 5 and 6).

**Pusher clearance rule (p. 132):** if the propeller is behind the wing trailing edge,
the distance between the wing trailing edge and the propeller plane must be **at least
one half of the local wing chord**. This prevents dynamic excitation of the propeller
blades by the wing vortex system.

### Step 5.8
Decide on mounting the engines on:

- a. the wing
- b. the fuselage
- c. the empennage
- d. any combination of a through c

Refer to the configuration discussions of Sections 3.1 and 3.2, and to factors 1–5 above.
Document all decisions with the reasons for and against.

**Propeller tip clearance rule (p. 133):** keep a clearance between the propeller tips
and the fuselage of **20–40 inches**, depending on the blade power loading and on the
propeller tip speed. This clearance prevents acoustic fatigue of the adjacent structure
and excessive cabin noise.

For jet engines, keep primary structure away from the exhaust gases.

### Step 5.9
Obtain the necessary information on (p. 133):

1. engine geometry and clearance envelope
2. engine mounting (attachment) points
3. engine air-ducting requirements
4. engine thrust reversing requirements
5. engine exhaust system requirements
6. engine accessory requirements
7. engine c.g. location
8. engine firewall requirements
9. for a propeller/pusher installation, verify that the propeller thrust bearings suit a
   pusher installation
10. engine inlet requirements, which can control the layout where long inlets are
    necessary, as in many "buried" installations
11. for supersonic airplanes, a variable geometry inlet duct is often required

Items 1–9 normally come directly from the engine manufacturer.

### Step 5.10
Make dimensioned drawings of all engine installations. The drawings must identify the
engine envelope, the nacelle envelope and any necessary inlet ducts.

### Step 5.11
Make certain the proposed installations satisfy (p. 134):

1. acceptable FOD characteristics
2. geometric clearance when static on the ramp: no nacelle or propeller tip may touch the
   ground with deflated landing gear struts and tires
3. geometric clearance during take-off rotation: no scraping of nacelles or propeller
   tips, with deflated landing gear struts and tires
4. geometric clearance during a low speed approach with a **five degree bank angle**
5. no gun exhaust gases may enter the inlet of a jet engine; gun exhaust gases are highly
   corrosive to fan, compressor and turbine blades

### Step 5.12
Draw the engine installation in the threeview. The detail depends on the type of
threeview.

### Step 5.13
Document the decisions of Steps 5.1 through 5.11 in a brief descriptive report, with
clear dimensioned drawings.

---

## 5.4 Example Applications

- 5.4.1 Twin engine propeller driven airplane: **Selene**
- 5.4.2 Jet transport: **Ourania**
- 5.4.3 Fighter: **Eris**

### 5.4.1 Twin Engine Propeller Driven Airplane (Selene)

- **Step 5.1.** Table 2.17 of Part I specifies two piston engine/propeller combinations.
- **Step 5.2.** Figure 5.2 gives the preliminary speed-altitude envelope (data from Part I).
- **Step 5.3.** Comparison with Figure 5.1 shows the piston/propeller combination is
  acceptable.
- **Step 5.4.** `P_TO` = **898 hp** (matching results of p. 178, Part I).
- **Step 5.5.** Two engines were specified, so 898/2 = **449 hp** per engine is necessary.
  Candidate engines from Ref. 8 (1983–84):
  1. AVCO-Lycoming TIGO-541-E1A: **425 max hp** from sea level to 15,000 ft
     (supercharged), dry weight **700 lb**.
  2. Teledyne-Continental GTSIO-520-F,K: **435 max hp** from sea level to 11,000 ft
     (supercharged), dry weight **502 lb**.
  The AVCO-Lycoming engine was chosen. It is 24 hp short of the requirement, which is
  inside the accuracy of the Part I sizing.
- **Step 5.6.** Three blades per propeller are normal for twins, so `n_p` = **3**. Blade
  power loading `P_bl` = **3.0** hp/ft² was selected. Eq. (5.1) then gives
  `D_p` = **7.8 ft**. (Check: D_p = {4·425/(π·3·3.0)}^0.5 = 7.75 ft.)
  Note: the printed text cites "Table 5.3" for the twin-engine blade count, but the twin
  engine FAR23 data are in **Table 5.4**. Suspected misprint.
- **Step 5.7.** A pusher configuration was already selected in Step 3.5.
- **Step 5.8.** Step 3.5 decided to mount the engines in the wing, with the propellers
  behind the wing trailing edge.
- **Step 5.9.** Engine information from AVCO-Lycoming Specification No. 2397-C.
- **Step 5.10.** Figure 5.3 gives the preliminary engine installation.
- **Step 5.11.** Figure 5.3 shows requirements 2, 3 and 4 are satisfied. Requirements 1
  and 5 do not apply.
- **Step 5.12.** The threeview of Figure 13.1 shows the proposed installation.
- **Step 5.13.** Omitted to save space.

### 5.4.2 Jet Transport (Ourania)

- **Step 5.1.** Table 2.18 of Part I specifies two turbofan engines.
- **Step 5.2.** Figure 5.4 gives the preliminary speed-altitude envelope.
- **Step 5.3.** Comparison with Figure 5.1 shows the turbofan is appropriate.
- **Step 5.4.** `T_TO` = **47,625 lb** (matching results, pp. 183–184 of Part I).
- **Step 5.5.** Two engines, so **23,813 lb** thrust per engine. Ref. 8 (1983–84) shows the
  **CFM56-2** turbofan is the only engine that satisfies this: `T_max` = **24,000 lb**,
  dry weight **4,612 lb**.
- **Step 5.6.** Not applicable.
- **Step 5.7.** The engines are mounted under the wing, forward of the c.g. This makes the
  airplane a tractor.
- **Step 5.8.** See Step 5.7.
- **Step 5.9.** Engine envelope information from Ref. 8 (1983–84).
- **Step 5.10.** Figure 5.5 gives the proposed installation.
- **Step 5.11.** For FOD, the installation is very similar to the Boeing 737-300, which
  satisfies FOD requirements, so the same is assumed for the Ourania. Figure 5.5 shows
  requirements 2–4 are satisfied. Requirement 5 does not apply.
- **Step 5.12.** Figure 13.2 shows the installation in the threeview.
- **Step 5.13.** Omitted to save space.

### 5.4.3 Fighter (Eris)

- **Step 5.1.** Table 2.19 of Part I specifies two turbofans.
- **Step 5.2.** Figure 5.6 gives the preliminary speed-altitude envelope.
- **Step 5.3.** Comparison with Figure 5.1 shows turbofans are appropriate.
- **Step 5.4.** `T_TO` = **29,670 lb** (matching results, pp. 190–191 of Part I).
- **Step 5.5.** Two engines, so maximum rated thrust per engine = **14,835 lb**. Candidates
  from Ref. 8 (1983–84):
  1. Pratt and Whitney JT3D (TF33): `T_max` = **18,000 lb** dry, `W_dry` = **4,340 lb**.
  2. Pratt and Whitney JTF22 (F100): `T_max` = **14,670 lb** dry, `W_dry` = **3,033 lb**.
  3. General Electric **F404**: `T_max` = **16,000 lb** in afterburner, `W_dry` =
     **2,000 lb**.
  The F404 was selected: it is relatively light and is in operational use on the F17, F18
  and X29.
- **Step 5.6.** Not applicable.
- **Step 5.7.** Step 3.5 (p. 106) decided the engines go in the fuselage, as in the DH110.
  The inlets are ahead of the c.g., so the Eris is a tractor.
- **Step 5.8.** See Step 5.7.
- **Step 5.9.** The geometric envelope of the F404 came from Ref. 8 (1983–84).
- **Step 5.10.** Figure 4.9 (p. 122) shows the proposed installation.
- **Step 5.11.** The Eris is similar to the DH110 (p. 106), so requirement 1 is assumed
  satisfied. Figure 4.9 shows requirements 2–4 are satisfied. For requirement 5, a gun-gas
  deflector plate is installed on the fuselage nose (shown in Figure 4.9).
- **Step 5.12.** Figure 13.3 shows the installation in a threeview.
- **Step 5.13.** Omitted to save space.

### Figure 5.2 — Selene: Preliminary Speed-Altitude Envelope
*[Roskam Part II, Fig. 5.2, p. 136]* — Altitude (ft, 0 to 20,000) vs. Mach number (0 to
0.4). Printed points and labels (read from plot): **T.O.** at sea level, about M 0.12;
**CLEAN** at sea level, about M 0.14; a dashed boundary rising from the clean sea-level
point to about M 0.17 at 20,000 ft; a separate short dashed line at the right labelled
**CRUISE 250 KTS**, at about M 0.39 and 6,000–9,000 ft.

### Figure 5.3 — Selene: Preliminary Engine Installation
*[Roskam Part II, Fig. 5.3, p. 136]* — Side view of the wing-mounted pusher engine with
the engine envelope and the propeller centerline, plus the rear-fuselage/ground clearance
check. Printed values: propeller diameter **7.8 ft**; ground clearance angle at the
rear fuselage **16 deg**, drawn for both a **compressed** and an **extended** landing
gear strut. Layout drawing; no other plotted data.

### Figure 5.4 — Ourania: Preliminary Speed-Altitude Envelope
*[Roskam Part II, Fig. 5.4, p. 136]* — Altitude (ft × 10⁻³, 0 to 40) vs. Mach number
(0 to 1.0). Printed points and labels (read from plot): **T.O.** at sea level, about
M 0.19; **CLEAN** at sea level, about M 0.22; the dashed climb boundary rises to about
M 0.30 at 22,000 ft; a separate dashed line labelled **CRUISE M = .82, 35,000 FT**.

### Figure 5.5 — Ourania: Preliminary Engine Installation
*[Roskam Part II, Fig. 5.5, p. 139]* — Plan view and front/side view of the under-wing
nacelle. Labels: engine envelope, wing chord at nacelle, wing airfoil at nacelle, and the
ground clearance check with the tire drawn **deflected** and **static**. No printed
dimensions on the figure.

### Figure 5.6 — Eris: Preliminary Speed-Altitude Envelope
*[Roskam Part II, Fig. 5.6, p. 139]* — Altitude (ft × 10⁻³, 0 to 40) vs. Mach number
(0 to 1.0). Two boundaries are drawn, **WITH STORES** and **CLEAN**. Printed points
(read from plot): **T.O.** at sea level, about M 0.15; sea-level **WITH STORES** about
M 0.60 and sea-level **CLEAN** about M 0.68; at 40,000 ft, **WITH STORES** about M 0.82
and **CLEAN** about M 0.87. A third short dashed line runs from the T.O. point up to
about M 0.20 at 16,000 ft.
