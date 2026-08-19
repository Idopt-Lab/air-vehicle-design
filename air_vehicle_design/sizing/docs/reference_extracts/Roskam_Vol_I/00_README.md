# Reference Extracts — Roskam, *Airplane Design, Part I: Preliminary Sizing of Airplanes*

Scraped equations, tables, and graphs from:

> Jan Roskam, **Airplane Design, Part I: Preliminary Sizing of Airplanes**, Roskam
> Aviation and Engineering Corporation, Lawrence, KS.

One file per chapter. The goal is a citable, machine-readable capture of every
equation, table, and graph for use as a validation/reference source in the
`sizing/` framework, mirroring the `Nicolai_Aircraft_Design_Vol_I/` and
`Raymer_Aircraft_Design_6ed/` extractions.

## Citation convention

Each scraped item carries an inline citation of the form:

> *[Roskam, Eq. (X.Y), p. NNN]*  — equations
> *[Roskam, Table X.Y, p. NNN]*  — tables
> *[Roskam, Fig. X.Y, p. NNN]*   — figures/graphs

- **Page number** is the book's printed folio, not the PDF page index.
- **Author** is abbreviated "Roskam" throughout (full citation above).
- **Graphs** are digitized by reading values off the plotted curves where the plot
  carries design data a sizing formula would need. Values read this way are marked
  *(read from plot)*.
- Narrative/prose is paraphrased, not transcribed verbatim, in agreement with
  ASD-STE100 Simplified Technical English.

## Progress

| # | File | Chapter | Book pp | Status |
|---|------|---------|---------|--------|
| 1 | `01_introduction_and_takeoff_weight.md` | 1 Introduction; 2 Estimating Take-Off Gross Weight, Empty Weight, and Mission Fuel Weight | 1–88   | **done** |
| 2 | `02_sizing_to_performance_requirements_part1.md` | 3.1–3.4 Sizing to Stall Speed, Take-off, Landing, and Climb Requirements | 89–159 | **done** |
| 3 | `03_sizing_to_performance_requirements_part2.md` | 3.5–3.8 Sizing to Maneuvering, Cruise Speed, and Matching Requirements; Chapter 4 A User's Guide to Preliminary Airplane Sizing | 160–196 | **done** |

*(Book-page ranges above are the actual extracted spans, confirmed during extraction
by matching running headers and printed page footers — the front-matter table-of-
contents estimate drifted slightly from the true boundaries. Chapter 5 References
and Chapter 6 Index are back matter, not extracted.)*

## Extraction complete

All 4 chapters (1 through 4) are extracted, cited, and in this folder.

## Correctness sweep (2026-08-17)

Every page that carried an OCR-uncertainty flag was re-rendered at 300 dpi and
compared against the extracted text. A sample of unflagged, high-value pages was
checked the same way. **No `[verify]` flags remain.** Results:

| Page | Item | Outcome |
|---|---|---|
| 47  | Table 2.15 (`A`,`B` empty-weight regression) | Confirmed. Homebuilts sub-rows pair correctly. Category 2 "Composites" has no printed value in the source; this is not an OCR gap. |
| 77  | Table 2.20 (Breguet partials) | **Corrected.** The `V` row was wrong: the propeller side has no Range case, and the jet Range case is `-Rc_j(V^2 L/D)^-1`. Mixed-unit convention (sm/mph for props, nm-or-sm/kt-or-mph for jets) is now stated explicitly. |
| 101–102 | Eq. (3.9) (military ground run) | **Corrected.** The extract had an invented equation. The true form, and the `k_1`/`k_2`/`X`/`l_p` definitions plus the propeller disk-loading table, are now in place. |
| 152 | Eqs. (3.37)–(3.39) (steep-climb `sin gamma`) | **Corrected.** Eq. (3.39) was substantively wrong; it is `P_dl = (L/D)^2/{1 + (L/D)^2}`. Eq. (3.38) is now complete. |
| 185–186 | §3.7.4.1 fighter take-off tabulation | **Corrected.** The extract held one column of a 4x3 grid and named `k_2` as `k_1`. The full table and the reduced take-off relation are now in place. |
| 18  | Eq. (2.16) (empty-weight regression) | Confirmed exactly. |
| 90  | Eq. (3.1) (power-off stall speed) | Confirmed exactly. |
| 98  | Eqs. (3.7)–(3.8) (`TOP_25`) | Confirmed exactly. |
| 122 | Tables 3.4 and 3.5 (parasite/wetted-area regressions) | **One digit corrected**: Business Jets `d` = 0.6977, not 0.6971. All other rows confirmed, including the Fighters row (`c` = -0.1289, `d` = 0.7506) that `F16GeomL1.m` cites. |

Note on method: three of the five corrections were NOT self-flagged by the
extraction pass. Trust the sweep table above, not the absence of a `[verify]`
marker, when judging whether a given value has been checked.

Status values: `pending` → `in progress` → `done`.
