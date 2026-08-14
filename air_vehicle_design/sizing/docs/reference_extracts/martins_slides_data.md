# Martins Slides — "13: Refined Sizing, Trade Studies and Improved Fuel Fractions" — Extracted Data

**Source:** J.R.R.A. Martins, AE 481 Aircraft Design lecture slides, "13 — Refined Sizing, Trade Studies and Improved Fuel Fractions", University of Michigan, 2023 (`13-Sizing_refinement.pptx`).
**Compiled:** 2026-08-13, from a text extraction of the `.pptx`. The extraction is text-only: some equations lost symbols, subscripts, and exponents. Items with extraction (OCR) uncertainty are marked. Cross-check every equation form against `metabook_data.md` (same author, same method) before a test or a class cites a slide-only form.
**Purpose:** Documents the two sizing frameworks — the initial framework (= L1 sizing) and the preliminary framework (= L2 sizing) — that the sizing rewrite implements.

---

## Slides 3–4 — Initial design framework: weight build

- Empty-weight fraction: `We/W0 = a * W0^b`. Inputs: a, b. (Same form as metabook Eq. 2.3, where the constants are named A and C.)
- Range-segment fuel fraction: `Wi+1/Wi = exp(-R*C/(V*(L/D)))`. (Metabook Eq. 2.7.)
- Endurance-segment fuel fraction: `Wi+1/Wi = exp(-E*C/(L/D))`. (Metabook Eq. 2.8.)
- Fuel fraction: `Wf/W0 = 1 - Mff`, where Mff is the product of all segment fractions.
- W0 found by iteration from a W0 guess. (Metabook Algorithm 1.)
- Inputs: a, b; c (TSFC), L/D, R, V.

## Slide 5 — Design diagram (constraint diagram)

- T0/W0 vs W0/Sref diagram. Inputs: CD0, K, sFL, Ks, G, M, CLmax.
- Sample objective (cost) equation:
  ```
  C_aircraft = 10^(3.3191 + 0.8043*log10(MTOW))
  ```
- Landing equation:
  ```
  sL = 80*(WL/Sref) / ((rho/rhoSL)*CLmax,L) + Sa
  ```
  (Same form as metabook Eq. 4.19.)
- Takeoff equation: the slide text extracts only as the fragment `T/W = Ks²*CLmax,C*...` — the rest of the printed form was lost in extraction. Do NOT cite the slide for the takeoff form; cite metabook Eq. 4.16 (takeoff, TOP) or Eq. 4.24 (climb, which carries the ks²/CLmax structure) instead.

## Slide 6 — Initial design framework (= L1 sizing), full loop

Boxes and data flow. Quoted slide note: "Red lines indicate iterative process. Green boxes are inputs. Not all of them are design variables!"

- Fuel fraction box → `Wf/W0`.
- Empty weight I box → `We/W0`; inputs a, b.
- Design diagram box → `T0/W0` and `W0/Sref`; inputs CD0 and K (from Drag polar I, which takes Swet/Sref, AR, e), plus sFL, Ks, G, M, CLmax. The design diagram is consulted ONCE — it does not sit inside the iteration.
- MTOW iteration starting from `W0,guess`.
- Outputs: W0, Sref, T0, fuel burn.

## Slide 7 — Issues with the initial framework

Issues:
1. No correlation between Sref and W0.
2. No correlation between L/D and the estimated drag polar (CD0, K).
3. No correlation between the drag polar and the concept.

Solutions:
1. Better empty-weight estimation.
2. Estimate L/D from the drag polar.
3. Estimate wetted areas based on the concept.

## Slide 8 — Preliminary design framework (= L2 sizing)

- TWO iteration loops: the MTOW iteration (from `W0,guess`) AND a T0 iteration (from `T0,guess`).
- Empty weight II box (component-based estimation).
- Drag polar II box; inputs Sref; AR, e.
- Tail sizing box: inputs Lfus, Dfus → outputs Sht, Svt. It feeds BOTH the empty-weight box and the drag-polar box.
- Wing loading box (`W0/Sref`). Quoted slide note: "You don't need to draw the entire chart because W/S is fixed."
- Constraint inputs: sFL, Ks, G, M, CLmax.
- Outputs: W0, T0, fuel burn (or other objective).

## Slides 39–55 — Improved fuel fractions

Covered by the mission-analysis rewrite in `src/core/mission/` (L1 and L2 segment models); not re-extracted here.
