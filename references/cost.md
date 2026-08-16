---
layout: default
title: Cost & Value
nav_order: 10
permalink: /cost/
---

# Cost & Value
{: .no_toc }

Development and production cost, direct operating cost, and the value argument that
decides whether a design is worth building.

1. TOC
{:toc}

---

## Topic: Development & Production Cost (DPC)

### Primary References

1. **CST-DPC-P01** — [DAPCA: A Computer Program for Determining Aircraft Development and Production Costs](https://www.rand.org/content/dam/rand/pubs/research_memoranda/2006/RM5221.pdf)
   Boren, H. E., Jr., *DAPCA: A Computer Program for Determining Aircraft Development and
   Production Costs*, RM-5221-PR, RAND Corporation, Santa Monica, CA, 1967. 93 pp.
   The original DAPCA. Every "RAND DAPCA-IV" cost model in every design textbook descends
   from this. Inputs are physical characteristics — gross takeoff weight, speed, engine
   type and count, thrust. Appendices give the full costing equations, flowcharts, and the
   FORTRAN IV source. Worth reading to see what the modern cost equations are actually
   approximating.
   Landing page: [rand.org/pubs/research_memoranda/RM5221.html](https://www.rand.org/pubs/research_memoranda/RM5221.html)
   `Open`

### Secondary References

1. **CST-DPC-S01** — [A Computer Model for Estimating Development and Procurement Costs of Aircraft (DAPCA-III)](https://www.rand.org/pubs/reports/R1854.html)
   Boren, H. E., Jr., R-1854-PR, RAND Corporation, 1976.
   The third-generation model. Closer to the cost estimating relationships you will find
   reproduced in Raymer and Nicolai.
   `Open`

2. **CST-DPC-S02** — [Aircraft Airframe Cost Estimating Relationships](https://apps.dtic.mil/sti/tr/pdf/ADA212920.pdf)
   Resetar, S. A., Rogers, J. C., and Hess, R. W., *Advanced Airframe Structures Materials:
   A Primer and Cost Estimating Methodology*, R-3255-AF, RAND Corporation.
   DTIC accession ADA212920.
   Airframe CERs with material effects broken out — relevant if your design uses a
   significant composite or titanium fraction and you need to defend the cost penalty.
   `Open`

---

## Topic: Direct Operating Cost (DOC)

### Primary References

1. **CST-DOC-P01** — [Aircraft Cost Estimations (Jenkinson)](http://wpage.unina.it/fabrnico/DIDATTICA/PGV_2012/MAT_DID_CORSO/08_Prestazioni/DOC_Jenkinson.pdf)
   Jenkinson, L. R., Simpkin, P., and Rhodes, D., "Aircraft Cost Estimations," in
   *Civil Jet Aircraft Design*, Arnold / AIAA Education Series, 1999.
   ISBN 978-0-340-74152-8. doi:10.2514/4.473500. 24 pp.
   The most directly usable DOC method for a student project: complete, self-contained,
   with a specimen calculation and reference data explicitly intended for student work.
   Covers the main DOC elements and touches indirect costs. **Start here.**
   {: .warning }
   > Scan of a copyrighted textbook hosted on a university course page. Cite the book.
   > [Publisher listing](https://arc.aiaa.org/doi/10.2514/4.473500)

   `Open`

### Secondary References

1. **CST-DOC-S01** — [Comparative Analysis on Aircraft Direct Operating Cost Models](https://doi.org/10.2514/6.2025-3499)
   Espinosa-Juárez, E., Jouannet, C., Amadori, K., and Sánchez Mata, A., "Comparative
   Analysis on Aircraft Direct Operating Cost Models," AIAA Paper 2025-3499,
   *AIAA AVIATION Forum and ASCEND*, Las Vegas, NV, 21–25 July 2025. 25 pp.
   doi:10.2514/6.2025-3499
   Reviews nine DOC models and shows how far apart their estimates are — important context
   before you quote a single DOC number to three significant figures. Proposes a model for
   smaller and electrified aircraft, adding battery depreciation and degradation, amortized
   interest, SAF blending and carbon tax.
   `Publisher`

2. **CST-DOC-S02** — [Evaluating hybrid-electric aircraft viability: The Ampaire Eco Caravan cost analysis](https://doi.org/10.1016/j.trd.2025.104759)
   Cusati, V., Di Stasio, M., Lucci, G., and Zhang, Q., "Evaluating hybrid-electric aircraft
   viability: The Ampaire Eco Caravan cost analysis," *Transportation Research Part D:
   Transport and Environment*, Vol. 144, 2025, Art. 104759.
   doi:10.1016/j.trd.2025.104759
   Full DOC analysis of a real hybrid-electric retrofit (Cessna 208B Grand Caravan). Fuel
   and emissions down ~50%, operating costs down 9%, but acquisition cost pushes total DOC
   *up* 3%. A clean worked example of why a technology that improves every physical metric
   can still fail the business case. **Open access (CC BY).**
   `Open`

3. **CST-DOC-S03** — [Air Cargo Economics](https://ocw.mit.edu/courses/16-886-air-transportation-systems-architecting-spring-2004/resources/06cargo_econmics/)
   Clarke, J.-P., *Air Cargo Economics*, Lecture 6, 16.886 Air Transportation Systems
   Architecting, MIT, 24 February 2004. MIT OpenCourseWare.
   DOC from the operator's side for cargo operations. See also
   [Operations, Market & Environment]({{ site.baseurl }}/operations-environment/).
   `Open`

---

## Topic: Life-Cycle Cost & Value (LCV)

### Primary References

1. **CST-LCV-P01** — [Cost and Financial Analysis](https://ocw.mit.edu/courses/16-885j-aircraft-systems-engineering-fall-2004/dfeae3bb47e8b5e6b562a0159ee2cccb_pres_willcox.pdf)
   Willcox, K., *Cost Analysis*, Lecture 4, 16.885J Aircraft Systems Engineering, MIT,
   Fall 2004. MIT OpenCourseWare. 51 pp.
   Lifecycle cost, operating cost, development cost, manufacturing cost and revenue
   valuation in one lecture, framed around the design decisions that drive each. The
   clearest short overview of the whole cost picture.
   `Open`

2. **CST-LCV-P02** — [Design of Aircraft for Best Value](https://doi.org/10.2514/1.C036012)
   Bevilaqua, P. M., "Design of Aircraft for Best Value," *Journal of Aircraft*, 2021.
   doi:10.2514/1.C036012. 12 pp.
   The argument for why "maximum performance" and "minimum cost" are both wrong objectives.
   Uses operations analysis and parametric costing to weigh added performance against its
   cost, including the hidden cost of buying fewer aircraft when unit cost rises. Written by
   the designer of the F-35B lift-fan system.
   `Publisher`

### Secondary References

1. **CST-LCV-S01** — [COCOMO: A procedural cost estimate model for software projects](https://medium.com/@warakornjetlohasiri/cocomo-a-regression-model-in-procedural-cost-estimate-model-for-software-projects-65ab5222a1f5)
   Jetlohasiri, W., "COCOMO: A procedural cost estimate model for software projects."
   Overview of Boehm's COCOMO model — organic, semi-detached and embedded project classes,
   and the effort/schedule relations. Relevant because avionics and mission-system software
   is now a large and frequently underestimated share of development cost. See also the
   [Wikipedia article on COCOMO](https://en.wikipedia.org/wiki/COCOMO) and Boehm, B. W.,
   *Software Engineering Economics*, Prentice-Hall, 1981.
   `Open`

2. **CST-LCV-S02** — Airframe Development Cost Calculator (CSGNetwork)
   Online DAPCA-style airframe development cost calculator.
   {: .warning }
   > The host `csgnetwork.com/airframedevcalc.html` is no longer reachable. Use CST-DPC-P01
   > directly, or the DAPCA-IV equations as reproduced in Raymer.

   `Citation only`
