---
layout: default
title: Aerodynamics
nav_order: 5
permalink: /aerodynamics/
---

# Aerodynamics
{: .no_toc }

Drag estimation and high-speed wing design at the level of fidelity a conceptual design
actually supports.

1. TOC
{:toc}

---

## Topic: Induced Drag & Oswald Factor (OSW)

### Primary References

1. **AER-OSW-P01** — [Estimating the Oswald Factor from Basic Aircraft Geometrical Parameters](https://www.fzt.haw-hamburg.de/pers/Scholz/OPerA/OPerA_PUB_DLRK_12-09-10.pdf)
   Niţă, M., and Scholz, D., "Estimating the Oswald Factor from Basic Aircraft Geometrical
   Parameters," *Deutscher Luft- und Raumfahrtkongress 2012*, Berlin, 10–12 September 2012.
   Document ID 281424. 19 pp.
   **Use this instead of assuming _e_ = 0.8.** Builds a theoretical Oswald factor from taper
   ratio and sweep, then corrects for fuselage, zero-lift drag and Mach number using
   statistical aircraft data. Claimed accuracy within 4%. Also covers non-planar
   configurations — winglets, dihedral and box wings.
   `Open`

### Secondary References

1. **AER-OSW-S01** — [DGLR publication record, Document ID 281424](https://publikationen.dglr.de/?tx_dglrpublications_pi1%5Bdocument_id%5D=281424)
   Official conference record for AER-OSW-P01, with the persistent URN
   `urn:nbn:de:101:1-201212176728`. Cite this if you need a formal archival reference.
   `Open`

---

## Topic: Transonic Aerodynamics (TRN)

### Primary References

1. **AER-TRN-P01** — [Transonic Aerodynamics of Airfoils and Wings](https://archive.aoe.vt.edu/mason/Mason_f/ConfigAeroTransonics.pdf)
   Mason, W. H., "Transonic Aerodynamics of Airfoils and Wings," Ch. 7 in
   *Configuration Aerodynamics*, Virginia Tech, 2006. 24 pp.
   Why transonic cruise is hard, what supercritical airfoils actually buy you, and how to
   pick a drag-divergence Mach number. Defines M<sub>DD</sub> at dC<sub>D</sub>/dM = 0.10 —
   use that definition consistently in your drag rise model.
   Now also published as a chapter of the VT open textbook
   [Lecture Notes on Configuration Aerodynamics](https://pressbooks.lib.vt.edu/configurationaerodynamics/).
   `Open`

### Secondary References

1. **AER-TRN-S01** — [Subsonic Aerodynamics of Airfoils and Wings](https://archive.aoe.vt.edu/mason/Mason_f/ConfigAeroSubFoilWing.pdf)
   Mason, W. H., "Subsonic Aerodynamics of Airfoils and Wings," Ch. 6 in
   *Configuration Aerodynamics*, Virginia Tech, 2006.
   The companion chapter to AER-TRN-P01. Read first if your cruise Mach is below drag rise.
   `Open`

---

## Topic: Supersonic Wing Design (SUP)

### Secondary References

1. **AER-SUP-S01** — [Aerodynamic shape optimization of a supersonic transport including a subsonic static margin constraint](https://doi.org/10.1016/j.ast.2025.110565)
   Seraj, S., Yildirim, A., and Martins, J. R. R. A., "Aerodynamic shape optimization of a
   supersonic transport including a subsonic static margin constraint,"
   *Aerospace Science and Technology*, Vol. 166, 2025, Art. 110565.
   doi:10.1016/j.ast.2025.110565
   RANS-based shape optimization of a three-surface supersonic transport. The point for a
   design course is the coupling: optimizing purely for supersonic cruise drives the
   configuration into an unacceptable low-speed stability condition, so the static margin
   has to enter the optimization as a constraint. Directly relevant to any supersonic
   project. See also [Mission Case Studies]({{ site.baseurl }}/case-studies/).
   `Publisher`

---

## Topic: Aerodynamics Texts & Airfoil Data (TXT)

### Primary References

1. **AER-TXT-P01** — [Theory of Wing Sections, Including a Summary of Airfoil Data](https://store.doverpublications.com/products/9780486605869)
   Abbott, I. H., and von Doenhoff, A. E., *Theory of Wing Sections, Including a Summary of
   Airfoil Data*, Dover Publications, New York, 1959. ISBN 978-0-486-60586-9.
   The airfoil data source. You need it for section lift curve slope, c<sub>l,max</sub>,
   moment coefficient and drag bucket when you pick an airfoil — the appendix is the reason
   the book is still in print. In print from Dover; borrowable scan at the
   [Internet Archive](https://archive.org/details/theoryofwingsect0000abbo).
   Much of the same data is free in the underlying NACA report, cited as AER-TXT-S04.
   `Publisher`

2. **AER-TXT-P02** — [Introduction to Transonic Aerodynamics](https://doi.org/10.1007/978-94-017-9747-4)
   Vos, R., and Farokhi, S., *Introduction to Transonic Aerodynamics*, Fluid Mechanics and
   Its Applications, Vol. 110, Springer, Dordrecht, 2015. doi:10.1007/978-94-017-9747-4
   Book-length treatment of the regime every transport design sits in. Where Mason's chapter
   (AER-TRN-P01) gives you the design rules, this gives you the physics they come from —
   shock/boundary-layer interaction, supercritical section design, and sweep theory with its
   limits.
   `Publisher`

3. **AER-TXT-P03** — [Lecture Notes on Configuration Aerodynamics](https://pressbooks.lib.vt.edu/configurationaerodynamics/)
   Mason, W. H., *Lecture Notes on Configuration Aerodynamics*, Virginia Tech Open
   Textbook, University Libraries, Virginia Tech.
   Bill Mason's Virginia Tech notes, released as an open textbook. Aerodynamics written for
   the configuration designer rather than the aerodynamicist — the whole book is about what
   the shape does to the numbers. It is the parent text of AER-TRN-P01 and AER-TRN-S01
   above, and its RCS chapter is cited on the
   [Survivability & Stealth]({{ site.baseurl }}/survivability-stealth/) page. Free, current,
   and written for this department.
   `Open`

### Secondary References

1. **AER-TXT-S01** — [Aerodynamics for Engineers](https://doi.org/10.1017/9781009105842)
   Bertin, J. J., and Cummings, R. M., *Aerodynamics for Engineers*, 6th ed., Cambridge
   University Press, Cambridge, 2021. doi:10.1017/9781009105842
   The undergraduate aerodynamics text, included here as the fallback when a method on this
   page assumes something you have forgotten. Raj's list cites the earlier Prentice-Hall
   editions.
   `Publisher`

2. **AER-TXT-S02** — [Aircraft Aerodynamic Design with Computational Software](https://doi.org/10.1017/9781139094672)
   Rizzi, A., and Oppelstrup, J., *Aircraft Aerodynamic Design with Computational Software*,
   Cambridge University Press, Cambridge, 2021. doi:10.1017/9781139094672
   Aerodynamic design done through actual computational tools, with the software and
   exercises supplied. The right reference if your project goes past handbook methods into
   panel or CFD work — it is explicit about what each level of fidelity can and cannot
   settle.
   `Publisher`

3. **AER-TXT-S03** — [The Aerodynamic Design of Aircraft](https://doi.org/10.2514/4.869228)
   Küchemann, D., *The Aerodynamic Design of Aircraft*, AIAA Education Series, AIAA, Reston,
   VA, 2012 (reprint of Pergamon Press, Oxford, 1978). doi:10.2514/4.869228
   Küchemann's classification of aircraft by the flow type they exploit — classical, swept,
   slender, waverider — and the design consequences of each. The deepest statement available
   of *why* configurations look the way they do at a given Mach number. Hard going, but the
   framework is worth having before you choose a planform.
   VT access: [Knovel (VT sign-in)](https://app-knovel-com.ezproxy.lib.vt.edu/web/toc.v/cid:kpADA0000T/viewerType:toc//root_slug:aerodynamic-design-aircraft)
   `Publisher`

4. **AER-TXT-S04** — [Summary of Airfoil Data](https://ntrs.nasa.gov/api/citations/19930090976/downloads/19930090976.pdf)
   Abbott, I. H., von Doenhoff, A. E., and Stivers, L. S., Jr., *Summary of Airfoil Data*,
   NACA Report No. 824, National Advisory Committee for Aeronautics, 1945.
   NTRS citation: [19930090976](https://ntrs.nasa.gov/citations/19930090976)
   The NACA report that became the data appendix of AER-TXT-P01 — section characteristics
   for the 4-, 5- and 6-series airfoils, free. Use this if you cannot get the book.
   `Open`
