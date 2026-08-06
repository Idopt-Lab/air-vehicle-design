# Chapter 20 — Refined Weight Estimate

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, AIAA Education
Series, 2010. Chapter 20, printed pp. 551–574 (PDF pp. 560–583).

Text-layer inventory (regex scan, PDF pp. 560–583): Figs 20.1–20.2, Table 20.1, Eqs (20.1a)–(20.81)
(83 equations — a dense weight-estimation-equation chapter with comparatively few figures/tables).

Note on pagination: for this chapter the PDF-to-printed page offset shifts from the +10 pattern seen in
Chapters 15–19 to **+9** (PDF page = printed page + 9), confirmed at the Chapter 20 opener (PDF 560 =
printed 551) and the Chapter 21 opener (PDF 584 = printed 575).

## Chapter Opener (p. 551)

Photo: a twin-boom, canard, tandem-engine aircraft (the Rutan Voyager) resting on grass, registration
N269VA visible on the boom. Section-list sidebar: Military, Commercial, & GA WERs; Adjustment for Advanced
Composites; Low Wing Loading ($W/S < 5$); Locating the C.G.; Estimating Moments of Inertia. Sidebar note:
"Estimating weights is critical in the design of an aircraft. This is especially true for weight-critical
aircraft such as the Voyager designed by Burt Rutan (Scaled Composite Inc). Learn more about this aircraft
in Section 20.2.4." Epigraph: "Estimating the weight of an airplane or airship involves as much art as it
does science." Copyright notice: © 2010 American Institute of Aeronautics and Astronautics.

## §20.1 Introduction (p. 552)

At this point the designer should do a detailed weight estimate of the aircraft. The original estimate of
the aircraft empty weight (from Chapter 5) used the impersonal empty-weight trend curves of Appendix I. As
such they were not able to capture the unique and innovative features of the conceptual aircraft. However,
they were appropriate for that point in the design cycle when the aircraft information was sparse. Now
there is considerable information available on the aircraft and the weights of all the aircraft components
can be estimated to get a refined empty weight and center of gravity location. Component weights are
determined in large part through the use of empirical formulations that are conditioned upon the many
different geometric properties of the components. A multiple regression analysis is used to determine the
best curve-fit expression for the historical data.

The designer must be careful when applying these weight-estimate equations to new designs. If the new
aircraft will be considerably different in performance and/or structural design than the aircraft used to
develop the weight-estimate equations, then the weight equations might have to be altered. Weight-
estimation methods for advanced systems are guarded very closely by aircraft companies as they represent
their expertise in the design of advanced systems. The Aeronautical Systems Center at Wright-Patterson AFB,
Ohio, served as a clearinghouse for the exchange of weights information in the 1960s and 1970s, hosting
weight-prediction workshops. Currently, NAVAIR at Patuxent River, Maryland, serves as the government
clearinghouse. The Society of Allied Weight Engineers (SAWE) also promotes the exchange of
weight-estimating information.

The weight-estimating equations contained in this chapter have come from many sources. It is recommended
that the equations be calibrated case-by-case, by comparing the estimated weights with real aircraft
(Appendix I) and other sources (see [1-6]).

As discussed in Appendix I, estimating the empty weight of an aircraft is the most challenging part of the
conceptual design process. Historical data are available to make credible weight estimates (estimating
weight at the conceptual design level is an art and it will never be a science). Most design groups carry
a weight margin through conceptual and preliminary design to account for the uncertainty in the weight
estimates and the inevitable and dreaded "weights growth." At the Lockheed Martin Skunk Works the margin on
empty weight is 6%.

## §20.2 Weight-Estimation Methods (p. 553)

### §20.2.1 Conventional Metal Aircraft—Moderate Subsonic to Supersonic Performance

Credit for the following weight-estimation methods for conventional metal aircraft goes to many sources in
the aerospace industry. The weight equations give the component weight in pounds.

#### §20.2.1.1 Structure

**Wing**

U.S. Air Force (USAF) Fighter Aircraft:

$$\text{Wt} = 3.08\left(\frac{K_{PIV}\,N\,W_{TO}}{t/c}\left\{\left[\tan\Lambda_{LE} -
\frac{2(1-\lambda)}{\text{AR}(1+\lambda)}\right]^2+1.0\right\}\times10^{-6}\right)^{0.593}
\left[(1+\lambda)\text{AR}\right]^{0.89}S_w^{0.741} \tag{20.1a}$$
*[Nicolai & Carichner, Eq. (20.1a), p. 553]*

U.S. Navy (USN) Fighter Aircraft:

$$\text{Wt} = 19.29\left(\frac{K_{PIV}\,N\,W_{TO}}{t/c}\left\{\left[\tan\Lambda_{LE} -
\frac{2(1-\lambda)}{\text{AR}(1+\lambda)}\right]^2+1.0\right\}\times10^{-6}\right)^{0.464}
\left[(1+\lambda)\text{AR}\right]^{0.70}S_w^{0.58} \tag{20.1b}$$
*[Nicolai & Carichner, Eq. (20.1b), p. 553]*

where:
- $K_{PIV}$ = wing variable-sweep structural factor = 1.00 for fixed wings, = 1.175 for variable-sweep wings
- $t/c$ = maximum thickness ratio
- $W_{TO}$ = takeoff weight, in pounds (lb)
- $\Lambda_{LE}$ = leading edge sweep
- $\lambda$ = taper ratio
- AR = wing aspect ratio
- $S_w$ = wing area, in square feet (ft²)
- $N$ = ultimate load factor = 13.5 for fighter aircraft (based on a design limit load factor of +9.0 and a
  margin of safety of 1.5); = 4.5 for bomber and transport aircraft (based on a design limit load factor of
  +3.0)

Subsonic Aircraft (Military and Commercial):

$$\text{Wt} = 0.00428(S_w)^{0.48}\frac{\text{AR}^{1.0}(M_0)^{0.43}}{(100\,t/c)^{0.76}}
\frac{(W_{TO}\,N)^{0.84}(\lambda)^{0.14}}{(\cos\Lambda_{1/2})^{1.54}} \tag{20.2}$$
*[Nicolai & Carichner, Eq. (20.2), p. 554]*

where $M_0$ = maximum Mach number at sea level; $\Lambda_{1/2}$ = sweep of half-chord; $t/c$ = maximum
thickness ratio. This wing weight equation is valid for an $M_0$ range of 0.4-0.8, a $t/c$ range of
0.08-0.15, and an aspect ratio (AR) range of 4-12.

**Horizontal and Vertical Tail**

Horizontal Tail:

$$\text{Wt} = 0.0034\,\gamma^{0.915} \tag{20.3a}$$
*[Nicolai & Carichner, Eq. (20.3a), p. 554]*

where $\gamma = (W_{TO}N)^{0.813}(S_{HT})^{0.584}(b_{HT}/t_{R_{HT}})^{0.033}(\bar{c}_{wing}/L_t)^{0.28}$;
$N$ = ultimate load factor; $S_{HT}$ = horizontal tail total planform area (include fuselage
carry-through), in square feet (ft²); $t_{R_{HT}}$ = thickness of the horizontal tail at the root, in feet;
$\bar{c}_{wing}$ = mac of the wing, in feet; $L_t$ = tail moment arm, in feet — distance from one-fourth
wing mac to one-fourth tail mac (for canard surfaces, use distance from 0.4 wing mac to one-fourth canard
mac); $b_{HT}$ = span of horizontal tail, in feet.

Vertical Tail:

$$\text{Wt} = 0.19\,\gamma^{1.014} \tag{20.3b}$$
*[Nicolai & Carichner, Eq. (20.3b), p. 554]*

where
$\gamma = (1+h_T/h_V)^{0.5}(W_{TO}N)^{0.363}(S_{VT})^{1.089}M_0^{0.601}(L_t)^{-0.726}(1+S_r/S_{VT})^{0.217}
\times(\text{AR}_{VT})^{0.337}(1+\lambda_V)^{0.363}(\cos\Lambda_{VT})^{-0.484}$

$h_T/h_V$ = ratio of horizontal tail height to vertical tail height. For a "T" tail this ratio is 1.0; for
a fuselage-mounted horizontal tail this ratio is 0
; $S_{VT}$ = area of vertical tail, in square feet (ft²); $M_0$ = maximum Mach number at sea level; $L_t$ =
tail moment arm, in feet (one-fourth wing mac to one-fourth tail mac); $S_r$ = rudder area, in square feet
(if unknown, use $S_r/S_V=0.3$); $\text{AR}_{VT}$ = aspect ratio of vertical tail; $\lambda_V$ = taper ratio
of vertical tail; $\Lambda_{VT}$ = sweep of vertical tail quarter-chord.

**Fuselage**

USAF and Commercial:

$$\text{Wt} = 10.43\,(K_{INL})^{1.42}(q\times10^{-2})^{0.283}(W_{TO}\times10^{-3})^{0.95}(L/H)^{0.71}
\tag{20.4}$$
*[Nicolai & Carichner, Eq. (20.4), p. 555]*

USN:

$$\text{Wt} = 11.03\,(K_{INL})^{1.23}(q\times10^{-2})^{0.245}(W_{TO}\times10^{-3})^{0.98}(L/H)^{0.61}
\tag{20.5}$$
*[Nicolai & Carichner, Eq. (20.5), p. 555]*

where $q$ = maximum dynamic pressure, in pounds per square foot (lb/ft²); $L$ = fuselage length, in feet
(ft); $H$ = maximum fuselage height, in feet; $K_{INL}$ = 1.25 for inlets on fuselage, = 1.0 for inlets in
wing root or elsewhere.

**Landing Gear**

USAF and Commercial:

$$\text{Wt} = 62.21\,(W_{TO}\times10^{-3})^{0.84} \tag{20.6}$$
*[Nicolai & Carichner, Eq. (20.6), p. 555]*

USN:

$$\text{Wt} = 129.1\,(W_{TO}\times10^{-3})^{0.66} \tag{20.7}$$
*[Nicolai & Carichner, Eq. (20.7), p. 555]*

#### §20.2.1.2 Propulsion

**Engine**

Engine weights should be based upon the engine manufacturer's data and scaling factors. Assume the exhaust,
cooling, turbo-supercharger, and lubrication systems weights are included in the engine weight.

**Propulsion Subsystems**

Propulsion subsystem items are the air induction system, fuel system, engine controls, and starting system.

**Air Induction System**

The parameters used in determining air induction system weights: $A_i$ = capture area per inlet, in square
feet (ft²); $N_i$ = number of inlets, vehicle configuration; $L_d$ = subsonic duct length, per inlet, in
feet (ft); $L_r$ = ramp length forward of throat, per inlet, in feet; $K_{GEO}$ = duct shape factor (use
$K=1.33$ if duct has two or more relatively flat sides; use $K=1.0$ if duct is round or has one flat side);
$P_2$ = maximum static pressure at engine compressor face, in pounds per square inch absolute (psia);
$K_{TE}$ = temperature correction factor (= 1 for $M_D<3.0$; $=(M_D+2)/5$ for $M_D$ between 3.0 and 6.0,
where design Mach number $M_D$ is the maximum Mach number); $K_M$ = duct material factor (use $K=1.0$ for
$M_D<1.4$; use $K=1.5$ for $M_D\geq1.4$).

Duct Provisions:

$$\text{Wt} = 0.32\,(N_i)(L_d)(A_i)^{0.65}(P2)^{0.6} \tag{20.8}$$
*[Nicolai & Carichner, Eq. (20.8), p. 556]*

This equation accounts for the duct support structure and should only be used for internal installations.
Duct provisions are normally included with the weight, but they have been separated out for this discussion
to complete the total air-induction system weight.

Internal Duct Weight:

$$\text{Wt} = 1.735\left[(N_i)(L_d)(A_i)^{0.5}(P_2)(K_{GEO})(K_M)\right]^{0.7331} \tag{20.9}$$
*[Nicolai & Carichner, Eq. (20.9), p. 556]*

This equation accounts for the duct structure from the inlet lip to the engine compressor face, and it
should only be used for internal engine installations.

Variable-Geometry Ramps, Actuators, and Control Weights:

$$\text{Wt} = 4.079\left[(N_i)(L_r)(A_i)^{0.5}(K_{TE})\right]^{1.201} \tag{20.10}$$
*[Nicolai & Carichner, Eq. (20.10), p. 556]*

This equation should only be used for internal installations. Variable-geometry ramps are normally used
with rectangular inlets.

Half-Round Fixed Spike Weight:

$$W_{HFS} = 12.53\,(N_i)(A_i) \tag{20.11}$$
*[Nicolai & Carichner, Eq. (20.11), p. 557]*

This equation should only be used for internal installations.

Full-Round Translating Spike Weight:

$$\text{Wt} = 15.65\,(N_i)(A_i) \tag{20.12}$$
*[Nicolai & Carichner, Eq. (20.12), p. 557]*

This equation can be used for either internal or external (podded) engine installations.

Translating and Expanding Spike Weight:

$$W_{TES} = 51.8\,(N_i)(A_i) \tag{20.13}$$
*[Nicolai & Carichner, Eq. (20.13), p. 557]*

This equation can be used for either internal or external engine installations.

External Turbojet Cowl and Duct Weight:

$$\text{Wt} = 3.00\,(N_i)\left[(A_i)^{0.5}(L_d)(P_2)\right]^{0.731} \tag{20.14}$$
*[Nicolai & Carichner, Eq. (20.14), p. 557]*

This equation accounts for the exterior cowl or cover panels, ducting, and substructure such as rings,
frames, stiffeners, and longerons, from the inlet lip to the engine compressor face, and should only be
used for external engine installations.

External Turbofan Cowl and Duct Weight:

$$W_{DTF} = 7.435\,(N_i)\left[(L_d)(A_i)^{0.5}(P_2)\right]^{0.731} \tag{20.15}$$
*[Nicolai & Carichner, Eq. (20.15), p. 557]*

This equation accounts for cowl panels, substructure, and the basic engine duct and the fan duct, and it
should only be used for external engine installations.

**Fuel System**

Self-Sealing Bladder Cells:

$$\text{Wt} = 41.6\left[(F_{GW}+F_{GF})\times10^{-2}\right]^{0.818} \tag{20.16}$$
*[Nicolai & Carichner, Eq. (20.16), p. 557]*

where $F_{GW}$ = total wing fuel in gallons and $F_{GF}$ = total fuselage fuel in gallons.

Non-Self-Sealing Bladder Cells:

$$\text{Wt} = 23.10\left[(F_{GW}+F_{GF})\times10^{-2}\right]^{0.758} \tag{20.17}$$
*[Nicolai & Carichner, Eq. (20.17), p. 558]*

Fuel System Bladder Cell Backing and Supports (Both Self-Sealing and Non-Self-Sealing):

$$\text{Wt} = 7.91\left[(F_{GW}+F_{GF})\times10^{-2}\right]^{0.854} \tag{20.18}$$
*[Nicolai & Carichner, Eq. (20.18), p. 558]*

In-Flight Refuel System:

$$\text{Wt} = 13.64\left[(F_{GW}+F_{GF})\times10^{-2}\right]^{0.392} \tag{20.19}$$
*[Nicolai & Carichner, Eq. (20.19), p. 558]*

Dump-and-Drain System:

$$\text{Wt} = 7.38\left[(F_{GW}+F_{GF})\times10^{-2}\right]^{0.458} \tag{20.20}$$
*[Nicolai & Carichner, Eq. (20.20), p. 558]*

C.G. Control System (Transfer Pumps and Monitor):

$$\text{Wt} = 28.38\left[(F_{GW}+F_{GF})\times10^{-2}\right]^{0.442} \tag{20.21}$$
*[Nicolai & Carichner, Eq. (20.21), p. 558]*

**Engine Controls**

Body- or Wing-Root-Mounted Jet:

$$\text{Wt} = K_{ECO}(L_f N_E)^{0.792} \tag{20.22}$$
*[Nicolai & Carichner, Eq. (20.22), p. 558]*

where $L_f$ = fuselage length, in feet (ft); $N_E$ = number of engines (per airplane); $K_{ECO}$ = engine
control engine-type coefficient = 0.686, nonafterburning engines; = 1.080, afterburning (A/B) engines.

Wing-Mounted Turbojet and Turbofan:

$$\text{Wt} = 88.46\left[(L_f+b)N_E\times10^{-2}\right]^{0.294} \tag{20.23}$$
*[Nicolai & Carichner, Eq. (20.23), p. 558]*

Wing-Mounted Turboprop:

$$\text{Wt} = 56.84\left[(L_f+b)N_E\times10^{-2}\right]^{0.514} \tag{20.24}$$
*[Nicolai & Carichner, Eq. (20.24), p. 558]*

Wing-Mounted Reciprocating:

$$\text{Wt} = 60.27\left[(L_f+b)N_E\times10^{-2}\right]^{0.724} \tag{20.25}$$
*[Nicolai & Carichner, Eq. (20.25), p. 559]*

where $b$ = wing span, in feet.

**Starting Systems**

One or Two Jet Engines—Cartridge and Pneumatic:

$$\text{Wt} = 9.33\,(N_E W_{ENG}\times10^{-3})^{1.078} \tag{20.26}$$
*[Nicolai & Carichner, Eq. (20.26), p. 559]*

where $N_E$ = number of engines per airplane, and $W_{ENG}$ = engine weight, in pounds per engine.

One or Two Jet Engines—Electrical:

$$\text{Wt} = 38.93\,(N_E W_{ENG}\times10^{-3})^{0.918} \tag{20.27}$$
*[Nicolai & Carichner, Eq. (20.27), p. 559]*

Four or More Jet Engines—Pneumatic:

$$\text{Wt} = 49.19\,(N_E W_{ENG}\times10^{-3})^{0.541} \tag{20.28}$$
*[Nicolai & Carichner, Eq. (20.28), p. 559]*

Turboprop Engines—Pneumatic:

$$\text{Wt} = 12.05\,(N_E W_{ENG}\times10^{-3})^{1.458} \tag{20.29}$$
*[Nicolai & Carichner, Eq. (20.29), p. 559]*

Reciprocating Engines—Electric:

$$\text{Wt} = 50.38\,(N_E W_{ENG}\times10^{-3})^{0.459} \tag{20.30}$$
*[Nicolai & Carichner, Eq. (20.30), p. 559]*

**Propeller Systems**

Propellers:

$$\text{Wt} = K_p N_p (N_{BL})^{0.391}(d_p\times\text{HP}\times10^{-3})^{0.782} \tag{20.31}$$
*[Nicolai & Carichner, Eq. (20.31), p. 559]*

where $N_p$ = number of propellers per airplane; $N_{BL}$ = number of blades per propeller; $d_p$ =
propeller diameter, in feet per propeller; HP = rated engine shaft horsepower; $K_p$ = propeller-engine
coefficient = 24.00 for turboprop above 1500 shaft horsepower; = 31.92 for reciprocating engine at all
horsepower and turboprop below 1500 shaft horsepower.

Propeller Controls—Turboprop Engines:

$$\text{Wt} = 0.322\,(N_{BL})^{0.589}(N_p d_p\,\text{HP}\times10^{-3})^{1.178} \tag{20.32}$$
*[Nicolai & Carichner, Eq. (20.32), p. 560]*

Propeller Controls—Reciprocating Engines:

$$\text{Wt} = 4.552\,(N_{BL})^{0.379}(N_p d_p\,\text{HP}\times10^{-3})^{0.759} \tag{20.33}$$
*[Nicolai & Carichner, Eq. (20.33), p. 560]*

#### §20.2.1.3 Surface Controls Plus Hydraulics and Pneumatics

Fighters—USAF:

$$\text{Wt} = K_{SC}(W_{TO}\times10^{-3})^{0.581} \tag{20.34}$$
*[Nicolai & Carichner, Eq. (20.34), p. 560]*

where $K_{SC}$ = surface control coefficient = 106.10 for elevon without horizontal tail; = 138.18 for
horizontal tail; = 167.48 for variable-sweep wing.

Fighter and Attack—USN:

$$\text{Wt} = 23.77\,(W_{TO}\times10^{-3})^{1.10} \tag{20.35}$$
*[Nicolai & Carichner, Eq. (20.35), p. 560]*

Executive and Commercial Passenger Transports:

$$\text{Wt} = 56.01\,(W_{TO}\times q\times10^{-5})^{0.576} \tag{20.36}$$
*[Nicolai & Carichner, Eq. (20.36), p. 560]*

where $q$ = maximum dynamic pressure, in pounds per square foot (lb/ft²).

Commercial and Military Cargo-Troop Transports:

$$\text{Wt} = 15.96\,(W_{TO}\times q\times10^{-5})^{0.815} \tag{20.37}$$
*[Nicolai & Carichner, Eq. (20.37), p. 560]*

Bombers:

$$\text{Wt} = 1.049\,(S_{TOT}\times q\times10^{-3})^{1.21} \tag{20.38}$$
*[Nicolai & Carichner, Eq. (20.38), p. 560]*

where $S_{TOT}$ = total surface control area, in square feet (ft²).

#### §20.2.1.4 Instruments

**Flight Instrument Indicators**

$$\text{Wt} = N_{PIL}\left[15.0+0.032(W_{TO}\times10^{-3})\right] \tag{20.39}$$
*[Nicolai & Carichner, Eq. (20.39), p. 561]*

where $N_{PIL}$ = number of pilots.

**Engine Instrument Indicators**

Turbine Engines:

$$\text{Wt} = N_E\left[4.80+0.006(W_{TO}\times10^{-3})\right] \tag{20.40}$$
*[Nicolai & Carichner, Eq. (20.40), p. 561]*

where $N_E$ = number of engines.

Reciprocating Engines:

$$\text{Wt} = N_E\left[7.40+0.046(W_{TO}\times10^{-3})\right] \tag{20.41}$$
*[Nicolai & Carichner, Eq. (20.41), p. 561]*

Miscellaneous Indicators:

$$\text{Wt} = 0.15(W_{TO}\times10^{-3}) \tag{20.42}$$
*[Nicolai & Carichner, Eq. (20.42), p. 561]*

#### §20.2.1.5 Electrical System

The weight prediction relationships are expressed in terms of the total weight of the fuel system plus the
total weight of the electronics system, the prime users of electrical power on most aircraft.

USAF Fighters:

$$\text{Wt} = 426.17\left[(W_{FS}\times W_{TRON})\times10^{-3}\right]^{0.510} \tag{20.43}$$
*[Nicolai & Carichner, Eq. (20.43), p. 561]*

where $W_{FS}$ = weight of fuel system, in pounds (lb); $W_{TRON}$ = weight of electronics system, in
pounds (lb).

USN Fighters and Attack:

$$\text{Wt} = 346.98\left[(W_{FS}\times W_{TRON})\times10^{-3}\right]^{0.509} \tag{20.44}$$
*[Nicolai & Carichner, Eq. (20.44), p. 561]*

Bombers:

$$\text{Wt} = 185.46\left[(W_{FS}\times W_{TRON})\times10^{-3}\right]^{1.286} \tag{20.45}$$
*[Nicolai & Carichner, Eq. (20.45), p. 561]*

Transports:

$$\text{Wt} = 1162.66\left[(W_{FS}\times W_{TRON})\times10^{-3}\right]^{0.506} \tag{20.46}$$
*[Nicolai & Carichner, Eq. (20.46), p. 562]*

#### §20.2.1.6 Furnishings

**Fighter and Attack Aircraft**

Ejection Seats:

$$\text{Wt} = 22.89\,(N_{CR}\times q\times10^{-2})^{0.743} \tag{20.47}$$
*[Nicolai & Carichner, Eq. (20.47), p. 562]*

where $N_{CR}$ = number of crew; $q$ = maximum dynamic pressure, in pounds per square foot (lb/ft²).

Miscellaneous and Emergency Equipment:

$$\text{Wt} = 106.61\,(N_{CR}W_{TO}\times10^{-5})^{0.585} \tag{20.48}$$
*[Nicolai & Carichner, Eq. (20.48), p. 562]*

**Bomber and Observation Aircraft**

Seats:

*Fixed*: $\text{Wt} = 83.23\,(N_{CR})^{0.726}$ *[Eq. (20.49), p. 562]*

*Ejection*: $\text{Wt} = K_{SEA}(N_{CR})^{1.20}$ *[Eq. (20.50), p. 562]*

where $K_{SEA}$ = ejection seat coefficient = 149.12 with survival kit; = 99.54 without survival kit.

Oxygen System:

$$\text{Wt} = 16.89\,(N_{CR})^{1.494} \tag{20.51}$$
*[Nicolai & Carichner, Eq. (20.51), p. 562]*

Crew Bunks:

$$\text{Wt} = 12.18\,(N_{BU})^{1.085} \tag{20.52}$$
*[Nicolai & Carichner, Eq. (20.52), p. 562]*

where $N_{BU}$ = number of crew bunks.

**Transport Aircraft**

Flight Deck Seats—Executive and Commercial:

$$\text{Wt} = 54.99\,(N_{FDS}) \tag{20.53}$$
*[Nicolai & Carichner, Eq. (20.53), p. 562]*

where $N_{FDS}$ = number of flight deck stations.

Passenger Seats—Executive and Commercial:

$$\text{Wt} = 32.03\,(N_{PASS}) \tag{20.54}$$
*[Nicolai & Carichner, Eq. (20.54), p. 563]*

where $N_{PASS}$ = number of passengers.

Troop Seats—Troop Transports:

$$\text{Wt} = 11.17\,(N_{TRO}) \tag{20.55}$$
*[Nicolai & Carichner, Eq. (20.55), p. 563]*

where $N_{TRO}$ = number of troops.

Lavatories and Water Provisions—Executive and Commercial:

$$\text{Wt} = K_{LAV}(N_{PASS})^{1.33} \tag{20.56}$$
*[Nicolai & Carichner, Eq. (20.56), p. 563]*

where $K_{LAV}$ = 3.90 for executive; = 1.11 for long-range commercial passenger; = 0.31 for short-range
commercial passenger.

Lavatories and Water Provisions—Military Transport:

$$\text{Wt} = 1.11\,(N_{PASS})^{1.33} \tag{20.57}$$
*[Nicolai & Carichner, Eq. (20.57), p. 563]*

Food Provisions—Executive and Commercial:

$$\text{Wt} = K_{BUF}(N_{PASS})^{1.12} \tag{20.58}$$
*[Nicolai & Carichner, Eq. (20.58), p. 563]*

where $K_{BUF}$ = 5.68 for long-range (707, 990, 737, 747, 757, 767, 777, etc.); = 1.02 for short-range
(340, 202, Citation, Learjet, King Air, Jetstream, etc.).

Oxygen System:

$$\text{Wt} = 7.00\,(N_{CR}+N_{PASS}+N_{ATT})^{0.702} \tag{20.59}$$
*[Nicolai & Carichner, Eq. (20.59), p. 563]*

where $N_{ATT}$ = number of attendants.

Cabin Windows—Executive and Commercial:

$$\text{Wt} = 109.33\left[N_{PASS}(1+P_C)\times10^{-2}\right]^{0.505} \tag{20.60}$$
*[Nicolai & Carichner, Eq. (20.60), p. 563]*

where $P_C$ = ultimate cabin pressure, in pounds per square inch (lb/in²).

Baggage and Cargo Handling Provisions:

$$\text{Wt} = K_{CBC}(N_{PASS})^{1.456} \tag{20.61}$$
*[Nicolai & Carichner, Eq. (20.61), p. 564]*

where $K_{CBC}$ = 0.0646 without preload provisions; = 0.316 with preload provisions.

**Miscellaneous Furnishings and Equipment**

Executive and Commercial:

$$\text{Wt} = 0.771\,(W_{TO}\times10^{-3}) \tag{20.62}$$
*[Nicolai & Carichner, Eq. (20.62), p. 564]*

Military Passenger:

$$\text{Wt} = 0.771\,(W_{TO}\times10^{-3}) \tag{20.63}$$
*[Nicolai & Carichner, Eq. (20.63), p. 564]*

Military Troop-Cargo:

$$\text{Wt} = 0.618\,(W_{TO}\times10^{-3})^{0.839} \tag{20.64}$$
*[Nicolai & Carichner, Eq. (20.64), p. 564]*

#### §20.2.1.7 Air Conditioning and Anti-Icing

**Fighters**

High Subsonic and Supersonic:

$$\text{Wt} = 210.66\left[(W_{TRON}\times200\,N_{CR})\times10^{-3}\right]^{0.735} \tag{20.65}$$
*[Nicolai & Carichner, Eq. (20.65), p. 564]*

where $W_{TRON}$ = weight of electronics system, in pounds (lb); $N_{CR}$ = number of crew.

Subsonic (Below Approximately M = 0.50):

$$\text{Wt} = K_{ACAI}\left[(W_{TRON}\times200\,N_{CR})\times10^{-3}\right]^{0.538} \tag{20.66}$$
*[Nicolai & Carichner, Eq. (20.66), p. 564]*

where $K_{ACAI}$ = air conditioning and anti-icing coefficient = 108.64, no wing or tail anti-icing;
= 212.00, wing and tail anti-icing.

**Bombers and Military Troop-Cargo-Passenger Transports**

$$\text{Wt} = K_{ACAI}\left[V_{PR}\times10^{-2}\right]^{0.242} \tag{20.67}$$
*[Nicolai & Carichner, Eq. (20.67), p. 564]*

where $V_{PR}$ = pressurized or occupied volume, in cubic feet (ft³); $K_{ACAI}$ = air conditioning and
anti-ice coefficient = 887.25, bomber and military transport with wing and tail anti-icing; = 748.15,
bomber and military transport without wing and tail anti-icing, supersonic to $M=2.50$; = 610.56, bomber
and military transport without wing or tail anti-icing, subsonic.

**Executive and Commercial Passenger-Cargo Transports**

$$\text{Wt} = 469.30\left[V_{PR}(N_{CR}+N_{ATT}+N_{PASS})\times10^{-4}\right]^{0.419} \tag{20.68}$$
*[Nicolai & Carichner, Eq. (20.68), p. 565]*

where $V_{PR}$ = pressurized or occupied volume, in cubic feet (ft³); $N_{ATT}$ = number of attendants;
$N_{PASS}$ = number of passengers.

#### §20.2.1.8 Electronics (Avionics)

Usually requirements will specify the avionics gear for the aircraft. The weight of the avionics can then
be determined using Table 8.6 of Chapter 8 or manufacturer information on the particular electronics
equipment.

If the electronics gear is not specified, estimates of the weight can be made using the statistical methods
of Table 8.7.

#### §20.2.1.9 Landing Retardation Devices

The weight of landing retardation devices (brakes, thrust reversers, and drag chutes) can be determined
using the information in Chapter 10. The designer should examine the engine information to see if the
thrust reverser is included in the basic engine weight.

### §20.2.2 Conventional Metal Aircraft—Light Utility Aircraft

The weight equations of §20.2.1 predict unrealistic component weights for light utility aircraft such as
those reported in Table I.3 in Appendix I. The following equations are recommended for the low-to-moderate
performance (up to about 300 kt) light utility aircraft. The weight equations give the component weight in
pounds.

#### §20.2.2.1 Structure

**Wing**

$$\text{Wt} = 96.948\left[\left(\frac{W_{TO}N}{10^5}\right)^{0.65}\left(\frac{\text{AR}}{\cos\Lambda_{1/4}}
\right)^{0.57}\left(\frac{S_w}{100}\right)^{0.61}\left(\frac{1+\lambda}{2t/c}\right)^{0.36}
\left(1+\frac{V_e}{500}\right)^{0.5}\right]^{0.993} \tag{20.69}$$
*[Nicolai & Carichner, Eq. (20.69), p. 566]*

where $W_{TO}$ = takeoff weight, in pounds (lb); $N$ = ultimate load factor (1.5 × limit load factor); AR =
wing aspect ratio; $\Lambda_{1/4}$ = wing quarter-chord sweep; $S_w$ = wing area in square feet (ft²);
$\lambda$ = wing taper ratio; $t/c$ = maximum wing thickness ratio; $V_e$ = equivalent maximum airspeed at
sea level, in knots.

**Fuselage**

$$\text{Wt} = 200\left[\left(\frac{W_{TO}N}{10^5}\right)^{0.286}\left(\frac{L}{10}\right)^{0.857}
\left(\frac{W+D}{10}\right)\left(\frac{V_e}{100}\right)^{0.338}\right]^{1.1} \tag{20.70}$$
*[Nicolai & Carichner, Eq. (20.70), p. 566]*

where $L$ = fuselage length, in feet; $W$ = fuselage maximum width, in feet; $D$ = fuselage maximum depth,
in feet.

**Horizontal Tail**

$$\text{Wt} = 127\left[\left(\frac{W_{TO}N}{10^5}\right)^{0.87}\left(\frac{S_H}{100}\right)^{1.2}
\left(\frac{\ell_T}{10}\right)^{0.483}\left(\frac{b_H}{t_{HR}}\right)^{0.5}\right]^{0.458} \tag{20.71}$$
*[Nicolai & Carichner, Eq. (20.71), p. 566]*

where $S_H$ = horizontal tail area, in square feet (ft²); $\ell_T$ = distance from wing one-fourth mac to
tail one-fourth mac; $b_H$ = horizontal tail span, in feet; $t_{HR}$ = horizontal tail maximum root
thickness, in inches.

**Vertical Tail**

$$\text{Wt} = 98.5\left[\left(\frac{W_{TO}N}{10^5}\right)^{0.87}\left(\frac{S_V}{100}\right)^{1.2}
\left(\frac{b_V}{t_{VR}}\right)^{0.5}\right] \tag{20.72}$$
*[Nicolai & Carichner, Eq. (20.72), p. 567]*

where $S_V$ = vertical tail area, in square feet (ft²); $b_V$ = vertical tail span, in feet; $t_{VR}$ =
vertical tail maximum root thickness, in inches.

**Landing Gear**

$$\text{Wt} = 0.054\,(L_{LG})^{0.501}(W_{LAND}N_{LAND})^{0.684} \tag{20.73}$$
*[Nicolai & Carichner, Eq. (20.73), p. 567]*

where $L_{LG}$ = length of main landing gear strut, in inches; $W_{LAND}$ = landing weight (if unknown, use
$W_{TO}$ minus 60% fuel); $N_{LAND}$ = ultimate load factor at $W_{LAND}$.

#### §20.2.2.2 Propulsion

**Total Installed Propulsion Unit Weight Less Fuel System**

This includes mounting and air induction weight:

$$\text{Wt} = 2.575\,(W_{ENG})^{0.922}N_E \tag{20.74}$$
*[Nicolai & Carichner, Eq. (20.74), p. 567]*

where $W_{ENG}$ = bare engine weight; $N_E$ = number of engines.

**Fuel System**

This includes fuel pumps, lines, and tanks:

$$\text{Wt} = 2.49\left[(F_G)^{0.6}\left(\frac{1}{1+\text{Int}}\right)^{0.3}(N_T)^{0.2}(N_E)^{0.13}
\right]^{1.21} \tag{20.75}$$
*[Nicolai & Carichner, Eq. (20.75), p. 567]*

where $F_G$ = total fuel, in gallons; Int = percentage of fuel tanks that are integral; $N_T$ = number of
separate fuel tanks.

#### §20.2.2.3 Surface Controls

For powered surface control systems, use

$$\text{Wt} = 1.08\,(W_{TO})^{0.7} \tag{20.76}$$
*[Nicolai & Carichner, Eq. (20.76), p. 568]*

For unpowered surface control systems, use

$$\text{Wt} = 1.066\,(W_{TO})^{0.626} \tag{20.77}$$
*[Nicolai & Carichner, Eq. (20.77), p. 568]*

#### §20.2.2.4 Electrical System

The weight-prediction relationships are expressed in terms of the total weight of the fuel system and the
electronics system, the primary users of electrical power on the aircraft:

$$\text{Wt} = 426\left(\frac{W_{FS}+W_{TRON}}{1000}\right)^{0.51} \tag{20.78}$$
*[Nicolai & Carichner, Eq. (20.78), p. 568]*

where $W_{FS}$ = fuel system weight, in pounds, Eq. (20.75); $W_{TRON}$ = weight of installed electronics,
in pounds, Eq. (20.81).

#### §20.2.2.5 Furnishings

The weight expression for the crew seats is

$$\text{Wt} = 34.5\,(N_{CR})(q)^{0.25} \tag{20.79}$$
*[Nicolai & Carichner, Eq. (20.79), p. 568]*

where $N_{CR}$ = number of crew; $q$ = maximum dynamic pressure, in pounds per square foot (lb/ft²).

The weight of the passenger seats is determined from Eq. (20.54) and a weight allowance for miscellaneous
furnishings from Eq. (20.62). If the aircraft is pressurized, an additional weight allowance should be
considered using Eq. (20.60).

#### §20.2.2.6 Air Conditioning and Anti-Icing

If the aircraft has air conditioning and anti-icing, the following expression can be used to estimate the
weight of this equipment:

$$\text{Wt} = 0.265\,(W_{TO})^{0.52}(N_{CR}+N_{PASS})^{0.68}(W_{TRON})^{0.17}(M_E)^{0.08} \tag{20.80}$$
*[Nicolai & Carichner, Eq. (20.80), p. 568]*

where $N_{PASS}$ = number of passengers; $N_{CR}$ = number of crew; $W_{TRON}$ = weight of installed
electronics in pounds, see Eq. (20.81); $M_E$ = equivalent maximum Mach number at sea level.

#### §20.2.2.7 Electronics (Avionics)

The total installed weight of the avionics equipment is

$$W_{TRON} = 2.117\,(W_{AU})^{0.933} \tag{20.81}$$
*[Nicolai & Carichner, Eq. (20.81), p. 569]*

where $W_{AU}$ = bare avionics equipment weight (uninstalled).

### §20.2.3 Advanced-Composites Aircraft

The high strength-to-weight and stiffness-to-weight ratios associated with advanced composite materials can
significantly reduce aircraft structural weight. The blending of high-strength fibers such as graphite,
boron, Kevlar 49, and glass in epoxy, polyimide, or metallic matrices (as discussed in Chapter 19) offers
new opportunities for the creative structural engineer to tailor the material to exploit innovative
structural designs. The full potential of advanced composites in realizing structural weight reductions
(and airframe cost reductions) has not been demonstrated yet; however, there is no question that it will be
significant. The designer should review the discussion in Appendix I.

The results of many advanced composites development programs and aircraft conceptual studies indicate that
the material can decrease the weight of primary and secondary structural elements by about 25% and 40%,
respectively. The conceptual complete aircraft studies indicate that an aircraft should not be 100%
composite materials because there are many places where it is more cost effective to use metals,
honeycomb, and other materials. Some of the places where it is not cost effective or practical to use
advanced composites are canopies, tires, seats, seals, mechanisms, radomes, latches, hinges, and clamps.
The optimum composite utilization appears to be about 55% in terms of most cost and weight effectiveness.

Based upon a composite utilization by weight of about 55%, the following methodology is recommended for
estimating the aircraft component weights, at this point in the conceptual design:

1. Estimate the weight of the component using the metal weight equations of §20.2.1 or §20.2.2.
2. Reduce the metal weights by the following amounts:
   - Wing, 20%
   - Tail, 25%
   - Fuselage, fighter, 10%
   - Fuselage, transport, 25%
   - Secondary (flaps, slats, access panels, etc.), 40%
   - Landing gear, 8%
   - Air induction, 30%

### §20.2.4 Low Wing Loading Aircraft (p. 570)

Aircraft in this class are characterized by $W/S \leq 2$ lb/ft² and are powered by solar or human energy.
Solar or human energy is puny compared to the more traditional sources of energy for aircraft (i.e.,
turbine, piston, and rocket). Because power required is dependent on speed, this aircraft class will
typically have flight speeds less than 30 KEAS. Human-powered aircraft cruise at speeds of 16 KEAS or less
(current distance record was established by the MIT Daedalus at 74 miles in 3 hr 54 min, in 1988) and
solar-powered at 23 KEAS (typical maximum speed for Helios at 1000 ft), both flying at wing loadings of
between 0.6 and 1.0 lb/ft². The Solar Snooper solar-powered aircraft of §§6.7 and 18.9 had a
$W/S = 1.86$ lb/ft².

Estimating weights for this class of aircraft is very challenging because the historical data base is
almost nonexistant. The large data base for sailplanes is not much help because their wing loadings range
from about 5 to 12 lb/ft². Sailplanes are designed for aggressive maneuvering as they chase a thermal and
high speed for wind penetration. The structural criteria and design of an aircraft with $W/S=1$ lb/ft² are
very much different than for one with $W/S=10$ lb/ft². Solar-powered aircraft would have design limit load
factors of 2.0 whereas sailplanes would have a limit of 6.0. The patent for the AeroVironment Centurion
contains a good discussion of structural design for this class of aircraft [7]. The wing weight (weight per
wing area) for existing aircraft and sailplanes with wing loadings ranging between 0.6 and 40 lb/ft² is
shown in Fig. 20.1.

The construction materials for the wings shown in Fig. 20.1 vary significantly as the wing loading
decreases. The U-2A, U-2S, and Boeing Condor wings are conventional built-up metal structures. The Lockheed
Martin Tier III-Minus Darkstar wing was made from graphite composites with an aluminum carry-through spar.
The Scaled Composites Voyager wing is also made from high-strength composites. Figure 20.1 shows two wing
loadings for the Voyager (26.8 to 7.5 lb/ft²) because its 72% fuel fraction is uncommonly large. The
Lockheed Martin Polecat features sandwich structures, water-jet cut ribs and keel, and simplified sandwich
skins using LTM45 carbon fiber prepreg. The sailplane group is constructed from Fiberglass and graphite
composites. The Helios, Centurion, and Daedalus wings use a hollow carbon tube spar with polystyrene sheet
ribs with leading edge and trailing edge members wrapped in a clear plastic Mylar skin covering that is
one-half mil thick.

**Fig. 20.1** — *Wing weight vs wing loading for various high-AR, low wing loading aircraft*
*[Nicolai & Carichner, Fig. 20.1, p. 571]*. Log-log plot: vertical axis Wing Wt/Wing Area (lb/ft²,
0.1-10), horizontal axis TOGW/Wing Area (lb/ft², 0.1-100). A single trend line runs diagonally from about
(0.5, 0.15) to (40, 4.3) across the full data range. Data points, keyed by symbol (circle = High altitude,
square = Low-Med altitude) and numbered 1-12 per the adjoining legend table, cluster in two groups: a
"Sailplanes" cluster (unlabeled squares/circles clustered around TOGW/Wing Area ≈ 5-12, Wing Wt/Wing Area
≈ 1.3-3.7) and the twelve named/numbered points scattered along the trend line from lower-left (points
9, 10, 11 near 0.7, 0.12-0.15) to upper-right (point 1 near 40, 4.3), with point 5 (Voyager) plotted twice
(once on-trend near the sailplane cluster, once as an outlier at high TOGW/Wing Area, low Wing Wt/Wing Area
≈ 1.5, reflecting its unusually large 72% fuel fraction).

Legend table (Number | Aircraft | AR):

| Number | Aircraft | AR |
|---|---|---|
| 1 | U-2S | 10.6 |
| 2 | U-2A | 10.6 |
| 3 | Tier III- (Darkstar) | 14.1 |
| 4 | Condor | 36.0 |
| 5 | Voyager | 33.8 |
| 6 | Polecat | 11.9 |
| 7 | PW-5 | 17.8 |
| 8 | SB-8 | 23.0 |
| 9 | Helios | 30.9 |
| 10 | Centurion | 23.0 |
| 11 | Daedalus | 38 |
| 12 | Nemesis | 6.5 |

**Sidebar** — *"Weights Rule!"* (p. 572): Estimating weights is critical in the design of an aircraft
(remember the weights rule). This is especially true for weight-critical aircraft such as the Voyager,
designed by Burt Rutan (Scaled Composite Inc). It had to have a fuel fraction of 72 percent in order to fly
22,912 nm around the world nonstop. The Voyager, piloted by Dick Rutan (Burt's brother) and Jeana Yeager,
took off from Edwards AFB in California on December 14, 1986 and returned 9 days later—making this unique
aircraft the first to complete the first nonstop, nonfueled flight around the world.

The airframe, largely made of fiberglass, carbon fiber, and Kevlar, weighed 939 lb when empty, which gave
it a weight fraction of 9.7 percent. The aircraft weighed 9695 lb at takeoff, 2250 lb empty, 534 lb for
payload (including the pilots) and 7010 lb of fuel. The Voyager had a wing span of 110 ft, 8 inches and an
aspect ratio of 33.8, giving the aircraft a maximum L/D of 27. The takeoff wing loading was 26.8 psf and
7.5 psf at landing (with 3 gallons of fuel remaining in the tanks).

The team behind the Voyager's flight, including designer Rutan, were awarded the Collier Trophy for their
record-breaking flight. The Voyager is hanging in the Smithsonian Air and Space Museum in Washington, D.C.

## §20.3 Determining Center of Gravity and Moments of Inertia (p. 572)

The following component weights are summed to give the aircraft empty weight:

- Structure (wing, fuselage, tail, and landing gear)
- Propulsion (engine, inlet, fuel system, starting system, engine controls, and thrust reversers)
- Surface controls plus hydraulics and pneumatics
- Instruments
- Electrical system
- Furnishings (ejection seats and crew equipment)
- Air conditioning and anti-icing
- Electronics (avionics)
- Miscellaneous (drag chutes, etc.)

Adding the fuel weight and fixed weights (crew and payload) gives the aircraft takeoff weight.

Next, it is important to determine the location for each of the components to determine the center of
gravity (c.g.) of the aircraft. Many of the component weight locations will be self-evident, such as the
pilot, fire control system, and landing gear. Other components, such as fuel cells,
navigation equipment, bombs, and baggage, can be shifted around to a certain extent to influence the c.g.
location.

A weight and moment summary in tabular form is shown in Table 20.1. This serves to provide the designer
with a refined estimate of the aircraft c.g. as a function of component placement. Chapter 23 discusses the
desired c.g. location to give good flying qualities.

**Table 20.1** — *Weight and Moment Summary* *[Nicolai & Carichner, Table 20.1, p. 573]*. Columns:
Component; Weight (lb); Distance from Aircraft Nose (ft); Moment (ft·lb). Rows: Fuselage; Wing; Main gear;
Vertical tail; Horizontal tail; etc. — each a blank template row for the designer to fill in — with a
totals row: Weight column = $\Sigma\text{Wt}$, Distance column = "Total moment =", Moment column =
$\Sigma M$.

The longitudinal position of the c.g. may now be determined as

$$X_{c.g.} = \text{Total Moment}/\Sigma\text{Wt}$$
*(unnumbered equation, p. 573)*

This center of gravity should be expressed as distance from the nose of the aircraft and percentage of the
mean aerodynamic chord. The designer should determine an $X$ location of c.g. for both a full and an empty
aircraft as shown in Fig. 23.3 (the c.g. envelope). Figure 23.3 shows the most forward and most aft c.g.
locations. It would be embarrassing to have a tricycle-gear aircraft fall on its tail in one of these
extreme loading conditions.

The aircraft body axes are defined according to Fig. 2.2 or 21.1. The aircraft moments of inertia are
defined as follows:

$$I_{xx} = \int(y^2+z^2)\,dm$$
$$I_{yy} = \int(x^2+z^2)\,dm$$
$$I_{zz} = \int(x^2+y^2)\,dm$$
*(unnumbered equations, p. 573)*

where $dm$ is an incremental mass element of aircraft. The products of inertia are defined as

$$I_{xy} = \int(xy)\,dm$$
*(unnumbered equation, p. 573)*

and so on. The moments of inertia can be estimated at this point in the design process using Figure 20.2,
which is based upon historical data from many existing aircraft.

**Fig. 20.2** — *Aircraft moments of inertia as a function of gross weight* *[Nicolai & Carichner, Fig. 20.2,
p. 574]*. Log-log plot: vertical axis Moment of Inertia (1000 slug·ft², 2-100), horizontal axis Gross Weight
(1000 lb, 2-100). Four curves, all rising monotonically and roughly linearly (in log-log space) with gross
weight: $I_{zz}$ (leftmost/lowest curve, starting near gross weight 3.5); $I_{yy}$ (rising steeply,
reaching 100 by about gross weight 27, labeled "Twin Engine" alongside $I_{xx}$); $I_{xx}$ "Twin Engine"
(tracks close to and slightly below $I_{yy}$); $I_{xx}$ "Single Engine" (the rightmost/lowest-slope curve,
reaching only about 60 by gross weight 40-100, labeled separately from the twin-engine curves).

### References *[Nicolai & Carichner, Ch. 20 References, p. 574]*

[1] Torenbeek, E., *Synthesis of Subsonic Aircraft Design*, Delft Univ. Press, The Netherlands, 1976.
[2] Roskam, J., *Aircraft Design*, Pt. 5, Roskam Aviation and Engineering Corp., Ottawa, KS, 1985.
    [Available via www.darcorp.com (accessed 31 Oct. 2009).]
[3] Raymer, D. P., *Aircraft Design: A Conceptual Approach*, AIAA Education Series, AIAA, Reston, VA, 2006.
[4] Thomas, F., *Fundamentals of Sailplane Design*, College Park Press, College Park, MD, 1999.
[5] Stender, W., "Sailplane Weight Estimation," OSTIV (International Scientific and Technical Gliding
    Organization), Elstree-Wassenaar, The Netherlands, 1969.
[6] Adams, D. F., "High Performance Composite Material Airframe Weight and Cost Estimating Relations,"
    *Journal of Aircraft*, Vol. 11, No. 12, Dec. 1974.
[7] Hibbs, B. D., Lissaman, P. B. S., Morgan, W. R., and Radkey, R. L., "Solar Rechargeable Unmanned
    Aircraft," U.S. Patent No. 5,810,284, 22 Sept. 1998 (patent for the AeroVironment Centurion).

Chapter 20 extraction complete.
