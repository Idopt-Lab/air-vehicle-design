# Chapter 2 — Overview of the Design Process

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA Education
Series, 2018), Chapter 2 "Overview of the Design Process," printed pp. 9–25.

Mostly qualitative process description (requirements sourcing, the three design phases, IPD/IPT
practice); no numbered equations, one bulleted TRL scale, six process-diagram figures (no plotted
numeric data in any of them).

---

## §2.1 Requirements

Aircraft design is iterative, and design requirements are never really fixed — whatever
requirements exist on day one of a project will have changed before the airplane flies (e.g. the
X-31, Fig. 2.1), and an aircraft's roles/missions keep changing well past first flight
[Raymer, p. 9].

Even so, drawing a concept needs firm numbers (wing area, engine size) that can only be calculated
from specific requirements — if a customer hasn't supplied a proper requirements set, the designer
must get some, or invent them [Raymer, p. 9].

Requirements come from several sources/levels:
- **Top-level framework assumptions**: purpose/operation of the aircraft, likely customer/operator,
  development time frame, acceptable technological risk — often so obvious they get overlooked, but
  should be written down explicitly [Raymer, p. 9].
- **Customer-centric mission/performance requirements**: range, payload, speed, and subtler items
  like low observability or fitting an existing parking spot. Civil requirements are typically set
  by the manufacturer from customer input/market analysis/competition study (the company designs,
  then the customer decides to buy); military requirements are set by the customer as RFP
  deliverables, but a company's advanced-design staff usually has to invent a requirements set to
  start its own first layout, because waiting for the customer community to finalize its own would
  mean losing to a competitor already working the problem [Raymer, p. 9–10].
- **Sizing-driving requirements**: for most projects the takeoff gross weight is set by payload
  weight and mission range (the "sizing" calculation of Chapters 3 and 6); engine size and wing area
  are generally set by max speed, stall speed, climb rate, takeoff distance, and similar performance
  items (Chapter 5 and elsewhere) [Raymer, p. 10–11].
- **Cost targets**, explicit or implied — the new design shouldn't cost more than other ways to do
  the same mission; cost goals reflect what the market will bear and can include firm limits set by
  the customer that bound the requirements trade studies [Raymer, p. 11].
- **Specific equipment/dimensional constraints** implied by the mission (bombs, radars, toilets,
  cargo gear) or dictated externally — e.g. the USAF Advanced Tactical Fighter program (→ F-22)
  required all design candidates to fit existing hardened shelters, capping wing span below the
  optimum in some cases [Raymer, p. 11].
- **Legalistic design specifications** — civil/military design specs covering performance, design,
  and operational detail (down to acceptable fuel color), often heavily cross-referenced and
  difficult to interpret; items most relevant to design (landing sink speed, stall speed, structural
  design limits, pilot outside-vision angles, reserve fuel, etc.) are summarized in the book's
  Appendices [Raymer, p. 11]. In the U.S., civil aircraft fall under the FARs (Title 14 CFR),
  chiefly **FAR Part 23** (normal/utility/acrobatic/commuter category) and **FAR Part 25**
  (transport category); the EU's EASA CS (Certification Specifications) mirror the FARs' numbering,
  with an ongoing effort to harmonize the two completely [Raymer, p. 11]. The U.S. military uses
  Mil-Specs/Mil-Standards — e.g. MIL-C-8785 (aerodynamics/stability/control), MIL-F-87858 (flying
  qualities), MIL-A-8860 (structural loads), MIL-A-8861–8864/8870 (strength and rigidity) — many of
  which have since been "deactivated" in favor of commercial practice or contractor trust to cut
  compliance cost (e.g. the old MIL-STD-1374 weight/balance reporting spec is now administered by
  the Society of Allied Weight Engineers as SAWE's SAWES) [Raymer, p. 11–12].
- **Company design experience** — proprietary design handbooks and best practices built up over a
  company's history; their absence is a serious barrier to entry for a new aircraft company (no
  handbooks) [Raymer, p. 12].

Raymer cautions against over-relying on requirements-definition tools such as the "House of
Quality": useful in moderation early on, but easily devolving into a consolidated-guesswork exercise
(e.g. rating "is high aspect ratio important for range" 1–10) without any actual layout to ground
the answer against competing concerns like weight or ground clearance. His recommendation: get to
an initial layout quickly, using it (and the real numbers it produces) to assess relative importance
and finalize requirements, rather than trying to fully settle requirements on paper first
[Raymer, p. 12].

### Fig. 2.1 — X-31 design: early layout to final configuration
*[Raymer, Fig. 2.1, p. 10]* — Multi-view comparison sketch of the X-31 concept as it evolved from
an early layout to the final configuration during the concept development phase Raymer himself led.
Illustrative photo/sketch sequence, no plotted data.

## §2.2 Phases of Aircraft Design

Aircraft design breaks into three major phases (Fig. 2.2): **Conceptual Design**, **Preliminary
Design**, and **Detail Design**, followed by fabrication [Raymer, p. 12–13].

### Fig. 2.2 — Three phases of aircraft design
*[Raymer, Fig. 2.2, p. 13]* — Flow diagram, three stacked boxes:
- **Conceptual Design**: What requirements drive the design? What should it look like? Weight?
  Cost? What tradeoffs/technologies? Do the requirements produce a viable, salable airplane?
- **Preliminary Design**: freeze the configuration; develop lofting (surface definition); develop
  test/analytical database; design major items; develop an actual (statistical) cost estimate —
  "you bet your company!"
- **Detail Design**: design the actual pieces to be built; design tooling/fabrication process; test
  major items (structure, landing gear, ...); finalize weight and performance estimates — "NOW you
  learn the real numbers!"

  → **Fabrication**. Diagram only, no plotted data.

### §2.2.1 Conceptual Design

The focus of the book. Conceptual design answers the basic questions of configuration arrangement,
size/weight, and performance, and is characterized by many design alternatives, continuous trade
studies, and evolutionary change. The central question: *can any affordable aircraft be built that
meets the requirements?* — if not, requirements themselves may need revision/relaxation
[Raymer, p. 13].

Configuration design during this phase is not deep in detail (e.g. landing gear may be no more than
a circle-and-stick sketch), but the *interactions* among components are what matter, and getting
that right takes years of design experience [Raymer, p. 13–14]. The design layout is constantly
revised as understanding grows and trade studies mature — essentially week-by-week — touching
everything from wing geometry to tail arrangement to engine count. Multiple alternative
configurations are typically carried in parallel (e.g. canard vs. aft-tail vs. tailless) and let the
numbers, not opinion, pick a winner [Raymer, p. 14]. This "everything changes constantly" nature of
conceptual design is a poor fit for high-end production-oriented CAD systems, discussed further
later in the chapter [Raymer, p. 14].

Conceptual design can take anywhere from a week (done poorly) to several years; a major program
typically spends about six months studying requirements/technologies/configuration alternatives
before down-selecting to a best concept [Raymer, p. 14].

### Fig. 2.3 — Design phases: front wing spar
*[Raymer, Fig. 2.3, p. 14]* — Three stacked panels showing the same front wing spar at increasing
levels of design detail: (top) **conceptual design** — spar is just a line from root to tip,
assumed to span the airfoil depth at that station; (middle) **preliminary design** — actual spar
cross-section shape is defined and structurally sized (thickness or composite ply count) for
expected loads; (bottom) **detail design** — full buildable definition with attachments, cutouts,
access panels, flanges, and manufacturing/fuel-sealing detail. Illustrative geometry progression,
no plotted data [Raymer, p. 14–15].

The example illustrates the general point: conceptual-design-level detail is intentionally crude
because the whole-aircraft arrangement (not any one part's exact geometry) is what's being decided;
this level of definition is enough to answer questions like wing-box, wing-fuel-tank, and
leading-edge-flap sizing envelopes [Raymer, p. 15].

### §2.2.2 Preliminary Design

Begins once the big configuration questions (e.g. canard vs. aft tail) are resolved and the general
arrangement is expected to hold, with only minor revisions. Characterized by growing maturity,
detail, and confidence over many months. At some point the company "freezes" the design — a crucial
milestone letting structures/subsystems designers proceed without fear their work will be
invalidated by later configuration changes [Raymer, p. 15].

During preliminary design, structures/landing-gear/control-system specialists design and analyze
their portions; serious aerodynamics/propulsion/structures/stability-and-control testing begins;
a mockup (physical or CAD-electronic, walkable in 3-D goggles/gloves) may be built. A key activity is
**lofting**: mathematically modeling the outer skin surface precisely enough that parts designed and
even fabricated in different locations still fit together — a term/technique originating in
shipyards (done with flexible "spline" rulers in a "loft" over the yard); covered in Chapter 7
[Raymer, p. 15].

Preliminary design's end goal is readiness for detail design (full-scale development, FSD),
typically via an FSD proposal — informally "you bet your company," since a contract overrun or lost
sale can exceed the firm's net worth. In the wing-spar example, preliminary design refines the
overall spar geometry into an actual (still not buildable) cross-section shape, sized structurally
but without attachments/cutouts/manufacturing detail (Fig. 2.3, middle) [Raymer, p. 15–16].

Preliminary design duration ranges from a few months (done poorly) to ~2 years for a complex,
high-tech design (e.g. supersonic transport, stealth fighter) — supersonic wind-tunnel test-modify-
retest cycles alone can take many months [Raymer, p. 16]. CAD tools here must support rapid
reshaping of the overall configuration while still supporting production-quality surface definition,
plus geometry access-management as the design team grows [Raymer, p. 16].

### §2.2.3 Detail Design

Begins once FSD is approved. The actual buildable parts — every individual structural component and
system (landing gear, hydraulic, electrical, pneumatic, fuel, propulsion, etc.) — are designed down
to exact cutout radii and fastener-hole locations, plus all the "little pieces" not previously
considered (flap tracks, brackets, clips, doors, avionics racks) [Raymer, p. 16–17].

Parts counts are large — a fighter has several hundred thousand parts; a big airliner has several
million parts (plus fasteners) and hundreds of miles of wiring — so the small conceptual/preliminary
team is augmented or replaced by hundreds to thousands of engineers; most aerospace engineers
actually work in preliminary or detail design rather than conceptual design [Raymer, p. 17].

**Production design** (how the airplane will actually be fabricated, subassembly by subassembly) is
also a detail-design task; production designers often want manufacturing-driven modifications that
can affect performance/weight, forcing compromises while still meeting the original requirements.
(Historically, the former Soviet Union used a wholly separate production design bureau — usually
better producibility, at some performance/weight cost [Raymer, p. 17].) Testing intensifies:
structure is fabricated and tested, flight control laws run on an "iron-bird" simulator, and flight
simulators are flown by company and customer test pilots. Modern high-end CAD (Solidworks, Siemens
NX, Creo Elements/Pro, CATIA) is well suited to this stage's "little pieces" and production-feature
definition, and its database feeds computer-aided manufacturing directly [Raymer, p. 17].

Detail design ends with fabrication; schedule pressure sometimes forces some parts into fabrication
before detail design is fully complete, risking expensive late changes to already-built parts/tools
[Raymer, p. 17–18]. Prototypes are often built on cheaper "soft"/temporary tooling with different
fabrication processes than the eventual production run — cheaper up front, but risks missing
production problems; using production tooling from the start (e.g. Mitsubishi F-2, an F-16
derivative) surfaces production issues earlier and can reduce total program cost despite higher
initial cost [Raymer, p. 18]. Production itself begins with tooling design/fabrication — historically
a massive, expensive undertaking of jigs and fixtures, with an ongoing cost-reduction trend toward
CAM technology and innovative design to minimize hard tooling [Raymer, p. 18].

## §2.3 Aircraft Conceptual Design Process

Conceptual design begins from the requirements described in §2.1 — customer-supplied or
company-guessed. Occasionally a design starts from an innovative idea rather than a stated
requirement (John Northrop pursued the flying wing for years as his own idea of "the better
airplane," well before it was matched to a specific Army Air Corps requirement) [Raymer, p. 18].

A key upfront decision is which **technologies** to incorporate: near-term aircraft must rely on
currently available technology/engines/avionics; more distant designs require estimating future
state-of-the-art readiness. (E.g., as of 2018, no aircraft with fully all-electric actuators had
entered production, though the technology was considered low-risk after successful flight
demonstration; active laminar-flow-control-by-suction, despite a strong analytical/flight-test
payoff, was considered too risky for near-term transport-jet adoption.) An overly optimistic
technology estimate yields a lighter/cheaper design at higher development risk; relying only on
"yesterday's technology" yields a heavy, underperforming, unsellable airplane [Raymer, p. 18].

To make risk arguments objective rather than self-serving ("our concept is low risk"), NASA/DoD
define the **Technology Readiness Level (TRL)** scale [Raymer, p. 18–19]:

### TRL scale
*[Raymer, p. 19–20]* — all nine rows confirmed word-for-word 2026-08-18 against 320-dpi renders of
book pp. 19–20 (TRL 1–7 print on p. 19, TRL 8–9 continue on p. 20).

| TRL | Description |
|---|---|
| 1 | Basic principles observed and reported |
| 2 | Technology concept and/or application formulated |
| 3 | Analytical and experimental function or characteristic proof-of-concept |
| 4 | Component and/or breadboard validation in laboratory environment |
| 5 | Component and/or breadboard validation in relevant environment |
| 6 | Model or prototype demonstration in a relevant environment |
| 7 | System prototype demonstration in an actual environment |
| 8 | Actual system completed and qualified through test and demonstration |
| 9 | Actual system proven through successful mission operations |

### Fig. 2.4 — Aircraft conceptual design process
*[Raymer, Fig. 2.4, p. 19]* (box-by-box confirmed 2026-08-18 against a 320-dpi render) — Flow diagram: **Design requirements** + **Technology availability**
→ **Concept sketch** (fed also by "new concept ideas," with a feedback loop for "requirements
trade-offs") → **First-guess sizing** → **Initial layout** → **Initial analysis** (aerodynamics,
weights, propulsion) → **Sizing & performance optimization** → **Revised layout** → **Analysis**
(aerodynamics, weights, propulsion, stability & control, structures, cost, subsystems, etc.) →
**Refined sizing & performance optimization** → feeds into **Preliminary design**. Process/workflow
diagram, no plotted numeric data.

The conceptual effort itself usually starts with a **conceptual sketch** (Fig. 2.5) — the "back of
a napkin" drawing giving a rough sense of the design: approximate wing/tail geometry, fuselage
shape, and internal locations of major components (engine, cockpit, payload/passenger compartment,
landing gear, fuel tanks) [Raymer, p. 20]. The sketch supports estimating aerodynamics and weight
fractions by analogy to prior designs, feeding a first-cut total/fuel weight estimate via "sizing"
(the sketch may be skippable if the new design closely resembles an existing one) [Raymer, p. 20].
(Both page citations corrected 2026-08-18 from p. 19 to p. 20 — this prose prints on p. 20,
alongside Fig. 2.5.)

### Fig. 2.5 — Initial sketch
*[Raymer, Fig. 2.5, p. 20]* — Freehand conceptual sketch labeled "Supercruise lightweight fighter,"
showing rough external lines and internal component placement. Illustrative sketch, no plotted
data.

Initial sizing then drives an **initial design layout** (Fig. 2.6) — a three-view drawing with the
more important internal-arrangement detail (landing gear, payload/passenger compartment,
engines/inlet ducts, fuel tanks, cockpit, major avionics), with enough cross-sections shown to
verify everything fits [Raymer, p. 19–20]. On a drafting table this is drawn at a convenient scale
(1/10, 1/20, 1/40, 1/100); on CAD it's normally done full-scale numerically [Raymer, p. 21].

### Fig. 2.6 — Configuration layout
*[Raymer, Fig. 2.6, p. 21]* — Detailed three-view (plan/side/front) layout drawing with internal
component cross-sections and hand-lettered notes. Illustrative layout drawing, no plotted data.

✓ Resolved 2026-08-18 against a 320-dpi render. Three fixes: the figure is on book **p. 21**, not
p. 20 (p. 20 carries Fig. 2.5, "Initial sketch"); the printed caption is simply **"Configuration
layout."**; and the drawing carries **no aircraft type name** — so there is nothing to recover, and
the earlier `[verify]` flag was chasing a label the book never prints. The subject is a twin-boom,
canard, single-pusher-propeller design; its legible notes read "COMPOSITE WING BOX", "CONSTANT CROSS
SECTION", "CONSTANT CHORD WING AND CANARD SWEPT FORWARD 22 deg FOR ELLIPTICAL LIFT DISTRIBUTION",
"OUTER WING AND CANARD PANELS ARE GEOMETRICALLY IDENTICAL EXCEPT FOR SCALE", "FUEL", "3-MAN CREW"
and "12 deg STATIC TAIL DOWN GROUND ANGLE". Stations run 0–1347 (inches).

This initial layout is analyzed to check whether it can really fly the mission implied by the
first-order sizing: actual aerodynamics, weights, and installed propulsion characteristics feed a
detailed sizing calculation, and calculated performance is compared against requirements.
Optimization then finds the lightest/lowest-cost aircraft meeting both the mission and all
performance requirements, producing a better total/fuel-weight estimate and required
engine/wing-size revisions — which usually means a new/revised layout, and the cycle repeats
[Raymer, p. 21].

> **Sidebar — "Design Is Iterative — You Never Build the Dash-One" (p. 21).** Industry gives each
> project drawing a project/drawing number (e.g. D645-5); the very first drawing (D645-1) is the
> "Dash-One." The Dash-One is never built — it is only a tool for making the Dash-Two, which is a
> tool for the Dash-Three, and so on; a Dash-50 is not unheard of before the design that will
> actually be built is locked in.

Each revised drawing, after some number of iterations, is examined by an ever-expanding group of
specialists (e.g. controls experts running a six-DOF analysis to check control-surface sizing,
instructing the designer to enlarge a surface if inadequate, which the designer must then fit in
without breaking something else like flaps or landing gear) [Raymer, p. 21]. The end product is a
design ready to confidently pass into preliminary design — further changes should be expected there,
but not major ones if conceptual design succeeded. Preliminary design is essentially a continuation
of the same "revised layout" iteration loop (right side of Fig. 2.4), now down-selected to one
concept and using more sophisticated/expensive tools (CFD, FEM, 6-DOF, wind tunnel) with a larger
team (a handful of people up to 50+ in a large company), repeating: analyze the baseline, find
problems, find solutions, optimize/simplify/verify, redraw, repeat until "enough!" [Raymer, p. 21–22].

CAD tools for conceptual design should support rapid (about one-day) notional-concept development and
continuous revision/geometric trade studies — rivet-location or cutter-path tools are worthless here,
but a tool that changes wing sweep and automatically updates spar/rib geometry accordingly is highly
valuable, since sweep will likely change after every optimization study or wind-tunnel test
[Raymer, p. 22].

## §2.4 Integrated Product Development and Aircraft Design

Aircraft design today is commonly done via **Integrated Product Development (IPD)**, executed by
**Integrated Product Teams (IPT)**. Per the USAF Materiel Command Guide, IPD is "a philosophy that
systematically employs a teaming of functional disciplines to integrate and concurrently apply all
necessary processes to produce an effective and efficient product that satisfies customer's needs"
[Raymer, Ref. 4, p. 23]. IPD rejects traditional hierarchical/bureaucratic engineering-org structure,
pushing decisions to the lowest possible level; collocated, multidisciplinary IPTs bring design,
engineering, production, operations, and customer representatives together to develop new products
up to and including whole new aircraft [Raymer, p. 23].

IPTs resemble the old "project" side of matrix management — a well-run legacy project already
collocated a diverse specialist group, communicated with customers constantly, and single-mindedly
pursued the best product. What often blocked that in the past: functional department heads
preferring to keep their people together (no collocated project home), difficulty budgeting for
production/operations experts early ("bring them in later"), and design micromanagement from above
by people unaware of the real tradeoffs, which demoralized teams and de-optimized designs. IPD/IPT
practice explicitly fixes these problems and is now near-universally adopted in industry
[Raymer, p. 23–24].

Kelly Johnson (Lockheed Skunk Works, F-104/SR-71) championed a "strong but small" project office with
real authority for the project manager/team, free of micromanagement — but warned against "design by
committee — reviews and recommendations, conferences and consultations, by those not directly doing
the job. Nothing very stupid will result, but nothing brilliant either. And it's in the brilliant
concept that a major advance is achieved" [Raymer, Ref. 5, p. 24]. Raymer stresses an IPT should not
substitute for, or tie the hands of, an experienced configuration designer on judgment calls within
their expertise (e.g. flutter risk is not decided by team vote) — but that designer benefits from,
and should draw on, the team's collective knowledge, and a collocated team with a shared goal
iterates and trades faster and more creatively [Raymer, p. 24].

**Concurrent engineering** is a core IPT practice. Historically, product development was serial:
advanced design created a concept through conceptual/preliminary design, then "threw it over a wall"
to detail design, then again to manufacturing — who then asked "how can I build this stupid
thing?!" With concurrent engineering, detail-design and production personnel join at the earliest
design stages within the IPT, reducing manufacturing cost and improving quality with fewer
production-stage engineering changes, at the cost of somewhat higher up-front spend (worthwhile
long-run, per Raymer) [Raymer, p. 24]. In an extreme form (routine in the automotive industry, where
part geometry changes little between model years — e.g. a fender-stamping die can be revised at the
last minute from known-similar prior contours), a production designer might be developing tooling
concurrently with a not-yet-finalized aircraft design; aircraft aren't cars and wings aren't fenders,
but early involvement of detail-design/production staff is still beneficial [Raymer, p. 25].

## What We've Learned (chapter close, p. 25)

Design is done in three phases: conceptual, preliminary, and detail. It starts with requirements,
but they evolve as you learn more. And remember: you never build the Dash-One.

---

*Chapter 2 extraction complete (§§2.1–2.4, Figs. 2.1–2.6, TRL scale table, References [4]–[5], no
numbered equations — chapter is process/qualitative prose per the source's own scope).*
