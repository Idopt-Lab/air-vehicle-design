# AOE 4065 — Aerodynamics and Wing Design (Boeing 737 MAX 8)

## Start here

1. Unzip the whole folder.
2. Open MATLAB and set the current folder to `aero-wing-design/`.
3. Open `START_HERE.mlx` and run it. It puts the helpers on the path and checks your release.
4. Then run the lectures in order, `lecture/L01` to `lecture/L05`.

## What is in here

| Folder or file | What it is |
|---|---|
| `START_HERE.mlx` | Path set-up, release check, smoke test |
| `lecture/` | L01 geometry, L02 airfoil section, L03 cruise drag at three fidelity levels, L04 low speed, L05 Nicolai Table 7.1 cell by cell. |
| `lab/` | `LAB01_pick_the_AR` — the assignment (TODO 1–5). The quiz is on Canvas. |
| `helpers/` | Short functions that hold the textbook equations. Each one names its source: book, edition, equation, page. |
| `output/` | A place to save your figures. |

## Requirements

- MATLAB R2022b or newer runs the code. Open the `.mlx` files on R2026a or newer; they were saved on R2026a.
- No toolbox is necessary. The atmosphere comes from `helpers/isa_si.m`.

## Running a Live Script in class

- **Ctrl+Enter** runs one section.
- **Ctrl+Shift+Enter** runs a section and moves to the next.

All quantities are SI (m, kg, N, Pa, s). Where a textbook equation uses British units (Raymer Eq. 15.25, the wing weight), the helper converts the inputs and the result. The comments in the helper show the conversion.

## Where the numbers come from

- **Aircraft data:**
  - Boeing D6-38A004, *737 MAX Airplane Characteristics for Airport Planning*, Rev K (2025).
  - EASA type-certificate data sheets IM.A.120 (737) and E.115 (LEAP-1B).
  - The 737-800 reference wing from Jenkinson, Simpkin & Rhodes, *Civil Jet Aircraft Design* (1999), Data A. Boeing does not publish the MAX wing area or airfoils.
- **Equations:**
  - Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (2018).
  - Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design*, Vol. I (2010).
  - Roskam, *Airplane Design*, Parts I and II.
  - *U.S. Standard Atmosphere, 1976*.
  - 14 CFR Part 25.
- **Assumptions:** where no source exists, the lesson states the assumption in the text and in the helper.

## For the instructor

From MATLAB, in `air_vehicle_design/sizing/teaching/aero-wing-design/`:

```matlab
make_student_package                                % everything: mlx, instructor, smoke, zip
make_student_package('steps', ["mlx" "zip"])        % only some steps
check_lesson_numbers                                % re-derive every number the text quotes
runtests('tests')                                   % the helper unit tests
crosscheck_framework                                % helpers vs. the sizing framework (Aerospace Toolbox)
```

- **Solution:** the lab solution is built to `instructor_package/`. It is never in the zip. The build stops if a SOLUTION file gets into the student package or the zip.
- **Instructor files (not shipped):**
  - `SOURCES.md`: every citation, the input data and the trend matrix.
  - `FRAMEWORK_FINDINGS.md`: the differences between the lesson equations and the sizing framework (`src/`).
  - `crosscheck_framework.m`: computes those differences, one row per equation. It reads the repository `src/` and is not in the package.
