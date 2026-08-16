# Reference Extracts — Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed.

Scraped equations, tables, and graphs from:

> Daniel P. Raymer, **Aircraft Design: A Conceptual Approach**, 6th edition, AIAA
> Education Series, American Institute of Aeronautics and Astronautics, Reston, VA,
> 2018.

One file per chapter/appendix. The goal is a citable, machine-readable capture of
every equation, table, and graph for use as a validation/reference source in the
`sizing/` framework, mirroring the `Nicolai_Aircraft_Design_Vol_I/` extraction.

## Citation convention

Each scraped item carries an inline citation of the form:

> *[Raymer, Eq. (X.Y), p. NNN]*  — equations
> *[Raymer, Table X.Y, p. NNN]*  — tables
> *[Raymer, Fig. X.Y, p. NNN]*   — figures/graphs

- **Page number** is the book's printed folio (read from each page), not the PDF page index.
- **Author** is abbreviated "Raymer" throughout (full citation above).
- **Graphs** are digitized by reading values off the plotted curves where the plot carries
  design data a sizing formula would need. Tabulated values read this way are
  **approximate** (subject to plot-reading error) and are marked *(read from plot)*.
  Purely illustrative/photographic figures are noted by caption only, not digitized.
- Narrative/prose is condensed relative to the book — design guidance is paraphrased,
  not transcribed verbatim, except where a definition or caveat is load-bearing.

## Progress

| # | File | Chapter / Appendix | Book pp | Status |
|---|------|--------------------|---------|--------|
| 1  | `01_design_a_separate_discipline.md`     | 1 Design—A Separate Discipline                    | 1–26    | **done** |
| 2  | `02_overview_of_design_process.md`       | 2 Overview of the Design Process                  | 27–52   | **done** |
| 3  | `03_sizing_from_conceptual_sketch.md`    | 3 Sizing from a Conceptual Sketch                 | 53–92   | **done** |
| 4  | `04_airfoil_and_wing_tail_geometry.md`   | 4 Airfoil and Wing/Tail Geometry Selection        | 55–113  | **done** |
| 5  | `05_thrust_to_weight_and_wing_loading.md`| 5 Thrust-to-Weight Ratio and Wing Loading         | 115–144 | **done** |
| 6  | `06_initial_sizing.md`                   | 6 Initial Sizing                                  | 145–164 | **done** |
| 7  | `07_configuration_layout_and_loft.md`    | 7 Configuration Layout and Loft                   | 165–212 | **done** |
| 8  | `08_special_considerations_config_layout.md` | 8 Special Considerations in Configuration Layout | 213–260 | **done** |
| 9  | `09_crew_station_passengers_payload.md`  | 9 Crew Station, Passengers, and Payload           | 261–274 | **done** |
| 10 | `10_propulsion_and_fuel_system_integration.md` | 10 Propulsion and Fuel System Integration   | 275–336 | **done** |
| 11 | `11_landing_gear_and_subsystems.md`      | 11 Landing Gear and Subsystems                    | 337–378 | **done** |
| 12 | `12_aerodynamics.md`                     | 12 Aerodynamics                                   | 389–462 | **done** |
| 13 | `13_propulsion.md`                       | 13 Propulsion                                     | 463–489 | **done** |
| 14 | `14_structures_and_loads.md`             | 14 Structures and Loads                           | 491–557 | **done** |
| 15 | `15_weights.md`                          | 15 Weights                                        | 559–584 | **done** |
| 16 | `16_stability_control_handling_qualities.md` | 16 Stability, Control, and Handling Qualities | 585–636 | **done** |
| 17 | `17_performance_and_flight_mechanics.md` | 17 Performance and Flight Mechanics               | 637–686 | **done** |
| 18 | `18_cost_analysis.md`                    | 18 Cost Analysis                                  | 687–708 | **done** |
| 19 | `19_sizing_and_trade_studies.md`         | 19 Sizing and Trade Studies                       | 709–734 | **done** |
| 20 | `20_electric_aircraft.md`                | 20 Electric Aircraft                              | 735–762 | **done** |
| 21 | `21_vertical_flight_jet_and_prop.md`     | 21 Vertical Flight—Jet and Prop                   | 763–804 | **done** |
| 22 | `22_extremes_of_flight.md`               | 22 Extremes of Flight                             | 805–832 | **done** |
| 23 | `23_design_of_unique_aircraft_concepts.md` | 23 Design of Unique Aircraft Concepts           | 833–866 | **done** |
| 24 | `24_conceptual_design_examples.md`       | 24 Conceptual Design Examples                     | 867–958 | **done** |
| A  | `A_unit_conversion.md`                   | Appendix A Unit Conversion                        | 959–962 | **done** |
| B  | `B_standard_atmosphere.md`               | Appendix B Standard Atmosphere                    | 963–968 | **done** |
| C  | `C_airspeed.md`                          | Appendix C Airspeed                               | 969–970 | **done** |
| D  | `D_airfoil_data.md`                      | Appendix D Airfoil Data                           | 971–986 | **done** |
| E  | `E_typical_engine_performance_curves.md` | Appendix E Typical Engine Performance Curves      | 987–994 | **done** |
| F  | `F_design_requirements_and_specifications.md` | Appendix F Design Requirements and Specifications | 995–998 | **done** |

*(Book-page ranges above are the actual extracted spans, confirmed during extraction by
matching the "CHAPTER N" / "Appendix X" running header on each page — the scan inserts
unnumbered photo plates that shift the book-page→PDF-index offset partway through the book,
so several ranges differ from the printed table of contents' estimates. Chapter 24 runs
through book p. 958, well past the TOC's p. 904 estimate; Appendix A begins at p. 959, not
p. 905. Questions (p. 999) / References (p. 1009) / Index (p. 1017) are back-matter, not
extracted — no equations/tables/figures to cite.)*

## Extraction complete

All 24 chapters and all 6 appendices (A–F) have been extracted, cited, and are in this folder.
Several equation coefficients/exponents from the older, partly OCR-garbled `raymer_data.md`
extract in the parent `reference_extracts/` folder were re-verified against fresh page-image
renders during this extraction; two were corrected (Eq. 12.11 winglet AR, Eq. 15.3 vertical-tail
sweep exponent, Eq. 15.13 oil-cooling exponent — see `12_aerodynamics.md`/`15_weights.md` for
details) and one flagged discrepancy (old Eq. 10.8 sign) was found in the fresh OCR of
`10_propulsion_and_fuel_system_integration.md` — see that file's header notes before using
either coefficient in code. Remaining OCR uncertainties are flagged inline per-file with
`[verify p. NNN]`.
