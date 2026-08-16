---
layout: default
title: Stability & Control
nav_order: 8
permalink: /stability-control/
---

# Stability & Control
{: .no_toc }

Empennage sizing, static and dynamic stability, lateral-directional characteristics, and
the engine-out case.

1. TOC
{:toc}

---

## Topic: Empennage Sizing (EMP)

### Primary References

1. **STC-EMP-P01** — [Empennage General Design](https://www.fzt.haw-hamburg.de/pers/Scholz/HOOU/AircraftDesign_9_EmpennageGeneralDesign.pdf)
   Scholz, D., "Empennage General Design," Sec. 9 in *Aircraft Design*, Hamburg University
   of Applied Sciences (HAW Hamburg). 16 pp.
   Tail volume coefficient method to size horizontal and vertical tails. **Expected level
   for the Fall semester.** Covers empennage types, functions, and the trim/stability/control
   roles each surface plays.
   `Open`

2. **STC-EMP-P02** — [Empennage Sizing](https://www.fzt.haw-hamburg.de/pers/Scholz/HOOU/AircraftDesign_11_EmpennageSizing.pdf)
   Scholz, D., "Empennage Sizing," Sec. 11 in *Aircraft Design*, Hamburg University of
   Applied Sciences (HAW Hamburg). 29 pp.
   In-depth empennage sizing from moment equilibrium, including full scissor-plot
   development. **Expected level for the Spring semester.** Picks up exactly where
   STC-EMP-P01 stops.
   `Open`

3. **STC-EMP-P03** — [Tail Design](http://aero.us.es/adesign/Slides/Extra/Stability/Design_Tail/Chapter%206.%20Tail%20Design.pdf)
   Sadraey, M. H., "Tail Design," Ch. 6 in *Aircraft Design: A Systems Engineering
   Approach*, John Wiley & Sons, 2012.
   Step-by-step walkthrough of tail design with an explicit design procedure and worked
   numbers. The most procedural of the three — useful when you want a checklist rather
   than a derivation.
   `Open`

### Secondary References

1. **STC-EMP-S01** — [Empennage Sizing and Aircraft Stability using Matlab](https://digitalcommons.calpoly.edu/aerosp/67/)
   Struett, R. C., *Empennage Sizing and Aircraft Stability using Matlab*, Senior Project,
   Aerospace Engineering Dept., California Polytechnic State University, San Luis Obispo,
   June 2012. 37 pp.
   Four-stage workflow: size the empennage for static stability, check dynamic stability
   from the equations of motion, verify static stability across all flight conditions, then
   augment. Includes the MATLAB source. A realistic model of scope for a student project.
   Direct PDF: [digitalcommons.calpoly.edu](https://digitalcommons.calpoly.edu/cgi/viewcontent.cgi?article=1074&context=aerosp)
   `Open`

2. **STC-EMP-S02** — [Sizing and Optimization of the Horizontal Tail of a Jet Trainer](https://www.eucass.eu/doi/EUCASS2019-0335.pdf)
   Karatoprak, S., and Özgen, S., "Sizing and Optimization of the Horizontal Tail of a Jet
   Trainer," *8th European Conference for Aeronautics and Space Sciences (EUCASS)*, 2019.
   doi:10.13009/EUCASS2019-335. 15 pp.
   Horizontal tail sized to meet stability and control requirements across a specified CG
   range, then optimized. Introduces relaxed static stability with active control and what
   it buys in tail volume and weight. Good source of tail sizing diagrams.
   `Open`

3. **STC-EMP-S03** — [Aircraft Horizontal and Vertical Tail Design](https://aerotoolbox.com/design-aircraft-tail/)
   AeroToolbox, "Aircraft Horizontal and Vertical Tail Design," *Fundamentals of Aircraft
   Design* series.
   Short, readable introduction to tail sizing with typical aspect ratios and configuration
   trade-offs (conventional, T-tail, cruciform). Good orientation before tackling
   STC-EMP-P01.
   `Open`

4. **STC-EMP-S04** — Tail Design and Sizing (Stanford AA241)
   Kroo, I., and Shevell, R. S., "Tail Design and Sizing," in *Aircraft Design: Synthesis
   and Analysis*, Desktop Aeronautics / Stanford University.
   {: .warning }
   > Both Stanford hosts (`adg.stanford.edu`, `aerodesign.stanford.edu`) are offline.
   > Retained for the citation. Older captures exist — search
   > `adg.stanford.edu/aircraftdesign/stability/taildesign.html` on the
   > [Internet Archive Wayback Machine](https://web.archive.org/). The fuselage chapter of
   > the same text is mirrored and linked as
   > [CFG-FUS-P01]({{ site.baseurl }}/configuration-fuselage/).

   `Citation only`

---

## Topic: Static & Dynamic Stability Analysis (SSA)

### Primary References

1. **STC-SSA-P01** — [Static Longitudinal Stability and Control (Perkins & Hage, Ch. 5–7)](http://wpage.unina.it/fabrnico/DIDATTICA/PGV_2012/MAT_DID_CORSO/03_Stab_Contr_Longitudinale/CAP5-7_PERKINS.pdf)
   Perkins, C. D., and Hage, R. E., Chs. 5–7 in *Airplane Performance, Stability and
   Control*, John Wiley & Sons, New York, 1949. ISBN 978-0-471-68046-8. 102 pp.
   The classic longitudinal stability and control treatment. Still the clearest derivation
   of neutral point, stick-fixed and stick-free stability, and elevator sizing for trim.
   {: .warning }
   > Scan of a copyrighted textbook hosted on the Università di Napoli Federico II course
   > page. Cite the book, not the URL.
   > [Publisher listing](https://www.wiley.com/en-ae/Airplane+Performance,+Stability+and+Control-p-9780471680468)

   `Open`

2. **STC-SSA-P02** — [Directional Stability and Control (Perkins & Hage)](http://wpage.unina.it/fabrnico/DIDATTICA/PGV_2012/MAT_DID_CORSO/04_Stab_Contr_Direzionale/Stab_Contr_DIR_Perkins.pdf)
   Perkins, C. D., and Hage, R. E., "Directional Stability and Control," in *Airplane
   Performance, Stability and Control*, John Wiley & Sons, 1949. 26 pp.
   Weathercock stability, rudder sizing, and the asymmetric-thrust case. Read alongside
   STC-OEI-P01.
   {: .warning }
   > Scan of a copyrighted textbook. Cite the book.

   `Open`

3. **STC-SSA-P03** — [Dihedral Effect and Lateral Control (Perkins & Hage)](http://wpage.unina.it/fabrnico/DIDATTICA/PGV_2012/MAT_DID_CORSO/05_EffDiedro_Contr_Rollio/EffDiedro_Rollio_Perkins.pdf)
   Perkins, C. D., and Hage, R. E., "Dihedral Effect and Lateral Control," in *Airplane
   Performance, Stability and Control*, John Wiley & Sons, 1949. 33 pp.
   Where C<sub>lβ</sub> comes from, how wing position and sweep contribute, and how to size
   ailerons for roll rate.
   {: .warning }
   > Scan of a copyrighted textbook. Cite the book.

   `Open`

### Secondary References

1. **STC-SSA-S01** — [AeroFuse.jl Static Stability Analysis Tutorial](https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-stability/#Static-Stability-Analysis)
   HKUST OCTAD Lab, "Static Stability Analysis," *AeroFuse.jl* documentation.
   Worked static stability analysis using a vortex lattice method (VLM) workflow. Useful if
   you want to move past tail volume coefficients to a computed neutral point.
   `Open`

2. **STC-SSA-S02** — [Introduction to Aircraft Stability and Control (Course Notes, M&AE 5070)](https://courses.cit.cornell.edu/mae5070/Caughey_2011_04.pdf)
   Caughey, D. A., *Introduction to Aircraft Stability and Control*, Course Notes for
   M&AE 5070, Sibley School of Mechanical and Aerospace Engineering, Cornell University,
   2011.
   Full set of notes covering static longitudinal stability, the dynamical equations and
   stability derivatives, and dynamic response to perturbations. The source of STC-DAT-P01.
   `Open`

---

## Topic: Aircraft Data & Stability Derivatives (DAT)

### Primary References

1. **STC-DAT-P01** — [Stability Characteristics of the Boeing 747](https://courses.cit.cornell.edu/mae5070/B747_Data.pdf)
   Caughey, D. A., "Stability Characteristics of the Boeing 747," Sec. 5.4 in
   *Introduction to Aircraft Stability and Control*, Course Notes for M&AE 5070,
   Cornell University, 2011.
   Longitudinal, lateral and directional stability derivatives for the 747 at several
   flight conditions (sea level, 20,000 ft, 40,000 ft; clean, and powered approach with
   gear up and 20° flap), with the corresponding mass properties. The standard validation
   dataset — check your own derivative estimates against these before trusting them.
   `Open`

---

## Topic: One-Engine-Inoperative (OEI)

### Primary References

1. **STC-OEI-P01** — One-Engine-Inoperative (OEI) Analysis
   Course lecture material, Air Vehicle Design, Virginia Tech.
   V<sub>MC</sub> determination, rudder sizing for the engine-out case, and the
   climb-gradient requirements that size the vertical tail on multi-engine designs.
   Distributed through the course; no public copy located. For the underlying method see
   STC-SSA-P02 and FAR/CS-25 Subpart B.
   `Citation only`

### Secondary References

1. **STC-OEI-S01** — [14 CFR Part 25 Subpart B — Flight](https://www.ecfr.gov/current/title-14/chapter-I/subchapter-C/part-25/subpart-B)
   U.S. Federal Aviation Administration, *Airworthiness Standards: Transport Category
   Airplanes*, 14 CFR Part 25, Subpart B.
   The binding source for V<sub>MC</sub>, V<sub>MCG</sub>, and the one-engine-inoperative
   climb gradients (§25.111, §25.121, §25.149). If your design is transport category, size
   the vertical tail against this, not against a rule of thumb.
   `Open`

---

## Topic: Flight Mechanics Texts (TXT)

### Primary References

1. **STC-TXT-P01** — [Performance, Stability, Dynamics, and Control of Airplanes](https://doi.org/10.2514/4.102745)
   Pamadi, B. N., *Performance, Stability, Dynamics, and Control of Airplanes*, 3rd ed.,
   AIAA Education Series, AIAA, Reston, VA, 2015. doi:10.2514/4.102745
   The single text covering everything on this page and the performance page in one
   consistent notation — written by a Virginia Tech and NASA Langley author. Best feature
   for a design course is that it derives the stability derivatives from geometry, so you
   can compute them for *your* configuration rather than looking them up for someone else's.
   VT access: [ProQuest Ebook Central (VT sign-in)](https://ebookcentral.proquest.com/lib/vt/detail.action?docID=3111614)
   `Publisher`

2. **STC-TXT-P02** — [Introduction to Aircraft Flight Mechanics](https://doi.org/10.2514/4.862069)
   Yechout, T. R., with Morris, S. L., Bossert, D. E., and Hallgren, W. F., *Introduction to
   Aircraft Flight Mechanics: Performance, Static Stability, Dynamic Stability, and
   Classical Feedback Control*, AIAA Education Series, AIAA, Reston, VA, 2003.
   doi:10.2514/4.862069 (3rd ed., 2024,
   doi:[10.2514/4.107252](https://doi.org/10.2514/4.107252).)
   The more approachable of the two. Comes out of the USAF Test Pilot School tradition, so
   it stays tied to what the airplane actually does. The right first source for the dynamic
   modes — phugoid, short period, Dutch roll, spiral — and for deciding whether yours need
   augmentation.
   `Publisher`

### Secondary References

1. **STC-TXT-S01** — Flying Qualities and Flight Testing of the Airplane
   Stinton, D., *Flying Qualities and Flight Testing of the Airplane*, AIAA Education
   Series, AIAA, Reston, VA, 1996. ISBN 978-1-56347-117-6.
   Flying qualities from the pilot's side — what the handling-qualities requirements mean in
   the cockpit, and how they get tested. Useful for justifying a Cooper-Harper-style claim
   about your design rather than asserting it. No public copy located.
   `Citation only`
