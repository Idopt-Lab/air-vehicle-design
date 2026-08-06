# Reference Extracts — Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I*

Scraped equations, tables, and graphs from:

> Leland M. Nicolai and Grant E. Carichner, **Fundamentals of Aircraft and Airship
> Design, Volume I — Aircraft Design**, AIAA Education Series, American Institute of
> Aeronautics and Astronautics, Reston, VA, 2010. ISBN 978-1-60086-751-4.

One file per chapter/appendix. The goal is a citable, machine-readable capture of
every equation, table, and graph for use as a validation/reference source in the
`sizing/` framework.

## Citation convention

Each scraped item carries an inline citation of the form:

> *[Nicolai & Carichner, Eq. (X.Y), p. NNN]*  — equations
> *[Nicolai & Carichner, Table X.Y, p. NNN]*  — tables
> *[Nicolai & Carichner, Fig. X.Y, p. NNN]*   — figures/graphs

- **Page number** is the book's printed folio (read from each page), not the PDF page index.
- **Author** is abbreviated "Nicolai & Carichner" throughout (full citation above).
- **Graphs** are digitized by reading values off the plotted curves. Tabulated values
  are **approximate** (subject to plot-reading error) and are marked *(read from plot)*.
  The graph's title/caption and axes are recorded verbatim.

## Progress

| # | File | Chapter / Appendix | PDF pp | Status |
|---|------|--------------------|--------|--------|
| 1  | `01_introduction.md`                    | 1 Introduction                              | 17–48   | **done** |
| 2  | `02_practical_aerodynamics.md`          | 2 Review of Practical Aerodynamics          | 48–86   | **done** |
| 3  | `03_aircraft_performance_methods.md`    | 3 Aircraft Performance Methods              | 86–116  | **done** |
| 4  | `04_operating_envelope.md`              | 4 Aircraft Operating Envelope               | 116–138 | **done** |
| 5  | `05_takeoff_weight_estimate.md`         | 5 Preliminary Estimate of Takeoff Weight    | 138–165 | **done** |
| 6  | `06_takeoff_wing_loading.md`            | 6 Estimating the Takeoff Wing Loading       | 165–184 | **done** |
| 7  | `07_planform_and_airfoil.md`            | 7 Selecting the Planform and Airfoil        | 184–208 | **done** |
| 8  | `08_fuselage_sizing.md`                 | 8 Preliminary Fuselage Sizing and Design    | 208–232 | **done** |
| 9  | `09_high_lift_devices.md`               | 9 High-Lift Devices                         | 233–265 | **done** |
| 10 | `10_takeoff_and_landing.md`             | 10 Takeoff and Landing Analysis             | 266–295 | **done** |
| 11 | `11_tail_sizing.md`                     | 11 Preliminary Sizing of Tails              | 294–305 | **done** |
| 12 | `12_survivability_stealth.md`           | 12 Designing for Survivability (Stealth)    | 305–332 | **done** |
| 13 | `13_wing_body_aerodynamics.md`          | 13 Estimating Wing–Body Aerodynamics        | 333–366 | **done** |
| 14 | `14_propulsion_fundamentals.md`         | 14 Propulsion System Fundamentals           | 355–382 | **done** |
| 15 | `15_inlet_design.md`                    | 15 Turbine Engine Inlet Design              | 383–412 | **done** |
| 16 | `16_engine_installation.md`             | 16 Corrections for Engine Installation      | 413–434 | **done** |
| 17 | `17_propeller_propulsion.md`            | 17 Propeller Propulsion Systems             | 435–465 | **done** |
| 18 | `18_thrust_sizing.md`                   | 18 Propulsion System Thrust Sizing          | 467–490 | **done** |
| 19 | `19_structures_and_materials.md`        | 19 Structures and Materials                 | 491–550 | **done** |
| 20 | `20_refined_weight_estimate.md`         | 20 Refined Weight Estimate                  | 551–574 | **done** |
| 21 | `21_static_stability_and_control.md`    | 21 Static Stability and Control             | 584–609 | **done** |
| 22 | `22_trim_drag_and_maneuvering.md`       | 22 Trim Drag and Maneuvering Flight         | 610–621 | **done** |
| 23 | `23_control_surface_sizing.md`          | 23 Control Surface Sizing Criteria          | 622–633 | **done** |
| 24 | `24_life_cycle_cost.md`                 | 24 Life Cycle Cost                          | 634–659 | **done** |
| 25 | `25_trade_studies_and_sizing.md`        | 25 Trade Studies and Sizing                 | 660–677 | **done** |
| A  | `A_conversions.md`                      | Appendix A Conversions                      | 678–688 | **done** |
| B–K | — | Appendices B–K (Atmospheric Data, Isentropic Flow, Normal Shock, Oblique & Conical Shocks, NACA Airfoil Data, Real-Aircraft Aero Data, Wing–Body Aero, Weights Data, Propulsion Data, Misc. Data) | — | **not in source** |

*(PDF page ranges above are exact, confirmed during extraction. Appendices B–K are listed in
the book's own front matter/table of contents, but this PDF file's content ends after Appendix
A — PDF page 688 (printed p. 679) is immediately followed by the back-of-book Index (PDF pp.
689–755, confirmed via total page count = 755). No further appendix content exists in this
source file to extract.)*

Status values: `pending` → `in progress` → `done` → `not in source` (content confirmed absent
from this PDF file).

## Extraction complete

All 25 main chapters and the one appendix present in this PDF file (Appendix A) have been
fully extracted, cited, and Grep-verified. Appendices B–K are not present in the source PDF
and cannot be extracted from it.
