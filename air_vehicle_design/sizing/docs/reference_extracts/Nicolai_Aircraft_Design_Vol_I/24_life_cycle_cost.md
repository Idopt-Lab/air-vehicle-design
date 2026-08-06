# Chapter 24 — Life Cycle Cost

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, printed
pp. 625–650 (PDF pp. 634–659). Page offset: PDF page = printed page + 9 (consistent with Ch. 20-23).

Text-layer inventory: Figs 24.1-24.6 (with sub-parts 24.6a-d — regex initially only caught 24.6a-c; 24.6d
confirmed present during transcription); Tables 24.1-24.3; Eqs 24.1-24.8 (with sub-parts 24.6a-b) —
confirmed complete via post-transcription Grep verification.

## Chapter Opener (p. 625)

Photo of a Singapore Airlines Boeing 777 ("Triple 7") on the runway, landing gear down, in a moody
overcast setting. Caption *(paraphrased)*: the 777 was developed in the 1990s to compete head-on with the
Airbus A340 and the MD-11/12; Boeing has delivered over twice as many 777s as Airbus has A340s (McDonnell
Douglas dropped out of this market); Example 24.1 uses the 777 to estimate development and acquisition
cost. Photograph courtesy of Singapore Airlines.

Section-list sidebar: Cost-Estimating Equations; Economic Escalation Factors; Design for Reduced O&M;
Cost-Estimating Charts; UCAV vs Manned Aircraft O&S; Design for Production.

Epigraph: "A billion here, a billion there— pretty soon it adds up to real money!" — Everett McKinley
Dirksen.

Copyright notice: Copyright © 2010 American Institute of Aeronautics and Astronautics.

## §24.1 Life Cycle Cost (p. 626)

The *life cycle cost* (LCC) of a military aircraft is the total cost to transition the aircraft from
"cradle to grave." It includes the following phases (as shown in Fig. 1.16):

- Research
- Development, Test, and Evaluation (DT&E)
- Acquisition (production, ground equipment, initial spares, training aids, etc.)
- Operations and Maintenance (O&M)

The *research phase* involves the basic research and the exploratory and advanced development efforts
required to mature those technologies that are essential to the successful operation of the aircraft.
This phase can include technology demonstrator aircraft, testbeds, and prototypes. An example of this
phase would be the effort expended in researching the integration of the shaft-driven lift fan into the
Joint Strike Fighter short takeoff, vertical landing (STOVL) prototype X-35B. This phase is important
because, without it, advanced technologies would not find their way onto new aircraft systems.

In many cases, a commercial aircraft will build upon technology that was developed for a military
aircraft program, thereby reducing the research cost for the commercial program. The research phase is a
difficult cost item to estimate because of the uncertainty inherent in a research and technology
development program. Also, the research phase is a mixture of contractor funding and government funding.

The *development, test, and evaluation cost* is that cost required to engineer, develop, fabricate, and
flight test a number $Q_D$ of aircraft prior to committing to production. The DT&E aircraft might number
as few as 2 or as many as 10. The DT&E phase is usually government funded. The cost elements charged to
DT&E are as follows:

- Airframe engineering
- Development support
- Flight test aircraft
  - Engine and avionics
  - Manufacturing labor
  - Material and equipment
  - Tooling
  - Quality control
- Flight test operations
- Test facilities
- Profit

The *acquisition cost* includes the cumulative cost of $Q_P$ production aircraft, associated ground
equipment (such as starting carts and special

equipment for maintenance and operation), initial spares, and training aids (simulators, manuals, etc.).
The cost elements charged to production are as follows:

- Engines and avionics
- Manufacturing labor
- Material and equipment
- Airframe engineering (sustaining)
- Tooling
- Quality control
- Manufacturing facilities
- Profit

The *operations costs* comprise the fuel and oil (POL), including storage and delivery, salaries of
operating and support personnel, day-to-day (direct) maintenance, depot and overhaul, spares, depreciation
of equipment, and indirect costs.

For a military aircraft the breakdown of O&M costs (sometimes called O&S, operations and support) is as
follows:

- **Spares.** Initial, replenishment, engines, war reserve material (WRM)
- **Maintenance.** Both on-equipment and off-equipment
- **Management personnel.** System and item managers
- **Training.** Ground and flight training
- **Operations.** Crew, commander, staff, and operations personnel
- **Support.** Base operating support (the care and feeding of all squadron personnel)
- **POL.** Fuel, oil, and lubricants
- **Modifications.** Hardware modifications
- **Munitions and missiles.** Training
- **Personnel.** Permanent change of station (PCS)
- **Attrition**
- **New facilities**

For commercial aircraft the LCC phases are similar to those of a military aircraft except that the
research, development, test, and evaluation (RDT&E) phase is all privately funded. This phase ends with
the type certification of the aircraft by the Federal Aviation Administration (FAA). As discussed in
Chapter 1, this phase is shorter for a commercial aircraft than for a military aircraft.

The acquisition phase for a commercial aircraft is termed the *production phase*.

For commercial operations the cost breakdown is as follows:

- Flight operations—crew, POL, airport fees, insurance
- Station and ground
- Ticketing, sales, and promotion
- Maintenance and overhaul
- Flight equipment depreciation
- Passenger services
- General administration and taxes

The O&M phase costs are the largest element of the LCC because most aircraft are operational for several
decades: the commercial aircraft flying 24/7 revenue flights [1] and the military manned aircraft doing
peacetime training. Figures 24.1 and 24.2 show the LCC for the B-52 and the F-111, respectively—two
military aircraft whose operational life was more than three decades.

The B-52 LCC shown in Fig. 24.1 is typical of the military LCC history, where the RDT&E is small relative
to the acquisition and operations phases and precedes the acquisition phase with only a small overlap. The
F-111, Fig. 24.2, on the other hand, had technical problems during the latter part of the flight test and
early operations phase, which resulted in an overlapping RDT&E phase and significant increase in RDT&E
cost. The F-111 history was more the exception than the rule, involving several new technologies and
occurring during a semiwartime situation. However, it points out the importance of being careful and
thorough during the RDT&E phase and committing to production only after completed test and evaluation.

In both the commercial and military O&M phase, direct personnel costs are more than one-third of the
costs. This points out the huge impact

**Fig. 24.1** — *B-52 life cycle cost (LCC) (data from [2])* *[Nicolai & Carichner, Fig. 24.1, p. 628]*.
Chart of Cost ($billion, y-axis 0-1.5) vs Year (x-axis 1950-1970+), with three overlapping shaded areas:
"RDT&E ($0.47B)" (small triangular area peaking ~1950-1952), "Acquisition (Total=$5.8B)" (larger irregular
peaked area spanning roughly 1952-1962, peaking near 1.35 around 1958-59, with a secondary hump around
1961), and "Operations" (the largest, cumulative area rising from ~1955 onward and continuing to climb
through 1977, reaching ~1.25-1.3 by the end of the chart, with a tabulated "Year / Cum Total" callout: 1962
$6.27 Billion, 1965 $8.94 Billion, 1970 $14.21 Billion, 1975 $20.66 Billion). Along the top, "% of Program
Cost RDT&E/Acq/Oper" is annotated at five points along the curve: 4/46/50 (~1962), 3/37/60 (~1965), 2/27/71
(~1971), 2/21/77 (~1977, dashed continuation).

**Fig. 24.2** — *F-111 life cycle cost (data from [3])* *[Nicolai & Carichner, Fig. 24.2, p. 629]*. Chart
of Cost ($billion, y-axis 0-1.0) vs Year (x-axis 1960-1985+), with shaded areas: "RDT&E ($1.6B)" (an
irregular multi-peaked area spanning roughly 1962-1975, itself overlapping a taller unlabeled dashed
outline peaking near 0.83 around 1968-69 — reflecting the schedule overrun/overlap discussed in the text);
"Acquisition (Total=$4.8B)" (overlapping area rising through the early 1970s to a plateau ~0.43-0.44 by
~1974); "Operations" (the plateaued cumulative total continuing flat from ~1974 onward, with a callout
table "After / Cum Total": 10 yr $3.41B, 20 yr $7.73B, and vertical reference lines at "10 years" and
"20 years"). Along the plateau, "% of Program Cost RDT&E/Acq/Oper" is annotated at two points: 17/49/34
(~10-year mark) and 12/34/54 (~20-year mark).

that the human element has on aircraft O&M and makes a good argument for military UAVs [this will be
examined later in an example comparing squadron O&M costs for the F-16 and an unmanned combat aerial
vehicle (UCAV)].

## §24.2 DT&E and Acquisition-Production Costs (p. 629)

The methodology presented in this section is very preliminary but is adequate for the economic analysis
appropriate to this level of design. There are more-refined LCC methods available but they require
information that is normally not available at the conceptual design.

Methodology for estimating the research phase costs is not available as this is a very nebulous effort
and very much dependent upon the individual aircraft program. The designer should examine the design for
the development status of the technologies being used, then talk with the technology community relative to
the schedule and funds appropriate to these technologies.

Methodology for estimating costs for the remaining three LCC phases will be discussed in the following
sections. In many cases the costs will be estimated in terms of 1998 U.S. dollars. Figure 24.3 can be used
to convert the 1998 dollar costs to "now year" costs by multiplying the 1998 dollars by the economic
escalation factor [Consumer Price Index (CPI)].

The *cost-estimating relationships* (CERs) for the military DT&E and production phases will be based
upon the methodology developed by the

**Fig. 24.3** — *Economic escalation factors (CPI)* *[Nicolai & Carichner, Fig. 24.3, p. 630]*. Chart of
Consumer Price Index (y-axis, $100-$300) vs Year (x-axis, 1980-2020), a single rising curve from $100 in
1980 through $200 at "1998 = $200" (marked with a dot), continuing up to a local peak around $262 near
2008, a slight dip to ~$258 by ~2010, then a dashed projected continuation rising to ~$295 by 2020.
Reference note: "Ref: Bureau of Labor Statistics."

Rand Corporation in 1986 and presented in [4]. This was preceded by [5] in 1971; it examined 29 aircraft
built between 1945 and 1970. Reference [4] added the following 13 more modern aircraft to the data base:

- **Attack.** A-6, A-7, A-10, S-3
- **Fighter.** F-111, F-4, F-14, F-15, F-16, F-18
- **Transport.** C-141, C-5
- **Utility.** T-39

The Rand study of the DT&E and production costs for aircraft built between 1945 and 1986 concluded that
the primary characteristics driving these costs were as follows:

1. $W$, empty weight in pounds (discussed in the next section)
2. $S$, maximum speed in knots
3. $Q$, quantity of aircraft produced during DT&E and production

All other aircraft characteristics appeared to be second order.

It is worth bringing to the attention of the reader that the weight influencing the cost of the aircraft
is more correctly the weight according to the American Manufacturers Planning Report (the *AMPR weight*),
which is the empty weight of the aircraft minus the procured items (such as engines, wheels, instruments,
and electrical equipment). To determine the AMPR weight the designer needs a detailed weight summary,
which is often not available during the conceptual design phase. Typically, the AMPR weight

is approximately 62% of the empty weight. In the cost methodology that follows (from [4]) the
always-available empty weight is used and the 62% has been absorbed into the coefficients. Reference [5]
used AMPR weight.

The reader will observe that the direct labor hours to produce an item (such as engineering, assembly, or
tooling) will decrease as the cumulative number of items produced ($Q$) increases. The basis for this is
that the personnel involved in producing the item get smarter as they produce more items. This improvement
is called the learning curve. Early CERs were built upon an 80% learning curve, where the labor hours
reduced by 20% every time the quantity produced doubled. Thus, the second-unit labor cost was 80% of that
for the first unit, the fourth was 80% of the second, the eighth was 80% of the fourth, and so on.

When large quantities of the same item are produced, the rate of improvement with respect to time may be
so small as to go unnoticed. For example, if 1000 units have been produced and the production rate is 250
units per year, four years will be required to reach 2000 units: four years to double the quantity and
attain a 20% reduction in labor hours. It should be noticed, however, that the 2000th unit would require
8.7% of the labor hours needed for the first unit. Thus, production runs are necessary to drive the unit
costs down. If Ford only produced 50 automobiles each year, no one could afford them. It is only through
mass production that could put "a car in every garage."

Reference [4] examined the cost-quantity relationship and found it to vary for the different cost
elements. Thus, the CERs presented in the next sections will have different values of the cost-quantity
curve slope (or exponent for $Q$) for each cost element. The learning curve is close to 80 for only a few
of the cost elements.

#### §24.2.1 Airframe Engineering (DT&E and Production) (p. 631)

The engineering activities involved in the DT&E are as follows:

1. Design studies and integration
2. Engineering for wind tunnel models, mock-ups, and engine tests
3. Test engineering, laboratory work on subsystems and static test items, and development testing
4. Release and maintenance of drawings and specifications
5. Shop and vendor liaison (*)
6. Analysis and incorporation of changes (*)
7. Materials and process specifications (*)
8. Reliability (*)

The starred items (*) are also part of the sustaining engineering effort production. Engineering hours
not directly related to airframe design and

development are not included here. For example, test engineering, ground handling equipment design and
development, mobile training units, and publications are not charged to airframe engineering.

The cumulative total *airframe engineering hours E* can be estimated using the following expression
(from [4]):

$$E = 4.86\,W^{0.777}S^{0.894}Q^{0.163} \tag{24.1}$$
*[Nicolai & Carichner, Eq. (24.1), p. 632]*

where $W$ = empty weight in pounds; $S$ = maximum speed (kt) at best altitude; $Q$ = cumulative quantity
produced = $Q_D$ for DT&E phase (number of development flight test aircraft), = $Q_D + Q_P$ for production
phase.

The empty weight $W$ is defined as the takeoff gross weight (TOGW) minus the fuel and payload. Said
another way, the empty weight of the aircraft is the sum of the (1) airframe structure and canopy,
(2) wheels, brakes, and tires, (3) engines and accessories, (4) cooling fluid, (5) rubber or nylon bladder
type fuel cells, (6) crew seats and instruments, (7) batteries, electrical power supply, and
conversion-conditioning equipment, (8) electronic and avionics equipment, (9) armament and fire-control
system, (10) air conditioning units and fluid, (11) onboard power plant unit, and (12) trapped fuel and
oil.

Equation (24.1) gives the total engineering hours for either DT&E or production. For the DT&E phase the
quantity $Q$ is equal to the number of flight test aircraft $Q_D$ and the engineering hours are just for
DT&E. For the production phase, the quantity $Q$ is the total produced ($Q_D$ plus the $Q_P$ production
aircraft). The production phase sustaining engineering hours are the hours from Eq. (24.1) minus the DT&E
engineering hours (see Section 24.3.9 for an example).

The hours from Eq. (24.1) are then multiplied by an appropriate engineering dollar rate for the year of
interest. This rate includes direct labor, overhead, general and administrative expense, and miscellaneous
direct charges. Figure 24.4 presents historical data on average hourly rates, created with data from the
U.S. Department of Labor. These labor rates can be estimated from the consumer price index (CPI), which is
available from the U.S. Department of Labor, Bureau of Labor Statistics Web site.

#### §24.2.2 Development Support (DT&E) (p. 632)

*Development support* is defined as the nonrecurring manufacturing effort undertaken in support of
engineering during the DT&E phase of an

**Fig. 24.4** — *Trends in hourly rates in aircraft construction for engineering, tooling, manufacturing,
and quality control* *[Nicolai & Carichner, Fig. 24.4, p. 633]*. Chart of Hourly Rate ($/h, y-axis 0-120)
vs Year (x-axis 1970-2010), four roughly-linear rising trend lines labeled (top to bottom near the
2000-2010 end) "Tooling," "Engineering," "Quality Control," "Manufacturing," all starting near $0 around
1970 and reaching roughly $105-120/h by 2010, with Manufacturing consistently the lowest of the four.
Linear curve fits (y=year) given in a callout box: Tooling $R_T = 2.883y - 5666$; Engineering
$R_E = 2.576y - 5058$; QC $R_{QC} = 2.60y - 5112$; Manufacturing $R_M = 2.316y - 4552$.

aircraft program. The cost of the development support is the cost of manufacturing labor and material
required to produce mock-ups, test parts, static test items, and other items of hardware that are needed
for airframe design and development work. The level of this effort is largely dependent upon the extent
that new technologies figure into the aircraft program. If the aircraft design involves new and untried
concepts, then the development support cost can be high. For example, the KC-135 was largely a derivative
of the Boeing 707, and the development support cost was $(1957)37 million, whereas the F-111A incorporated
several new and untried technologies and its development support cost was $(1965)178 million.

The development support cost can be estimated using (from [4])

$$D = 66\,W^{0.63}S^{1.3} \tag{24.2}$$
*[Nicolai & Carichner, Eq. (24.2), p. 633]*

where $D$ = development support cost in 1998 constant dollars; $W$ = empty weight, in pounds (lb);
$S$ = maximum speed, in knots (kt), at best altitude.

#### §24.2.3 Flight Test Operations (DT&E) (p. 633)

The *flight test operations* cost element includes all costs incurred by the aircraft builder to carry
out flight tests except the cost of the flight test

aircraft. It includes flight test engineering planning and data reduction, manufacturing support,
instrumentation, spares, fuel and oil, pilot's pay, facilities rental, and insurance. The flight test
establishes the operating envelope of the aircraft, its flying and handling qualities, general
airworthiness, initial maintainability features, and compatibility with ground support equipment. Civil
and commercial aircraft are establishing the aircraft's compliance with the FARs for airworthiness
certification. Military aircraft are demonstrating compliance with government specifications and
regulations, such as Air Force Regulation 80-14.

The cost for flight test operations can be estimated using (from [4])

$$F = 1852\,W^{0.325}S^{0.822}Q_D^{1.21} \tag{24.3}$$
*[Nicolai & Carichner, Eq. (24.3), p. 634]*

where $F$ is the flight test operations cost in 1998 constant dollars and $W$, $S$, and $Q_D$ are as
defined in Eq. (24.1).

#### §24.2.4 Tooling (DT&E and Production) (p. 634)

*Tools* are the jigs, fixtures, dies, and special equipment used in the fabrication of an aircraft.
*Tooling hours* are defined as the hours charged for tool design, tool planning, tool fabrication,
production test equipment, checkout of tools, maintenance of tooling, normal changes, and production
planning. Tooling hours are dependent upon a new variable called *production rate*. Tools designed for low
production rates do not have to be as well engineered as tools for high production rates. Sometimes tools
are destroyed during the fabrication process (called *soft tooling*) and have to be rebuilt for each
aircraft. Tooling can be as simple as 2x4s or as complicated and costly as matched metal dies of stainless
steel accurate to one ten-thousandth of an inch (1/10,000 in.).

The tooling hours can be estimated using the following expression (from [4]):

$$T = 5.99\,W^{0.777}S^{0.696}Q^{0.263} \tag{24.4}$$
*[Nicolai & Carichner, Eq. (24.4), p. 634]*

where $T$ = cumulative tooling hours; $Q$ = cumulative quantity, $Q_D+Q_P$; $Q_D$ = DT&E; $Q_P$ =
production.

The *total tooling cost* is the tooling hours multiplied by an appropriate tooling hourly rate. Figure
24.4 shows some historical data on average hourly tooling rates.

Equation (24.4) gives the total tooling hours for either DT&E or production. For the DT&E phase tooling
hours, the quantity $Q$ is $Q_D$. For the production phase, the quantity $Q$ is $Q_D$ plus the $Q_P$
production aircraft and the tooling hours are the hours from Eq. (24.4) minus the DT&E tooling hours.

#### §24.2.5 Manufacturing Labor (DT&E and Production) (p. 635)

Manufacturing labor hours include those hours necessary to fabricate, process, and assemble the major
structure of an aircraft, and to install purchased parts, government furnished equipment (GFE), and
off-site manufactured assemblies (i.e., subcontract components). Airframe structure direct manufacturing
man-hours also include effort on those parts that, because of their configuration or weight
characteristics, are design controlled for the basic aircraft. These normally represent significant
proportions of the airframe weight and manufacturing effort, and they are included regardless of their
method of acquisition. Such parts specifically include [4] the following:

1. Actuating hydraulic cylinders
2. Radomes, canopies, and ducts
3. Passenger and crew seats
4. Fixed external tanks

The manufacturing labor hours can be estimated using the expression (from [4])

$$L = 7.37\,W^{0.82}S^{0.484}Q^{0.641} \tag{24.5}$$
*[Nicolai & Carichner, Eq. (24.5), p. 635]*

where $L$ is cumulative total manufacturing hours, and $W$, $S$, and $Q$ are defined in Eq. (24.1). The
manufacturing labor hours for DT&E and for production are determined separately as discussed in Sections
24.2.1 and 24.2.4. The cumulative manufacturing cost is obtained by multiplying the manufacturing labor
hours $L$ by a representative hourly rate. Figure 24.4 gives representative average hourly rates for
manufacturing.

#### §24.2.6 Quality Control (p. 635)

*Quality control* (QC) is the task of inspecting fabricated and purchased parts, subassemblies, and
assembled items against material and process

standards, drawings, and/or specifications. Quality control is an extremely important activity in the
manufacture of aircraft because of their complexity. Government specifications and standards require
close inspection of all facets of fabrication. Quality control is closely related to direct manufacturing
labor and is considered to be a percentage of the labor hours. The quality control hours can be estimated
as follows (from [4]):

$$\text{QC} = 0.076\,L \text{ for cargo and transport aircraft} \tag{24.6a}$$
*[Nicolai & Carichner, Eq. (24.6a), p. 636]*

$$\text{QC} = 0.13\,L \text{ for all other aircraft} \tag{24.6b}$$
*[Nicolai & Carichner, Eq. (24.6b), p. 636]*

The total cost for quality control is obtained by multiplying the man-hours from Eq. (24.6) by the
representative manufacturing hourly rate.

#### §24.2.7 Manufacturing Material and Equipment (DT&E and Production) (p. 636)

The *material and equipment list* (sometimes called the BOM, bill of materials) includes the raw
material, hardware, and purchased parts required for the fabrication and assembly of the airframe. All
airframe equipment except engines and avionics are included in this cost item. Specific items in the
material and equipment cost are as follows:

1. Raw materials in sheets, plates, bars, rods, and so on
2. Raw castings and forgings
3. Wires, cables, fabrics, tubing, windshield glass and canopies, and so on
4. Fasteners, clamps, bushings, and so on
5. Hydraulic and plumbing fittings, valves, and fixtures
6. Standard electrical products such as motors, transformers, inverters, alternators, voltage regulators,
   switches, controls, generators, batteries, and auxiliary power units (APUs)
7. Pumps for fuel, hydraulic, water, and so on
8. Environmental systems, air conditioning, and oxygen equipment
9. Crew furnishings, seats, instruments, bunks, and so on
10. Bladder-type fuel tanks

The manufacturing material and equipment costs can be estimated from the following expression [4]:

$$M = 16.39\,W^{0.921}S^{0.621}Q^{0.799} \tag{24.7}$$
*[Nicolai & Carichner, Eq. (24.7), p. 636]*

where $M$ = cumulative total manufacturing material and equipment cost in 1998 dollars and $W$, $S$, and
$Q$ are defined in Eq. (24.1). The costs for DT&E

and production are determined separately using development $Q=Q_D$ and production $Q=Q_P$ (see example
in Section 24.3).

#### §24.2.8 Engine and Avionics Costs (p. 637)

The engine and avionics will be assumed to be off-the-shelf items so that DT&E costs of these subsystems
will not be considered. Only production unit costs are considered.

Costs in 1998 dollars for current turbine engines are shown in Fig. 24.5. Figure 24.5 shows quite a bit of
scatter in the data. This scatter is explained by the fact that the engines represent different types,
levels of technology, and production quantities. More refined propulsion cost methodology would take these
variables into consideration [6]. However, at this point in the design, the data from Fig. 24.5 or the
following expression is adequate:

$$P = 2306\left[0.043\,T_{SLS} + 243.3\,M_{max} + 0.969\,T_R - 2228\right] \tag{24.8}$$
*[Nicolai & Carichner, Eq. (24.8), p. 637]*

where $P$ = production engine unit cost in 1998 dollars; $T_{SLS}$ = sea level maximum thrust in pounds;
$M_{max}$ = maximum Mach number; $T_R$ = turbine inlet temperature in degrees absolute (Rankine).

Avionics equipment is so varied that space will not be taken here to list avionics gear and associated
costs. The designer is referred to the avionics vendors for prices of selected avionics equipment.

Figure 24.6 presents unit prices [\$(1993)] for existing fighters, bombers, transports, bizjets, cruise
missiles, and targets. The charts confirm that aircraft are bought by the pound. The prices can be
adjusted to reflect any year by ratioing the escalation factors from Fig. 24.3.

Unit prices are not the only thing taken into account when determining an aircraft's selling price. Often
the selling price will include initial spares for initial fleet operation, data and publications, and
flight training for the pilots and maintenance training for the ground crews. These "extras" can easily be
10% of the selling price.

The cost-estimating relations presented in Sections 24.2.1 through 24.2.8 will be demonstrated by
estimating the cost for the Boeing 777-200LR. This will be a good checkout for the CERs as they were
developed from a military aircraft data base.

Note the cost numbers in this example: it is a major decision for a company to commit to an \$8 billion
DT&E cost for a new aircraft line.

**Fig. 24.5** — *Engine production unit costs in 1998 dollars* *[Nicolai & Carichner, Fig. 24.5, p. 638]*.
Log-log scatter chart of Unit Production Costs [\$(1998) thousand] (y-axis, 10-10,000) vs Maximum Sea Level
Static Thrust (lb, x-axis, 100-100,000), with two parallel fitted trend lines (one for turbojets, one for
turbofans) and 27 numbered engine data points keyed to a legend table "Number / Engine": 1 PW F100, 2 GE
J101, 3 PW JT3D, 4 PW TF33, 5 GE TF34, 6 GE TF39, 7 PW JT8D, 8 PW JT12A, 9 CAE J69-T-25, 10 CAE J69-T-406,
11 Allison TF41, 12 PW J75, 13 GE J79, 14 GE J85, 15 PW TF30, 16 Allison TF41, 17 PW JT8D-11, 18 PW JT15D,
19 GE CF6-50, 20 Aimes TRS-18, 21 PW JT8D-209, 22 PW JT9D-7, 23 Williams WR-19-10, 24 Williams FJ-44-3A,
25 GE 90-76B, 26 GE 90-110B, 27 PW 4090. Each point is marked with one of four symbols per a "Symbol / Type"
legend: circle = Dry Turbojet, square = Aug Turbojet, triangle = Dry Turbofan, hexagon = Aug Turbofan.
Fitted-curve annotation: $\text{Unit Cost}[\$(1998)] = K\,T^{0.8356}$, where $T$ = Max Sea Level Static
Thrust, $K=436$ for Turbojets, $K=520$ for Turbofans.

**Fig. 24.6a** — *Unit prices for target and cruise missiles* *[Nicolai & Carichner, Fig. 24.6a, p. 639]*.
Chart of Unit Price [\$(1993) thousand] (y-axis 0-1400) vs Empty Weight (lb, x-axis 0-1600), with four
straight reference lines from the origin labeled \$1000/lb, \$750/lb, \$500/lb, \$250/lb, and data points
for named vehicles *(read from plot)*: BQM-74E (Chukar) ~(270, 240); MQM-107D (Streaker) ~(580, 300);
AGM-84 (Harpoon) ~(600, 850); AGM-158A (JASSM) ~(1050, 360); SLAM-ER ~(870, 900); AGM-109A (Tomahawk)
~(1350, 520); BQM-34E (Firebee) ~(1500, 460); AGM-86B (ALCM) ~(1400, 1400, at the top near/above the
$1000/lb line).

**Fig. 24.6b** — *Unit prices for light bizjets and turboprop aircraft* *[Nicolai & Carichner, Fig. 24.6b,
p. 639]*. Chart of Unit Price [\$(1993) million] (y-axis 0-12) vs Empty Weight (1000 lb, x-axis 0-25), with
two straight reference lines from the origin labeled \$500/lb and \$400/lb, and data points *(read from
plot)*: Diamond D-Jet ~(3, 1.3); Eclipse 500 ~(3.5, 1.2); Adam A-700 ~(5.5, 1.3); Beech King Air ~(7, 2.2);
Swearingen SJ-30 ~(7, 3.2); Piper Cheyenne ~(7, 4.0); Cessna Citation II ~(8.7, 3.5); Cessna Citation IV
~(9.5, 5.1); Learjet 35A / Learjet 36A / Beechjet (clustered) ~(10.7, 5.0-5.5); BAE Jetstream 41 ~(15,
7.0); Dornier 320-100 ~(15, 8.3); Bombardier Dash 8 ~(24, 10.6, near/above the $500/lb line).

**Fig. 24.6c** — *Unit prices for medium and large transports and bombers* *[Nicolai & Carichner,
Fig. 24.6c, p. 640]*. Chart of Unit Price [\$(1993) million] (y-axis 0-300) vs Empty Weight (lb — actually
1000 lb per axis label convention of this figure series, x-axis 0-500), with five straight reference lines
from the origin labeled \$1000/lb, \$600/lb, \$550/lb, \$500/lb, \$400/lb, and data points *(read from
plot)*: Gulfstream IV, C-130H, B-737-600, C-130J, B-737-800 (clustered low, ~40-90 empty weight, ~25-55
unit price); B-767-200ER ~(180, 85); B-767-300ER ~(200, 105); B-787-3 ~(220, 105); B-767-400ER ~(225, 110);
B-787-9 ~(255, 130); C-17A ~(255, 178); B-1B ~(190, 250, near/above the \$1000/lb line); B-777F ~(325, 165);
B-777-200LR ~(330, 143, labeled "Section 24.3 Example" in a highlighted callout); B-777-300ER ~(360, 195);
B-747-400ER ~(380, 165); C-5B ~(380, 155); B-747-8 ~(400, 200).

**Fig. 24.6d** — *Unit prices for fighter aircraft* *[Nicolai & Carichner, Fig. 24.6d, p. 640]*. Chart of
Unit Price [\$(1993) million] (y-axis 0-60) vs Empty Weight (1000 lb, x-axis 0-50), with two straight
reference lines from the origin labeled \$1500/lb and \$1000/lb, and data points *(read from plot)*: AV-8
~(14, 22); F-16C ~(19, 20); F/A-18C ~(23, 33); F-117A ~(27, 40); A-6E ~(28, 45); F-15E ~(28, 42); F-14A
~(40, 40); F-22 ~(33, 57, above the $1500/lb line).

#### Example 24.1 — DT&E and Acquisition Cost of the Boeing 777 (p. 640)

Estimate the cost of the Boeing 777 (called the triple seven). It was designed and developed between
October 1990 and October 1994. The first flight of the 777-200 was June 1994 and the aircraft became

operational with United Airlines in June 1995. The aircraft received its FAA and Joint Aviation Authority
(JAA, the European FAA) certificates in April 1995.

The 777-200LR (LR for longer range) became the world's longest unrefueled range commercial airliner when
it entered service in 2006. In November 2005, a 777-200LR flew 11,664 n mile on a special flight from Hong
Kong to London, a new world record. The aircraft can carry 440 passengers in an economy-class arrangement.
The 777 family features a digital fly-by-wire flight control system, a supercritical airfoil on a wing
swept 31.6 deg, 9% of the structural weight is composite materials, and the largest landing gear and tires
ever used on a commercial aircraft. The aircraft was designed entirely on a computer. All design drawings
were created on 3-D CAD software system known as CATIA. The aircraft was entirely "paperless." As of
November 2009 Boeing had delivered 816 aircraft in all models.

The information needed for developing the selling price for the 777-200LR is as follows (at this point it
is recommended that the reader review the Boeing 777 case study in Volume 2):

**Input table** *[Nicolai & Carichner, Example 24.1 input table, p. 641]*: Time frame for costing — 1998;
TOGW — 766,000 lb; Empty weight — 326,000 lb; Maximum speed — 510 kt (Mach 0.89); Engines — two GE 90-110B
($T_{SLS}=110{,}000$ lb); Avionics cost — \$250,000 (estimated); Flight test aircraft number — 9;
Production quantity for costing — 500 units; Labor rates, dollars per hour (\$/h) for 1998: Engineering
$R_E$ = \$88.85, Tooling $R_T$ = \$94.23, Manufacturing $R_M$ = \$75.37, Quality control $R_{QC}$ = \$82.80.

**Engineering hours** *[Nicolai & Carichner, Example 24.1 worked table, p. 641]*, using Eq. (24.1)
$E = 4.86\,W^{0.777}S^{0.894}Q^{0.163}$:
- Development: $Q_D=9$; $E_D = 35{,}201{,}600$ h; Cost = \$3,127,664,790.
- Production: $Q_P = 500+9 = 509$; $E_P = 67{,}909{,}467 - 35{,}201{,}600 = 32{,}707{,}867$ h;
  Cost = \$2,906,093,988.

**Development support**, using Eq. (24.2) $D = 66\,W^{0.63}S^{1.3}$: $D = \$666{,}235{,}760$.

**Flight test operations**, using Eq. (24.3) $F = 1852\,W^{0.325}S^{0.822}Q_D^{1.21}$:
$F = \$275{,}407{,}260$.

**Tooling**, using Eq. (24.4) $T = 5.99\,W^{0.777}S^{0.696}Q^{0.263}$:
- Development: $Q_D=9$; $T_D = 15{,}718{,}000$ h; Cost = \$1,481,107,000.
- Production: $Q_P = 9+500 = 509$; $T_P = 45{,}419{,}128 - 15{,}718{,}000 = 29{,}707{,}000$ h;
  Cost = \$2,799,324,000.

**Manufacturing labor**, using Eq. (24.5) $L = 7.37\,W^{0.82}S^{0.484}Q^{0.641}$:
- Development: $Q_D=9$; $L_D = 20{,}437{,}778$ h; Cost = \$1,540,395,000.
- Production: $Q_P = 9+500 = 509$; $L_P = 271{,}521{,}328 - 20{,}437{,}778 = 251{,}062{,}540$ h;
  Cost = \$18,922,583,650.

**Quality control**, using Eq. (24.6b) $\text{QC} = 0.13\,L$ (this is an "all other aircraft," i.e.
non-cargo/transport-CER row per the text's classification, applied here to the 777 as printed):
- Development: $Q_{CD} = 2{,}657{,}000$ h; Cost = \$219,992,000.
- Production: $Q_{CP} = 32{,}638{,}000$ h; Cost = \$2,702,431,000.

**Material and equipment, in 1998 dollars [\$(1998)]**, using Eq. (24.7)
$M = 16.39\,W^{0.921}S^{0.621}Q^{0.799}$:
- Development: $Q_D=9$; $M_D = \$544{,}418{,}700$.
- Production: $Q_P = 500$; $M_P = \$13{,}682{,}352{,}500$.

**Engine cost [\$(1998)]**, using Eq. (24.8): Engines maximum $T_{SLS} = 110{,}000$ lb; Unit cost =
\$8,483,800 (from Fig. 24.5); Development — assume three per aircraft, Cost = \$229,041,000; Production —
two per aircraft, Cost = \$8,483,000,000.

**Avionics cost [\$(1998)]: \$250,000** — Development Cost = \$2,250,000; Production Cost =
\$125,000,000.

**Total DT&E cost [\$(1998)]** *[Nicolai & Carichner, Example 24.1 DT&E summary table, p. 643]*: Airframe
engineering \$3,127,665,000; Development support \$666,236,000; Flight test aircraft \$4,017,204,000;
Engines \$229,041,000; Avionics \$2,250,000; Manufacturing labor \$1,540,395,000; Material and equipment
\$544,418,700; Tooling \$1,481,107,000; Quality control \$219,992,000; Flight test operations
\$275,407,000; Test facilities \$0; **Subtotal \$8,086,512,000**.

If this were a contracted effort there would be a profit added onto the DT&E cost. Because this is a
private company project there is no profit. Assume no special test facilities were built for this
program.

This DT&E cost is amortized over some number of units. Assume it to be amortized over 250 units so that
the price per aircraft will be increased by \$32,346,000.

**Total production and unit cost [in \$(1998)]** *[Nicolai & Carichner, Example 24.1 production summary
table, p. 643]*: Engines \$8,483,000,000; Avionics \$125,000,000; Manufacturing labor \$18,922,584,000;
Material and equipment \$13,682,353,000; Sustaining engineering \$2,906,094,000; Tooling \$2,199,324,000;
Quality control \$2,702,786,000; Manufacturing facilities \$0; **Subtotal for 500 aircraft
\$49,020,786,000**.

Assume for this discussion that there were no new manufacturing facilities needed for the production of
the 777-200LR. This was not the case, as new facilities were built for the 777 family—but this information
was not available for this example.

The unit cost is the total production cost divided by 500 aircraft plus the amortized cost: The unit
cost = \$130.4 million.

The unit price is the unit cost plus the profit on each aircraft. Assuming a 15% profit the unit selling
price is \$(1998)150 million. Boeing quotes a 2008 selling price for the 777-200LR of \$237.5 million.
Adjusting our estimated selling price to 2008 dollars (using the economic escalation factors on Fig. 24.3)
gives (260/200) = \$194 million, or a 22% cost difference. In the world of cost estimating a difference of
22% is considered quite close.

## §24.3 Operations and Maintenance Phase (p. 644)

The O&M costs are based upon a period of operation, usually 10 years. A fleet size and number of flying
hours (FH) per year are estimated.

The aircraft operating characteristics are known at this point so that an average fuel flow per hour, in
gallons per hour, can be determined. At the time of this writing the fuel prices were in a state of random
motion. The designer should obtain current and projected fuel prices from petroleum vendors and then
determine the operating fuel costs. The oil and lubricant costs are less than 0.5% of the operating fuel
costs and could be neglected in the total POL costs.

Each fleet of aircraft has a crew ratio that varies with the type of aircraft and the utilization rate.
Table 24.1 gives information on crew ratios for different aircraft and annual flying rates. Salaries for
these personnel are estimated and the aircrew costs determined.

The direct maintenance personnel costs are best determined using the *maintenance-man-hours per
flying-hour* (MMH/FH). Table 24.2 gives MMH/FH for current aircraft. This ratio varies with the type of
aircraft, the mission or sortie length, the utilization rate, and the years-in-service of the aircraft. The
MMH/FH decreases with increased sortie length because the takeoffs and landings are harder on the aircraft
than cruising flight. In addition, maintenance cannot be performed on a failed item until the aircraft
lands; when the aircraft is flying it continues to accumulate flying hours.

**Table 24.1** — *Crew Ratio for LCC Planning* *[Nicolai & Carichner, Table 24.1, p. 644]*. Aircraft Type
/ Flying Hours / Ratio: Transport, Less than 1200, 1.5; Transport, 1200-2400, 2.5; Transport, 2400-3600,
3.5; Bomber, 500, 1.5; Fighter, 500, 1.1.

**Table 24.2** — *LCC Planning Data* *[Nicolai & Carichner, Table 24.2, p. 645-646]*. Columns: Aircraft /
Average Annual FH per Aircraft / MMH/FH / Year. Rows (part 1, p. 645): Cessna 150/172 (—, 0.3, 1974);
Cessna Skywagon (—, 0.5, 1974); Beech Kingair (—, 1.0, 1974); Citation II (—, 3.0, 1988); T-37 (—, 7.8,
1981); T-38 (400, 10, 1981); T-39 (600, 9.8, 1974); T-43 (700, 10, 1974); F-5E (410, 17, 1981); A-7D (300,
25, 1974); A-10A (300, 13, 1984); F-14 (314, 48, 1988); F-15C (302, 22, 1998); F-16C (346, 19, 1998); F-18C
(360, 18, 1988); F-4E (302, 33, 1981); F-105G (316, 58, 1974); F-111D (280, 40, 1974); F-117A (—, 113,
1983 (IOC)); F-117A (—, 45, 2003); F-22A (316, 10.5, 2009); B-2A (—, 124, 1997 (IOC)); B-2A (—, 51, 2002);
B-2A (—, 32, 2004); C-17 (780, 24, 2005); C-17 (780, 20, 2007); C-17 (780, 16, 2008); C-5B (716, 58, 2005);
C-5B (716, 41, 2007); C-5B (716, 33, 2008); C-130E (720, 20, 1974); C-141B (1080, 21, 1981); B-52D (424,
37, 1981); B-52G (516, 49, 1981); B-58A (430, 54, 1974); KC-135 (377, 27, 1974); L1011 (1870, 14.1, 1981).
Rows (part 2, p. 646): DC-10-10 (2450, 11, 1981); B727-100 (2670, 8, 1974); B727-200 (2800, 6.5, 1974);
B737-200 (2200, 6.6, 1974); B747 (3525, 14.5, 1981); B757 (3010, 9.1, 1998); B767 (3010, 11.4, 1998); B777
(3010, 10.2, 1998); SR-71 (260, ~400, 1981). Data sources noted below the table: General Aviation—Cessna
and Beech Aircraft; Military—AFM-173-10, 3M data and U.S. Air Force and U.S. Navy maintenance records;
Commercial—CAB Form 41, Boeing Airplane Co.; Blackbird—Lockheed SR-71 Researcher's Handbook.

Notice the big difference in annual flying hours for the military and commercial. This is because the
commercial aircraft are losing money when they are sitting on the ground. Thus, the commercial aircraft
average about 14 hours in the air each day for the long-range transports and 10-12 hours for the shorter
route aircraft. In the military each pilot needs about 260 flying hours per year to stay proficient. Using
the crew ratios from Table 24.1, this gives about 300 h for fighters and 400 h for bombers per year, or
about one hour per day.

The *utilization rate* (flying hours per period of time) also affects the MMH/FH. This reduction in
man-hour requirement with increased utilization can be explained as follows. Aircraft systems, used daily,
normally receive better upkeep and experience fewer failures per flight hour. Also, aircraft that fly
frequently are on the ground less time and require maintenance to be accomplished in a limited amount of
time. Because of this pressure, maintenance is accomplished more efficiently and frequently by personnel
with higher skill level. Maintenance personnel can more easily retain knowledge of failures and maintenance
accomplished the day before, hence there is better continuity between maintenance tasks [3].

The MMH/FH are not static but vary with the point in the aircraft's service life. The MMH/FH decreases
from the initial deployment to a point where the aircraft is a mature, well-understood member of the fleet
and then starts increasing as the aircraft begins to wear out. Two good examples are the F-117A and B-2A.
Both aircraft had a very high MMH/FH at initial operational capability (IOC) due largely to the new
stealth technolo-

gies on the aircraft. As the maintenance crews became familiar with the aircraft and the new
low-observable (LO) materials the MMH/FH dropped dramatically.

The data in Table 24.2 are for typical sortie lengths and several years-in-service. The maintenance
personnel costs are determined from an estimated MMH/FH, the maintenance personnel hourly rates and the
annual flying hours.

## §24.4 O&M Costs (p. 647)

The elimination of peacetime flying (or at most minimal flying) would result in a large O&M cost saving
for a UCAV relative to a manned fighter squadron. The following example is notional and is used to develop
values for the various O&M cost elements. The example indicates that the cost savings in annual O&M for
the UCAV could be greater than 80%. This O&M cost saving needs to be quantified with a careful and
thorough study that examines the peacetime training (of both operators and ground crew) and the design
impact of long-term flyable storage.

#### Example 24.2 — Comparison of O&M Costs for Manned and Unmanned Tactical Fighter Squadrons (p. 647)

Manning of a 24-aircraft UCAV squadron is shown in Table 24.3 and compared with a 24-aircraft F-16C
squadron. Both squadrons are air-to-ground strike/SEAD (suppression of enemy air defenses) units. The
costs shown are annual O&M during peacetime. The number of officers (primarily pilots or remote operators)
is about the same for the two squadrons, but the number of enlisted personnel doing maintenance and
support is very much less for the UCAV squadron.

The UCAVs would be stored in a humidity-controlled, flyable storage facility. To ensure readiness, four
UCAVs would be taken out of storage each year and flown for manned aircraft interface and
maintenance-support crew training. The total squadron flying hours would be about 140. In contrast, a
24-unit F-16 squadron would fly about 8300 h each year. The composition of the enlisted personnel are 15
ground support crew (6 weapons handlers, 7 vehicle support, 1 chief, and 1 administration), 10 technicians
(ground control station and associated avionics maintenance), and 7 administration and support.

During wartime the active duty ground support crew would be augmented by 4 reserve crews to support a
tempo of four sorties per day for 30 days. During peacetime the active-duty ground support crew would
train the 4 reserve crews, support the limited UCAV flying, and maintain the aircraft in flyable storage.

**Table 24.3** — *UCAV Peacetime O&S Cost Compared with an F-16C Squadron [\$(2002)Million]* *[Nicolai &
Carichner, Table 24.3, p. 648]*. Two columns, "F-16C Annual O&S (per AFI 65-503)" and "UCAV Annual O&S
(per modified AFI 65-503)": Unit personnel — F-16C \$15.7M (42 off./307 enl.), UCAV \$3.6M (30 off./32
enl.); Fuel — F-16C \$5.5M (8300 flying hours), UCAV \$0.09M (140 flying hours); Base support personnel —
F-16C \$10.1M, UCAV \$1.4M; Depot maintenance — F-16C \$6.7M, UCAV (blank); Training and personnel
acquisition — F-16C \$5.3M, UCAV \$0.69M; Replenish spares — F-16C \$6.6M, UCAV (blank); System support
and mods. — F-16C \$4.3M, UCAV \$0.66M; Munitions and missiles — F-16C \$1.2M, UCAV (blank); **Total** —
F-16C **\$55.4M**, UCAV **\$6.44M**.

## §24.5 Design for Reduced Cost (p. 648)

The designer must recognize and appreciate the fact that he has a powerful influence over the life cycle
cost of an aircraft system. The major portion of the LCC is locked in at the conceptual and early
preliminary design phases, because it is during these early design phases that the aircraft is taking on
its shape and size. Once the design is in preliminary design, details are being fine tuned and all the
gross features, good and bad, are already locked in. This argument was presented in Fig. 1.16 and will be
developed in the following paragraphs.

The designer influences the RDT&E costs directly by the choice of new technologies to be incorporated in
the new design. The selection of new technologies that are not quite mature (i.e., ready for system
application) can cause this cost to skyrocket. The F-111 is an example of incorporating new technologies
that needed more research before moving them into the DT&E phase. The F-111A cost for development support
and engineering was more than any other U.S. Air Force production fighter. The technologies should be
fully demonstrated and validated before putting them on a new aircraft.

#### §24.5.1 Design for Production (p. 648)

The key to reducing production costs is to reduce the "touch labor." The designer has more influence over
this than any other person. Some design guidelines for reducing production costs are as follows:

1. Minimize the part count; this in turn reduces the tooling, fabrication, and assembly time, which
   reduces touch labor.
2. Standardize left and right tooling; this is another way to keep the part count down. Examples would be
   interchangeable right and left ailerons, main landing gears, and horizontal tails.
3. Require structural parts to perform multiple functions. An example would be the main landing gear
   mounted to the wing carry-through structure.
4. Use large unitary pieces of structure rather then build up the structure from many smaller pieces. This
   reduces touch labor and is ofttimes the rationale for using composites (large co-cured pieces) rather
   than metal built-up parts.
5. Minimize complex checkout.
6. Combine engineering and quality testing.
7. Use simple curvature shapes; the use of compound curvature surfaces greatly increases the tooling and
   fabrication time.
8. Use simple and common parts; use parts that are common to other aircraft such as landing gears, crew
   furnishings, and equipment.
9. Use state-of-the-art materials and structures design; this means the use of technology demonstrators
   during the research phase to fully develop and validate materials and structural concepts before
   committing them to the aircraft.
10. Use proven engines and inlet-nozzle configurations.

The overall design rule is "Keep It Simple."

#### §24.5.2 Design for O&M (p. 649)

The best thing that a designer can do for reduced O&M costs is to design for quick and easy access to
everything. This is difficult and it means a far from optimum packaging in the fuselage and wings. However,
a slightly larger and roomier fuselage, although weighing more and giving lower performance, will pay for
itself in reduced MMH/FH. The MMH/FH is a direct function of accessibility (getting to the faulty or
suspicious item), complexity of the system, and ease of component removal. The designer should recognize
that

- Avionics equipment is always going to need attention
- Hydraulic systems are going to leak
- Fasteners are going to "unfasten"
- Mechanisms are going to wear out and/or need adjusting

so design for the situation. The location of most of the components and the roominess of the equipment
bays are locked-in by the conceptual and early preliminary design.

The early McDonnell F-4s had some communications avionics located beneath the rear seat. Every time the
communications gear needed adjusting (which was about every 3 sorties) the rear ejection seat needed to be
removed and then replaced. This poor design added 2.3 maintenance hours just to gain access to the
avionics equipment [7]. A tightly packed fuselage might be elegant from a design viewpoint but it is a
nightmare for the ground crew as they often have to remove good equipment just to gain access to a faulty
piece of equipment. A good design rule is to only package equipment "one deep."

The McDonnell F-4 and F-15 are aircraft of similar size and weight. The F-15, designed in the early
1970s, emphasized reduced MMH/FH. The primary design solution was to improve the accessibility of the
F-15 over that of the F-4. The result was 570 ft² of access doors and panels on the F-15 compared with
55 ft² on the F-4. This feature was largely responsible for the MMH/FH being reduced from 33 for the F-4
to 22 for the F-15.

The painful compromise that a designer must make between performance and cost must surely be evident by
now. It is paramount that the designer appreciate the importance of cost, otherwise Calvin Coolidge's
recommendation of "buy one aircraft and let the aviators take turns flying it" may someday become a
reality.

## References (p. 650)

[1] "LCC Breakdown," *Aviation Week and Space Technology*, 22 Oct. 2007, p. 23.
[2] Reel, R. E., Totey, C. E., and Johnson, W. L., "Weapon System Support Cost Reduction Study (U),"
Aeronautical Systems Div., Deputy for Development Plans, ASD/XR Rept. 72-49, Wright-Patterson AFB, OH,
June 1972.
[3] Johnson, W. L., and Reel, R. E., "Maintainability/Reliability Impact on System Support Costs," U.S.
Air Force Flight Dynamics Laboratory, AFFDL/PTC, AFFDL-TR-73-152, Wright-Patterson AFB, OH, Dec. 1973.
[4] Hess, R. W., and Romanoff, H. P., "Cost-Estimating Relationships for Aircraft Airframes," Rand Rept.
R-3255-AF, Rand Corporation, Santa Monica, CA, Dec. 1987.
[5] Levenson, G. S., Boren, H. E., Tihansky, D. P., and Timson, F., "Cost Estimating Relationships for
Aircraft Airframes," Rand Rept. R-761-PR, Rand Corp., Santa Monica, CA, Dec. 1971.
[6] Large, J. P., "Estimating Aircraft Turbine Engine Costs," Rand Corp. Rept. RM-6384/1-PR, Sept. 1970.
[7] "R&M Proof," *Aerospace Daily*, Vol. 135, No. 15, 23 Sept. 1985, p. 113.

Chapter 24 extraction complete.

