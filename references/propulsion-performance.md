---
layout: default
title: Propulsion & Performance
nav_order: 7
permalink: /propulsion-performance/
---

# Propulsion & Performance
{: .no_toc }

Engine selection data, thrust models you can actually curve-fit, and the performance
calculations they feed.

1. TOC
{:toc}

---

## Topic: Engine Data & Selection (ENG)

### Primary References

1. **PRP-ENG-P01** — The Engine Handbook, 2014 Edition
   Directorate of Propulsion, Air Force Life Cycle Management Center (AFLCMC/LPZ),
   *The Engine Handbook*, 2014 Edition, Revision 2.0, U.S. Air Force. 88 pp.
   Reference data for the USAF turbine engine inventory — thrust class, application,
   physical dimensions and program status by engine. The standard starting point when
   choosing an existing production engine to meet an RFP constraint. No public copy
   located; the [AFLCMC Propulsion Directorate](https://www.aflcmc.af.mil/WELCOME/Organizations/Propulsion-Directorate/)
   is the originating office.
   `Citation only`

2. **PRP-ENG-P02** — Aircraft Engine Handbook, 1992
   Naval Air Systems Command, *Aircraft Engine Handbook*, U.S. Navy, 1992. 244 pp.
   Navy counterpart to PRP-ENG-P01, covering the naval engine inventory of the period.
   Still useful for legacy engines that remain in service. No public copy located.
   `Citation only`

### Secondary References

1. **PRP-ENG-S01** — [Thrust Data for Performance Calculations](https://onlinelibrary.wiley.com/doi/10.1002/9780470117859.app4)
   Saarlas, M., "Appendix D: Thrust Data for Performance Calculations," in
   *Aircraft Performance*, John Wiley & Sons, Hoboken, NJ, 2007.
   ISBN 978-0-470-04416-2. doi:10.1002/9780470117859.app4
   Engine decks for ten representative engines — J60, J52, JT9D-3, JT8D-9, TF30, TFE731-2,
   GE F404-400, FJ44, Allison T56 turboprop and an AVCO Lycoming unit — presented as
   curve-fits of thrust versus altitude and velocity. Exactly the form you need for a
   performance code when you cannot get a real deck.
   `Publisher`

---

## Topic: Thrust Modelling (THR)

### Primary References

1. **PRP-THR-P01** — [Measurement Effects on the Calculation of In-Flight Thrust for an F404 Turbofan Engine](https://ntrs.nasa.gov/api/citations/19900002425/downloads/19900002425.pdf)
   Conners, T. R., *Measurement Effects on the Calculation of In-Flight Thrust for an F404
   Turbofan Engine*, NASA TM-4140, NASA Dryden Flight Research Facility, 1989. 25 pp.
   NTRS citation: [19900002425](https://ntrs.nasa.gov/citations/19900002425)
   In-flight thrust calculation for the F404-GE-400 as flown on the X-29A, using the
   mass flow–temperature and area–pressure gas generator methods. Includes net thrust
   uncertainty and influence coefficients — read it for how much you should trust a thrust
   number, not just how to compute one.
   `Open`

---

## Topic: Aircraft Performance (PER)

### Secondary References

1. **PRP-PER-S01** — [Aircraft Performance](https://www.wiley.com/en-us/Aircraft+Performance-p-9780470044162)
   Saarlas, M., *Aircraft Performance*, John Wiley & Sons, Hoboken, NJ, 2007.
   ISBN 978-0-470-04416-2.
   Parent text for PRP-ENG-S01. Standard treatment of the performance equations —
   takeoff, climb, cruise, turn, and range/endurance — at the level a conceptual design
   report needs.
   `Publisher`

2. **PRP-PER-S02** — [Advanced Aircraft Flight Performance](https://doi.org/10.1017/CBO9781139161893)
   Filippone, A., *Advanced Aircraft Flight Performance*, Cambridge Aerospace Series,
   Cambridge University Press, Cambridge, 2012. doi:10.1017/CBO9781139161893
   Performance past the textbook equations: flight envelopes, mission analysis, fuel
   planning, noise and emissions trajectories. Go here when a reviewer asks what your
   aircraft does off the design point. Raj's list gives an AIAA imprint and 1996 date for
   this title; the Cambridge edition above is the one that exists.
   `Publisher`

---

## Topic: Propulsion Texts (TXT)

*Aircraft Engine Design* (Mattingly, Heiser and Pratt) is a core text for this course and
is listed on the Foundations page as
[FND-TXT-P03]({{ site.baseurl }}/foundations/) — go there for engine constraint and
mission analysis. The references below support it.

### Primary References

1. **PRP-TXT-P01** — [Elements of Propulsion: Gas Turbines and Rockets](https://doi.org/10.2514/4.103711)
   Mattingly, J. D., *Elements of Propulsion: Gas Turbines and Rockets*, 2nd ed., AIAA
   Education Series, AIAA, Reston, VA, 2016. doi:10.2514/4.103711
   (1st ed., 2006, doi:[10.2514/4.861789](https://doi.org/10.2514/4.861789).)
   Where the engine cycle comes from. For a conceptual design the payoff is parametric
   cycle analysis: it tells you which of the numbers on an engine deck are physically
   linked, so you know what you may and may not scale independently.
   VT access: [Knovel (VT sign-in)](https://app-knovel-com.ezproxy.lib.vt.edu/web/view/khtml/show.v/rcid:kpEPGTR002/cid:kt0046LK6H/viewerType:khtml//root_slug:1-introduction/url_slug:introduction-2)
   `Publisher`

### Secondary References

1. **PRP-TXT-S01** — [Aircraft Propulsion Systems Technology and Design](https://doi.org/10.2514/4.861499)
   Oates, G. C. (ed.), *Aircraft Propulsion Systems Technology and Design*, AIAA Education
   Series, AIAA, Washington, DC, 1989. doi:10.2514/4.861499
   Edited volume on propulsion system *integration* — installation losses, inlet and nozzle
   matching, and the design and development process for an engine programme. The chapter on
   propulsion/airframe integration is the relevant one for a configuration study.
   VT access: [Knovel (VT sign-in)](https://app-knovel-com.ezproxy.lib.vt.edu/web/toc.v/cid:kpAPSTD00K/viewerType:toc/root_slug:aircraft-propulsion-systems)
   `Publisher`

2. **PRP-TXT-S02** — [Intake Aerodynamics](https://doi.org/10.2514/4.473616)
   Seddon, J., and Goldsmith, E. L., *Intake Aerodynamics*, 2nd ed., AIAA Education Series,
   AIAA, Reston, VA / Blackwell Science, 1999. doi:10.2514/4.473616
   The reference on inlet design and the pressure recovery your installed thrust depends on.
   Necessary if your design is supersonic, has a buried or S-duct inlet, or puts the intake
   anywhere the flow is not clean — all of which are configuration decisions you make on the
   three-view.
   VT access: [VT Libraries (VT sign-in)](https://virginiatech.primo.exlibrisgroup.com/permalink/01VT_INST/st7rnq/alma991001720169708646)
   `Publisher`
