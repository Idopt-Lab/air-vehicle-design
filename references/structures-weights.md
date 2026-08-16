---
layout: default
title: Structures & Weights
nav_order: 9
permalink: /structures-weights/
---

# Structures & Weights
{: .no_toc }

Weight estimation from historical data, and structural sizing when historical data is not
good enough.

1. TOC
{:toc}

---

## Topic: Weight Estimation from Historical Data (WHD)

### Primary References

1. **STW-WHD-P01** — [Predicting Conceptual Aircraft Design Parameters Using Gaussian Process Regressions on Historical Data](https://www.gokcincinar.com/publication/j-2026-joaircraft-gpr/j-2026-JoAircraft-GPR.pdf)
   Arnson, M., Aljaber, R., and Cinar, G., "Predicting Conceptual Aircraft Design
   Parameters Using Gaussian Process Regressions on Historical Data,"
   *Journal of Aircraft*, 2026. doi:10.2514/1.C038387. 32 pp.
   Replaces the classical single-variable weight regressions with Gaussian process
   regressions over an open database of 400+ aircraft and 200+ engines. Non-parametric, so
   inputs can be supplied in whatever combination you happen to have. Reports improved
   accuracy on operating empty weight and uninstalled engine weight versus the standard
   textbook relations.
   The linked PDF is the authors' accepted manuscript (post-print); the published version
   is at [doi.org/10.2514/1.C038387](https://doi.org/10.2514/1.C038387).
   Landing page: [IDEAS Lab, University of Michigan](https://www.gokcincinar.com/publication/j-2026-joaircraft-gpr/)
   `Open`

### Secondary References

1. **STW-WHD-S01** — [FAST — Future Aircraft Sizing Tool](https://github.com/ideas-um/FAST)
   IDEAS Lab, University of Michigan, *FAST: Future Aircraft Sizing Tool*.
   The open-source database and sizing tool behind STW-WHD-P01. The database alone is worth
   having — it is the cleanest freely available source of consistent aircraft and engine
   parameters for building your own regressions.
   `Open`

2. **STW-WHD-S02** — [Predicting Aircraft Design Parameters Using Gaussian Process Regressions on Historical Data](https://doi.org/10.2514/6.2025-1287)
   Arnson, M., Aljaber, R., and Cinar, G., AIAA Paper 2025-1287, AIAA SciTech Forum, 2025.
   The conference version of STW-WHD-P01. Shorter; useful if you want the method without
   the full journal treatment.
   `Publisher`

---

## Topic: Structural Design & Wing Weight (STR)

### Primary References

1. **STW-STR-P01** — [Enhanced Conceptual Wing Weight Estimation Through Structural Optimization and Simulation](https://labs.engineering.asu.edu/aircraft-design/wp-content/uploads/sites/115/2023/03/AIAA-2010-9075-Structural-Design-and-Weight-Estimation.pdf)
   Petermeier, J., Radtke, G., Stohr, M., Woodland, A., Takahashi, T. T., Donovan, S., and
   Shubert, M., "Enhanced Conceptual Wing Weight Estimation Through Structural Optimization
   and Simulation," AIAA Paper 2010-9075, *13th AIAA/ISSMO Multidisciplinary Analysis
   Optimization Conference*, Fort Worth, TX, 13–15 September 2010. 22 pp.
   doi:10.2514/6.2010-9075
   Builds a wing weight estimate from an actual optimized structure (Excel/VBA driving
   CATIA and ABAQUS) rather than a historical regression, then compares against the
   regressions. Read it to understand *when* the empirical weight equations stop being
   trustworthy — unconventional planforms, unusual load paths, high aspect ratio.
   Hosted by the [Takahashi Aircraft Design Lab, ASU](https://labs.engineering.asu.edu/aircraft-design/publications/).
   `Open`

### Secondary References

1. **STW-STR-S01** — [Transport Category Wing Weight Estimation Using an Optimizing Beam-Element Structural Formulation](https://labs.engineering.asu.edu/aircraft-design/wp-content/uploads/sites/115/2023/05/AIAA-2015-1898.pdf)
   Takahashi, T. T., et al., AIAA Paper 2015-1898, AIAA SciTech Forum, 2015.
   doi:10.2514/6.2015-1898
   The follow-on to STW-STR-P01 using a lighter-weight beam-element formulation — closer to
   something you could actually implement inside a conceptual design loop.
   `Open`

---

## Topic: Airframe Structures Texts (TXT)

### Primary References

1. **STW-TXT-P01** — Airframe Structural Design: Practical Design Information and Data on Aircraft Structures
   Niu, M. C. Y., *Airframe Structural Design*, 2nd ed., Adaso/Adastra Engineering Center,
   2011. ISBN 978-962-7128-09-0.
   The practical airframe structures reference — how wing boxes, fuselage frames, cutouts,
   joints and fittings are actually built and sized, with the data to do it. Use it to sanity
   check that the structure implied by your weight estimate can physically exist. No public
   copy located; the publisher sells direct.
   `Citation only`

### Secondary References

1. **STW-TXT-S01** — Composite Airframe Structures: Practical Design Information and Data
   Niu, M. C. Y., *Composite Airframe Structures*, 3rd ed., Hong Kong Conmilit Press,
   Hong Kong, 2010. ISBN 978-962-7128-11-3.
   The composites counterpart. Relevant the moment you claim a composite weight fraction —
   it shows what the layup, joints and inspection provisions cost you, which is where naive
   composite weight savings go. No public copy located.
   `Citation only`
