# Chapter 18 — Cost Analysis

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 18
"Cost Analysis," printed pp. 687–708 (PDF index 718–739).

Mostly statistical cost-estimating relationships (CERs) and narrative guidance; one figure (learning
curve) is a genuine multi-curve design chart, digitized below. Chapter is prose/equation-heavy with
few tables.

---

## §18.1 Introduction

All competing proposals for a new aircraft typically meet the technical requirements, so the customer
often selects on **cost**. Cost estimation is statistical (predicting a new aircraft's cost from
prior aircraft's actual costs), but historical costs are hard to normalize: program stop-starts (e.g.
B-1A→B-1B, with partially-reused tooling and substantial reengineering) corrupt a clean baseline;
politically stretched-out low production rates inflate today's per-unit cost in ways that shouldn't
carry forward; and cost data must be compared in consistent dollars.

**Then-year vs constant-year dollars**: then-year = actual dollars spent each year (needs an inflation
estimate for future years); constant-year = then-year dollars ratioed by inflation factors to one
reference year. Congress budgets in then-year dollars, so most published cost data is then-year, but
cost *comparisons*/baselines should use constant-year dollars. Example [132]: late-1970s then-year
unit costs were $17.6M (F-15) vs $10.8M (F-16) — the F-15 looks like a 60%-more-expensive bargain given
its greater capability. In constant 1978 dollars: $18.8M (F-15) vs $8.2M (F-16) — the F-15 actually
cost 130% more.

Production **quantity/rate** also confounds comparisons via the learning-curve effect (§18.4.1) — a
new-production aircraft isn't comparable to one already built in the hundreds/thousands. Different
**cost groupings** (flyaway vs program vs life-cycle cost) must not be cross-compared without knowing
which grouping each number represents (§18.2).

## §18.2 Elements of Life-Cycle Cost

Analogy: a car's sticker price ignores its ~$50,000 lifetime operating cost (at 50¢/mile over the
car's life) — aircraft life-cycle cost (LCC) similarly dwarfs purchase price.

**Fig. 18.1 — Elements of life-cycle cost** *[Raymer, Fig. 18.1, p. 689]* — nested/stacked box diagram,
box sizes roughly proportional to cost magnitude for a typical aircraft, showing: RDT&E (small);
Production (flyaway cost); together summing to "Procurement" (military) / feeding into purchase price
(civil); Operations and maintenance — by far the largest box, broken into fuel/oil, crew personnel,
ground personnel, maintenance, other indirect costs, depreciation. No numeric axis values (a relative-
proportion schematic, not a plotted curve) — the qualitative takeaway (O&M ≫ everything else) is the
content, not a table of numbers.

- **RDT&E** (research, development, test, evaluation): technology research, design engineering,
  prototype fabrication, flight/ground test, operational-suitability evaluation; includes civil
  certification cost or military Mil-Spec/airworthiness demonstration cost. Fixed (nonrecurring)
  regardless of production quantity; typically <10% of total LCC.
- **Flyaway (production) cost**: labor + material to manufacture (airframe, engines, avionics) +
  production tooling + manufacturer overhead/admin. Recurring, quantity-dependent, reduced per-unit by
  the learning curve. ≈ half of military LCC; a smaller fraction of commercial LCC (commercial
  aircraft fly far more hours, so O&M dominates even more).
- **Purchase price** (civil): set to recover RDT&E + production + profit; RDT&E recovery assumption
  requires an assumed total production quantity.
- **Procurement/acquisition cost** (military): production cost + ground support equipment (simulators,
  test equipment) + initial spares. (Civil: these are usually purchased separately.)
- **Program cost**: total military development+deployment cost, including special facilities (e.g. new
  bomb-proof shelters if a new type's wingspan doesn't fit existing ones) + RDT&E + procurement.
- **Operations and maintenance (O&M)/Operations and Support (O&S)**: fuel, oil, aircrew, maintenance,
  indirect costs (+ insurance for civil). Usually the largest LCC element — much larger than
  development+production for commercial aircraft, roughly equal to them for military.
- **Depreciation** (civil, part of operating cost): allocation of purchase price over a depreciation
  schedule — simplest is straight-line (purchase price / depreciation years). Commercial aircraft
  typically depreciated 12–14 years despite 20+ year useful life.
- **Disposal**: military aircraft retirement/"pickling" and storage (small, often ignored); civil
  aircraft instead have a *negative* disposal cost (resale value, typically ~10% of purchase price,
  highly variable).

## §18.3 Cost-Estimating Methods

Rule of thumb, 2012 USD: small GA aircraft ≈ $200/lb empty weight; airliners/business jets ≈ $800/lb;
older military fighters ≈ $2000/lb; F-22 ≈ $3500/lb; F-35 approaching $5000/lb. Weight is the dominant
cost factor within a class, though speed/avionics/production-rate also matter.

Full-scale-development proposals use a detailed work breakdown structure (WBS, potentially thousands
of tasks) with hours estimated by each functional group — a massive, company-defining effort.
Conceptual design instead uses statistical **cost-estimating relationships (CERs)** — e.g. a simple
linear fit of airliner purchase price vs empty weight gives price ≈ $5M + $550 × (empty weight, lb)
[2012 USD]. CERs are developed like "blind statistics" weight equations (no underlying physics) —
massive normalized cost datasets correlated against design parameters (empty weight, max velocity,
production quantity/rate). CERs preferably predict **labor hours** rather than dollars directly, so
labor-rate/macroeconomic effects can be applied separately.

**DCPR/AMPR weight** ("defense contractors planning report" / "aeronautical manufacturers planning
report" weight, aka "airframe unit weight"): empty weight minus wheels, brakes, tires, engines,
starters, cooling fluids, fuel bladders, instruments, batteries, electrical power supplies/converters,
avionics, armament, fire control, air conditioning, and APU — i.e., only the parts the airframe
manufacturer actually *fabricates* rather than buys and installs (Chapter 15). Typically 60–70% of
empty weight; a better CER weight-basis than raw empty weight. The Air Force's detailed "modular
life-cycle cost model" (MLCCM) and RAND Corp CERs (below) are the standard tools; cost analysts
routinely apply judgment-based fudge factors to bridge CER assumptions vs. the specific new design.

## §18.4 RDT&E and Production Costs

RDT&E and production costs are often combined in CERs since they're historically hard to separate
cleanly (e.g. long-lead production items like landing-gear forgings start before first flight; that
engineering support logically belongs to "production" but is hard to disentangle after the fact).
CER developers also often assume prototype cost follows the production-cost CER (with the learning
curve accounting for the higher prototype cost) — though prototypes, built largely by hand with
simplified tooling, can actually cost much more than the learning curve alone implies.

Best CERs come from a very similar, very recent aircraft — an advantage current producers (e.g.
Boeing, estimating a new jetliner from its own current-aircraft cost data) have over new entrants.
When a detailed cost baseline for a similar aircraft is available, simply multiplying new-aircraft
component weights by that baseline's $/lb or hr/lb (e.g. 50 hr/lb fuselage+subsystems, 90 hr/lb
wings+tails as sample values) can beat a sophisticated CER built from dissimilar aircraft — especially
useful for prototype/demonstrator (X-series) aircraft that production-based CERs estimate poorly.

### §18.4.1 The Learning Curve

Production labor cost per unit falls as cumulative quantity rises (aka "experience curve"). Identified
at Wright-Patterson AFB in the 1930s: costs fell up to 15% each quantity doubling → "85% learning
curve." Later data suggests aircraft production typically follows a 75–85% learning curve (Boeing 727,
first unit to #1000, followed an 80% curve — nearly a perfect straight line on log-log paper). CERs
represent this as production quantity raised to a (negative) statistical exponent.

**Fig. 18.2 — Production learning curve** *[Raymer, Fig. 18.2, p. 694]* — production labor hr per
aircraft vs production quantity `Q`, for the case `Q₁ = 1`. The axes are **linear**, `Q` = 0–1000; the
ordinate is labelled only at `H₁` and `.5×H₁`. Five curves are printed, each labelled with both its
%-learning-curve and its exponent: 95% (`x`=.926), 90% (`x`=.848), 80% (`x`=.678), 70% (`x`=.485),
60% (`x`=.263). The figure prints its own closed form:

```
H = H₁ · (Q/Q₁)^(x−1)        where   2^x = 2 · (% Learning curve / 100)
```

The exponent relation checks out exactly against every printed label: 95% → 2^x = 1.9 → x = 0.926;
90% → 1.8 → 0.848; 80% → 1.6 → 0.678; 70% → 1.4 → 0.485; 60% → 1.2 → 0.263.

`H/H₁` evaluated from that closed form (`Q₁ = 1`), which is what the curves plot:

| Q | 95% (x=.926) | 90% (x=.848) | 80% (x=.678) | 70% (x=.485) | 60% (x=.263) |
|---|---|---|---|---|---|
| 1 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| 10 | 0.843 | 0.705 | 0.476 | 0.306 | 0.183 |
| 100 | 0.711 | 0.497 | 0.227 | 0.0933 | 0.0336 |
| 200 | 0.676 | 0.447 | 0.182 | 0.0653 | 0.0201 |
| 500 | 0.631 | 0.389 | 0.135 | 0.0407 | 0.0103 |
| 1000 | 0.600 | 0.350 | 0.108 | 0.0285 | 0.0062 |

(**Corrected 2026-08-18** against a 300/700-dpi render of book p. 694. The figure is fully legible at
that resolution. Three errors were fixed: the axes are linear, not "log-log-style"; the previous table
did not satisfy its own stated `Q^(x−1)` model — the 500- and 1000-unit columns were 18–45% high and
the 60% column was wrong at Q=10 and Q=100 by factors of 1.2 and 1.6 — and the printed closed form and
the `2^x` definition were not recorded at all. The table above is now computed exactly from the book's
own printed equation, not eyeballed off the curves, which is the more accurate reading for a figure
whose ordinate carries only two labelled gridlines.)

**Book misprint noted**: the figure prints the ratio as `(Q₁/Q)^(x−1)`. With `x < 1` and `Q > Q₁` that
form *increases* with quantity, which contradicts the decreasing curves plotted beside it. The
dimensionally and physically correct form is `(Q/Q₁)^(x−1)`, used above.

The learning-curve effect is more than shop-floor experience — it also reflects *expectation*:
companies investing in efficient dedicated tooling/factories for an expected high-quantity program
(at large upfront cost) get a much lower unit cost if the quantity materializes, but are stuck with
sunk costs if it doesn't (the B-2 program, for Northrop). Some argue modern CNC/3-D-printing
manufacturing is flattening the learning curve (first unit ≈ as efficient as the last), but human
production-line work still shows a real, if reduced, learning effect ("bugs" in the first few dozen
units) — plus the expectation-driven tooling-investment effect persists.

### §18.4.2 RAND DAPCA IV Model

RAND's **DAPCA IV** ("Development and Procurement Costs of Aircraft" model) [133] is a general-purpose
conceptual-design CER set — not the best for any single class, but reasonably good across fighters,
bombers, transports (and, with fudge factors, GA/small UAV). It estimates **hours** by functional group
(engineering, tooling, manufacturing, quality control), each multiplied by an hourly "wrap rate," plus
directly-estimated development-support, flight-test, and manufacturing-material costs.

- **Engineering hours**: airframe design/analysis, test engineering, configuration control, systems
  engineering, and airframe-contractor integration of propulsion/avionics (not the propulsion/avionics
  contractors' own engineering, which is treated as purchased equipment). Mostly RDT&E-phase but some
  continues through production — a 500-aircraft run's total engineering effort is ≈3× a 1-aircraft
  run's.
- **Tooling hours**: tool/fixture design+fabrication, mold/die prep, NC-machining programming,
  production-test-apparatus development, plus ongoing production tooling support.
- **Manufacturing labor**: direct fabrication labor (forming, machining, fastening, subassembly, final
  assembly, routing, purchased-part installation) including subcontractor manufacturing hours.
- **Quality control**: receiving/production/final inspection of tools, subassemblies, and completed
  aircraft (estimated separately though logically part of manufacturing).
- **Development support cost**: RDT&E-phase nonrecurring manufacturing support (mockups, iron-bird
  simulators, structural test articles, etc.) — estimated directly rather than via hours.
- **Flight-test cost**: airworthiness/Mil-Spec-compliance demonstration costs (planning,
  instrumentation, flight ops, data reduction, engineering/manufacturing test support) — *excludes*
  the cost of the flight-test aircraft themselves (those are counted in the production-run cost).
- **Manufacturing materials**: raw structural materials (aluminum, steel, prepreg composite) + electrical/
  hydraulic/pneumatic systems + ECS + fasteners/clamps — essentially everything except engines and
  avionics; can be CFE or GFE.

**Modified DAPCA IV cost model** (quantity term per [133] appendix; costs in 2012 USD)
[Raymer, Eq. (18.1)–(18.9), pp. 696–697]:

```
Engineering hours:  HE = 4.86 We^0.777 V^0.894 Q^0.163        {fps}
                        = 5.18 We^0.777 V^0.894 Q^0.163        {mks}          (18.1)

Tooling hours:      HT = 5.99 We^0.777 V^0.696 Q^0.263        {fps}
                        = 7.22 We^0.777 V^0.696 Q^0.263        {mks}          (18.2)

Mfg hours:          HM = 7.37 We^0.82 V^0.484 Q^0.641          {fps}
                        = 10.5 We^0.82 V^0.484 Q^0.641          {mks}         (18.3)

QC hours:           HQ = 0.076·HM   (cargo airplane)
                        = 0.133·HM   (otherwise)                             (18.4)

Devel support cost: CD = 91.3 We^0.630 V^1.3        {fps}
                        = 67.4 We^0.630 V^1.3        {mks}                    (18.5)

Flt test cost:      CF = 2498 We^0.325 V^0.822 FTA^1.21   {fps}
                        = 1947 We^0.325 V^0.822 FTA^1.21   {mks}              (18.6)

Mfg materials cost: CM = 22.1 We^0.921 V^0.621 Q^0.799   {fps}
                        = 31.2 We^0.921 V^0.621 Q^0.799   {mks}               (18.7)

Engine production cost:
  Ceng = 3112[0.043 Tmax + 243.25 Mmax + 0.969 Tturbine-inlet − 2228]   {fps}
       = 3112[9.66 Tmax + 243.25 Mmax + 1.74 Tturbine-inlet − 2228]     {mks}  (18.8)

RDT&E + flyaway = HE·RE + HT·RT + HM·RM + HQ·RQ + CD + CF + CM + Ceng·Neng + Cavionics   (18.9)
```

where `We` = empty weight (lb or kg); `V` = max velocity (kt or km/h); `Q` = lesser of (production
quantity) or (quantity produced in 5 years); `FTA` = number of flight-test aircraft (typically 2–6);
`Neng` = total production quantity × engines/aircraft; `Tmax` = engine max thrust (lb or kN); `Mmax` =
engine max Mach; `Tturbine-inlet` = turbine inlet temperature (°R or K); `Cavionics` = avionics cost
(estimated separately, DAPCA does not cover it).

**Material fudge factors** (relative to aluminum, applied to the hours estimates above, since DAPCA's
base statistics are an aluminum-aircraft database):

| Material | Fudge factor |
|---|---|
| Aluminum | 1.0 |
| Graphite-epoxy | 1.1–1.8 |
| Fiberglass | 1.1–1.2 |
| Steel | 1.5–2.0 |
| Titanium | 1.1–1.8 |

(More detailed advanced-material CER adjustment methodology: [135]; all such factors "highly
debatable.")

**Wrap rates** (2012 USD/hr, include salary + benefits + overhead/admin — salary alone is roughly
less than half the wrap rate) [133]:

| Group | Wrap rate ($/hr, 2012) |
|---|---|
| Engineering (RE) | 115 |
| Tooling (RT) | 118 |
| Quality control (RQ) | 108 |
| Manufacturing (RM) | 98 |

Predicted then-year costs are ratioed by an economic-escalation factor to a chosen constant-dollar
year (different cost elements can escalate at different rates — e.g. engineer salaries vs. aluminum
raw-material cost). The "Federal Price Deflator for the Aircraft Industry" is the detailed factor;
for student/initial estimates, the Consumer Price Index (CPI) is an adequate proxy.

**Avionics cost** (not covered by DAPCA): estimate from similar-aircraft data or vendor quotes; ranges
5–25% of flyaway cost depending on sophistication, or approximate as $4000–$8000/lb ($9000–$18,000/kg)
in 2012 USD.

**Passenger-interior cost** (not covered by DAPCA — seats, bins, closets, lavatories, insulation,
ceilings/floors/walls) [18]: add per-aircraft $3500/passenger (jet transport), $1700 (regional),
$850 (GA), 2012 USD.

**Overall DAPCA adjustment factors**: DAPCA's underlying database is non-stealth, non-composite
fighters/trainers/transports/bombers — apply ×1.2 for modern designs; DAPCA over-predicts commercial
aircraft cost — apply ×0.9; for GA aircraft, some practitioners report needing to divide by 4 (hard to
credit, but possibly usable for relative trade studies only).

Predicted cost × "**investment cost factor**" (cost of money + contractor profit, proprietary,
roughly 1.1–1.4) → customer purchase price. Initial spares add ~10–15% to purchase price.

## §18.5 Operations and Maintenance Costs

O&M/O&S cost breakdown (rough, highly variable in practice):

**Military**: fuel ≈15% of O&M, crew salaries ≈35%, maintenance ≈50% of the remainder (>1/3 of total
USAF manpower is maintenance).
**Commercial** (many more flight hours/year): fuel ≈38%, crew salaries ≈24%, maintenance ≈25%,
depreciation ≈12%, insurance ≈1%; landing fees add ~2% on top.

### §18.5.1 Fuel and Oil Costs

Actual missions rarely burn all design-mission fuel (loiter/alternate-airport reserves usually land
with fuel remaining). Estimate: typical mission profile → average fuel burn/hour × assumed yearly
flight hours (Table 18.1) × fuel price (from vendor quotes, ratioed to the target year — fuel prices
are volatile: ~$0.80/gal in 1998 → ~$4/gal in 2011, a 30% jump that one year alone). Oil cost <0.5% of
fuel cost, usually ignored.

**Table 18.1 — LCC Parameter Approximations** *[Raymer, Table 18.1, p. 700]*

| Aircraft Class | FH/YR/AC | Crew Ratio | MMH/FH |
|---|---|---|---|
| Light aircraft | 500–1000 | — | 1/4–1 |
| Business jet | 500–2000 | — | 3–6 |
| Jet trainer | 300–500 | — | 6–10 |
| Fighter (modern) | 300–500 | 1.1 | 10–15 |
| Bomber | 300–500 | 1.5 | 25–50 |
| Military transport | 700–1400 | 1.5 if FH/YR<1200; 2.5 if 1200<FH/YR<2400; 3.5 if FH/YR>2400 | 20–40 |
| Civil transport | 2500–4500 | — | 5–15 |

(FH/YR/AC = flight hours per year per aircraft; Crew Ratio = aircrews per aircraft, military only;
MMH/FH = maintenance man-hours per flight hour.)

### §18.5.2 Crew Salaries

**Civil**: statistically based on yearly "block hours" — total in-use time from wheels-off-blocks at
departure to wheels-on-blocks at arrival (taxi, ground hold, flight, holding, ATC delay, gate wait).
Block speed `VB` (trip distance / block time) is substantially below cruise speed. Approximation:
block time ≈ mission flight time + 15 min ground maneuver + 6 min air maneuver [95]. Actual mission
distance exceeds great-circle distance (airliners follow federal airways): +~2% for trips >1400 mi,
+(0.015 + 7/D)% for shorter D. Block hours/year = (block/flight-time ratio for the design mission) ×
(flight hours/year, Table 18.1); for long-range aircraft block ≈ flight hours, but short-range
(sub-1-hr trips) can have block time substantially exceeding flight time.

Crew cost per block hour, from Boeing data via [95] (2012 USD) [Raymer, Eq. (18.10)–(18.11), p. 701]:

```
Two-man crew cost   = 70.4 · ( Vc · W0/10⁵ )^0.3 + 168.8      {fps}
                    = 74.5 · ( Vc · W0/10⁵ )^0.3 + 168.8      {mks}         (18.10)

Three-man crew cost = 94.5 · ( Vc · W0/10⁵ )^0.3 + 237.2      {fps}
                    =  100 · ( Vc · W0/10⁵ )^0.3 + 237.2      {mks}         (18.11)
```
(**Corrected 2026-08-18** against a 300-dpi render of book p. 701: the 0.3 exponent applies to the
whole product `Vc·W0/10⁵`, not to `W0/10⁵` alone — the previous form left `Vc` outside the power, which
changes the result. The symbol is `Vc` (cruise velocity), not `Ve`. Coefficients 70.4 / 74.5 / 94.5 /
100 and the additive 168.8 / 237.2 are all confirmed as printed. `Vc` = cruise velocity [kt or km/h];
`W0` = takeoff gross weight [lb or kg]; output is 2012 dollars per **block** hour.) Real-world variation is
huge — a legacy-carrier senior-captain-heavy 747 crew can cost up to 5× a low-fare-carrier crew.

**Military**: crew cost = (aircraft count) × (crew/aircraft) × (crew ratio, Table 18.1, 1.1 fighters to
3.5 heavily-used transports) × (avg cost/crew member). Absent better data, use the engineering wrap
rate × 2080 hr/yr as a proxy for cost/crew-member.

### §18.5.3 Maintenance Expenses

Unscheduled maintenance: (breakage frequency) × (avg repair cost). Scheduled maintenance: driven by
flight hours (e.g. light-aircraft 100-hr inspections) or, for commercial aircraft, by cycles (flights)
as well. Summarized as **MMH/FH** (maintenance man-hours per flight hour) — the primary "goodness"
metric, roughly proportional to weight (more parts/systems complexity), and strongly affected by
utilization: e.g. civil DC-9 MMH/FH ≈6.4 vs its military C-9 variant (half the flight hours/year) at
≈12. From MMH/FH × flight hours/year → maintenance man-hours/year → labor cost via wrap rate (absent
better data, use the manufacturing wrap rate).

Materials/parts/supplies for maintenance ≈ labor cost for military aircraft. Civil materials cost
per flight-hour and per-cycle [95] (2012 USD; `Ca` = aircraft cost less engine, `Ce` = cost/engine,
`Ne` = number of engines) [Raymer, Eq. (18.12)–(18.13), p. 702]:

```
material cost / FH    = 3.3(Ca/10⁶) + 14.2 + [ 58(Ce/10⁶) − 26.1 ] Ne     (18.12)
material cost / cycle = 4.0(Ca/10⁶) + 9.3  + [ 7.5(Ce/10⁶) + 5.6  ] Ne     (18.13)
```
(**Resolved 2026-08-18** against a 300-dpi render of book p. 702. Both equations are fully legible and
**neither has an fps/mks split** — they are single equations, output in 2012 dollars per flight hour and
per cycle, with `Ca` and `Ce` in dollars. The previous `{fps}` / `{mks}` tags were invented; the
coefficients themselves (3.3, 14.2, 58, 26.1, 4.0, 9.3, 7.5, 5.6) are all confirmed correct, and the
signs on the two bracketed engine terms — minus in 18.12, plus in 18.13 — are as printed.)
Total materials cost/year = (cost/FH × FH/yr) + (cost/cycle × cycles/yr), cycles/yr = total yearly
block time / block time per flight.

### §18.5.4 Depreciation

Straight-line: airframe depreciation/yr = (airframe cost − resale value)/(depreciation years) —
airframe cost = total cost minus engine cost, since airframe and engines depreciate on different
schedules (e.g. resale=10%, 12 yr depreciation → yearly = 0.9×(airframe cost)/12). Engine resale value
usually neglected; engine depreciation/yr = (engine price)/4 yr (typical).

### §18.5.5 Insurance

Commercial insurance ≈ 1–3% of operating cost.

## §18.6 Cost Measures of Merit (Military)

Beyond raw cost, "cost-effectiveness" measures combine cost with mission value. For military
aircraft the ultimate metric is war outcome (via campaign-simulation models comparing outcome-with-
vs-without the new type against total 20-year LCC); simpler proxies: cost per weapon-pound delivered,
cost per target killed (require detailed sortie-rate/survivability/weapons-effectiveness analysis,
beyond this book's scope). Trade studies vary these metrics against payload/turn-rate/etc. In
"design-to-cost" procurements, cost itself is the hard constraint — if the fully-compliant design
costs too much, performance or range must be sacrificed (Chapter 19 discusses further); the designer's
hope is that no competitor manages to satisfy all three (performance, range, cost) simultaneously.

## §18.7 Aircraft and Airline Economics

### §18.7.1 DOC and IOC

Airliner cost-effectiveness is purely economic: revenue must exceed operating cost by enough to beat
alternative investments. **Direct operating cost (DOC)**: fuel, oil, crew, maintenance, depreciation,
insurance, plus landing fees (proportional to landing weight; can approach 1/3 of fuel cost, sometimes
nearly equal to it) and potential future carbon taxes (some estimates: up to 1/4 of airline profits).
DOC is expressed per **seat-mile** (seats × statute miles flown) — current airliners average
6–8 ¢/seat-mile DOC, a standard comparison/trade-study metric.

**Indirect operating cost (IOC)**: ground-facility depreciation, sales/customer service, admin/overhead
— design-independent, airline-operating-model-dependent (e.g. Southwest's low-IOC model vs full-service
carriers), not amenable to statistical estimation; typically 1/3× to 1× of DOC. [136] recommended for
in-depth airliner economics.

**CASM** (cost per available seat-mile) = DOC+IOC combined, a standard airline financial metric —
typical major-airline CASM ≈15¢ (≈4¢ labor, 5¢ fuel, rest "other"), varies widely by airline/year.

### §18.7.2 Airline Revenue

Revenue ≈ ticket sales, roughly proportional to distance (higher per-mile for shorter trips); four
fare classes (first/business/coach/excursion): first ≈2× coach, business ≈1.5× coach, excursion ≈
50–90% of coach. Typical North Atlantic sales mix: 5% first, 15% business, 10% coach, 70% excursion —
weighted-average fare ≈ coach fare. **Load factor** = seats sold / seats available (typically 60–70%);
revenue/seat-mile ≈ (avg fare/mile, ≈ coach fare) × load factor.

### §18.7.3 Break-Even Analysis

**Manufacturer break-even**: sales price = production cost + contribution margin (recovers RDT&E +
cost-of-money + eventual profit); break-even unit count = (RDT&E + cost of money)/(contribution margin
per aircraft). Example: $400M development cost, $2M margin/aircraft → break-even at aircraft #200,
profit thereafter. Pricing tension: too high → insufficient sales; too low → break-even never reached.

**Airline break-even load factor**: operating-cost break-even = (DOC/seat-mile)/(avg fare/seat-mile) —
the load factor at which passenger revenue exactly covers DOC (nothing left for IOC or profit).
Total-cost break-even uses (DOC+IOC)/seat-mile; IOC/seat-mile = (airline's total yearly IOC)/(total
yearly seat-miles flown), roughly ≈ DOC/seat-mile as a rough approximation.

### §18.7.4 Investment Cost Analysis

Airline purchase decision: net present value (NPV) of revenue-minus-cost over the aircraft's useful
life vs. purchase price. **NPV** rests on time-value-of-money: money today is worth more than the same
nominal amount later (it could earn interest or be invested). Future/present value relation [Raymer,
Eq. (18.14)–(18.15), p. 707]:

```
Vn = V0 (1+r)^n                                                          (18.14)
V0 = Vnp = Vn / (1+r)^n                                                   (18.15)
```
(`r` = discount factor/rate.) Airliner NPV = Σ (NPV of each year's operating profit = revenue − DOC −
IOC, excluding depreciation, over the depreciation-period life) + NPV of end-of-life salvage value
(≈10% of purchase price). Investment is worthwhile only if total NPV > purchase price. The discount
rate should exceed safe-investment yields (govt bonds) but be below risky-investment yields; a
practical floor is the airline's own stock's real rate of return (dividends + share appreciation,
over purchase price). Alternatively, solve for the discount rate `r` at which NPV exactly equals the
investment — the **internal rate of return** — and compare it to alternative-investment yields.

## What We've Learned

Cost is the real design measure of merit and, for conceptual design, can be estimated statistically
(CERs) with judgment-based adjustments.

*Illustration: Advanced Tailless Airliner Concept, D. Raymer, 2011 (rendering by A. Ramirez P.),
p. 708 — no plotted data.*

---

*Chapter 18 complete (§§18.1–18.7, Table 18.1, Figs 18.1–18.2, Eqs 18.1–18.15). Fig. 18.1 is a
proportional-box schematic (no numeric axis, not digitized beyond its qualitative ranking).*

*Correctness sweep, 2026-08-18: book pages 694, 696, 697, 698, 700, 701 and 702 were re-rendered at
300–700 dpi and read as images, and the chapter's true section structure was taken from the printed
table of contents (book p. xv) plus the printed section headings on pp. 693, 694, 699–706. All
`[verify]` markers in this chapter are now resolved.*

*Confirmed term by term against the page images — no change needed: the DAPCA IV coefficients and
exponents in Eqs. 18.1, 18.3, 18.4, 18.5, 18.6, 18.7, 18.8 and 18.9; the material fudge-factor table;
the wrap rates (RE=115, RT=118, RQ=108, RM=98); the avionics $4000–$8000/lb and $9000–$18,000/kg
ranges; the interior costs $3500/$1700/$850; the 1.2 and 0.9 overall adjustment factors; Table 18.1
(every cell, including the three-branch military-transport crew ratio); and Eqs. 18.12/18.13's eight
coefficients and both engine-term signs.*

*Corrections applied: Eq. 18.2's mks coefficient (7.22) was missing entirely — the extract had claimed
the fps and mks forms shared one coefficient. Eq. 18.10/18.11 had the 0.3 exponent applied to
`W0/10⁵` alone, where the book applies it to the whole product `Vc·W0/10⁵`. Eq. 18.13 was tagged with a
spurious `{fps}`/`{mks}` split that does not exist in the book. Fig. 18.2's learning-curve table was
replaced with values computed from the figure's own printed closed form, and the axes are linear, not
log-log. Book misprint recorded: Fig. 18.2 prints `(Q₁/Q)^(x−1)`, whose trend is opposite to the
plotted curves; `(Q/Q₁)^(x−1)` is the correct form.*

***Section-numbering correction (systematic).** The extract originally demoted the book's §18.4 RDT&E
and Production Costs to a subsection §18.3.1, which shifted every later section down by one. The
book's contents give §18.4 RDT&E and Production Costs (692), §18.5 Operations and Maintenance Costs
(699), §18.6 Cost Measures of Merit (Military) (703), §18.7 Aircraft and Airline Economics (704), and
the printed headings confirm §18.4.1 The Learning Curve (693), §18.4.2 RAND DAPCA IV Model (694),
§18.5.2 Crew Salaries (700) and §18.5.3 Maintenance Expenses (701). All headings and cross-references
in this file were renumbered to the book's scheme.*

*Next: Chapter 19 — Sizing and Trade Studies.*
