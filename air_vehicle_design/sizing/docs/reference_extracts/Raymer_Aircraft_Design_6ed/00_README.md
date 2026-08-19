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

## Correctness sweep (2026-08-17/18) — READ THIS BEFORE USING ANY VALUE

The extraction pass above was written largely from the PDF's **OCR text layer**. A full
correctness sweep has since re-checked flagged and high-value content against **rendered page
images** (320–700 dpi). It found errors at a rate high enough that the sweep result, not the
original extraction, is what you should trust.

### What the sweep changed

Roughly 90 items were corrected across 20 files. The recurring defect classes:

1. **Column-major table scramble (most common).** The OCR emits a multi-column table
   column-by-column; the extraction reassembled it row-wise, silently displacing every cell. The
   result looks plausible and is entirely wrong. Confirmed in Tables 4.2, 9.1, 11.1, 14.3, 14.4,
   14.5, 15.3, 16.18, 17.1 and Box 3.3.
2. **Fabricated content.** Where OCR failed, some material was replaced with plausible invented
   values rather than flagged. Chapter 24's DR-1 example had two design requirements invented
   outright ("roll rate ≥180 deg/s", "ceiling ≥15,000 ft" — the page prints neither) and a
   three-view sketch conjured from the engine's dimensions in **inches**. Table 22.2's planetary
   data was partly replaced with modern astronomical values in different units from the book's.
3. **Inverted trends in digitized figures.** Figures digitized "from OCR plus the underlying
   closed-form model" instead of from the image: Figs. 16.4, 16.13, 16.21 and 19.7 had their
   trends backwards; Fig. 18.2's table did not satisfy the model it claimed to come from.
4. **Systematic section renumbering.** Chapters 7, 11, 13, 14, 17 and 18 had invented section
   numbering (unnumbered sub-headings promoted to numbered sections, shifting everything after).
   All are now renumbered to the book's own scheme.
5. **Page-citation drift.** ~30 citations pointed 1–2 pages off. All corrected where found.

**Most of these were never self-flagged.** Roughly half the real errors sat in content the
extraction pass was confident about. Do not read the absence of a `[verify]` marker as evidence
that something was checked.

### Book misprints found (the book itself is wrong; the files record the correct value + a note)

| Where | Printed | Recorded | Why |
|---|---|---|---|
| Eq. 15.1, p. 572 | `(t/c)root` with **no exponent** | `(t/c)root^-0.4` | As printed, a thinner wing gets lighter — physics inverted |
| Table 12.5, p. 421 | composite `k` = 0.7×10⁻⁵ ft | 0.17×10⁻⁵ ft | Contradicts its own metric column; all other rows convert at 0.3048 |
| Eq. 13.14, p. 482 | `V⁵√(ρ/Pn²)` (square root) | `⁵√(ρV⁵/(Pn²))` | Dimensionally impossible; book's own prose states the intent |
| Fig. 18.2, p. 694 | `H = H₁(Q₁/Q)^(x−1)` | `(Q/Q₁)^(x−1)` | As printed the curve rises with quantity, contradicting the plot |
| Table E.2, p. 991 | bypass ratio `80` | 8.0 | Not physically possible for a turbofan |
| Appendix D, p. 977 | station `30.916` | 39.916 | Breaks monotonic order; complementary station sums to 80.0 |
| Table 22.2, p. 813 | Jupiter dia. 14,000 km; whole Pluto row | kept as printed, marked unusable | Internally inconsistent |
| p. 48 prose | "payload 5000 and 20,000 lb" | 15,000 lb | Box 3.3, Fig. 3.13's axis and the arithmetic all say 15,000 |
| Fig. 16.16, p. 606 | tick "1.52" | 1.50 | Uniformly spaced axis |
| p. 235 | "80,000 ft {24,300 mg}" | m | Unit typo |

### Edition trap — do not "fix" the code to match this folder

This folder records the **6th edition**. Some coefficients differ in the 7th, and the project's
MATLAB deliberately cites the 7th:

- **Eqs. 10.4 / 10.10** engine weight: 6th ed. prints `0.084` / `0.063`; 7th ed. has
  `0.0847` / `0.0637`. `src/disciplines/propulsion/PropL2.m` uses `0.0637` and its header records
  that a person holding the 7th edition confirmed it on 2026-07-30. **Both are correct for their
  own edition.** Always state which edition when citing these.
- Table 6.4 tail volume coefficients are the *same* in both (jet fighter 0.40 / 0.07–0.12), so
  `F16TailL1`'s derived 0.315 / 0.063 is consistent with this folder.

### Verified clean (checked cell-by-cell against page images, no change needed)

Eqs. 15.1–15.24 (the fighter/attack weights set, in full); Eqs. 10.4–10.15 (engine sizing);
Eqs. 18.1–18.15 (DAPCA IV); Tables 3.1, 3.2, 6.1, 6.2, 6.3, 6.4, 6.5, 11.2, 11.3, 11.4, 11.5,
12.4, 14.2, 18.1; Table B.1 (standard atmosphere, all 74 rows × 7 columns, zero errors) and
Table B.2 (after 6 fixes). The standard-atmosphere tables are now digit-for-digit correct.

### Still outstanding

**No live `[verify]` markers remain in this folder.** The last seven (propeller/piston-engine data
in ch. 10, and the cargo/transport equation set in ch. 15) were resolved on 2026-08-17. What they
turned up, since several were substantive:

- **Eq. (10.23)** — the flag's premise was false. There is no per-blade-count exponent; the
  exponent is a **fourth root** in the equation itself, `D = K_p·⁴√(Power)`.
- **Tables 10.3 and 10.4** — both had been collapsed from **four** engine columns (Opposed /
  In-line / Radial / Turboprop) to two, with Radial data mislabelled as Turboprop throughout.
  Table 10.4's entire Metric block was missing.
- **Table 10.3 Length row** — two more **book misprints**: `4.24` and `3.730` are decimal slips for
  `0.424` and `0.373`, proven by Table 10.4 on the facing page printing the same exponents right.
- **Eq. (10.26)** — mks coefficient is **58**, not the suspected 55; and Eqs. 10.25/10.26 are on
  p. 320, not p. 322.
- **Table 10.5** — on p. **327** (not 326), with **four** temperature points, not three.
- **Table 15.2** — column order was reversed, putting nearly every value under the wrong aircraft
  class, plus two invented ranges.
- **Eqs. (15.25)–(15.45)** — the set runs to **15.45**, not 15.44: the **nacelle-group equation
  (15.31) was omitted entirely**, shifting every subsequent equation number one low. Seven
  individual coefficient/subscript errors were also fixed, including `Nc^2.541` → `Nc^0.541`.
- **Fig. 15.3** — the figure carries **seven** duct shapes; only four had been recorded.

One useful confirmation fell out of this: **Eq. (15.25) prints `(t/c)root^-0.4` explicitly**, which
independently corroborates that the same term's missing exponent in Eq. (15.1) is a printing error.

Still not image-verified: the qualitatively-described figures in ch. 17 (Figs. 17.2, 17.6–17.16,
17.19–17.26). Give any of these the same treatment before using them quantitatively.
