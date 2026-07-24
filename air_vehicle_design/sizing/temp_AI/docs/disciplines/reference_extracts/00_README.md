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
| 5  | `05_takeoff_weight_estimate.md`         | 5 Preliminary Estimate of Takeoff Weight    | 138–165 | pending |
| 6  | `06_takeoff_wing_loading.md`            | 6 Estimating the Takeoff Wing Loading       | 165–184 | pending |
| 7  | `07_planform_and_airfoil.md`            | 7 Selecting the Planform and Airfoil        | 184–208 | pending |
| 8  | `08_fuselage_sizing.md`                 | 8 Preliminary Fuselage Sizing and Design    | 208–234 | pending |
| 9  | `09_high_lift_devices.md`               | 9 High-Lift Devices                         | 234–267 | pending |
| 10 | `10_takeoff_and_landing.md`             | 10 Takeoff and Landing Analysis             | 267–295 | pending |
| 11 | `11_tail_sizing.md`                     | 11 Preliminary Sizing of Tails              | 295–305 | pending |
| 12 | `12_survivability_stealth.md`           | 12 Designing for Survivability (Stealth)    | 305–334 | pending |
| 13 | `13_wing_body_aerodynamics.md`          | 13 Estimating Wing–Body Aerodynamics        | 334–366 | pending |
| 14 | `14_propulsion_fundamentals.md`         | 14 Propulsion System Fundamentals           | 366–394 | pending |
| 15 | `15_inlet_design.md`                    | 15 Turbine Engine Inlet Design              | 394–424 | pending |
| 16 | `16_engine_installation.md`             | 16 Corrections for Engine Installation      | 424–446 | pending |
| 17 | `17_propeller_propulsion.md`            | 17 Propeller Propulsion Systems             | 446–477 | pending |
| 18 | `18_thrust_sizing.md`                   | 18 Propulsion System Thrust Sizing          | 477–501 | pending |
| 19 | `19_structures_and_materials.md`        | 19 Structures and Materials                 | 501–561 | pending |
| 20 | `20_refined_weight_estimate.md`         | 20 Refined Weight Estimate                  | 561–585 | pending |
| 21 | `21_static_stability_and_control.md`    | 21 Static Stability and Control             | 585–611 | pending |
| 22 | `22_trim_drag_and_maneuvering.md`       | 22 Trim Drag and Maneuvering Flight         | 611–623 | pending |
| 23 | `23_control_surface_sizing.md`          | 23 Control Surface Sizing Criteria          | 623–635 | pending |
| 24 | `24_life_cycle_cost.md`                 | 24 Life Cycle Cost                          | 635–661 | pending |
| 25 | `25_trade_studies_and_sizing.md`        | 25 Trade Studies and Sizing                 | 661–679 | pending |
| A  | `A_conversions.md`                      | Appendix A Conversions                      | 680–692 | pending |
| B  | `B_atmospheric_data.md`                 | Appendix B Atmospheric Data                 | 692–700 | pending |
| C  | `C_isentropic_flow.md`                  | Appendix C Isentropic Compressible Flow     | 700–708 | pending |
| D  | `D_normal_shock.md`                     | Appendix D Normal Shock Functions           | 708–714 | pending |
| E  | `E_oblique_conical_shocks.md`           | Appendix E Oblique & Conical Shocks         | 714–726 | pending |
| F  | `F_naca_airfoil_data.md`                | Appendix F NACA Airfoil Nomenclature/Data   | 726–744 | pending |
| G  | `G_real_aircraft_aero_data.md`          | Appendix G Aerodynamic Data of Real Aircraft| 744–756 | pending |
| H  | `H_wing_body_aero.md`                   | Appendix H Aerodynamics of Wing–Body Combos | 756–770 | pending |
| I  | `I_aircraft_weights_data.md`            | Appendix I Aircraft Weights Data            | 770–796 | pending |
| J  | `J_propulsion_data.md`                  | Appendix J Propulsion Data                  | 796–834 | pending |
| K  | `K_miscellaneous_data.md`               | Appendix K Miscellaneous Data               | 834–755 | pending |

*(PDF page ranges for appendices are approximate and will be confirmed during extraction.)*

Status values: `pending` → `in progress` → `done`.
