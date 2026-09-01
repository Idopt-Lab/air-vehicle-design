# Reference Extracts — Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration of the Propulsion System*

Scraped equations, tables, and graphs from:

> Jan Roskam, **Airplane Design, Part II: Preliminary Configuration Design and
> Integration of the Propulsion System**, Design, Analysis and Research Corporation
> (DARcorporation), Lawrence, KS, 2018.

One file per chapter. The goal is a citable, machine-readable capture of every
equation, table, and graph for use as a validation/reference source in the
`sizing/` framework, mirroring the `Nicolai_Aircraft_Design_Vol_I/`,
`Raymer_Aircraft_Design_6ed/` and `Roskam_Vol_I/` extractions.

## Citation convention

Each scraped item carries an inline citation of the form:

> *[Roskam Vol. II, Eq. (X.Y), p. NNN]*  — equations
> *[Roskam Vol. II, Table X.Y, p. NNN]*  — tables
> *[Roskam Vol. II, Fig. X.Y, p. NNN]*   — figures/graphs

- **Page number** is the book's printed folio, not the PDF page index.
- Abbreviated "Roskam Vol. II" throughout, to keep it distinct from Part I.
- **Graphs** are digitized by reading values off the plotted curves where the plot
  carries design data a sizing formula would need. Values read this way are marked
  *(read from plot)*.
- Narrative/prose is paraphrased, not transcribed verbatim, in agreement with
  ASD-STE100 Simplified Technical English.

## Source characteristics — read before extending this extraction

**This PDF has no usable text layer.** 320 of its 324 pages are pure scanned images
(only the title page, copyright page and the two back-cover advertisement pages carry
text). `page.get_text()` returns nothing for the entire body of the book.

Every value in these files was therefore read **visually from a rendered page image**,
not from OCR. That is slower, but it structurally avoids the failure mode that produced
most of the errors found in the Raymer and Roskam Vol. I extractions, where the OCR text
layer emitted multi-column tables column-by-column and they were reassembled row-wise
with every cell displaced.

The scan itself is clean, high-contrast monospace typescript and is comfortably legible
at 200–260 dpi; dense tables and small subscripts were rendered at 400–700 dpi.

**Book page → PDF index offset is +11 and is constant throughout** (verified: PDF index
20 is printed page 9). Chapter openers were cross-checked against the PDF's embedded
outline.

## Progress

| # | File | Chapter | Book pp | PDF idx | Status |
|---|------|---------|---------|---------|--------|
| 1  | `01_introduction.md`                    | 1 Introduction                                                        | 1–6     | 12–17   | pending |
| 2  | `02_step_by_step_configuration_guide.md`| 2 Step-By-Step Guide to Configuration Design                          | 7–24    | 18–35   | pending |
| 3  | `03_selection_of_overall_configuration.md`| 3 Selection of the Overall Configuration                             | 25–106  | 36–117  | pending |
| 4  | `04_cockpit_and_fuselage_layouts.md`    | 4 Design of Cockpit and Fuselage Layouts                              | 107–122 | 118–133 | pending |
| 5  | `05_propulsion_system_integration.md`   | 5 Selection and Integration of the Propulsion System                  | 123–140 | 134–151 | pending |
| 6  | `06_wing_planform_and_lateral_controls.md`| 6 Class I Wing Planform Design; Sizing/Locating Lateral Controls     | 141–166 | 152–177 | pending |
| 7  | `07_max_lift_and_high_lift_devices.md`  | 7 Class I Clean-Airplane Max Lift; Sizing High-Lift Devices           | 167–186 | 178–197 | pending |
| 8  | `08_empennage_and_control_surface_sizing.md`| 8 Class I Empennage Sizing & Disposition; Control Surface Sizing   | 187–216 | 198–227 | pending |
| 9  | `09_landing_gear_sizing_and_disposition.md`| 9 Class I Landing Gear Sizing and Disposition                      | 217–236 | 228–247 | pending |
| 10 | `10_weight_and_balance_analysis.md`     | 10 Class I Weight and Balance Analysis                                | 237–258 | 248–269 | pending |
| 11 | `11_stability_and_control_analysis.md`  | 11 Class I Method for Stability and Control Analysis                  | 259–280 | 270–291 | pending |
| 12 | `12_drag_polar_determination.md`        | 12 Class I Method for Drag Polar Determination                        | 281–294 | 292–305 | pending |
| 13 | `13_preliminary_three_view.md`          | 13 Result of Preliminary Design Sequence I: The Preliminary Three View | 295–302 | 306–313 | pending |

*(Chapter 14 References (PDF idx 314–317) and Chapter 15 Index (PDF idx 318–321) are
back matter with nothing to cite, and are not extracted. The two trailing pages are
publisher advertisements.)*

Status values: `pending` → `in progress` → `done`.
